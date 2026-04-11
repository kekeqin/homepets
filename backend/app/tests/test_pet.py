from fastapi.testclient import TestClient
from sqlmodel import Session

from app.core.security import hash_password
from app.models.user import User


def _setup_family(client: TestClient, db: Session) -> tuple[str, int, int]:
    admin = User(
        phone="13800000001",
        password_hash=hash_password("testpass123"),
        nickname="管理员",
        role="admin",
    )
    db.add(admin)
    db.commit()
    db.refresh(admin)

    token = client.post(
        "/api/auth/login", json={"phone": "13800000001", "password": "testpass123"}
    ).json()["access_token"]
    headers = {"Authorization": f"Bearer {token}"}

    # Family is auto-created on login, get it from /me
    me = client.get("/api/auth/me", headers=headers).json()
    family_id = me["family_id"]

    member_resp = client.post(
        f"/api/families/{family_id}/members",
        json={"nickname": "小明"},
        headers=headers,
    )
    child_id = member_resp.json()["id"]
    return token, family_id, child_id


def _get_pets(client: TestClient, token: str, family_id: int) -> list[dict]:
    headers = {"Authorization": f"Bearer {token}"}
    resp = client.get(f"/api/families/{family_id}/pets", headers=headers)
    return resp.json()


# ── Auto Egg Creation ──────────────────────────────────────────


def test_auto_egg_on_family_create(client: TestClient, db: Session) -> None:
    token, family_id, _ = _setup_family(client, db)
    pets = _get_pets(client, token, family_id)
    admin_eggs = [p for p in pets if p["pet_form"] == "egg" and p["owner_nickname"] == "管理员"]
    assert len(admin_eggs) == 1
    assert admin_eggs[0]["pet_type"] == "egg"
    assert admin_eggs[0]["name"] == "宠物蛋"


def test_auto_egg_on_add_member(client: TestClient, db: Session) -> None:
    token, family_id, _ = _setup_family(client, db)
    pets = _get_pets(client, token, family_id)
    child_eggs = [p for p in pets if p["pet_form"] == "egg" and p["owner_nickname"] == "小明"]
    assert len(child_eggs) == 1


def test_list_pets_shows_owner(client: TestClient, db: Session) -> None:
    token, family_id, _ = _setup_family(client, db)
    pets = _get_pets(client, token, family_id)
    for pet in pets:
        assert "owner_nickname" in pet
        assert pet["owner_nickname"] is not None


# ── Hatch ───────────────────────────────────────────────────────


def test_hatch_egg_success(client: TestClient, db: Session) -> None:
    token, family_id, _ = _setup_family(client, db)
    headers = {"Authorization": f"Bearer {token}"}
    pets = _get_pets(client, token, family_id)
    egg = [p for p in pets if p["pet_form"] == "egg"][0]

    client.post(f"/api/pets/{egg['id']}/feed", json={"points": 30}, headers=headers)
    resp = client.post(
        f"/api/pets/{egg['id']}/hatch",
        json={"pet_type": "cat", "name": "咪咪"},
        headers=headers,
    )
    assert resp.status_code == 200
    data = resp.json()
    assert data["pet_form"] == "pet"
    assert data["pet_type"] == "cat"
    assert data["name"] == "咪咪"
    assert data["level"] == 1


def test_hatch_insufficient_exp(client: TestClient, db: Session) -> None:
    token, family_id, _ = _setup_family(client, db)
    headers = {"Authorization": f"Bearer {token}"}
    pets = _get_pets(client, token, family_id)
    egg = [p for p in pets if p["pet_form"] == "egg"][0]

    client.post(f"/api/pets/{egg['id']}/feed", json={"points": 10}, headers=headers)
    resp = client.post(
        f"/api/pets/{egg['id']}/hatch",
        json={"pet_type": "cat", "name": "咪咪"},
        headers=headers,
    )
    assert resp.status_code == 400


def test_hatch_already_hatched(client: TestClient, db: Session) -> None:
    token, family_id, _ = _setup_family(client, db)
    headers = {"Authorization": f"Bearer {token}"}
    pets = _get_pets(client, token, family_id)
    egg = [p for p in pets if p["pet_form"] == "egg"][0]

    client.post(f"/api/pets/{egg['id']}/feed", json={"points": 30}, headers=headers)
    client.post(
        f"/api/pets/{egg['id']}/hatch",
        json={"pet_type": "cat", "name": "咪咪"},
        headers=headers,
    )
    resp = client.post(
        f"/api/pets/{egg['id']}/hatch",
        json={"pet_type": "dog", "name": "旺财"},
        headers=headers,
    )
    assert resp.status_code == 400


# ── Feed ────────────────────────────────────────────────────────


def test_feed_egg_increases_exp(client: TestClient, db: Session) -> None:
    token, family_id, _ = _setup_family(client, db)
    headers = {"Authorization": f"Bearer {token}"}
    pets = _get_pets(client, token, family_id)
    egg = [p for p in pets if p["pet_form"] == "egg"][0]

    resp = client.post(f"/api/pets/{egg['id']}/feed", json={"points": 20}, headers=headers)
    assert resp.status_code == 200
    assert resp.json()["experience"] == 20
    assert resp.json()["pet_form"] == "egg"


def test_feed_pet_levels_up(client: TestClient, db: Session) -> None:
    token, family_id, _ = _setup_family(client, db)
    headers = {"Authorization": f"Bearer {token}"}
    pets = _get_pets(client, token, family_id)
    egg = [p for p in pets if p["pet_form"] == "egg"][0]

    client.post(f"/api/pets/{egg['id']}/feed", json={"points": 30}, headers=headers)
    client.post(
        f"/api/pets/{egg['id']}/hatch",
        json={"pet_type": "cat", "name": "咪咪"},
        headers=headers,
    )
    resp = client.post(f"/api/pets/{egg['id']}/feed", json={"points": 100}, headers=headers)
    assert resp.status_code == 200
    data = resp.json()
    assert data["experience"] == 100
    assert data["level"] == 2


def test_pet_history_includes_feed_records(client: TestClient, db: Session) -> None:
    token, family_id, _ = _setup_family(client, db)
    headers = {"Authorization": f"Bearer {token}"}
    pets = _get_pets(client, token, family_id)
    egg = [p for p in pets if p["pet_form"] == "egg"][0]

    feed_response = client.post(
        f"/api/pets/{egg['id']}/feed",
        json={"points": 20},
        headers=headers,
    )
    assert feed_response.status_code == 200

    history_response = client.get(f"/api/pets/{egg['id']}/history", headers=headers)
    assert history_response.status_code == 200

    history = history_response.json()
    assert len(history) >= 1
    assert history[0]["task_title"] == "喂养记录"
    assert history[0]["points"] == 20
    assert history[0]["event_type"] == "feed"
