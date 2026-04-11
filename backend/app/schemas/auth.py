from pydantic import BaseModel, Field


class RegisterRequest(BaseModel):
    phone: str = Field(min_length=11, max_length=15, pattern=r"^\d+$")
    password: str = Field(min_length=6, max_length=50)
    nickname: str = Field(min_length=1, max_length=50)


class LoginRequest(BaseModel):
    phone: str
    password: str


class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"


class UserResponse(BaseModel):
    id: int
    phone: str | None
    nickname: str
    role: str
    avatar_url: str | None
    points: int
    family_id: int | None
