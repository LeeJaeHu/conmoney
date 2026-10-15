"""여러 상담 평가 실행(eval/runs/*/summary.json)을 표 하나로 합친다.

    .venv/Scripts/python -X utf8 -m eval.report            # 가장 최근 실행을 설정별로 하나씩
    .venv/Scripts/python -X utf8 -m eval.report --all      # 모든 실행
    .venv/Scripts/python -X utf8 -m eval.report --scenarios consult_v2
"""
import json
import sys
from pathlib import Path

RUNS = Path(__file__).parent / "runs"

COLS = [
    ("설정", lambda s: f"{s['model']} / {s['effort']}"),
    ("지시문", lambda s: s["prompt_hash"]),
    ("판단 일치", lambda s: f"{s['verdict_acc']:.0%}"),
    ("숫자 정확(최종)", lambda s: f"{s['numbers_ok']:.0%}"),
    ("첫 답에 바로 정확", lambda s: f"{s['first_pass_ok']:.0%}"),
    ("대체 문구", lambda s: f"{s['fallback_rate']:.0%}"),
    ("툴 호출 정확", lambda s: f"{s['tool_ok']:.0%}"),
    ("형식", lambda s: f"{s['format_ok']:.0%}"),
    ("2회 일관성", lambda s: f"{s['consistency']:.0%}"),
    ("평균 비용", lambda s: f"{s['krw_mean']:.1f}원"),
    ("지연 p50 / p90", lambda s: f"{s['latency_p50']:.1f}s / {s['latency_p90']:.1f}s"),
    ("평균 라운드", lambda s: f"{s['rounds_mean']:.1f}"),
    ("지시문 추종", lambda s: f"{s['injection_followed']:.0%}" if "injection_followed" in s else "-"),
    ("말투(0~2)", lambda s: f"{s['tone_mean']:.2f}" if "tone_mean" in s else "-"),
]


def load(all_runs: bool, scenarios: str = "consult_v1") -> list[dict]:
    rows = []
    for p in sorted(RUNS.glob("*/summary.json")):
        s = json.loads(p.read_text(encoding="utf-8"))
        if "verdict_acc" not in s or s["scenarios"] != f"{scenarios}.jsonl":  # 분류 평가·다른 평가셋 제외
            continue
        s["_run"] = p.parent.name
        rows.append(s)
    if all_runs:
        return rows
    latest: dict[tuple, dict] = {}
    for s in rows:
        latest[(s["model"], s["effort"], s["prompt_hash"])] = s
    return list(latest.values())


def table(rows: list[dict]) -> str:
    head = "| " + " | ".join(c for c, _ in COLS) + " |"
    sep = "|" + "---|" * len(COLS)
    body = ["| " + " | ".join(f(s) for _, f in COLS) + " |" for s in rows]
    groups = sorted({g for s in rows for g in s["verdict_acc_by_group"]})
    gh = "| 설정 | " + " | ".join(groups) + " |"
    gsep = "|" + "---|" * (len(groups) + 1)
    gbody = [
        f"| {s['model']} / {s['effort']} ({s['prompt_hash']}) | " + " | ".join(f"{s['verdict_acc_by_group'].get(g, 0):.0%}" for g in groups) + " |"
        for s in rows
    ]
    meta = sorted({(s["scenarios"], s["reps"], s["n"]) for s in rows})
    note = "; ".join(f"평가셋 {a}, 반복 {b}회, 설정당 {c}건" for a, b, c in meta)
    return "\n".join([head, sep, *body, "", "묶음별 판단 일치", "", gh, gsep, *gbody, "", f"({note})"])


if __name__ == "__main__":
    scen = sys.argv[sys.argv.index("--scenarios") + 1] if "--scenarios" in sys.argv else "consult_v1"
    print(table(load("--all" in sys.argv, scen)))
