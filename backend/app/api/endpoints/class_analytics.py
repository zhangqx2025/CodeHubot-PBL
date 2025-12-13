"""
班级数据分析和可视化API
提供各种统计图表和数据分析功能
"""
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from sqlalchemy import func, and_, or_, case
from typing import List, Optional, Dict
from datetime import datetime, timedelta
from collections import defaultdict

from ...db.session import SessionLocal
from ...core.response import success_response, error_response
from ...core.deps import get_db, get_current_admin
from ...models.admin import Admin, User
from ...models.pbl import (
    PBLClass, PBLClassMember, PBLCourse, PBLUnit, PBLTask,
    PBLTaskProgress, PBLCourseEnrollment, PBLProjectOutput
)
from ...core.logging_config import get_logger

router = APIRouter()
logger = get_logger(__name__)


# ===== 班级整体统计 =====

@router.get("/classes/{class_uuid}/analytics/overview")
def get_class_analytics_overview(
    class_uuid: str,
    db: Session = Depends(get_db),
    current_admin: Admin = Depends(get_current_admin)
):
    """获取班级整体统计概览"""
    pbl_class = db.query(PBLClass).filter(PBLClass.uuid == class_uuid).first()
    if not pbl_class:
        return error_response(
            message="班级不存在",
            code=404,
            status_code=status.HTTP_404_NOT_FOUND
        )
    
    # 权限检查
    if current_admin.role != 'platform_admin':
        if pbl_class.school_id != current_admin.school_id:
            return error_response(
                message="无权限查看该班级",
                code=403,
                status_code=status.HTTP_403_FORBIDDEN
            )
    
    # 获取班级课程
    courses = db.query(PBLCourse).filter(
        PBLCourse.class_id == pbl_class.id,
        PBLCourse.status == 'published'
    ).all()
    
    if not courses:
        return success_response(data={
            'total_students': pbl_class.current_members,
            'total_courses': 0,
            'total_tasks': 0,
            'total_submissions': 0,
            'avg_completion_rate': 0,
            'active_students': 0,
            'inactive_students': 0
        })
    
    course_ids = [c.id for c in courses]
    
    # 统计总任务数
    total_tasks = db.query(func.count(PBLTask.id)).join(
        PBLUnit, PBLTask.unit_id == PBLUnit.id
    ).filter(
        PBLUnit.course_id.in_(course_ids)
    ).scalar() or 0
    
    # 统计总提交数
    total_submissions = db.query(func.count(PBLTaskProgress.id)).join(
        PBLTask, PBLTaskProgress.task_id == PBLTask.id
    ).join(
        PBLUnit, PBLTask.unit_id == PBLUnit.id
    ).filter(
        PBLUnit.course_id.in_(course_ids),
        PBLTaskProgress.submission.isnot(None)
    ).scalar() or 0
    
    # 计算平均完成率
    members = db.query(PBLClassMember).filter(
        PBLClassMember.class_id == pbl_class.id,
        PBLClassMember.is_active == 1
    ).all()
    
    total_completion_rate = 0
    active_students = 0  # 有提交记录的学生
    
    for member in members:
        # 统计学生的任务完成情况
        completed_tasks = db.query(func.count(PBLTaskProgress.id)).join(
            PBLTask, PBLTaskProgress.task_id == PBLTask.id
        ).join(
            PBLUnit, PBLTask.unit_id == PBLUnit.id
        ).filter(
            PBLUnit.course_id.in_(course_ids),
            PBLTaskProgress.user_id == member.student_id,
            PBLTaskProgress.submission.isnot(None)  # 只要提交了就算完成
        ).scalar() or 0
        
        if total_tasks > 0:
            completion_rate = (completed_tasks / total_tasks) * 100
            total_completion_rate += completion_rate
        
        # 检查是否有提交记录
        has_submissions = db.query(func.count(PBLTaskProgress.id)).join(
            PBLTask, PBLTaskProgress.task_id == PBLTask.id
        ).join(
            PBLUnit, PBLTask.unit_id == PBLUnit.id
        ).filter(
            PBLUnit.course_id.in_(course_ids),
            PBLTaskProgress.user_id == member.student_id,
            PBLTaskProgress.submission.isnot(None)
        ).scalar() or 0
        
        if has_submissions > 0:
            active_students += 1
    
    avg_completion_rate = 0
    if len(members) > 0:
        avg_completion_rate = int(total_completion_rate / len(members))
    
    inactive_students = len(members) - active_students
    
    return success_response(data={
        'total_students': len(members),
        'total_courses': len(courses),
        'total_tasks': total_tasks,
        'total_submissions': total_submissions,
        'avg_completion_rate': avg_completion_rate,
        'active_students': active_students,
        'inactive_students': inactive_students
    })


# ===== 学生进度分布 =====

@router.get("/classes/{class_uuid}/analytics/progress-distribution")
def get_progress_distribution(
    class_uuid: str,
    db: Session = Depends(get_db),
    current_admin: Admin = Depends(get_current_admin)
):
    """获取学生进度分布（用于饼图/柱状图）"""
    pbl_class = db.query(PBLClass).filter(PBLClass.uuid == class_uuid).first()
    if not pbl_class:
        return error_response(
            message="班级不存在",
            code=404,
            status_code=status.HTTP_404_NOT_FOUND
        )
    
    # 权限检查
    if current_admin.role != 'platform_admin':
        if pbl_class.school_id != current_admin.school_id:
            return error_response(
                message="无权限查看该班级",
                code=403,
                status_code=status.HTTP_403_FORBIDDEN
            )
    
    # 获取班级课程
    courses = db.query(PBLCourse).filter(
        PBLCourse.class_id == pbl_class.id,
        PBLCourse.status == 'published'
    ).all()
    
    if not courses:
        return success_response(data={
            'ranges': [],
            'counts': []
        })
    
    course_ids = [c.id for c in courses]
    
    # 统计总任务数
    total_tasks = db.query(func.count(PBLTask.id)).join(
        PBLUnit, PBLTask.unit_id == PBLUnit.id
    ).filter(
        PBLUnit.course_id.in_(course_ids)
    ).scalar() or 0
    
    if total_tasks == 0:
        return success_response(data={
            'ranges': ['0%', '1-30%', '31-60%', '61-90%', '91-100%'],
            'counts': [0, 0, 0, 0, 0]
        })
    
    # 获取所有学生
    members = db.query(PBLClassMember).filter(
        PBLClassMember.class_id == pbl_class.id,
        PBLClassMember.is_active == 1
    ).all()
    
    # 进度分布统计
    distribution = {
        '0%': 0,
        '1-30%': 0,
        '31-60%': 0,
        '61-90%': 0,
        '91-100%': 0
    }
    
    for member in members:
        # 统计学生的任务完成情况
        completed_tasks = db.query(func.count(PBLTaskProgress.id)).join(
            PBLTask, PBLTaskProgress.task_id == PBLTask.id
        ).join(
            PBLUnit, PBLTask.unit_id == PBLUnit.id
        ).filter(
            PBLUnit.course_id.in_(course_ids),
            PBLTaskProgress.user_id == member.student_id,
            PBLTaskProgress.submission.isnot(None)  # 只要提交了就算完成
        ).scalar() or 0
        
        completion_rate = (completed_tasks / total_tasks) * 100
        
        if completion_rate == 0:
            distribution['0%'] += 1
        elif completion_rate <= 30:
            distribution['1-30%'] += 1
        elif completion_rate <= 60:
            distribution['31-60%'] += 1
        elif completion_rate <= 90:
            distribution['61-90%'] += 1
        else:
            distribution['91-100%'] += 1
    
    return success_response(data={
        'ranges': list(distribution.keys()),
        'counts': list(distribution.values())
    })


# ===== 任务完成趋势 =====

@router.get("/classes/{class_uuid}/analytics/completion-trend")
def get_completion_trend(
    class_uuid: str,
    days: int = 30,
    db: Session = Depends(get_db),
    current_admin: Admin = Depends(get_current_admin)
):
    """获取任务完成趋势（用于折线图）"""
    pbl_class = db.query(PBLClass).filter(PBLClass.uuid == class_uuid).first()
    if not pbl_class:
        return error_response(
            message="班级不存在",
            code=404,
            status_code=status.HTTP_404_NOT_FOUND
        )
    
    # 权限检查
    if current_admin.role != 'platform_admin':
        if pbl_class.school_id != current_admin.school_id:
            return error_response(
                message="无权限查看该班级",
                code=403,
                status_code=status.HTTP_403_FORBIDDEN
            )
    
    # 获取班级课程
    courses = db.query(PBLCourse).filter(
        PBLCourse.class_id == pbl_class.id,
        PBLCourse.status == 'published'
    ).all()
    
    if not courses:
        return success_response(data={
            'dates': [],
            'submissions': [],
            'completions': []
        })
    
    course_ids = [c.id for c in courses]
    
    # 计算日期范围
    end_date = datetime.now()
    start_date = end_date - timedelta(days=days)
    
    # 按日期统计提交和完成数量
    dates = []
    submissions = []
    completions = []
    
    current_date = start_date
    while current_date <= end_date:
        date_str = current_date.strftime('%Y-%m-%d')
        dates.append(date_str)
        
        # 统计当天的提交数
        daily_submissions = db.query(func.count(PBLTaskProgress.id)).join(
            PBLTask, PBLTaskProgress.task_id == PBLTask.id
        ).join(
            PBLUnit, PBLTask.unit_id == PBLUnit.id
        ).filter(
            PBLUnit.course_id.in_(course_ids),
            PBLTaskProgress.submission.isnot(None),
            func.date(PBLTaskProgress.updated_at) == current_date.date()
        ).scalar() or 0
        
        # 统计当天的完成数
        daily_completions = db.query(func.count(PBLTaskProgress.id)).join(
            PBLTask, PBLTaskProgress.task_id == PBLTask.id
        ).join(
            PBLUnit, PBLTask.unit_id == PBLUnit.id
        ).filter(
            PBLUnit.course_id.in_(course_ids),
            PBLTaskProgress.submission.isnot(None),  # 只要提交了就算完成
            func.date(PBLTaskProgress.updated_at) == current_date.date()
        ).scalar() or 0
        
        submissions.append(daily_submissions)
        completions.append(daily_completions)
        
        current_date += timedelta(days=1)
    
    return success_response(data={
        'dates': dates,
        'submissions': submissions,
        'completions': completions
    })


# ===== 成绩分布 =====

@router.get("/classes/{class_uuid}/analytics/score-distribution")
def get_score_distribution(
    class_uuid: str,
    db: Session = Depends(get_db),
    current_admin: Admin = Depends(get_current_admin)
):
    """获取成绩分布（用于柱状图）"""
    pbl_class = db.query(PBLClass).filter(PBLClass.uuid == class_uuid).first()
    if not pbl_class:
        return error_response(
            message="班级不存在",
            code=404,
            status_code=status.HTTP_404_NOT_FOUND
        )
    
    # 权限检查
    if current_admin.role != 'platform_admin':
        if pbl_class.school_id != current_admin.school_id:
            return error_response(
                message="无权限查看该班级",
                code=403,
                status_code=status.HTTP_403_FORBIDDEN
            )
    
    # 获取班级课程
    courses = db.query(PBLCourse).filter(
        PBLCourse.class_id == pbl_class.id,
        PBLCourse.status == 'published'
    ).all()
    
    if not courses:
        return success_response(data={
            'ranges': [],
            'counts': []
        })
    
    course_ids = [c.id for c in courses]
    
    # 获取所有学生的平均分
    members = db.query(PBLClassMember).filter(
        PBLClassMember.class_id == pbl_class.id,
        PBLClassMember.is_active == 1
    ).all()
    
    # 成绩分布统计
    distribution = {
        '0-59': 0,
        '60-69': 0,
        '70-79': 0,
        '80-89': 0,
        '90-100': 0,
        '未评分': 0
    }
    
    for member in members:
        # 计算学生的平均分
        avg_score = db.query(func.avg(PBLTaskProgress.score)).join(
            PBLTask, PBLTaskProgress.task_id == PBLTask.id
        ).join(
            PBLUnit, PBLTask.unit_id == PBLUnit.id
        ).filter(
            PBLUnit.course_id.in_(course_ids),
            PBLTaskProgress.user_id == member.student_id,
            PBLTaskProgress.score.isnot(None)
        ).scalar()
        
        if avg_score is None:
            distribution['未评分'] += 1
        elif avg_score < 60:
            distribution['0-59'] += 1
        elif avg_score < 70:
            distribution['60-69'] += 1
        elif avg_score < 80:
            distribution['70-79'] += 1
        elif avg_score < 90:
            distribution['80-89'] += 1
        else:
            distribution['90-100'] += 1
    
    return success_response(data={
        'ranges': list(distribution.keys()),
        'counts': list(distribution.values())
    })


# ===== 任务类型统计 =====

@router.get("/classes/{class_uuid}/analytics/task-type-stats")
def get_task_type_stats(
    class_uuid: str,
    db: Session = Depends(get_db),
    current_admin: Admin = Depends(get_current_admin)
):
    """获取任务类型统计（用于饼图）"""
    pbl_class = db.query(PBLClass).filter(PBLClass.uuid == class_uuid).first()
    if not pbl_class:
        return error_response(
            message="班级不存在",
            code=404,
            status_code=status.HTTP_404_NOT_FOUND
        )
    
    # 权限检查
    if current_admin.role != 'platform_admin':
        if pbl_class.school_id != current_admin.school_id:
            return error_response(
                message="无权限查看该班级",
                code=403,
                status_code=status.HTTP_403_FORBIDDEN
            )
    
    # 获取班级课程
    courses = db.query(PBLCourse).filter(
        PBLCourse.class_id == pbl_class.id,
        PBLCourse.status == 'published'
    ).all()
    
    if not courses:
        return success_response(data={
            'types': [],
            'counts': []
        })
    
    course_ids = [c.id for c in courses]
    
    # 统计各类型任务的完成情况
    task_stats = db.query(
        PBLTask.type,
        func.count(PBLTask.id).label('total'),
        func.count(PBLTaskProgress.id).label('completed')
    ).outerjoin(
        PBLTaskProgress,
        and_(
            PBLTaskProgress.task_id == PBLTask.id,
            PBLTaskProgress.submission.isnot(None)  # 只要提交了就算完成
        )
    ).join(
        PBLUnit, PBLTask.unit_id == PBLUnit.id
    ).filter(
        PBLUnit.course_id.in_(course_ids)
    ).group_by(PBLTask.type).all()
    
    types = []
    counts = []
    
    for stat in task_stats:
        task_type = stat.type or 'other'
        types.append(task_type)
        counts.append(stat.total)
    
    return success_response(data={
        'types': types,
        'counts': counts
    })


# ===== 学生活跃度排行 =====

@router.get("/classes/{class_uuid}/analytics/student-activity-ranking")
def get_student_activity_ranking(
    class_uuid: str,
    limit: int = 10,
    db: Session = Depends(get_db),
    current_admin: Admin = Depends(get_current_admin)
):
    """获取学生活跃度排行（用于排行榜）"""
    pbl_class = db.query(PBLClass).filter(PBLClass.uuid == class_uuid).first()
    if not pbl_class:
        return error_response(
            message="班级不存在",
            code=404,
            status_code=status.HTTP_404_NOT_FOUND
        )
    
    # 权限检查
    if current_admin.role != 'platform_admin':
        if pbl_class.school_id != current_admin.school_id:
            return error_response(
                message="无权限查看该班级",
                code=403,
                status_code=status.HTTP_403_FORBIDDEN
            )
    
    # 获取班级课程
    courses = db.query(PBLCourse).filter(
        PBLCourse.class_id == pbl_class.id,
        PBLCourse.status == 'published'
    ).all()
    
    if not courses:
        return success_response(data=[])
    
    course_ids = [c.id for c in courses]
    
    # 获取所有学生
    members = db.query(PBLClassMember, User).join(
        User, PBLClassMember.student_id == User.id
    ).filter(
        PBLClassMember.class_id == pbl_class.id,
        PBLClassMember.is_active == 1
    ).all()
    
    student_activity = []
    
    for member, user in members:
        # 统计提交数
        submission_count = db.query(func.count(PBLTaskProgress.id)).join(
            PBLTask, PBLTaskProgress.task_id == PBLTask.id
        ).join(
            PBLUnit, PBLTask.unit_id == PBLUnit.id
        ).filter(
            PBLUnit.course_id.in_(course_ids),
            PBLTaskProgress.user_id == member.student_id,
            PBLTaskProgress.submission.isnot(None)
        ).scalar() or 0
        
        # 统计完成数
        completion_count = db.query(func.count(PBLTaskProgress.id)).join(
            PBLTask, PBLTaskProgress.task_id == PBLTask.id
        ).join(
            PBLUnit, PBLTask.unit_id == PBLUnit.id
        ).filter(
            PBLUnit.course_id.in_(course_ids),
            PBLTaskProgress.user_id == member.student_id,
            PBLTaskProgress.submission.isnot(None)  # 只要提交了就算完成
        ).scalar() or 0
        
        # 计算平均分
        avg_score = db.query(func.avg(PBLTaskProgress.score)).join(
            PBLTask, PBLTaskProgress.task_id == PBLTask.id
        ).join(
            PBLUnit, PBLTask.unit_id == PBLUnit.id
        ).filter(
            PBLUnit.course_id.in_(course_ids),
            PBLTaskProgress.user_id == member.student_id,
            PBLTaskProgress.score.isnot(None)
        ).scalar() or 0
        
        # 计算活跃度得分（提交数 * 1 + 完成数 * 2 + 平均分 * 0.1）
        activity_score = submission_count + (completion_count * 2) + (avg_score * 0.1)
        
        student_activity.append({
            'student_id': user.id,
            'student_name': user.name or user.real_name,
            'student_number': user.student_number or '',
            'submission_count': submission_count,
            'completion_count': completion_count,
            'avg_score': round(avg_score, 2),
            'activity_score': round(activity_score, 2)
        })
    
    # 按活跃度得分排序
    student_activity.sort(key=lambda x: x['activity_score'], reverse=True)
    
    # 限制返回数量
    return success_response(data=student_activity[:limit])


# ===== 作业提交时间分析 =====

@router.get("/classes/{class_uuid}/analytics/submission-time-analysis")
def get_submission_time_analysis(
    class_uuid: str,
    db: Session = Depends(get_db),
    current_admin: Admin = Depends(get_current_admin)
):
    """获取作业提交时间分析（用于热力图/时间分布图）"""
    pbl_class = db.query(PBLClass).filter(PBLClass.uuid == class_uuid).first()
    if not pbl_class:
        return error_response(
            message="班级不存在",
            code=404,
            status_code=status.HTTP_404_NOT_FOUND
        )
    
    # 权限检查
    if current_admin.role != 'platform_admin':
        if pbl_class.school_id != current_admin.school_id:
            return error_response(
                message="无权限查看该班级",
                code=403,
                status_code=status.HTTP_403_FORBIDDEN
            )
    
    # 获取班级课程
    courses = db.query(PBLCourse).filter(
        PBLCourse.class_id == pbl_class.id,
        PBLCourse.status == 'published'
    ).all()
    
    if not courses:
        return success_response(data={
            'hours': [],
            'counts': []
        })
    
    course_ids = [c.id for c in courses]
    
    # 按小时统计提交分布
    hour_distribution = {str(i): 0 for i in range(24)}
    
    # 获取所有提交记录
    submissions = db.query(PBLTaskProgress).join(
        PBLTask, PBLTaskProgress.task_id == PBLTask.id
    ).join(
        PBLUnit, PBLTask.unit_id == PBLUnit.id
    ).filter(
        PBLUnit.course_id.in_(course_ids),
        PBLTaskProgress.submission.isnot(None)
    ).all()
    
    for submission in submissions:
        if submission.updated_at:
            hour = submission.updated_at.hour
            hour_distribution[str(hour)] += 1
    
    return success_response(data={
        'hours': list(hour_distribution.keys()),
        'counts': list(hour_distribution.values())
    })
