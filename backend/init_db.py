import app.models  # noqa: F401
from app.core.database import create_db_and_tables

print("Creating database tables...")

try:
    create_db_and_tables()
    print("Database tables created successfully!")
except Exception as e:
    print(f"Error creating tables: {e}")
