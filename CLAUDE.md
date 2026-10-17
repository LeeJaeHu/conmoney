# conmoney — 스트레스 없는 월 예산 에이전트

개인용 Android 앱(APK 직접 설치). 카드 결제 알림을 읽어 "오늘 쓸 수 있는 금액"을 보여주고, 구매를 고민할 때 내 소비 패턴을 근거로 조언한다. 답변·문서는 한국어로 쓴다.

## 먼저 읽을 문서
- `docs/PRD_budget_agent.md` — 목표, 기능(F1–F11), 결정 기록(11장), 열린 질문(12장)
- `docs/SPEC_P0.md` — P0 구현 명세: 데이터 모델, 계산 공식(3장), 기능별 동작, 수락 테스트(8장), 실데이터 분석(부록 A)
- `docs/EXPERIMENTS.md` — 실험·개선 기록(제약 → 문제 → 측정 → 개선). 지원(토스 AI Engineer) 포트폴리오의 근거
- `README.md` — 포트폴리오 요약(저장소 첫 화면)
- `docs/WORKLOG.md` — 날짜별 작업 일지(사용자 결정 · 만든 것 · 검증과 개선 · 다음)
- 결정이 바뀌면 PRD 11장 결정 기록과 Spec을 같이 고친다
- 무언가를 측정하고 바꿨으면 EXPERIMENTS.md에 수치와 함께 남긴다. 측정 안 한 것은 "계획"에만 적는다

## 작업 기록 (자동, 사용자 요청 10/16)
- 작업 단위가 끝날 때마다 **커밋 전에** `docs/WORKLOG.md` 맨 위 그날 항목(없으면 새로)에 덧붙인다. 사용자가 따로 말하지 않아도 한다
  - **사용자 결정**: 사용자가 정하거나 바꾼 것(말의 요지). 이유·대안이 있으면 PRD 11장에도
  - **만든 것**: 기능과 파일 위치
  - **검증과 개선**: 테스트·평가 수치, 실패 원인과 고친 것. 자세한 건 EXPERIMENTS.md의 E번호로 링크
  - **다음**: 남은 일, 열어 둔 질문
- 한 일만 적고 추측·계획은 "다음"에만. 같은 내용을 여러 문서에 길게 반복하지 말고 링크한다
- 평가 수치가 바뀌면 대시보드·판단 탐색기 데이터도 다시 만든다(`server/eval/dashboard_data.py`, `explorer_data.py`)

## 구조
```
docs/    PRD, Spec
tools/   import_statements.py — 카드사 내역 파일 → CSV (PC에서 실행)
data/    가져온 거래 CSV, 라벨 (git 제외)
카드내역/ 카드사 원본 파일 (git 제외)
app/     Flutter 앱 + android/ Kotlin 알림 리스너
server/  Cloud Run(Python, FastAPI) LLM 중계. 비밀값은 server/.env(git 제외), 형식은 server/.env.example. 실행·테스트는 server/README.md
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
- AI: 0단계 코드 → 1단계 jev(분류, 확신도) → 2단계 OpenAI(상담 gpt-6-luna 추론 low — 10/15 평가로 sol에서 변경, 가벼운 작업 gpt-6-luna). 모든 금액 계산은 코드가 하고 LLM은 툴 결과 숫자만 인용
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
- [x] 서버(`server/`): /v1/categorize(jev → gpt-6-luna), /v1/agent(gpt-6.1-sol, 숫자·판단 검증, 범위 밖 거절). 로컬에서 앱 코드↔서버↔OpenAI 전체 흐름 확인
- [x] 구매 상담 화면(F6): 홈 > 살까 말까 물어보기. 서버 주소·토큰은 `app/config/dev.json`(git 제외) → `flutter run --dart-define-from-file=config/dev.json`
- [x] Cloud Run 배포: 프로젝트 `comoney`, 서울, https://conmoney-812487409574.asia-northeast3.run.app, 키는 Secret Manager(자세한 건 server/README.md). gcloud 계정은 morugureum@gmail.com(기본 프로젝트는 그대로 두고 `--project comoney`로 실행). `app/config/dev.json`에 이 주소가 들어 있음
- [x] 교통비 월 예약형(정기 지출의 한 종류): "후불" 결제를 모두 연결, 남은 예약분만 F. 정기 지출 화면에서 [예약]
- [x] 먼저 알려주기(F7): 규칙 3개·하루 1회·조용한 시간, WorkManager 1시간 주기 아침 검사, 로컬 알림, 설정 화면. 결제 직후 검사는 F2 저장 시점에 연결 필요
- [x] 다음 달 구매는 그 달 예산(없으면 이어 씀)으로 판단, 2·3개월 할부 대안, 금액대 구간 판단(simulate_range), 예정 지출(DB v5, 홈 메뉴 > 예정 지출, 상담에서 [등록] 제안). 평가셋 v3(E13)
- [x] 일상 대화형 상담: 회복 계획(plan_recovery)·평소 대비(compare_spending)·잡담, 평가셋 v4(E14)
- [x] 홈 지출 달력(날짜별 쓴 금액, 탭 → 그날 내역), 스크롤 화면 아래 여백(내비게이션 바)
- [x] 지출 분석 화면: 이번 달 흐름(누적 vs 예산·평소), 평소와 비교 그래프(`core/analysis.dart`)
- [x] 디자인 B2(테마 `ui/theme.dart`, 글꼴 Pretendard `assets/fonts`(OFL), 홈 예산 게이지, 상담 버튼 아래 고정). 화면 캡처: `app`에서 `SCREENSHOTS=1 flutter test test/screens --update-goldens` → `docs/design/`
- [x] 알림 → 거래(F2): 롯데카드 알림톡 파서(`core/payment_parser.dart`), 저장·중복·취소·할부·카테고리 추천(`data/notification_ingest.dart`), DB v6 `notification_results`. 홈을 열 때·돌아올 때·새로고침 때 동기화 + 결제 직후 F7 검사(`services/notification_sync.dart`)
- [ ] 현대카드·토스 파서(샘플 필요), 롯데 취소·할부·해외 실제 형식 확인, 앱이 꺼져 있을 때 반영, 확인 알림(F3), 상담 평가셋 50개
