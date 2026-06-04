import json
from datetime import UTC, datetime, timedelta

from app.services import sms_verification
from app.services.sms_verification import AliyunSmsVerificationClient, MockSmsVerificationClient


def test_mock_sms_verification_prints_and_accepts_generated_code(capsys) -> None:
    client = MockSmsVerificationClient(
        valid_seconds=300,
        now=lambda: datetime(2026, 6, 4, tzinfo=UTC),
        code_factory=lambda: "246810",
    )

    client.send_code("13800000001")

    output = capsys.readouterr().out
    assert "13800000001" in output
    assert "246810" in output
    assert client.check_code("13800000001", "246810") is True
    assert client.check_code("13800000001", "246810") is False


def test_mock_sms_verification_rejects_expired_code() -> None:
    current_time = datetime(2026, 6, 4, tzinfo=UTC)

    def now() -> datetime:
        return current_time

    client = MockSmsVerificationClient(
        valid_seconds=300,
        now=now,
        code_factory=lambda: "135790",
    )
    client.send_code("13800000001")

    current_time += timedelta(seconds=301)

    assert client.check_code("13800000001", "135790") is False


def test_sms_client_factory_uses_mock_when_enabled(monkeypatch) -> None:
    monkeypatch.setattr(sms_verification.settings, "SMS_VERIFICATION_MOCK_ENABLED", True)

    client = sms_verification.get_sms_verification_client()

    assert isinstance(client, MockSmsVerificationClient)


def test_aliyun_template_param_matches_supported_minute_variables() -> None:
    client = AliyunSmsVerificationClient(
        access_key_id="access-key-id",
        access_key_secret="access-key-secret",
        sign_name="HomePets",
        template_code="100001",
        scheme_name="HomePets",
        region_id="cn-hangzhou",
        endpoint="https://example.com/",
        valid_seconds=300,
        timeout_seconds=5,
    )

    params = json.loads(client._template_param())

    assert params == {"code": "##code##", "min": "5", "minute": "5"}


def test_aliyun_send_code_uses_verify_code_parameter_names() -> None:
    client = _CapturingAliyunSmsVerificationClient(
        access_key_id="access-key-id",
        access_key_secret="access-key-secret",
        sign_name="HomePets",
        template_code="100001",
        scheme_name="HomePets",
        region_id="cn-hangzhou",
        endpoint="https://example.com/",
        valid_seconds=300,
        timeout_seconds=5,
    )

    client.send_code("13800000001")

    assert client.action == "SendSmsVerifyCode"
    assert client.business_params is not None
    assert client.business_params["TemplateCode"] == "100001"
    assert "TemplateParam" in client.business_params
    assert "SmsTemplateCode" not in client.business_params
    assert "SmsTemplateParam" not in client.business_params


class _CapturingAliyunSmsVerificationClient(AliyunSmsVerificationClient):
    action: str | None = None
    business_params: dict[str, str] | None = None

    def _request(self, action: str, business_params: dict[str, str]) -> dict:
        self.action = action
        self.business_params = business_params
        return {"Code": "OK"}
