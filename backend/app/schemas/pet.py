from datetime import datetime

from pydantic import BaseModel


class PetResponse(BaseModel):
    id: int
    name: str
    pet_type: str
    level: int
    experience: int
    owner_id: int
    owner_nickname: str | None = None
    family_id: int
    created_at: datetime
    level_threshold: int | None
    next_level_image: str | None
    emoji: str | None = None


class PetHistoryEntryResponse(BaseModel):
    id: int
    event_type: str = "task"
    title: str
    task_title: str
    points: int = 0
    task_points: int = 0
    description: str | None = None
    created_at: datetime
