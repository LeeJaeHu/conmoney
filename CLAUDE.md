# conmoney — 스트레스 없는 월 예산 에이전트

개인용 Android 앱(APK 직접 설치). 카드 결제 알림을 읽어 "오늘 쓸 수 있는 금액"을 보여주고, 구매를 고민할 때 내 소비 패턴을 근거로 조언한다. 답변·문서는 한국어로 쓴다.

## 먼저 읽을 문서
- `docs/PRD_budget_agent.md` — 목표, 기능(F1–F11), 결정 기록(11장), 열린 질문(12장)
- `docs/SPEC_P0.md` — P0 구현 명세: 데이터 모델, 계산 공식(3장), 기능별 동작, 수락 테스트(8장), 실데이터 분석(부록 A)
- 결정이 바뀌면 PRD 11장 결정 기록과 Spec을 같이 고친다

## 구조
```
docs/    PRD, Spec
tools/   import_statements.py — 카드사 내역 파일 → CSV (PC에서 실행)
data/    가져온 거래 CSV, 라벨 (git 제외)
카드내역/ 카드사 원본 파일 (git 제외)
app/     Flutter 앱 + android/ Kotlin 알림 리스너
server/  Cloud Run(Python) LLM 중계 (예정). 비밀값은 server/.env(git 제외), 형식은 server/.env.example
```

## 데이터 (git에 없음 — 노트북 사이 직접 복사)
- `카드내역/`: 롯데·현대·신한 .xls(실제로는 HTML), 토스 후불교통 PDF
- `data/labels.csv`: 사용자가 검수한 정답(category, is_foreign, cancelled). **카테고리 정답의 기준 파일**
- `data/transactions_v3.csv`: 최신 가져오기 결과(446건, 2026-05~10-13). 폰에서 쓰려면 이 파일을 폰으로 옮겨 앱 메뉴 > 과거 기록 가져오기
- drift 코드 생성: `app`에서 `dart run build_runner build` (database.dart를 고친 뒤)
- 재생성: `python tools/import_statements.py 카드내역 data/transactions_v3.csv` (토스 PDF는 `pypdf` 필요)
- 실제 결제 내역이므로 git·외부 서비스·LLM 프롬프트에 원본을 올리지 않는다. 테스트용 데이터는 금액·가맹점을 바꾼 샘플을 따로 만든다

## 확정된 주요 결정 (자세한 건 PRD 11장)
- 예산 기간은 매월 1일~말일. 목표 방식은 고정/단계적(예: 80만 → 67만 → 54만) 중 선택
- 홈: 오늘 쓸 수 있는 금액(크게) + 이번 달 남은 예산(작게). 초과 시 얼마나 넘었는지 금액으로 표시
- 할부: 회차 금액 = 100원 단위 내림, 나머지는 1회차. 1회차는 승인 월
- 특이 지출은 예산에 포함, 평소 패턴 통계에서 제외(닌텐도 결제는 특이 지출)
- 신한카드는 알림 대상에서 제외, 과거 기록은 교통비로 포함
- 카테고리: 식비/카페·간식/교통/게임/쇼핑/구독/API/통신/공과금/의료/교육/영화/경조사·선물/연회비/기타
- AI: 0단계 코드 → 1단계 jev(분류, 확신도) → 2단계 OpenAI(상담 gpt-6.1-sol, 가벼운 작업 gpt-6-luna). 모든 금액 계산은 코드가 하고 LLM은 툴 결과 숫자만 인용
- 돈 상담·상담 기록(F11)은 P1

## 작업 방식
- 계산 로직(BudgetEngine)은 Flutter 의존 없는 순수 Dart로 만들고 Spec 8장 테스트 ID(C1…, P1…)를 테스트 이름으로 쓴다
- 낮에는 이 노트북, 저녁에는 집 노트북(Android Studio 있음)에서 작업 → 작업 끝에 push, 시작할 때 pull
- Flutter 버전은 두 노트북에서 같게 맞춘다: **Flutter 3.47.7 (stable), Dart 3.13.5**. 이 노트북은 `C:/flutter`에 설치(PATH 등록됨. Claude Code의 bash에서는 `export PATH="/c/flutter/bin:$PATH"`가 필요할 수 있음)
- 이 노트북에는 Android SDK가 없어 APK 빌드·폰 설치는 집 노트북에서 한다. `flutter test`는 양쪽 모두 가능

## 진행 상황
- [x] PRD·Spec, 카드 내역 가져오기(tools/), 실데이터 분석
- [x] BudgetEngine(`app/lib/core/`) + 테스트 C1~C18 (`app/test/core/`)
- [x] 알림 리스너 + 샘플 수집 화면 — **집 노트북에서 빌드·설치 후 알림 접근 허용 필요**
- [ ] 현대카드 앱 패키지명 확인(샘플 수집 화면의 "알림을 보낸 앱" 목록) → `SourceFilter` 수정
- [x] DB(drift, `app/lib/data/`) + CSV 가져오기(설정 메뉴 > 과거 기록 가져오기). 실데이터 월 합계가 부록 A와 일치(테스트)
- [x] 홈 화면(오늘 금액 + 남은 예산 + 초과액 + 단계 표시), 예산 설정(고정/단계적, 만 원 단위 입력)
- [x] 정기 지출(F5): 자동 탐지(실데이터 13개), 등록 시 지난 결제까지 연결, [아니요]·[이번 달 없음], 직접 추가·수정. 홈 메뉴 > 정기 지출
- [x] 카테고리 보기(F8): 기간 선택, 특이 지출 토글, 카테고리 막대, 6개월 추이, 거래 수정 시트(F3 시트 재사용). 거래 직접 추가는 미구현
- [x] `server/.env.example`(모델: 상담 gpt-6.1-sol, 가벼운 작업 gpt-6-luna, 분류 jev). `server/.env`에 키를 채워야 함
- [ ] 알림 파서(F2), 확인 알림(F3), 서버·구매 상담(F6), 먼저 알림(F7)
