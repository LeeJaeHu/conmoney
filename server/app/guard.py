"""가드레일과 숫자 검증(Spec 6장, F6).

LLM이 답에 쓴 금액이 이번 대화의 툴 결과(또는 사용자가 말한 금액)에 있는지 확인한다.
횟수·날짜·퍼센트(2번, 12일, 10%)는 대안 제시에 자연스럽게 나오므로 검증하지 않고, 금액(원·만·천)만 본다.
"""
import json
import re

# ---------------------------------------------------------------- 식별 정보 가리기(앱에서도 가리지만 한 번 더)
_MASKS = [
    (re.compile(r"[\d*]{4}-[\d*]{4}-[\d*]{4}-[\d*]{3,4}"), "****-****-****-****"),
    (re.compile(r"(승인\s*번호|승인No\.?)\s*[:：]?\s*\d+"), "승인번호 ******"),
    (re.compile(r"01\d-?\d{3,4}-?\d{4}"), "010-****-****"),
    (re.compile(r"(?<![\d,.])\d{6,}(?![\d,])"), "******"),
]


def mask(text: str) -> str:
    for pattern, repl in _MASKS:
        text = pattern.sub(repl, text)
    return text


# ---------------------------------------------------------------- 범위 밖 질문(투자·대출 권유 금지)
_OUT_OF_SCOPE = re.compile(
    r"(주식|코인|비트코인|이더리움|암호화폐|가상화폐|ETF|펀드|채권|투자|대출|신용대출|마이너스\s*통장|보험\s*(추천|가입)|레버리지|선물\s*옵션)"
)
REFUSAL = "그 질문은 도와드리기 어려워요. 저는 예산 안에서 쓸지 말지를 같이 판단해 드리는 역할이라 투자·대출·보험 같은 금융 상품은 추천하지 않아요."


def out_of_scope(text: str) -> bool:
    return bool(_OUT_OF_SCOPE.search(text))


# ---------------------------------------------------------------- 금액 추출
_AMOUNT = re.compile(
    r"(?P<man>\d+(?:\.\d+)?)\s*만(?:\s*(?P<cheon>\d+)\s*천)?\s*원?"  # 15만, 21만 6천, 1.5만
    r"|(?P<cheon_only>\d+)\s*천\s*원"  # 5천 원
    r"|(?P<won>\d{1,3}(?:,\d{3})+|\d+)\s*원"  # 216,000원, 990원
)


def amounts_in(text: str) -> set[int]:
    found: set[int] = set()
    for m in _AMOUNT.finditer(text):
        if m.group("man"):
            v = float(m.group("man")) * 10000 + (int(m.group("cheon")) * 1000 if m.group("cheon") else 0)
        elif m.group("cheon_only"):
            v = int(m.group("cheon_only")) * 1000
        else:
            v = int(m.group("won").replace(",", ""))
        found.add(int(round(v)))
    return found


def _numbers_in_json(value, out: set[int]) -> None:
    if isinstance(value, bool):
        return
    if isinstance(value, (int, float)):
        out.add(int(round(value)))
    elif isinstance(value, str):
        out.update(amounts_in(value))
    elif isinstance(value, dict):
        for v in value.values():
            _numbers_in_json(v, out)
    elif isinstance(value, list):
        for v in value:
            _numbers_in_json(v, out)


def allowed_numbers(items: list[dict]) -> set[int]:
    """툴 결과와 사용자 메시지에 나온 금액. 표시용 반올림(100원·1만 원 단위 내림)도 허용한다."""
    base: set[int] = set()
    for item in items:
        if item.get("type") == "function_call_output":
            try:
                _numbers_in_json(json.loads(item.get("output", "")), base)
            except json.JSONDecodeError:
                base.update(amounts_in(item.get("output", "")))
        elif item.get("role") == "user":
            content = item.get("content")
            if isinstance(content, str):
                base.update(amounts_in(content))
            elif isinstance(content, list):
                for c in content:
                    if isinstance(c, dict) and isinstance(c.get("text"), str):
                        base.update(amounts_in(c["text"]))
    allowed = set(base)
    for v in base:
        sign = -1 if v < 0 else 1
        a = abs(v)
        allowed |= {sign * (a // 100 * 100), sign * (a // 1000 * 1000), sign * (a // 10000 * 10000), abs(v)}
    return allowed


def unverified_amounts(text: str, items: list[dict]) -> set[int]:
    """답에 나온 금액 중 근거가 없는 것. 0원은 늘 허용."""
    allowed = allowed_numbers(items)
    return {a for a in amounts_in(text) if a != 0 and a not in allowed}


VERDICT_WORDS = {
    "ok": "괜찮아요",
    "conditional": "조건부",
    "postpone": "미루는 걸 추천",
    "next_month": "다음 달",
}


def last_verdict(items: list[dict]) -> str | None:
    """대화에서 마지막으로 실행된 simulate_purchase의 판단."""
    calls = {i.get("call_id"): i.get("name") for i in items if i.get("type") == "function_call"}
    verdict = None
    for i in items:
        if i.get("type") == "function_call_output" and calls.get(i.get("call_id")) == "simulate_purchase":
            try:
                verdict = json.loads(i["output"]).get("verdict")
            except (json.JSONDecodeError, KeyError, AttributeError):
                pass
    return verdict


def verdict_mismatch(text: str, verdict: str | None) -> bool:
    """판단을 코드가 내렸는데 답이 다른 판단을 말하면 True."""
    if verdict is None or verdict not in VERDICT_WORDS:
        return False
    expected = VERDICT_WORDS[verdict]
    others = [w for k, w in VERDICT_WORDS.items() if k != verdict and k != "next_month"]
    first_line = text.strip().splitlines()[0] if text.strip() else ""
    return expected not in text or any(w in first_line for w in others)


FALLBACK = "계산을 확인하지 못했어요. 홈 화면의 숫자를 확인해 주세요."
