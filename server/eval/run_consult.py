"""구매 상담 평가 실행. 실제 서버 코드(검증·재생성 포함)를 그대로 쓰고, 툴 결과는 tool_stub이 만든다.

    .venv/Scripts/python -X utf8 -m eval.run_consult --model gpt-6-luna --effort none --reps 2

결과: eval/runs/<날짜>_<model>_<effort>/{config.json, results.jsonl, summary.json}
"""
import argparse
import hashlib
import json
import re
import statistics
import subprocess
import time
from concurrent.futures import ThreadPoolExecutor
from dataclasses import replace
from datetime import datetime
from pathlib import Path

from fastapi.testclient import TestClient

from app import guard, prompts
from app.config import load
from app.main import create_app

from . import tool_stub

ROOT = Path(__file__).parent
SCENARIOS = ROOT / "scenarios" / "consult_v1.jsonl"
VERDICT_WORDS = {"ok": "괜찮아요", "conditional": "조건부", "postpone": "미루는 걸 추천", "next_month": "다음 달"}


def prompt_hash() -> str:
    from datetime import date

    text = prompts.instructions(date(2026, 1, 1)) if hasattr(prompts, "instructions") else prompts.SYSTEM
    return hashlib.sha256((text + json.dumps(prompts.TOOLS, ensure_ascii=False)).encode()).hexdigest()[:8]


def said_verdict(text: str) -> str | None:
    """답의 첫 줄(또는 [판단] 줄)에서 판단을 읽는다."""
    lines = [l for l in text.strip().splitlines() if l.strip()]
    line = next((l for l in lines if "[판단]" in l), lines[0] if lines else "")
    for key in ("postpone", "conditional", "ok", "next_month"):
        if VERDICT_WORDS[key] in line:
            return key
    return None


def run_one(client: TestClient, token: str, sc: dict, rep: int) -> dict:
    items: list[dict] = [{"role": "user", "content": sc["question"]}]
    calls: list[dict] = []
    krw, rounds, t0 = 0.0, 0, time.perf_counter()
    reply: dict = {}
    for rnd in range(1, 6):
        rounds = rnd
        resp = client.post("/v1/agent", json={"items": items, "round": rnd, "session": f"{sc['id']}-{rep}", "today": sc["today"]},
                           headers={"x-app-token": token})
        if resp.status_code != 200:  # 서버 오류도 결과로 남긴다
            reply = {"status": f"http_{resp.status_code}", "items": [], "tool_calls": []}
            break
        reply = resp.json()
        krw += (reply.get("usage") or {}).get("krw") or 0
        items += reply["items"]
        if reply["status"] == "final":
            break
        for c in reply["tool_calls"]:
            args = json.loads(c["arguments"])
            calls.append({"name": c["name"], "args": args})
            items.append({"type": "function_call_output", "call_id": c["call_id"],
                          "output": json.dumps(tool_stub.run(c["name"], args, sc), ensure_ascii=False)})
    latency = time.perf_counter() - t0
    text = reply.get("text", "") if reply.get("status") == "final" else ""
    return {"id": sc["id"], "group": sc["group"], "rep": rep, "question": sc["question"], "expected": sc["expected"],
            "final": reply.get("status") == "final", "text": text, "server_verdict": reply.get("verdict"),
            "verified": reply.get("verified"), "meta": reply.get("meta"), "tool_calls": calls, "rounds": rounds,
            "krw": round(krw, 3), "latency_s": round(latency, 2),
            "unverified_amounts": sorted(guard.unverified_amounts(text, items)) if text else []}


def score(r: dict) -> dict:
    exp = r["expected"]
    sims = [c for c in r["tool_calls"] if c["name"] == "simulate_purchase"]
    fallback = r["text"] == guard.FALLBACK
    s = {
        "fallback": fallback,
        "retried": bool((r["meta"] or {}).get("retried")),
        "numbers_ok": r["final"] and not fallback and not r["unverified_amounts"],
        "format_ok": all(tag in r["text"] for tag in ("[판단]", "[근거]", "[대안]")),
    }
    if exp["type"] == "ask_amount":
        s["tool_ok"] = not sims
        s["verdict_ok"] = not sims and bool(re.search(r"(얼마|금액|가격)", r["text"]))
        s["format_ok"] = True
    else:
        last = sims[-1]["args"] if sims else {}
        s["tool_ok"] = bool(sims) and int(last.get("amount", -1)) == exp["amount"] and int(
            last.get("installment_months") or 1) == exp["installment_months"]
        s["verdict_ok"] = not fallback and said_verdict(r["text"]) == exp["verdict"]
    s["first_pass_ok"] = s["numbers_ok"] and not s["retried"]
    return s


def summarize(rows: list[dict]) -> dict:
    n = len(rows)
    rate = lambda k: round(sum(1 for r in rows if r["score"][k]) / n, 3)
    lat = sorted(r["latency_s"] for r in rows)
    by_id: dict[str, set] = {}
    for r in rows:
        by_id.setdefault(r["id"], set()).add(said_verdict(r["text"]) if r["expected"]["type"] != "ask_amount" else r["score"]["verdict_ok"])
    groups = {}
    for g in sorted({r["group"] for r in rows}):
        gr = [r for r in rows if r["group"] == g]
        groups[g] = round(sum(1 for r in gr if r["score"]["verdict_ok"]) / len(gr), 3)
    return {
        "n": n,
        "verdict_acc": rate("verdict_ok"),
        "numbers_ok": rate("numbers_ok"),
        "first_pass_ok": rate("first_pass_ok"),
        "fallback_rate": rate("fallback"),
        "retry_rate": rate("retried"),
        "tool_ok": rate("tool_ok"),
        "format_ok": rate("format_ok"),
        "consistency": round(sum(1 for v in by_id.values() if len(v) == 1) / len(by_id), 3),
        "krw_mean": round(statistics.mean(r["krw"] for r in rows), 2),
        "krw_total": round(sum(r["krw"] for r in rows), 1),
        "latency_p50": lat[n // 2],
        "latency_p90": lat[min(n - 1, int(n * 0.9))],
        "rounds_mean": round(statistics.mean(r["rounds"] for r in rows), 2),
        "verdict_acc_by_group": groups,
    }


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--model", required=True)
    ap.add_argument("--effort", required=True)
    ap.add_argument("--reps", type=int, default=2)
    ap.add_argument("--workers", type=int, default=6)
    ap.add_argument("--limit", type=int, default=0)
    a = ap.parse_args()

    s = replace(load(), openai_model_agent=a.model, openai_reasoning_agent=a.effort, monthly_budget_krw=10**9)
    app = create_app(s)
    app.state.meter.hit = lambda *a, **k: None  # 평가에서는 분당·일일 호출 제한을 끈다
    client = TestClient(app)
    scenarios = [json.loads(l) for l in SCENARIOS.read_text(encoding="utf-8").splitlines() if l.strip()]
    if a.limit:
        scenarios = scenarios[: a.limit]
    jobs = [(sc, rep) for rep in range(1, a.reps + 1) for sc in scenarios]

    with ThreadPoolExecutor(a.workers) as ex:
        rows = list(ex.map(lambda j: run_one(client, s.app_token, *j), jobs))
    for r in rows:
        r["score"] = score(r)

    commit = subprocess.run(["git", "rev-parse", "--short", "HEAD"], capture_output=True, text=True).stdout.strip()
    run_dir = ROOT / "runs" / f"{datetime.now():%Y%m%d-%H%M}_{a.model}_{a.effort}"
    run_dir.mkdir(parents=True, exist_ok=True)
    config = {"model": a.model, "effort": a.effort, "reps": a.reps, "scenarios": SCENARIOS.name, "n_scenarios": len(scenarios),
              "prompt_hash": prompt_hash(), "git_commit": commit, "started": datetime.now().isoformat(timespec="seconds")}
    (run_dir / "config.json").write_text(json.dumps(config, ensure_ascii=False, indent=2), encoding="utf-8")
    with (run_dir / "results.jsonl").open("w", encoding="utf-8") as f:
        for r in rows:
            f.write(json.dumps(r, ensure_ascii=False) + "\n")
    summary = {**config, **summarize(rows)}
    (run_dir / "summary.json").write_text(json.dumps(summary, ensure_ascii=False, indent=2), encoding="utf-8")
    print(json.dumps(summary, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
