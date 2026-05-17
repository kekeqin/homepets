from datetime import UTC, datetime, timedelta

from sqlmodel import Field, SQLModel


def utc_now() -> datetime:
    return datetime.now(UTC)


def default_trial_end() -> datetime:
    return utc_now() + timedelta(days=7)


class Subscription(SQLModel, table=True):
    __tablename__ = "subscriptions"

    id: int | None = Field(default=None, primary_key=True)
    user_id: int | None = Field(default=None, foreign_key="users.id", index=True)
    family_id: int | None = Field(default=None, foreign_key="families.id", index=True)
    trial_started_at: datetime = Field(default_factory=utc_now)
    trial_ends_at: datetime = Field(default_factory=default_trial_end)
    status: str = Field(default="trial_active", index=True, max_length=50)
    provider: str = Field(default="revenuecat", max_length=50)
    entitlement_id: str = Field(default="premium", max_length=100)
    revenuecat_app_user_id: str = Field(index=True, max_length=150)
    original_app_user_id: str | None = Field(default=None, max_length=150)
    product_id: str | None = Field(default=None, max_length=200)
    expires_at: datetime | None = Field(default=None)
    will_renew: bool = Field(default=False)
    last_verified_at: datetime | None = Field(default=None)
    last_event_id: str | None = Field(default=None, index=True, max_length=200)
    created_at: datetime = Field(default_factory=utc_now)
    updated_at: datetime = Field(default_factory=utc_now)
