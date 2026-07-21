import logging

from fastapi import APIRouter, Depends, HTTPException, Request, status
from sqlmodel import Session, select

from app.core.config import settings
from app.core.dependencies import get_current_user, get_db
from app.core.family_names import default_family_name, default_family_names_for
from app.core.security import create_access_token
from app.models.family import Family
from app.models.user import User
from app.schemas.auth import (
    AppleLoginRequest,
    LoginRequest,
    SmsCodeRequest,
    SmsCodeResponse,
    TokenResponse,
    UserResponse,
)
from app.services.apple_identity import (
    AppleIdentityConfigurationError,
    AppleIdentityVerificationError,
    AppleIdentityVerifierProtocol,
    get_apple_identity_verifier,
)
from app.services.sms_rate_limiter import SmsRateLimiter
from app.services.sms_verification import (
    SmsVerificationClient,
    SmsVerificationConfigurationError,
    SmsVerificationError,
    get_sms_verification_client,
)
from app.services.subscription_service import ensure_subscription_for_user

router = APIRouter(prefix="/api/auth", tags=["auth"])
logger = logging.getLogger(__name__)

sms_rate_limiter = SmsRateLimiter(
    send_cooldown_seconds=settings.ALIYUN_SMS_RESEND_INTERVAL_SECONDS,
    phone_send_limit_per_hour=settings.SMS_SEND_RATE_LIMIT_PER_PHONE_PER_HOUR,
    ip_send_limit_per_hour=settings.SMS_SEND_RATE_LIMIT_PER_IP_PER_HOUR,
    phone_verify_failure_limit=settings.SMS_VERIFY_FAILURE_LIMIT_PER_PHONE,
    ip_verify_failure_limit=settings.SMS_VERIFY_FAILURE_LIMIT_PER_IP,
    verify_failure_window_seconds=settings.SMS_VERIFY_FAILURE_WINDOW_SECONDS,
)


def _normalize_default_family_name(db: Session, user: User, family: Family) -> None:
    if family.owner_id != user.id:
        return
    if family.name not in default_family_names_for(user.nickname):
        return

    next_name = default_family_name(user.nickname)
    if family.name == next_name:
        return

    family.name = next_name
    db.add(family)
    db.commit()


def _ensure_admin_family(db: Session, user: User) -> None:
    """Ensure each admin user owns or belongs to a family after login."""
    if user.role != "admin":
        return

    if user.family_id is not None:
        family = db.get(Family, user.family_id)
        if family is not None:
            _normalize_default_family_name(db, user, family)
        return

    existing = db.exec(select(Family).where(Family.owner_id == user.id)).first()
    if existing is not None:
        _normalize_default_family_name(db, user, existing)
        user.family_id = existing.id
        db.add(user)
        db.commit()
        return

    family = Family(name=default_family_name(user.nickname), owner_id=user.id)
    db.add(family)
    db.commit()
    db.refresh(family)

    user.family_id = family.id
    db.add(user)
    db.commit()


def _create_session_token(db: Session, user: User) -> TokenResponse:
    _ensure_admin_family(db, user)
    ensure_subscription_for_user(db, user)
    token = create_access_token(data={"sub": str(user.id)})
    return TokenResponse(access_token=token)


@router.post("/apple", response_model=TokenResponse)
def login_with_apple(
    body: AppleLoginRequest,
    db: Session = Depends(get_db),
    apple_verifier: AppleIdentityVerifierProtocol = Depends(get_apple_identity_verifier),
) -> TokenResponse:
    try:
        identity = apple_verifier.verify(body.identity_token, body.nonce)
    except AppleIdentityConfigurationError as exc:
        logger.error("Apple Sign In is not configured: %s", exc)
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="\u82f9\u679c\u767b\u5f55\u670d\u52a1\u5c1a\u672a\u914d\u7f6e",
        ) from exc
    except AppleIdentityVerificationError as exc:
        logger.warning("Apple Sign In identity verification failed: %s", exc)
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="\u82f9\u679c\u767b\u5f55\u51ed\u8bc1\u65e0\u6548",
        ) from exc

    user = db.exec(select(User).where(User.apple_sub == identity.subject)).first()
    if user is None:
        user = User(
            apple_sub=identity.subject,
            email=identity.email,
            nickname=_apple_display_name(body.full_name),
            role="admin",
        )
        db.add(user)
        db.commit()
        db.refresh(user)
    elif identity.email and user.email != identity.email:
        user.email = identity.email
        db.add(user)
        db.commit()
        db.refresh(user)

    return _create_session_token(db, user)


@router.post(
    "/sms-code",
    response_model=SmsCodeResponse,
    response_model_exclude_none=True,
)
def send_sms_code(
    body: SmsCodeRequest,
    request: Request,
    sms_client: SmsVerificationClient = Depends(get_sms_verification_client),
) -> SmsCodeResponse:
    ip_address = _client_host(request)
    apply_send_rate_limit = _should_apply_sms_send_rate_limit()
    if apply_send_rate_limit:
        retry_after = sms_rate_limiter.retry_after_send(body.phone, ip_address)
        if retry_after > 0:
            raise _rate_limited(
                code="SMS_SEND_RATE_LIMITED",
                message="验证码发送太频繁，请稍后再试",
                retry_after_seconds=retry_after,
            )

    try:
        dev_code = sms_client.send_code(body.phone)
    except SmsVerificationConfigurationError as exc:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="短信服务尚未配置",
        ) from exc
    except SmsVerificationError as exc:
        logger.warning(
            "Aliyun SMS code send failed for phone_suffix=%s: %s",
            body.phone[-4:],
            exc,
        )
        raise HTTPException(
            status_code=status.HTTP_502_BAD_GATEWAY,
            detail="验证码发送失败，请稍后再试",
        ) from exc

    if apply_send_rate_limit:
        sms_rate_limiter.record_send(body.phone, ip_address)

    cooldown_seconds = settings.ALIYUN_SMS_RESEND_INTERVAL_SECONDS if apply_send_rate_limit else 0
    if not (settings.DEBUG or settings.SMS_VERIFICATION_MOCK_ENABLED):
        dev_code = None
    return SmsCodeResponse(cooldown_seconds=cooldown_seconds, dev_code=dev_code)


@router.post("/login", response_model=TokenResponse)
def login(
    body: LoginRequest,
    request: Request,
    db: Session = Depends(get_db),
    sms_client: SmsVerificationClient = Depends(get_sms_verification_client),
) -> TokenResponse:
    ip_address = _client_host(request)
    apply_verify_rate_limit = _should_apply_sms_verify_rate_limit()
    if apply_verify_rate_limit:
        retry_after = sms_rate_limiter.retry_after_verify(body.phone, ip_address)
    else:
        retry_after = 0
    if retry_after > 0:
        raise _rate_limited(
            code="SMS_VERIFY_RATE_LIMITED",
            message="验证码尝试过多，请稍后再试",
            retry_after_seconds=retry_after,
        )

    try:
        verified = sms_client.check_code(body.phone, body.code)
    except SmsVerificationConfigurationError as exc:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="短信服务尚未配置",
        ) from exc
    except SmsVerificationError as exc:
        raise HTTPException(
            status_code=status.HTTP_502_BAD_GATEWAY,
            detail="验证码校验失败，请稍后再试",
        ) from exc

    if not verified:
        if apply_verify_rate_limit:
            sms_rate_limiter.record_verify_failure(body.phone, ip_address)
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="验证码错误或已过期",
        )

    if apply_verify_rate_limit:
        sms_rate_limiter.clear_verify_failures(body.phone, ip_address)
    user = db.exec(select(User).where(User.phone == body.phone)).first()
    if user is None:
        user = User(phone=body.phone, nickname="我", role="admin")
        db.add(user)
        db.commit()
        db.refresh(user)

    _ensure_admin_family(db, user)
    ensure_subscription_for_user(db, user)
    token = create_access_token(data={"sub": str(user.id)})
    return TokenResponse(access_token=token)


@router.get("/me", response_model=UserResponse)
def get_me(current_user: User = Depends(get_current_user)) -> User:
    return current_user


def _client_host(request: Request) -> str:
    return request.client.host if request.client else "unknown"


def _should_apply_sms_send_rate_limit() -> bool:
    return not (settings.DEBUG or settings.SMS_VERIFICATION_MOCK_ENABLED)


def _should_apply_sms_verify_rate_limit() -> bool:
    return not (settings.DEBUG or settings.SMS_VERIFICATION_MOCK_ENABLED)


def _apple_display_name(full_name: str | None) -> str:
    if full_name is None:
        return "我"

    display_name = " ".join(full_name.split())
    if not display_name:
        return "我"

    return display_name[:50]


def _rate_limited(code: str, message: str, retry_after_seconds: int) -> HTTPException:
    return HTTPException(
        status_code=status.HTTP_429_TOO_MANY_REQUESTS,
        detail={
            "code": code,
            "message": message,
            "retry_after_seconds": retry_after_seconds,
        },
        headers={"Retry-After": str(retry_after_seconds)},
    )
