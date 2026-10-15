"""카테고리 분류 평가: jev vs gpt-6-luna vs 내장 규칙. 정답은 사용자가 검수한 라벨(transactions_v3.csv의 category).

    .venv/Scripts/python -X utf8 -m eval.run_category

- 실제 가맹점 이름을 쓰므로 건별 결과는 git에 없는 data/eval/에만 저장한다.
- git에는 집계 수치(eval/runs/<날짜>_category/summary.json)만 남긴다.
- 정확도는 거래 단위(같은 가맹점 여러 건이면 모두 셈). 가맹점 하나에 정답이 둘 이상인 경우(구글플레이 등)가 있어
  가맹점 이름만 보는 분류의 상한은 100%가 아니다 → "상한"도 함께 계산한다.
"""
import csv
import json
import statistics
import sys
import time
from collections import Counter, defaultdict
from concurrent.futures import ThreadPoolExecutor
from datetime import datetime
from pathlib import Path

from app import llm
from app.config import PRICES, load

ROOT = Path(__file__).parent
DATA = ROOT.parent.parent / "data"
BUCKETS = [(0.95, 1.01), (0.9, 0.95), (0.8, 0.9), (0.6, 0.8), (0.0, 0.6)]


def classify(fn, s, merchant, categories):
    t0 = time.perf_counter()
    try:
        r = fn(s, merchant, categories)
        return {"category": r.category, "confidence": r.confidence, "model": r.model,
                "in_tokens": r.usage.input_tokens if r.usage else 0, "out_tokens": r.usage.output_tokens if r.usage else 0,
                "latency_s": round(time.perf_counter() - t0, 3), "error": None}
    except Exception as e:  # 평가에서는 실패도 결과로 남긴다
        return {"category": None, "confidence": None, "model": None, "in_tokens": 0, "out_tokens": 0,
                "latency_s": round(time.perf_counter() - t0, 3), "error": type(e).__name__}


def main() -> None:
    s = load()
    rows = [r for r in csv.DictReader(open(DATA / "transactions_v3.csv", encoding="utf-8-sig")) if r["category"]]
    categories = sorted({r["category"] for r in rows})
    merchants = sorted({r["merchant"] for r in rows})
    labels = defaultdict(Counter)
    for r in rows:
        labels[r["merchant"]][r["category"]] += 1

    if "--from" in sys.argv:  # 저장된 건별 결과로 다시 집계(API 호출 없음)
        src = Path(sys.argv[sys.argv.index("--from") + 1])
        saved = [json.loads(line) for line in src.read_text(encoding="utf-8").splitlines() if line.strip()]
        jev = {x["merchant"]: x["jev"] for x in saved}
        luna = {x["merchant"]: x["luna"] for x in saved}
        stamp = src.stem.removeprefix("category_")
    else:
        with ThreadPoolExecutor(8) as ex:
            jev = dict(zip(merchants, ex.map(lambda m: classify(llm.jev_classify, s, m, categories), merchants)))
            luna = dict(zip(merchants, ex.map(lambda m: classify(llm.openai_classify, s, m, categories), merchants)))
        stamp = f"{datetime.now():%Y%m%d-%H%M}"
        (DATA / "eval").mkdir(exist_ok=True)
        with (DATA / "eval" / f"category_{stamp}.jsonl").open("w", encoding="utf-8") as f:
            for m in merchants:
                f.write(json.dumps({"merchant": m, "labels": labels[m], "jev": jev[m], "luna": luna[m]}, ensure_ascii=False) + "\n")

    n = len(rows)

    def acc(pred) -> float:
        """pred: 가맹점 → 카테고리 dict, 또는 거래 행 → 카테고리 함수(금액을 보는 규칙용)."""
        f = pred if callable(pred) else (lambda r: pred.get(r["merchant"]))
        return round(sum(1 for r in rows if f(r) == r["category"]) / n, 4)

    def cost_krw(res: dict, key: str) -> float:
        inp, out = PRICES[key]
        return round(sum(v["in_tokens"] * inp + v["out_tokens"] * out for v in res.values()) / 1e6 * s.usd_krw, 2)

    def latency(res: dict) -> dict:
        xs = sorted(v["latency_s"] for v in res.values() if not v["error"])
        return {"p50": xs[len(xs) // 2], "p90": xs[int(len(xs) * 0.9)], "mean": round(statistics.mean(xs), 3)}

    # 확신도 구간별 정답률(거래 단위)과 그 구간에 든 거래 비율
    calib = []
    for lo, hi in BUCKETS:
        sel = [r for r in rows if jev[r["merchant"]]["confidence"] is not None and lo <= jev[r["merchant"]]["confidence"] < hi]
        calib.append({"range": f"[{lo}, {min(hi, 1.0)}]", "share": round(len(sel) / n, 3),
                      "acc": round(sum(1 for r in sel if jev[r["merchant"]]["category"] == r["category"]) / len(sel), 3) if sel else None})
    th = s.jev_min_confidence
    confident = [r for r in rows if (jev[r["merchant"]]["confidence"] or 0) >= th]

    # 규칙은 금액을 보는 것도 있어(구글클라우드·구글플레이) 거래 단위로 평가한다
    def rule(r):
        return r["category_guess"] or None

    def conf(m):
        return jev[m]["confidence"] or 0

    def jev_or_luna(r, th=0.95):
        return jev[r["merchant"]]["category"] if conf(r["merchant"]) >= th else luna[r["merchant"]]["category"]

    uncovered = [r for r in rows if not rule(r)]
    summary = {
        "date": stamp,
        "n_transactions": n,
        "n_merchants": len(merchants),
        "n_categories": len(categories),
        "upper_bound_merchant_only": round(sum(c.most_common(1)[0][1] for c in labels.values()) / n, 4),
        "rules": {"acc": acc(rule), "coverage": round(sum(1 for r in rows if rule(r)) / n, 4),
                  "note": "같은 데이터로 만든 규칙이라 낙관값"},
        "jev": {"model": next((v["model"] for v in jev.values() if v["model"]), None), "acc": acc({m: v["category"] for m, v in jev.items()}),
                "errors": sum(1 for v in jev.values() if v["error"]), "latency_s": latency(jev), "krw_total": cost_krw(jev, "jev"),
                "calibration": calib,
                f"confident_ge_{th}": {"share": round(len(confident) / n, 3),
                                       "acc": round(sum(1 for r in confident if jev[r["merchant"]]["category"] == r["category"]) / len(confident), 3)}},
        "luna": {"model": s.openai_model_light, "acc": acc({m: v["category"] for m, v in luna.items()}),
                 "errors": sum(1 for v in luna.values() if v["error"]), "latency_s": latency(luna),
                 "krw_total": cost_krw(luna, s.openai_model_light)},
        # 단계 조합(앞 단계가 정하면 그대로, 아니면 다음 단계)
        "cascades": {
            "rules→jev": acc(lambda r: rule(r) or jev[r["merchant"]]["category"]),
            "rules→luna": acc(lambda r: rule(r) or luna[r["merchant"]]["category"]),
            "jev(≥0.95)→luna": acc(jev_or_luna),
            "rules→jev(≥0.95)→luna": acc(lambda r: rule(r) or jev_or_luna(r)),
        },
        # 처음 보는 가맹점 흉내: 규칙이 못 정한 거래만 모아 모델끼리 비교
        "rule_uncovered": {
            "n": len(uncovered),
            "jev_acc": round(sum(1 for r in uncovered if jev[r["merchant"]]["category"] == r["category"]) / max(1, len(uncovered)), 3),
            "luna_acc": round(sum(1 for r in uncovered if luna[r["merchant"]]["category"] == r["category"]) / max(1, len(uncovered)), 3),
        },
    }
    out = ROOT / "runs" / f"{stamp}_category"
    out.mkdir(parents=True, exist_ok=True)
    (out / "summary.json").write_text(json.dumps(summary, ensure_ascii=False, indent=2), encoding="utf-8")
    print(json.dumps(summary, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
