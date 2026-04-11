from fastapi import APIRouter, Depends, HTTPException, status
from sqlmodel import Session, select

from app.core.dependencies import get_current_user, get_db
from app.models.pet import Pet, PetHistoryEvent
from app.models.user import User
from app.schemas.pet import PetFeed, PetHatch, PetResponse
from app.services.pet_service import (
    EGG_HATCH_EXP,
    VALID_PET_TYPES,
    calculate_level,
    can_hatch,
    create_egg,
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
    name = user.nickname if user else "\u672a\u77e5"
    _user_cache[owner_id] = name
    return name


def _build_pet_response(pet: Pet, db: Session) -> PetResponse:
    if pet.pet_form == "egg":
        threshold = EGG_HATCH_EXP
    else:
        next_lvl = get_next_level_threshold(pet.level)
        threshold = next_lvl if next_lvl else (get_next_level_threshold(pet.level) or 0)

    next_img = None
    if pet.pet_form != "egg":
        nxt = get_next_level_threshold(pet.level)
        if nxt:
            next_img = get_image(pet.pet_type, pet.level + 1)

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
        level_threshold=threshold,
        next_level_image=next_img,
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


def auto_create_egg(db: Session, family_id: int, owner_id: int) -> Pet:
    """Auto-create a pet egg for a user."""
    data = create_egg(family_id, owner_id)
    pet = Pet(**data)
    db.add(pet)
    db.commit()
    db.refresh(pet)
    return pet


@router.get("/families/{family_id}/pets", response_model=list[PetResponse])
def list_pets(
    family_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> list[PetResponse]:
    _user_cache.clear()
    pets = db.exec(select(Pet).where(Pet.family_id == family_id)).all()
    return [_build_pet_response(pet, db) for pet in pets]


@router.get("/pets/{pet_id}", response_model=PetResponse)
def get_pet(
    pet_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> PetResponse:
    pet = db.get(Pet, pet_id)
    if not pet:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="\u5ba0\u7269\u4e0d\u5b58\u5728",
        )
    if current_user.family_id != pet.family_id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="\u65e0\u6743\u67e5\u770b\u6b64\u5ba0\u7269",
        )
    return _build_pet_response(pet, db)


@router.get("/pets/{pet_id}/history")
def get_pet_history(
    pet_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> list[dict]:
    """Get growth history for a pet, including task and feed events."""
    pet = db.get(Pet, pet_id)
    if not pet:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="\u5ba0\u7269\u4e0d\u5b58\u5728",
        )
    if current_user.family_id != pet.family_id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="\u65e0\u6743\u67e5\u770b",
        )

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
    events.sort(key=lambda item: item["created_at"], reverse=True)
    return events[:20]


@router.post("/pets/{pet_id}/hatch", response_model=PetResponse)
def hatch_pet(
    pet_id: int,
    body: PetHatch,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> PetResponse:
    """Hatch an egg into a pet. Owner or family admin can hatch."""
    pet = db.get(Pet, pet_id)
    if not pet:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="\u5ba0\u7269\u4e0d\u5b58\u5728",
        )
    is_owner = pet.owner_id == current_user.id
    is_family_admin = current_user.role == "admin" and current_user.family_id == pet.family_id
    if not is_owner and not is_family_admin:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="\u65e0\u6743\u64cd\u4f5c\u6b64\u5ba0\u7269",
        )
    if pet.pet_form != "egg":
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="\u8be5\u5ba0\u7269\u5df2\u7ecf\u5b75\u5316",
        )
    if not can_hatch(pet.experience):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"\u79ef\u5206\u4e0d\u8db3\uff0c\u9700\u8981 {EGG_HATCH_EXP} \u79ef\u5206\u624d\u80fd\u5b75\u5316",
        )
    if body.pet_type not in VALID_PET_TYPES:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail=(
                "\u4e0d\u652f\u6301\u7684\u5ba0\u7269\u7c7b\u578b\uff0c\u53ef\u9009\uff1a"
                f" {', '.join(sorted(VALID_PET_TYPES))}"
            ),
        )

    pet.pet_form = "pet"
    pet.pet_type = body.pet_type
    pet.name = body.name
    pet.level = 1
    pet.experience = pet.experience - EGG_HATCH_EXP
    pet.image_url = get_image(body.pet_type, 1)
    db.add(pet)
    _record_pet_history(
        db,
        pet=pet,
        event_type="hatch",
        title="\u5b75\u5316\u6210\u529f",
        points=0,
        description=f"\u5b75\u5316\u6210 {body.name}",
    )
    db.commit()
    db.refresh(pet)
    return _build_pet_response(pet, db)


@router.post("/pets/{pet_id}/feed", response_model=PetResponse)
def feed_pet(
    pet_id: int,
    body: PetFeed,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> PetResponse:
    pet = db.get(Pet, pet_id)
    if not pet:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="\u5ba0\u7269\u4e0d\u5b58\u5728",
        )
    if current_user.family_id != pet.family_id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="\u65e0\u6743\u64cd\u4f5c\u6b64\u5ba0\u7269",
        )

    was_egg = pet.pet_form == "egg"
    pet.experience = max(0, pet.experience + body.points)
    if pet.pet_form == "pet":
        new_level = calculate_level(pet.experience)
        if new_level != pet.level:
            pet.level = new_level
            pet.image_url = get_image(pet.pet_type, new_level)

    db.add(pet)
    _record_pet_history(
        db,
        pet=pet,
        event_type="feed",
        title="\u5582\u517b\u8bb0\u5f55",
        points=body.points,
        description=(
            "\u7ed9\u5ba0\u7269\u86cb\u8865\u5145\u80fd\u91cf"
            if was_egg
            else "\u7ed9\u5ba0\u7269\u51c6\u5907\u4e86\u4e00\u987f\u7f8e\u5473"
        ),
    )
    db.commit()
    db.refresh(pet)
    return _build_pet_response(pet, db)
