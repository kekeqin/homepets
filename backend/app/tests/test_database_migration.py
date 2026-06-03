from sqlalchemy import text
from sqlmodel import create_engine

from app.core.database import migrate_sqlite_legacy_tables


def test_migrate_sqlite_legacy_tables_drops_removed_task_columns(tmp_path) -> None:
    db_path = tmp_path / "legacy_tasks.db"
    engine = create_engine(f"sqlite:///{db_path}")

    with engine.begin() as connection:
        connection.execute(text("CREATE TABLE families (id INTEGER PRIMARY KEY)"))
        connection.execute(text("INSERT INTO families (id) VALUES (7)"))
        connection.execute(
            text(
                """
                CREATE TABLE tasks (
                    id INTEGER NOT NULL,
                    title VARCHAR(200) NOT NULL,
                    description VARCHAR(1000),
                    points INTEGER NOT NULL,
                    task_type VARCHAR NOT NULL,
                    time_limit_minutes INTEGER,
                    family_id INTEGER NOT NULL,
                    is_active BOOLEAN NOT NULL,
                    created_at DATETIME NOT NULL,
                    icon VARCHAR(64) NOT NULL DEFAULT 'sparkles',
                    PRIMARY KEY (id)
                )
                """
            )
        )
        connection.execute(
            text(
                """
                INSERT INTO tasks (
                    id,
                    title,
                    description,
                    points,
                    task_type,
                    time_limit_minutes,
                    family_id,
                    is_active,
                    created_at,
                    icon
                )
                VALUES (
                    1,
                    'Water plants',
                    'Legacy note',
                    10,
                    'daily',
                    NULL,
                    7,
                    1,
                    '2026-05-18 10:00:00',
                    'sparkles'
                )
                """
            )
        )

    migrate_sqlite_legacy_tables(engine)

    with engine.begin() as connection:
        columns = {row[1] for row in connection.execute(text("PRAGMA table_info(tasks)")).all()}
        assert columns == {"id", "title", "points", "family_id", "is_active", "created_at"}
        row = connection.execute(text("SELECT * FROM tasks WHERE id = 1")).mappings().one()
        assert row["title"] == "Water plants"
        assert row["points"] == 10
        assert row["family_id"] == 7
        assert row["is_active"] == 1

        connection.execute(
            text(
                """
                INSERT INTO tasks (title, points, family_id, is_active, created_at)
                VALUES ('Read book', 20, 7, 1, '2026-05-18 11:00:00')
                """
            )
        )
        created = (
            connection.execute(text("SELECT title, points FROM tasks WHERE title = 'Read book'"))
            .mappings()
            .one()
        )
        assert created["points"] == 20


def test_migrate_sqlite_legacy_tables_drops_removed_pet_columns(tmp_path) -> None:
    db_path = tmp_path / "legacy_pets.db"
    engine = create_engine(f"sqlite:///{db_path}")

    with engine.begin() as connection:
        connection.execute(text("CREATE TABLE families (id INTEGER PRIMARY KEY)"))
        connection.execute(
            text(
                """
                CREATE TABLE users (
                    id INTEGER NOT NULL,
                    nickname VARCHAR(50) NOT NULL,
                    PRIMARY KEY (id)
                )
                """
            )
        )
        connection.execute(text("INSERT INTO families (id) VALUES (7)"))
        connection.execute(text("INSERT INTO users (id, nickname) VALUES (3, 'Ming')"))
        connection.execute(
            text(
                """
                CREATE TABLE pets (
                    id INTEGER NOT NULL,
                    name VARCHAR(50) NOT NULL,
                    pet_type VARCHAR(50) NOT NULL,
                    pet_form VARCHAR NOT NULL,
                    level INTEGER NOT NULL,
                    experience INTEGER NOT NULL,
                    image_url VARCHAR,
                    owner_id INTEGER NOT NULL,
                    family_id INTEGER NOT NULL,
                    created_at DATETIME NOT NULL,
                    PRIMARY KEY (id)
                )
                """
            )
        )
        connection.execute(
            text(
                """
                INSERT INTO pets (
                    id,
                    name,
                    pet_type,
                    pet_form,
                    level,
                    experience,
                    image_url,
                    owner_id,
                    family_id,
                    created_at
                )
                VALUES (
                    1,
                    'Mimi',
                    'cat',
                    'baby',
                    2,
                    30,
                    NULL,
                    3,
                    7,
                    '2026-05-18 10:00:00'
                )
                """
            )
        )

    migrate_sqlite_legacy_tables(engine)

    with engine.begin() as connection:
        columns = {row[1] for row in connection.execute(text("PRAGMA table_info(pets)")).all()}
        assert columns == {
            "id",
            "name",
            "pet_type",
            "level",
            "experience",
            "owner_id",
            "family_id",
            "created_at",
        }
        row = connection.execute(text("SELECT * FROM pets WHERE id = 1")).mappings().one()
        assert row["name"] == "Mimi"
        assert row["pet_type"] == "cat"
        assert row["level"] == 2
        assert row["experience"] == 30
        assert row["owner_id"] == 3
        assert row["family_id"] == 7

        connection.execute(
            text(
                """
                INSERT INTO pets (
                    name,
                    pet_type,
                    level,
                    experience,
                    owner_id,
                    family_id,
                    created_at
                )
                VALUES ('Bunny', 'rabbit', 1, 0, 3, 7, '2026-05-18 11:00:00')
                """
            )
        )
        created = (
            connection.execute(text("SELECT name, pet_type FROM pets WHERE name = 'Bunny'"))
            .mappings()
            .one()
        )
        assert created["pet_type"] == "rabbit"


def test_migrate_sqlite_legacy_tables_drops_removed_user_password_hash(tmp_path) -> None:
    db_path = tmp_path / "legacy_users.db"
    engine = create_engine(f"sqlite:///{db_path}")

    with engine.begin() as connection:
        connection.execute(text("CREATE TABLE families (id INTEGER PRIMARY KEY)"))
        connection.execute(text("INSERT INTO families (id) VALUES (7)"))
        connection.execute(
            text(
                """
                CREATE TABLE users (
                    id INTEGER NOT NULL,
                    phone VARCHAR,
                    password_hash VARCHAR,
                    nickname VARCHAR(50) NOT NULL,
                    role VARCHAR NOT NULL,
                    avatar_url VARCHAR,
                    points INTEGER NOT NULL,
                    family_id INTEGER,
                    created_at DATETIME NOT NULL,
                    PRIMARY KEY (id)
                )
                """
            )
        )
        connection.execute(
            text(
                """
                INSERT INTO users (
                    id,
                    phone,
                    password_hash,
                    nickname,
                    role,
                    avatar_url,
                    points,
                    family_id,
                    created_at
                )
                VALUES (
                    1,
                    '13800000001',
                    'legacy-hash',
                    'Admin',
                    'admin',
                    NULL,
                    8,
                    7,
                    '2026-05-18 10:00:00'
                )
                """
            )
        )

    migrate_sqlite_legacy_tables(engine)

    with engine.begin() as connection:
        columns = {row[1] for row in connection.execute(text("PRAGMA table_info(users)")).all()}
        assert columns == {
            "id",
            "phone",
            "nickname",
            "role",
            "avatar_url",
            "points",
            "family_id",
            "created_at",
        }
        row = connection.execute(text("SELECT * FROM users WHERE id = 1")).mappings().one()
        assert row["phone"] == "13800000001"
        assert row["nickname"] == "Admin"
        assert row["role"] == "admin"
        assert row["points"] == 8
        assert row["family_id"] == 7

        connection.execute(
            text(
                """
                INSERT INTO users (phone, nickname, role, points, created_at)
                VALUES ('13800000002', 'Parent', 'admin', 0, '2026-05-18 11:00:00')
                """
            )
        )
        created = (
            connection.execute(
                text("SELECT phone, nickname FROM users WHERE phone = '13800000002'")
            )
            .mappings()
            .one()
        )
        assert created["nickname"] == "Parent"
