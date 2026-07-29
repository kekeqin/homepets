"""Generate unique 6-character public IDs for users."""

from __future__ import annotations

import secrets
from typing import TYPE_CHECKING

from sqlmodel import Session, select

if TYPE_CHECKING:
    from app.models.user import User

# Exclude ambiguous characters: 0/O, 1/I/L
PUBLIC_ID_ALPHABET = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
PUBLIC_ID_LENGTH = 6
_MAX_ALLOCATE_ATTEMPTS = 32


def generate_public_id() -> str:
    """Return a random 6-character alphanumeric public ID."""
    return "".join(secrets.choice(PUBLIC_ID_ALPHABET) for _ in range(PUBLIC_ID_LENGTH))


def allocate_public_id(db: Session, *, reserved: set[str] | None = None) -> str:
    """Allocate a public ID that is not already used in the database."""
    from app.models.user import User

    reserved_ids = reserved if reserved is not None else set()
    for _ in range(_MAX_ALLOCATE_ATTEMPTS):
        candidate = generate_public_id()
        if candidate in reserved_ids:
            continue
        existing = db.exec(select(User.id).where(User.public_id == candidate)).first()
        if existing is None:
            reserved_ids.add(candidate)
            return candidate
    raise RuntimeError("Unable to allocate a unique public_id")


def ensure_user_public_id(db: Session, user: User) -> bool:
    """Assign a public_id when missing. Returns True if the user was updated."""
    if user.public_id:
        return False
    user.public_id = allocate_public_id(db)
    db.add(user)
    db.commit()
    db.refresh(user)
    return True


def backfill_missing_public_ids(db: Session) -> int:
    """Assign public IDs to all users that are missing one. Returns count updated."""
    from app.models.user import User

    users = db.exec(select(User).where((User.public_id == None) | (User.public_id == ""))).all()  # noqa: E711
    if not users:
        return 0

    reserved: set[str] = set()
    updated = 0
    for user in users:
        user.public_id = allocate_public_id(db, reserved=reserved)
        db.add(user)
        updated += 1
    db.commit()
    return updated
