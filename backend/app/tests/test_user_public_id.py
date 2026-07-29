from sqlmodel import Session, select

from app.models.user import User
from app.services.user_public_id import (
    PUBLIC_ID_ALPHABET,
    PUBLIC_ID_LENGTH,
    allocate_public_id,
    generate_public_id,
)


def test_generate_public_id_format() -> None:
    public_id = generate_public_id()
    assert len(public_id) == PUBLIC_ID_LENGTH
    assert all(char in PUBLIC_ID_ALPHABET for char in public_id)


def test_allocate_public_id_is_unique(db: Session) -> None:
    first = allocate_public_id(db)
    user = User(phone="13800000099", nickname="测试", role="admin", public_id=first)
    db.add(user)
    db.commit()

    second = allocate_public_id(db)
    assert second != first
    assert len(second) == PUBLIC_ID_LENGTH


def test_user_default_factory_assigns_public_id(db: Session) -> None:
    user = User(phone="13800000088", nickname="默认", role="admin")
    db.add(user)
    db.commit()
    db.refresh(user)

    assert user.public_id
    assert len(user.public_id) == PUBLIC_ID_LENGTH
    stored = db.exec(select(User).where(User.id == user.id)).first()
    assert stored is not None
    assert stored.public_id == user.public_id
