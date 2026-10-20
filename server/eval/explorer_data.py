"""판단 탐색기(HTML)용 데이터 묶음. 평가셋(가짜 숫자)과 실행 결과만 담는다(개인 데이터 없음).

    .venv/Scripts/python -X utf8 -m eval.explorer_data

출력: eval/explorer/data.json
"""
import json
from pathlib import Path

from app import prompts

from .dashboard_data import PROMPT_LABEL

ROOT = Path(__file__).parent
OUT = ROOT / "explorer" / "data.json"


def main() -> None:
    cases = {}
    for name in ("consult_v1", "consult_v2", "consult_v3", "consult_v4", "consult_v5"):
        rows = [json.loads(line) for line in (ROOT / "scenarios" / f"{name}.jsonl").read_text(encoding="utf-8").splitlines() if line.strip()]
        for r in rows:
            r.setdefault("turns", [r.pop("question")] if "question" in r else r.get("turns"))
        cases[name] = rows

    runs, results = [], {}
    for d in sorted(p for p in (ROOT / "runs").iterdir() if p.is_dir() and (p / "results.jsonl").exists()):
        cfg = json.loads((d / "config.json").read_text(encoding="utf-8"))
        if cfg["prompt_hash"] not in PROMPT_LABEL:
            continue
        summ = json.loads((d / "summary.json").read_text(encoding="utf-8"))
        scen = cfg["scenarios"].removesuffix(".jsonl")
        key = d.name
        runs.append({
            "key": key, "model": cfg["model"], "effort": cfg["effort"], "prompt": cfg["prompt_hash"],
            "promptLabel": PROMPT_LABEL[cfg["prompt_hash"]], "scenarios": scen,
            "summary": {k: summ.get(k) for k in ("verdict_acc", "numbers_ok", "first_pass_ok", "tool_ok", "consistency",
                                                 "krw_mean", "latency_p50", "latency_p90", "injection_followed")},
        })
        per: dict[str, list] = {}
        for line in (d / "results.jsonl").read_text(encoding="utf-8").splitlines():
            r = json.loads(line)
            per.setdefault(r["id"], []).append({
                "rep": r["rep"], "turns": r.get("turns") or [r.get("question")], "texts": r.get("texts") or [r["text"]], "serverVerdict": r.get("server_verdict"),
                "verified": r.get("verified"), "meta": r.get("meta"), "calls": r["tool_calls"], "rounds": r["rounds"],
                "krw": r["krw"], "latency": r["latency_s"], "score": r["score"], "unverified": r.get("unverified_amounts", []),
            })
        results[key] = per

    out = {
        "cases": cases,
        "runs": runs,
        "results": results,
        "promptNow": prompts.SYSTEM,
        "tools": prompts.TOOLS,
        "threshold": [dict(zip(("threshold", "coverage", "accuracy"), map(float, row.split(","))))
                      for row in (ROOT / "dashboard" / "jev_threshold.csv").read_text(encoding="utf-8").splitlines()[1:]],
    }
    OUT.parent.mkdir(exist_ok=True)
    OUT.write_text(json.dumps(out, ensure_ascii=False), encoding="utf-8")
    print(OUT, round(OUT.stat().st_size / 1024), "KB", len(runs), "runs")


if __name__ == "__main__":
    main()
