from collections.abc import Generator
from typing import Any

import pytest
from fastapi.testclient import TestClient
from sqlmodel import Session, select

from app.api import auth as auth_api
from app.main import app
from app.models.family import Family
from app.models.user import User
from app.services.apple_identity import (
    AppleIdentity,
    AppleIdentityVerificationError,
    get_apple_identity_verifier,
)


@pytest.fixture(autouse=True)
def clear_apple_verifier_override() -> Generator[None, None, None]:
    yield
    app.dependency_overrides.pop(get_apple_identity_verifier, None)


@pytest.fixture(autouse=True)
def use_real_sms_rate_limits_by_default(monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.setattr(auth_api.settings, "DEBUG", False)
    monkeypatch.setattr(auth_api.settings, "SMS_VERIFICATION_MOCK_ENABLED", False)


def _create_admin(db: Session, phone: str = "13800000001") -> User:
    user = User(phone=phone, nickname="管理员", role="admin")
    db.add(user)
    db.commit()
    db.refresh(user)
    return user


def test_send_sms_code_success(client: TestClient, fake_sms_client: Any) -> None:
    response = client.post("/api/auth/sms-code", json={"phone": "13800000001"})

    assert response.status_code == 200
    assert response.json() == {"cooldown_seconds": 60}
    assert fake_sms_client.sent_phones == ["13800000001"]


def test_send_sms_code_rejects_invalid_phone(client: TestClient) -> None:
    response = client.post("/api/auth/sms-code", json={"phone": "abc"})

    assert response.status_code == 422


def test_send_sms_code_rate_limited_by_phone(
    client: TestClient,
    fake_sms_client: Any,
) -> None:
    first = client.post("/api/auth/sms-code", json={"phone": "13800000001"})
    second = client.post("/api/auth/sms-code", json={"phone": "13800000001"})

    assert first.status_code == 200
    assert second.status_code == 429
    assert second.json()["detail"]["retry_after_seconds"] > 0
    assert fake_sms_client.sent_phones == ["13800000001"]


def test_send_sms_code_mock_mode_skips_send_rate_limit(
    client: TestClient,
    fake_sms_client: Any,
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    monkeypatch.setattr(auth_api.settings, "SMS_VERIFICATION_MOCK_ENABLED", True)

    first = client.post("/api/auth/sms-code", json={"phone": "13800000001"})
    second = client.post("/api/auth/sms-code", json={"phone": "13800000001"})

    assert first.status_code == 200
    assert first.json() == {"cooldown_seconds": 0, "dev_code": "123456"}
    assert second.status_code == 200
    assert second.json() == {"cooldown_seconds": 0, "dev_code": "123456"}
    assert fake_sms_client.sent_phones == ["13800000001", "13800000001"]


def test_send_sms_code_debug_mode_skips_send_rate_limit(
    client: TestClient,
    fake_sms_client: Any,
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    monkeypatch.setattr(auth_api.settings, "DEBUG", True)

    first = client.post("/api/auth/sms-code", json={"phone": "13800000001"})
    second = client.post("/api/auth/sms-code", json={"phone": "13800000001"})

    assert first.status_code == 200
    assert first.json() == {"cooldown_seconds": 0, "dev_code": "123456"}
    assert second.status_code == 200
    assert second.json() == {"cooldown_seconds": 0, "dev_code": "123456"}
    assert fake_sms_client.sent_phones == ["13800000001", "13800000001"]


def test_login_with_sms_code_existing_user(client: TestClient, db: Session) -> None:
    user = _create_admin(db, phone="13800000001")

    response = client.post(
        "/api/auth/login",
        json={"phone": "13800000001", "code": "123456"},
    )

    assert response.status_code == 200
    assert response.json()["token_type"] == "bearer"
    token = response.json()["access_token"]
    me = client.get("/api/auth/me", headers={"Authorization": f"Bearer {token}"}).json()
    assert me["id"] == user.id
    assert me["phone"] == "13800000001"


def test_login_with_sms_code_auto_registers_new_phone(
    client: TestClient,
    db: Session,
) -> None:
    response = client.post(
        "/api/auth/login",
        json={"phone": "13800000002", "code": "123456"},
    )

    assert response.status_code == 200
    created = db.exec(select(User).where(User.phone == "13800000002")).first()
    assert created is not None
    assert created.nickname == "家长"
    assert created.role == "admin"
    assert "password_hash" not in User.model_fields
    family = db.get(Family, created.family_id)
    assert family is not None
    assert family.owner_id == created.id


def test_login_with_apple_auto_registers_new_user(
    client: TestClient,
    db: Session,
) -> None:
    app.dependency_overrides[get_apple_identity_verifier] = lambda: _FakeAppleVerifier(
        AppleIdentity(subject="apple-sub-1", email="parent@example.com")
    )

    response = client.post(
        "/api/auth/apple",
        json={
            "identity_token": "valid-token",
            "authorization_code": "auth-code",
            "nonce": "nonce-123",
            "full_name": "Apple Parent",
        },
    )

    assert response.status_code == 200
    token = response.json()["access_token"]
    me = client.get("/api/auth/me", headers={"Authorization": f"Bearer {token}"}).json()
    created = db.exec(select(User).where(User.apple_sub == "apple-sub-1")).first()
    assert created is not None
    assert me["id"] == created.id
    assert created.email == "parent@example.com"
    assert created.nickname == "Apple Parent"
    assert created.role == "admin"
    family = db.get(Family, created.family_id)
    assert family is not None
    assert family.owner_id == created.id


def test_login_with_apple_reuses_existing_user(client: TestClient, db: Session) -> None:
    user = User(apple_sub="apple-sub-1", email="old@example.com", nickname="Apple", role="admin")
    db.add(user)
    db.commit()
    db.refresh(user)
    app.dependency_overrides[get_apple_identity_verifier] = lambda: _FakeAppleVerifier(
        AppleIdentity(subject="apple-sub-1", email="new@example.com")
    )

    response = client.post(
        "/api/auth/apple",
        json={"identity_token": "valid-token", "authorization_code": "auth-code"},
    )

    assert response.status_code == 200
    token = response.json()["access_token"]
    me = client.get("/api/auth/me", headers={"Authorization": f"Bearer {token}"}).json()
    db.refresh(user)
    assert me["id"] == user.id
    assert user.email == "new@example.com"


def test_login_with_apple_rejects_invalid_identity(client: TestClient) -> None:
    app.dependency_overrides[get_apple_identity_verifier] = lambda: _RejectingAppleVerifier()

    response = client.post(
        "/api/auth/apple",
        json={"identity_token": "bad-token", "authorization_code": "auth-code"},
    )

    assert response.status_code == 401


def test_login_rejects_wrong_sms_code(client: TestClient, db: Session) -> None:
    _create_admin(db, phone="13800000001")

    response = client.post(
        "/api/auth/login",
        json={"phone": "13800000001", "code": "000000"},
    )

    assert response.status_code == 401
    assert response.json()["detail"] == "验证码错误或已过期"


def test_login_sms_code_rate_limited_after_failures(client: TestClient, db: Session) -> None:
    _create_admin(db, phone="13800000001")

    for _ in range(5):
        response = client.post(
            "/api/auth/login",
            json={"phone": "13800000001", "code": "000000"},
        )
        assert response.status_code == 401

    response = client.post(
        "/api/auth/login",
        json={"phone": "13800000001", "code": "000000"},
    )

    assert response.status_code == 429
    assert response.json()["detail"]["code"] == "SMS_VERIFY_RATE_LIMITED"


def test_password_register_route_removed(client: TestClient) -> None:
    response = client.post(
        "/api/auth/register",
        json={"phone": "13800000001", "password": "password123", "nickname": "爸爸"},
    )

    assert response.status_code == 404


def test_password_login_payload_removed(client: TestClient, db: Session) -> None:
    _create_admin(db, phone="13800000001")

    response = client.post(
        "/api/auth/login",
        json={"phone": "13800000001", "password": "testpass123"},
    )

    assert response.status_code == 422


def test_me_authenticated(client: TestClient, db: Session) -> None:
    user = _create_admin(db, phone="13800000001")
    login_resp = client.post(
        "/api/auth/login",
        json={"phone": "13800000001", "code": "123456"},
    )
    token = login_resp.json()["access_token"]

    response = client.get("/api/auth/me", headers={"Authorization": f"Bearer {token}"})

    assert response.status_code == 200
    data = response.json()
    assert data["id"] == user.id
    assert data["phone"] == "13800000001"
    assert data["nickname"] == "管理员"


def test_me_unauthenticated(client: TestClient) -> None:
    response = client.get("/api/auth/me")
    assert response.status_code == 401


def test_me_invalid_token(client: TestClient) -> None:
    response = client.get("/api/auth/me", headers={"Authorization": "Bearer invalid"})
    assert response.status_code == 401


def test_sms_rate_limiter_can_be_reset_for_test_isolation() -> None:
    auth_api.sms_rate_limiter.reset()
    assert auth_api.sms_rate_limiter.retry_after_send("13800000001", "testclient") == 0


class _FakeAppleVerifier:
    def __init__(self, identity: AppleIdentity) -> None:
        self._identity = identity

    def verify(self, identity_token: str, nonce: str | None = None) -> AppleIdentity:
        return self._identity


class _RejectingAppleVerifier:
    def verify(self, identity_token: str, nonce: str | None = None) -> AppleIdentity:
        raise AppleIdentityVerificationError("invalid identity token")
