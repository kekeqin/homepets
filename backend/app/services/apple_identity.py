import hashlib
import json
from collections.abc import Sequence
from dataclasses import dataclass
from datetime import UTC, datetime, timedelta
from threading import Lock
from typing import Any, Protocol
from urllib.error import HTTPError, URLError
from urllib.request import Request, urlopen

from jose import JWTError, jwt

from app.core.config import Settings, settings

APPLE_ISSUER = "https://appleid.apple.com"
APPLE_ID_TOKEN_ALGORITHMS = ["RS256"]


class AppleIdentityVerifierProtocol(Protocol):
    def verify(self, identity_token: str, nonce: str | None = None) -> "AppleIdentity": ...


@dataclass(frozen=True)
class AppleIdentity:
    subject: str
    email: str | None = None
    email_verified: bool = False


class AppleIdentityVerificationError(Exception):
    pass


class AppleIdentityConfigurationError(AppleIdentityVerificationError):
    pass


class AppleIdentityVerifier:
    def __init__(
        self,
        *,
        client_ids: Sequence[str],
        keys_url: str,
        timeout_seconds: float,
        keys_cache_seconds: int,
    ) -> None:
        self._client_ids = tuple(client_ids)
        self._keys_url = keys_url
        self._timeout_seconds = timeout_seconds
        self._keys_cache_seconds = keys_cache_seconds
        self._keys: list[dict[str, Any]] | None = None
        self._keys_expires_at: datetime | None = None
        self._lock = Lock()

    @classmethod
    def from_settings(cls, app_settings: Settings) -> "AppleIdentityVerifier":
        return cls(
            client_ids=app_settings.apple_sign_in_client_ids,
            keys_url=app_settings.APPLE_SIGN_IN_KEYS_URL,
            timeout_seconds=app_settings.APPLE_SIGN_IN_TIMEOUT_SECONDS,
            keys_cache_seconds=app_settings.APPLE_SIGN_IN_KEYS_CACHE_SECONDS,
        )

    def verify(self, identity_token: str, nonce: str | None = None) -> AppleIdentity:
        if not self._client_ids:
            raise AppleIdentityConfigurationError("Apple Sign in client ids are not configured")
        if not identity_token.strip():
            raise AppleIdentityVerificationError("Missing identity token")

        try:
            header = jwt.get_unverified_header(identity_token)
        except JWTError as exc:
            raise AppleIdentityVerificationError("Invalid Apple identity token header") from exc

        key = self._key_for_header(header)
        try:
            claims = jwt.decode(
                identity_token,
                key,
                algorithms=APPLE_ID_TOKEN_ALGORITHMS,
                options={"verify_aud": False},
            )
        except JWTError as exc:
            raise AppleIdentityVerificationError("Invalid Apple identity token") from exc

        return self._identity_from_claims(claims, nonce)

    def _key_for_header(self, header: dict[str, Any]) -> dict[str, Any]:
        token_algorithm = header.get("alg")
        if token_algorithm not in APPLE_ID_TOKEN_ALGORITHMS:
            raise AppleIdentityVerificationError("Unsupported Apple identity token algorithm")

        key_id = header.get("kid")
        if not isinstance(key_id, str) or not key_id:
            raise AppleIdentityVerificationError("Missing Apple identity token key id")

        for key in self._public_keys():
            if key.get("kid") == key_id:
                return key

        raise AppleIdentityVerificationError("Unknown Apple identity token key id")

    def _public_keys(self) -> list[dict[str, Any]]:
        now = datetime.now(UTC)
        with self._lock:
            if (
                self._keys is not None
                and self._keys_expires_at is not None
                and self._keys_expires_at > now
            ):
                return self._keys

            request = Request(self._keys_url, headers={"User-Agent": "HomePets/1.0"})
            try:
                with urlopen(request, timeout=self._timeout_seconds) as response:
                    payload = json.loads(response.read().decode("utf-8"))
            except (HTTPError, URLError, TimeoutError, OSError, json.JSONDecodeError) as exc:
                raise AppleIdentityVerificationError("Failed to fetch Apple public keys") from exc

            keys = payload.get("keys")
            if not isinstance(keys, list):
                raise AppleIdentityVerificationError("Apple public keys response is invalid")

            parsed_keys = [key for key in keys if isinstance(key, dict)]
            self._keys = parsed_keys
            self._keys_expires_at = now + timedelta(seconds=self._keys_cache_seconds)
            return parsed_keys

    def _identity_from_claims(
        self,
        claims: dict[str, Any],
        nonce: str | None,
    ) -> AppleIdentity:
        if claims.get("iss") != APPLE_ISSUER:
            raise AppleIdentityVerificationError("Apple identity token issuer is invalid")

        audience = claims.get("aud")
        if audience not in self._client_ids:
            raise AppleIdentityVerificationError("Apple identity token audience is invalid")

        subject = claims.get("sub")
        if not isinstance(subject, str) or not subject:
            raise AppleIdentityVerificationError("Apple identity token subject is missing")

        if nonce:
            token_nonce = claims.get("nonce")
            allowed_nonces = {nonce, hashlib.sha256(nonce.encode("utf-8")).hexdigest()}
            if token_nonce not in allowed_nonces:
                raise AppleIdentityVerificationError("Apple identity token nonce is invalid")

        email = claims.get("email")
        return AppleIdentity(
            subject=subject,
            email=email if isinstance(email, str) and email else None,
            email_verified=_truthy_claim(claims.get("email_verified")),
        )


def _truthy_claim(value: Any) -> bool:
    if isinstance(value, bool):
        return value
    if isinstance(value, str):
        return value.lower() == "true"
    return False


def get_apple_identity_verifier() -> AppleIdentityVerifierProtocol:
    return AppleIdentityVerifier.from_settings(settings)
