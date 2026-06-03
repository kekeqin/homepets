from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    APP_NAME: str = "HomePets"
    DEBUG: bool = True

    DATABASE_URL: str | None = None
    TEST_DATABASE_URL: str = "sqlite:///./test.db"

    SECRET_KEY: str = "dev-secret-key-change-in-production"
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60 * 24  # 24 hours

    REVENUECAT_SECRET_API_KEY: str | None = None
    REVENUECAT_PROJECT_ID: str | None = None
    REVENUECAT_WEBHOOK_AUTH: str | None = None
    REVENUECAT_ENTITLEMENT_ID: str = "premium"

    ALIBABA_CLOUD_ACCESS_KEY_ID: str | None = None
    ALIBABA_CLOUD_ACCESS_KEY_SECRET: str | None = None
    ALIYUN_SMS_SIGN_NAME: str | None = None
    ALIYUN_SMS_TEMPLATE_CODE: str | None = None
    ALIYUN_SMS_SCHEME_NAME: str = "HomePets"
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

    model_config = {"env_file": ".env", "env_file_encoding": "utf-8"}

    @property
    def database_url(self) -> str:
        """Use a local SQLite database by default for zero-config development."""
        return self.DATABASE_URL or "sqlite:///./homepets.db"


settings = Settings()
