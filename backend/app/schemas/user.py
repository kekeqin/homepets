from pydantic import BaseModel, Field


class UserUpdate(BaseModel):
    nickname: str | None = Field(default=None, min_length=1, max_length=50)
    avatar_url: str | None = None
