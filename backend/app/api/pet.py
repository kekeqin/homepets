from fastapi import APIRouter, Depends, HTTPException, status
from sqlmodel import Session, select

from app.core.dependencies import get_current_user, get_db
from app.models.pet import Pet, PetHistoryEvent
from app.models.user import User
from app.schemas.pet import PetFeed, PetResponse
from app.services.pet_service import (
    calculate_level,
    get_emoji,
    get_image,
    get_next_level_threshold,
)

router = APIRouter(prefix="/api", tags=["pets"])

_user_cache: dict[int, str] = {}


def _get_owner_nickname(db: Session, owner_id: int) -> str:
    if owner_id in _user_cache:
        return _user_cache[owner_id]
    user = db.get(User, owner_id)
    name = user.nickname if user else "未知"
    _user_cache[owner_id] = name
    return name


def _build_pet_response(pet: Pet, db: Session) -> PetResponse:
    next_threshold = get_next_level_threshold(pet.level)
    next_image = get_image(pet.pet_type, pet.level + 1) if next_threshold else None
    return PetResponse(
        id=pet.id,  # type: ignore[arg-type]
        name=pet.name,
        pet_type=pet.pet_type,
        pet_form=pet.pet_form,
        level=pet.level,
        experience=pet.experience,
        image_url=pet.image_url,
        owner_id=pet.owner_id,
        owner_nickname=_get_owner_nickname(db, pet.owner_id),
        family_id=pet.family_id,
        created_at=pet.created_at,
        level_threshold=next_threshold or 0,
        next_level_image=next_image,
        emoji=get_emoji(pet.pet_type),
    )


def _record_pet_history(
    db: Session,
    *,
    pet: Pet,
    event_type: str,
    title: str,
    points: int,
    description: str | None = None,
) -> None:
    db.add(
        PetHistoryEvent(
            pet_id=pet.id,  # type: ignore[arg-type]
            owner_id=pet.owner_id,
            family_id=pet.family_id,
            event_type=event_type,
            title=title,
            description=description,
            points=points,
        )
    )


@router.get("/families/{family_id}/pets", response_model=list[PetResponse])
def list_pets(
    family_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> list[PetResponse]:
    if current_user.family_id != family_id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="无权查看此宠物列表")
    _user_cache.clear()
    pets = db.exec(select(Pet).where(Pet.family_id == family_id).where(Pet.pet_form == "pet")).all()
    return [_build_pet_response(pet, db) for pet in pets]


@router.get("/pets/{pet_id}", response_model=PetResponse)
def get_pet(
    pet_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> PetResponse:
    pet = db.get(Pet, pet_id)
    if not pet or pet.pet_form != "pet":
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="宠物不存在")
    if current_user.family_id != pet.family_id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="无权查看此宠物")
    return _build_pet_response(pet, db)


@router.get("/pets/{pet_id}/history")
def get_pet_history(
    pet_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> list[dict[str, str | int | None]]:
    pet = db.get(Pet, pet_id)
    if not pet or pet.pet_form != "pet":
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="宠物不存在")
    if current_user.family_id != pet.family_id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="无权查看")

    from app.models.task import Task, TaskCompletion

    task_events = [
        {
            "task_title": task.title,
            "points": task.points,
            "created_at": comp.created_at.isoformat(),
            "event_type": "task",
            "description": None,
        }
        for comp, task in db.exec(
            select(TaskCompletion, Task)
            .join(Task, TaskCompletion.task_id == Task.id)
            .where(TaskCompletion.member_id == pet.owner_id)
            .where(TaskCompletion.status == "approved")
            .order_by(TaskCompletion.created_at.desc())
            .limit(20)
        ).all()
    ]

    pet_events = [
        {
            "task_title": event.title,
            "points": event.points,
            "created_at": event.created_at.isoformat(),
            "event_type": event.event_type,
            "description": event.description,
        }
        for event in db.exec(
            select(PetHistoryEvent)
            .where(PetHistoryEvent.pet_id == pet_id)
            .order_by(PetHistoryEvent.created_at.desc())
            .limit(20)
        ).all()
    ]

    events = [*task_events, *pet_events]
    events.sort(key=lambda item: str(item["created_at"]), reverse=True)
    return events[:20]


@router.post("/pets/{pet_id}/feed", response_model=PetResponse)
def feed_pet(
    pet_id: int,
    body: PetFeed,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> PetResponse:
    pet = db.get(Pet, pet_id)
    if not pet or pet.pet_form != "pet":
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="宠物不存在")
    if current_user.family_id != pet.family_id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="无权操作此宠物")

    pet.experience = max(0, pet.experience + body.points)
    new_level = calculate_level(pet.experience)
    if new_level != pet.level:
        pet.level = new_level
        pet.image_url = get_image(pet.pet_type, new_level)

    db.add(pet)
    _record_pet_history(
        db,
        pet=pet,
        event_type="feed",
        title="喂养记录",
        points=body.points,
        description="给宠物准备了一顿美味",
    )
    db.commit()
    db.refresh(pet)
    return _build_pet_response(pet, db)
