"""
课程模板服务
提供从模板创建课程实例的功能
"""
from sqlalchemy.orm import Session
import uuid as uuid_lib
from typing import Optional, Tuple
from ..models.pbl import (
    PBLCourse, PBLCourseTemplate,
    PBLUnit, PBLUnitTemplate,
    PBLResource, PBLResourceTemplate,
    PBLTask, PBLTaskTemplate,
    PBLTemplateSchoolPermission
)
from ..utils.timezone import get_beijing_time_naive
from ..core.logging_config import get_logger

logger = get_logger(__name__)


def copy_course_from_template(
    db: Session,
    template_id: int,
    school_id: int,
    creator_id: int,
    class_id: Optional[int] = None,
    class_name: Optional[str] = None,
    permission_id: Optional[int] = None
) -> PBLCourse:
    """
    从模板创建完整的课程实例（包括单元、资源、任务）
    
    Args:
        db: 数据库会话
        template_id: 模板ID
        school_id: 学校ID
        creator_id: 创建者ID
        class_id: 班级ID（可选）
        class_name: 班级名称（可选）
        permission_id: 权限ID（可选）
    
    Returns:
        创建的课程对象
    """
    # 查询模板
    template = db.query(PBLCourseTemplate).filter(
        PBLCourseTemplate.id == template_id
    ).first()
    
    if not template:
        raise ValueError(f"模板不存在: {template_id}")
    
    # 创建课程实例
    new_course = PBLCourse(
        uuid=str(uuid_lib.uuid4()),
        template_id=template.id,
        template_version=template.version,
        permission_id=permission_id,
        title=template.title,
        description=template.description,
        cover_image=template.cover_image,
        duration=template.duration,
        difficulty=template.difficulty,
        status='published',
        creator_id=creator_id,
        school_id=school_id,
        class_id=class_id,
        class_name=class_name,
        is_customized=0,
        sync_with_template=1
    )
    db.add(new_course)
    db.flush()
    
    logger.info(f"创建课程实例 - 模板ID: {template_id}, 课程ID: {new_course.id}, 标题: {new_course.title}")
    
    # 复制单元模板
    unit_templates = db.query(PBLUnitTemplate).filter(
        PBLUnitTemplate.course_template_id == template_id
    ).order_by(PBLUnitTemplate.order).all()
    
    # 用于映射模板ID到实例ID
    unit_template_map = {}
    
    for unit_template in unit_templates:
        new_unit = PBLUnit(
            uuid=str(uuid_lib.uuid4()),
            course_id=new_course.id,
            title=unit_template.title,
            description=unit_template.description,
            order=unit_template.order,
            status='locked',  # 默认锁定状态
            learning_guide=unit_template.learning_objectives
        )
        db.add(new_unit)
        db.flush()
        
        unit_template_map[unit_template.id] = new_unit.id
        
        logger.info(f"  复制单元 - 模板ID: {unit_template.id}, 单元ID: {new_unit.id}, 标题: {new_unit.title}")
        
        # 复制资源模板
        resource_templates = db.query(PBLResourceTemplate).filter(
            PBLResourceTemplate.unit_template_id == unit_template.id
        ).order_by(PBLResourceTemplate.order).all()
        
        for resource_template in resource_templates:
            new_resource = PBLResource(
                uuid=str(uuid_lib.uuid4()),
                unit_id=new_unit.id,
                type=resource_template.type,
                title=resource_template.title,
                description=resource_template.description,
                url=resource_template.url,
                content=resource_template.content,
                duration=resource_template.duration,
                order=resource_template.order,
                video_id=resource_template.video_id,
                video_cover_url=resource_template.video_cover_url,
                max_views=resource_template.default_max_views
            )
            db.add(new_resource)
            
            logger.info(f"    复制资源 - 类型: {resource_template.type}, 标题: {resource_template.title}")
        
        # 复制任务模板
        task_templates = db.query(PBLTaskTemplate).filter(
            PBLTaskTemplate.unit_template_id == unit_template.id
        ).order_by(PBLTaskTemplate.order).all()
        
        for task_template in task_templates:
            new_task = PBLTask(
                uuid=str(uuid_lib.uuid4()),
                unit_id=new_unit.id,
                title=task_template.title,
                description=task_template.description,
                type=task_template.type,
                difficulty=task_template.difficulty,
                estimated_time=task_template.estimated_time,
                order=task_template.order,
                requirements=task_template.requirements,
                prerequisites=task_template.prerequisites,
                publish_status='published'  # 默认发布状态
            )
            db.add(new_task)
            
            logger.info(f"    复制任务 - 类型: {task_template.type}, 标题: {task_template.title}")
    
    db.flush()
    
    logger.info(f"完成课程实例创建 - 课程ID: {new_course.id}, 单元数: {len(unit_templates)}")
    
    return new_course


def validate_template_permission(
    db: Session,
    template_id: int,
    school_id: int
) -> Tuple[PBLCourseTemplate, PBLTemplateSchoolPermission]:
    """
    验证学校是否有权使用该模板
    
    Args:
        db: 数据库会话
        template_id: 模板ID
        school_id: 学校ID
    
    Returns:
        (模板对象, 权限对象)
    
    Raises:
        ValueError: 如果模板不存在或学校无权限
    """
    from sqlalchemy import or_
    
    # 查询模板
    template = db.query(PBLCourseTemplate).filter(
        PBLCourseTemplate.id == template_id
    ).first()
    
    if not template:
        raise ValueError("模板不存在")
    
    # 检查学校是否有权使用该模板
    now = get_beijing_time_naive()
    permission = db.query(PBLTemplateSchoolPermission).filter(
        PBLTemplateSchoolPermission.template_id == template_id,
        PBLTemplateSchoolPermission.school_id == school_id,
        PBLTemplateSchoolPermission.is_active == 1,
        or_(
            PBLTemplateSchoolPermission.valid_from.is_(None),
            PBLTemplateSchoolPermission.valid_from <= now
        ),
        or_(
            PBLTemplateSchoolPermission.valid_until.is_(None),
            PBLTemplateSchoolPermission.valid_until >= now
        )
    ).first()
    
    if not permission:
        raise ValueError("您的学校无权使用此模板")
    
    # 检查实例数限制
    instance_count = db.query(PBLCourse).filter(
        PBLCourse.template_id == template_id,
        PBLCourse.school_id == school_id
    ).count()
    
    if permission.max_instances is not None and instance_count >= permission.max_instances:
        raise ValueError(f"已达到该模板的最大实例数限制（{permission.max_instances}）")
    
    return template, permission
