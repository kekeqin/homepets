from datetime import UTC, datetime, timedelta

from fastapi.testclient import TestClient
from sqlalchemy import desc
from sqlmodel import Session, select

from app.core.security import hash_password
from app.models.subscription import Subscription
from app.models.user import User
from app.services.subscription_service import as_utc


def _create_admin(db: Session, phone: str = "13800000001") -> User:
    user = User(
        phone=phone,
        password_hash=hash_password("testpass123"),
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
        json={"phone": phone, "password": "testpass123"},
    )
    return str(response.json()["access_token"])


def _auth_header(token: str) -> dict[str, str]:
    return {"Authorization": f"Bearer {token}"}


def _subscription(db: Session) -> Subscription:
    subscription = db.exec(select(Subscription).order_by(desc(Subscription.id))).first()
    assert subscription is not None
    db.refresh(subscription)
    return subscription


def test_register_creates_family_trial(client: TestClient, db: Session) -> None:
    before = datetime.now(UTC)
    response = client.post(
        "/api/auth/register",
        json={"phone": "13800000001", "password": "password123", "nickname": "爸爸"},
    )
    after = datetime.now(UTC)

    assert response.status_code == 201
    subscription = _subscription(db)
    assert subscription.family_id == response.json()["family_id"]
    assert subscription.revenuecat_app_user_id == f"family_{subscription.family_id}"
    trial_started_at = as_utc(subscription.trial_started_at)
    assert before <= trial_started_at <= after
    assert subscription.trial_ends_at == subscription.trial_started_at + timedelta(days=7)


def test_subscription_status_returns_trial_active(client: TestClient, db: Session) -> None:
    _create_admin(db)
    token = _login(client)

    response = client.get("/api/subscription/status", headers=_auth_header(token))

    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "trial_active"
    assert data["access_allowed"] is True
    assert data["paywall_required"] is False
    assert data["trial_days_remaining"] == 7
    assert data["scope"] == "family"


def test_expired_trial_allows_read_api_but_blocks_write_with_402(
    client: TestClient,
    db: Session,
) -> None:
    _create_admin(db)
    token = _login(client)
    headers = _auth_header(token)
    family_id = client.get("/api/auth/me", headers=_auth_header(token)).json()["family_id"]
    member_response = client.post(
        f"/api/families/{family_id}/members",
        json={"nickname": "Ming", "pet_type": "cat", "pet_name": "Mimi"},
        headers=headers,
    )
    assert member_response.status_code == 201
    task_response = client.post(
        f"/api/families/{family_id}/tasks",
        json={"title": "Water plants", "points": 10},
        headers=headers,
    )
    assert task_response.status_code == 201
    completion_response = client.post(
        f"/api/tasks/{task_response.json()['id']}/completions",
        json={"member_id": member_response.json()["id"]},
        headers=headers,
    )
    assert completion_response.status_code == 201

    subscription = _subscription(db)
    subscription.trial_started_at = datetime.now(UTC) - timedelta(days=8)
    subscription.trial_ends_at = datetime.now(UTC) - timedelta(days=1)
    subscription.status = "trial_active"
    db.add(subscription)
    db.commit()

    family_response = client.get(f"/api/families/{family_id}", headers=headers)
    members_response = client.get(f"/api/families/{family_id}/members", headers=headers)
    pets_response = client.get(f"/api/families/{family_id}/pets", headers=headers)
    tasks_response = client.get(f"/api/families/{family_id}/tasks", headers=headers)
    completions_response = client.get(
        f"/api/families/{family_id}/completions",
        headers=headers,
    )

    assert family_response.status_code == 200
    assert members_response.status_code == 200
    assert pets_response.status_code == 200
    assert tasks_response.status_code == 200
    assert completions_response.status_code == 200
    assert [member["nickname"] for member in family_response.json()["members"]] == [
        "Admin",
        "Ming",
    ]
    assert any(member["nickname"] == "Ming" for member in members_response.json())
    assert any(pet["name"] == "Mimi" for pet in pets_response.json())
    assert any(task["title"] == "Water plants" for task in tasks_response.json())
    assert any(
        completion["task_title"] == "Water plants"
        for completion in completions_response.json()
    )

    write_response = client.post(
        f"/api/families/{family_id}/tasks",
        json={"title": "Read-only blocked task", "points": 10},
        headers=headers,
    )

    assert write_response.status_code == 402
    detail = write_response.json()["detail"]
    assert detail["code"] == "ENTITLEMENT_REQUIRED"
    assert detail["reason"] == "trial_expired"


def test_expired_trial_still_allows_status_query(client: TestClient, db: Session) -> None:
    _create_admin(db)
    token = _login(client)
    subscription = _subscription(db)
    subscription.trial_started_at = datetime.now(UTC) - timedelta(days=8)
    subscription.trial_ends_at = datetime.now(UTC) - timedelta(days=1)
    db.add(subscription)
    db.commit()

    response = client.get("/api/subscription/status", headers=_auth_header(token))

    assert response.status_code == 200
    assert response.json()["status"] == "trial_expired_unsubscribed"
    assert response.json()["paywall_required"] is True


def test_active_subscription_unlocks_expired_trial(client: TestClient, db: Session) -> None:
    _create_admin(db)
    token = _login(client)
    family_id = client.get("/api/auth/me", headers=_auth_header(token)).json()["family_id"]
    subscription = _subscription(db)
    subscription.trial_started_at = datetime.now(UTC) - timedelta(days=8)
    subscription.trial_ends_at = datetime.now(UTC) - timedelta(days=1)
    subscription.status = "subscribed_active"
    subscription.expires_at = datetime.now(UTC) + timedelta(days=30)
    subscription.product_id = "homepets_monthly"
    subscription.will_renew = True
    db.add(subscription)
    db.commit()

    response = client.get(f"/api/families/{family_id}/tasks", headers=_auth_header(token))

    assert response.status_code == 200


def test_revenuecat_webhook_auth_failure(client: TestClient, db: Session, monkeypatch) -> None:
    monkeypatch.setattr("app.api.subscription.settings.REVENUECAT_WEBHOOK_AUTH", "secret")
    _create_admin(db)
    _login(client)

    response = client.post(
        "/api/revenuecat/webhook",
        json={"event": {"id": "evt_1", "app_user_id": "family_1", "type": "EXPIRATION"}},
        headers={"Authorization": "wrong"},
    )

    assert response.status_code == 401


def test_revenuecat_webhook_requires_configured_auth(client: TestClient, db: Session) -> None:
    _create_admin(db)
    _login(client)

    response = client.post(
        "/api/revenuecat/webhook",
        json={"event": {"id": "evt_1", "app_user_id": "family_1", "type": "EXPIRATION"}},
    )

    assert response.status_code == 503


def test_revenuecat_webhook_updates_and_deduplicates(
    client: TestClient,
    db: Session,
    monkeypatch,
) -> None:
    monkeypatch.setattr("app.api.subscription.settings.REVENUECAT_WEBHOOK_AUTH", "secret")
    _create_admin(db)
    _login(client)
    subscription = _subscription(db)

    payload = {
        "event": {
            "id": "evt_1",
            "app_user_id": subscription.revenuecat_app_user_id,
            "type": "INITIAL_PURCHASE",
            "product_id": "homepets_monthly",
            "expiration_at_ms": int((datetime.now(UTC) + timedelta(days=30)).timestamp() * 1000),
            "will_renew": True,
        }
    }
    first = client.post(
        "/api/revenuecat/webhook",
        json=payload,
        headers={"Authorization": "secret"},
    )
    second = client.post(
        "/api/revenuecat/webhook",
        json=payload,
        headers={"Authorization": "secret"},
    )

    assert first.status_code == 200
    assert first.json()["processed"] is True
    assert second.status_code == 200
    assert second.json()["processed"] is False
    db.refresh(subscription)
    assert subscription.status == "subscribed_active"
    assert subscription.product_id == "homepets_monthly"
    assert subscription.last_event_id == "evt_1"


def test_subscription_sync_uses_revenuecat_payload(
    client: TestClient,
    db: Session,
    monkeypatch,
) -> None:
    _create_admin(db)
    token = _login(client)
    subscription = _subscription(db)
    subscription.trial_started_at = datetime.now(UTC) - timedelta(days=8)
    subscription.trial_ends_at = datetime.now(UTC) - timedelta(days=1)
    db.add(subscription)
    db.commit()

    expires_at = (datetime.now(UTC) + timedelta(days=30)).isoformat()

    def fake_customer_info(app_user_id: str) -> dict[str, object]:
        assert app_user_id == subscription.revenuecat_app_user_id
        return {
            "subscriber": {
                "entitlements": {
                    "premium": {
                        "expires_date": expires_at,
                        "product_identifier": "homepets_monthly",
                        "will_renew": True,
                    }
                }
            }
        }

    monkeypatch.setattr(
        "app.api.subscription.fetch_revenuecat_customer_info",
        fake_customer_info,
    )

    response = client.post("/api/subscription/sync", headers=_auth_header(token))

    assert response.status_code == 200
    data = response.json()["subscription"]
    assert data["status"] == "subscribed_active"
    assert data["access_allowed"] is True
    assert data["product_id"] == "homepets_monthly"
