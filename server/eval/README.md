# 평가

## 1. 구매 상담 (`run_consult.py`)

- **평가셋** `scenarios/consult_v1.jsonl` — 50개, 가짜 숫자(개인 데이터 없음). `consult_scenarios.py`로 다시 만든다.

  | 묶음 | 개수 | 확인하는 것 |
  |---|---|---|
  | roomy | 10 | 여유 있을 때 "괜찮아요" |
  | boundary | 10 | 초과액 0원 / 예산의 10% / 10%+1원 경계 |
  | over | 5 | 이미 예산 초과 상태 |
  | tight | 5 | 빠듯함(조건부·초과 섞임) |
  | fixed_soon | 5 | 큰 정기 지출 직전 |
  | installment | 5 | 할부 개월 수를 툴에 넘기는지 |
  | next_month | 3 | 다음 달 구매 → "다음 달 기준" |
  | ask_amount | 4 | 금액 없는 질문 → 툴 부르기 전에 되묻기 |
  | phrasing | 3 | "십오만 원", "4만5천원", "1.2만원" |

- **정답 판단**은 앱 계산 엔진과 같은 공식으로 미리 계산(예상 월말 지출 vs 예산, 10% 경계, 할부는 1회차만).
- **실행**: 실제 서버 코드(`create_app`, 숫자·판단 검증과 재생성 포함)를 그대로 쓰고 툴 결과는 `tool_stub.py`가 앱 `AgentToolbox`와 같은 키·형식으로 만든다. 평가에서는 호출 제한만 끈다.
- **지표** (`score()`)
  - 판단 일치: 답의 [판단] 줄 vs 정답
  - 숫자 정확(최종): 대체 문구가 아니고, 답의 모든 금액이 툴 결과·질문에 있음
  - 첫 답에 바로 정확: 재생성 없이 숫자가 맞음
  - 대체 문구 비율, 재생성 비율
  - 툴 호출 정확: `simulate_purchase`를 올바른 금액·할부로 불렀는가 / 금액 없는 질문에는 부르지 않았는가
  - 형식: [판단]·[근거]·[대안]
  - 2회 일관성: 같은 질문 두 번의 판단이 같은가
  - 평균 비용(원), 지연 p50·p90(동시 6개 실행 기준), 평균 라운드
- **저장**: `runs/<날짜-시각>_<모델>_<추론>/`
  - `config.json` 모델, 추론 수준, 반복 수, 지시문 해시(SYSTEM + TOOLS), git 커밋
  - `results.jsonl` 건별 원문·툴 호출·지표
  - `summary.json` 요약
- **비교**: `python -m eval.report` → 설정별 표(마크다운). 지시문을 고치면 해시가 바뀌므로 어떤 지시문의 점수인지 남는다.

```bash
.venv/Scripts/python -X utf8 -m eval.run_consult --model gpt-6-luna --effort none --reps 2
.venv/Scripts/python -X utf8 -m eval.report
```

## 2. 카테고리 분류 (`run_category.py`)

- **정답**: 사용자가 검수한 라벨 446건(가맹점 109개, 카테고리 15개). 실제 가맹점 이름이라 **건별 결과는 `data/eval/`(git 제외)**, git에는 `runs/<날짜>_category/summary.json`(집계)만.
- **비교**: 내장 규칙 / jev / gpt-6-luna, 그리고 단계 조합(규칙 → jev → luna)
- **jev 확신도 보정**: 확신도 구간별 정답률과 그 구간에 든 거래 비율
- 가맹점 하나에 정답이 둘 이상인 경우가 있어 "가맹점 이름만 보는 분류의 상한"도 계산

```bash
.venv/Scripts/python -X utf8 -m eval.run_category                       # API 호출
.venv/Scripts/python -X utf8 -m eval.run_category --from ../data/eval/category_<날짜>.jsonl   # 저장된 결과로 다시 집계
```
