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
