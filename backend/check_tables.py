from sqlmodel import Session, create_engine, text

from app.core.config import settings

print(f"Database URL: {settings.database_url}")

try:
    engine = create_engine(settings.database_url)
    with Session(engine) as db:
        result = db.exec(
            text("SELECT table_name FROM information_schema.tables WHERE table_schema = 'public'")
        ).all()
        print(f"Found {len(result)} tables:")
        for row in result:
            print(f"  - {row[0]}")
except Exception as e:
    print(f"Error: {e}")
