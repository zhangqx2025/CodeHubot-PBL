from fastapi import APIRouter, Depends, HTTPException, status, Body
from sqlalchemy.orm import Session
from typing import Optional, Dict, Any
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
    import json
    import logging
    
    logger = logging.getLogger(__name__)
    logger.info(f"获取任务详情 - 任务UUID: {task_uuid}, 用户ID: {current_user.id}")
    
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
        logger.info("未找到进度记录，创建新记录")
        progress = PBLTaskProgress(
            task_id=task.id,
            user_id=current_user.id,
            status='pending',
            progress=0
        )
        db.add(progress)
        db.commit()
        db.refresh(progress)
    else:
        # 刷新对象以确保获取最新数据
        db.refresh(progress)
        logger.info(f"找到进度记录 - ID: {progress.id}, 状态: {progress.status}")
        logger.info(f"提交内容: {json.dumps(progress.submission, ensure_ascii=False) if progress.submission else 'None'}")
    
    # 构造返回数据
    progress_data = {
        'id': progress.id,
        'status': progress.status,
        'progress': progress.progress,
        'submission': progress.submission if progress.submission else None,
        'score': progress.score,
        'feedback': progress.feedback,
        'graded_at': progress.graded_at.isoformat() if progress.graded_at else None,
        'created_at': progress.created_at.isoformat() if progress.created_at else None,
        'updated_at': progress.updated_at.isoformat() if progress.updated_at else None
    }
    
    logger.info(f"返回的progress数据: {json.dumps(progress_data, ensure_ascii=False)}")
    
    result = {
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
        'progress': progress_data
    }
    
    return success_response(data=result)

@router.post("/tasks/{task_uuid}/submit")
def submit_task(
    task_uuid: str,
    submission: Dict[str, Any] = Body(...),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """学生提交任务（支持重复提交）"""
    import json
    import logging
    
    logger = logging.getLogger(__name__)
    logger.info(f"收到提交请求 - 任务UUID: {task_uuid}, 用户ID: {current_user.id}")
    logger.info(f"提交内容: {json.dumps(submission, ensure_ascii=False)}")
    
    task = db.query(PBLTask).filter(PBLTask.uuid == task_uuid).first()
    
    if not task:
        return error_response(
            message="任务不存在",
            code=404,
            status_code=status.HTTP_404_NOT_FOUND
        )
    
    logger.info(f"找到任务 - ID: {task.id}, 标题: {task.title}")
    
    try:
        # 查找或创建任务进度
        progress = db.query(PBLTaskProgress).filter(
            PBLTaskProgress.task_id == task.id,
            PBLTaskProgress.user_id == current_user.id
        ).first()
        
        is_resubmit = False
        if not progress:
            logger.info("创建新的进度记录")
            progress = PBLTaskProgress(
                task_id=task.id,
                user_id=current_user.id,
                status='pending',
                progress=0
            )
            db.add(progress)
            db.flush()  # 先 flush 以获取 ID
        else:
            logger.info(f"找到现有进度记录 - ID: {progress.id}, 状态: {progress.status}")
            # 如果是重新提交，清除原有的评分和反馈
            if progress.status in ['review', 'completed']:
                is_resubmit = True
                progress.score = None
                progress.feedback = None
                progress.graded_by = None
                progress.graded_at = None
        
        # 更新提交内容和状态
        progress.submission = submission
        progress.status = 'review'
        progress.progress = 100
        
        logger.info(f"准备提交到数据库 - 进度ID: {progress.id}, submission: {progress.submission}")
        
        db.commit()
        db.refresh(progress)
        
        logger.info(f"数据库提交成功 - 进度ID: {progress.id}")
        
        # 验证数据是否写入
        verify = db.query(PBLTaskProgress).filter(PBLTaskProgress.id == progress.id).first()
        logger.info(f"验证写入 - submission: {verify.submission}")
        
        message = "作业重新提交成功，等待教师重新评分" if is_resubmit else "任务提交成功，等待教师评分"
        
        return success_response(
            data={
                'id': progress.id,
                'task_id': progress.task_id,
                'status': progress.status,
                'progress': progress.progress,
                'submission': progress.submission,
                'submitted_at': progress.updated_at.isoformat() if progress.updated_at else None,
                'is_resubmit': is_resubmit
            },
            message=message
        )
    except Exception as e:
        db.rollback()
        logger.error(f"提交失败: {str(e)}", exc_info=True)
        return error_response(
            message=f"提交失败: {str(e)}",
            code=500,
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR
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
    """获取我提交的所有任务"""
    from ...models.pbl import PBLUnit, PBLCourse
    
    # 只查询已提交的任务（status为review或completed）
    query = db.query(PBLTaskProgress).filter(
        PBLTaskProgress.user_id == current_user.id,
        PBLTaskProgress.status.in_(['review', 'completed'])
    )
    
    if status_filter:
        query = query.filter(PBLTaskProgress.status == status_filter)
    
    progress_list = query.order_by(PBLTaskProgress.updated_at.desc()).all()
    
    result = []
    for progress in progress_list:
        task = db.query(PBLTask).filter(PBLTask.id == progress.task_id).first()
        if task:
            # 获取单元信息
            unit = db.query(PBLUnit).filter(PBLUnit.id == task.unit_id).first()
            if unit:
                # 获取课程信息
                course = db.query(PBLCourse).filter(PBLCourse.id == unit.course_id).first()
                if course:
                    result.append({
                        'task_id': task.id,
                        'task_uuid': task.uuid,
                        'task_title': task.title,
                        'task_type': task.type,
                        'task_difficulty': task.difficulty,
                        'estimated_time': task.estimated_time,
                        'unit_id': unit.id,
                        'unit_uuid': unit.uuid,
                        'unit_title': unit.title,
                        'course_id': course.id,
                        'course_uuid': course.uuid,
                        'course_title': course.title,
                        'progress_id': progress.id,
                        'status': progress.status,
                        'progress': progress.progress,
                        'score': progress.score,
                        'feedback': progress.feedback,
                        'submitted_at': progress.updated_at.isoformat() if progress.updated_at else None,
                        'graded_at': progress.graded_at.isoformat() if progress.graded_at else None
                    })
    
    return success_response(data=result)
