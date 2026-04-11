from datetime import datetime

from pydantic import BaseModel, Field


class PetFeed(BaseModel):
    points: int = Field(ge=1, le=10000)


class PetHatch(BaseModel):
    pet_type: str = Field(min_length=1, max_length=50)
    name: str = Field(min_length=1, max_length=50)


class PetResponse(BaseModel):
    id: int
    name: str
    pet_type: str
    pet_form: str
    level: int
    experience: int
    image_url: str | None
    owner_id: int
    owner_nickname: str | None = None
    family_id: int
    created_at: datetime
    level_threshold: int | None
    next_level_image: str | None
    emoji: str | None = None
