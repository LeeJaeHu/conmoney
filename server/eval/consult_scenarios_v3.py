"""구매 상담 평가셋 v3: 10/15 기능 — 다음 달 구매는 그 달 예산으로, 비싼 건 2·3개월 할부안, 예정 지출(가짜 숫자).

정답은 consult_scenarios의 같은 공식(verdict, installment_options)으로 계산한다.

    .venv/Scripts/python -X utf8 -m eval.consult_scenarios_v3
"""
import json
from pathlib import Path

from .consult_scenarios import BIG_FIXED, ROOMY, TIGHT, TODAY, installment_options, state, thresholds, verdict

OUT = Path(__file__).parent / "scenarios" / "consult_v3.jsonl"

CARRY = {**TIGHT, "next": {"usual": 400_000}}  # 11월 예산 없음 → 54만 이어 씀, 여유 81,000
NEXT_SET = {**TIGHT, "next": {"budget": 670_000, "usual": 400_000}}  # 11월 예산 67만, 여유 211,000
NEXT_KNOWN = {**TIGHT, "next": {"known": 150_000, "usual": 400_000}}  # 11월 할부 이월 15만 → 이미 초과
GIFT = {"name": "친구 축의금", "kind": "planned", "amount": 100_000, "due_date": "2026-10-24", "estimate": False}
WITH_GIFT = state(800_000, 420_000, 180_000, fixed=[*BIG_FIXED["fixed"], GIFT])  # 여유 -30,300
NEXT_GIFT = {**ROOMY, "next": {"fixed": 59_000 + 200_000, "usual": 600_000}}  # 11월 선물 20만 예정 → 여유 141,000


def build() -> list[dict]:
    out: list[dict] = []

    def add(group: str, st: dict, turns: list[str], kind: str = "verdict", amount: int | None = None,
            months: int = 1, date: str | None = None, **extra):
        expected: dict = {"type": kind}
        if kind in ("verdict", "installment_alt"):
            expected.update(amount=amount, installment_months=months, date=date, verdict=verdict(st, amount, months, date))
        if kind == "installment_alt":
            opts = installment_options(st, amount, date)
            assert opts, (turns, "할부안이 없는 시나리오")
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
        expected.update(extra)
        out.append({"id": f"w{len(out) + 1:02d}", "group": group, "today": TODAY, "turns": turns, "state": st, "expected": expected})

    # A. 다음 달 구매(7): 그 달 예산(없으면 이어 씀)으로 판단, "예산이 없다"고 하지 않기
    add("next_month", CARRY, ["다음 달 1일에 6만 원짜리 운동화 살까?"], amount=60000, date="2026-11-01")
    add("next_month", CARRY, ["11월 10일에 12만 원 쓸 일이 있는데 괜찮아?"], amount=120000, date="2026-11-10")
    add("next_month", NEXT_SET, ["다음 달에 15만 원 키보드 사도 돼? 1일에 살게"], amount=150000, date="2026-11-01")
    add("next_month", NEXT_SET, ["11월 5일에 콘서트 25만 원"], amount=250000, date="2026-11-05")
    add("next_month", NEXT_KNOWN, ["다음 달 3일에 5만 원 써도 될까?"], amount=50000, date="2026-11-03")
    add("next_month", CARRY, ["이번 달엔 빠듯하니까 다음 달 1일에 8만 원 가방 사면?"], amount=80000, date="2026-11-01")
    add("next_month", ROOMY, ["12월 1일에 20만 원 패딩 사도 될까?"], amount=200000, date="2026-12-01")
    # B. 비싼 물건: 일시불이 ok가 아니면 2·3개월 할부안을 대안으로(6)
    add("installment_alt", ROOMY, ["40만 원짜리 의자 살까?"], kind="installment_alt", amount=400000)
    add("installment_alt", TIGHT, ["12만 원 신발 사고 싶어"], kind="installment_alt", amount=120000)
    add("installment_alt", BIG_FIXED, ["30만 원짜리 이어폰 어때?"], kind="installment_alt", amount=300000)
    add("installment_alt", NEXT_SET, ["다음 달 1일에 45만 원 모니터 사려는데"], kind="installment_alt", amount=450000, date="2026-11-01")
    add("installment_alt", ROOMY, ["50만 원 자전거 일시불로 사도 돼?"], kind="installment_alt", amount=500000)
    add("installment_alt", CARRY, ["다음 달 1일에 20만 원 코트 살까?"], kind="installment_alt", amount=200000, date="2026-11-01")
    # C. 예정 지출 등록 제안(5): add_planned_expense를 금액·날짜로 부르고 [등록]을 안내. 날짜 모르면 묻기
    add("plan", ROOMY, ["다음 주 토요일에 친구 결혼식이라 축의금 10만 원 내야 해"], kind="plan", amount=100000, date="2026-10-24")
    add("plan", ROOMY, ["11월 7일에 조카 돌잔치 선물 5만 원 쓸 예정이야. 예산에 넣어줘"], kind="plan", amount=50000, date="2026-11-07")
    add("plan", TIGHT, ["이번 달 31일에 동아리 회비 3만 원 나가"], kind="plan", amount=30000, date="2026-10-31")
    add("plan", ROOMY, ["다음 달 15일 부모님 생신 선물로 20만 원 쓸 거야"], kind="plan", amount=200000, date="2026-11-15")
    add("plan", ROOMY, ["축의금 10만 원 낼 일이 생겼어. 미리 빼 둬"], kind="ask_date")
    # D. 예정 지출이 이미 있는 상태에서 판단(2)
    add("planned_state", WITH_GIFT, ["이번 주에 5만 원 써도 돼?"], amount=50000)
    add("planned_state", NEXT_GIFT, ["다음 달 1일에 15만 원 신발 살까?"], amount=150000, date="2026-11-01")
    # E. 금액 범위를 구간별로(4, 10/15 사용자 요청): "10만 원대"면 되묻지 말고 구간마다 판단
    add("range_split", ROOMY, ["30만 원대 모니터 살까?"], kind="range", lo=300000, hi=400000)
    add("range_split", TIGHT, ["5~10만 원 정도 저녁 먹어도 돼?"], kind="range", lo=50000, hi=100000)
    add("range_split", BIG_FIXED, ["10만 원대 운동화 어때?"], kind="range", lo=100000, hi=200000)
    add("range_split", TIGHT, ["2만 원에서 4만 원 사이 선물 사도 될까?"], kind="range", lo=20000, hi=40000)
    return out


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
        print(r["id"], r["group"], r["turns"][-1][:24], r["expected"].get("verdict", r["expected"]["type"]),
              r["expected"].get("option_amounts", ""), r["expected"].get("segments", ""))
