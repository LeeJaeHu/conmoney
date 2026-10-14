"""server/.env 설정(Spec 5장). 값은 환경 변수가 우선한다(Cloud Run에서는 환경 변수로 주입)."""
import os
from dataclasses import dataclass
from pathlib import Path

from dotenv import load_dotenv

load_dotenv(Path(__file__).resolve().parent.parent / ".env")


@dataclass(frozen=True)
class Settings:
    app_token: str
    openai_model_agent: str
    openai_reasoning_agent: str
    openai_model_light: str
    openai_reasoning_light: str
    jev_api_key: str
    jev_base_url: str
    jev_model: str
    jev_min_confidence: float
    monthly_budget_krw: int
    usd_krw: float
    debug: bool


def load() -> Settings:
    e = os.environ.get
    return Settings(
        app_token=e("APP_TOKEN", ""),
        openai_model_agent=e("OPENAI_MODEL_AGENT", "gpt-6.1-sol"),
        openai_reasoning_agent=e("OPENAI_REASONING_AGENT", "low"),
        openai_model_light=e("OPENAI_MODEL_LIGHT", "gpt-6-luna"),
        openai_reasoning_light=e("OPENAI_REASONING_LIGHT", "none"),
        jev_api_key=e("JEV_API_KEY", ""),
        jev_base_url=e("JEV_BASE_URL", "https://api.typesafe.ai").rstrip("/"),
        jev_model=e("JEV_MODEL", "jev-latest"),
        jev_min_confidence=float(e("JEV_MIN_CONFIDENCE", "0.8")),
        monthly_budget_krw=int(e("MONTHLY_BUDGET_KRW", "10000")),
        usd_krw=float(e("USD_KRW", "1400")),
        debug=e("DEBUG", "0") == "1",
    )


# 공식 모델 문서의 가격(USD / 100만 토큰). 비용 상한 계산용이며 바뀌면 여기만 고친다.
PRICES = {
    "gpt-6-astra": (10.0, 50.0),
    "gpt-6.1-sol": (2.0, 10.0),
    "gpt-6-luna": (0.10, 0.50),
    "jev": (0.042, 0.0),
}
