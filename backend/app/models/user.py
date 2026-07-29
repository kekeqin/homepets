from datetime import UTC, datetime

from sqlmodel import Field, SQLModel

from app.services.user_public_id import generate_public_id


class User(SQLModel, table=True):
    __tablename__ = "users"

    id: int | None = Field(default=None, primary_key=True)
    public_id: str = Field(
        default_factory=generate_public_id,
        min_length=6,
        max_length=6,
        unique=True,
        index=True,
    )
    phone: str | None = Field(default=None, unique=True, index=True)
    apple_sub: str | None = Field(default=None, unique=True, index=True)
    email: str | None = Field(default=None, index=True)
    nickname: str = Field(min_length=1, max_length=50)
    role: str = Field(default="child")  # admin=家长，child=儿童
    avatar_url: str | None = Field(default=None)
    points: int = Field(default=0)
    family_id: int | None = Field(default=None, foreign_key="families.id", index=True)
    created_at: datetime = Field(default_factory=lambda: datetime.now(UTC))
