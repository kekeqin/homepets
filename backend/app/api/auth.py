from fastapi import APIRouter, Depends, HTTPException, status
from sqlmodel import Session, select

from app.core.dependencies import get_current_user, get_db
from app.core.security import create_access_token, hash_password, verify_password
from app.models.family import Family
from app.models.user import User
from app.schemas.auth import LoginRequest, RegisterRequest, TokenResponse, UserResponse

router = APIRouter(prefix="/api/auth", tags=["auth"])


def _ensure_admin_family(db: Session, user: User) -> None:
    """Auto-create a family for an admin if they do not have one yet."""
    if user.role != "admin" or user.family_id is not None:
        return

    existing = db.exec(select(Family).where(Family.owner_id == user.id)).first()
    if existing is not None:
        user.family_id = existing.id
        db.add(user)
        db.commit()
        return

    family = Family(name=f"{user.nickname}的家庭", owner_id=user.id)
    db.add(family)
    db.commit()
    db.refresh(family)

    user.family_id = family.id
    db.add(user)
    db.commit()


@router.post("/register", response_model=UserResponse, status_code=status.HTTP_201_CREATED)
def register(body: RegisterRequest, db: Session = Depends(get_db)) -> User:
    existing = db.exec(select(User).where(User.phone == body.phone)).first()
    if existing:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="该手机号已注册",
        )

    user = User(
        phone=body.phone,
        password_hash=hash_password(body.password),
        nickname=body.nickname,
        role="admin",
    )
    db.add(user)
    db.commit()
    db.refresh(user)

    _ensure_admin_family(db, user)
    db.refresh(user)
    return user


@router.post("/login", response_model=TokenResponse)
def login(body: LoginRequest, db: Session = Depends(get_db)) -> TokenResponse:
    user = db.exec(select(User).where(User.phone == body.phone)).first()
    if not user or not user.password_hash or not verify_password(body.password, user.password_hash):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="手机号或密码错误",
        )

    _ensure_admin_family(db, user)
    token = create_access_token(data={"sub": str(user.id)})
    return TokenResponse(access_token=token)


@router.get("/me", response_model=UserResponse)
def get_me(current_user: User = Depends(get_current_user)) -> User:
    return current_user
