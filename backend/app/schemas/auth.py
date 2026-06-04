from pydantic import BaseModel, Field


class SmsCodeRequest(BaseModel):
    phone: str = Field(min_length=11, max_length=11, pattern=r"^1\d{10}$")


class SmsCodeResponse(BaseModel):
    cooldown_seconds: int


class LoginRequest(BaseModel):
    phone: str = Field(min_length=11, max_length=11, pattern=r"^1\d{10}$")
    code: str = Field(min_length=4, max_length=8, pattern=r"^\d+$")


class AppleLoginRequest(BaseModel):
    identity_token: str = Field(min_length=1)
    authorization_code: str | None = Field(default=None, min_length=1)
    nonce: str | None = Field(default=None, min_length=1, max_length=256)
    full_name: str | None = Field(default=None, min_length=1, max_length=100)


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
