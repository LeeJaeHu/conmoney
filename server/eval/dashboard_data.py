"""평가 리포트 대시보드용 집계 파일(CSV) 생성. 수치만 담는다(가맹점 이름 등 원본 없음).

    .venv/Scripts/python -X utf8 -m eval.dashboard_data

출력: eval/dashboard/*.csv
"""
import csv
import json
from pathlib import Path

ROOT = Path(__file__).parent
RUNS = ROOT / "runs"
OUT = ROOT / "dashboard"
DATA = ROOT.parent.parent / "data"

PROMPT_LABEL = {"36a0b422": "v1", "e6f9c3f0": "v2 (오늘 날짜 추가)", "dbfec513": "v3 (합산은 코드, 범위 판단)"}
CONFIG_ORDER = ["gpt-6-luna / none", "gpt-6-luna / low", "gpt-6.1-sol / low", "gpt-6.1-sol / medium"]


def write(name: str, rows: list[dict]) -> None:
    OUT.mkdir(exist_ok=True)
    with (OUT / name).open("w", newline="", encoding="utf-8") as f:
        w = csv.DictWriter(f, fieldnames=list(rows[0]))
        w.writeheader()
        w.writerows(rows)
    print(name, len(rows))


def consult(scenarios: str = "consult_v1", prefix: str = "consult") -> None:
    latest: dict[tuple, dict] = {}
    for p in sorted(RUNS.glob("*/summary.json")):
        s = json.loads(p.read_text(encoding="utf-8"))
        if "verdict_acc" in s and s["prompt_hash"] in PROMPT_LABEL and s["scenarios"] == f"{scenarios}.jsonl":
            latest[(s["model"], s["effort"], s["prompt_hash"])] = s
    runs, groups = [], []
    order = list(PROMPT_LABEL)
    for (model, effort, ph), s in sorted(latest.items(), key=lambda kv: (order.index(kv[0][2]), CONFIG_ORDER.index(f"{kv[0][0]} / {kv[0][1]}"))):
        config = f"{model} / {effort}"
        runs.append({
            "run": f"{config} · {PROMPT_LABEL[ph]}", "config": config, "prompt": PROMPT_LABEL[ph], "n": s["n"],
            "verdict_acc": s["verdict_acc"], "numbers_ok": s["numbers_ok"], "first_pass_ok": s["first_pass_ok"],
            "tool_ok": s["tool_ok"], "consistency": s["consistency"], "fallback_rate": s["fallback_rate"],
            "krw_mean": s["krw_mean"], "latency_p50": s["latency_p50"], "latency_p90": s["latency_p90"],
            "injection_followed": s.get("injection_followed", ""), "tone_mean": s.get("tone_mean", ""),
        })
        for g, v in s["verdict_acc_by_group"].items():
            groups.append({"run": f"{config} · {PROMPT_LABEL[ph]}", "config": config, "prompt": PROMPT_LABEL[ph], "group": g, "verdict_acc": v})
    write(f"{prefix}_runs.csv", runs)
    write(f"{prefix}_groups.csv", groups)


def category() -> None:
    summaries = sorted(RUNS.glob("*_category/summary.json"))
    s = json.loads(summaries[-1].read_text(encoding="utf-8"))
    c = s["cascades"]
    write("category_methods.csv", [
        {"method": "내장 규칙", "accuracy": s["rules"]["acc"], "latency_p50_s": 0, "krw_per_100": 0},
        {"method": "jev", "accuracy": s["jev"]["acc"], "latency_p50_s": s["jev"]["latency_s"]["p50"],
         "krw_per_100": round(s["jev"]["krw_total"] / s["n_merchants"] * 100, 2)},
        {"method": "gpt-6-luna", "accuracy": s["luna"]["acc"], "latency_p50_s": s["luna"]["latency_s"]["p50"],
         "krw_per_100": round(s["luna"]["krw_total"] / s["n_merchants"] * 100, 2)},
        {"method": "규칙 → jev", "accuracy": c["rules→jev"], "latency_p50_s": "", "krw_per_100": ""},
        {"method": "규칙 → luna", "accuracy": c["rules→luna"], "latency_p50_s": "", "krw_per_100": ""},
    ])
    write("jev_calibration.csv", [{"range": b["range"], "share": b["share"], "accuracy": b["acc"]} for b in s["jev"]["calibration"]])

    # 확신도 기준별 적용률·정답률(거래 단위). 건별 결과(data/eval, git 제외)에서 집계만 뽑는다
    src = sorted((DATA / "eval").glob("category_*.jsonl"))[-1]
    saved = [json.loads(line) for line in src.read_text(encoding="utf-8").splitlines() if line.strip()]
    tx = [(x["jev"]["confidence"] or 0, x["jev"]["category"] == label)
          for x in saved for label, cnt in x["labels"].items() for _ in range(cnt)]
    rows = []
    for th in [0.5, 0.6, 0.7, 0.8, 0.85, 0.9, 0.95, 0.98, 0.99]:
        sel = [ok for conf, ok in tx if conf >= th]
        rows.append({"threshold": th, "coverage": round(len(sel) / len(tx), 4), "accuracy": round(sum(sel) / len(sel), 4) if sel else ""})
    write("jev_threshold.csv", rows)
    write("category_meta.csv", [{"n_transactions": s["n_transactions"], "n_merchants": s["n_merchants"],
                                 "n_categories": s["n_categories"], "upper_bound": s["upper_bound_merchant_only"]}])


EXPERIMENTS = [
    ("E1", "10/13", "데이터", "카드사 파일 4종 가져오기 검증", "롯데 5개 파일 합계 5/5 일치, 토스 61건 일치, 앱 엔진 = 분석값"),
    ("E2", "10/13", "계산", "할부 분할 규칙: 원 단위 → 100원 단위 내림", "실제 명세서 4건과 일치"),
    ("E3", "10/13", "문제 정의", "'월말 과소비' 가정 검증", "월말이 가장 큰 달 0/5 → 매일 보는 하루 금액으로 재정의"),
    ("E4", "10/13", "분류", "카테고리 규칙 + 애매한 가맹점 분리", "94.6% → 96.9%"),
    ("E5", "10/13", "정기 지출", "추정형 탐지는 3개월 이상", "오탐 2 → 0, 필수 9개 유지"),
    ("E6", "10/14", "정기 지출", "알림 없는 교통비를 월 예약형으로", "3,100원 × 평일 22일 → 69,000원 미리 뗌"),
    ("E7", "10/14", "상담", "금액·판단 검증 후 재생성, 음수 표현 수정", "실제 모델 4/4 통과"),
    ("E8", "10/14", "비용·지연", "작업별 모델 단계(코드 → jev → LLM)", "jev 0.4초 vs luna 2.8초"),
    ("E10", "10/15", "분류", "jev 확신도 기준 0.8 → 0.95", "≥0.95 정답률 99.7%(거래 65%)"),
    ("E11", "10/15", "상담", "오늘 날짜를 지시문에 추가", "'다음 달' 33~83% → 100%, luna/low = sol"),
    ("E12", "10/15", "상담", "평가셋 v2: 범위 밖 판단을 jev로, 합계는 코드가", "과잉 거절 해소, luna/low v2 98% → 100%"),
]


if __name__ == "__main__":
    consult()
    consult("consult_v2", "consult_v2")
    category()
    write("experiments.csv", [{"id": a, "date": b, "area": c, "change": d, "result": e} for a, b, c, d, e in EXPERIMENTS])
