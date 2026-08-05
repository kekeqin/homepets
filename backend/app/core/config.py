from pathlib import Path

from pydantic_settings import BaseSettings, SettingsConfigDict

# Resolve backend/.env even when the process is started from the monorepo root.
_BACKEND_DIR = Path(__file__).resolve().parents[2]
_ENV_FILE = _BACKEND_DIR / ".env"


class Settings(BaseSettings):
    APP_NAME: str = "拾星小宠"
    DEBUG: bool = True

    DATABASE_URL: str | None = None
    TEST_DATABASE_URL: str = "sqlite:///./test.db"

    SECRET_KEY: str = "dev-secret-key-change-in-production"
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60 * 24 * 30  # 30 days

    REVENUECAT_SECRET_API_KEY: str | None = None
    REVENUECAT_PROJECT_ID: str | None = None
    REVENUECAT_WEBHOOK_AUTH: str | None = None
    REVENUECAT_ENTITLEMENT_ID: str = "premium"

    ALIBABA_CLOUD_ACCESS_KEY_ID: str | None = None
    ALIBABA_CLOUD_ACCESS_KEY_SECRET: str | None = None
    ALIYUN_SMS_SIGN_NAME: str | None = None
    ALIYUN_SMS_TEMPLATE_CODE: str | None = None
    ALIYUN_SMS_SCHEME_NAME: str = "拾星小宠"
    ALIYUN_SMS_REGION_ID: str = "cn-hangzhou"
    ALIYUN_SMS_ENDPOINT: str = "https://dypnsapi.aliyuncs.com/"
    ALIYUN_SMS_CODE_VALID_SECONDS: int = 300
    ALIYUN_SMS_RESEND_INTERVAL_SECONDS: int = 60
    ALIYUN_SMS_TIMEOUT_SECONDS: float = 5.0
    SMS_VERIFICATION_MOCK_ENABLED: bool = False
    SMS_SEND_RATE_LIMIT_PER_PHONE_PER_HOUR: int = 5
    SMS_SEND_RATE_LIMIT_PER_IP_PER_HOUR: int = 30
    SMS_VERIFY_FAILURE_LIMIT_PER_PHONE: int = 5
    SMS_VERIFY_FAILURE_LIMIT_PER_IP: int = 30
    SMS_VERIFY_FAILURE_WINDOW_SECONDS: int = 600

    # Native iOS/macOS audience is the bundle id. Add Services IDs for Android/Web.
    APPLE_SIGN_IN_CLIENT_IDS: str = "com.kkqin.pickstarpet"
    APPLE_SIGN_IN_KEYS_URL: str = "https://appleid.apple.com/auth/keys"
    APPLE_SIGN_IN_TIMEOUT_SECONDS: float = 5.0
    APPLE_SIGN_IN_KEYS_CACHE_SECONDS: int = 3600

    model_config = SettingsConfigDict(
        env_file=str(_ENV_FILE) if _ENV_FILE.is_file() else ".env",
        env_file_encoding="utf-8",
        extra="ignore",
    )

    @property
    def database_url(self) -> str:
        """Use a local SQLite database by default for zero-config development."""
        return self.DATABASE_URL or "sqlite:///./pickstarpet.db"

    @property
    def apple_sign_in_client_ids(self) -> list[str]:
        return [
            client_id.strip()
            for client_id in self.APPLE_SIGN_IN_CLIENT_IDS.split(",")
            if client_id.strip()
        ]


settings = Settings()
