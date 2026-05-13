from datetime import UTC, datetime

from sqlmodel import Field, SQLModel


class Pet(SQLModel, table=True):
    __tablename__ = "pets"

    id: int | None = Field(default=None, primary_key=True)
    name: str = Field(min_length=1, max_length=50)
    pet_type: str = Field(max_length=50, default="cat")
    level: int = Field(default=1)
    experience: int = Field(default=0)
    owner_id: int = Field(foreign_key="users.id", index=True)
    family_id: int = Field(foreign_key="families.id", index=True)
    created_at: datetime = Field(default_factory=lambda: datetime.now(UTC))
