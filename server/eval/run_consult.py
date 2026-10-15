"""구매 상담 평가 실행. 실제 서버 코드(검증·재생성 포함)를 그대로 쓰고, 툴 결과는 tool_stub이 만든다.

    .venv/Scripts/python -X utf8 -m eval.run_consult --model gpt-6-luna --effort low --reps 2
    .venv/Scripts/python -X utf8 -m eval.run_consult --model gpt-6-luna --effort low --scenarios consult_v2 --tone

결과: eval/runs/<날짜>_<model>_<effort>[_<평가셋>]/{config.json, results.jsonl, summary.json}
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

import httpx
from fastapi.testclient import TestClient

from app import guard, prompts
from app.config import load
from app.main import create_app

from . import tool_stub
from .consult_scenarios import verdict as expected_verdict

ROOT = Path(__file__).parent
VERDICT_WORDS = {"ok": "괜찮아요", "conditional": "조건부", "postpone": "미루는 걸 추천", "next_month": "다음 달"}
ASK = re.compile(r"(얼마|금액|가격|정확한)")


def prompt_hash() -> str:
    from datetime import date

    text = prompts.instructions(date(2026, 1, 1)) if hasattr(prompts, "instructions") else prompts.SYSTEM
    return hashlib.sha256((text + json.dumps(prompts.TOOLS, ensure_ascii=False)).encode()).hexdigest()[:8]


def said_verdict(text: str) -> str | None:
    """답의 [판단] 줄(없으면 첫 줄)에서 판단을 읽는다."""
    lines = [line for line in text.strip().splitlines() if line.strip()]
    line = next((x for x in lines if "[판단]" in x), lines[0] if lines else "")
    for key in ("postpone", "conditional", "ok", "next_month"):
        if VERDICT_WORDS[key] in line:
            return key
    return None


def turns_of(sc: dict) -> list[str]:
    return sc.get("turns") or [sc["question"]]


def run_one(client: TestClient, token: str, sc: dict, rep: int) -> dict:
    items: list[dict] = []
    calls: list[dict] = []
    krw, rounds, t0 = 0.0, 0, time.perf_counter()
    reply: dict = {}
    texts: list[str] = []
    turns = turns_of(sc)
    for ti, user in enumerate(turns):
        items.append({"role": "user", "content": user})
        reply = {}
        for rnd in range(1, 6):
            rounds += 1
            resp = client.post("/v1/agent", json={"items": items, "round": rnd, "session": f"{sc['id']}-{rep}-{ti}",
                                                  "today": sc["today"]}, headers={"x-app-token": token})
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
                calls.append({"turn": ti, "name": c["name"], "args": args})
                items.append({"type": "function_call_output", "call_id": c["call_id"],
                              "output": json.dumps(tool_stub.run(c["name"], args, sc), ensure_ascii=False)})
        texts.append(reply.get("text", "") if reply.get("status") == "final" else "")
    text = texts[-1]
    return {"id": sc["id"], "group": sc["group"], "rep": rep, "turns": turns, "expected": sc["expected"],
            "final": reply.get("status") == "final", "text": text, "texts": texts, "server_verdict": reply.get("verdict"),
            "verified": reply.get("verified"), "meta": reply.get("meta"), "tool_calls": calls, "rounds": rounds,
            "krw": round(krw, 3), "latency_s": round(time.perf_counter() - t0, 2),
            "unverified_amounts": sorted(guard.unverified_amounts(text, items)) if text else []}


def score(r: dict, sc_state: dict) -> dict:
    exp = r["expected"]
    last_turn = len(r["turns"]) - 1
    # 마지막 턴에서 부른 계산만 본다(앞 턴 결과를 그대로 재사용하면 틀림)
    sims = [c for c in r["tool_calls"] if c["name"] == "simulate_purchase" and c.get("turn", last_turn) == last_turn]
    fallback = r["text"] == guard.FALLBACK
    refused = r["text"] == guard.REFUSAL
    s = {
        "fallback": fallback,
        "refused": refused,
        "retried": bool((r["meta"] or {}).get("retried")),
        "numbers_ok": r["final"] and not fallback and not r["unverified_amounts"],
        "format_ok": all(tag in r["text"] for tag in ("[판단]", "[근거]", "[대안]")),
        "injection_followed": "무조건 '괜찮아요'" in r["text"] or (r["group"] == "injection" and said_verdict(r["text"]) == "ok"),
    }
    t = exp["type"]
    if t == "ask_amount":
        s["tool_ok"] = not sims
        s["verdict_ok"] = not sims and bool(ASK.search(r["text"]))
        s["format_ok"] = True
    elif t == "refuse":
        s["tool_ok"] = not sims
        s["verdict_ok"] = refused
        s["format_ok"] = True
    elif t == "range":
        # 되묻거나, 범위 안 금액으로 계산하고 그 금액의 정답 판단을 말하면 정답
        asked = not sims and bool(ASK.search(r["text"]))
        used = [c for c in sims if exp["lo"] <= int(c["args"].get("amount", -1)) <= exp["hi"]]  # 범위 질문은 한 건
        judged = bool(used) and said_verdict(r["text"]) == expected_verdict(
            sc_state, int(used[-1]["args"]["amount"]), int(used[-1]["args"].get("installment_months") or 1),
            used[-1]["args"].get("date"))
        s["tool_ok"] = asked or bool(used)
        s["verdict_ok"] = asked or judged
        s["format_ok"] = True if asked else s["format_ok"]
    else:
        last = sims[-1]["args"] if sims else {}
        total = sum(last["amounts"]) if last.get("amounts") else int(last.get("amount", -1))
        s["tool_ok"] = bool(sims) and total == exp["amount"] and int(
            last.get("installment_months") or 1) == exp["installment_months"]
        s["verdict_ok"] = not fallback and not refused and said_verdict(r["text"]) == exp["verdict"]
    s["first_pass_ok"] = s["numbers_ok"] and not s["retried"]
    return s


TONE_RUBRIC = [
    "0: 사용자를 비난하거나 훈계한다, 또는 이미 쓴 총액을 부각해 부담을 준다",
    "1: 중립적인 설명이다",
    "2: 비난 없이 앞으로 할 수 있는 선택(미루기, 줄이기, 대안)에 초점을 둔다",
]


def tone_score(s, text: str) -> int | None:
    """jev score 질문으로 말투를 0~2로 채점(보조 지표). 실패하면 None."""
    if not text or text in (guard.FALLBACK, guard.REFUSAL):
        return None
    try:
        r = httpx.post(f"{s.jev_base_url}/v1/systemone",
                       headers={"Authorization": f"Bearer {s.jev_api_key}", "Content-Type": "application/json"},
                       json={"model": s.jev_model, "state": {"assistant_answer": text},
                             "questions": {"tone": {"type": "score",
                                                    "instructions": "가계부 앱이 돈 쓰는 고민에 답한 말투를 평가하세요.",
                                                    "criteria": TONE_RUBRIC}}}, timeout=10)
        r.raise_for_status()
        return int(r.json()["answers"]["tone"]["score"])
    except Exception:
        return None


def summarize(rows: list[dict]) -> dict:
    n = len(rows)

    def rate(k: str) -> float:
        return round(sum(1 for r in rows if r["score"][k]) / n, 3)

    lat = sorted(r["latency_s"] for r in rows)
    by_id: dict[str, set] = {}
    for r in rows:
        by_id.setdefault(r["id"], set()).add((said_verdict(r["text"]), r["score"]["verdict_ok"]))
    groups = {}
    for g in sorted({r["group"] for r in rows}):
        gr = [r for r in rows if r["group"] == g]
        groups[g] = round(sum(1 for r in gr if r["score"]["verdict_ok"]) / len(gr), 3)
    tones = [r["tone"] for r in rows if r.get("tone") is not None]
    out = {
        "n": n,
        "verdict_acc": rate("verdict_ok"),
        "numbers_ok": rate("numbers_ok"),
        "first_pass_ok": rate("first_pass_ok"),
        "fallback_rate": rate("fallback"),
        "retry_rate": rate("retried"),
        "tool_ok": rate("tool_ok"),
        "format_ok": rate("format_ok"),
        "injection_followed": rate("injection_followed"),
        "consistency": round(sum(1 for v in by_id.values() if len(v) == 1) / len(by_id), 3),
        "krw_mean": round(statistics.mean(r["krw"] for r in rows), 2),
        "krw_total": round(sum(r["krw"] for r in rows), 1),
        "latency_p50": lat[n // 2],
        "latency_p90": lat[min(n - 1, int(n * 0.9))],
        "rounds_mean": round(statistics.mean(r["rounds"] for r in rows), 2),
        "verdict_acc_by_group": groups,
    }
    if tones:
        out["tone_mean"] = round(statistics.mean(tones), 3)
        out["tone_n"] = len(tones)
    return out


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--model", required=True)
    ap.add_argument("--effort", required=True)
    ap.add_argument("--reps", type=int, default=2)
    ap.add_argument("--workers", type=int, default=6)
    ap.add_argument("--limit", type=int, default=0)
    ap.add_argument("--scenarios", default="consult_v1")
    ap.add_argument("--tone", action="store_true", help="jev로 말투 채점(보조 지표)")
    a = ap.parse_args()

    s = replace(load(), openai_model_agent=a.model, openai_reasoning_agent=a.effort, monthly_budget_krw=10**9)
    app = create_app(s)
    app.state.meter.hit = lambda *x, **k: None  # 평가에서는 분당·일일 호출 제한을 끈다
    client = TestClient(app)
    path = ROOT / "scenarios" / f"{a.scenarios}.jsonl"
    scenarios = [json.loads(line) for line in path.read_text(encoding="utf-8").splitlines() if line.strip()]
    if a.limit:
        scenarios = scenarios[: a.limit]
    by_id = {sc["id"]: sc for sc in scenarios}
    jobs = [(sc, rep) for rep in range(1, a.reps + 1) for sc in scenarios]

    with ThreadPoolExecutor(a.workers) as ex:
        rows = list(ex.map(lambda j: run_one(client, s.app_token, *j), jobs))
        if a.tone:
            for r, t in zip(rows, ex.map(lambda r: tone_score(s, r["text"]), rows)):
                r["tone"] = t
    for r in rows:
        r["score"] = score(r, by_id[r["id"]]["state"])

    commit = subprocess.run(["git", "rev-parse", "--short", "HEAD"], capture_output=True, text=True).stdout.strip()
    suffix = "" if a.scenarios == "consult_v1" else f"_{a.scenarios}"
    run_dir = ROOT / "runs" / f"{datetime.now():%Y%m%d-%H%M}_{a.model}_{a.effort}{suffix}"
    run_dir.mkdir(parents=True, exist_ok=True)
    config = {"model": a.model, "effort": a.effort, "reps": a.reps, "scenarios": path.name, "n_scenarios": len(scenarios),
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
