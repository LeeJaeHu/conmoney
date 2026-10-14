"""실제 OpenAI로 상담 흐름을 끝까지 돌려 보는 수동 점검(pytest가 모으지 않음).
툴 결과는 가짜 숫자다. 실제 결제 내역을 보내지 않는다.

    .venv/Scripts/python -X utf8 -m tests.live_agent
"""
import json

from fastapi.testclient import TestClient

from app.config import load
from app.main import create_app

FAKE = {
    "get_budget_status": {
        "budget": 540000, "budget_text": "540,000원", "spent": 300000, "spent_text": "300,000원",
        "upcoming_fixed": 64000, "upcoming_fixed_text": "64,000원", "remaining": 176000, "remaining_text": "176,000원",
        "days_left": 18, "today_available": 9700, "today_available_text": "9,700원",
    },
    "get_upcoming_fixed": {"items": [{"name": "한국전력 전기료", "amount": 50000, "amount_text": "약 50,000원", "due_date": "2026-10-26"}]},
    "get_spending_pattern": {"median": 160000, "median_text": "160,000원", "months_used": 3, "source": "history"},
    "get_category_summary": {"categories": [{"category": "식비", "total": 180000, "total_text": "180,000원"}]},
}


def simulate(args: dict) -> dict:
    amount = args["amount"]
    over = 300000 + 64000 + 160000 + amount - 540000
    verdict = "ok" if over <= 0 else "conditional" if over <= 54000 else "postpone"
    return {
        "verdict": verdict, "amount_text": f"{amount:,}원",
        "remaining_after": 176000 - amount, "remaining_after_text": f"{176000 - amount:,}원",
        "projected_month_end": 524000 + amount, "projected_month_end_text": f"{524000 + amount:,}원",
        "projected_over": over, "projected_over_text": f"{over:,}원",
    }


def run(client: TestClient, token: str, question: str) -> None:
    items: list[dict] = [{"role": "user", "content": question}]
    total = 0.0
    for rnd in range(1, 6):
        r = client.post("/v1/agent", json={"items": items, "round": rnd}, headers={"x-app-token": token}).json()
        total += r["usage"]["krw"] if r.get("usage") else 0
        items += r["items"]
        if r["status"] == "final":
            print(f"\nQ: {question}\n(라운드 {rnd}, 판단 {r.get('verdict')}, 검증 {r.get('verified')}, 약 {total:.1f}원)\n{r['text']}")
            return
        for c in r["tool_calls"]:
            args = json.loads(c["arguments"])
            out = simulate(args) if c["name"] == "simulate_purchase" else FAKE[c["name"]]
            print(f"  tool {c['name']}({args})")
            items.append({"type": "function_call_output", "call_id": c["call_id"], "output": json.dumps(out, ensure_ascii=False)})
    print("라운드 초과")


if __name__ == "__main__":
    s = load()
    client = TestClient(create_app(s))
    for q in ["키보드 15만 원 살까?", "이번 주말에 5만 원 써도 돼?", "삼성전자 주식 살까?", "신발 사고 싶어"]:
        run(client, s.app_token, q)
