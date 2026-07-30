#!/usr/bin/env python3
"""Grant a permanent premium subscription to a user.

Designed to run inside the backend Docker container (has app code + DATABASE_URL),
or locally with the same environment.

Permanent entitlement semantics (matches subscription_service.calculate_status):
  - status = subscribed_active
  - expires_at = None  (never expires)

Usage (inside container):
  python /path/to/grant_permanent_subscription.py ABC234
  python /path/to/grant_permanent_subscription.py --public-id ABC234
  python /path/to/grant_permanent_subscription.py --user-id 42 --dry-run
"""

from __future__ import annotations

import argparse
import sys
from datetime import UTC, datetime

from sqlmodel import Session, select

from app.core.config import settings
from app.core.database import engine
from app.models.subscription import Subscription
from app.models.user import User
from app.services.subscription_service import (
    build_subscription_status,
    ensure_subscription_for_user,
    revenuecat_app_user_id_for,
)

ADMIN_PROVIDER = "admin"
ADMIN_PRODUCT_ID = "admin_lifetime"


def now_utc() -> datetime:
    return datetime.now(UTC)


def parse_args(argv: list[str] | None = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Grant permanent premium subscription to a user (admin tool).",
    )
    id_group = parser.add_mutually_exclusive_group(required=False)
    id_group.add_argument(
        "--user-id",
        type=int,
        help="Internal numeric users.id (only when you intentionally need DB primary key)",
    )
    id_group.add_argument(
        "--public-id",
        type=str,
        help="User public_id (6-char, e.g. ABC234). Same as positional argument.",
    )
    parser.add_argument(
        "public_id_ref",
        nargs="?",
        help="User public_id (default identifier). Example: ABC234",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Show what would change without writing to the database",
    )
    args = parser.parse_args(argv)

    has_flag_id = args.user_id is not None or args.public_id is not None
    if args.public_id_ref and has_flag_id:
        parser.error("Do not pass both a positional public_id and --user-id/--public-id")

    if args.user_id is None and args.public_id is None:
        if not args.public_id_ref:
            parser.error("Provide a public_id (positional), --public-id, or --user-id")
        args.public_id = args.public_id_ref.strip().upper()
    elif args.public_id is not None:
        args.public_id = args.public_id.strip().upper()

    return args


def load_user(db: Session, *, user_id: int | None, public_id: str | None) -> User:
    if user_id is not None:
        user = db.get(User, user_id)
        if user is None:
            raise SystemExit(f"User not found: users.id={user_id}")
        return user

    assert public_id is not None
    user = db.exec(select(User).where(User.public_id == public_id)).first()
    if user is None:
        raise SystemExit(f"User not found: public_id={public_id}")
    return user


def _find_existing_subscription(db: Session, user: User) -> Subscription | None:
    if user.family_id is not None:
        statement = select(Subscription).where(Subscription.family_id == user.family_id)
    else:
        statement = select(Subscription).where(
            Subscription.user_id == user.id,
            Subscription.family_id.is_(None),  # type: ignore[union-attr]
        )
    return db.exec(statement).first()


def _print_user(user: User) -> None:
    print("---- user ----")
    print(f"  users.id     : {user.id}")
    print(f"  public_id    : {user.public_id}")
    print(f"  nickname     : {user.nickname}")
    print(f"  role         : {user.role}")
    print(f"  family_id    : {user.family_id}")


def grant_permanent(db: Session, user: User, *, dry_run: bool) -> Subscription | None:
    """Ensure subscription row exists and mark it as permanent premium."""
    current_time = now_utc()
    existing = _find_existing_subscription(db, user)

    _print_user(user)

    if dry_run:
        print("---- dry-run plan ----")
        if existing is None:
            print("  would create subscription row, then set permanent premium")
            print(f"  scope: {'family' if user.family_id is not None else 'user'}")
        else:
            print(f"  existing subscription id: {existing.id}")
            print(f"  status: {existing.status} -> subscribed_active")
            print(f"  expires_at: {existing.expires_at} -> None (never expires)")
            print(f"  provider: {existing.provider} -> {ADMIN_PROVIDER}")
            print(f"  product_id: {existing.product_id} -> {ADMIN_PRODUCT_ID}")
        print("[dry-run] no changes written")
        return existing

    subscription = ensure_subscription_for_user(db, user)
    before = {
        "id": subscription.id,
        "status": subscription.status,
        "expires_at": subscription.expires_at,
        "provider": subscription.provider,
        "product_id": subscription.product_id,
        "will_renew": subscription.will_renew,
        "family_id": subscription.family_id,
        "user_id": subscription.user_id,
        "revenuecat_app_user_id": subscription.revenuecat_app_user_id,
    }

    subscription.status = "subscribed_active"
    subscription.expires_at = None
    subscription.will_renew = False
    subscription.provider = ADMIN_PROVIDER
    subscription.product_id = ADMIN_PRODUCT_ID
    subscription.entitlement_id = settings.REVENUECAT_ENTITLEMENT_ID
    subscription.revenuecat_app_user_id = revenuecat_app_user_id_for(user)
    subscription.last_verified_at = current_time
    subscription.updated_at = current_time

    db.add(subscription)
    db.commit()
    db.refresh(subscription)

    after_status = build_subscription_status(subscription)
    print("---- subscription before ----")
    for key, value in before.items():
        print(f"  {key}: {value}")
    print("---- subscription after ----")
    print(f"  id                      : {subscription.id}")
    print(f"  status                  : {subscription.status}")
    print(f"  expires_at              : {subscription.expires_at}")
    print(f"  provider                : {subscription.provider}")
    print(f"  product_id              : {subscription.product_id}")
    print(f"  will_renew              : {subscription.will_renew}")
    print(f"  family_id               : {subscription.family_id}")
    print(f"  user_id                 : {subscription.user_id}")
    print(f"  revenuecat_app_user_id  : {subscription.revenuecat_app_user_id}")
    print("---- computed access ----")
    print(f"  computed_status : {after_status.status}")
    print(f"  access_allowed  : {after_status.access_allowed}")
    print(f"  is_premium      : {after_status.is_premium_active}")
    print(f"  scope           : {after_status.scope}")
    if user.family_id is not None:
        print(
            "Note: subscription is family-scoped; all members of this family share premium access."
        )
    return subscription


def main(argv: list[str] | None = None) -> int:
    args = parse_args(argv)
    print(f"database: {settings.database_url.split('@')[-1] if '@' in settings.database_url else settings.database_url}")

    with Session(engine) as db:
        user = load_user(db, user_id=args.user_id, public_id=args.public_id)
        grant_permanent(db, user, dry_run=args.dry_run)

    print("OK: permanent subscription granted" if not args.dry_run else "OK: dry-run complete")
    return 0


if __name__ == "__main__":
    # Support `python - <args>` when script is piped via stdin (shell helper).
    sys.exit(main())
