import json

import pytest
from fastapi.testclient import TestClient

from app import guard, llm, main
from app.config import Settings

S = Settings(
    app_token="t" * 20, openai_model_agent="gpt-6.1-sol", openai_reasoning_agent="low",
    openai_model_light="gpt-6-luna", openai_reasoning_light="none", jev_api_key="k", jev_base_url="https://x",
    jev_model="jev-latest", jev_min_confidence=0.8, monthly_budget_krw=10000, usd_krw=1400, debug=False,
)
H = {"x-app-token": S.app_token}
U = llm.Usage("gpt-6.1-sol", 1000, 200)


@pytest.fixture
def client():
    return TestClient(main.create_app(S))


def test_토큰_없으면_거절(client):
    assert client.post("/v1/categorize", json={"merchant": "a", "categories": ["식비"]}).status_code == 401


def test_분류_jev_확신도_낮으면_ambiguous(client, monkeypatch):
    monkeypatch.setattr(llm, "jev_classify", lambda s, m, c: llm.Classification("쇼핑", 0.55, "jev-1.13.0", None))
    r = client.post("/v1/categorize", json={"merchant": "네이버페이", "categories": ["식비", "쇼핑"]}, headers=H).json()
    assert r == {"category": "쇼핑", "confidence": 0.55, "ambiguous": True, "model": "jev-1.13.0"}


def test_분류_jev_실패하면_대비책_목록_밖이면_NONE(client, monkeypatch):
    def boom(*a):
        raise TimeoutError()
    monkeypatch.setattr(llm, "jev_classify", boom)
    monkeypatch.setattr(llm, "openai_classify", lambda s, m, c: llm.Classification("식비", None, "gpt-6-luna", None))
    r = client.post("/v1/categorize", json={"merchant": "김밥천국", "categories": ["식비"]}, headers=H).json()
    assert r["category"] == "식비" and r["ambiguous"] is True
    monkeypatch.setattr(llm, "openai_classify", lambda s, m, c: llm.Classification("투자", None, "gpt-6-luna", None))
    assert client.post("/v1/categorize", json={"merchant": "x", "categories": ["식비"]}, headers=H).json()["category"] == "NONE"


def test_범위_밖_질문은_LLM_없이_거절(client, monkeypatch):
    monkeypatch.setattr(llm, "openai_agent", lambda *a: pytest.fail("LLM을 부르면 안 됨"))
    r = client.post("/v1/agent", json={"items": [{"role": "user", "content": "비트코인 사도 돼?"}]}, headers=H).json()
    assert r["status"] == "final" and r["text"] == guard.REFUSAL


def test_툴_호출을_앱에_돌려준다(client, monkeypatch):
    call = {"type": "function_call", "call_id": "c1", "name": "simulate_purchase", "arguments": '{"amount":150000}'}
    monkeypatch.setattr(llm, "openai_agent", lambda *a: llm.AgentTurn([call], "", U))
    r = client.post("/v1/agent", json={"items": [{"role": "user", "content": "키보드 15만 원 살까?"}]}, headers=H).json()
    assert r["status"] == "tool_calls"
    assert r["tool_calls"] == [{"call_id": "c1", "name": "simulate_purchase", "arguments": '{"amount":150000}'}]


ITEMS = [
    {"role": "user", "content": "키보드 15만 원 살까?"},
    {"type": "function_call", "call_id": "c1", "name": "simulate_purchase", "arguments": "{}"},
    {"type": "function_call_output", "call_id": "c1",
     "output": json.dumps({"verdict": "postpone", "remaining_after_text": "66,000원", "remaining_after": 66000})},
]


def _msg(text):
    return {"type": "message", "role": "assistant", "content": [{"type": "output_text", "text": text}]}


def test_숫자_검증_실패하면_다시_생성(client, monkeypatch):
    texts = iter(["[판단] 미루는 걸 추천\n남은 예산 70,000원", "[판단] 미루는 걸 추천\n남은 예산 66,000원"])
    monkeypatch.setattr(llm, "openai_agent", lambda *a: (t := next(texts), llm.AgentTurn([_msg(t)], t, U))[1])
    r = client.post("/v1/agent", json={"items": ITEMS, "round": 2}, headers=H).json()
    assert r["status"] == "final" and r["verified"] is True and "66,000원" in r["text"]
    assert r["verdict"] == "postpone"


def test_두_번_실패하면_숫자_없는_대체_문구(client, monkeypatch):
    monkeypatch.setattr(llm, "openai_agent", lambda *a: llm.AgentTurn([_msg("[판단] 괜찮아요")], "[판단] 괜찮아요", U))
    r = client.post("/v1/agent", json={"items": ITEMS, "round": 2}, headers=H).json()
    assert r["text"] == guard.FALLBACK and r["verified"] is False


def test_라운드_초과(client):
    assert client.post("/v1/agent", json={"items": ITEMS, "round": 6}, headers=H).status_code == 400
