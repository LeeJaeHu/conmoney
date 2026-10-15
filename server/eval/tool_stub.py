"""평가용 툴 실행기. 앱의 AgentToolbox(app/lib/core/agent_tools.dart)와 같은 키·형식으로 시나리오 숫자에서 결과를 만든다."""
from .consult_scenarios import first_installment, verdict


def won(v: int) -> str:
    return f"{'-' if v < 0 else ''}{abs(v):,}원"


def _money(key: str, v: int) -> dict:
    return {key: v, f"{key}_text": won(v)}


def run(name: str, args: dict, scenario: dict) -> dict:
    st = scenario["state"]
    fixed = sum(f["amount"] for f in st["fixed"])
    remaining = st["budget"] - st["spent"] - fixed
    if name == "get_budget_status":
        return {
            "today": scenario["today"],
            **_money("budget", st["budget"]),
            **_money("spent", st["spent"]),
            **_money("upcoming_fixed", fixed),
            **_money("remaining", remaining),
            "days_left": st["days_left"],
            **_money("today_available", st["today_available"]),
            **_money("today_over", 0),
            **_money("month_over", max(0, -remaining)),
        }
    if name == "get_upcoming_fixed":
        items = [
            {"name": f["name"], "amount": f["amount"], "amount_text": ("약 " if f["estimate"] else "") + won(f["amount"]),
             "due_date": f["due_date"]}
            for f in st["fixed"]
        ]
        return {"days": args.get("days", 7), "items": items, **_money("total", fixed)}
    if name == "get_spending_pattern":
        return {"window": args.get("window", "rest_of_month"), **_money("median", st["pattern"]), "months_used": 3,
                "source": "history", "note": "특이 지출·정기 지출 제외. 지난 몇 달의 같은 남은 기간 소비 중앙값"}
    if name == "simulate_purchase":
        parts = [int(x) for x in (args.get("amounts") or [])]
        amount = sum(parts) if parts else int(args["amount"])
        if amount <= 0:
            return {"error": "금액을 모르면 이 툴을 부르지 말고 사용자에게 금액을 물어보세요."}
        months = int(args.get("installment_months") or 1)
        this_month = first_installment(amount, months)
        projected = st["spent"] + fixed + st["pattern"] + this_month
        return {
            "verdict": verdict(st, amount, months, args.get("date")),
            "rule": "예상 월말 지출 ≤ 예산이면 ok, 초과액이 예산의 10% 이하면 conditional, 그 이상이면 postpone",
            **_money("amount", amount),
            **({"parts_text": " + ".join(won(p) for p in parts)} if len(parts) > 1 else {}),
            "installment_months": months,
            **_money("remaining_after", remaining - this_month),
            **_money("today_available_after", max(0, st["today_available"] - this_month)),
            **_money("projected_month_end", projected),
            **_money("projected_over", projected - st["budget"]),
            **_money("usual_rest_of_month", st["pattern"]),
            **_money("budget", st["budget"]),
        }
    if name == "get_category_summary":
        return {"period": args.get("period", "this_month"), **_money("total", st["spent"]),
                "categories": st.get("categories") or [{"category": "식비", **_money("total", st["spent"] * 45 // 100), "count": 20},
                                                       {"category": "쇼핑", **_money("total", st["spent"] * 25 // 100), "count": 8}]}
    return {"error": f"unknown tool {name}"}
