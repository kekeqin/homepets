from collections.abc import AsyncIterator
from contextlib import asynccontextmanager
from pathlib import Path

from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import FileResponse
from fastapi.staticfiles import StaticFiles

from app.api.auth import router as auth_router
from app.api.family import router as family_router
from app.api.pet import router as pet_router
from app.api.subscription import router as subscription_router
from app.api.task import router as task_router
from app.api.user import router as user_router
from app.core.config import settings
from app.core.database import create_db_and_tables


def resolve_website_dir() -> Path | None:
    """Locate the static marketing/legal site directory.

    Resolution order:
    1. ``app/static/website`` (bundled next to the Python package)
    2. ``<package-parent>/website`` (Docker: ``/app/website`` next to ``/app/app``)
    3. monorepo ``website/`` when running from a local checkout
    """
    # main.py lives at <...>/app/main.py
    app_dir = Path(__file__).resolve().parent
    candidates = (
        app_dir / "static" / "website",
        app_dir.parent / "website",  # Docker: /app/website beside /app/app
        app_dir.parents[1] / "website",  # monorepo: <repo>/website beside backend/
    )
    for path in candidates:
        if path.is_dir() and (path / "privacy.html").is_file():
            return path
    return None


WEBSITE_DIR = resolve_website_dir()


@asynccontextmanager
async def lifespan(_app: FastAPI) -> AsyncIterator[None]:
    create_db_and_tables()
    yield


app = FastAPI(
    title=settings.APP_NAME,
    description="家庭宠物养成系统 API",
    version="0.1.0",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth_router)
app.include_router(subscription_router)
app.include_router(family_router)
app.include_router(pet_router)
app.include_router(task_router)
app.include_router(user_router)


@app.get("/health")
def health_check() -> dict[str, str]:
    return {"status": "ok"}


def _website_file(name: str) -> FileResponse:
    if WEBSITE_DIR is None:
        raise HTTPException(status_code=404, detail="Not Found")
    path = (WEBSITE_DIR / name).resolve()
    try:
        path.relative_to(WEBSITE_DIR.resolve())
    except ValueError as exc:
        raise HTTPException(status_code=404, detail="Not Found") from exc
    if not path.is_file():
        raise HTTPException(status_code=404, detail="Not Found")
    media_type = "text/html; charset=utf-8"
    if name.endswith(".css"):
        media_type = "text/css; charset=utf-8"
    return FileResponse(path, media_type=media_type)


@app.get("/")
def site_index() -> FileResponse:
    return _website_file("index.html")


@app.get("/privacy.html")
def privacy_policy() -> FileResponse:
    return _website_file("privacy.html")


@app.get("/terms.html")
def terms_of_service() -> FileResponse:
    return _website_file("terms.html")


@app.get("/support.html")
def support_page() -> FileResponse:
    return _website_file("support.html")


@app.get("/styles.css")
def site_styles() -> FileResponse:
    return _website_file("styles.css")


if WEBSITE_DIR is not None and (WEBSITE_DIR / "assets").is_dir():
    app.mount(
        "/assets",
        StaticFiles(directory=str(WEBSITE_DIR / "assets")),
        name="website-assets",
    )
