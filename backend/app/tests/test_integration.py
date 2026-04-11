"""Integration test: full flow from registration to pet growth."""

from fastapi.testclient import TestClient
from sqlmodel import Session


def test_full_flow(client: TestClient, db: Session) -> None:
    # 1. Register admin
    reg_resp = client.post(
        "/api/auth/register",
        json={"phone": "13800000001", "password": "password123", "nickname": "爸爸"},
    )
    assert reg_resp.status_code == 201
    admin_id = reg_resp.json()["id"]

    # 2. Login
    login_resp = client.post(
        "/api/auth/login",
        json={"phone": "13800000001", "password": "password123"},
    )
    assert login_resp.status_code == 200
    token = login_resp.json()["access_token"]
    headers = {"Authorization": f"Bearer {token}"}

    # 3. Family is auto-created on login, get it from /me
    me = client.get("/api/auth/me", headers=headers).json()
    family_id = me["family_id"]

    # 4. Add child member (auto-creates egg for child)
    child_resp = client.post(
        f"/api/families/{family_id}/members",
        json={"nickname": "小明"},
        headers=headers,
    )
    assert child_resp.status_code == 201
    child_resp.json()["id"]

    # 5. Verify admin has an egg
    pets_resp = client.get(f"/api/families/{family_id}/pets", headers=headers)
    admin_eggs = [
        p for p in pets_resp.json() if p["owner_id"] == admin_id and p["pet_form"] == "egg"
    ]
    assert len(admin_eggs) == 1
    egg_id = admin_eggs[0]["id"]

    # 6. Feed egg to 30 exp
    feed_resp = client.post(f"/api/pets/{egg_id}/feed", json={"points": 30}, headers=headers)
    assert feed_resp.status_code == 200
    assert feed_resp.json()["experience"] == 30

    # 7. Hatch egg into a cat named 咪咪
    hatch_resp = client.post(
        f"/api/pets/{egg_id}/hatch",
        json={"pet_type": "cat", "name": "咪咪"},
        headers=headers,
    )
    assert hatch_resp.status_code == 200
    assert hatch_resp.json()["pet_form"] == "pet"
    assert hatch_resp.json()["pet_type"] == "cat"

    # 8. Create task
    task_resp = client.post(
        "/api/tasks",
        json={"title": "打扫房间", "points": 80},
        headers=headers,
    )
    assert task_resp.status_code == 201
    task_id = task_resp.json()["id"]

    # 9. Submit task completion (auto-approved, pet fed immediately)
    comp_resp = client.post(f"/api/tasks/{task_id}/completions", headers=headers)
    assert comp_resp.status_code == 201

    # 10. Verify pet got exp (80 points added)
    pet_check = client.get(f"/api/families/{family_id}/pets", headers=headers)
    my_pet = next(p for p in pet_check.json() if p["id"] == egg_id)
    assert my_pet["experience"] == 80
    assert my_pet["level"] == 1

    # 11. Update profile
    profile_resp = client.put(
        f"/api/users/{admin_id}",
        json={"nickname": "超级爸爸"},
        headers=headers,
    )
    assert profile_resp.status_code == 200
    assert profile_resp.json()["nickname"] == "超级爸爸"

    # 12. Get family with members
    family_check = client.get(f"/api/families/{family_id}", headers=headers)
    assert family_check.status_code == 200
    assert len(family_check.json()["members"]) == 2
