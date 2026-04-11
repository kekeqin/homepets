from app.core.config import Settings


def test_database_url_defaults_to_local_sqlite(monkeypatch) -> None:
    monkeypatch.delenv("DATABASE_URL", raising=False)

    settings = Settings()

    assert settings.database_url == "sqlite:///./homepets.db"


def test_database_url_prefers_explicit_env(monkeypatch) -> None:
    expected_database_url = "postgresql://homepets:homepets@db:5432/homepets"
    monkeypatch.setenv("DATABASE_URL", expected_database_url)

    settings = Settings()

    assert settings.database_url == expected_database_url
