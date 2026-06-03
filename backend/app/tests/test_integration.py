"""Integration test: full flow from registration to member pet growth."""

from fastapi.testclient import TestClient
from sqlmodel import Session


def test_full_flow(client: TestClient, db: Session) -> None:
    login_response = client.post(
        "/api/auth/login",
        json={"phone": "13800000001", "code": "123456"},
    )
    assert login_response.status_code == 200
    token = login_response.json()["access_token"]
    headers = {"Authorization": f"Bearer {token}"}

    me = client.get("/api/auth/me", headers=headers).json()
    admin_id = me["id"]
    family_id = me["family_id"]

    child_id = client.post(
        f"/api/families/{family_id}/members",
        json={"nickname": "Kid"},
        headers=headers,
    ).json()["id"]

    select_pet_response = client.put(
        f"/api/families/{family_id}/members/{child_id}/pet",
        json={"pet_type": "cat", "name": "Mimi"},
        headers=headers,
    )
    assert select_pet_response.status_code == 200

    pets_response = client.get(f"/api/families/{family_id}/pets", headers=headers)
    family_pets = pets_response.json()
    child_pet = next(pet for pet in family_pets if pet["owner_id"] == child_id)
    assert child_pet["pet_type"] == "cat"
    assert child_pet["name"] == "Mimi"

    task_id = client.post(
        f"/api/families/{family_id}/tasks",
        json={"title": "Clean room", "points": 80},
        headers=headers,
    ).json()["id"]

    completion_response = client.post(
        f"/api/tasks/{task_id}/completions",
        json={"member_id": child_id},
        headers=headers,
    )
    assert completion_response.status_code == 201

    pet_check = client.get(f"/api/families/{family_id}/pets", headers=headers).json()
    refreshed_pet = next(pet for pet in pet_check if pet["id"] == child_pet["id"])
    assert refreshed_pet["experience"] == 80
    assert refreshed_pet["level"] == 1

    profile_response = client.put(
        f"/api/users/{admin_id}",
        json={"nickname": "Super Parent"},
        headers=headers,
    )
    assert profile_response.status_code == 200
    assert profile_response.json()["nickname"] == "Super Parent"

    family_response = client.get(f"/api/families/{family_id}", headers=headers)
    assert family_response.status_code == 200
    assert len(family_response.json()["members"]) == 2
