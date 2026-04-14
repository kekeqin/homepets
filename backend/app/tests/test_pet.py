from fastapi.testclient import TestClient
from sqlmodel import Session

from app.core.security import hash_password
from app.models.user import User


def _setup_family(client: TestClient, db: Session) -> tuple[str, int, int]:
    admin = User(
        phone="13800000001",
        password_hash=hash_password("testpass123"),
        nickname="Admin",
        role="admin",
    )
    db.add(admin)
    db.commit()
    db.refresh(admin)

    token = client.post(
        "/api/auth/login",
        json={"phone": "13800000001", "password": "testpass123"},
    ).json()["access_token"]
    headers = {"Authorization": f"Bearer {token}"}

    family_id = client.get("/api/auth/me", headers=headers).json()["family_id"]
    child_id = client.post(
        f"/api/families/{family_id}/members",
        json={"nickname": "Ming"},
        headers=headers,
    ).json()["id"]
    return token, family_id, child_id


def _auth_header(token: str) -> dict[str, str]:
    return {"Authorization": f"Bearer {token}"}


def _get_pets(client: TestClient, token: str, family_id: int) -> list[dict]:
    response = client.get(f"/api/families/{family_id}/pets", headers=_auth_header(token))
    return list(response.json())


def _assign_pet(
    client: TestClient,
    token: str,
    family_id: int,
    member_id: int,
    pet_type: str = "cat",
    name: str = "Mimi",
) -> dict:
    response = client.put(
        f"/api/families/{family_id}/members/{member_id}/pet",
        json={"pet_type": pet_type, "name": name},
        headers=_auth_header(token),
    )
    assert response.status_code == 200
    return response.json()


def test_add_member_no_longer_auto_creates_pet(client: TestClient, db: Session) -> None:
    token, family_id, child_id = _setup_family(client, db)
    pets = _get_pets(client, token, family_id)
    assert [pet for pet in pets if pet["owner_id"] == child_id] == []


def test_set_member_pet_creates_selected_pet_with_name(client: TestClient, db: Session) -> None:
    token, family_id, child_id = _setup_family(client, db)
    _assign_pet(client, token, family_id, child_id, pet_type="hamster", name="Doudou")

    pets = _get_pets(client, token, family_id)
    child_pet = next(pet for pet in pets if pet["owner_id"] == child_id)
    assert child_pet["pet_type"] == "hamster"
    assert child_pet["name"] == "Doudou"
    assert child_pet["pet_form"] == "pet"


def test_list_pets_shows_owner(client: TestClient, db: Session) -> None:
    token, family_id, child_id = _setup_family(client, db)
    _assign_pet(client, token, family_id, child_id)

    pets = _get_pets(client, token, family_id)
    assert len(pets) == 1
    assert pets[0]["owner_nickname"] == "Ming"


def test_feed_pet_increases_exp(client: TestClient, db: Session) -> None:
    token, family_id, child_id = _setup_family(client, db)
    _assign_pet(client, token, family_id, child_id)
    pet = _get_pets(client, token, family_id)[0]

    response = client.post(
        f"/api/pets/{pet['id']}/feed",
        json={"points": 20},
        headers=_auth_header(token),
    )
    assert response.status_code == 200
    assert response.json()["experience"] == 20
    assert response.json()["pet_form"] == "pet"


def test_feed_pet_levels_up(client: TestClient, db: Session) -> None:
    token, family_id, child_id = _setup_family(client, db)
    _assign_pet(client, token, family_id, child_id)
    pet = _get_pets(client, token, family_id)[0]

    response = client.post(
        f"/api/pets/{pet['id']}/feed",
        json={"points": 100},
        headers=_auth_header(token),
    )
    assert response.status_code == 200
    assert response.json()["experience"] == 100
    assert response.json()["level"] == 2


def test_pet_history_includes_feed_records(client: TestClient, db: Session) -> None:
    token, family_id, child_id = _setup_family(client, db)
    _assign_pet(client, token, family_id, child_id)
    pet = _get_pets(client, token, family_id)[0]

    feed_response = client.post(
        f"/api/pets/{pet['id']}/feed",
        json={"points": 20},
        headers=_auth_header(token),
    )
    assert feed_response.status_code == 200

    history_response = client.get(
        f"/api/pets/{pet['id']}/history",
        headers=_auth_header(token),
    )
    assert history_response.status_code == 200
    history = history_response.json()
    assert len(history) >= 1
    assert history[0]["event_type"] == "feed"
    assert history[0]["points"] == 20
