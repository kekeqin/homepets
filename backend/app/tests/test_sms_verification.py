from datetime import UTC, datetime, timedelta

from app.services import sms_verification
from app.services.sms_verification import MockSmsVerificationClient


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
