"""Database initialization script. Run with: uv run python -m app.db_init"""

import app.models  # noqa: F401
from app.core.database import create_db_and_tables

if __name__ == "__main__":
    create_db_and_tables()
    print("Database tables created.")
