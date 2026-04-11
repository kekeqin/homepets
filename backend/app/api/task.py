from datetime import UTC, datetime, timedelta

from fastapi import APIRouter, Depends, HTTPException, status
from sqlmodel import Session, select

from app.core.dependencies import get_current_admin, get_current_user, get_db
from app.models.pet import Pet
from app.models.task import Task, TaskCompletion
from app.models.user import User
from app.schemas.task import (
    CompletionResponse,
    CompletionSubmit,
    QuestLogResponse,
    TaskCreate,
    TaskListItemResponse,
    TaskOverviewResponse,
    TaskResponse,
    TaskUpdate,
)
from app.services.pet_service import calculate_level, get_image

router = APIRouter(prefix="/api", tags=["tasks"])


def _as_utc(value: datetime) -> datetime:
    """Normalize SQLite-returned naive datetimes to UTC for safe comparisons."""
    if value.tzinfo is None:
        return value.replace(tzinfo=UTC)
    return value.astimezone(UTC)


def _require_family_access(family_id: int, current_user: User) -> None:
    if current_user.family_id != family_id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="无权查看",
        )


def _family_task_map(db: Session, family_id: int) -> dict[int, Task]:
    return {
        task.id: task
        for task in db.exec(select(Task).where(Task.family_id == family_id)).all()
        if task.id is not None
    }


def _family_member_map(db: Session, family_id: int) -> dict[int, User]:
    return {
        member.id: member
        for member in db.exec(select(User).where(User.family_id == family_id)).all()
        if member.id is not None
    }


def _task_status(*, completed_today: bool) -> str:
    return "completed" if completed_today else "pending"


def _serialize_task(
    task: Task,
    *,
    completed_today_ids: set[int],
    completed_week_counts: dict[int, int],
) -> dict:
    task_id = task.id or 0
    completed_today = task_id in completed_today_ids
    completed_this_week = completed_week_counts.get(task_id, 0) > 0
    return {
        "id": task.id,
        "title": task.title,
        "points": task.points,
        "family_id": task.family_id,
        "is_active": task.is_active,
        "created_at": task.created_at,
        "completed_today": completed_today,
        "completed_this_week": completed_this_week,
        "status": _task_status(completed_today=completed_today),
    }


def _list_family_completion_payload(
    family_id: int,
    db: Session,
    current_user: User,
    *,
    limit: int = 20,
) -> list[dict]:
    _require_family_access(family_id, current_user)

    from sqlalchemy import desc

    task_map = _family_task_map(db, family_id)
    member_map = _family_member_map(db, family_id)
    member_ids = list(member_map.keys())
    if not member_ids or limit <= 0:
        return []

    completions = db.exec(
        select(TaskCompletion)
        .where(TaskCompletion.member_id.in_(member_ids))  # type: ignore[arg-type]
        .order_by(desc(TaskCompletion.created_at))  # type: ignore[arg-type]
        .limit(limit)
    ).all()

    payload = []
    for completion in completions:
        task = task_map.get(completion.task_id)
        if task is not None and task.family_id != family_id:
            continue

        member = member_map.get(completion.member_id)
        payload.append(
            {
                "id": completion.id,
                "task_id": completion.task_id,
                "member_id": completion.member_id,
                "status": completion.status,
                "created_at": completion.created_at,
                "reviewed_at": completion.reviewed_at,
                "task_title": task.title if task else f"已删除任务 #{completion.task_id}",
                "task_points": task.points if task else 0,
                "task_is_active": task.is_active if task else False,
                "member_nickname": member.nickname if member else None,
            }
        )
    return payload


def _serialize_quest_log(item: dict) -> dict:
    return {
        "id": item["id"],
        "task_id": item["task_id"],
        "member_id": item["member_id"],
        "status": item["status"],
        "title": item["task_title"] or f"已删除任务 #{item['task_id']}",
        "points": item["task_points"],
        "is_task_active": item["task_is_active"],
        "completed_at": item["created_at"],
        "member_nickname": item["member_nickname"],
    }


def _build_task_overview(
    family_id: int,
    db: Session,
    current_user: User,
    *,
    recent_completion_limit: int = 10,
) -> dict:
    _require_family_access(family_id, current_user)

    task_map = _family_task_map(db, family_id)
    member_map = _family_member_map(db, family_id)
    member_ids = list(member_map.keys())
    active_tasks = sorted(
        (task for task in task_map.values() if task.is_active),
        key=lambda task: _as_utc(task.created_at),
        reverse=True,
    )

    now = datetime.now(UTC)
    today_start = now.replace(hour=0, minute=0, second=0, microsecond=0)
    week_start = today_start - timedelta(days=today_start.weekday())

    approved_completions: list[TaskCompletion] = []
    if member_ids:
        approved_completions = db.exec(
            select(TaskCompletion).where(
                TaskCompletion.member_id.in_(member_ids),  # type: ignore[arg-type]
                TaskCompletion.status == "approved",
                TaskCompletion.created_at >= week_start,
            )
        ).all()

    completed_today_ids: set[int] = set()
    completed_week_counts: dict[int, int] = {}
    today_completed_count = 0
    week_completed_count = 0
    for completion in approved_completions:
        task = task_map.get(completion.task_id)
        if task is not None and task.family_id != family_id:
            continue

        week_completed_count += 1
        if task is not None:
            completed_week_counts[completion.task_id] = (
                completed_week_counts.get(completion.task_id, 0) + 1
            )

        completion_created_at = _as_utc(completion.created_at)
        if completion_created_at >= today_start:
            today_completed_count += 1
            if task is not None:
                completed_today_ids.add(completion.task_id)

    recent_completions = []
    if recent_completion_limit > 0:
        recent_completions = [
            _serialize_quest_log(item)
            for item in _list_family_completion_payload(
                family_id,
                db,
                current_user,
                limit=recent_completion_limit,
            )
        ]

    return {
        "active_tasks": [
            _serialize_task(
                task,
                completed_today_ids=completed_today_ids,
                completed_week_counts=completed_week_counts,
            )
            for task in active_tasks
        ],
        "today_completed_count": today_completed_count,
        "week_completed_count": week_completed_count,
        "recent_completions": recent_completions,
    }


@router.post("/tasks", response_model=TaskResponse, status_code=status.HTTP_201_CREATED)
def create_task(
    body: TaskCreate,
    db: Session = Depends(get_db),
    admin: User = Depends(get_current_admin),
) -> Task:
    if admin.family_id is None:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="您还没有家庭组",
        )

    task = Task(
        title=body.title,
        points=body.points,
        family_id=admin.family_id,
    )
    db.add(task)
    db.commit()
    db.refresh(task)
    return task


@router.get(
    "/families/{family_id}/tasks/overview",
    response_model=TaskOverviewResponse,
)
def get_task_overview(
    family_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> dict:
    return _build_task_overview(family_id, db, current_user)


@router.get("/families/{family_id}/tasks", response_model=list[TaskListItemResponse])
def list_tasks(
    family_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> list[dict]:
    overview = _build_task_overview(
        family_id,
        db,
        current_user,
        recent_completion_limit=0,
    )
    return overview["active_tasks"]


@router.put("/tasks/{task_id}", response_model=TaskResponse)
def update_task(
    task_id: int,
    body: TaskUpdate,
    db: Session = Depends(get_db),
    admin: User = Depends(get_current_admin),
) -> Task:
    task = db.get(Task, task_id)
    if not task:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="任务不存在",
        )
    if task.family_id != admin.family_id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="无权操作此任务",
        )

    if body.title is not None:
        task.title = body.title
    if body.points is not None:
        task.points = body.points

    db.add(task)
    db.commit()
    db.refresh(task)
    return task


@router.delete("/tasks/{task_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_task(
    task_id: int,
    db: Session = Depends(get_db),
    admin: User = Depends(get_current_admin),
) -> None:
    task = db.get(Task, task_id)
    if not task:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="任务不存在",
        )
    if task.family_id != admin.family_id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="无权操作此任务",
        )

    task.is_active = False
    db.add(task)
    db.commit()


@router.post(
    "/tasks/{task_id}/completions",
    response_model=CompletionResponse,
    status_code=status.HTTP_201_CREATED,
)
def submit_completion(
    task_id: int,
    body: CompletionSubmit | None = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> TaskCompletion:
    task = db.get(Task, task_id)
    if not task or not task.is_active:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="任务不存在",
        )
    if current_user.family_id != task.family_id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="无权提交此任务",
        )

    member_id = current_user.id
    if body and body.member_id:
        target = db.get(User, body.member_id)
        if target and target.family_id == current_user.family_id:
            member_id = body.member_id

    completion = TaskCompletion(
        task_id=task_id,
        member_id=member_id,
        status="approved",
        reviewed_at=datetime.now(UTC),
    )
    db.add(completion)
    db.commit()
    db.refresh(completion)

    pets = db.exec(select(Pet).where(Pet.owner_id == member_id)).all()
    for pet in pets:
        pet.experience = max(0, pet.experience + task.points)
        if pet.pet_form == "pet":
            new_level = calculate_level(pet.experience)
            if new_level != pet.level:
                pet.level = new_level
                pet.image_url = get_image(pet.pet_type, new_level)
        db.add(pet)

    member = db.get(User, member_id)
    if member:
        member.points = max(0, member.points + task.points)
        db.add(member)

    db.commit()
    return completion


@router.get(
    "/families/{family_id}/completions",
    response_model=list[CompletionResponse],
)
def list_completions(
    family_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> list[dict]:
    return _list_family_completion_payload(
        family_id,
        db,
        current_user,
        limit=20,
    )


@router.get(
    "/families/{family_id}/quest-logs",
    response_model=list[QuestLogResponse],
)
def list_quest_logs(
    family_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> list[dict]:
    completion_payload = _list_family_completion_payload(
        family_id,
        db,
        current_user,
        limit=50,
    )
    return [_serialize_quest_log(item) for item in completion_payload]
