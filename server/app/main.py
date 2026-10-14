"""conmoney LLM 중계 서버(Spec 5장).

- 서버는 상태를 저장하지 않는다. 대화 기록은 앱이 들고 매 요청에 보낸다.
- 툴은 앱에서 실행된다. 서버는 툴 정의와 시스템 프롬프트, 숫자 검증, 가드레일만 맡는다.
- 요청·응답 본문은 DEBUG=1일 때만 로그에 남긴다.
"""
import logging
import secrets
import time
from collections import defaultdict, deque
from dataclasses import replace
from datetime import datetime

from fastapi import Depends, FastAPI, Header, HTTPException
from pydantic import BaseModel, Field

from . import guard, llm, prompts
from .config import Settings, load

log = logging.getLogger("conmoney")
logging.basicConfig(level=logging.INFO)

MAX_ROUNDS = 5


class Meter:
    """분당·일일 호출 수와 월 누적 비용(원). Cloud Run 인스턴스가 바뀌면 초기화되는 단순한 상한이다."""

    def __init__(self) -> None:
        self.calls: deque[float] = deque()
        self.daily: dict[str, int] = defaultdict(int)
        self.monthly_krw: dict[str, float] = defaultdict(float)

    def hit(self, per_minute: int = 30, per_day: int = 500) -> None:
        now = time.time()
        while self.calls and now - self.calls[0] > 60:
            self.calls.popleft()
        day = datetime.now().strftime("%Y-%m-%d")
        if len(self.calls) >= per_minute or self.daily[day] >= per_day:
            raise HTTPException(429, "요청이 너무 많아요. 잠시 후 다시 시도해 주세요.")
        self.calls.append(now)
        self.daily[day] += 1

    def add(self, usage: llm.Usage | None, usd_krw: float) -> None:
        if usage:
            self.monthly_krw[datetime.now().strftime("%Y-%m")] += usage.usd() * usd_krw

    def month_krw(self) -> float:
        return self.monthly_krw[datetime.now().strftime("%Y-%m")]


def create_app(settings: Settings | None = None) -> FastAPI:
    s = settings or load()
    app = FastAPI(title="conmoney", docs_url=None, redoc_url=None)
    meter = Meter()
    app.state.meter = meter

    def auth(x_app_token: str = Header(default="")) -> None:
        if not s.app_token or not secrets.compare_digest(x_app_token, s.app_token):
            raise HTTPException(401, "unauthorized")
        meter.hit()

    @app.get("/healthz")
    def healthz() -> dict:
        return {"ok": True}

    # ---------------------------------------------------------------- 분류
    class CategorizeIn(BaseModel):
        merchant: str = Field(max_length=200)
        categories: list[str] = Field(min_length=1, max_length=255)

    @app.post("/v1/categorize", dependencies=[Depends(auth)])
    def categorize(body: CategorizeIn) -> dict:
        merchant = guard.mask(body.merchant)[:50]
        result: llm.Classification | None = None
        try:
            result = llm.jev_classify(s, merchant, body.categories)
        except Exception as e:  # jev 장애·타임아웃이면 가벼운 LLM으로
            log.warning("jev 실패, 대비책 사용: %s", type(e).__name__)
            # 상한을 넘으면 규칙만 쓰도록 앱에 NONE을 돌려준다(Spec 5장)
            if meter.month_krw() < s.monthly_budget_krw * 0.8:
                try:
                    result = llm.openai_classify(s, merchant, body.categories)
                except Exception as e2:
                    log.warning("대비책 실패: %s", type(e2).__name__)
        if result is None or result.category not in body.categories:
            return {"category": "NONE", "confidence": None, "ambiguous": True, "model": result.model if result else None}
        meter.add(result.usage, s.usd_krw)
        ambiguous = result.confidence is None or result.confidence < s.jev_min_confidence
        return {"category": result.category, "confidence": result.confidence, "ambiguous": ambiguous, "model": result.model}

    # ---------------------------------------------------------------- 구매 상담
    class AgentIn(BaseModel):
        items: list[dict] = Field(min_length=1, max_length=200)
        round: int = Field(default=1, ge=1)

    def _final(text: str, items: list[dict], usage: list[llm.Usage], verdict: str | None, checked: bool) -> dict:
        return {
            "status": "final",
            "text": text,
            "items": items,
            "verdict": verdict,
            "verified": checked,
            "usage": _usage(usage),
        }

    def _usage(usage: list[llm.Usage]) -> dict:
        return {
            "input_tokens": sum(u.input_tokens for u in usage),
            "output_tokens": sum(u.output_tokens for u in usage),
            "krw": round(sum(u.usd() for u in usage) * s.usd_krw, 2),
            "model": usage[-1].model if usage else None,
        }

    @app.post("/v1/agent", dependencies=[Depends(auth)])
    def agent(body: AgentIn) -> dict:
        if body.round > MAX_ROUNDS:
            raise HTTPException(400, "too many rounds")
        items = [_mask_user(i) for i in body.items]
        if s.debug:
            log.info("agent in: %s", items[-3:])

        last = items[-1]
        if last.get("role") == "user" and guard.out_of_scope(_text_of(last)):
            msg = {"role": "assistant", "content": guard.REFUSAL}
            return _final(guard.REFUSAL, [msg], [], None, True)

        # 월 비용 상한에 가까우면 상담도 가벼운 모델로 내린다(Spec 5장)
        cfg = s
        if meter.month_krw() >= s.monthly_budget_krw * 0.8:
            cfg = replace(s, openai_model_agent=s.openai_model_light, openai_reasoning_agent=s.openai_reasoning_light)

        usage: list[llm.Usage] = []
        turn = llm.openai_agent(cfg, prompts.SYSTEM, items, prompts.TOOLS)
        usage.append(turn.usage)
        meter.add(turn.usage, s.usd_krw)

        calls = [o for o in turn.output_items if o.get("type") == "function_call"]
        if calls:
            unknown = [c["name"] for c in calls if c.get("name") not in prompts.TOOL_NAMES]
            if unknown:
                raise HTTPException(502, f"unknown tool {unknown}")
            return {
                "status": "tool_calls",
                "items": turn.output_items,
                "tool_calls": [{"call_id": c["call_id"], "name": c["name"], "arguments": c["arguments"]} for c in calls],
                "usage": _usage(usage),
            }

        # 최종 답: 금액·판단 검증 → 실패하면 1번 다시 생성 → 또 실패하면 숫자 없는 대체 문구(Spec F6)
        verdict = guard.last_verdict(items)
        problem = _problem(turn.text, items, verdict)
        if not problem:
            return _final(turn.text, turn.output_items, usage, verdict, True)

        log.info("숫자 검증 실패, 다시 생성: %s", problem if s.debug else "(숨김)")
        retry_items = items + turn.output_items + [{"role": "developer", "content": problem}]
        turn2 = llm.openai_agent(cfg, prompts.SYSTEM, retry_items, prompts.TOOLS)
        usage.append(turn2.usage)
        meter.add(turn2.usage, s.usd_krw)
        if turn2.text and not any(o.get("type") == "function_call" for o in turn2.output_items):
            if not _problem(turn2.text, items, verdict):
                return _final(turn2.text, turn2.output_items, usage, verdict, True)
        msg = {"role": "assistant", "content": guard.FALLBACK}
        return _final(guard.FALLBACK, [msg], usage, verdict, False)

    return app


def _problem(text: str, items: list[dict], verdict: str | None) -> str | None:
    bad = guard.unverified_amounts(text, items)
    if bad:
        shown = ", ".join(f"{b:,}원" for b in sorted(bad))
        return f"직전 답의 금액({shown})은 툴 결과에 없습니다. 툴 결과의 *_text 값을 그대로 인용해 같은 형식으로 다시 답하세요."
    if guard.verdict_mismatch(text, verdict):
        return f"판단은 simulate_purchase의 verdict({verdict})를 따라 '{guard.VERDICT_WORDS[verdict]}'로 다시 답하세요."
    return None


def _text_of(item: dict) -> str:
    c = item.get("content")
    if isinstance(c, str):
        return c
    if isinstance(c, list):
        return " ".join(x.get("text", "") for x in c if isinstance(x, dict))
    return ""


def _mask_user(item: dict) -> dict:
    if item.get("role") != "user":
        return item
    c = item.get("content")
    if isinstance(c, str):
        return {**item, "content": guard.mask(c)}
    return item


app = create_app()
