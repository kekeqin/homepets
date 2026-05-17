from datetime import datetime

from pydantic import BaseModel, Field


class SubscriptionStatusResponse(BaseModel):
    status: str
    access_allowed: bool
    paywall_required: bool
    reason: str | None = None
    scope: str
    family_id: int | None = None
    user_id: int | None = None
    trial_started_at: datetime | None = None
    trial_ends_at: datetime | None = None
    trial_days_remaining: int = 0
    is_premium_active: bool = False
    entitlement_id: str
    product_id: str | None = None
    subscription_expires_at: datetime | None = None
    will_renew: bool = False
    last_verified_at: datetime | None = None
    revenuecat_app_user_id: str


class SubscriptionSyncRequest(BaseModel):
    revenuecat_app_user_id: str | None = Field(default=None, min_length=1, max_length=150)


class SubscriptionSyncResponse(BaseModel):
    synced: bool
    message: str
    subscription: SubscriptionStatusResponse
