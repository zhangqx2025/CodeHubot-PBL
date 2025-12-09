from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List, Optional

from ...core.response import success_response, error_response
from ...core.deps import get_db, get_current_user
from ...models.pbl import PBLCourse, PBLUnit, PBLProject, PBLResource, PBLTask, PBLCourseEnrollment

router = APIRouter()

def serialize_course_list_item(course: PBLCourse, enrollment: PBLCourseEnrollment = None) -> dict:
    """序列化课程列表项"""
    # 如果有选课记录，使用选课记录中的进度；否则计算进度
    if enrollment:
        progress = enrollment.progress
        enrollment_status = enrollment.enrollment_status
        enrolled_at = enrollment.enrolled_at.isoformat() if enrollment.enrolled_at else None
    else:
        # 计算课程进度（简化版，后续可以根据实际学习进度计算）
        units = course.units
        total_units = len(units)
        completed_units = len([u for u in units if u.status == 'completed'])
        progress = int((completed_units / total_units * 100) if total_units > 0 else 0)
        enrollment_status = None
        enrolled_at = None
    
    units = course.units
    total_units = len(units)
    completed_units = len([u for u in units if u.status == 'completed'])
    
    return {
        'id': course.id,
        'uuid': course.uuid,
        'title': course.title,
        'description': course.description,
        'cover_image': course.cover_image,
        'duration': course.duration,
        'difficulty': course.difficulty,
        'status': course.status,
        'progress': progress,
        'enrollment_status': enrollment_status,
        'enrolled_at': enrolled_at,
        'total_units': total_units,
        'completed_units': completed_units,
        'created_at': course.created_at.isoformat() if course.created_at else None,
        'updated_at': course.updated_at.isoformat() if course.updated_at else None
    }

def serialize_unit_summary(unit: PBLUnit) -> dict:
    """序列化单元摘要信息"""
    resources_count = len(unit.resources)
    tasks_count = len(unit.tasks)
    
    return {
        'id': unit.id,
        'uuid': unit.uuid,
        'title': unit.title,
        'description': unit.description,
        'order': unit.order,
        'status': unit.status,
        'resources_count': resources_count,
        'tasks_count': tasks_count,
        'created_at': unit.created_at.isoformat() if unit.created_at else None
    }

def serialize_course_detail(course: PBLCourse) -> dict:
    """序列化课程详情"""
    units = sorted(course.units, key=lambda x: x.order)
    projects = course.projects
    
    return {
        'id': course.id,
        'uuid': course.uuid,
        'title': course.title,
        'description': course.description,
        'cover_image': course.cover_image,
        'duration': course.duration,
        'difficulty': course.difficulty,
        'status': course.status,
        'units': [serialize_unit_summary(unit) for unit in units],
        'projects': [{
            'id': p.id,
            'uuid': p.uuid,
            'title': p.title,
            'description': p.description,
            'status': p.status,
            'progress': p.progress,
            'repo_url': p.repo_url
        } for p in projects],
        'created_at': course.created_at.isoformat() if course.created_at else None,
        'updated_at': course.updated_at.isoformat() if course.updated_at else None
    }

def serialize_unit_detail(unit: PBLUnit) -> dict:
    """序列化单元详情（包含资料和任务）"""
    # 按 order 字段排序资源
    resources = sorted(unit.resources, key=lambda x: x.order)
    # 按 order 字段排序任务
    tasks = sorted(unit.tasks, key=lambda x: x.order)

    return {
        'id': unit.id,
        'uuid': unit.uuid,
        'course_id': unit.course_id,
        'course_uuid': unit.course.uuid if unit.course else None,
        'course_title': unit.course.title if unit.course else None,
        'title': unit.title,
        'description': unit.description,
        'order': unit.order,
        'status': unit.status,
        'learning_guide': unit.learning_guide,
        'resources': [{
            'id': r.id,
            'uuid': r.uuid,
            'type': r.type,
            'title': r.title,
            'description': r.description,
            'url': r.url,
            'content': r.content,
            'duration': r.duration,
            'order': r.order,
            'video_id': r.video_id,
            'video_cover_url': r.video_cover_url
        } for r in resources],
        'tasks': [{
            'id': t.id,
            'uuid': t.uuid,
            'title': t.title,
            'description': t.description,
            'type': t.type,
            'difficulty': t.difficulty,
            'estimated_time': t.estimated_time,
            'requirements': t.requirements,
            'prerequisites': t.prerequisites,
            'order': t.order  # 添加 order 字段到返回数据
        } for t in tasks],
        'created_at': unit.created_at.isoformat() if unit.created_at else None,
        'updated_at': unit.updated_at.isoformat() if unit.updated_at else None
    }

@router.get("/courses")
def get_my_courses(
    skip: int = 0,
    limit: int = 100,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """获取我的课程列表（仅返回已选课的课程）"""
    # 查询当前用户的选课记录
    enrollments = db.query(PBLCourseEnrollment).filter(
        PBLCourseEnrollment.user_id == current_user.id,
        PBLCourseEnrollment.enrollment_status == 'enrolled'
    ).offset(skip).limit(limit).all()
    
    # 获取对应的课程信息
    result_items = []
    for enrollment in enrollments:
        course = db.query(PBLCourse).filter(
            PBLCourse.id == enrollment.course_id,
            PBLCourse.status == 'published'  # 只返回已发布的课程
        ).first()
        
        if course:
            result_items.append(serialize_course_list_item(course, enrollment))
    
    return success_response(data={
        'total': len(result_items),
        'items': result_items
    })

@router.get("/courses/{course_uuid}")
def get_course_detail(
    course_uuid: str,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """获取课程详情（包含单元列表和项目列表）"""
    course = db.query(PBLCourse).filter(PBLCourse.uuid == course_uuid).first()
    
    if not course:
        return error_response(
            message="课程不存在",
            code=404,
            status_code=status.HTTP_404_NOT_FOUND
        )
    
    # 检查学生是否已选该课程
    enrollment = db.query(PBLCourseEnrollment).filter(
        PBLCourseEnrollment.course_id == course.id,
        PBLCourseEnrollment.user_id == current_user.id,
        PBLCourseEnrollment.enrollment_status == 'enrolled'
    ).first()
    
    if not enrollment:
        return error_response(
            message="您未选修此课程，无权访问",
            code=403,
            status_code=status.HTTP_403_FORBIDDEN
        )
    
    # 检查课程是否已发布
    if course.status != 'published':
        return error_response(
            message="该课程暂未开放",
            code=403,
            status_code=status.HTTP_403_FORBIDDEN
        )
    
    return success_response(data=serialize_course_detail(course))

@router.get("/units/{unit_uuid}")
def get_unit_detail(
    unit_uuid: str,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """获取单元详情（包含学习资料和任务）"""
    unit = db.query(PBLUnit).filter(PBLUnit.uuid == unit_uuid).first()
    
    if not unit:
        return error_response(
            message="单元不存在",
            code=404,
            status_code=status.HTTP_404_NOT_FOUND
        )
    
    # 检查学生是否已选该单元所属的课程
    enrollment = db.query(PBLCourseEnrollment).filter(
        PBLCourseEnrollment.course_id == unit.course_id,
        PBLCourseEnrollment.user_id == current_user.id,
        PBLCourseEnrollment.enrollment_status == 'enrolled'
    ).first()
    
    if not enrollment:
        return error_response(
            message="您未选修此课程，无权访问该单元",
            code=403,
            status_code=status.HTTP_403_FORBIDDEN
        )
    
    # 检查单元是否可访问（简化版，后续可加入解锁逻辑）
    if unit.status == 'locked':
        return error_response(
            message="该单元尚未解锁",
            code=403,
            status_code=status.HTTP_403_FORBIDDEN
        )
    
    return success_response(data=serialize_unit_detail(unit))

@router.get("/courses/{course_uuid}/units")
def get_course_units(
    course_uuid: str,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """获取课程的单元列表"""
    course = db.query(PBLCourse).filter(PBLCourse.uuid == course_uuid).first()
    
    if not course:
        return error_response(
            message="课程不存在",
            code=404,
            status_code=status.HTTP_404_NOT_FOUND
        )
    
    # 检查学生是否已选该课程
    enrollment = db.query(PBLCourseEnrollment).filter(
        PBLCourseEnrollment.course_id == course.id,
        PBLCourseEnrollment.user_id == current_user.id,
        PBLCourseEnrollment.enrollment_status == 'enrolled'
    ).first()
    
    if not enrollment:
        return error_response(
            message="您未选修此课程，无权访问",
            code=403,
            status_code=status.HTTP_403_FORBIDDEN
        )
    
    units = sorted(course.units, key=lambda x: x.order)
    return success_response(data=[serialize_unit_summary(unit) for unit in units])

@router.get("/units/{unit_uuid}/resources")
def get_unit_resources(
    unit_uuid: str,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """获取单元的学习资料列表"""
    unit = db.query(PBLUnit).filter(PBLUnit.uuid == unit_uuid).first()
    
    if not unit:
        return error_response(
            message="单元不存在",
            code=404,
            status_code=status.HTTP_404_NOT_FOUND
        )
    
    # 检查学生是否已选该单元所属的课程
    enrollment = db.query(PBLCourseEnrollment).filter(
        PBLCourseEnrollment.course_id == unit.course_id,
        PBLCourseEnrollment.user_id == current_user.id,
        PBLCourseEnrollment.enrollment_status == 'enrolled'
    ).first()
    
    if not enrollment:
        return error_response(
            message="您未选修此课程，无权访问",
            code=403,
            status_code=status.HTTP_403_FORBIDDEN
        )
    
    resources = sorted(unit.resources, key=lambda x: x.order)
    return success_response(data=[{
        'id': r.id,
        'uuid': r.uuid,
        'type': r.type,
        'title': r.title,
        'description': r.description,
        'url': r.url,
        'content': r.content,
        'duration': r.duration,
        'order': r.order,
        'video_id': r.video_id,
        'video_cover_url': r.video_cover_url
    } for r in resources])

@router.get("/units/{unit_uuid}/tasks")
def get_unit_tasks(
    unit_uuid: str,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """获取单元的任务列表"""
    unit = db.query(PBLUnit).filter(PBLUnit.uuid == unit_uuid).first()
    
    if not unit:
        return error_response(
            message="单元不存在",
            code=404,
            status_code=status.HTTP_404_NOT_FOUND
        )
    
    # 检查学生是否已选该单元所属的课程
    enrollment = db.query(PBLCourseEnrollment).filter(
        PBLCourseEnrollment.course_id == unit.course_id,
        PBLCourseEnrollment.user_id == current_user.id,
        PBLCourseEnrollment.enrollment_status == 'enrolled'
    ).first()
    
    if not enrollment:
        return error_response(
            message="您未选修此课程，无权访问",
            code=403,
            status_code=status.HTTP_403_FORBIDDEN
        )
    
    tasks = sorted(unit.tasks, key=lambda x: x.order)
    return success_response(data=[{
        'id': t.id,
        'uuid': t.uuid,
        'title': t.title,
        'description': t.description,
        'type': t.type,
        'difficulty': t.difficulty,
        'estimated_time': t.estimated_time,
        'requirements': t.requirements,
        'prerequisites': t.prerequisites,
        'order': t.order
    } for t in tasks])
