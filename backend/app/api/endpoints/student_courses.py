from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List, Optional

from ...core.response import success_response, error_response
from ...core.deps import get_db, get_current_user
from ...models.pbl import PBLCourse, PBLUnit, PBLProject, PBLResource, PBLTask, PBLLearningProgress, PBLClassMember

router = APIRouter()

def serialize_course_list_item(course: PBLCourse, db: Session = None, user_id: int = None) -> dict:
    """序列化课程列表项"""
    units = course.units
    total_units = len(units)
    
    # 计算学生实际完成的单元数（通过学习进度记录）
    completed_units = 0
    if db and user_id:
        # 查询该学生已完成的单元数量
        unit_ids = [unit.id for unit in units]
        if unit_ids:
            completed_count = db.query(PBLLearningProgress).filter(
                PBLLearningProgress.user_id == user_id,
                PBLLearningProgress.unit_id.in_(unit_ids),
                PBLLearningProgress.progress_type == 'unit_complete',
                PBLLearningProgress.status == 'completed'
            ).count()
            completed_units = completed_count
    
    # 计算课程进度
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

def serialize_unit_summary(unit: PBLUnit, db: Session = None, user_id: int = None) -> dict:
    """序列化单元摘要信息"""
    resources_count = len(unit.resources)
    tasks_count = len(unit.tasks)
    
    # 初始化分类统计
    video_count = 0
    document_count = 0
    completed_videos = 0
    completed_documents = 0
    completed_tasks = 0
    
    # 计算单元学习进度
    progress = 0
    if db and user_id:
        # 分类统计资源
        for resource in unit.resources:
            if resource.type == 'video':
                video_count += 1
            elif resource.type == 'document':
                document_count += 1
            
            # 检查资源是否完成
            resource_progress = db.query(PBLLearningProgress).filter(
                PBLLearningProgress.user_id == user_id,
                PBLLearningProgress.unit_id == unit.id,
                PBLLearningProgress.resource_id == resource.id,
                PBLLearningProgress.status == 'completed'
            ).first()
            if resource_progress:
                if resource.type == 'video':
                    completed_videos += 1
                elif resource.type == 'document':
                    completed_documents += 1
        
        # 统计已完成或已提交的任务数量（review状态也算完成）
        for task in unit.tasks:
            task_progress = db.query(PBLLearningProgress).filter(
                PBLLearningProgress.user_id == user_id,
                PBLLearningProgress.unit_id == unit.id,
                PBLLearningProgress.task_id == task.id,
                PBLLearningProgress.status.in_(['completed', 'review'])
            ).first()
            if task_progress:
                completed_tasks += 1
        
        # 计算总进度百分比
        total_items = resources_count + tasks_count
        if total_items > 0:
            completed_items = completed_videos + completed_documents + completed_tasks
            progress = int((completed_items / total_items) * 100)
    else:
        # 如果没有用户信息，只统计数量
        for resource in unit.resources:
            if resource.type == 'video':
                video_count += 1
            elif resource.type == 'document':
                document_count += 1
    
    return {
        'id': unit.id,
        'uuid': unit.uuid,
        'title': unit.title,
        'description': unit.description,
        'order': unit.order,
        'status': unit.status,
        'resources_count': resources_count,
        'tasks_count': tasks_count,
        'progress': progress,
        # 新增详细统计
        'video_count': video_count,
        'document_count': document_count,
        'completed_videos': completed_videos,
        'completed_documents': completed_documents,
        'completed_tasks': completed_tasks,
        'created_at': unit.created_at.isoformat() if unit.created_at else None
    }

def serialize_course_detail(course: PBLCourse, db: Session = None, user_id: int = None) -> dict:
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
        'units': [serialize_unit_summary(unit, db, user_id) for unit in units],
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
    """获取我的课程列表（基于班级成员关系）"""
    # 查询当前用户所在的所有活跃班级
    class_members = db.query(PBLClassMember).filter(
        PBLClassMember.student_id == current_user.id,
        PBLClassMember.is_active == 1
    ).all()
    
    if not class_members:
        return success_response(data={
            'total': 0,
            'items': []
        })
    
    # 获取所有班级ID
    class_ids = [cm.class_id for cm in class_members]
    
    # 查询这些班级的所有已发布课程
    courses = db.query(PBLCourse).filter(
        PBLCourse.class_id.in_(class_ids),
        PBLCourse.status == 'published'
    ).offset(skip).limit(limit).all()
    
    # 序列化课程信息
    result_items = []
    for course in courses:
        result_items.append(serialize_course_list_item(course, db, current_user.id))
    
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
    
    # 检查课程是否已发布
    if course.status != 'published':
        return error_response(
            message="该课程暂未开放",
            code=403,
            status_code=status.HTTP_403_FORBIDDEN
        )
    
    # 检查学生是否是该课程所属班级的成员
    if course.class_id:
        is_member = db.query(PBLClassMember).filter(
            PBLClassMember.class_id == course.class_id,
            PBLClassMember.student_id == current_user.id,
            PBLClassMember.is_active == 1
        ).first()
        
        if not is_member:
            return error_response(
                message="您不是该班级成员，无权访问此课程",
                code=403,
                status_code=status.HTTP_403_FORBIDDEN
            )
    else:
        # 如果课程没有关联班级，则不允许学生访问
        return error_response(
            message="该课程未关联班级，无法访问",
            code=403,
            status_code=status.HTTP_403_FORBIDDEN
        )
    
    return success_response(data=serialize_course_detail(course, db, current_user.id))

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
    
    # 获取单元所属课程
    course = db.query(PBLCourse).filter(PBLCourse.id == unit.course_id).first()
    if not course:
        return error_response(
            message="课程不存在",
            code=404,
            status_code=status.HTTP_404_NOT_FOUND
        )
    
    # 检查学生是否是该课程所属班级的成员
    if course.class_id:
        is_member = db.query(PBLClassMember).filter(
            PBLClassMember.class_id == course.class_id,
            PBLClassMember.student_id == current_user.id,
            PBLClassMember.is_active == 1
        ).first()
        
        if not is_member:
            return error_response(
                message="您不是该班级成员，无权访问该单元",
                code=403,
                status_code=status.HTTP_403_FORBIDDEN
            )
    else:
        return error_response(
            message="该课程未关联班级，无法访问",
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
    
    # 检查学生是否是该课程所属班级的成员
    if course.class_id:
        is_member = db.query(PBLClassMember).filter(
            PBLClassMember.class_id == course.class_id,
            PBLClassMember.student_id == current_user.id,
            PBLClassMember.is_active == 1
        ).first()
        
        if not is_member:
            return error_response(
                message="您不是该班级成员，无权访问此课程",
                code=403,
                status_code=status.HTTP_403_FORBIDDEN
            )
    else:
        return error_response(
            message="该课程未关联班级，无法访问",
            code=403,
            status_code=status.HTTP_403_FORBIDDEN
        )
    
    units = sorted(course.units, key=lambda x: x.order)
    
    # 为每个单元添加用户的完成状态
    units_data = []
    for unit in units:
        unit_data = serialize_unit_summary(unit, db, current_user.id)
        
        # 检查该用户是否完成了该单元
        unit_complete = db.query(PBLLearningProgress).filter(
            PBLLearningProgress.user_id == current_user.id,
            PBLLearningProgress.unit_id == unit.id,
            PBLLearningProgress.progress_type == 'unit_complete',
            PBLLearningProgress.status == 'completed'
        ).first()
        
        # 如果有完成记录，覆盖单元状态
        if unit_complete:
            unit_data['status'] = 'completed'
        
        units_data.append(unit_data)
    
    return success_response(data=units_data)

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
    
    # 获取单元所属课程
    course = db.query(PBLCourse).filter(PBLCourse.id == unit.course_id).first()
    if not course:
        return error_response(
            message="课程不存在",
            code=404,
            status_code=status.HTTP_404_NOT_FOUND
        )
    
    # 检查学生是否是该课程所属班级的成员
    if course.class_id:
        is_member = db.query(PBLClassMember).filter(
            PBLClassMember.class_id == course.class_id,
            PBLClassMember.student_id == current_user.id,
            PBLClassMember.is_active == 1
        ).first()
        
        if not is_member:
            return error_response(
                message="您不是该班级成员，无权访问",
                code=403,
                status_code=status.HTTP_403_FORBIDDEN
            )
    else:
        return error_response(
            message="该课程未关联班级，无法访问",
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
    
    # 获取单元所属课程
    course = db.query(PBLCourse).filter(PBLCourse.id == unit.course_id).first()
    if not course:
        return error_response(
            message="课程不存在",
            code=404,
            status_code=status.HTTP_404_NOT_FOUND
        )
    
    # 检查学生是否是该课程所属班级的成员
    if course.class_id:
        is_member = db.query(PBLClassMember).filter(
            PBLClassMember.class_id == course.class_id,
            PBLClassMember.student_id == current_user.id,
            PBLClassMember.is_active == 1
        ).first()
        
        if not is_member:
            return error_response(
                message="您不是该班级成员，无权访问",
                code=403,
                status_code=status.HTTP_403_FORBIDDEN
            )
    else:
        return error_response(
            message="该课程未关联班级，无法访问",
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
