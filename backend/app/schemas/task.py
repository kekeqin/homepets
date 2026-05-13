from datetime import datetime

from pydantic import BaseModel, Field


class TaskCreate(BaseModel):
    title: str = Field(min_length=1, max_length=200)
    points: int = Field(default=10, ge=-1000, le=1000)


class TaskUpdate(BaseModel):
    title: str | None = Field(default=None, min_length=1, max_length=200)
    points: int | None = Field(default=None, ge=-1000, le=1000)


class TaskResponse(BaseModel):
    id: int
    title: str
    points: int
    family_id: int
    is_active: bool
    created_at: datetime


class TaskListItemResponse(TaskResponse):
    completed_today: bool = False
    completed_this_week: bool = False
    status: str = "pending"


class CompletionSubmit(BaseModel):
    member_id: int | None = None


class CompletionResponse(BaseModel):
    id: int
    task_id: int
    member_id: int
    status: str
    created_at: datetime
    reviewed_at: datetime | None
    task_title: str | None = None
    task_points: int = 0
    task_is_active: bool | None = None
    member_nickname: str | None = None
