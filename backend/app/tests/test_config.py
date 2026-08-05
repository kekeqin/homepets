import pytest

from app.core.config import Settings


def test_access_token_expire_minutes_defaults_to_30_days(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    monkeypatch.delenv("ACCESS_TOKEN_EXPIRE_MINUTES", raising=False)

    settings = Settings(_env_file=None)

    assert settings.ACCESS_TOKEN_EXPIRE_MINUTES == 60 * 24 * 30


def test_database_url_defaults_to_local_sqlite(monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.delenv("DATABASE_URL", raising=False)

    settings = Settings(_env_file=None)

    assert settings.database_url == "sqlite:///./pickstarpet.db"


def test_database_url_prefers_explicit_env(monkeypatch: pytest.MonkeyPatch) -> None:
    expected_database_url = "postgresql://pickstarpet:pickstarpet@db:5432/pickstarpet"
    monkeypatch.setenv("DATABASE_URL", expected_database_url)

    settings = Settings(_env_file=None)

    assert settings.database_url == expected_database_url


def test_apple_sign_in_client_ids_default_matches_bundle_id(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    monkeypatch.delenv("APPLE_SIGN_IN_CLIENT_IDS", raising=False)

    settings = Settings(_env_file=None)

    assert settings.apple_sign_in_client_ids == ["com.kkqin.pickstarpet"]


def test_apple_sign_in_client_ids_parses_comma_separated_values(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    monkeypatch.setenv(
        "APPLE_SIGN_IN_CLIENT_IDS",
        "com.kkqin.pickstarpet, com.kkqin.pickstarpet.service ",
    )

    settings = Settings(_env_file=None)

    assert settings.apple_sign_in_client_ids == [
        "com.kkqin.pickstarpet",
        "com.kkqin.pickstarpet.service",
    ]


def test_apple_sign_in_client_ids_empty_string_means_unconfigured(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    monkeypatch.setenv("APPLE_SIGN_IN_CLIENT_IDS", "  ,  ")

    settings = Settings(_env_file=None)

    assert settings.apple_sign_in_client_ids == []
