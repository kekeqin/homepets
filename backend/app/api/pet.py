from fastapi import APIRouter, Depends, HTTPException, status
from sqlmodel import Session, select

from app.core.dependencies import get_current_user, get_db
from app.models.pet import Pet
from app.models.user import User
from app.schemas.pet import PetResponse
from app.services.pet_service import get_emoji, get_image, get_next_level_threshold

router = APIRouter(prefix="/api", tags=["pets"])

_user_cache: dict[int, str] = {}


def _get_owner_nickname(db: Session, owner_id: int) -> str:
    if owner_id in _user_cache:
        return _user_cache[owner_id]
    user = db.get(User, owner_id)
    name = user.nickname if user else "未知"
    _user_cache[owner_id] = name
    return name


def _build_pet_response(pet: Pet, db: Session) -> PetResponse:
    next_threshold = get_next_level_threshold(pet.level)
    next_image = get_image(pet.pet_type, pet.level + 1) if next_threshold else None
    return PetResponse(
        id=pet.id,  # type: ignore[arg-type]
        name=pet.name,
        pet_type=pet.pet_type,
        level=pet.level,
        experience=pet.experience,
        owner_id=pet.owner_id,
        owner_nickname=_get_owner_nickname(db, pet.owner_id),
        family_id=pet.family_id,
        created_at=pet.created_at,
        level_threshold=next_threshold or 0,
        next_level_image=next_image,
        emoji=get_emoji(pet.pet_type),
    )


# 列出当前登录用户所在家庭的所有宠物。
@router.get("/families/{family_id}/pets", response_model=list[PetResponse])
def list_pets(
    family_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> list[PetResponse]:
    if current_user.family_id != family_id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="无权查看此家庭的宠物")
    _user_cache.clear()
    pets = db.exec(select(Pet).where(Pet.family_id == family_id)).all()
    return [_build_pet_response(pet, db) for pet in pets]


# 获取单只宠物的成长信息。
@router.get("/pets/{pet_id}", response_model=PetResponse)
def get_pet(
    pet_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> PetResponse:
    pet = db.get(Pet, pet_id)
    if not pet:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="宠物不存在")
    if current_user.family_id != pet.family_id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="无权查看此宠物")
    return _build_pet_response(pet, db)
