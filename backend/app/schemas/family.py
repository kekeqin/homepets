from datetime import datetime

from pydantic import BaseModel, Field


class FamilyCreate(BaseModel):
    name: str = Field(min_length=1, max_length=100)


class MemberCreate(BaseModel):
    nickname: str = Field(min_length=1, max_length=50)
    pet_type: str | None = Field(default=None, min_length=1, max_length=50)
    pet_name: str | None = Field(default=None, min_length=1, max_length=50)
    name: str | None = Field(default=None, min_length=1, max_length=50)


class MemberPetSelection(BaseModel):
    pet_type: str = Field(min_length=1, max_length=50)
    name: str = Field(min_length=1, max_length=50)


class MemberResponse(BaseModel):
    id: int
    nickname: str
    role: str
    avatar_url: str | None
    points: int = 0
    pet_id: int | None = None
    pet_type: str | None = None
    needs_pet_selection: bool = False


class FamilyResponse(BaseModel):
    id: int
    name: str
    pet_title: str
    owner_id: int
    created_at: datetime
    members: list[MemberResponse] = []


class FamilyUpdate(BaseModel):
    name: str | None = Field(default=None, min_length=1, max_length=100)
    pet_title: str | None = Field(default=None, min_length=1, max_length=50)
