from fastapi.testclient import TestClient
from sqlmodel import Session

from app.models.family import Family
from app.models.user import User


def _create_admin(db: Session, phone: str = "13800000001") -> User:
    user = User(
        phone=phone,
        nickname="Admin",
        role="admin",
    )
    db.add(user)
    db.commit()
    db.refresh(user)
    return user


def _login(client: TestClient, phone: str = "13800000001") -> str:
    response = client.post(
        "/api/auth/login",
        json={"phone": phone, "code": "123456"},
    )
    return str(response.json()["access_token"])


def _auth_header(token: str) -> dict[str, str]:
    return {"Authorization": f"Bearer {token}"}


def _get_me(client: TestClient, token: str) -> dict:
    return client.get("/api/auth/me", headers=_auth_header(token)).json()


def _list_pets(client: TestClient, token: str, family_id: int) -> list[dict]:
    response = client.get(f"/api/families/{family_id}/pets", headers=_auth_header(token))
    return list(response.json())


def test_login_auto_creates_family(client: TestClient, db: Session) -> None:
    _create_admin(db)
    token = _login(client)
    me = _get_me(client, token)
    assert me["family_id"] is not None


def test_get_family_success(client: TestClient, db: Session) -> None:
    _create_admin(db)
    token = _login(client)
    family_id = _get_me(client, token)["family_id"]
    response = client.get(f"/api/families/{family_id}", headers=_auth_header(token))
    assert response.status_code == 200
    assert "Admin" in [member["nickname"] for member in response.json()["members"]]


def test_get_family_normalizes_legacy_default_family_name(client: TestClient, db: Session) -> None:
    admin = _create_admin(db)
    family = Family(name="Admin的家庭", owner_id=admin.id)
    db.add(family)
    db.commit()
    db.refresh(family)
    admin.family_id = family.id
    db.add(admin)
    db.commit()

    token = _login(client)
    response = client.get(f"/api/families/{family.id}", headers=_auth_header(token))

    assert response.status_code == 200
    assert response.json()["name"] == "Admin的家"


def test_add_member_success_requires_pet_selection(client: TestClient, db: Session) -> None:
    _create_admin(db)
    token = _login(client)
    family_id = _get_me(client, token)["family_id"]

    response = client.post(
        f"/api/families/{family_id}/members",
        json={"nickname": "Ming"},
        headers=_auth_header(token),
    )

    assert response.status_code == 201
    data = response.json()
    assert data["nickname"] == "Ming"
    assert data["role"] == "child"
    assert data["needs_pet_selection"] is True
    assert data["pet_type"] is None


def test_add_member_can_create_selected_pet_in_one_request(
    client: TestClient,
    db: Session,
) -> None:
    _create_admin(db)
    token = _login(client)
    family_id = _get_me(client, token)["family_id"]

    response = client.post(
        f"/api/families/{family_id}/members",
        json={"nickname": "Ming", "pet_type": "dog", "pet_name": "Tuantuan"},
        headers=_auth_header(token),
    )

    assert response.status_code == 201
    data = response.json()
    assert data["nickname"] == "Ming"
    assert data["pet_type"] == "dog"
    assert data["pet_id"] is not None
    assert data["needs_pet_selection"] is False

    pets = _list_pets(client, token, family_id)
    member_pet = next(pet for pet in pets if pet["owner_id"] == data["id"])
    assert member_pet["name"] == "Tuantuan"
    assert member_pet["pet_type"] == "dog"


def test_set_member_pet_success_with_name(client: TestClient, db: Session) -> None:
    _create_admin(db)
    token = _login(client)
    family_id = _get_me(client, token)["family_id"]
    member_id = client.post(
        f"/api/families/{family_id}/members",
        json={"nickname": "Ming"},
        headers=_auth_header(token),
    ).json()["id"]

    response = client.put(
        f"/api/families/{family_id}/members/{member_id}/pet",
        json={"pet_type": "rabbit", "name": "Tuantuan"},
        headers=_auth_header(token),
    )
    assert response.status_code == 200
    assert response.json()["pet_type"] == "rabbit"
    assert response.json()["needs_pet_selection"] is False

    pets = _list_pets(client, token, family_id)
    member_pet = next(pet for pet in pets if pet["owner_id"] == member_id)
    assert member_pet["name"] == "Tuantuan"
    assert "pet_form" not in member_pet
    assert "image_url" not in member_pet


def test_list_members_success(client: TestClient, db: Session) -> None:
    _create_admin(db)
    token = _login(client)
    family_id = _get_me(client, token)["family_id"]

    client.post(
        f"/api/families/{family_id}/members",
        json={"nickname": "Ming"},
        headers=_auth_header(token),
    )
    client.post(
        f"/api/families/{family_id}/members",
        json={"nickname": "Hong"},
        headers=_auth_header(token),
    )

    response = client.get(f"/api/families/{family_id}/members", headers=_auth_header(token))
    assert response.status_code == 200
    assert len(response.json()) == 3


def test_delete_member_success(client: TestClient, db: Session) -> None:
    _create_admin(db)
    token = _login(client)
    family_id = _get_me(client, token)["family_id"]
    member_id = client.post(
        f"/api/families/{family_id}/members",
        json={"nickname": "Ming"},
        headers=_auth_header(token),
    ).json()["id"]

    response = client.delete(
        f"/api/families/{family_id}/members/{member_id}",
        headers=_auth_header(token),
    )
    assert response.status_code == 204


def test_delete_member_removes_bound_pet_from_family_pets(
    client: TestClient,
    db: Session,
) -> None:
    _create_admin(db)
    token = _login(client)
    family_id = _get_me(client, token)["family_id"]
    member_id = client.post(
        f"/api/families/{family_id}/members",
        json={"nickname": "Ming"},
        headers=_auth_header(token),
    ).json()["id"]

    pet_response = client.put(
        f"/api/families/{family_id}/members/{member_id}/pet",
        json={"pet_type": "rabbit", "name": "Tuantuan"},
        headers=_auth_header(token),
    )
    assert pet_response.status_code == 200
    assert any(pet["owner_id"] == member_id for pet in _list_pets(client, token, family_id))

    response = client.delete(
        f"/api/families/{family_id}/members/{member_id}",
        headers=_auth_header(token),
    )

    assert response.status_code == 204
    assert all(pet["owner_id"] != member_id for pet in _list_pets(client, token, family_id))
