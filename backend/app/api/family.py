from fastapi import APIRouter, Depends, HTTPException, status
from sqlmodel import Session, select

from app.api.pet import auto_create_egg
from app.core.dependencies import get_current_admin, get_current_user, get_db
from app.models.family import Family
from app.models.pet import Pet
from app.models.user import User
from app.schemas.family import (
    FamilyCreate,
    FamilyResponse,
    FamilyUpdate,
    MemberCreate,
    MemberResponse,
)

router = APIRouter(prefix="/api/families", tags=["families"])


def _build_family_response(family: Family, db: Session) -> FamilyResponse:
    members = db.exec(select(User).where(User.family_id == family.id)).all()
    return FamilyResponse(
        id=family.id,
        name=family.name,
        pet_title=family.pet_title,
        owner_id=family.owner_id,
        created_at=family.created_at,
        members=[
            MemberResponse(
                id=m.id, nickname=m.nickname, role=m.role, avatar_url=m.avatar_url, points=m.points
            )
            for m in members
        ],
    )


@router.post("", response_model=FamilyResponse, status_code=status.HTTP_201_CREATED)
def create_family(
    body: FamilyCreate,
    db: Session = Depends(get_db),
    admin: User = Depends(get_current_admin),
) -> FamilyResponse:
    existing = db.exec(select(Family).where(Family.owner_id == admin.id)).first()
    if existing:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="您已有家庭组",
        )
    family = Family(name=body.name, owner_id=admin.id)
    db.add(family)
    db.commit()
    db.refresh(family)
    admin.family_id = family.id
    db.add(admin)
    db.commit()
    # Auto-create egg for admin
    auto_create_egg(db, family.id, admin.id)
    return _build_family_response(family, db)


@router.get("/{family_id}", response_model=FamilyResponse)
def get_family(
    family_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> FamilyResponse:
    family = db.get(Family, family_id)
    if not family:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="家庭组不存在")
    return _build_family_response(family, db)


@router.post(
    "/{family_id}/members",
    response_model=MemberResponse,
    status_code=status.HTTP_201_CREATED,
)
def add_member(
    family_id: int,
    body: MemberCreate,
    db: Session = Depends(get_db),
    admin: User = Depends(get_current_admin),
) -> User:
    family = db.get(Family, family_id)
    if not family:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="家庭组不存在")
    if family.owner_id != admin.id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="无权操作此家庭组")
    member = User(
        nickname=body.nickname,
        role="child",
        family_id=family_id,
    )
    db.add(member)
    db.commit()
    db.refresh(member)
    # Auto-create egg for new member
    auto_create_egg(db, family_id, member.id)  # type: ignore[arg-type]
    return member


@router.get("/{family_id}/members", response_model=list[MemberResponse])
def list_members(
    family_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> list[User]:
    family = db.get(Family, family_id)
    if not family:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="家庭组不存在")
    members = db.exec(select(User).where(User.family_id == family_id)).all()
    return list(members)


@router.delete("/{family_id}/members/{member_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_member(
    family_id: int,
    member_id: int,
    db: Session = Depends(get_db),
    admin: User = Depends(get_current_admin),
) -> None:
    family = db.get(Family, family_id)
    if not family:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="家庭组不存在")
    if family.owner_id != admin.id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="无权操作此家庭组")
    member = db.get(User, member_id)
    if not member or member.family_id != family_id:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="成员不存在")
    if member.id == admin.id:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="不能删除自己")
    # Delete member's pets
    pets = db.exec(select(Pet).where(Pet.owner_id == member.id)).all()
    for pet in pets:
        db.delete(pet)
    member.family_id = None
    db.add(member)
    db.commit()


@router.put("/{family_id}", response_model=FamilyResponse)
def update_family(
    family_id: int,
    body: FamilyUpdate,
    db: Session = Depends(get_db),
    admin: User = Depends(get_current_admin),
) -> FamilyResponse:
    family = db.get(Family, family_id)
    if not family:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="家庭组不存在")
    if family.owner_id != admin.id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="无权操作此家庭组")
    if body.name is not None:
        family.name = body.name
    if body.pet_title is not None:
        family.pet_title = body.pet_title
    db.add(family)
    db.commit()
    db.refresh(family)
    return _build_family_response(family, db)
