from datetime import datetime

from pydantic import BaseModel


class ShopItemResponse(BaseModel):
    id: int
    name: str
    description: str | None
    category: str
    price: int
    emoji: str
    pet_type: str | None
    owned: bool = False
    equipped: bool = False


class BuyRequest(BaseModel):
    item_id: int
    for_user_id: int | None = None


class UserItemResponse(BaseModel):
    id: int
    item_id: int
    item_name: str
    item_emoji: str
    category: str
    equipped: bool
    created_at: datetime
