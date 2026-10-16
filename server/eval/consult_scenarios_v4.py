"""상담 평가셋 v4: 일상 대화형(10/16, 가짜 숫자). 구매 질문이 아닌 "넘었는데 어캄", "어디서 많이 썼어?", 잡담.

정답은 앱 AgentToolbox.planRecovery / compareSpending과 같은 식(eval/tool_stub.py)으로 계산한다.

    .venv/Scripts/python -X utf8 -m eval.consult_scenarios_v4
"""
import json
from pathlib import Path

from .consult_scenarios import BIG_FIXED, OVER, ROOMY, TIGHT, TODAY, state, verdict  # noqa: F401
from .tool_stub import compare, recovery

OUT = Path(__file__).parent / "scenarios" / "consult_v4.jsonl"

# 0원으로 버텨도 이번 달 안에 못 메우는 상태
DEEP = state(540_000, 600_000, 150_000)
# 평소대로 쓰면 넘지만 남은 기간에 덜 쓰면 메울 수 있는 상태
RECOVER = state(540_000, 360_000, 150_000)  # 월말 예상 29,000원 초과
RECOVER2 = state(800_000, 520_000, 180_000, fixed=BIG_FIXED["fixed"])  # 30,300원 초과, 정기 지출 큼
# 식비가 평소보다 크게 많은 달(비교용)
FOOD_HEAVY = {**TIGHT, "compare": {"this_month": [["식비", 180_000, 110_000], ["쇼핑", 60_000, 80_000], ["카페·간식", 30_000, 20_000]],
                                  "last_month": [["식비", 260_000, 250_000], ["쇼핑", 90_000, 140_000], ["게임", 40_000, 0]]}}


def build() -> list[dict]:
    out: list[dict] = []

    def add(group: str, st: dict, turns: list[str], kind: str, **extra):
        expected: dict = {"type": kind, **extra}
        if kind == "recovery":
            r = recovery(st)
            # 질문에 따라 다른 툴로 답해도 맞는 경우(also: [(툴, 인용해야 할 값)])
            expected["also"] = [list(x) for x in extra.get("also", [])]
            expected["status"] = r["status"]
            # 답에 꼭 나와야 하는 툴 숫자(하나 이상)
            keys = {"on_track": [], "recoverable": ["daily_cut_needed_text", "daily_spend_target_text", "projected_over_if_usual_text"],
                    "not_recoverable_this_month": ["over_even_if_zero_spend_text", "projected_over_if_usual_text"]}[r["status"]]
            expected["must_quote_any"] = [r[k] for k in keys]
        if kind == "compare":
            c = compare(st, extra["window"])
            top = c["categories"][0]
            expected.update(top_category=top["category"], top_diff_text=top["diff_text"])
        if kind == "verdict":
            expected.update(installment_months=1, date=None, verdict=verdict(st, extra["amount"]))
        out.append({"id": f"d{len(out) + 1:02d}", "group": group, "today": TODAY, "turns": turns, "state": st, "expected": expected})

    # A. 상황 상담(9): plan_recovery를 부르고 툴 숫자로 답. 사용자가 말한 숫자가 앱과 달라도 앱 숫자 기준
    add("recovery", OVER, ["이번달 16일 남았는데, 예산 2만원 넘음;; 어캄"], "recovery")
    add("recovery", RECOVER, ["이번 달 버틸 수 있을까?"], "recovery")
    add("recovery", DEEP, ["이번 달 완전 망했다... 어떻게 해야 돼"], "recovery")
    add("recovery", ROOMY, ["요즘 좀 많이 쓴 것 같은데 괜찮은 거야?"], "recovery",
        also=[("compare_spending", compare(ROOMY, "this_month")["total_diff_text"])])
    add("recovery", RECOVER2, ["월말까지 하루에 얼마씩 쓰면 돼?"], "recovery",  # 홈 화면의 "오늘 쓸 수 있는 금액"도 맞는 답
        also=[("get_budget_status", f"{RECOVER2['today_available']:,}원")])
    add("recovery", RECOVER2, ["예산 넘을 것 같아 ㅠㅠ 남은 기간 어떻게 아껴?"], "recovery")
    add("recovery", DEEP, ["이미 6만원이나 넘었는데 다음 달은 어떡하지"], "recovery")
    add("recovery", RECOVER, ["이번 달 빠듯한 거 같은데 어디서 줄이면 돼?"], "recovery")
    add("recovery", OVER, ["카드값 너무 많이 나왔어", "그럼 이번 주에 얼마나 줄여야 해?"], "recovery")
    # B. 비교·조회(5)
    add("compare", FOOD_HEAVY, ["이번 달 어디서 많이 썼어?"], "compare", window="this_month")
    add("compare", FOOD_HEAVY, ["평소보다 많이 쓴 거 있어?"], "compare", window="this_month")
    add("compare", FOOD_HEAVY, ["지난달은 평소랑 비교하면 어땠어?"], "compare", window="last_month")
    add("compare", ROOMY, ["이번 달 소비 평소랑 비슷해?"], "compare", window="this_month")
    add("compare", FOOD_HEAVY, ["지난달에 뭐에 돈 제일 많이 늘었어?"], "compare", window="last_month")
    # C. 잡담·감정(4): 툴 없이 짧게, 금액 말하지 않기, 거절하지 않기
    add("chitchat", ROOMY, ["아 배고프다"], "chitchat")
    add("chitchat", TIGHT, ["돈 없어ㅠ"], "chitchat")
    add("chitchat", ROOMY, ["오늘 월급날이다!"], "chitchat")
    add("chitchat", OVER, ["고마워 덕분에 좀 덜 썼어"], "chitchat")
    # D. 섞인 질문(2): 상황 이야기 + 구매 질문이면 구매 판단
    add("mixed", OVER, ["예산 넘어서 우울한데 이번 주말 3만원 써도 돼?"], "verdict", amount=30000)
    add("mixed", TIGHT, ["16일 남았는데 2만원 넘을 것 같아. 그래도 1만원짜리 책 사도 돼?"], "verdict", amount=10000)
    return out


if __name__ == "__main__":
    rows = build()
    with OUT.open("w", encoding="utf-8") as f:
        for r in rows:
            f.write(json.dumps(r, ensure_ascii=False) + "\n")
    from collections import Counter

    print(len(rows), "개 →", OUT)
    print(Counter(r["group"] for r in rows))
    for r in rows:
        e = r["expected"]
        print(r["id"], r["group"], r["turns"][-1][:22], e.get("status") or e.get("top_category") or e.get("verdict") or "", e.get("must_quote_any", ""), e.get("top_diff_text", ""))
