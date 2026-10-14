# conmoney 서버

LLM 중계 서버(Spec 5장). 상태를 저장하지 않고, 툴은 앱에서 실행된다.

- `POST /v1/categorize` — 가맹점 분류(jev → 실패 시 gpt-6-luna)
- `POST /v1/agent` — 구매 상담 한 단계(툴 호출을 돌려주거나 검증된 최종 답)
- 인증: `x-app-token` 헤더 = `.env`의 `APP_TOKEN`

## 로컬 실행
```bash
python -m venv .venv
.venv/Scripts/python -m pip install -r requirements.txt pytest
.venv/Scripts/python -m uvicorn app.main:app --port 8080
```
설정은 `.env`(형식: `.env.example`, git 제외).

## 테스트
```bash
.venv/Scripts/python -m pytest -q          # 단위·API(모델 호출 없음)
.venv/Scripts/python -X utf8 -m tests.live_agent   # 실제 OpenAI로 상담 시나리오(가짜 숫자, 몇 원)
```

## 앱 연결
`app/config/dev.json`(git 제외)에 `CONMONEY_SERVER`, `CONMONEY_TOKEN`을 넣고
`flutter run --dart-define-from-file=config/dev.json`. 에뮬레이터에서 PC의 로컬 서버는 `http://10.0.2.2:8080`.
