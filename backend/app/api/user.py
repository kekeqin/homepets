from fastapi import APIRouter, Depends, HTTPException, status
from sqlmodel import Session

from app.core.dependencies import (
    get_current_user_with_active_access,
    get_db,
)
from app.core.family_names import default_family_name, default_family_names_for
from app.models.family import Family
from app.models.user import User
from app.schemas.auth import UserResponse
from app.schemas.user import UserUpdate

router = APIRouter(prefix="/api/users", tags=["users"])


# 修改用户昵称或头像；管理员可以修改同家庭成员资料。
@router.put("/{user_id}", response_model=UserResponse)
def update_user(
    user_id: int,
    body: UserUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user_with_active_access),
) -> User:
    user = db.get(User, user_id)
    if not user:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="用户不存在")
    can_update_self = current_user.id == user_id
    can_update_family_member = (
        current_user.role == "admin"
        and current_user.family_id is not None
        and current_user.family_id == user.family_id
    )
    if not can_update_self and not can_update_family_member:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="只能修改自己或同家庭成员的信息",
        )
    if body.nickname is not None:
        old_nickname = user.nickname
        next_nickname = body.nickname
        if current_user.id == user.id and user.role == "admin" and user.family_id is not None:
            family = db.get(Family, user.family_id)
            if (
                family is not None
                and family.owner_id == user.id
                and family.name in default_family_names_for(old_nickname)
            ):
                family.name = default_family_name(next_nickname)
                db.add(family)
        user.nickname = next_nickname
    if body.avatar_url is not None:
        user.avatar_url = body.avatar_url
    db.add(user)
    db.commit()
    db.refresh(user)
    return user
