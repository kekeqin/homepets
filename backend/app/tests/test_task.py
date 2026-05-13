from typing import Any

from fastapi.testclient import TestClient
from sqlmodel import Session

from app.core.security import hash_password
from app.models.user import User


def _setup_family(client: TestClient, db: Session) -> tuple[str, int, int, int]:
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

    me = client.get("/api/auth/me", headers=headers).json()
    family_id = me["family_id"]
    member_id = client.post(
        f"/api/families/{family_id}/members",
        json={"nickname": "Ming"},
        headers=headers,
    ).json()["id"]
    client.put(
        f"/api/families/{family_id}/members/{member_id}/pet",
        json={"pet_type": "cat", "name": "Mimi"},
        headers=headers,
    )
    pet_id = next(
        pet["id"]
        for pet in client.get(f"/api/families/{family_id}/pets", headers=headers).json()
        if pet["owner_id"] == member_id
    )
    return token, family_id, member_id, pet_id


def _auth_header(token: str) -> dict[str, str]:
    return {"Authorization": f"Bearer {token}"}


def _create_task(
    client: TestClient, token: str, title: str = "Clean room", points: int = 20
) -> Any:
    response = client.post(
        "/api/tasks",
        json={"title": title, "points": points},
        headers=_auth_header(token),
    )
    return response.json()


def test_create_task_success(client: TestClient, db: Session) -> None:
    token, _, _, _ = _setup_family(client, db)
    response = client.post(
        "/api/tasks",
        json={"title": "Clean room", "points": 20},
        headers=_auth_header(token),
    )
    assert response.status_code == 201
    assert response.json()["points"] == 20


def test_list_tasks_success_after_completion(client: TestClient, db: Session) -> None:
    token, family_id, _, _ = _setup_family(client, db)
    task = _create_task(client, token, title="Water plants", points=10)
    response = client.post(
        f"/api/tasks/{task['id']}/completions",
        headers=_auth_header(token),
    )
    assert response.status_code == 201

    tasks_response = client.get(
        f"/api/families/{family_id}/tasks",
        headers=_auth_header(token),
    )
    assert tasks_response.status_code == 200
    assert tasks_response.json()[0]["completed_today"] is True


def test_completion_auto_feeds_member_pet(client: TestClient, db: Session) -> None:
    token, family_id, member_id, pet_id = _setup_family(client, db)
    task = _create_task(client, token, title="Read book", points=20)

    response = client.post(
        f"/api/tasks/{task['id']}/completions",
        json={"member_id": member_id},
        headers=_auth_header(token),
    )
    assert response.status_code == 201

    pets = client.get(f"/api/families/{family_id}/pets", headers=_auth_header(token)).json()
    member_pet = next(pet for pet in pets if pet["id"] == pet_id)
    assert member_pet["experience"] == 20


def test_completion_levels_member_pet(client: TestClient, db: Session) -> None:
    token, family_id, member_id, pet_id = _setup_family(client, db)
    task = _create_task(client, token, title="Read book", points=100)

    response = client.post(
        f"/api/tasks/{task['id']}/completions",
        json={"member_id": member_id},
        headers=_auth_header(token),
    )
    assert response.status_code == 201

    pets = client.get(f"/api/families/{family_id}/pets", headers=_auth_header(token)).json()
    member_pet = next(pet for pet in pets if pet["id"] == pet_id)
    assert member_pet["experience"] == 100
    assert member_pet["level"] == 2


def test_list_completions(client: TestClient, db: Session) -> None:
    token, family_id, _, _ = _setup_family(client, db)
    task = _create_task(client, token, title="Wash bowl", points=15)
    client.post(f"/api/tasks/{task['id']}/completions", headers=_auth_header(token))

    response = client.get(
        f"/api/families/{family_id}/completions",
        headers=_auth_header(token),
    )
    assert response.status_code == 200
    assert len(response.json()) == 1
    assert response.json()[0]["task_title"] == "Wash bowl"


def test_quest_logs_endpoint_removed(client: TestClient, db: Session) -> None:
    token, family_id, _, _ = _setup_family(client, db)
    task = _create_task(client, token, title="Weekend walk", points=40)
    client.post(f"/api/tasks/{task['id']}/completions", headers=_auth_header(token))

    response = client.get(
        f"/api/families/{family_id}/quest-logs",
        headers=_auth_header(token),
    )
    assert response.status_code == 404


def test_task_overview_endpoint_removed(client: TestClient, db: Session) -> None:
    token, family_id, _, _ = _setup_family(client, db)

    response = client.get(
        f"/api/families/{family_id}/tasks/overview",
        headers=_auth_header(token),
    )
    assert response.status_code == 404
