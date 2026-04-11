from sqlmodel import Session, create_engine, select

from app.core.config import settings
from app.models.user import User

print(f"Database URL: {settings.database_url}")

try:
    engine = create_engine(settings.database_url)
    with Session(engine) as db:
        users = db.exec(select(User)).all()
        print(f"Found {len(users)} users:")
        for u in users[:10]:
            print(f"  ID: {u.id}, Phone: {u.phone}, Nickname: {u.nickname}, Role: {u.role}")
except Exception as e:
    print(f"Error: {e}")
