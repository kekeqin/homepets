from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    APP_NAME: str = "HomePets"
    DEBUG: bool = True

    DATABASE_URL: str | None = None
    TEST_DATABASE_URL: str = "sqlite:///./test.db"

    SECRET_KEY: str = "dev-secret-key-change-in-production"
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60 * 24  # 24 hours

    model_config = {"env_file": ".env", "env_file_encoding": "utf-8"}

    @property
    def database_url(self) -> str:
        """Use a local SQLite database by default for zero-config development."""
        return self.DATABASE_URL or "sqlite:///./homepets.db"


settings = Settings()
