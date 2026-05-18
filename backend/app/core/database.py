from collections.abc import Generator

from sqlalchemy import Engine, text
from sqlmodel import Session, SQLModel, create_engine

import app.models  # noqa: F401
from app.core.config import settings

engine_options: dict[str, object] = {}
if settings.database_url.startswith("sqlite"):
    engine_options["connect_args"] = {"check_same_thread": False}

engine = create_engine(settings.database_url, echo=settings.DEBUG, **engine_options)


def create_db_and_tables() -> None:
    SQLModel.metadata.create_all(engine)
    migrate_sqlite_legacy_tables(engine)


def migrate_sqlite_legacy_tables(db_engine: Engine) -> None:
    """Rebuild local SQLite tables when old non-null columns remain."""
    if db_engine.url.get_backend_name() != "sqlite":
        return

    _migrate_sqlite_legacy_task_table(db_engine)
    _migrate_sqlite_legacy_pet_table(db_engine)


def _migrate_sqlite_legacy_task_table(db_engine: Engine) -> None:
    expected_columns = set(SQLModel.metadata.tables["tasks"].columns.keys())
    with db_engine.connect() as connection:
        rows = connection.execute(text("PRAGMA table_info(tasks)")).mappings().all()
        if not rows:
            return

        actual_columns = {str(row["name"]) for row in rows}
        if actual_columns == expected_columns:
            return

        removed_columns = actual_columns - expected_columns
        missing_columns = expected_columns - actual_columns
        legacy_columns = {"description", "task_type", "time_limit_minutes", "icon"}
        if not (removed_columns & legacy_columns or missing_columns):
            return

        connection.exec_driver_sql("PRAGMA foreign_keys=OFF")
        connection.commit()

        with connection.begin():
            connection.exec_driver_sql("DROP TABLE IF EXISTS tasks_schema_migration_new")
            connection.exec_driver_sql(
                """
                CREATE TABLE tasks_schema_migration_new (
                    id INTEGER NOT NULL,
                    title VARCHAR(200) NOT NULL,
                    points INTEGER NOT NULL,
                    family_id INTEGER NOT NULL,
                    is_active BOOLEAN NOT NULL,
                    created_at DATETIME NOT NULL,
                    PRIMARY KEY (id),
                    FOREIGN KEY(family_id) REFERENCES families (id)
                )
                """
            )

            title_expr = _sqlite_column_or_default(actual_columns, "title", "''")
            points_expr = _sqlite_column_or_default(actual_columns, "points", "10")
            family_id_expr = _sqlite_column_or_default(actual_columns, "family_id", "0")
            is_active_expr = _sqlite_column_or_default(actual_columns, "is_active", "1")
            created_at_expr = _sqlite_column_or_default(
                actual_columns,
                "created_at",
                "CURRENT_TIMESTAMP",
            )
            id_expr = "id" if "id" in actual_columns else "NULL"

            connection.exec_driver_sql(
                f"""
                INSERT INTO tasks_schema_migration_new (
                    id,
                    title,
                    points,
                    family_id,
                    is_active,
                    created_at
                )
                SELECT
                    {id_expr},
                    {title_expr},
                    {points_expr},
                    {family_id_expr},
                    {is_active_expr},
                    {created_at_expr}
                FROM tasks
                """
            )
            connection.exec_driver_sql("DROP TABLE tasks")
            connection.exec_driver_sql("ALTER TABLE tasks_schema_migration_new RENAME TO tasks")
            connection.exec_driver_sql(
                "CREATE INDEX IF NOT EXISTS ix_tasks_family_id ON tasks (family_id)"
            )

        connection.exec_driver_sql("PRAGMA foreign_keys=ON")
        connection.commit()


def _sqlite_column_or_default(
    actual_columns: set[str],
    column_name: str,
    default_sql: str,
) -> str:
    if column_name not in actual_columns:
        return default_sql
    return f"COALESCE({column_name}, {default_sql})"


def _migrate_sqlite_legacy_pet_table(db_engine: Engine) -> None:
    expected_columns = set(SQLModel.metadata.tables["pets"].columns.keys())
    with db_engine.connect() as connection:
        rows = connection.execute(text("PRAGMA table_info(pets)")).mappings().all()
        if not rows:
            return

        actual_columns = {str(row["name"]) for row in rows}
        if actual_columns == expected_columns:
            return

        removed_columns = actual_columns - expected_columns
        missing_columns = expected_columns - actual_columns
        legacy_columns = {"pet_form", "image_url"}
        if not (removed_columns & legacy_columns or missing_columns):
            return

        connection.exec_driver_sql("PRAGMA foreign_keys=OFF")
        connection.commit()

        with connection.begin():
            connection.exec_driver_sql("DROP TABLE IF EXISTS pets_schema_migration_new")
            connection.exec_driver_sql(
                """
                CREATE TABLE pets_schema_migration_new (
                    id INTEGER NOT NULL,
                    name VARCHAR(50) NOT NULL,
                    pet_type VARCHAR(50) NOT NULL,
                    level INTEGER NOT NULL,
                    experience INTEGER NOT NULL,
                    owner_id INTEGER NOT NULL,
                    family_id INTEGER NOT NULL,
                    created_at DATETIME NOT NULL,
                    PRIMARY KEY (id),
                    FOREIGN KEY(owner_id) REFERENCES users (id),
                    FOREIGN KEY(family_id) REFERENCES families (id)
                )
                """
            )

            id_expr = "id" if "id" in actual_columns else "NULL"
            name_expr = _sqlite_column_or_default(actual_columns, "name", "'Pet'")
            pet_type_expr = _sqlite_column_or_default(actual_columns, "pet_type", "'cat'")
            level_expr = _sqlite_column_or_default(actual_columns, "level", "1")
            experience_expr = _sqlite_column_or_default(actual_columns, "experience", "0")
            owner_id_expr = _sqlite_column_or_default(actual_columns, "owner_id", "0")
            family_id_expr = _sqlite_column_or_default(actual_columns, "family_id", "0")
            created_at_expr = _sqlite_column_or_default(
                actual_columns,
                "created_at",
                "CURRENT_TIMESTAMP",
            )

            connection.exec_driver_sql(
                f"""
                INSERT INTO pets_schema_migration_new (
                    id,
                    name,
                    pet_type,
                    level,
                    experience,
                    owner_id,
                    family_id,
                    created_at
                )
                SELECT
                    {id_expr},
                    {name_expr},
                    {pet_type_expr},
                    {level_expr},
                    {experience_expr},
                    {owner_id_expr},
                    {family_id_expr},
                    {created_at_expr}
                FROM pets
                """
            )
            connection.exec_driver_sql("DROP TABLE pets")
            connection.exec_driver_sql("ALTER TABLE pets_schema_migration_new RENAME TO pets")
            connection.exec_driver_sql(
                "CREATE INDEX IF NOT EXISTS ix_pets_family_id ON pets (family_id)"
            )
            connection.exec_driver_sql(
                "CREATE INDEX IF NOT EXISTS ix_pets_owner_id ON pets (owner_id)"
            )

        connection.exec_driver_sql("PRAGMA foreign_keys=ON")
        connection.commit()


def get_session() -> Generator[Session, None, None]:
    with Session(engine) as session:
        yield session
