from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List, Optional

from ...db.session import SessionLocal
from ...core.response import success_response, error_response
from ...core.deps import get_db, get_current_admin
from ...models.admin import Admin
from ...models.pbl import PBLTask, PBLUnit, PBLTaskProgress
from ...schemas.pbl import TaskCreate, TaskUpdate, Task

router = APIRouter()

def serialize_task(task: PBLTask) -> dict:
    """将 Task 模型转换为字典"""
    return Task.model_validate(task).model_dump(mode='json')

def serialize_tasks(tasks: List[PBLTask]) -> List[dict]:
    """将 Task 模型列表转换为字典列表"""
    return [serialize_task(task) for task in tasks]

@router.get("/unit/{unit_uuid}")
def get_tasks_by_unit(
    unit_uuid: str,
    db: Session = Depends(get_db),
    current_admin: Admin = Depends(get_current_admin)
):
    """获取学习单元下的所有任务"""
    # 验证单元是否存在
    unit = db.query(PBLUnit).filter(PBLUnit.uuid == unit_uuid).first()
    if not unit:
        return error_response(
            message="学习单元不存在",
            code=404,
            status_code=status.HTTP_404_NOT_FOUND
        )
    
    tasks = db.query(PBLTask).filter(PBLTask.unit_id == unit.id).order_by(PBLTask.order).all()
    return success_response(data=serialize_tasks(tasks))

@router.post("")
def create_task(
    task_data: TaskCreate,
    db: Session = Depends(get_db),
    current_admin: Admin = Depends(get_current_admin)
):
    """创建任务"""
    # 验证单元是否存在
    unit = db.query(PBLUnit).filter(PBLUnit.id == task_data.unit_id).first()
    if not unit:
        return error_response(
            message="学习单元不存在",
            code=404,
            status_code=status.HTTP_404_NOT_FOUND
        )
    
    # 验证任务类型
    if task_data.type not in ['analysis', 'coding', 'design', 'deployment']:
        return error_response(
            message="无效的任务类型",
            code=400,
            status_code=status.HTTP_400_BAD_REQUEST
        )
    
    new_task = PBLTask(
        unit_id=task_data.unit_id,
        title=task_data.title,
        description=task_data.description,
        type=task_data.type,
        difficulty=task_data.difficulty or 'easy',
        estimated_time=task_data.estimated_time,
        order=task_data.order if task_data.order is not None else 0,
        requirements=task_data.requirements,
        prerequisites=task_data.prerequisites
    )
    
    db.add(new_task)
    db.commit()
    db.refresh(new_task)
    
    return success_response(data=serialize_task(new_task), message="任务创建成功")

@router.get("/{task_uuid}")
def get_task(
    task_uuid: str,
    db: Session = Depends(get_db),
    current_admin: Admin = Depends(get_current_admin)
):
    """获取任务详情"""
    task = db.query(PBLTask).filter(PBLTask.uuid == task_uuid).first()
    if not task:
        return error_response(
            message="任务不存在",
            code=404,
            status_code=status.HTTP_404_NOT_FOUND
        )
    
    return success_response(data=serialize_task(task))

@router.put("/{task_uuid}")
def update_task(
    task_uuid: str,
    task_data: TaskUpdate,
    db: Session = Depends(get_db),
    current_admin: Admin = Depends(get_current_admin)
):
    """更新任务"""
    task = db.query(PBLTask).filter(PBLTask.uuid == task_uuid).first()
    if not task:
        return error_response(
            message="任务不存在",
            code=404,
            status_code=status.HTTP_404_NOT_FOUND
        )
    
    # 更新字段
    for field, value in task_data.dict(exclude_unset=True).items():
        setattr(task, field, value)
    
    db.commit()
    db.refresh(task)
    
    return success_response(data=serialize_task(task), message="任务更新成功")

@router.delete("/{task_uuid}")
def delete_task(
    task_uuid: str,
    db: Session = Depends(get_db),
    current_admin: Admin = Depends(get_current_admin)
):
    """删除任务"""
    task = db.query(PBLTask).filter(PBLTask.uuid == task_uuid).first()
    if not task:
        return error_response(
            message="任务不存在",
            code=404,
            status_code=status.HTTP_404_NOT_FOUND
        )
    
    db.delete(task)
    db.commit()
    
    return success_response(message="任务删除成功")

@router.get("/{task_uuid}/progress")
def get_task_progress_list(
    task_uuid: str,
    db: Session = Depends(get_db),
    current_admin: Admin = Depends(get_current_admin)
):
    """获取任务的所有学生进度"""
    task = db.query(PBLTask).filter(PBLTask.uuid == task_uuid).first()
    if not task:
        return error_response(
            message="任务不存在",
            code=404,
            status_code=status.HTTP_404_NOT_FOUND
        )
    
    progress_list = db.query(PBLTaskProgress).filter(
        PBLTaskProgress.task_id == task.id
    ).all()
    
    result = []
    for progress in progress_list:
        user = db.query(Admin).filter(Admin.id == progress.user_id).first()
        result.append({
            'id': progress.id,
            'task_id': progress.task_id,
            'user_id': progress.user_id,
            'user_name': user.full_name if user else 'Unknown',
            'status': progress.status,
            'progress': progress.progress,
            'submission': progress.submission,
            'score': progress.score,
            'feedback': progress.feedback,
            'graded_by': progress.graded_by,
            'graded_at': progress.graded_at.isoformat() if progress.graded_at else None,
            'created_at': progress.created_at.isoformat() if progress.created_at else None,
            'updated_at': progress.updated_at.isoformat() if progress.updated_at else None
        })
    
    return success_response(data=result)

@router.post("/{task_uuid}/grade")
def grade_task(
    task_uuid: str,
    user_id: int,
    score: int,
    feedback: Optional[str] = None,
    db: Session = Depends(get_db),
    current_admin: Admin = Depends(get_current_admin)
):
    """教师评分任务"""
    # 首先查找任务
    task = db.query(PBLTask).filter(PBLTask.uuid == task_uuid).first()
    if not task:
        return error_response(
            message="任务不存在",
            code=404,
            status_code=status.HTTP_404_NOT_FOUND
        )
    
    # 查找任务进度
    progress = db.query(PBLTaskProgress).filter(
        PBLTaskProgress.task_id == task.id,
        PBLTaskProgress.user_id == user_id
    ).first()
    
    if not progress:
        return error_response(
            message="未找到该学生的任务进度",
            code=404,
            status_code=status.HTTP_404_NOT_FOUND
        )
    
    # 更新评分
    progress.score = score
    progress.feedback = feedback
    progress.graded_by = current_admin.id
    from datetime import datetime
    progress.graded_at = get_beijing_time_naive()
    progress.status = 'completed'
    
    db.commit()
    db.refresh(progress)
    
    return success_response(
        data={
            'id': progress.id,
            'task_id': progress.task_id,
            'user_id': progress.user_id,
            'score': progress.score,
            'feedback': progress.feedback,
            'status': progress.status,
            'graded_by': progress.graded_by,
            'graded_at': progress.graded_at.isoformat() if progress.graded_at else None
        },
        message="评分成功"
    )
