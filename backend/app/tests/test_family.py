from fastapi.testclient import TestClient
from sqlmodel import Session

from app.core.security import hash_password
from app.models.user import User


def _create_admin(db: Session, phone: str = "13800000001") -> User:
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


def _login(client: TestClient, phone: str = "13800000001") -> str:
    resp = client.post("/api/auth/login", json={"phone": phone, "password": "testpass123"})
    return str(resp.json()["access_token"])


def _auth_header(token: str) -> dict[str, str]:
    return {"Authorization": f"Bearer {token}"}


def _get_me(client: TestClient, token: str) -> dict:
    return client.get("/api/auth/me", headers=_auth_header(token)).json()


# ── Create Family ───────────────────────────────────────────────


def test_login_auto_creates_family(client: TestClient, db: Session) -> None:
    _create_admin(db)
    token = _login(client)
    me = _get_me(client, token)
    assert me["family_id"] is not None


def test_create_family_already_exists(client: TestClient, db: Session) -> None:
    _create_admin(db)
    token = _login(client)
    response = client.post(
        "/api/families",
        json={"name": "另一个家庭"},
        headers=_auth_header(token),
    )
    assert response.status_code == 409


def test_create_family_unauthenticated(client: TestClient) -> None:
    response = client.post("/api/families", json={"name": "快乐家庭"})
    assert response.status_code == 401


# ── Get Family ──────────────────────────────────────────────────


def test_get_family_success(client: TestClient, db: Session) -> None:
    _create_admin(db)
    token = _login(client)
    me = _get_me(client, token)
    family_id = me["family_id"]
    response = client.get(f"/api/families/{family_id}", headers=_auth_header(token))
    assert response.status_code == 200
    assert "管理员" in [m["nickname"] for m in response.json()["members"]]


def test_get_family_not_found(client: TestClient, db: Session) -> None:
    _create_admin(db)
    token = _login(client)
    response = client.get("/api/families/999", headers=_auth_header(token))
    assert response.status_code == 404


def test_update_family_name_success(client: TestClient, db: Session) -> None:
    _create_admin(db)
    token = _login(client)
    me = _get_me(client, token)
    family_id = me["family_id"]
    response = client.put(
        f"/api/families/{family_id}",
        json={"name": "\u6211\u4eec\u7684\u5feb\u4e50\u5c0f\u5c4b"},
        headers=_auth_header(token),
    )
    assert response.status_code == 200
    assert response.json()["name"] == "\u6211\u4eec\u7684\u5feb\u4e50\u5c0f\u5c4b"


# ── Add Member ──────────────────────────────────────────────────


def test_add_member_success(client: TestClient, db: Session) -> None:
    _create_admin(db)
    token = _login(client)
    me = _get_me(client, token)
    family_id = me["family_id"]
    response = client.post(
        f"/api/families/{family_id}/members",
        json={"nickname": "小明"},
        headers=_auth_header(token),
    )
    assert response.status_code == 201
    assert response.json()["nickname"] == "小明"
    assert response.json()["role"] == "child"


# ── List Members ────────────────────────────────────────────────


def test_list_members_success(client: TestClient, db: Session) -> None:
    _create_admin(db)
    token = _login(client)
    me = _get_me(client, token)
    family_id = me["family_id"]
    client.post(
        f"/api/families/{family_id}/members",
        json={"nickname": "小明"},
        headers=_auth_header(token),
    )
    client.post(
        f"/api/families/{family_id}/members",
        json={"nickname": "小红"},
        headers=_auth_header(token),
    )
    response = client.get(f"/api/families/{family_id}/members", headers=_auth_header(token))
    assert response.status_code == 200
    assert len(response.json()) == 3  # admin + 2 children


# ── Delete Member ───────────────────────────────────────────────


def test_delete_member_success(client: TestClient, db: Session) -> None:
    _create_admin(db)
    token = _login(client)
    me = _get_me(client, token)
    family_id = me["family_id"]
    member_resp = client.post(
        f"/api/families/{family_id}/members",
        json={"nickname": "小明"},
        headers=_auth_header(token),
    )
    member_id = member_resp.json()["id"]
    response = client.delete(
        f"/api/families/{family_id}/members/{member_id}",
        headers=_auth_header(token),
    )
    assert response.status_code == 204
