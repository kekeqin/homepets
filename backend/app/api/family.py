from fastapi import APIRouter, Depends, HTTPException, status
from sqlmodel import Session, select

from app.core.dependencies import (
    get_current_admin_with_active_access,
    get_current_user_with_active_access,
    get_db,
)
from app.models.family import Family
from app.models.pet import Pet
from app.models.user import User
from app.schemas.family import (
    FamilyCreate,
    FamilyResponse,
    FamilyUpdate,
    MemberCreate,
    MemberPetSelection,
    MemberResponse,
)
from app.services.pet_service import VALID_SELECTABLE_PET_TYPES, create_member_pet
from app.services.subscription_service import ensure_subscription_for_user

router = APIRouter(prefix="/api/families", tags=["families"])


def _get_member_pet(db: Session, member_id: int) -> Pet | None:
    return db.exec(
        select(Pet).where(Pet.owner_id == member_id).order_by(Pet.created_at.desc())
    ).first()


def _build_member_response(member: User, db: Session) -> MemberResponse:
    pet = _get_member_pet(db, member.id or 0)
    return MemberResponse(
        id=member.id or 0,
        nickname=member.nickname,
        role=member.role,
        avatar_url=member.avatar_url,
        points=member.points,
        pet_id=pet.id if pet else None,
        pet_type=pet.pet_type if pet else None,
        needs_pet_selection=pet is None,
    )


def _build_family_response(family: Family, db: Session) -> FamilyResponse:
    members = db.exec(select(User).where(User.family_id == family.id)).all()
    return FamilyResponse(
        id=family.id,
        name=family.name,
        pet_title=family.pet_title,
        owner_id=family.owner_id,
        created_at=family.created_at,
        members=[_build_member_response(member, db) for member in members],
    )


# 创建家庭；通常注册或登录管理员时会自动创建家庭，此接口仅保留兜底能力。
@router.post("", response_model=FamilyResponse, status_code=status.HTTP_201_CREATED)
def create_family(
    body: FamilyCreate,
    db: Session = Depends(get_db),
    admin: User = Depends(get_current_admin_with_active_access),
) -> FamilyResponse:
    existing = db.exec(select(Family).where(Family.owner_id == admin.id)).first()
    if existing:
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail="您已经有家庭")

    family = Family(name=body.name, owner_id=admin.id)
    db.add(family)
    db.commit()
    db.refresh(family)

    admin.family_id = family.id
    db.add(admin)
    db.commit()
    ensure_subscription_for_user(db, admin)
    return _build_family_response(family, db)


# 获取家庭资料和成员概览。
@router.get("/{family_id}", response_model=FamilyResponse)
def get_family(
    family_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user_with_active_access),
) -> FamilyResponse:
    family = db.get(Family, family_id)
    if not family:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="家庭不存在")
    if current_user.family_id != family_id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="无权查看此家庭")
    return _build_family_response(family, db)


# 管理员向家庭添加儿童成员，新增成员需要后续选择宠物。
@router.post(
    "/{family_id}/members",
    response_model=MemberResponse,
    status_code=status.HTTP_201_CREATED,
)
def add_member(
    family_id: int,
    body: MemberCreate,
    db: Session = Depends(get_db),
    admin: User = Depends(get_current_admin_with_active_access),
) -> MemberResponse:
    family = db.get(Family, family_id)
    if not family:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="家庭不存在")
    if family.owner_id != admin.id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="无权操作此家庭")

    member = User(nickname=body.nickname, role="child", family_id=family_id)
    db.add(member)
    db.commit()
    db.refresh(member)
    return _build_member_response(member, db)


# 为家庭成员选择宠物；宠物创建后只能通过完成任务成长。
@router.put("/{family_id}/members/{member_id}/pet", response_model=MemberResponse)
def set_member_pet(
    family_id: int,
    member_id: int,
    body: MemberPetSelection,
    db: Session = Depends(get_db),
    admin: User = Depends(get_current_admin_with_active_access),
) -> MemberResponse:
    family = db.get(Family, family_id)
    if not family:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="家庭不存在")
    if family.owner_id != admin.id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="无权操作此家庭")

    member = db.get(User, member_id)
    if not member or member.family_id != family_id:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="成员不存在")

    pet_type = body.pet_type.strip().lower()
    pet_name = body.name.strip()
    if pet_type not in VALID_SELECTABLE_PET_TYPES:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="不支持的宠物类型，可选：cat、dog、hamster、rabbit、turtle",
        )
    if not pet_name:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="宠物名称不能为空",
        )

    existing_pet = _get_member_pet(db, member_id)
    if existing_pet is not None:
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail="该成员已经拥有宠物")

    pet = Pet(**create_member_pet(family_id, member_id, pet_type, pet_name))
    db.add(pet)
    db.commit()
    return _build_member_response(member, db)


# 列出家庭成员和每个成员的选宠状态。
@router.get("/{family_id}/members", response_model=list[MemberResponse])
def list_members(
    family_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user_with_active_access),
) -> list[MemberResponse]:
    family = db.get(Family, family_id)
    if not family:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="家庭不存在")
    if current_user.family_id != family_id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="无权查看此家庭")
    members = db.exec(select(User).where(User.family_id == family_id)).all()
    return [_build_member_response(member, db) for member in members]


# 管理员删除家庭成员，同时删除该成员名下宠物。
@router.delete("/{family_id}/members/{member_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_member(
    family_id: int,
    member_id: int,
    db: Session = Depends(get_db),
    admin: User = Depends(get_current_admin_with_active_access),
) -> None:
    family = db.get(Family, family_id)
    if not family:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="家庭不存在")
    if family.owner_id != admin.id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="无权操作此家庭")
    member = db.get(User, member_id)
    if not member or member.family_id != family_id:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="成员不存在")
    if member.id == admin.id:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="不能删除自己")

    pets = db.exec(select(Pet).where(Pet.owner_id == member.id)).all()
    for pet in pets:
        db.delete(pet)
    member.family_id = None
    db.add(member)
    db.commit()


# 修改家庭名称或家庭宠物称呼。
@router.put("/{family_id}", response_model=FamilyResponse)
def update_family(
    family_id: int,
    body: FamilyUpdate,
    db: Session = Depends(get_db),
    admin: User = Depends(get_current_admin_with_active_access),
) -> FamilyResponse:
    family = db.get(Family, family_id)
    if not family:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="家庭不存在")
    if family.owner_id != admin.id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="无权操作此家庭")

    if body.name is not None:
        family.name = body.name
    if body.pet_title is not None:
        family.pet_title = body.pet_title
    db.add(family)
    db.commit()
    db.refresh(family)
    return _build_family_response(family, db)
