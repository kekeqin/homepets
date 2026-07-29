from fastapi import APIRouter, Depends, HTTPException, status
from sqlmodel import Session, col, select

from app.core.dependencies import (
    get_current_admin_with_active_access,
    get_current_user,
    get_db,
)
from app.core.family_names import default_family_name, default_family_names_for
from app.models.family import Family
from app.models.pet import Pet
from app.models.user import User
from app.schemas.family import (
    FamilyResponse,
    FamilyUpdate,
    MemberCreate,
    MemberPetSelection,
    MemberResponse,
)
from app.services.pet_service import VALID_SELECTABLE_PET_TYPES, create_member_pet
from app.services.user_public_id import allocate_public_id

router = APIRouter(prefix="/api/families", tags=["families"])


def _get_member_pet(db: Session, member_id: int) -> Pet | None:
    return db.exec(
        select(Pet).where(Pet.owner_id == member_id).order_by(Pet.created_at.desc())
    ).first()


def _get_latest_member_pets(db: Session, members: list[User]) -> dict[int, Pet]:
    member_ids = [member.id for member in members if member.id is not None]
    if not member_ids:
        return {}

    pets = db.exec(
        select(Pet).where(col(Pet.owner_id).in_(member_ids)).order_by(Pet.created_at.desc())
    ).all()
    latest_pets: dict[int, Pet] = {}
    for pet in pets:
        latest_pets.setdefault(pet.owner_id, pet)
    return latest_pets


def _build_member_response(member: User, pet: Pet | None) -> MemberResponse:
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


def _build_single_member_response(member: User, db: Session) -> MemberResponse:
    return _build_member_response(member, _get_member_pet(db, member.id or 0))


def _build_family_response(family: Family, db: Session) -> FamilyResponse:
    members = db.exec(select(User).where(User.family_id == family.id)).all()
    latest_pets = _get_latest_member_pets(db, members)
    return FamilyResponse(
        id=family.id,
        name=family.name,
        pet_title=family.pet_title,
        owner_id=family.owner_id,
        created_at=family.created_at,
        members=[
            _build_member_response(member, latest_pets.get(member.id or 0)) for member in members
        ],
    )


def _normalize_default_family_name(family: Family, db: Session) -> None:
    owner = db.get(User, family.owner_id)
    if owner is None:
        return
    if family.name not in default_family_names_for(owner.nickname):
        return

    next_name = default_family_name(owner.nickname)
    if family.name == next_name:
        return

    family.name = next_name
    db.add(family)
    db.commit()
    db.refresh(family)


def _validate_member_pet_selection(body: MemberCreate) -> tuple[str, str] | None:
    pet_type = body.pet_type.strip().lower() if body.pet_type is not None else None
    pet_name = (body.pet_name or body.name or "").strip()

    if pet_type is None and not pet_name:
        return None
    if pet_type is None:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="请选择宠物类型",
        )
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

    return pet_type, pet_name


# 获取家庭资料和成员概览。
@router.get("/{family_id}", response_model=FamilyResponse)
def get_family(
    family_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> FamilyResponse:
    family = db.get(Family, family_id)
    if not family:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="家庭不存在")
    if current_user.family_id != family_id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="无权查看此家庭")
    _normalize_default_family_name(family, db)
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

    pet_selection = _validate_member_pet_selection(body)
    member = User(
        nickname=body.nickname,
        role="child",
        family_id=family_id,
        public_id=allocate_public_id(db),
    )
    db.add(member)
    db.flush()

    if pet_selection is not None:
        pet_type, pet_name = pet_selection
        if member.id is None:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="成员创建失败",
            )
        pet = Pet(**create_member_pet(family_id, member.id, pet_type, pet_name))
        db.add(pet)

    db.commit()
    db.refresh(member)
    return _build_single_member_response(member, db)


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
    return _build_single_member_response(member, db)


# 列出家庭成员和每个成员的选宠状态。
@router.get("/{family_id}/members", response_model=list[MemberResponse])
def list_members(
    family_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> list[MemberResponse]:
    family = db.get(Family, family_id)
    if not family:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="家庭不存在")
    if current_user.family_id != family_id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="无权查看此家庭")
    members = db.exec(select(User).where(User.family_id == family_id)).all()
    latest_pets = _get_latest_member_pets(db, members)
    return [_build_member_response(member, latest_pets.get(member.id or 0)) for member in members]


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
