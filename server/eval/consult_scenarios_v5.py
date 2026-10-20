"""상담 평가셋 v5: AI 소비 분석·아낄 곳·앞으로(10/20, 가짜 숫자).

툴 get_spending_insights의 결과는 앱 core/insights.dart와 같은 형식으로 시나리오에 미리 넣어 둔다(state["insights"]).
정답: 툴 호출 + 1순위 아낄 곳의 월 절약액 인용 + [특징]·[아낄 수 있는 곳]·[앞으로] 형식 + 숫자 검증 통과.

    .venv/Scripts/python -X utf8 -m eval.consult_scenarios_v5
"""
import json
from pathlib import Path

from .consult_scenarios import ROOMY, TIGHT, TODAY

OUT = Path(__file__).parent / "scenarios" / "consult_v5.jsonl"
ASK = "내 소비 패턴과 특징을 분석해 주고, 어디서 아낄 수 있는지와 앞으로 어떻게 하면 좋을지 알려줘"  # 앱 [AI 분석 받기]


def won(v: int) -> str:
    return f"{'-' if v < 0 else ''}{abs(v):,}원"


def m(key: str, v: int) -> dict:
    return {key: v, f"{key}_text": won(v)}


def insights(usual: int, budget: int | None, cats: list, small: tuple, weekend: str, busiest: str, late: str | None,
             fixed: int, cands: list, months: list) -> dict:
    """앱 AgentToolbox.spendingInsights()와 같은 키."""
    out = {"months_used": len(months), "monthly_totals": [{"month": f"{mo}월", **m("total", t)} for mo, t in months],
           **m("usual_month", usual)}
    if budget is not None:
        out.update(**m("budget", budget), **m("gap_to_budget", usual - budget))
    out["categories"] = [{"category": n, **m("usual_monthly", u), "share": sh, **(m("change_3m", ch) if ch is not None else {})}
                         for n, u, sh, ch in cats]
    out["small_purchases"] = {"count_per_month": small[0], **m("total_per_month", small[1]), "note": "1만 원 미만 결제"}
    out.update(weekend_share=weekend, busiest_weekday=busiest)
    if late:
        out["late_night_share"] = late
    out.update(m("fixed_monthly", fixed))
    out["saving_candidates"] = [{"kind": k, **({"category": c} if c else {}), **m("monthly_saving", s), "basis": b}
                                for k, c, s, b in cands]
    if cands:
        top3 = sum(c[2] for c in cands[:3])
        out.update(m("saving_top3_total", top3))
        if budget is not None:
            out.update(m("gap_after_savings", usual - budget - top3))
    out["note"] = "특이 지출 제외. 평소 = 최근 완료 3개월 중앙값. 금액은 이 값만 인용(직접 더하거나 나누지 않기). 가맹점 이름은 없음"
    return out


# 예산보다 크게 많이 씀(실데이터와 비슷한 모양, 숫자는 바꿈)
HEAVY = insights(
    1_052_000, 540_000,
    [("식비", 371_000, "35%", 88_000), ("쇼핑", 266_000, "25%", 104_000), ("구독", 91_000, "9%", 52_000),
     ("통신", 63_000, "6%", 0), ("공과금", 54_000, "5%", 31_000), ("카페·간식", 17_000, "2%", 6_000)],
    (15, 74_000), "22%", "화요일", "14%", 162_000,
    [("categoryLow", "쇼핑", 133_000, "쇼핑: 평소 월 266,000원, 최근 5개월 중 가장 적었던 달 104,000원 수준이면"),
     ("categoryLow", "식비", 41_000, "식비: 평소 월 371,000원, 최근 5개월 중 가장 적었던 달 330,000원 수준이면"),
     ("subscriptions", "구독", 9_100, "구독 10개, 월 91,000원. 하나를 정리하면 평균"),
     ("categoryLow", "카페·간식", 6_800, "카페·간식: 평소 월 17,000원, 최근 5개월 중 가장 적었던 달 10,200원 수준이면")],
    [(5, 812_000), (6, 1_190_000), (7, 1_052_000), (8, 988_000), (9, 1_090_000)],
)
# 예산 안이지만 카페·소액이 늘어남
STEADY = insights(
    482_000, 540_000,
    [("식비", 212_000, "44%", 8_000), ("카페·간식", 61_000, "13%", 24_000), ("교통", 52_000, "11%", 0),
     ("쇼핑", 48_000, "10%", -12_000), ("구독", 31_000, "6%", 0)],
    (22, 68_000), "41%", "토요일", "9%", 96_000,
    [("categoryLow", "카페·간식", 23_000, "카페·간식: 평소 월 61,000원, 최근 6개월 중 가장 적었던 달 38,000원 수준이면"),
     ("smallPurchases", None, 15_000, "1만 원 미만 결제가 월 22건, 합 30,000원. 횟수를 절반으로 줄이면")],
    [(4, 455_000), (5, 470_000), (6, 466_000), (7, 482_000), (8, 501_000), (9, 479_000)],
)
# 크게 줄일 곳이 없음, 예산 미설정
LEAN = insights(
    610_000, None,
    [("식비", 260_000, "43%", -5_000), ("교통", 70_000, "11%", 0), ("통신", 58_000, "10%", 0)],
    (6, 21_000), "28%", "금요일", None, 140_000, [],
    [(7, 620_000), (8, 598_000), (9, 610_000)],
)
NO_DATA_ERR = {"error": "지난달까지 기록이 한 달도 없어 소비 특징을 볼 수 없어요. 과거 기록 가져오기를 먼저 해 주세요."}


def build() -> list[dict]:
    out: list[dict] = []

    def add(group: str, ins: dict, turns: list[str], kind: str, base=TIGHT, **extra):
        st = {**base, "insights": ins}
        exp = {"type": kind, **extra}
        if kind in ("insight_report", "insight_follow") and ins.get("saving_candidates"):
            exp.setdefault("must_quote", ins["saving_candidates"][0]["monthly_saving_text"])
        out.append({"id": f"s{len(out) + 1:02d}", "group": group, "today": TODAY, "turns": turns, "state": st, "expected": exp})

    # A. 분석 리포트(9): 앱 버튼 문장과 일상 표현
    for ins, base in [(HEAVY, TIGHT), (STEADY, ROOMY), (LEAN, ROOMY)]:
        add("report", ins, [ASK], "insight_report", base=base)
        add("report", ins, ["요즘 내 소비 습관 어때?"], "insight_report", base=base)
        add("report", ins, ["어디서 돈을 아낄 수 있을까?"], "insight_report", base=base, tags=False)
    # B. 앞으로(2): 예산과 차이가 클 때 현실적인 계획
    add("plan_ahead", HEAVY, ["앞으로 어떻게 하면 예산 54만 원 맞출 수 있어?"], "insight_report", tags=False,
        must_quote_any=[HEAVY["gap_after_savings_text"], HEAVY["saving_top3_total_text"]])
    add("plan_ahead", STEADY, ["지금처럼 쓰면 괜찮은 거야? 앞으로 뭘 신경 쓰면 돼?"], "insight_report", base=ROOMY, tags=False)
    # C. 이어지는 상담(3): 리포트 뒤 특정 항목 질문
    add("follow", HEAVY, [ASK, "쇼핑은 어떻게 줄이면 좋을까?"], "insight_follow", must_category="쇼핑")
    add("follow", HEAVY, [ASK, "구독은 뭐부터 정리할까?"], "insight_follow", must_category="구독",
        must_quote=HEAVY["saving_candidates"][2]["monthly_saving_text"])
    add("follow", STEADY, [ASK, "카페는 얼마나 줄이면 돼?"], "insight_follow", base=ROOMY, must_category="카페")
    # D. 기록 없음(1)
    add("no_data", NO_DATA_ERR, [ASK], "insight_nodata", base=ROOMY)
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
        print(r["id"], r["group"], r["turns"][-1][:24], r["expected"])
