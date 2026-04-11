from fastapi.testclient import TestClient
from sqlmodel import Session

from app.core.security import hash_password
from app.models.user import User


def _create_admin(db: Session) -> User:
    user = User(
        phone="13800000001",
        password_hash=hash_password("testpass123"),
        nickname="管理员",
        role="admin",
    )
    db.add(user)
    db.commit()
    db.refresh(user)
    return user


def _login(client: TestClient) -> str:
    return str(
        client.post(
            "/api/auth/login", json={"phone": "13800000001", "password": "testpass123"}
        ).json()["access_token"]
    )


def test_get_user_profile(client: TestClient, db: Session) -> None:
    user = _create_admin(db)
    token = _login(client)
    headers = {"Authorization": f"Bearer {token}"}
    response = client.get(f"/api/users/{user.id}", headers=headers)
    assert response.status_code == 200
    data = response.json()
    assert data["nickname"] == "管理员"
    assert data["phone"] == "13800000001"


def test_update_user_nickname(client: TestClient, db: Session) -> None:
    user = _create_admin(db)
    token = _login(client)
    headers = {"Authorization": f"Bearer {token}"}
    response = client.put(
        f"/api/users/{user.id}",
        json={"nickname": "超级管理员"},
        headers=headers,
    )
    assert response.status_code == 200
    assert response.json()["nickname"] == "超级管理员"


def test_update_user_avatar(client: TestClient, db: Session) -> None:
    user = _create_admin(db)
    token = _login(client)
    headers = {"Authorization": f"Bearer {token}"}
    response = client.put(
        f"/api/users/{user.id}",
        json={"avatar_url": "https://example.com/avatar.png"},
        headers=headers,
    )
    assert response.status_code == 200
    assert response.json()["avatar_url"] == "https://example.com/avatar.png"


def test_update_other_user_forbidden(client: TestClient, db: Session) -> None:
    _create_admin(db)
    token = _login(client)
    headers = {"Authorization": f"Bearer {token}"}
    # Try to update a different user
    response = client.put(
        "/api/users/999",
        json={"nickname": "hacker"},
        headers=headers,
    )
    assert response.status_code == 404


def test_admin_can_update_family_member_avatar(client: TestClient, db: Session) -> None:
    admin = _create_admin(db)
    token = _login(client)
    headers = {"Authorization": f"Bearer {token}"}

    me_response = client.get("/api/auth/me", headers=headers)
    family_id = me_response.json()["family_id"]
    assert family_id is not None

    member_response = client.post(
        f"/api/families/{family_id}/members",
        json={"nickname": "小明"},
        headers=headers,
    )
    assert member_response.status_code == 201
    member_id = member_response.json()["id"]

    update_response = client.put(
        f"/api/users/{member_id}",
        json={"avatar_url": "emoji:🐱"},
        headers=headers,
    )
    assert update_response.status_code == 200
    assert update_response.json()["avatar_url"] == "emoji:🐱"
    assert update_response.json()["id"] != admin.id
