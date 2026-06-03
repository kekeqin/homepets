from sqlmodel import SQLModel

from app.models.pet import Pet
from app.models.task import Task
from app.models.user import User


def test_removed_tables_are_not_registered() -> None:
    assert "shop_items" not in SQLModel.metadata.tables
    assert "user_items" not in SQLModel.metadata.tables
    assert "pet_history_events" not in SQLModel.metadata.tables


def test_removed_pet_columns_are_not_registered() -> None:
    pet_columns = set(Pet.__table__.columns.keys())
    assert "pet_form" not in pet_columns
    assert "image_url" not in pet_columns


def test_removed_task_columns_are_not_registered() -> None:
    task_columns = set(Task.__table__.columns.keys())
    assert "description" not in task_columns
    assert "task_type" not in task_columns
    assert "time_limit_minutes" not in task_columns
    assert "icon" not in task_columns


def test_removed_user_columns_are_not_registered() -> None:
    user_columns = set(User.__table__.columns.keys())
    assert "password_hash" not in user_columns
