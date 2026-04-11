from datetime import UTC, datetime

from sqlmodel import Field, SQLModel


class ShopItem(SQLModel, table=True):
    __tablename__ = "shop_items"

    id: int | None = Field(default=None, primary_key=True)
    name: str = Field(max_length=100)
    description: str | None = Field(default=None, max_length=500)
    category: str = Field(max_length=50)  # skin, background, clothes, shoes, accessory
    price: int = Field(default=10, ge=1)
    image_url: str | None = Field(default=None)
    emoji: str = Field(default="🎁")
    pet_type: str | None = Field(default=None)  # null = all types
    created_at: datetime = Field(default_factory=lambda: datetime.now(UTC))


class UserItem(SQLModel, table=True):
    __tablename__ = "user_items"

    id: int | None = Field(default=None, primary_key=True)
    user_id: int = Field(foreign_key="users.id", index=True)
    item_id: int = Field(foreign_key="shop_items.id", index=True)
    equipped: bool = Field(default=False)
    created_at: datetime = Field(default_factory=lambda: datetime.now(UTC))
