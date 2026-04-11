from datetime import UTC, datetime

from sqlmodel import Field, SQLModel


class Pet(SQLModel, table=True):
    __tablename__ = "pets"

    id: int | None = Field(default=None, primary_key=True)
    name: str = Field(min_length=1, max_length=50)
    pet_type: str = Field(max_length=50, default="egg")  # egg, cat, dog, rabbit, etc.
    pet_form: str = Field(default="egg")  # "egg" or "pet"
    level: int = Field(default=0)
    experience: int = Field(default=0)
    image_url: str | None = Field(default=None)
    owner_id: int = Field(foreign_key="users.id", index=True)
    family_id: int = Field(foreign_key="families.id", index=True)
    created_at: datetime = Field(default_factory=lambda: datetime.now(UTC))


class PetHistoryEvent(SQLModel, table=True):
    __tablename__ = "pet_history_events"

    id: int | None = Field(default=None, primary_key=True)
    pet_id: int = Field(foreign_key="pets.id", index=True)
    owner_id: int = Field(foreign_key="users.id", index=True)
    family_id: int = Field(foreign_key="families.id", index=True)
    event_type: str = Field(max_length=50)
    title: str = Field(min_length=1, max_length=100)
    description: str | None = Field(default=None, max_length=255)
    points: int = Field(default=0)
    created_at: datetime = Field(default_factory=lambda: datetime.now(UTC))
