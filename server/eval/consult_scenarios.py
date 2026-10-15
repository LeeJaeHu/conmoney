"""구매 상담 평가셋 v1 생성(가짜 숫자, 개인 데이터 없음).

정답 판단은 앱 계산 엔진과 같은 공식으로 미리 계산한다(Spec 3.8):
  이번 달 반영액 = 일시불은 금액, 할부는 1회차(100원 단위 내림, 나머지는 1회차)
  예상 월말 지출 E = 확정 지출 S + 예정 정기 지출 F + 평소 남은 기간 소비 P + 이번 달 반영액
  초과액 = E − 예산 B → ≤ 0 ok / ≤ B×10% conditional / 그 외 postpone.
  구매일이 다음 달 이후면 그 달 기준(10/15): E = 이월 할부 + 정기·예정 지출 전체 + 평소 한 달 소비 + 1회차,
  B = 그 달 예산(없으면 직전 달 예산을 이어 씀)

    .venv/Scripts/python -X utf8 -m eval.consult_scenarios
"""
import json
from pathlib import Path

TODAY = "2026-10-14"  # 10월, 오늘 포함 남은 18일
DAYS_LEFT = 18
OUT = Path(__file__).parent / "scenarios" / "consult_v1.jsonl"


def first_installment(amount: int, months: int) -> int:
    if months <= 1:
        return amount
    rest = amount // months // 100 * 100
    return amount - rest * (months - 1)


def split(amount: int, months: int) -> list[int]:
    if months <= 1:
        return [amount]
    rest = amount // months // 100 * 100
    return [amount - rest * (months - 1)] + [rest] * (months - 1)


def judge(over: int, b: int) -> str:
    if over <= 0:
        return "ok"
    return "conditional" if over <= b // 10 else "postpone"


def month_over(state: dict, part: int, future: bool) -> tuple[int, int]:
    """(그 달에 part를 더했을 때 예상 초과액, 그 달 예산). future면 다음 달 이후 예상(평가에서는 다음 달 이후가 모두 같다고 둔다)."""
    if not future:
        b = state["budget"]
        return state["spent"] + sum(f["amount"] for f in state["fixed"]) + state["pattern"] + part - b, b
    nx = next_month(state)
    b = nx["budget"] or state["budget"]
    return nx["known"] + nx["fixed"] + nx["usual"] + part - b, b


def next_month(state: dict) -> dict:
    """다음 달 이후 예상. budget이 None이면 아직 없음(이번 달 예산을 이어 씀)."""
    nx = state.get("next") or {}
    return {"budget": nx.get("budget"), "known": nx.get("known", 0),
            "fixed": nx.get("fixed", sum(f["amount"] for f in state["fixed"] if f.get("due_date"))),
            "usual": nx.get("usual", state["spent"] + state["pattern"])}


def is_future(date: str | None) -> bool:
    return bool(date) and date[:7] > TODAY[:7]


def verdict(state: dict, amount: int, months: int = 1, date: str | None = None) -> str:
    over, b = month_over(state, split(amount, months)[0], is_future(date))
    return judge(over, b)


def thresholds(state: dict, date: str | None = None) -> tuple[int, int, int]:
    """(ok 최대 금액, conditional 최대 금액, 예산). 1,000원 단위 내림, 해당 금액이 없으면 -1(앱 BudgetEngine.thresholds와 같음)."""
    over0, b = month_over(state, 0, is_future(date))

    def floor(v: int) -> int:
        return -1 if v < 0 else v // 1000 * 1000
    return floor(-over0), floor(b // 10 - over0), b


def installment_options(state: dict, amount: int, date: str | None = None) -> list[dict]:
    """일시불이 ok가 아니면 2·3개월 할부안. 첫 달은 구매 달, 이후는 다음 달 이후 예상."""
    if verdict(state, amount, 1, date) == "ok":
        return []
    out = []
    for n in (2, 3):
        rows = []
        for k, part in enumerate(split(amount, n)):
            over, b = month_over(state, part, is_future(date) or k > 0)
            rows.append({"k": k, "amount": part, "verdict": judge(over, b), "over": over})
        order = ["ok", "conditional", "postpone"]
        out.append({"months": n, "worst": max((x["verdict"] for x in rows), key=order.index), "per_month": rows})
    return out


def slack(state: dict) -> int:
    """이만큼까지 쓰면 정확히 예산에 맞는다(초과액 0)."""
    return state["budget"] - state["spent"] - sum(f["amount"] for f in state["fixed"]) - state["pattern"]


def state(budget: int, spent: int, pattern: int, fixed=None, today_available: int | None = None) -> dict:
    fixed = fixed or [{"name": "통신비", "amount": 59000, "due_date": "2026-10-20", "estimate": False}]
    st = {"budget": budget, "spent": spent, "pattern": pattern, "fixed": fixed, "days_left": DAYS_LEFT}
    remaining = budget - spent - sum(f["amount"] for f in fixed)
    st["today_available"] = today_available if today_available is not None else max(0, remaining // DAYS_LEFT)
    return st


ROOMY = state(1_000_000, 380_000, 260_000)  # slack 301,000
TIGHT = state(540_000, 300_000, 150_000)  # slack 31,000
OVER = state(540_000, 520_000, 120_000)  # slack -159,000
BIG_FIXED = state(
    800_000,
    420_000,
    180_000,
    fixed=[
        {"name": "KT 휴대폰", "amount": 38000, "due_date": "2026-10-16", "estimate": True},
        {"name": "한국전력 전기료", "amount": 52000, "due_date": "2026-10-26", "estimate": True},
        {"name": "교통(후불)(이번 달 남은 예약분)", "amount": 40300, "due_date": None, "estimate": True},
    ],
)  # slack 69,700

ITEMS = ["키보드", "운동화", "무선 이어폰", "겨울 코트", "모니터", "콘서트 티켓", "게임", "책 세트", "가방", "저녁 외식"]


def won(n: int) -> str:
    if n % 10000 == 0:
        return f"{n // 10000}만 원"
    return f"{n:,}원"


def build() -> list[dict]:
    out: list[dict] = []

    def add(group: str, st: dict, question: str, amount: int | None, months: int = 1, date: str | None = None, kind: str = "verdict"):
        expected = {"type": kind}
        if kind == "verdict":
            expected.update(amount=amount, installment_months=months, verdict=verdict(st, amount, months, date))
        out.append({"id": f"c{len(out) + 1:02d}", "group": group, "today": TODAY, "question": question, "state": st, "expected": expected})

    # A. 여유 있음(10)
    for i, amt in enumerate([30000, 50000, 80000, 120000, 150000, 200000, 250000, 15000, 99000, 300000]):
        add("roomy", ROOMY, f"{ITEMS[i]} {won(amt)}짜리 살까?", amt)
    # B. 경계(10): 초과액 0 / 10% / 10%+1 을 여러 상태에서
    for st in (ROOMY, TIGHT, BIG_FIXED):
        s = slack(st)
        tenth = st["budget"] // 10
        add("boundary", st, f"{s:,}원 쓰려는데 괜찮을까?", s)
        add("boundary", st, f"{s + tenth:,}원짜리 사도 돼?", s + tenth)
        add("boundary", st, f"{s + tenth + 1:,}원 결제해도 될까?", s + tenth + 1)
    add("boundary", TIGHT, "2만 원 정도 써도 돼?", 20000)
    # C. 확실히 초과(5)
    for i, amt in enumerate([50000, 100000, 150000, 30000, 200000]):
        add("over", OVER, f"{ITEMS[i]} {won(amt)} 살까 말까?", amt)
    # 빠듯함(5): 일부는 조건부, 일부는 초과
    for i, amt in enumerate([150000, 60000, 400000, 75000, 120000]):
        add("tight", TIGHT, f"{ITEMS[5 + i]}에 {won(amt)} 쓰고 싶은데", amt)
    # D. 큰 정기 지출 직전(5)
    for i, amt in enumerate([40000, 70000, 100000, 60000, 150000]):
        add("fixed_soon", BIG_FIXED, f"{ITEMS[i]} {won(amt)} 사도 될까? 이번 주에 통신비 나가는데", amt)
    # E. 할부(5)
    for amt, months, item in [(900000, 3, "노트북"), (600000, 6, "의자"), (240000, 2, "패딩"), (1200000, 12, "휴대폰"), (330000, 3, "자전거")]:
        add("installment", ROOMY if amt < 1_000_000 else TIGHT, f"{item} {won(amt)} {months}개월 할부로 사도 돼?", amt, months)
    # F. 다음 달 구매(3)
    for amt, date, text in [(300000, "2026-11-01", "다음 달 1일에"), (150000, "2026-11-05", "11월 5일에"), (80000, "2026-11-15", "다음 달 중순에")]:
        add("next_month", TIGHT, f"{text} {won(amt)}짜리 사려고 하는데 괜찮을까?", amt, date=date)
    # G. 금액 없는 질문(4)
    for q in ["운동화 사고 싶어", "이번 주말에 놀러 가도 될까?", "노트북 바꿀까?", "택시 타도 돼?"]:
        add("ask_amount", ROOMY, q, None, kind="ask_amount")
    # H. 다양한 금액 표현(3)
    add("phrasing", ROOMY, "십오만 원짜리 키보드 어때?", 150000)
    add("phrasing", TIGHT, "4만5천원짜리 저녁 먹어도 돼?", 45000)
    add("phrasing", ROOMY, "1.2만원 케이크 살까?", 12000)
    assert len(out) == 50, len(out)
    return out


if __name__ == "__main__":
    rows = build()
    OUT.parent.mkdir(parents=True, exist_ok=True)
    with OUT.open("w", encoding="utf-8") as f:
        for r in rows:
            f.write(json.dumps(r, ensure_ascii=False) + "\n")
    from collections import Counter

    print(len(rows), "개 →", OUT)
    print(Counter(r["group"] for r in rows))
    print(Counter(r["expected"].get("verdict", r["expected"]["type"]) for r in rows))
