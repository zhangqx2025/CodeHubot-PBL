from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import Optional
from datetime import datetime

from ...core.response import success_response, error_response
from ...core.deps import get_db, get_current_user
from ...models.admin import User
from ...models.pbl import PBLTask, PBLTaskProgress

router = APIRouter()

@router.get("/tasks/{task_uuid}")
def get_task_detail(
    task_uuid: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """获取任务详情"""
    task = db.query(PBLTask).filter(PBLTask.uuid == task_uuid).first()
    
    if not task:
        return error_response(
            message="任务不存在",
            code=404,
            status_code=status.HTTP_404_NOT_FOUND
        )
    
    # 获取当前用户的任务进度
    progress = db.query(PBLTaskProgress).filter(
        PBLTaskProgress.task_id == task.id,
        PBLTaskProgress.user_id == current_user.id
    ).first()
    
    # 如果没有进度记录，创建一个
    if not progress:
        progress = PBLTaskProgress(
            task_id=task.id,
            user_id=current_user.id,
            status='pending',
            progress=0
        )
        db.add(progress)
        db.commit()
        db.refresh(progress)
    
    return success_response(data={
        'id': task.id,
        'uuid': task.uuid,
        'unit_id': task.unit_id,
        'title': task.title,
        'description': task.description,
        'type': task.type,
        'difficulty': task.difficulty,
        'estimated_time': task.estimated_time,
        'requirements': task.requirements,
        'prerequisites': task.prerequisites,
        'progress': {
            'id': progress.id,
            'status': progress.status,
            'progress': progress.progress,
            'submission': progress.submission,
            'score': progress.score,
            'feedback': progress.feedback,
            'graded_at': progress.graded_at.isoformat() if progress.graded_at else None,
            'created_at': progress.created_at.isoformat() if progress.created_at else None,
            'updated_at': progress.updated_at.isoformat() if progress.updated_at else None
        }
    })

@router.post("/tasks/{task_uuid}/submit")
def submit_task(
    task_uuid: str,
    submission: dict,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """学生提交任务"""
    task = db.query(PBLTask).filter(PBLTask.uuid == task_uuid).first()
    
    if not task:
        return error_response(
            message="任务不存在",
            code=404,
            status_code=status.HTTP_404_NOT_FOUND
        )
    
    # 查找或创建任务进度
    progress = db.query(PBLTaskProgress).filter(
        PBLTaskProgress.task_id == task.id,
        PBLTaskProgress.user_id == current_user.id
    ).first()
    
    if not progress:
        progress = PBLTaskProgress(
            task_id=task.id,
            user_id=current_user.id,
            status='pending',
            progress=0
        )
        db.add(progress)
    
    # 更新提交内容和状态
    progress.submission = submission
    progress.status = 'review'
    progress.progress = 100
    
    db.commit()
    db.refresh(progress)
    
    return success_response(
        data={
            'id': progress.id,
            'task_id': progress.task_id,
            'status': progress.status,
            'progress': progress.progress,
            'submission': progress.submission,
            'submitted_at': progress.updated_at.isoformat() if progress.updated_at else None
        },
        message="任务提交成功，等待教师评分"
    )

@router.patch("/tasks/{task_uuid}/progress")
def update_task_progress(
    task_uuid: str,
    progress_value: int,
    task_status: Optional[str] = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """更新任务进度"""
    task = db.query(PBLTask).filter(PBLTask.uuid == task_uuid).first()
    
    if not task:
        return error_response(
            message="任务不存在",
            code=404,
            status_code=status.HTTP_404_NOT_FOUND
        )
    
    # 验证进度值
    if progress_value < 0 or progress_value > 100:
        return error_response(
            message="进度值必须在0-100之间",
            code=400,
            status_code=status.HTTP_400_BAD_REQUEST
        )
    
    # 验证状态值
    if task_status and task_status not in ['pending', 'in-progress', 'blocked', 'review', 'completed']:
        return error_response(
            message="无效的任务状态",
            code=400,
            status_code=status.HTTP_400_BAD_REQUEST
        )
    
    # 查找或创建任务进度
    progress = db.query(PBLTaskProgress).filter(
        PBLTaskProgress.task_id == task.id,
        PBLTaskProgress.user_id == current_user.id
    ).first()
    
    if not progress:
        progress = PBLTaskProgress(
            task_id=task.id,
            user_id=current_user.id,
            status='pending',
            progress=0
        )
        db.add(progress)
    
    # 更新进度
    progress.progress = progress_value
    if task_status:
        progress.status = task_status
    elif progress_value > 0 and progress.status == 'pending':
        progress.status = 'in-progress'
    
    db.commit()
    db.refresh(progress)
    
    return success_response(
        data={
            'id': progress.id,
            'task_id': progress.task_id,
            'status': progress.status,
            'progress': progress.progress,
            'updated_at': progress.updated_at.isoformat() if progress.updated_at else None
        },
        message="任务进度更新成功"
    )

@router.get("/my-tasks")
def get_my_tasks(
    status_filter: Optional[str] = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """获取我的所有任务"""
    query = db.query(PBLTaskProgress).filter(
        PBLTaskProgress.user_id == current_user.id
    )
    
    if status_filter:
        query = query.filter(PBLTaskProgress.status == status_filter)
    
    progress_list = query.all()
    
    result = []
    for progress in progress_list:
        task = db.query(PBLTask).filter(PBLTask.id == progress.task_id).first()
        if task:
            result.append({
                'task_id': task.id,
                'task_uuid': task.uuid,
                'task_title': task.title,
                'task_type': task.type,
                'task_difficulty': task.difficulty,
                'estimated_time': task.estimated_time,
                'progress_id': progress.id,
                'status': progress.status,
                'progress': progress.progress,
                'score': progress.score,
                'feedback': progress.feedback,
                'submitted_at': progress.updated_at.isoformat() if progress.updated_at else None,
                'graded_at': progress.graded_at.isoformat() if progress.graded_at else None
            })
    
    return success_response(data=result)
