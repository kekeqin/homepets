from typing import Any

from fastapi import APIRouter, Depends, Header, HTTPException, Request, status
from sqlmodel import Session

from app.core.config import settings
from app.core.dependencies import get_current_user, get_db
from app.models.user import User
from app.schemas.subscription import (
    SubscriptionStatusResponse,
    SubscriptionSyncRequest,
    SubscriptionSyncResponse,
)
from app.services.subscription_service import (
    access_allowed_for,
    apply_revenuecat_event,
    as_utc,
    build_subscription_status,
    calculate_status,
    ensure_subscription_for_user,
    fetch_revenuecat_customer_info,
    sync_subscription_from_client_entitlement,
    sync_subscription_from_customer_payload,
)

router = APIRouter(tags=["subscription"])


@router.get("/api/subscription/status", response_model=SubscriptionStatusResponse)
def get_subscription_status(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> SubscriptionStatusResponse:
    subscription = ensure_subscription_for_user(db, current_user)
    return build_subscription_status(subscription)


@router.post("/api/subscription/sync", response_model=SubscriptionSyncResponse)
def sync_subscription(
    body: SubscriptionSyncRequest | None = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> SubscriptionSyncResponse:
    subscription = ensure_subscription_for_user(db, current_user)
    if body is not None and body.revenuecat_app_user_id is not None:
        subscription.revenuecat_app_user_id = body.revenuecat_app_user_id

    customer_payload = fetch_revenuecat_customer_info(subscription.revenuecat_app_user_id)
    sync_subscription_from_customer_payload(subscription, customer_payload)
    synced_status = calculate_status(subscription)
    client_expires_at = body.subscription_expires_at if body is not None else None
    synced_expires_at = subscription.expires_at
    client_extends_subscription = (
        body is not None
        and body.is_active is True
        and client_expires_at is not None
        and synced_expires_at is not None
        and as_utc(client_expires_at) > as_utc(synced_expires_at)
    )
    should_use_client_entitlement = (
        body is not None
        and body.is_active is True
        and (not access_allowed_for(synced_status) or client_extends_subscription)
    )
    if should_use_client_entitlement:
        sync_subscription_from_client_entitlement(subscription, body)
    db.add(subscription)
    db.commit()
    db.refresh(subscription)
    return SubscriptionSyncResponse(
        synced=True,
        message="订阅状态已刷新。",
        subscription=build_subscription_status(subscription),
    )


@router.post("/api/revenuecat/webhook")
async def revenuecat_webhook(
    request: Request,
    authorization: str | None = Header(default=None),
    db: Session = Depends(get_db),
) -> dict[str, Any]:
    expected_auth = settings.REVENUECAT_WEBHOOK_AUTH
    if not expected_auth:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="RevenueCat webhook 鉴权未配置",
        )
    if authorization != expected_auth:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="无效的 webhook 鉴权")

    payload = await request.json()
    subscription, changed = apply_revenuecat_event(db, payload)
    return {
        "received": True,
        "processed": changed,
        "subscription_id": subscription.id if subscription else None,
    }
