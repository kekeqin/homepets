from fastapi.testclient import TestClient
from sqlmodel import Session

from app.core.security import hash_password
from app.models.family import Family
from app.models.user import User


def _create_admin(db: Session, phone: str = "13800000001") -> User:
    """Helper to create an admin user directly in DB."""
    user = User(
        phone=phone,
        password_hash=hash_password("testpass123"),
        nickname="管理员",
        role="admin",
    )
    db.add(user)
    db.commit()
    db.refresh(user)
    return user


# ── Register Tests ──────────────────────────────────────────────


def test_register_success(client: TestClient, db: Session) -> None:
    response = client.post(
        "/api/auth/register",
        json={"phone": "13800000001", "password": "password123", "nickname": "爸爸"},
    )
    assert response.status_code == 201
    data = response.json()
    assert data["phone"] == "13800000001"
    assert data["nickname"] == "爸爸"
    assert data["role"] == "admin"
    assert "id" in data
    family = db.get(Family, data["family_id"])
    assert family is not None
    assert family.name == "爸爸的家"


def test_register_duplicate_phone(client: TestClient, db: Session) -> None:
    _create_admin(db, phone="13800000001")
    response = client.post(
        "/api/auth/register",
        json={"phone": "13800000001", "password": "password123", "nickname": "妈妈"},
    )
    assert response.status_code == 409
    assert "已注册" in response.json()["detail"]


def test_register_invalid_phone(client: TestClient) -> None:
    response = client.post(
        "/api/auth/register",
        json={"phone": "abc", "password": "password123", "nickname": "爸爸"},
    )
    assert response.status_code == 422


def test_register_short_password(client: TestClient) -> None:
    response = client.post(
        "/api/auth/register",
        json={"phone": "13800000002", "password": "123", "nickname": "爸爸"},
    )
    assert response.status_code == 422


# ── Login Tests ─────────────────────────────────────────────────


def test_login_success(client: TestClient, db: Session) -> None:
    _create_admin(db, phone="13800000001")
    response = client.post(
        "/api/auth/login",
        json={"phone": "13800000001", "password": "testpass123"},
    )
    assert response.status_code == 200
    data = response.json()
    assert "access_token" in data
    assert data["token_type"] == "bearer"


def test_login_wrong_password(client: TestClient, db: Session) -> None:
    _create_admin(db, phone="13800000001")
    response = client.post(
        "/api/auth/login",
        json={"phone": "13800000001", "password": "wrongpassword"},
    )
    assert response.status_code == 401


def test_login_nonexistent_user(client: TestClient) -> None:
    response = client.post(
        "/api/auth/login",
        json={"phone": "13900000000", "password": "password123"},
    )
    assert response.status_code == 401


# ── Me Tests ────────────────────────────────────────────────────


def test_me_authenticated(client: TestClient, db: Session) -> None:
    user = _create_admin(db, phone="13800000001")
    login_resp = client.post(
        "/api/auth/login",
        json={"phone": "13800000001", "password": "testpass123"},
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
