from collections.abc import Generator

import pytest
from fastapi.testclient import TestClient
from sqlmodel import Session, SQLModel, create_engine
from sqlmodel.pool import StaticPool

from app.api import subscription as subscription_api
from app.api.auth import sms_rate_limiter
from app.core.database import get_session
from app.main import app

# Import all models so SQLModel.metadata knows about all tables
from app.models.family import Family  # noqa: F401
from app.models.pet import Pet  # noqa: F401
from app.models.subscription import Subscription  # noqa: F401
from app.models.task import Task, TaskCompletion  # noqa: F401
from app.models.user import User  # noqa: F401
from app.services.sms_verification import get_sms_verification_client

# Use in-memory SQLite for tests
test_engine = create_engine(
    "sqlite://",
    connect_args={"check_same_thread": False},
    poolclass=StaticPool,
)


def override_get_session() -> Generator[Session, None, None]:
    with Session(test_engine) as session:
        yield session


app.dependency_overrides[get_session] = override_get_session


class FakeSmsVerificationClient:
    def __init__(self) -> None:
        self.sent_phones: list[str] = []

    def send_code(self, phone: str) -> None:
        self.sent_phones.append(phone)

    def check_code(self, phone: str, code: str) -> bool:
        return code == "123456"


@pytest.fixture(autouse=True)
def setup_db() -> Generator[None, None, None]:
    subscription_api.settings.REVENUECAT_WEBHOOK_AUTH = None
    sms_rate_limiter.reset()
    SQLModel.metadata.create_all(test_engine)
    yield
    SQLModel.metadata.drop_all(test_engine)


@pytest.fixture(autouse=True)
def fake_sms_client() -> Generator[FakeSmsVerificationClient, None, None]:
    client = FakeSmsVerificationClient()
    app.dependency_overrides[get_sms_verification_client] = lambda: client
    yield client
    app.dependency_overrides.pop(get_sms_verification_client, None)


@pytest.fixture
def db() -> Generator[Session, None, None]:
    with Session(test_engine) as session:
        yield session


@pytest.fixture
def client() -> Generator[TestClient, None, None]:
    with TestClient(app) as c:
        yield c
