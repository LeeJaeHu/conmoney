"""평가용 툴 실행기. 앱의 AgentToolbox(app/lib/core/agent_tools.dart)와 같은 키·형식으로 시나리오 숫자에서 결과를 만든다."""
from .consult_scenarios import TODAY, thresholds, installment_options, is_future, month_over, next_month, split, verdict


def won(v: int) -> str:
    return f"{'-' if v < 0 else ''}{abs(v):,}원"


def _money(key: str, v: int) -> dict:
    return {key: v, f"{key}_text": won(v)}


def recovery(st: dict) -> dict:
    """앱 AgentToolbox.planRecovery와 같은 식."""
    fixed = sum(f["amount"] for f in st["fixed"])
    b, p, days = st["budget"], st["pattern"], st["days_left"]
    over = st["spent"] + fixed + p - b
    target = p - over
    up100 = lambda v: 0 if v <= 0 else (v + 99) // 100 * 100
    down100 = lambda v: 0 if v <= 0 else v // 100 * 100
    rest = st.get("rest_by_cat") or {"식비": p * 45 // 100, "쇼핑": p * 25 // 100, "카페·간식": p * 10 // 100}
    cands = sorted(((k, v) for k, v in rest.items() if v > 0), key=lambda kv: -kv[1])[:3]
    out = {
        **_money("budget", b), **_money("spent", st["spent"]), **_money("upcoming_fixed", fixed), "days_left": days,
        **_money("month_over_now", max(0, -(b - st["spent"] - fixed))), **_money("usual_rest_of_month", p),
        **_money("projected_over_if_usual", over),
        "status": "on_track" if over <= 0 else ("recoverable" if target >= 0 else "not_recoverable_this_month"),
    }
    if over > 0:
        out.update(_money("total_cut_needed", over))
        if target >= 0:
            out.update(**_money("daily_cut_needed", up100((over + days - 1) // days)), **_money("daily_spend_target", down100(target // days)))
        else:
            out.update(_money("over_even_if_zero_spend", -target))
    out["cut_candidates"] = [{"category": k, **_money("usual_rest", v), **_money("half_saves", down100(v // 2))} for k, v in cands]
    out["note"] = "평소대로 쓰면 월말에 얼마나 넘는지 기준. cut_candidates는 지난 몇 달의 같은 남은 기간 카테고리 소비 중앙값(특이 지출 제외, 고정성 지출 제외). 계산된 값만 인용"
    return out


def compare(st: dict, window: str) -> dict:
    """앱 AgentToolbox.compareSpending과 같은 형식. 시나리오의 compare 값(없으면 지출에서 만든 기본값)."""
    sp = st["spent"]
    rows = (st.get("compare") or {}).get(window) or [["식비", sp * 40 // 100, sp * 38 // 100], ["쇼핑", sp * 25 // 100, sp * 27 // 100],
                                                     ["카페·간식", sp * 8 // 100, sp * 8 // 100]]
    rows = sorted(rows, key=lambda r: -(r[1] - r[2]))
    cur, usual = sum(r[1] for r in rows), sum(r[2] for r in rows)
    return {"window": window, **_money("total", cur), **_money("usual_total", usual), **_money("total_diff", cur - usual),
            "categories": [{"category": n, **_money("amount", c), **_money("usual", u), **_money("diff", c - u)} for n, c, u in rows],
            "note": "특이 지출 제외. usual은 지난 몇 달 같은 기간의 카테고리별 중앙값. diff가 양수면 평소보다 많이 씀"}


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
            {"name": f["name"], "kind": f.get("kind", "recurring"), "amount": f["amount"],
             "amount_text": ("약 " if f["estimate"] else "") + won(f["amount"]), "due_date": f["due_date"]}
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
        date = args.get("date")
        future = is_future(date)
        first = split(amount, months)[0]
        over, b = month_over(st, first, future)
        m = int(date[5:7]) if future else int(TODAY[5:7])
        out = {
            "verdict": verdict(st, amount, months, date),
            "rule": "예상 월말 지출 ≤ 예산이면 ok, 초과액이 예산의 10% 이하면 conditional, 그 이상이면 postpone",
            "judged_month": f"{date[:7] if future else TODAY[:7]}",
            "judged_month_text": f"{m}월" if future else f"이번 달({m}월)",
        }
        if future:
            nx = next_month(st)
            out["month_note"] = (f"{m}월 예산이 아직 없어 직전 달 예산을 이어 썼고, 정기 지출 전체·예정 지출·평소 한 달 소비로 예상함"
                                 if nx["budget"] is None else f"{m}월 예산과 정기 지출 전체·예정 지출·평소 한 달 소비로 예상함")
        out.update({
            **_money("amount", amount),
            **({"parts_text": " + ".join(won(p) for p in parts)} if len(parts) > 1 else {}),
            "installment_months": months,
            **_money("remaining_after", (b - nx["known"] - nx["fixed"] if future else remaining) - first),
            **({} if future else _money("today_available_after", max(0, st["today_available"] - first))),
            **_money("projected_month_end", over + b),
            **_money("projected_over", over),
            **(_money("usual_month", nx["usual"]) if future else _money("usual_rest_of_month", st["pattern"])),
            **_money("budget", b),
        })
        opts = installment_options(st, amount, date) if months == 1 else []
        if opts:
            base = int(date[5:7]) if future else int(TODAY[5:7])
            out["installment_options"] = [
                {"months": o["months"], "worst_verdict": o["worst"], "per_month": [
                    {"month": f"{(base + x['k'] - 1) % 12 + 1}월", **_money("amount", x["amount"]), "verdict": x["verdict"],
                     **_money("projected_over", x["over"])} for x in o["per_month"]]}
                for o in opts]
            out["installment_note"] = "2·3개월 무이자 할부는 카드사·가맹점마다 다르므로 결제 전에 카드사 앱에서 확인"
        return out
    if name == "simulate_range":
        lo, hi, date = int(args.get("min") or 0), int(args.get("max") or 0), args.get("date")
        if lo <= 0 or hi < lo:
            return {"error": "min ≤ max인 원 단위 금액 범위가 필요해요."}
        ok_max, cond_max, b = thresholds(st, date)
        segs = []
        for f, t, v in [(lo, ok_max, "ok"), (lo if ok_max < 0 else ok_max + 1, cond_max, "conditional"),
                        (lo if cond_max < 0 else cond_max + 1, hi, "postpone")]:
            if f > hi or t < lo or t < f:
                continue
            segs.append({**_money("up_to", min(t, hi)), "verdict": v})
        m = int(date[5:7]) if is_future(date) else int(TODAY[5:7])
        return {"judged_month_text": f"{m}월" if is_future(date) else f"이번 달({m}월)", **_money("min", lo), **_money("max", hi),
                "segments": segs,
                "note": "일시불 기준. 경계는 1,000원 단위로 내림. 구간은 min부터 순서대로, 각 구간은 up_to까지"}
    if name == "add_planned_expense":
        amount, date = int(args.get("amount") or 0), args.get("date") or ""
        if amount <= 0 or len(date) != 10:
            return {"error": "예정 지출은 금액과 날짜(yyyy-MM-dd)가 필요해요. 사용자에게 물어보세요."}
        return {"status": "needs_user_confirmation", "name": args.get("name", "예정 지출"), **_money("amount", amount), "date": date,
                "note": "아직 등록 안 됨. 사용자가 화면의 [등록] 버튼을 눌러야 예산에 반영된다. 등록 전 계산에는 포함되지 않았다"}
    if name == "plan_recovery":
        return recovery(st)
    if name == "compare_spending":
        return compare(st, args.get("window") or "this_month")
    if name == "get_category_summary":
        return {"period": args.get("period", "this_month"), **_money("total", st["spent"]),
                "categories": st.get("categories") or [{"category": "식비", **_money("total", st["spent"] * 45 // 100), "count": 20},
                                                       {"category": "쇼핑", **_money("total", st["spent"] * 25 // 100), "count": 8}]}
    return {"error": f"unknown tool {name}"}
