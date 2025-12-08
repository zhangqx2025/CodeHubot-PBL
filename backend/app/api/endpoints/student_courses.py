from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List, Optional

from ...core.response import success_response, error_response
from ...core.deps import get_db, get_current_user
from ...models.pbl import PBLCourse, PBLUnit, PBLProject, PBLResource, PBLTask

router = APIRouter()

def serialize_course_list_item(course: PBLCourse) -> dict:
    """序列化课程列表项"""
    # 计算课程进度（简化版，后续可以根据实际学习进度计算）
    units = course.units
    total_units = len(units)
    completed_units = len([u for u in units if u.status == 'completed'])
    progress = int((completed_units / total_units * 100) if total_units > 0 else 0)
    
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
    resources = sorted(unit.resources, key=lambda x: x.order)
    tasks = unit.tasks
    
    return {
        'id': unit.id,
        'uuid': unit.uuid,
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
            'prerequisites': t.prerequisites
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
    """获取我的课程列表"""
    # 目前返回所有已发布的课程，后续可根据用户选课记录筛选
    courses = db.query(PBLCourse).filter(
        PBLCourse.status == 'published'
    ).offset(skip).limit(limit).all()
    
    return success_response(data={
        'total': len(courses),
        'items': [serialize_course_list_item(course) for course in courses]
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
    
    # 检查课程是否已发布（或者用户是否有权限访问）
    if course.status != 'published':
        return error_response(
            message="该课程暂未开放",
            code=403,
            status_code=status.HTTP_403_FORBIDDEN
        )
    
    return success_response(data=serialize_course_detail(course))

@router.get("/units/{unit_id}")
def get_unit_detail(
    unit_id: int,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """获取单元详情（包含学习资料和任务）"""
    unit = db.query(PBLUnit).filter(PBLUnit.id == unit_id).first()
    
    if not unit:
        return error_response(
            message="单元不存在",
            code=404,
            status_code=status.HTTP_404_NOT_FOUND
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
    
    units = sorted(course.units, key=lambda x: x.order)
    return success_response(data=[serialize_unit_summary(unit) for unit in units])

@router.get("/units/{unit_id}/resources")
def get_unit_resources(
    unit_id: int,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """获取单元的学习资料列表"""
    unit = db.query(PBLUnit).filter(PBLUnit.id == unit_id).first()
    
    if not unit:
        return error_response(
            message="单元不存在",
            code=404,
            status_code=status.HTTP_404_NOT_FOUND
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

@router.get("/units/{unit_id}/tasks")
def get_unit_tasks(
    unit_id: int,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """获取单元的任务列表"""
    unit = db.query(PBLUnit).filter(PBLUnit.id == unit_id).first()
    
    if not unit:
        return error_response(
            message="单元不存在",
            code=404,
            status_code=status.HTTP_404_NOT_FOUND
        )
    
    tasks = unit.tasks
    return success_response(data=[{
        'id': t.id,
        'uuid': t.uuid,
        'title': t.title,
        'description': t.description,
        'type': t.type,
        'difficulty': t.difficulty,
        'estimated_time': t.estimated_time,
        'requirements': t.requirements,
        'prerequisites': t.prerequisites
    } for t in tasks])
