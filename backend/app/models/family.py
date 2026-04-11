from datetime import UTC, datetime

from sqlmodel import Field, SQLModel


class Family(SQLModel, table=True):
    __tablename__ = "families"

    id: int | None = Field(default=None, primary_key=True)
    name: str = Field(min_length=1, max_length=100)
    pet_title: str = Field(default="家庭宠物", max_length=50)
    owner_id: int = Field(foreign_key="users.id", index=True)
    created_at: datetime = Field(default_factory=lambda: datetime.now(UTC))
