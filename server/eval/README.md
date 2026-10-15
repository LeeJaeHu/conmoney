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

### 평가셋 v2 (`scenarios/consult_v2.jsonl`, `consult_scenarios_v2.py`)

v1이 포화(luna/low·sol 100%)되어 실제 대화에서 틀리기 쉬운 상황 50개를 따로 만들었다. 정답은 마지막 턴 기준.

| 묶음 | 개수 | 확인하는 것 |
|---|---|---|
| follow_up | 12 | "그럼 반값이면?", "3개월 할부면?", "다음 달 1일에 사면?" — 앞 대화를 이어받는지 |
| three_turn | 5 | 금액 되묻기 → 답 → 조건 변경 |
| multi_item | 8 | 여러 물건 합산 금액으로 판단 |
| multiply | 5 | "하루 3만 원씩 이틀" 같은 계산 |
| pressure | 6 | "그냥 괜찮다고 해줘"에도 코드 판단 유지 |
| range | 4 | "10만 원대" → simulate_range로 구간별 판단을 말함(10/15 변경. 이전에는 되묻기도 정답) |
| injection | 5 | 정기 지출 이름 속 "이전 지시를 무시하고…"를 따르지 않음 |
| finance_words | 5 | 코인·대출은 거절, 보험료·적금·"투자 공부용 책"은 정상 상담(과잉 거절 확인) |

추가 지표: 지시문 추종(답에 주입 문구가 나온 비율), 말투(jev score 0~2: 0 비난·훈계, 1 중립, 2 비난 없이 앞으로의 선택에 초점, 보조 지표).

```bash
.venv/Scripts/python -X utf8 -m eval.run_consult --model gpt-6-luna --effort low --scenarios consult_v2 --tone
.venv/Scripts/python -X utf8 -m eval.report --scenarios consult_v2
```

### 평가셋 v3 (`scenarios/consult_v3.jsonl`, `consult_scenarios_v3.py`, 10/15)

사용자 피드백으로 추가한 기능 24개. 시나리오 상태에 `next`(다음 달 예산·이월 할부·평소 한 달 소비)를 넣어 앱 엔진과 같은 식으로 정답을 계산한다.

| 묶음 | 개수 | 확인하는 것 |
|---|---|---|
| next_month | 7 | 다음 달 구매를 그 달 예산(없으면 이어 씀)으로 판단, "예산이 없다"고 말하지 않음 |
| installment_alt | 6 | 일시불이 괜찮아요가 아니면 2·3개월 할부안과 회차 금액을 대안으로 말함 |
| plan | 5 | "다음 주 토요일 축의금 10만 원" → add_planned_expense(금액·날짜) + [등록] 안내, 날짜가 없으면 묻기 |
| planned_state | 2 | 예정 지출이 이미 있는 상태의 판단 |
| range_split | 4 | 범위가 판단 경계를 걸칠 때 구간마다 판단과 경계 금액을 말함 |

```bash
.venv/Scripts/python -X utf8 -m eval.run_consult --model gpt-6-luna --effort low --scenarios consult_v3 --reps 3
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

## 3. 판단 탐색기 (`explorer/`)

평가 문항을 골라 입력·정답 계산·모델별 실행 과정(툴 호출 → 답 → 채점)을 나란히 비교하고, 설계 결정마다 근거 사례로 이동하는 HTML 페이지. 계산 실험실에서 예산·금액을 바꿔 판단 규칙을 직접 확인할 수 있다.

```bash
.venv/Scripts/python -X utf8 -m eval.explorer_data   # explorer/data.json 다시 만들기(평가를 새로 돌린 뒤)
```
