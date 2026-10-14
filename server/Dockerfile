# Cloud Run용 이미지. 비밀값은 이미지에 넣지 않고 Cloud Run 환경 변수(또는 Secret Manager)로 준다.
FROM python:3.12-slim
WORKDIR /srv
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY app ./app
ENV PORT=8080
CMD exec uvicorn app.main:app --host 0.0.0.0 --port ${PORT}
