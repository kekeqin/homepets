import base64
import hashlib
import json
from datetime import UTC, datetime, timedelta
from io import BytesIO
from typing import Any
from unittest.mock import patch

import pytest
from cryptography.hazmat.primitives import serialization
from cryptography.hazmat.primitives.asymmetric import rsa
from jose import jwt

from app.services.apple_identity import (
    APPLE_ISSUER,
    AppleIdentityConfigurationError,
    AppleIdentityVerificationError,
    AppleIdentityVerifier,
)


@pytest.fixture
def rsa_key_pair() -> tuple[rsa.RSAPrivateKey, dict[str, Any]]:
    private_key = rsa.generate_private_key(public_exponent=65537, key_size=2048)
    public_numbers = private_key.public_key().public_numbers()
    jwk = {
        "kty": "RSA",
        "kid": "test-key-1",
        "use": "sig",
        "alg": "RS256",
        "n": _int_to_base64url(public_numbers.n),
        "e": _int_to_base64url(public_numbers.e),
    }
    return private_key, jwk


def test_verify_rejects_missing_client_ids() -> None:
    verifier = AppleIdentityVerifier(
        client_ids=[],
        keys_url="https://example.test/keys",
        timeout_seconds=1,
        keys_cache_seconds=60,
    )

    with pytest.raises(AppleIdentityConfigurationError):
        verifier.verify("token")


def test_verify_accepts_valid_identity_token(rsa_key_pair: tuple[Any, dict[str, Any]]) -> None:
    private_key, jwk = rsa_key_pair
    raw_nonce = "client-nonce-123"
    token = _mint_apple_token(
        private_key,
        kid=jwk["kid"],
        subject="apple-user-1",
        audience="com.kkqin.pickstarpet",
        email="parent@example.com",
        nonce=hashlib.sha256(raw_nonce.encode("utf-8")).hexdigest(),
    )
    verifier = AppleIdentityVerifier(
        client_ids=["com.kkqin.pickstarpet"],
        keys_url="https://example.test/keys",
        timeout_seconds=1,
        keys_cache_seconds=60,
    )

    with patch(
        "app.services.apple_identity.urlopen",
        return_value=_FakeResponse({"keys": [jwk]}),
    ):
        identity = verifier.verify(token, raw_nonce)

    assert identity.subject == "apple-user-1"
    assert identity.email == "parent@example.com"
    assert identity.email_verified is True


def test_verify_rejects_wrong_audience(rsa_key_pair: tuple[Any, dict[str, Any]]) -> None:
    private_key, jwk = rsa_key_pair
    token = _mint_apple_token(
        private_key,
        kid=jwk["kid"],
        subject="apple-user-1",
        audience="com.wrong.bundle",
    )
    verifier = AppleIdentityVerifier(
        client_ids=["com.kkqin.pickstarpet"],
        keys_url="https://example.test/keys",
        timeout_seconds=1,
        keys_cache_seconds=60,
    )

    with (
        patch(
            "app.services.apple_identity.urlopen",
            return_value=_FakeResponse({"keys": [jwk]}),
        ),
        pytest.raises(AppleIdentityVerificationError, match="audience"),
    ):
        verifier.verify(token)


def test_verify_rejects_invalid_nonce(rsa_key_pair: tuple[Any, dict[str, Any]]) -> None:
    private_key, jwk = rsa_key_pair
    token = _mint_apple_token(
        private_key,
        kid=jwk["kid"],
        subject="apple-user-1",
        audience="com.kkqin.pickstarpet",
        nonce=hashlib.sha256(b"expected-nonce").hexdigest(),
    )
    verifier = AppleIdentityVerifier(
        client_ids=["com.kkqin.pickstarpet"],
        keys_url="https://example.test/keys",
        timeout_seconds=1,
        keys_cache_seconds=60,
    )

    with (
        patch(
            "app.services.apple_identity.urlopen",
            return_value=_FakeResponse({"keys": [jwk]}),
        ),
        pytest.raises(AppleIdentityVerificationError, match="nonce"),
    ):
        verifier.verify(token, "different-nonce")


def _mint_apple_token(
    private_key: rsa.RSAPrivateKey,
    *,
    kid: str,
    subject: str,
    audience: str,
    email: str | None = None,
    nonce: str | None = None,
) -> str:
    now = datetime.now(UTC)
    claims: dict[str, Any] = {
        "iss": APPLE_ISSUER,
        "sub": subject,
        "aud": audience,
        "iat": int(now.timestamp()),
        "exp": int((now + timedelta(minutes=5)).timestamp()),
        "email_verified": "true",
    }
    if email is not None:
        claims["email"] = email
    if nonce is not None:
        claims["nonce"] = nonce

    pem = private_key.private_bytes(
        encoding=serialization.Encoding.PEM,
        format=serialization.PrivateFormat.PKCS8,
        encryption_algorithm=serialization.NoEncryption(),
    )
    return jwt.encode(claims, pem, algorithm="RS256", headers={"kid": kid})


def _int_to_base64url(value: int) -> str:
    raw = value.to_bytes((value.bit_length() + 7) // 8, byteorder="big")
    return base64.urlsafe_b64encode(raw).rstrip(b"=").decode("ascii")


class _FakeResponse(BytesIO):
    def __init__(self, payload: dict[str, Any]) -> None:
        super().__init__(json.dumps(payload).encode("utf-8"))

    def __enter__(self) -> "_FakeResponse":
        return self

    def __exit__(self, *args: object) -> None:
        self.close()
