from datetime import UTC, datetime

from sqlmodel import Field, SQLModel


class User(SQLModel, table=True):
    __tablename__ = "users"

    id: int | None = Field(default=None, primary_key=True)
    phone: str | None = Field(default=None, unique=True, index=True)
    nickname: str = Field(min_length=1, max_length=50)
    role: str = Field(default="child")  # admin=家长，child=儿童
    avatar_url: str | None = Field(default=None)
    points: int = Field(default=0)
    family_id: int | None = Field(default=None, foreign_key="families.id", index=True)
    created_at: datetime = Field(default_factory=lambda: datetime.now(UTC))
