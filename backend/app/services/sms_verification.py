import base64
import hashlib
import hmac
import json
from collections.abc import Callable
from dataclasses import dataclass
from datetime import UTC, datetime, timedelta
from secrets import randbelow
from threading import Lock
from typing import Any, Protocol
from urllib.error import HTTPError, URLError
from urllib.parse import quote
from urllib.request import Request, urlopen
from uuid import uuid4

from app.core.config import Settings, settings


class SmsVerificationClient(Protocol):
    def send_code(self, phone: str) -> None: ...

    def check_code(self, phone: str, code: str) -> bool: ...


class SmsVerificationError(Exception):
    pass


class SmsVerificationConfigurationError(SmsVerificationError):
    pass


@dataclass(frozen=True)
class _MockSmsCode:
    code: str
    expires_at: datetime


class MockSmsVerificationClient:
    def __init__(
        self,
        *,
        valid_seconds: int,
        now: Callable[[], datetime] | None = None,
        code_factory: Callable[[], str] | None = None,
    ) -> None:
        self._valid_seconds = valid_seconds
        self._now = now or (lambda: datetime.now(UTC))
        self._code_factory = code_factory or self._generate_code
        self._codes: dict[str, _MockSmsCode] = {}
        self._lock = Lock()

    def send_code(self, phone: str) -> None:
        code = self._code_factory()
        expires_at = self._now() + timedelta(seconds=self._valid_seconds)
        with self._lock:
            self._codes[phone] = _MockSmsCode(code=code, expires_at=expires_at)

        print(
            f"[HomePets SMS MOCK] phone={phone} code={code} expires_at={expires_at.isoformat()}",
            flush=True,
        )

    def check_code(self, phone: str, code: str) -> bool:
        with self._lock:
            stored = self._codes.get(phone)
            if stored is None:
                return False
            if stored.expires_at <= self._now():
                self._codes.pop(phone, None)
                return False
            if not hmac.compare_digest(stored.code, code):
                return False
            self._codes.pop(phone, None)
            return True

    def reset(self) -> None:
        with self._lock:
            self._codes.clear()

    def _generate_code(self) -> str:
        return f"{randbelow(1_000_000):06d}"


class AliyunSmsVerificationClient:
    def __init__(
        self,
        *,
        access_key_id: str,
        access_key_secret: str,
        sign_name: str,
        template_code: str,
        scheme_name: str,
        region_id: str,
        endpoint: str,
        valid_seconds: int,
        timeout_seconds: float,
    ) -> None:
        self._access_key_id = access_key_id
        self._access_key_secret = access_key_secret
        self._sign_name = sign_name
        self._template_code = template_code
        self._scheme_name = scheme_name
        self._region_id = region_id
        self._endpoint = endpoint
        self._valid_seconds = valid_seconds
        self._timeout_seconds = timeout_seconds

    @classmethod
    def from_settings(cls, app_settings: Settings) -> "AliyunSmsVerificationClient":
        required = {
            "ALIBABA_CLOUD_ACCESS_KEY_ID": app_settings.ALIBABA_CLOUD_ACCESS_KEY_ID,
            "ALIBABA_CLOUD_ACCESS_KEY_SECRET": app_settings.ALIBABA_CLOUD_ACCESS_KEY_SECRET,
            "ALIYUN_SMS_SIGN_NAME": app_settings.ALIYUN_SMS_SIGN_NAME,
            "ALIYUN_SMS_TEMPLATE_CODE": app_settings.ALIYUN_SMS_TEMPLATE_CODE,
        }
        missing = [name for name, value in required.items() if not value]
        if missing:
            raise SmsVerificationConfigurationError(
                f"Missing SMS configuration: {', '.join(missing)}"
            )

        return cls(
            access_key_id=app_settings.ALIBABA_CLOUD_ACCESS_KEY_ID or "",
            access_key_secret=app_settings.ALIBABA_CLOUD_ACCESS_KEY_SECRET or "",
            sign_name=app_settings.ALIYUN_SMS_SIGN_NAME or "",
            template_code=app_settings.ALIYUN_SMS_TEMPLATE_CODE or "",
            scheme_name=app_settings.ALIYUN_SMS_SCHEME_NAME,
            region_id=app_settings.ALIYUN_SMS_REGION_ID,
            endpoint=app_settings.ALIYUN_SMS_ENDPOINT,
            valid_seconds=app_settings.ALIYUN_SMS_CODE_VALID_SECONDS,
            timeout_seconds=app_settings.ALIYUN_SMS_TIMEOUT_SECONDS,
        )

    def send_code(self, phone: str) -> None:
        response = self._request(
            "SendSmsVerifyCode",
            {
                "PhoneNumber": phone,
                "SignName": self._sign_name,
                "TemplateCode": self._template_code,
                "TemplateParam": self._template_param(),
                "SchemeName": self._scheme_name,
            },
        )
        self._ensure_ok(response)

    def check_code(self, phone: str, code: str) -> bool:
        response = self._request(
            "CheckSmsVerifyCode",
            {
                "PhoneNumber": phone,
                "VerifyCode": code,
                "SchemeName": self._scheme_name,
            },
        )
        self._ensure_ok(response)
        model = response.get("Model")
        if not isinstance(model, dict):
            return False
        return model.get("VerifyResult") == "PASS"

    def _template_param(self) -> str:
        valid_minutes = max(1, self._valid_seconds // 60)
        valid_minutes_text = str(valid_minutes)
        return json.dumps(
            {
                "code": "##code##",
                "min": valid_minutes_text,
                "minute": valid_minutes_text,
            },
            ensure_ascii=False,
        )

    def _request(self, action: str, business_params: dict[str, str]) -> dict[str, Any]:
        params = {
            "Action": action,
            "Version": "2017-05-25",
            "Format": "JSON",
            "AccessKeyId": self._access_key_id,
            "SignatureMethod": "HMAC-SHA1",
            "Timestamp": datetime.now(UTC).strftime("%Y-%m-%dT%H:%M:%SZ"),
            "SignatureVersion": "1.0",
            "SignatureNonce": str(uuid4()),
            "RegionId": self._region_id,
            **business_params,
        }
        signed_params = {**params, "Signature": self._signature("POST", params)}
        body = self._encode_query(signed_params).encode()
        request = Request(
            self._endpoint,
            data=body,
            headers={"Content-Type": "application/x-www-form-urlencoded"},
            method="POST",
        )
        try:
            raw = urlopen(request, timeout=self._timeout_seconds).read()
        except HTTPError as exc:
            error_body = exc.read().decode("utf-8", errors="replace")
            message = self._error_message(error_body)
            raise SmsVerificationError(
                f"Aliyun SMS request failed: HTTP {exc.code}: {message}"
            ) from exc
        except URLError as exc:
            raise SmsVerificationError(f"Aliyun SMS request failed: {exc.reason}") from exc

        payload = json.loads(raw.decode("utf-8"))
        if not isinstance(payload, dict):
            raise SmsVerificationError("Aliyun SMS returned an invalid payload")
        return dict(payload)

    def _error_message(self, raw_body: str) -> str:
        if not raw_body:
            return "empty response body"
        try:
            payload = json.loads(raw_body)
        except json.JSONDecodeError:
            return raw_body
        if not isinstance(payload, dict):
            return raw_body

        code = payload.get("Code")
        message = payload.get("Message")
        request_id = payload.get("RequestId")
        parts = [
            str(value)
            for value in (code, message, request_id)
            if isinstance(value, str) and value
        ]
        return " | ".join(parts) if parts else raw_body

    def _signature(self, method: str, params: dict[str, str]) -> str:
        canonicalized_query = self._encode_query(dict(sorted(params.items())))
        string_to_sign = f"{method}&%2F&{self._percent_encode(canonicalized_query)}"
        digest = hmac.new(
            f"{self._access_key_secret}&".encode(),
            string_to_sign.encode(),
            hashlib.sha1,
        ).digest()
        return base64.b64encode(digest).decode()

    def _encode_query(self, params: dict[str, str]) -> str:
        return "&".join(
            f"{self._percent_encode(key)}={self._percent_encode(value)}"
            for key, value in params.items()
        )

    def _percent_encode(self, value: str) -> str:
        return quote(value, safe="~")

    def _ensure_ok(self, response: dict[str, Any]) -> None:
        if response.get("Code") == "OK":
            return
        message = response.get("Message", "Aliyun SMS request was rejected")
        raise SmsVerificationError(str(message))


mock_sms_verification_client = MockSmsVerificationClient(
    valid_seconds=settings.ALIYUN_SMS_CODE_VALID_SECONDS,
)


def get_sms_verification_client() -> SmsVerificationClient:
    if settings.SMS_VERIFICATION_MOCK_ENABLED:
        return mock_sms_verification_client
    return AliyunSmsVerificationClient.from_settings(settings)
