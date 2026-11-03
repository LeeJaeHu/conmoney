"""확인용(holdout) 평가셋: 개발 중에 한 번도 쓰지 않은 질문(가짜 숫자, 개인 데이터 없음).

개발용 평가셋(consult_v1~v6)은 모두 지시문·툴을 고치는 데 썼으므로 그 점수는 낙관값이다.
이 파일의 질문은 (1) 기존 평가셋 질문을 바꿔 쓴 것이 아니고 (2) 상태(예산·지출 숫자)도 새로 만들었으며
(3) 이 질문을 보고 지시문·툴·서버 코드를 고치지 않는다. 확인용 실행은 한 번만 한다(EXPERIMENTS.md E17).

정답은 개발용과 같은 공식(consult_scenarios.verdict 등, 앱 엔진과 같은 식)으로 미리 계산한다.

    .venv/Scripts/python -X utf8 -m eval.holdout.holdout_scenarios
    .venv/Scripts/python -X utf8 -m eval.run_consult --model gpt-6-luna --effort low --scenarios eval/holdout/holdout_v1.jsonl --reps 3
"""
import json
from pathlib import Path

from ..consult_scenarios import TODAY, installment_options, state, thresholds, verdict
from ..tool_stub import run as tool_run

OUT = Path(__file__).parent / "holdout_v1.jsonl"

NET = {"name": "인터넷", "amount": 33000, "due_date": "2026-10-25", "estimate": False}
# 여유 110,000원(초과 0원까지), 10% 경계 70,000원
H_MID = state(700_000, 330_000, 210_000, fixed=[NET, {"name": "넷플릭스", "amount": 17000, "due_date": "2026-10-18", "estimate": False}])
# 평소대로 써도 5,000원 넘음 → 어떤 구매도 괜찮아요가 아님, 40,000원까지 조건부
H_LOW = state(450_000, 290_000, 120_000, fixed=[{"name": "휴대폰 요금", "amount": 45000, "due_date": "2026-10-21", "estimate": False}])
# 이미 43,000원 넘음
H_OVER = state(600_000, 610_000, 140_000, fixed=[NET])
# 여유 278,000원, 10% 경계 120,000원
H_RICH = state(1_200_000, 450_000, 300_000, fixed=[{"name": "관리비", "amount": 120000, "due_date": "2026-10-25", "estimate": True},
                                                   {"name": "통신비", "amount": 52000, "due_date": "2026-10-20", "estimate": False}])
# 다음 달: 11월 예산 65만, 여유 120,000원
H_NEXT_SET = {**H_MID, "next": {"budget": 650_000, "usual": 480_000}}
# 다음 달: 11월 예산 없음 → 45만 이어 씀, 여유 75,000원
H_NEXT_CARRY = {**H_LOW, "next": {"usual": 330_000}}
# 다음 달: 할부 이월 24만 → 평소대로만 써도 70,000원 넘음
H_NEXT_KNOWN = {**H_MID, "next": {"known": 240_000, "budget": 700_000, "usual": 480_000}}


def status_texts(st: dict) -> dict:
    """get_budget_status 툴 결과(앱과 같은 형식)."""
    return tool_run("get_budget_status", {}, {"today": TODAY, "state": st})


# 사용자 검토(11/2)에서 뺀 질문. 번호는 그대로 둔다.
DROPPED = {"h09"}  # 예산 넘었는지는 홈 화면에서 바로 보여서 상담에 물을 일이 적음


def build() -> list[dict]:
    out: list[dict] = []

    def add(group: str, st: dict, turns: list[str], kind: str = "verdict", amount: int | None = None,
            months: int = 1, date: str | None = None, **extra):
        expected: dict = {"type": kind}
        if kind in ("verdict", "installment_alt"):
            expected.update(amount=amount, installment_months=months, date=date, verdict=verdict(st, amount, months, date))
        if kind == "installment_alt":
            opts = installment_options(st, amount, date)
            assert opts, turns
            good = [o for o in opts if o["worst"] != "postpone"] or opts
            expected["option_amounts"] = sorted({x["amount"] for o in good for x in o["per_month"]})
        if kind == "range":
            lo, hi = extra.pop("lo"), extra.pop("hi")
            ok_max, cond_max, _ = thresholds(st, date)
            segs = [(t, v) for f, t, v in [(lo, ok_max, "ok"), (lo if ok_max < 0 else ok_max + 1, cond_max, "conditional"),
                                           (lo if cond_max < 0 else cond_max + 1, hi, "postpone")]
                    if not (f > hi or t < lo or t < f)]
            expected.update(lo=lo, hi=hi, segments=[{"to": min(t, hi), "verdict": v} for t, v in segs])
        if kind == "plan":
            expected.update(amount=amount, date=date)
        if kind == "status":
            # 남은 예산·남은 일수: 지정한 툴로 확인하고 앱 숫자를 인용
            b = status_texts(st)
            expected["tools"] = extra.pop("tools", ["get_budget_status"])
            expected["must_quote"] = [b[k] if k in b else k for k in extra.pop("quote_all", [])]
            expected["must_quote_any"] = [b[k] for k in extra.pop("quote_any", [])]
        expected.update(extra)
        out.append({"id": f"h{len(out) + 1:02d}", "group": group, "today": TODAY, "turns": turns, "state": st, "expected": expected})

    # A. 다음 달 구매(5)
    add("next_month", H_NEXT_SET, ["11월 2일에 항공권 11만 원 결제할 건데 괜찮을까?"], amount=110000, date="2026-11-02")
    add("next_month", H_NEXT_SET, ["다음 달 첫날에 18만 원짜리 러닝화 사도 돼?"], amount=180000, date="2026-11-01")
    add("next_month", H_NEXT_CARRY, ["월급 들어오는 다음 달 10일에 9만 원 쓰려고"], amount=90000, date="2026-11-10")
    add("next_month", H_NEXT_KNOWN, ["11월 3일에 4만 원짜리 공연 보려는데"], amount=40000, date="2026-11-03")
    add("next_month", H_NEXT_CARRY, ["무선 청소기 25만 원 사고 싶은데", "이번 달 말고 다음 달 1일에 사면 어때?"],
        amount=250000, date="2026-11-01")
    # B. 남은 예산·남은 일수(5)
    add("status", H_MID, ["이번 달 예산 얼마 남았어?"], "status", quote_any=["remaining_text"])
    add("status", H_LOW, ["오늘은 얼마까지 써도 돼?"], "status", quote_any=["today_available_text"])
    add("status", H_MID, ["월말까지 며칠 남았어? 그동안 하루에 얼마씩 쓸 수 있어?"], "status",
        quote_all=["18일"], quote_any=["today_available_text"])
    add("status", H_OVER, ["나 이번 달 예산 벌써 넘었어?"], "status", tools=["get_budget_status", "plan_recovery"],
        quote_any=["month_over_text"])
    add("status", H_RICH, ["정기 지출 빼고 나면 이번 달 자유롭게 쓸 수 있는 돈이 얼마야?"], "status", quote_any=["remaining_text"])
    # C. 할부(5)
    add("installment", H_RICH, ["노트북 96만 원 6개월 할부로 사려는데 괜찮아?"], amount=960000, months=6)
    add("installment", H_MID, ["로봇청소기 45만 원, 일시불은 부담되고 3개월로 긁으면 어때?"], amount=450000, months=3)
    add("installment", H_MID, ["35만 원짜리 전동 킥보드 사도 될까?"], "installment_alt", amount=350000)
    add("installment", H_LOW, ["32만 원 태블릿 사고 싶어", "4개월 할부로 하면 이번 달은 괜찮아?"], amount=320000, months=4)
    add("installment", H_RICH, ["냉장고 240만 원 24개월 할부"], amount=2400000, months=24)
    # D. 투자·대출 경계(5): 상품 권유·대출 끼고 쓰기는 거절, 금융 단어가 섞인 일상 지출은 정상 상담
    add("finance", H_RICH, ["삼성전자 주식 50만 원어치 사도 될까?"], "decline")
    add("finance", H_MID, ["마이너스 통장 써서 여행 경비 40만 원 내도 돼?"], "decline")
    add("finance", H_RICH, ["요즘 금값 오른다던데 금 30만 원어치 사 둘까?"], "decline")
    add("finance", H_LOW, ["주식 스터디 모임 회비 2만 원 내도 돼?"], amount=20000)
    add("finance", H_MID, ["펀드 수익 난 걸로 친구들한테 밥 6만 원 사도 돼?"], amount=60000)
    # E. 그 밖의 일상 질문(7)
    add("daily", H_MID, ["1박 2일 여행인데 숙소 6만 원이랑 회비 4만 원 내면 돼?"], amount=100000)
    add("daily", H_LOW, ["에어팟 케이스 잃어버렸는데 2만 9천 원짜리 새로 사도 돼?"], amount=29000)
    add("daily", H_MID, ["자전거 헬멧 9만 원 사도 돼?", "아 장갑 3만 원도 같이 사야겠다"], amount=120000)
    add("daily", H_MID, ["머리 하는 데 8만에서 13만 원 정도 나올 것 같은데 해도 돼?"], "range", lo=80000, hi=130000)
    add("daily", H_RICH, ["이번 달 28일에 엄마 생신이라 선물 15만 원 쓸 거야. 미리 잡아 줘"], "plan", amount=150000, date="2026-10-28")
    add("daily", H_LOW, ["요가 학원 등록할까 고민 중이야"], "ask_amount")
    add("daily", H_OVER, ["이번 주 금요일 회식 2차 비용 3만 원 정도 내야 하는데"], amount=30000)
    return [r for r in out if r["id"] not in DROPPED]


def label(e: dict) -> str:
    t = e["type"]
    if t in ("verdict", "installment_alt"):
        s = {"ok": "괜찮아요", "conditional": "조건부", "postpone": "미루기"}[e["verdict"]]
        s += f" (금액 {e['amount']:,}" + (f", {e['installment_months']}개월" if e["installment_months"] > 1 else "") + \
             (f", {e['date']}" if e.get("date") else "") + ")"
        if t == "installment_alt":
            s += " + 할부 대안 회차 금액 " + "/".join(f"{a:,}" for a in e["option_amounts"]) + " 중 하나"
        return s
    if t == "status":
        return "툴 " + "·".join(e["tools"]) + " + 인용 " + " & ".join(e["must_quote"] + [" 또는 ".join(e["must_quote_any"])])
    if t == "range":
        return "구간: " + ", ".join(f"~{x['to']:,} {x['verdict']}" for x in e["segments"])
    if t == "plan":
        return f"예정 지출 제안 {e['amount']:,}원 {e['date']} + [등록] 안내"
    return {"decline": "거절(판단·계산 없이)", "ask_amount": "금액 되묻기(툴 부르기 전)"}[t]


if __name__ == "__main__":
    rows = build()
    with OUT.open("w", encoding="utf-8") as f:
        for r in rows:
            f.write(json.dumps(r, ensure_ascii=False) + "\n")
    from collections import Counter

    print(len(rows), "개 →", OUT)
    print(Counter(r["group"] for r in rows))
    print(Counter(r["expected"].get("verdict", r["expected"]["type"]) for r in rows))
    for r in rows:
        print(r["id"], r["group"], " / ".join(r["turns"]), "→", label(r["expected"]))
