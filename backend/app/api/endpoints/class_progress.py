from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from sqlalchemy import func
from typing import Optional, List
from datetime import datetime

from ...core.response import success_response, error_response
from ...core.deps import get_db, get_current_admin
from ...models.admin import User, Admin
from ...models.pbl import (
    PBLClass, PBLClassCourse, PBLCourse, PBLUnit, PBLResource, 
    PBLTask, PBLTaskProgress, PBLCourseEnrollment, PBLLearningProgress,
    PBLVideoPlayProgress
)
from ...core.logging_config import get_logger

router = APIRouter()
logger = get_logger(__name__)


@router.get("/classes")
def get_admin_classes(
    db: Session = Depends(get_db),
    current_admin: Admin = Depends(get_current_admin)
):
    """获取管理员可见的班级列表"""
    
    # 构建查询
    query = db.query(PBLClass).filter(PBLClass.is_active == 1)
    
    # 学校管理员只能看到本校的班级
    if current_admin.role in ['school_admin', 'teacher']:
        if not current_admin.school_id:
            return success_response(data=[])
        query = query.filter(PBLClass.school_id == current_admin.school_id)
    
    classes = query.order_by(PBLClass.grade.desc(), PBLClass.name).all()
    
    result = []
    for cls in classes:
        # 获取班级课程
        class_course = db.query(PBLClassCourse).filter(
            PBLClassCourse.class_id == cls.id,
            PBLClassCourse.status == 'active'
        ).first()
        
        # 获取学生数量
        student_count = db.query(User).filter(
            User.class_id == cls.id,
            User.role == 'student',
            User.is_active == 1
        ).count()
        
        course_info = None
        if class_course:
            course = db.query(PBLCourse).filter(PBLCourse.id == class_course.course_id).first()
            if course:
                course_info = {
                    'course_id': course.id,
                    'course_uuid': course.uuid,
                    'course_title': course.title,
                    'cover_image': course.cover_image
                }
        
        result.append({
            'class_id': cls.id,
            'class_uuid': cls.uuid,
            'class_name': cls.name,
            'grade': cls.grade,
            'academic_year': cls.academic_year,
            'student_count': student_count,
            'course': course_info,
            'created_at': cls.created_at.isoformat() if cls.created_at else None
        })
    
    return success_response(data=result)


@router.get("/class/{class_id}/course-progress")
def get_class_course_progress(
    class_id: int,
    db: Session = Depends(get_db),
    current_admin: Admin = Depends(get_current_admin)
):
    """获取班级课程学习进度详情"""
    
    # 检查班级是否存在
    cls = db.query(PBLClass).filter(PBLClass.id == class_id).first()
    if not cls:
        return error_response(
            message="班级不存在",
            code=404,
            status_code=status.HTTP_404_NOT_FOUND
        )
    
    # 权限检查 - 学校管理员只能查看本校班级
    if current_admin.role in ['school_admin', 'teacher']:
        if cls.school_id != current_admin.school_id:
            return error_response(
                message="无权查看该班级",
                code=403,
                status_code=status.HTTP_403_FORBIDDEN
            )
    
    # 获取班级课程
    class_course = db.query(PBLClassCourse).filter(
        PBLClassCourse.class_id == class_id,
        PBLClassCourse.status == 'active'
    ).first()
    
    if not class_course:
        return error_response(
            message="该班级未分配课程",
            code=404,
            status_code=status.HTTP_404_NOT_FOUND
        )
    
    # 获取课程信息
    course = db.query(PBLCourse).filter(PBLCourse.id == class_course.course_id).first()
    if not course:
        return error_response(
            message="课程不存在",
            code=404,
            status_code=status.HTTP_404_NOT_FOUND
        )
    
    # 获取课程单元和任务
    units = db.query(PBLUnit).filter(
        PBLUnit.course_id == course.id
    ).order_by(PBLUnit.order).all()
    
    total_units = len(units)
    
    # 统计总任务数
    total_tasks = db.query(PBLTask).join(
        PBLUnit, PBLUnit.id == PBLTask.unit_id
    ).filter(
        PBLUnit.course_id == course.id
    ).count()
    
    # 统计总资源数
    total_resources = db.query(PBLResource).join(
        PBLUnit, PBLUnit.id == PBLResource.unit_id
    ).filter(
        PBLUnit.course_id == course.id
    ).count()
    
    # 获取班级所有学生
    students = db.query(User).filter(
        User.class_id == class_id,
        User.role == 'student',
        User.is_active == 1
    ).order_by(User.student_number).all()
    
    student_progress_list = []
    
    for student in students:
        # 统计学生完成的任务数
        completed_tasks = db.query(PBLTaskProgress).join(
            PBLTask, PBLTask.id == PBLTaskProgress.task_id
        ).join(
            PBLUnit, PBLUnit.id == PBLTask.unit_id
        ).filter(
            PBLUnit.course_id == course.id,
            PBLTaskProgress.user_id == student.id,
            PBLTaskProgress.status == 'completed'
        ).count()
        
        # 统计学生观看的视频数
        watched_videos = db.query(PBLVideoPlayProgress).join(
            PBLResource, PBLResource.id == PBLVideoPlayProgress.resource_id
        ).join(
            PBLUnit, PBLUnit.id == PBLResource.unit_id
        ).filter(
            PBLUnit.course_id == course.id,
            PBLVideoPlayProgress.user_id == student.id,
            PBLVideoPlayProgress.is_completed == 1
        ).count()
        
        # 统计学生查看的文档数
        read_documents = db.query(PBLLearningProgress).join(
            PBLResource, PBLResource.id == PBLLearningProgress.resource_id
        ).join(
            PBLUnit, PBLUnit.id == PBLResource.unit_id
        ).filter(
            PBLUnit.course_id == course.id,
            PBLLearningProgress.user_id == student.id,
            PBLLearningProgress.progress_type == 'document_read',
            PBLLearningProgress.status == 'completed'
        ).count()
        
        # 计算总体进度
        if total_tasks > 0:
            task_progress = int((completed_tasks / total_tasks) * 100)
        else:
            task_progress = 0
        
        # 获取最后学习时间
        last_learning = db.query(func.max(PBLLearningProgress.updated_at)).filter(
            PBLLearningProgress.user_id == student.id,
            PBLLearningProgress.course_id == course.id
        ).scalar()
        
        # 获取总学习时长（秒）
        total_time_spent = db.query(func.sum(PBLLearningProgress.time_spent)).filter(
            PBLLearningProgress.user_id == student.id,
            PBLLearningProgress.course_id == course.id
        ).scalar() or 0
        
        student_progress_list.append({
            'student_id': student.id,
            'student_number': student.student_number,
            'student_name': student.name or student.real_name,
            'avatar': student.avatar,
            'progress': task_progress,
            'completed_tasks': completed_tasks,
            'total_tasks': total_tasks,
            'watched_videos': watched_videos,
            'read_documents': read_documents,
            'total_time_spent': total_time_spent,  # 秒
            'last_learning_time': last_learning.isoformat() if last_learning else None
        })
    
    # 计算班级整体统计
    total_students = len(students)
    if total_students > 0:
        avg_progress = sum([s['progress'] for s in student_progress_list]) / total_students
        completed_students = len([s for s in student_progress_list if s['progress'] >= 100])
    else:
        avg_progress = 0
        completed_students = 0
    
    return success_response(data={
        'class': {
            'class_id': cls.id,
            'class_uuid': cls.uuid,
            'class_name': cls.name,
            'grade': cls.grade,
            'academic_year': cls.academic_year
        },
        'course': {
            'course_id': course.id,
            'course_uuid': course.uuid,
            'course_title': course.title,
            'description': course.description,
            'cover_image': course.cover_image,
            'difficulty': course.difficulty,
            'total_units': total_units,
            'total_tasks': total_tasks,
            'total_resources': total_resources
        },
        'class_statistics': {
            'total_students': total_students,
            'avg_progress': round(avg_progress, 2),
            'completed_students': completed_students,
            'in_progress_students': total_students - completed_students
        },
        'students': student_progress_list
    })


@router.get("/class/{class_id}/student/{student_id}/detail")
def get_student_progress_detail(
    class_id: int,
    student_id: int,
    db: Session = Depends(get_db),
    current_admin: Admin = Depends(get_current_admin)
):
    """获取学生的详细学习进度"""
    
    # 检查班级是否存在
    cls = db.query(PBLClass).filter(PBLClass.id == class_id).first()
    if not cls:
        return error_response(
            message="班级不存在",
            code=404,
            status_code=status.HTTP_404_NOT_FOUND
        )
    
    # 权限检查
    if current_admin.role in ['school_admin', 'teacher']:
        if cls.school_id != current_admin.school_id:
            return error_response(
                message="无权查看该班级",
                code=403,
                status_code=status.HTTP_403_FORBIDDEN
            )
    
    # 检查学生是否存在且属于该班级
    student = db.query(User).filter(
        User.id == student_id,
        User.class_id == class_id,
        User.role == 'student'
    ).first()
    
    if not student:
        return error_response(
            message="学生不存在或不属于该班级",
            code=404,
            status_code=status.HTTP_404_NOT_FOUND
        )
    
    # 获取班级课程
    class_course = db.query(PBLClassCourse).filter(
        PBLClassCourse.class_id == class_id,
        PBLClassCourse.status == 'active'
    ).first()
    
    if not class_course:
        return error_response(
            message="该班级未分配课程",
            code=404,
            status_code=status.HTTP_404_NOT_FOUND
        )
    
    course = db.query(PBLCourse).filter(PBLCourse.id == class_course.course_id).first()
    if not course:
        return error_response(
            message="课程不存在",
            code=404,
            status_code=status.HTTP_404_NOT_FOUND
        )
    
    # 获取课程单元和进度详情
    units = db.query(PBLUnit).filter(
        PBLUnit.course_id == course.id
    ).order_by(PBLUnit.order).all()
    
    unit_progress_list = []
    
    for unit in units:
        # 获取单元的资源
        resources = db.query(PBLResource).filter(
            PBLResource.unit_id == unit.id
        ).order_by(PBLResource.order).all()
        
        resource_progress = []
        for resource in resources:
            if resource.type == 'video':
                # 查询视频播放进度
                video_progress = db.query(PBLVideoPlayProgress).filter(
                    PBLVideoPlayProgress.resource_id == resource.id,
                    PBLVideoPlayProgress.user_id == student_id
                ).order_by(PBLVideoPlayProgress.updated_at.desc()).first()
                
                if video_progress:
                    resource_progress.append({
                        'resource_id': resource.id,
                        'resource_uuid': resource.uuid,
                        'title': resource.title,
                        'type': resource.type,
                        'completion_rate': float(video_progress.completion_rate),
                        'is_completed': video_progress.is_completed == 1,
                        'watch_duration': video_progress.real_watch_duration,
                        'last_position': video_progress.current_position,
                        'last_learning': video_progress.updated_at.isoformat()
                    })
                else:
                    resource_progress.append({
                        'resource_id': resource.id,
                        'resource_uuid': resource.uuid,
                        'title': resource.title,
                        'type': resource.type,
                        'completion_rate': 0,
                        'is_completed': False,
                        'watch_duration': 0,
                        'last_position': 0,
                        'last_learning': None
                    })
            else:
                # 查询文档阅读进度
                doc_progress = db.query(PBLLearningProgress).filter(
                    PBLLearningProgress.resource_id == resource.id,
                    PBLLearningProgress.user_id == student_id
                ).first()
                
                if doc_progress:
                    resource_progress.append({
                        'resource_id': resource.id,
                        'resource_uuid': resource.uuid,
                        'title': resource.title,
                        'type': resource.type,
                        'is_completed': doc_progress.status == 'completed',
                        'progress_value': doc_progress.progress_value,
                        'last_learning': doc_progress.updated_at.isoformat()
                    })
                else:
                    resource_progress.append({
                        'resource_id': resource.id,
                        'resource_uuid': resource.uuid,
                        'title': resource.title,
                        'type': resource.type,
                        'is_completed': False,
                        'progress_value': 0,
                        'last_learning': None
                    })
        
        # 获取单元的任务
        tasks = db.query(PBLTask).filter(
            PBLTask.unit_id == unit.id
        ).order_by(PBLTask.order).all()
        
        task_progress = []
        for task in tasks:
            # 查询任务进度
            task_prog = db.query(PBLTaskProgress).filter(
                PBLTaskProgress.task_id == task.id,
                PBLTaskProgress.user_id == student_id
            ).first()
            
            if task_prog:
                task_progress.append({
                    'task_id': task.id,
                    'task_uuid': task.uuid,
                    'title': task.title,
                    'type': task.type,
                    'difficulty': task.difficulty,
                    'status': task_prog.status,
                    'progress': task_prog.progress,
                    'score': task_prog.score,
                    'feedback': task_prog.feedback,
                    'updated_at': task_prog.updated_at.isoformat()
                })
            else:
                task_progress.append({
                    'task_id': task.id,
                    'task_uuid': task.uuid,
                    'title': task.title,
                    'type': task.type,
                    'difficulty': task.difficulty,
                    'status': 'pending',
                    'progress': 0,
                    'score': None,
                    'feedback': None,
                    'updated_at': None
                })
        
        # 计算单元完成度
        total_items = len(resources) + len(tasks)
        completed_items = (
            len([r for r in resource_progress if r.get('is_completed', False)]) +
            len([t for t in task_progress if t['status'] == 'completed'])
        )
        
        unit_completion = int((completed_items / total_items * 100)) if total_items > 0 else 0
        
        unit_progress_list.append({
            'unit_id': unit.id,
            'unit_uuid': unit.uuid,
            'title': unit.title,
            'order': unit.order,
            'completion': unit_completion,
            'total_items': total_items,
            'completed_items': completed_items,
            'resources': resource_progress,
            'tasks': task_progress
        })
    
    return success_response(data={
        'student': {
            'student_id': student.id,
            'student_number': student.student_number,
            'student_name': student.name or student.real_name,
            'avatar': student.avatar
        },
        'course': {
            'course_id': course.id,
            'course_uuid': course.uuid,
            'course_title': course.title
        },
        'units': unit_progress_list
    })
