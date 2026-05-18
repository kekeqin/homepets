from datetime import UTC, datetime, timedelta, timezone

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import desc
from sqlmodel import Session, select

from app.core.dependencies import (
    get_current_admin_with_active_access,
    get_current_user_with_active_access,
    get_db,
)
from app.models.pet import Pet
from app.models.task import Task, TaskCompletion
from app.models.user import User
from app.schemas.task import (
    CompletionResponse,
    CompletionSubmit,
    TaskCreate,
    TaskListItemResponse,
    TaskResponse,
    TaskUpdate,
)
from app.services.pet_service import calculate_level

router = APIRouter(prefix="/api", tags=["tasks"])

LOCAL_DAY_ZONE = timezone(timedelta(hours=8), name="Asia/Shanghai")


def _as_utc(value: datetime) -> datetime:
    """将 SQLite 可能返回的 naive datetime 统一为 UTC，避免日期比较出错。"""
    if value.tzinfo is None:
        return value.replace(tzinfo=UTC)
    return value.astimezone(UTC)


def _local_day_start_utc(now: datetime) -> datetime:
    """Return the start of the current app day in UTC."""
    local_now = _as_utc(now).astimezone(LOCAL_DAY_ZONE)
    local_start = local_now.replace(hour=0, minute=0, second=0, microsecond=0)
    return local_start.astimezone(UTC)


def _require_family_access(family_id: int, current_user: User) -> None:
    if current_user.family_id != family_id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="无权查看此家庭")


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
    return {
        "id": task.id,
        "title": task.title,
        "points": task.points,
        "family_id": task.family_id,
        "is_active": task.is_active,
        "created_at": task.created_at,
        "completed_today": completed_today,
        "completed_this_week": completed_week_counts.get(task_id, 0) > 0,
        "status": _task_status(completed_today=completed_today),
    }


def _list_active_tasks(
    family_id: int,
    db: Session,
    current_user: User,
) -> list[dict]:
    _require_family_access(family_id, current_user)

    task_map = _family_task_map(db, family_id)
    member_ids = list(_family_member_map(db, family_id).keys())
    active_tasks = sorted(
        (task for task in task_map.values() if task.is_active),
        key=lambda task: _as_utc(task.created_at),
        reverse=True,
    )

    today_start = _local_day_start_utc(datetime.now(UTC))
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
    for completion in approved_completions:
        task = task_map.get(completion.task_id)
        if task is None or task.family_id != family_id:
            continue

        completed_week_counts[completion.task_id] = (
            completed_week_counts.get(completion.task_id, 0) + 1
        )
        if _as_utc(completion.created_at) >= today_start:
            completed_today_ids.add(completion.task_id)

    return [
        _serialize_task(
            task,
            completed_today_ids=completed_today_ids,
            completed_week_counts=completed_week_counts,
        )
        for task in active_tasks
    ]


def _create_task_for_family(
    *,
    db: Session,
    family_id: int,
    body: TaskCreate,
) -> Task:
    task = Task(title=body.title, points=body.points, family_id=family_id)
    db.add(task)
    db.commit()
    db.refresh(task)
    return task


def _list_family_completion_payload(
    family_id: int,
    db: Session,
    current_user: User,
    *,
    limit: int = 20,
) -> list[dict]:
    _require_family_access(family_id, current_user)

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


# 管理员为家庭创建任务，任务完成后会奖励成员积分并推动宠物成长。
@router.post("/tasks", response_model=TaskResponse, status_code=status.HTTP_201_CREATED)
def create_task(
    body: TaskCreate,
    db: Session = Depends(get_db),
    admin: User = Depends(get_current_admin_with_active_access),
) -> Task:
    if admin.family_id is None:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="您还没有家庭")

    return _create_task_for_family(db=db, family_id=admin.family_id, body=body)


@router.post(
    "/families/{family_id}/tasks",
    response_model=TaskResponse,
    status_code=status.HTTP_201_CREATED,
)
def create_family_task(
    family_id: int,
    body: TaskCreate,
    db: Session = Depends(get_db),
    admin: User = Depends(get_current_admin_with_active_access),
) -> Task:
    if admin.family_id is None:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="您还没有家庭")
    if admin.family_id != family_id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="无权操作此家庭")

    return _create_task_for_family(db=db, family_id=family_id, body=body)


# 列出家庭当前有效任务，并标记今日和本周是否完成过。
@router.get("/families/{family_id}/tasks", response_model=list[TaskListItemResponse])
def list_tasks(
    family_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user_with_active_access),
) -> list[dict]:
    return _list_active_tasks(family_id, db, current_user)


# 管理员修改任务标题或奖励分值。
@router.put("/tasks/{task_id}", response_model=TaskResponse)
def update_task(
    task_id: int,
    body: TaskUpdate,
    db: Session = Depends(get_db),
    admin: User = Depends(get_current_admin_with_active_access),
) -> Task:
    task = db.get(Task, task_id)
    if not task:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="任务不存在")
    if task.family_id != admin.family_id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="无权操作此任务")

    if body.title is not None:
        task.title = body.title
    if body.points is not None:
        task.points = body.points

    db.add(task)
    db.commit()
    db.refresh(task)
    return task


# 管理员删除任务；为保留历史完成记录，这里只做软删除。
@router.delete("/tasks/{task_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_task(
    task_id: int,
    db: Session = Depends(get_db),
    admin: User = Depends(get_current_admin_with_active_access),
) -> None:
    task = db.get(Task, task_id)
    if not task:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="任务不存在")
    if task.family_id != admin.family_id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="无权操作此任务")

    task.is_active = False
    db.add(task)
    db.commit()


# 提交任务完成记录，并立即给成员和名下宠物结算奖励。
@router.post(
    "/tasks/{task_id}/completions",
    response_model=CompletionResponse,
    status_code=status.HTTP_201_CREATED,
)
def submit_completion(
    task_id: int,
    body: CompletionSubmit | None = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user_with_active_access),
) -> TaskCompletion:
    task = db.get(Task, task_id)
    if not task or not task.is_active:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="任务不存在")
    if current_user.family_id != task.family_id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="无权提交此任务")

    member_id = current_user.id
    if body and body.member_id:
        target = db.get(User, body.member_id)
        if not target or target.family_id != current_user.family_id:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="成员不存在")
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
        new_level = calculate_level(pet.experience)
        if new_level != pet.level:
            pet.level = new_level
        db.add(pet)

    member = db.get(User, member_id)
    if member:
        member.points = max(0, member.points + task.points)
        db.add(member)

    db.commit()
    return completion


# 查询家庭近期任务完成动态，用于成员页或家庭动态展示。
@router.get(
    "/families/{family_id}/completions",
    response_model=list[CompletionResponse],
)
def list_completions(
    family_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user_with_active_access),
) -> list[dict]:
    return _list_family_completion_payload(family_id, db, current_user, limit=20)
