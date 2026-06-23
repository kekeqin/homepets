import json
from datetime import UTC, datetime, timedelta
from typing import Any
from urllib import error, parse, request

from fastapi import HTTPException, status
from sqlmodel import Session, select

from app.core.config import settings
from app.models.subscription import Subscription
from app.models.user import User
from app.schemas.subscription import SubscriptionStatusResponse, SubscriptionSyncRequest

ACCESS_ALLOWED_STATUSES = {
    "trial_active",
    "trial_expiring",
    "subscribed_active",
    "subscription_grace_period",
    "offline_cached_active",
}
PAYWALL_REQUIRED_STATUSES = {
    "trial_expired_unsubscribed",
    "subscription_expired",
    "offline_unverified_or_expired",
    "blocked",
}
REVENUECAT_PURCHASE_EVENTS = {
    "INITIAL_PURCHASE",
    "RENEWAL",
    "UNCANCELLATION",
    "PRODUCT_CHANGE",
    "TRANSFER",
}
REVENUECAT_BLOCKING_EVENTS = {"EXPIRATION", "CANCELLATION"}


def now_utc() -> datetime:
    """Return the server authorization clock in UTC."""
    return datetime.now(UTC)


def as_utc(value: datetime) -> datetime:
    """Normalize SQLite-naive datetimes and provider datetimes to UTC."""
    if value.tzinfo is None:
        return value.replace(tzinfo=UTC)
    return value.astimezone(UTC)


def revenuecat_app_user_id_for(user: User) -> str:
    """Return the stable RevenueCat app user id used by Flutter and webhooks."""
    return f"family_{user.family_id}" if user.family_id is not None else f"user_{user.id}"


def ensure_subscription_for_user(db: Session, user: User) -> Subscription:
    """Create or return the family/user entitlement record for a HomePets user."""
    if user.family_id is not None:
        statement = select(Subscription).where(Subscription.family_id == user.family_id)
    else:
        statement = select(Subscription).where(
            Subscription.user_id == user.id,
            Subscription.family_id.is_(None),  # type: ignore[union-attr]
        )
    subscription = db.exec(statement).first()
    if subscription is not None:
        expected_app_user_id = revenuecat_app_user_id_for(user)
        if subscription.revenuecat_app_user_id != expected_app_user_id:
            subscription.revenuecat_app_user_id = expected_app_user_id
            subscription.updated_at = now_utc()
            db.add(subscription)
            db.commit()
            db.refresh(subscription)
        return subscription

    started_at = now_utc()
    subscription = Subscription(
        user_id=user.id if user.family_id is None else None,
        family_id=user.family_id,
        trial_started_at=started_at,
        trial_ends_at=started_at + timedelta(days=7),
        status="trial_active",
        entitlement_id=settings.REVENUECAT_ENTITLEMENT_ID,
        revenuecat_app_user_id=revenuecat_app_user_id_for(user),
        last_verified_at=started_at,
    )
    db.add(subscription)
    db.commit()
    db.refresh(subscription)
    return subscription


def ensure_family_trial(db: Session, user: User) -> Subscription | None:
    """Ensure an admin-owned family has the initial seven-day trial entitlement."""
    if user.family_id is None:
        return None
    return ensure_subscription_for_user(db, user)


def calculate_status(subscription: Subscription, *, at: datetime | None = None) -> str:
    current_time = as_utc(at or now_utc())
    configured_status = subscription.status

    if configured_status in {"blocked", "offline_unverified_or_expired"}:
        return configured_status

    expires_at = subscription.expires_at
    if configured_status in {"subscribed_active", "subscription_grace_period"}:
        if expires_at is None or as_utc(expires_at) > current_time:
            return configured_status
        return "subscription_expired"

    if configured_status == "subscription_expired":
        return configured_status

    trial_ends_at = as_utc(subscription.trial_ends_at)
    if trial_ends_at <= current_time:
        return "trial_expired_unsubscribed"
    if trial_ends_at - current_time <= timedelta(days=2):
        return "trial_expiring"
    return "trial_active"


def trial_days_remaining(subscription: Subscription, *, at: datetime | None = None) -> int:
    remaining = as_utc(subscription.trial_ends_at) - as_utc(at or now_utc())
    if remaining.total_seconds() <= 0:
        return 0
    return max(1, (remaining.days + (1 if remaining.seconds or remaining.microseconds else 0)))


def access_allowed_for(status_value: str) -> bool:
    return status_value in ACCESS_ALLOWED_STATUSES


def reason_for(status_value: str) -> str | None:
    return {
        "trial_expired_unsubscribed": "trial_expired",
        "subscription_expired": "subscription_expired",
        "offline_unverified_or_expired": "offline_unverified_or_expired",
        "blocked": "blocked",
    }.get(status_value)


def build_subscription_status(
    subscription: Subscription,
    *,
    at: datetime | None = None,
) -> SubscriptionStatusResponse:
    computed_status = calculate_status(subscription, at=at)
    access_allowed = access_allowed_for(computed_status)
    return SubscriptionStatusResponse(
        status=computed_status,
        access_allowed=access_allowed,
        paywall_required=not access_allowed,
        reason=reason_for(computed_status),
        scope="family" if subscription.family_id is not None else "user",
        family_id=subscription.family_id,
        user_id=subscription.user_id,
        trial_started_at=subscription.trial_started_at,
        trial_ends_at=subscription.trial_ends_at,
        trial_days_remaining=trial_days_remaining(subscription, at=at),
        is_premium_active=computed_status in {"subscribed_active", "subscription_grace_period"},
        entitlement_id=subscription.entitlement_id,
        product_id=subscription.product_id,
        subscription_expires_at=subscription.expires_at,
        will_renew=subscription.will_renew,
        last_verified_at=subscription.last_verified_at,
        revenuecat_app_user_id=subscription.revenuecat_app_user_id,
    )


def sync_subscription_from_customer_payload(
    subscription: Subscription,
    payload: dict[str, Any] | None,
) -> None:
    """Update a subscription from a RevenueCat-style current entitlement payload."""
    current_time = now_utc()
    entitlement = _extract_entitlement(payload, subscription.entitlement_id)
    subscription.last_verified_at = current_time
    subscription.updated_at = current_time

    if entitlement is None:
        subscription.status = calculate_status(subscription, at=current_time)
        return

    expires_at = _parse_datetime(
        entitlement.get("expires_date")
        or entitlement.get("expires_at")
        or entitlement.get("expiration_at_ms")
        or entitlement.get("expires_date_ms")
    )
    subscription.expires_at = expires_at
    subscription.product_id = _string_or_none(
        entitlement.get("product_identifier") or entitlement.get("product_id")
    )
    subscription.will_renew = bool(
        entitlement.get("will_renew")
        or entitlement.get("unsubscribe_detected_at") is None
        and entitlement.get("billing_issues_detected_at") is None
    )
    subscription.status = (
        "subscribed_active"
        if expires_at is None or as_utc(expires_at) > current_time
        else "subscription_expired"
    )


def sync_subscription_from_client_entitlement(
    subscription: Subscription,
    entitlement: SubscriptionSyncRequest,
) -> None:
    """Update a subscription from an active entitlement already verified by the app SDK."""
    current_time = now_utc()
    subscription.last_verified_at = current_time
    subscription.updated_at = current_time

    if entitlement.entitlement_id:
        subscription.entitlement_id = entitlement.entitlement_id
    subscription.expires_at = (
        as_utc(entitlement.subscription_expires_at)
        if entitlement.subscription_expires_at is not None
        else None
    )
    subscription.product_id = entitlement.product_id
    subscription.will_renew = entitlement.will_renew
    subscription.status = (
        "subscribed_active"
        if subscription.expires_at is None or as_utc(subscription.expires_at) > current_time
        else "subscription_expired"
    )


def fetch_revenuecat_customer_info(app_user_id: str) -> dict[str, Any] | None:
    """Fetch current RevenueCat subscriber state when server credentials exist."""
    secret_api_key = settings.REVENUECAT_SECRET_API_KEY
    if not secret_api_key:
        return None

    encoded_app_user_id = parse.quote(app_user_id, safe="")
    url = f"https://api.revenuecat.com/v1/subscribers/{encoded_app_user_id}"
    revenuecat_request = request.Request(
        url,
        headers={
            "Accept": "application/json",
            "Authorization": f"Bearer {secret_api_key}",
        },
        method="GET",
    )
    try:
        with request.urlopen(revenuecat_request, timeout=8) as response:
            payload = json.loads(response.read().decode("utf-8"))
    except (OSError, error.HTTPError, json.JSONDecodeError) as exc:
        raise HTTPException(
            status_code=status.HTTP_502_BAD_GATEWAY,
            detail="RevenueCat 订阅状态验证失败",
        ) from exc

    if not isinstance(payload, dict):
        raise HTTPException(
            status_code=status.HTTP_502_BAD_GATEWAY,
            detail="RevenueCat 订阅状态响应异常",
        )
    return dict(payload)


def apply_revenuecat_event(
    db: Session,
    payload: dict[str, Any],
) -> tuple[Subscription | None, bool]:
    """Apply one RevenueCat webhook event and return whether it changed state."""
    event_payload = payload.get("event")
    event: dict[str, Any] = dict(event_payload) if isinstance(event_payload, dict) else payload
    event_id = _string_or_none(
        event.get("id")
        or event.get("event_id")
        or event.get("transaction_id")
        or event.get("original_transaction_id")
    )
    app_user_id = _string_or_none(event.get("app_user_id") or event.get("original_app_user_id"))
    aliases = event.get("aliases")
    if app_user_id is None and isinstance(aliases, list) and aliases:
        app_user_id = _string_or_none(aliases[0])
    if app_user_id is None:
        return None, False

    subscription = db.exec(
        select(Subscription).where(Subscription.revenuecat_app_user_id == app_user_id)
    ).first()
    if subscription is None:
        return None, False
    if event_id is not None and subscription.last_event_id == event_id:
        return subscription, False

    event_type = _string_or_none(event.get("type")) or ""
    current_time = now_utc()
    subscription.original_app_user_id = _string_or_none(event.get("original_app_user_id"))
    subscription.product_id = _string_or_none(
        event.get("product_id") or event.get("product_identifier")
    )
    subscription.expires_at = _parse_datetime(
        event.get("expiration_at_ms")
        or event.get("expiration_date_ms")
        or event.get("expires_date_ms")
        or event.get("expires_at")
        or event.get("expiration_date")
    )
    subscription.will_renew = bool(event.get("will_renew") or event.get("auto_resume_at_ms"))
    subscription.last_verified_at = current_time
    subscription.updated_at = current_time
    subscription.last_event_id = event_id

    if event_type in REVENUECAT_PURCHASE_EVENTS:
        subscription.status = "subscribed_active"
    elif event_type == "BILLING_ISSUE":
        subscription.status = "subscription_grace_period"
    elif event_type in REVENUECAT_BLOCKING_EVENTS:
        subscription.status = (
            "subscription_expired"
            if subscription.expires_at is None or as_utc(subscription.expires_at) <= current_time
            else "subscribed_active"
        )
    else:
        subscription.status = calculate_status(subscription, at=current_time)

    db.add(subscription)
    db.commit()
    db.refresh(subscription)
    return subscription, True


def require_subscription_access(db: Session, current_user: User) -> Subscription:
    """Raise 402 unless the current user has trial or subscription access."""
    subscription = ensure_subscription_for_user(db, current_user)
    entitlement = build_subscription_status(subscription)
    if entitlement.access_allowed:
        return subscription

    raise HTTPException(
        status_code=status.HTTP_402_PAYMENT_REQUIRED,
        detail={
            "code": "ENTITLEMENT_REQUIRED",
            "message": "试用期已结束，请订阅后继续使用。",
            "reason": entitlement.reason,
            "trial_ends_at": entitlement.trial_ends_at.isoformat()
            if entitlement.trial_ends_at
            else None,
        },
    )


def _extract_entitlement(
    payload: dict[str, Any] | None,
    entitlement_id: str,
) -> dict[str, Any] | None:
    if payload is None:
        return None
    entitlements = payload.get("entitlements")
    if isinstance(entitlements, dict):
        active = entitlements.get("active")
        if isinstance(active, dict) and isinstance(active.get(entitlement_id), dict):
            return dict(active[entitlement_id])
        entitlement = entitlements.get(entitlement_id)
        if isinstance(entitlement, dict):
            return dict(entitlement)
    subscriber = payload.get("subscriber")
    if isinstance(subscriber, dict):
        subscriber_entitlements = subscriber.get("entitlements")
        if isinstance(subscriber_entitlements, dict) and isinstance(
            subscriber_entitlements.get(entitlement_id),
            dict,
        ):
            return dict(subscriber_entitlements[entitlement_id])
    return None


def _parse_datetime(value: Any) -> datetime | None:
    if value is None:
        return None
    if isinstance(value, datetime):
        return as_utc(value)
    if isinstance(value, int | float):
        timestamp = value / 1000 if value > 10_000_000_000 else value
        return datetime.fromtimestamp(timestamp, UTC)
    if isinstance(value, str):
        normalized = value.replace("Z", "+00:00")
        try:
            return as_utc(datetime.fromisoformat(normalized))
        except ValueError:
            return None
    return None


def _string_or_none(value: Any) -> str | None:
    if value is None:
        return None
    text = str(value).strip()
    return text or None
