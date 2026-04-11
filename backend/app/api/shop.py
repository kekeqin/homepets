from fastapi import APIRouter, Depends, HTTPException, status
from sqlmodel import Session, select

from app.core.dependencies import get_current_user, get_db
from app.models.shop import ShopItem, UserItem
from app.models.user import User
from app.schemas.shop import BuyRequest, ShopItemResponse, UserItemResponse

router = APIRouter(prefix="/api/shop", tags=["shop"])

# Default shop items
DEFAULT_ITEMS = [
    {
        "name": "猫咪皇冠",
        "description": "给猫咪戴上闪闪发光的皇冠",
        "category": "accessory",
        "price": 50,
        "emoji": "👑",
        "pet_type": "cat",
    },
    {
        "name": "狗狗围巾",
        "description": "温暖的红色围巾",
        "category": "clothes",
        "price": 30,
        "emoji": "🧣",
        "pet_type": "dog",
    },
    {
        "name": "兔子蝴蝶结",
        "description": "粉色蝴蝶结发饰",
        "category": "accessory",
        "price": 25,
        "emoji": "🎀",
        "pet_type": "rabbit",
    },
    {
        "name": "星空背景",
        "description": "美丽的星空背景",
        "category": "background",
        "price": 80,
        "emoji": "🌌",
        "pet_type": None,
    },
    {
        "name": "花园背景",
        "description": "开满鲜花的花园",
        "category": "background",
        "price": 60,
        "emoji": "🌸",
        "pet_type": None,
    },
    {
        "name": "运动鞋",
        "description": "时尚运动鞋",
        "category": "shoes",
        "price": 40,
        "emoji": "👟",
        "pet_type": None,
    },
    {
        "name": "小红帽",
        "description": "经典小红帽",
        "category": "clothes",
        "price": 35,
        "emoji": "🧢",
        "pet_type": None,
    },
    {
        "name": "黄金皮肤",
        "description": "闪闪发光的黄金皮肤",
        "category": "skin",
        "price": 100,
        "emoji": "✨",
        "pet_type": None,
    },
    {
        "name": "彩虹翅膀",
        "description": "美丽的彩虹翅膀",
        "category": "accessory",
        "price": 120,
        "emoji": "🦋",
        "pet_type": None,
    },
    {
        "name": "小墨镜",
        "description": "酷酷的墨镜",
        "category": "accessory",
        "price": 20,
        "emoji": "🕶️",
        "pet_type": None,
    },
]


def _ensure_default_items(db: Session) -> None:
    count = db.exec(select(ShopItem)).first()
    if count is None:
        for item_data in DEFAULT_ITEMS:
            item = ShopItem(**item_data)
            db.add(item)
        db.commit()


@router.get("/items", response_model=list[ShopItemResponse])
def list_items(
    category: str | None = None,
    user_id: int | None = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> list[ShopItemResponse]:
    _ensure_default_items(db)
    query = select(ShopItem)
    if category:
        query = query.where(ShopItem.category == category)
    items = db.exec(query).all()
    # Use specified user_id or current user
    target_id = user_id if user_id and current_user.role == "admin" else current_user.id
    # Get user's owned items
    user_items = db.exec(select(UserItem).where(UserItem.user_id == target_id)).all()
    owned_ids = {ui.item_id: ui.equipped for ui in user_items}
    return [
        ShopItemResponse(
            id=item.id,  # type: ignore[arg-type]
            name=item.name,
            description=item.description,
            category=item.category,
            price=item.price,
            emoji=item.emoji,
            pet_type=item.pet_type,
            owned=item.id in owned_ids,
            equipped=owned_ids.get(item.id, False),
        )
        for item in items
    ]


@router.post("/buy")
def buy_item(
    body: BuyRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> dict:
    item = db.get(ShopItem, body.item_id)
    if not item:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="商品不存在")
    # Determine who to buy for
    buyer_id = (
        body.for_user_id if body.for_user_id and current_user.role == "admin" else current_user.id
    )
    buyer = db.get(User, buyer_id)
    if not buyer or buyer.family_id != current_user.family_id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="无权为此用户购买")
    # Check if already owned
    existing = db.exec(
        select(UserItem).where(UserItem.user_id == buyer_id, UserItem.item_id == body.item_id)
    ).first()
    if existing:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="已拥有此商品")
    # Check points
    if buyer.points < item.price:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="积分不足")
    # Deduct points and create user item
    buyer.points -= item.price
    user_item = UserItem(user_id=buyer_id, item_id=body.item_id)
    db.add(buyer)
    db.add(user_item)
    db.commit()
    return {"message": "购买成功", "remaining_points": buyer.points}


@router.post("/equip/{user_item_id}")
def equip_item(
    user_item_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> dict:
    user_item = db.get(UserItem, user_item_id)
    if not user_item:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="物品不存在")
    # Allow owner or admin of same family
    owner = db.get(User, user_item.user_id)
    is_owner = user_item.user_id == current_user.id
    is_family_admin = (
        current_user.role == "admin" and owner and owner.family_id == current_user.family_id
    )
    if not is_owner and not is_family_admin:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="无权操作")
    # Unequip same category items first
    item = db.get(ShopItem, user_item.item_id)
    if item:
        same_cat = db.exec(
            select(UserItem)
            .join(ShopItem)
            .where(
                UserItem.user_id == user_item.user_id,
                ShopItem.category == item.category,
            )
        ).all()
        for ui in same_cat:
            ui.equipped = False
            db.add(ui)
    user_item.equipped = True
    db.add(user_item)
    db.commit()
    return {"message": "装备成功"}


@router.post("/unequip/{user_item_id}")
def unequip_item(
    user_item_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> dict:
    user_item = db.get(UserItem, user_item_id)
    if not user_item:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="物品不存在")
    owner = db.get(User, user_item.user_id)
    is_owner = user_item.user_id == current_user.id
    is_family_admin = (
        current_user.role == "admin" and owner and owner.family_id == current_user.family_id
    )
    if not is_owner and not is_family_admin:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="无权操作")
    user_item.equipped = False
    db.add(user_item)
    db.commit()
    return {"message": "卸下成功"}


@router.get("/my-items", response_model=list[UserItemResponse])
def my_items(
    user_id: int | None = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> list[dict]:
    target_id = user_id if user_id and current_user.role == "admin" else current_user.id
    user_items = db.exec(
        select(UserItem, ShopItem)
        .join(ShopItem, UserItem.item_id == ShopItem.id)
        .where(UserItem.user_id == target_id)
        .order_by(UserItem.created_at.desc())
    ).all()
    return [
        {
            "id": ui.id,
            "item_id": item.id,
            "item_name": item.name,
            "item_emoji": item.emoji,
            "category": item.category,
            "equipped": ui.equipped,
            "created_at": ui.created_at,
        }
        for ui, item in user_items
    ]


@router.get("/equipped/{family_id}")
def get_family_equipped(
    family_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> dict[int, list[dict]]:
    """Get equipped items for all members in a family. Returns {user_id: [{emoji, category, name}]}."""
    if current_user.family_id != family_id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="无权查看")
    user_items = db.exec(
        select(UserItem, ShopItem)
        .join(ShopItem, UserItem.item_id == ShopItem.id)
        .join(User, UserItem.user_id == User.id)
        .where(User.family_id == family_id, UserItem.equipped.is_(True))
    ).all()
    result: dict[int, list[dict]] = {}
    for ui, item in user_items:
        uid = ui.user_id
        if uid not in result:
            result[uid] = []
        result[uid].append({"emoji": item.emoji, "category": item.category, "name": item.name})
    return result
