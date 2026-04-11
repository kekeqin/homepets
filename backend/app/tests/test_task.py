from typing import Any

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

    me = client.get("/api/auth/me", headers=headers).json()
    family_id = me["family_id"]

    member_resp = client.post(
        f"/api/families/{family_id}/members",
        json={"nickname": "小明"},
        headers=headers,
    )
    child_id = member_resp.json()["id"]
    return token, family_id, child_id


def _create_task(client: TestClient, token: str, family_id: int) -> Any:
    headers = {"Authorization": f"Bearer {token}"}
    resp = client.post(
        "/api/tasks",
        json={"title": "打扫房间", "points": 20},
        headers=headers,
    )
    return resp.json()


def _get_admin_egg(client: TestClient, token: str, family_id: int) -> dict:
    headers = {"Authorization": f"Bearer {token}"}
    me = client.get("/api/auth/me", headers=headers).json()
    pets = client.get(f"/api/families/{family_id}/pets", headers=headers).json()
    eggs = [p for p in pets if p["owner_id"] == me["id"] and p["pet_form"] == "egg"]
    return eggs[0]


def test_create_task_success(client: TestClient, db: Session) -> None:
    token, _, _ = _setup_family(client, db)
    headers = {"Authorization": f"Bearer {token}"}
    response = client.post(
        "/api/tasks",
        json={"title": "打扫房间", "points": 20},
        headers=headers,
    )
    assert response.status_code == 201
    data = response.json()
    assert data["title"] == "打扫房间"
    assert data["points"] == 20


def test_create_task_unauthenticated(client: TestClient, db: Session) -> None:
    response = client.post("/api/tasks", json={"title": "打扫房间", "points": 20})
    assert response.status_code == 401


def test_list_tasks_success(client: TestClient, db: Session) -> None:
    token, family_id, _ = _setup_family(client, db)
    headers = {"Authorization": f"Bearer {token}"}
    client.post("/api/tasks", json={"title": "任务1", "points": 10}, headers=headers)
    client.post("/api/tasks", json={"title": "任务2", "points": 20}, headers=headers)
    response = client.get(f"/api/families/{family_id}/tasks", headers=headers)
    assert response.status_code == 200
    assert len(response.json()) == 2


def test_list_tasks_success_after_completion(client: TestClient, db: Session) -> None:
    token, family_id, _ = _setup_family(client, db)
    headers = {"Authorization": f"Bearer {token}"}
    task = client.post(
        "/api/tasks",
        json={"title": "浇花", "points": 10},
        headers=headers,
    ).json()

    completion_response = client.post(
        f"/api/tasks/{task['id']}/completions",
        headers=headers,
    )
    assert completion_response.status_code == 201

    response = client.get(f"/api/families/{family_id}/tasks", headers=headers)
    assert response.status_code == 200
    assert response.json()[0]["completed_today"] is True
    assert response.json()[0]["completed_this_week"] is True


def test_task_overview_counts_deleted_task_completions(client: TestClient, db: Session) -> None:
    token, family_id, _ = _setup_family(client, db)
    headers = {"Authorization": f"Bearer {token}"}

    first_task = client.post(
        "/api/tasks",
        json={"title": "任务一", "points": 10},
        headers=headers,
    ).json()
    second_task = client.post(
        "/api/tasks",
        json={"title": "任务二", "points": 20},
        headers=headers,
    ).json()

    first_completion = client.post(
        f"/api/tasks/{first_task['id']}/completions",
        headers=headers,
    )
    second_completion = client.post(
        f"/api/tasks/{second_task['id']}/completions",
        headers=headers,
    )
    assert first_completion.status_code == 201
    assert second_completion.status_code == 201

    delete_response = client.delete(f"/api/tasks/{first_task['id']}", headers=headers)
    assert delete_response.status_code == 204

    overview_response = client.get(
        f"/api/families/{family_id}/tasks/overview",
        headers=headers,
    )
    assert overview_response.status_code == 200
    overview = overview_response.json()
    assert overview["today_completed_count"] == 2
    assert overview["week_completed_count"] == 2
    assert len(overview["active_tasks"]) == 1

    deleted_log = next(
        log for log in overview["recent_completions"] if log["task_id"] == first_task["id"]
    )
    assert deleted_log["title"] == "任务一"
    assert deleted_log["is_task_active"] is False


def test_update_task_success(client: TestClient, db: Session) -> None:
    token, family_id, _ = _setup_family(client, db)
    headers = {"Authorization": f"Bearer {token}"}
    task = _create_task(client, token, family_id)
    task_id = task["id"]
    response = client.put(
        f"/api/tasks/{task_id}",
        json={"title": "打扫客厅", "points": 30},
        headers=headers,
    )
    assert response.status_code == 200
    assert response.json()["title"] == "打扫客厅"
    assert response.json()["points"] == 30


def test_delete_task_success(client: TestClient, db: Session) -> None:
    token, family_id, _ = _setup_family(client, db)
    headers = {"Authorization": f"Bearer {token}"}
    task = _create_task(client, token, family_id)
    task_id = task["id"]
    response = client.delete(f"/api/tasks/{task_id}", headers=headers)
    assert response.status_code == 204


def test_submit_completion_success(client: TestClient, db: Session) -> None:
    token, family_id, _ = _setup_family(client, db)
    headers = {"Authorization": f"Bearer {token}"}
    task = _create_task(client, token, family_id)
    task_id = task["id"]
    response = client.post(f"/api/tasks/{task_id}/completions", headers=headers)
    assert response.status_code == 201
    data = response.json()
    assert data["task_id"] == task_id
    assert data["status"] == "approved"


def test_review_approve_feeds_pet(client: TestClient, db: Session) -> None:
    token, family_id, _ = _setup_family(client, db)
    headers = {"Authorization": f"Bearer {token}"}

    egg = _get_admin_egg(client, token, family_id)
    assert egg["experience"] == 0

    task = _create_task(client, token, family_id)
    assert task["points"] == 20

    comp_resp = client.post(f"/api/tasks/{task['id']}/completions", headers=headers)
    assert comp_resp.status_code == 201
    assert comp_resp.json()["status"] == "approved"

    pet_check = client.get(f"/api/families/{family_id}/pets", headers=headers)
    my_egg = next(p for p in pet_check.json() if p["id"] == egg["id"])
    assert my_egg["experience"] == 20


def test_completion_auto_feeds_pet(client: TestClient, db: Session) -> None:
    token, family_id, _ = _setup_family(client, db)
    headers = {"Authorization": f"Bearer {token}"}

    egg = _get_admin_egg(client, token, family_id)
    assert egg["experience"] == 0

    task = _create_task(client, token, family_id)
    client.post(f"/api/tasks/{task['id']}/completions", headers=headers)

    pet_check = client.get(f"/api/families/{family_id}/pets", headers=headers)
    my_egg = next(p for p in pet_check.json() if p["id"] == egg["id"])
    assert my_egg["experience"] == 20


def test_list_completions(client: TestClient, db: Session) -> None:
    token, family_id, _ = _setup_family(client, db)
    headers = {"Authorization": f"Bearer {token}"}

    task1 = _create_task(client, token, family_id)
    task2_resp = client.post(
        "/api/tasks",
        json={"title": "洗碗", "points": 15},
        headers=headers,
    )
    task2 = task2_resp.json()

    client.post(f"/api/tasks/{task1['id']}/completions", headers=headers)
    client.post(f"/api/tasks/{task2['id']}/completions", headers=headers)

    response = client.get(
        f"/api/families/{family_id}/completions",
        headers=headers,
    )
    assert response.status_code == 200
    data = response.json()
    assert len(data) == 2
    assert data[0]["task_title"] is not None
    assert "task_points" in data[0]
    assert "task_is_active" in data[0]


def test_list_quest_logs(client: TestClient, db: Session) -> None:
    token, family_id, _ = _setup_family(client, db)
    headers = {"Authorization": f"Bearer {token}"}

    task1 = client.post(
        "/api/tasks",
        json={"title": "收拾书桌", "points": 12},
        headers=headers,
    ).json()
    task2 = client.post(
        "/api/tasks",
        json={"title": "周末远足", "points": 40},
        headers=headers,
    ).json()

    client.post(f"/api/tasks/{task1['id']}/completions", headers=headers)
    client.post(f"/api/tasks/{task2['id']}/completions", headers=headers)

    response = client.get(
        f"/api/families/{family_id}/quest-logs",
        headers=headers,
    )
    assert response.status_code == 200
    data = response.json()
    assert len(data) == 2
    assert data[0]["title"]
    assert data[0]["points"] >= 0
    assert "completed_at" in data[0]


def test_quest_logs_keep_deleted_task_details(client: TestClient, db: Session) -> None:
    token, family_id, _ = _setup_family(client, db)
    headers = {"Authorization": f"Bearer {token}"}

    task = client.post(
        "/api/tasks",
        json={"title": "可追溯任务", "points": 18},
        headers=headers,
    ).json()

    completion_response = client.post(
        f"/api/tasks/{task['id']}/completions",
        headers=headers,
    )
    assert completion_response.status_code == 201

    delete_response = client.delete(f"/api/tasks/{task['id']}", headers=headers)
    assert delete_response.status_code == 204

    response = client.get(
        f"/api/families/{family_id}/quest-logs",
        headers=headers,
    )
    assert response.status_code == 200
    log = next(item for item in response.json() if item["task_id"] == task["id"])
    assert log["title"] == "可追溯任务"
    assert log["is_task_active"] is False
