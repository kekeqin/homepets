from datetime import UTC, datetime

from sqlmodel import Field, SQLModel


class Task(SQLModel, table=True):
    __tablename__ = "tasks"

    id: int | None = Field(default=None, primary_key=True)
    title: str = Field(min_length=1, max_length=200)
    description: str | None = Field(default=None, max_length=1000)
    points: int = Field(default=10, ge=-1000, le=1000)
    task_type: str = Field(default="daily", max_length=32)
    time_limit_minutes: int | None = Field(default=None)
    family_id: int = Field(foreign_key="families.id", index=True)
    is_active: bool = Field(default=True)
    created_at: datetime = Field(default_factory=lambda: datetime.now(UTC))
    icon: str = Field(default="sparkles", max_length=64)


class TaskCompletion(SQLModel, table=True):
    __tablename__ = "task_completions"

    id: int | None = Field(default=None, primary_key=True)
    task_id: int = Field(foreign_key="tasks.id", index=True)
    member_id: int = Field(foreign_key="users.id", index=True)
    status: str = Field(default="pending")  # pending, approved, rejected
    created_at: datetime = Field(default_factory=lambda: datetime.now(UTC))
    reviewed_at: datetime | None = Field(default=None)
