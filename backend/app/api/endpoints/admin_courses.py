from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session
from typing import List, Optional
import uuid as uuid_lib

from ...db.session import SessionLocal
from ...core.response import success_response, error_response
from ...core.deps import get_db, get_current_admin
from ...models.admin import Admin
from ...models.pbl import PBLCourse, PBLUnit, PBLResource, PBLTask, PBLCourseTemplate
from ...schemas.pbl import CourseBase, Course, CourseTemplate, CourseTemplateCreate, CourseTemplateUpdate

router = APIRouter()

def serialize_course(course: PBLCourse) -> dict:
    """将 Course 模型转换为字典"""
    return Course.model_validate(course).model_dump(mode='json')

def serialize_courses(courses: List[PBLCourse]) -> List[dict]:
    """将 Course 模型列表转换为字典列表"""
    return [serialize_course(course) for course in courses]

@router.get("")
def get_courses(
    skip: int = 0,
    limit: int = 100,
    status: Optional[str] = None,
    db: Session = Depends(get_db),
    current_admin: Admin = Depends(get_current_admin)
):
    """获取课程列表"""
    query = db.query(PBLCourse)
    
    if status:
        query = query.filter(PBLCourse.status == status)
    
    courses = query.offset(skip).limit(limit).all()
    return success_response(data=serialize_courses(courses))

@router.post("")
def create_course(
    course_data: CourseBase,
    db: Session = Depends(get_db),
    current_admin: Admin = Depends(get_current_admin)
):
    """创建课程"""
    new_course = PBLCourse(
        title=course_data.title,
        description=course_data.description,
        cover_image=course_data.cover_image,
        duration=course_data.duration,
        difficulty=course_data.difficulty or 'beginner',
        status='draft',
        creator_id=current_admin.id
    )
    
    db.add(new_course)
    db.commit()
    db.refresh(new_course)
    
    return success_response(data=serialize_course(new_course), message="课程创建成功")

@router.get("/templates")
def get_course_templates(
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    search: Optional[str] = Query(None, description="搜索关键词（标题或编码）"),
    category: Optional[str] = None,
    is_public: Optional[int] = None,
    db: Session = Depends(get_db),
    current_admin: Admin = Depends(get_current_admin)
):
    """获取课程模板列表（支持分页和搜索）"""
    query = db.query(PBLCourseTemplate)
    
    # 搜索
    if search:
        query = query.filter(
            (PBLCourseTemplate.title.like(f'%{search}%')) | 
            (PBLCourseTemplate.template_code.like(f'%{search}%'))
        )
    
    # 筛选
    if category:
        query = query.filter(PBLCourseTemplate.category == category)
    
    if is_public is not None:
        query = query.filter(PBLCourseTemplate.is_public == is_public)
    
    # 总数
    total = query.count()
    
    # 按使用次数和创建时间排序，并分页
    templates = query.order_by(
        PBLCourseTemplate.usage_count.desc(),
        PBLCourseTemplate.created_at.desc()
    ).offset((page - 1) * page_size).limit(page_size).all()
    
    # 序列化模板列表
    templates_data = [CourseTemplate.model_validate(template).model_dump(mode='json') for template in templates]
    
    return success_response(data={
        "items": templates_data,
        "total": total,
        "page": page,
        "page_size": page_size
    })


@router.post("/templates")
def create_course_template(
    template_data: CourseTemplateCreate,
    db: Session = Depends(get_db),
    current_admin: Admin = Depends(get_current_admin)
):
    """创建课程模板（仅平台管理员）"""
    # 检查权限
    if current_admin.role != 'platform_admin':
        raise HTTPException(status_code=403, detail="仅平台管理员可以创建课程模板")
    
    # 检查模板编码是否已存在
    existing = db.query(PBLCourseTemplate).filter(
        PBLCourseTemplate.template_code == template_data.template_code
    ).first()
    if existing:
        return error_response(
            message=f"模板编码 {template_data.template_code} 已存在",
            code=400,
            status_code=status.HTTP_400_BAD_REQUEST
        )
    
    # 创建模板
    new_template = PBLCourseTemplate(
        uuid=str(uuid_lib.uuid4()),
        template_code=template_data.template_code,
        title=template_data.title,
        description=template_data.description,
        cover_image=template_data.cover_image,
        duration=template_data.duration,
        difficulty=template_data.difficulty or 'beginner',
        category=template_data.category,
        version=template_data.version or '1.0.0',
        is_public=template_data.is_public,
        creator_id=current_admin.id,
        usage_count=0
    )
    
    db.add(new_template)
    db.commit()
    db.refresh(new_template)
    
    template_result = CourseTemplate.model_validate(new_template).model_dump(mode='json')
    return success_response(data=template_result, message="课程模板创建成功")


@router.get("/templates/{template_uuid}")
def get_course_template(
    template_uuid: str,
    db: Session = Depends(get_db),
    current_admin: Admin = Depends(get_current_admin)
):
    """获取课程模板详情"""
    template = db.query(PBLCourseTemplate).filter(
        PBLCourseTemplate.uuid == template_uuid
    ).first()
    
    if not template:
        return error_response(
            message="课程模板不存在",
            code=404,
            status_code=status.HTTP_404_NOT_FOUND
        )
    
    template_data = CourseTemplate.model_validate(template).model_dump(mode='json')
    return success_response(data=template_data)


@router.put("/templates/{template_uuid}")
def update_course_template(
    template_uuid: str,
    template_data: CourseTemplateUpdate,
    db: Session = Depends(get_db),
    current_admin: Admin = Depends(get_current_admin)
):
    """更新课程模板（仅平台管理员）"""
    # 检查权限
    if current_admin.role != 'platform_admin':
        raise HTTPException(status_code=403, detail="仅平台管理员可以修改课程模板")
    
    template = db.query(PBLCourseTemplate).filter(
        PBLCourseTemplate.uuid == template_uuid
    ).first()
    
    if not template:
        return error_response(
            message="课程模板不存在",
            code=404,
            status_code=status.HTTP_404_NOT_FOUND
        )
    
    # 如果要修改模板编码，检查是否与其他模板冲突
    if template_data.template_code and template_data.template_code != template.template_code:
        existing = db.query(PBLCourseTemplate).filter(
            PBLCourseTemplate.template_code == template_data.template_code,
            PBLCourseTemplate.id != template.id
        ).first()
        if existing:
            return error_response(
                message=f"模板编码 {template_data.template_code} 已被其他模板使用",
                code=400,
                status_code=status.HTTP_400_BAD_REQUEST
            )
    
    # 更新字段
    update_dict = template_data.dict(exclude_unset=True)
    for field, value in update_dict.items():
        setattr(template, field, value)
    
    db.commit()
    db.refresh(template)
    
    template_result = CourseTemplate.model_validate(template).model_dump(mode='json')
    return success_response(data=template_result, message="课程模板更新成功")


@router.delete("/templates/{template_uuid}")
def delete_course_template(
    template_uuid: str,
    db: Session = Depends(get_db),
    current_admin: Admin = Depends(get_current_admin)
):
    """删除课程模板（仅平台管理员）"""
    # 检查权限
    if current_admin.role != 'platform_admin':
        raise HTTPException(status_code=403, detail="仅平台管理员可以删除课程模板")
    
    template = db.query(PBLCourseTemplate).filter(
        PBLCourseTemplate.uuid == template_uuid
    ).first()
    
    if not template:
        return error_response(
            message="课程模板不存在",
            code=404,
            status_code=status.HTTP_404_NOT_FOUND
        )
    
    # 检查是否有课程在使用此模板
    courses_using_template = db.query(PBLCourse).filter(
        PBLCourse.template_id == template.id
    ).count()
    
    if courses_using_template > 0:
        return error_response(
            message=f"该模板正在被 {courses_using_template} 个课程使用，无法删除",
            code=400,
            status_code=status.HTTP_400_BAD_REQUEST
        )
    
    db.delete(template)
    db.commit()
    
    return success_response(message="课程模板删除成功")

@router.get("/{course_uuid}")
def get_course(
    course_uuid: str,
    db: Session = Depends(get_db),
    current_admin: Admin = Depends(get_current_admin)
):
    """获取课程详情"""
    course = db.query(PBLCourse).filter(PBLCourse.uuid == course_uuid).first()
    if not course:
        return error_response(
            message="课程不存在",
            code=404,
            status_code=status.HTTP_404_NOT_FOUND
        )
    
    return success_response(data=serialize_course(course))

@router.put("/{course_uuid}")
def update_course(
    course_uuid: str,
    course_data: CourseBase,
    db: Session = Depends(get_db),
    current_admin: Admin = Depends(get_current_admin)
):
    """更新课程"""
    course = db.query(PBLCourse).filter(PBLCourse.uuid == course_uuid).first()
    if not course:
        return error_response(
            message="课程不存在",
            code=404,
            status_code=status.HTTP_404_NOT_FOUND
        )
    
    # 更新字段
    for field, value in course_data.dict(exclude_unset=True).items():
        setattr(course, field, value)
    
    db.commit()
    db.refresh(course)
    
    return success_response(data=serialize_course(course), message="课程更新成功")

@router.delete("/{course_uuid}")
def delete_course(
    course_uuid: str,
    db: Session = Depends(get_db),
    current_admin: Admin = Depends(get_current_admin)
):
    """删除课程"""
    course = db.query(PBLCourse).filter(PBLCourse.uuid == course_uuid).first()
    if not course:
        return error_response(
            message="课程不存在",
            code=404,
            status_code=status.HTTP_404_NOT_FOUND
        )
    
    db.delete(course)
    db.commit()
    
    return success_response(message="课程删除成功")

@router.get("/{course_uuid}/full-detail")
def get_course_full_detail(
    course_uuid: str,
    db: Session = Depends(get_db),
    current_admin: Admin = Depends(get_current_admin)
):
    """获取课程完整详情（包括所有单元、资料和任务）"""
    course = db.query(PBLCourse).filter(PBLCourse.uuid == course_uuid).first()
    if not course:
        return error_response(
            message="课程不存在",
            code=404,
            status_code=status.HTTP_404_NOT_FOUND
        )
    
    # 序列化课程基本信息
    course_data = serialize_course(course)
    
    # 获取课程的所有单元（按顺序）
    units = db.query(PBLUnit).filter(PBLUnit.course_id == course.id).order_by(PBLUnit.order).all()
    
    units_data = []
    for unit in units:
        unit_dict = {
            'id': unit.id,
            'uuid': unit.uuid,
            'title': unit.title,
            'description': unit.description,
            'order': unit.order,
            'status': unit.status,
            'created_at': unit.created_at.isoformat() if unit.created_at else None,
            'updated_at': unit.updated_at.isoformat() if unit.updated_at else None
        }
        
        # 获取单元的资料（按顺序）
        resources = db.query(PBLResource).filter(PBLResource.unit_id == unit.id).order_by(PBLResource.order).all()
        unit_dict['resources'] = [
            {
                'id': r.id,
                'uuid': r.uuid,
                'type': r.type,
                'title': r.title,
                'description': r.description,
                'url': r.url,
                'duration': r.duration,
                'order': r.order
            }
            for r in resources
        ]
        
        # 获取单元的任务
        tasks = db.query(PBLTask).filter(PBLTask.unit_id == unit.id).all()
        unit_dict['tasks'] = [
            {
                'id': t.id,
                'uuid': t.uuid,
                'title': t.title,
                'description': t.description,
                'type': t.type,
                'difficulty': t.difficulty,
                'estimated_time': t.estimated_time
            }
            for t in tasks
        ]
        
        units_data.append(unit_dict)
    
    course_data['units'] = units_data
    
    return success_response(data=course_data)

@router.patch("/{course_uuid}/status")
def update_course_status(
    course_uuid: str,
    new_status: str,
    db: Session = Depends(get_db),
    current_admin: Admin = Depends(get_current_admin)
):
    """更新课程状态"""
    if new_status not in ['draft', 'published', 'archived']:
        return error_response(
            message="无效的状态值",
            code=400,
            status_code=status.HTTP_400_BAD_REQUEST
        )
    
    course = db.query(PBLCourse).filter(PBLCourse.uuid == course_uuid).first()
    if not course:
        return error_response(
            message="课程不存在",
            code=404,
            status_code=status.HTTP_404_NOT_FOUND
        )
    
    course.status = new_status
    db.commit()
    db.refresh(course)
    
    return success_response(data=serialize_course(course), message="课程状态更新成功")
