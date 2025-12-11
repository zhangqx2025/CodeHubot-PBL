"""
社团班课程系统API
- 班级管理（创建、列表、详情、更新、删除）
- 班级成员管理（添加、移除、设置角色）
- 基于模板创建课程并自动选课
- 学生端班级和课程查询
"""
from fastapi import APIRouter, Depends, HTTPException, status, Query, Body
from sqlalchemy.orm import Session
from sqlalchemy import func, and_, or_
from typing import List, Optional
from datetime import datetime
from pydantic import BaseModel

from ...db.session import SessionLocal
from ...core.response import success_response, error_response
from ...core.deps import get_db, get_current_admin
from ...models.admin import Admin, User
from ...models.pbl import (
    PBLClass, PBLClassMember, PBLCourse, PBLCourseTemplate,
    PBLCourseEnrollment, PBLUnit, PBLResource, PBLTask
)
from ...core.logging_config import get_logger

router = APIRouter()
logger = get_logger(__name__)

# ===== Pydantic 模型 =====

class ClassCreate(BaseModel):
    name: str
    class_type: str = 'club'  # club, project, interest, competition, regular
    description: Optional[str] = None
    max_students: int = 30

class ClassUpdate(BaseModel):
    name: Optional[str] = None
    class_type: Optional[str] = None
    description: Optional[str] = None
    max_students: Optional[int] = None
    is_open: Optional[bool] = None

class MemberAdd(BaseModel):
    student_ids: List[int]
    role: str = 'member'

class MemberRoleUpdate(BaseModel):
    role: str  # member, leader, deputy

class CourseCreateFromTemplate(BaseModel):
    template_id: int
    class_id: int
    title: Optional[str] = None
    auto_enroll: bool = True

# ===== 班级管理 =====

@router.get("/classes")
def get_classes(
    school_id: Optional[int] = None,
    class_type: Optional[str] = None,
    db: Session = Depends(get_db),
    current_admin: Admin = Depends(get_current_admin)
):
    """获取班级列表（支持按类型筛选）"""
    # 权限控制
    if current_admin.role != 'platform_admin':
        school_id = current_admin.school_id
    
    # 构建查询
    query = db.query(PBLClass).filter(PBLClass.is_active == 1)
    
    if school_id:
        query = query.filter(PBLClass.school_id == school_id)
    
    if class_type:
        query = query.filter(PBLClass.class_type == class_type)
    
    classes = query.order_by(PBLClass.created_at.desc()).all()
    
    result = []
    for cls in classes:
        # 统计课程数
        course_count = db.query(PBLCourse).filter(
            PBLCourse.class_id == cls.id,
            PBLCourse.status == 'published'
        ).count()
        
        result.append({
            'id': cls.id,
            'uuid': cls.uuid,
            'name': cls.name,
            'class_type': cls.class_type,
            'description': cls.description,
            'school_id': cls.school_id,
            'max_students': cls.max_students,
            'current_members': cls.current_members,
            'is_open': cls.is_open == 1,
            'is_active': cls.is_active == 1,
            'course_count': course_count,
            'created_at': cls.created_at.isoformat() if cls.created_at else None
        })
    
    return success_response(data=result)


@router.post("/classes")
def create_class(
    class_data: ClassCreate,
    db: Session = Depends(get_db),
    current_admin: Admin = Depends(get_current_admin)
):
    """创建班级"""
    # 权限检查
    if current_admin.role not in ['platform_admin', 'school_admin']:
        return error_response(
            message="无权限操作",
            code=403,
            status_code=status.HTTP_403_FORBIDDEN
        )
    
    # 从当前管理员获取学校ID
    school_id = current_admin.school_id
    if not school_id:
        return error_response(
            message="当前管理员未关联学校，无法创建班级",
            code=400,
            status_code=status.HTTP_400_BAD_REQUEST
        )
    
    # 创建班级
    new_class = PBLClass(
        school_id=school_id,
        name=class_data.name,
        class_type=class_data.class_type,
        description=class_data.description,
        max_students=class_data.max_students,
        current_members=0,
        is_active=1,
        is_open=1
    )
    db.add(new_class)
    db.commit()
    db.refresh(new_class)
    
    logger.info(f"创建班级 - 名称: {class_data.name}, 类型: {class_data.class_type}, 学校ID: {school_id}")
    
    return success_response(
        data={
            'id': new_class.id,
            'uuid': new_class.uuid,
            'name': new_class.name,
            'class_type': new_class.class_type,
            'description': new_class.description,
            'max_students': new_class.max_students,
            'current_members': new_class.current_members,
            'created_at': new_class.created_at.isoformat() if new_class.created_at else None
        },
        message="班级创建成功"
    )


@router.get("/classes/{class_uuid}")
def get_class_detail(
    class_uuid: str,
    db: Session = Depends(get_db),
    current_admin: Admin = Depends(get_current_admin)
):
    """获取班级详情"""
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
    
    # 获取班级成员
    members = db.query(PBLClassMember, User).join(
        User, PBLClassMember.student_id == User.id
    ).filter(
        PBLClassMember.class_id == pbl_class.id,
        PBLClassMember.is_active == 1
    ).all()
    
    member_list = []
    for member, user in members:
        member_list.append({
            'student_id': user.id,
            'name': user.name or user.real_name,
            'student_number': user.student_number,
            'role': member.role,
            'joined_at': member.joined_at.isoformat() if member.joined_at else None
        })
    
    # 获取班级课程
    courses = db.query(PBLCourse).filter(
        PBLCourse.class_id == pbl_class.id,
        PBLCourse.status == 'published'
    ).all()
    
    course_list = []
    for course in courses:
        # 统计选课人数
        enrolled_count = db.query(PBLCourseEnrollment).filter(
            PBLCourseEnrollment.course_id == course.id
        ).count()
        
        course_list.append({
            'id': course.id,
            'uuid': course.uuid,
            'title': course.title,
            'description': course.description,
            'cover_image': course.cover_image,
            'enrolled_count': enrolled_count
        })
    
    return success_response(data={
        'id': pbl_class.id,
        'uuid': pbl_class.uuid,
        'name': pbl_class.name,
        'class_type': pbl_class.class_type,
        'description': pbl_class.description,
        'max_students': pbl_class.max_students,
        'current_members': pbl_class.current_members,
        'is_open': pbl_class.is_open == 1,
        'is_active': pbl_class.is_active == 1,
        'members': member_list,
        'courses': course_list,
        'created_at': pbl_class.created_at.isoformat() if pbl_class.created_at else None
    })


@router.put("/classes/{class_uuid}")
def update_class(
    class_uuid: str,
    class_data: ClassUpdate,
    db: Session = Depends(get_db),
    current_admin: Admin = Depends(get_current_admin)
):
    """更新班级信息"""
    pbl_class = db.query(PBLClass).filter(PBLClass.uuid == class_uuid).first()
    if not pbl_class:
        return error_response(
            message="班级不存在",
            code=404,
            status_code=status.HTTP_404_NOT_FOUND
        )
    
    # 权限检查
    if current_admin.role not in ['platform_admin', 'school_admin']:
        return error_response(
            message="无权限操作",
            code=403,
            status_code=status.HTTP_403_FORBIDDEN
        )
    
    if current_admin.role == 'school_admin':
        if pbl_class.school_id != current_admin.school_id:
            return error_response(
                message="无权限操作该班级",
                code=403,
                status_code=status.HTTP_403_FORBIDDEN
            )
    
    # 更新字段
    if class_data.name is not None:
        pbl_class.name = class_data.name
    if class_data.class_type is not None:
        pbl_class.class_type = class_data.class_type
    if class_data.description is not None:
        pbl_class.description = class_data.description
    if class_data.max_students is not None:
        pbl_class.max_students = class_data.max_students
    if class_data.is_open is not None:
        pbl_class.is_open = 1 if class_data.is_open else 0
    
    db.commit()
    db.refresh(pbl_class)
    
    logger.info(f"更新班级 - UUID: {class_uuid}, 操作者: {current_admin.username}")
    
    return success_response(message="班级更新成功")


@router.delete("/classes/{class_uuid}")
def delete_class(
    class_uuid: str,
    db: Session = Depends(get_db),
    current_admin: Admin = Depends(get_current_admin)
):
    """删除班级（软删除）"""
    pbl_class = db.query(PBLClass).filter(PBLClass.uuid == class_uuid).first()
    if not pbl_class:
        return error_response(
            message="班级不存在",
            code=404,
            status_code=status.HTTP_404_NOT_FOUND
        )
    
    # 权限检查
    if current_admin.role not in ['platform_admin', 'school_admin']:
        return error_response(
            message="无权限操作",
            code=403,
            status_code=status.HTTP_403_FORBIDDEN
        )
    
    if current_admin.role == 'school_admin':
        if pbl_class.school_id != current_admin.school_id:
            return error_response(
                message="无权限操作该班级",
                code=403,
                status_code=status.HTTP_403_FORBIDDEN
            )
    
    # 软删除
    pbl_class.is_active = 0
    db.commit()
    
    logger.info(f"删除班级 - UUID: {class_uuid}, 操作者: {current_admin.username}")
    
    return success_response(message="班级已删除")


# ===== 班级成员管理 =====

@router.get("/classes/{class_uuid}/members")
def get_class_members(
    class_uuid: str,
    db: Session = Depends(get_db),
    current_admin: Admin = Depends(get_current_admin)
):
    """获取班级成员列表"""
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
    
    # 查询成员
    members = db.query(PBLClassMember, User).join(
        User, PBLClassMember.student_id == User.id
    ).filter(
        PBLClassMember.class_id == pbl_class.id,
        PBLClassMember.is_active == 1
    ).all()
    
    result = []
    for member, user in members:
        result.append({
            'student_id': user.id,
            'name': user.name or user.real_name,
            'student_number': user.student_number,
            'gender': user.gender,
            'role': member.role,
            'joined_at': member.joined_at.isoformat() if member.joined_at else None
        })
    
    return success_response(data=result)


@router.post("/classes/{class_uuid}/members")
def add_members_to_class(
    class_uuid: str,
    member_data: MemberAdd,
    db: Session = Depends(get_db),
    current_admin: Admin = Depends(get_current_admin)
):
    """添加成员到班级（并自动为其选上班级的所有课程）"""
    pbl_class = db.query(PBLClass).filter(PBLClass.uuid == class_uuid).first()
    if not pbl_class:
        return error_response(
            message="班级不存在",
            code=404,
            status_code=status.HTTP_404_NOT_FOUND
        )
    
    # 权限检查
    if current_admin.role not in ['platform_admin', 'school_admin']:
        return error_response(
            message="无权限操作",
            code=403,
            status_code=status.HTTP_403_FORBIDDEN
        )
    
    if current_admin.role == 'school_admin':
        if pbl_class.school_id != current_admin.school_id:
            return error_response(
                message="无权限操作该班级",
                code=403,
                status_code=status.HTTP_403_FORBIDDEN
            )
    
    added_count = 0
    auto_enrolled_courses = []
    
    for student_id in member_data.student_ids:
        # 检查学生是否存在
        student = db.query(User).filter(
            User.id == student_id,
            User.role == 'student'
        ).first()
        
        if not student:
            continue
        
        # 权限检查：学校管理员只能操作本校学生
        if current_admin.role == 'school_admin':
            if student.school_id != current_admin.school_id:
                continue
        
        # 检查是否已在班级中
        existing = db.query(PBLClassMember).filter(
            PBLClassMember.class_id == pbl_class.id,
            PBLClassMember.student_id == student_id,
            PBLClassMember.is_active == 1
        ).first()
        
        if existing:
            continue
        
        # 添加到班级
        member = PBLClassMember(
            class_id=pbl_class.id,
            student_id=student_id,
            role=member_data.role,
            is_active=1
        )
        db.add(member)
        added_count += 1
        
        # 自动为该学生选上班级的所有课程
        courses = db.query(PBLCourse).filter(
            PBLCourse.class_id == pbl_class.id,
            PBLCourse.status == 'published'
        ).all()
        
        for course in courses:
            # 检查是否已选课
            existing_enrollment = db.query(PBLCourseEnrollment).filter(
                PBLCourseEnrollment.course_id == course.id,
                PBLCourseEnrollment.user_id == student_id
            ).first()
            
            if not existing_enrollment:
                enrollment = PBLCourseEnrollment(
                    course_id=course.id,
                    user_id=student_id,
                    class_id=pbl_class.id,
                    status='active',
                    enrolled_at=datetime.now()
                )
                db.add(enrollment)
                if course.id not in auto_enrolled_courses:
                    auto_enrolled_courses.append(course.id)
    
    db.commit()
    
    logger.info(f"添加成员到班级 - 班级UUID: {class_uuid}, 成功: {added_count}, 自动选课: {len(auto_enrolled_courses)}")
    
    return success_response(
        data={
            'added_count': added_count,
            'auto_enrolled_courses': auto_enrolled_courses
        },
        message=f"成功添加 {added_count} 名成员到班级"
    )


@router.delete("/classes/{class_uuid}/members/{student_id}")
def remove_member_from_class(
    class_uuid: str,
    student_id: int,
    db: Session = Depends(get_db),
    current_admin: Admin = Depends(get_current_admin)
):
    """从班级移除成员"""
    pbl_class = db.query(PBLClass).filter(PBLClass.uuid == class_uuid).first()
    if not pbl_class:
        return error_response(
            message="班级不存在",
            code=404,
            status_code=status.HTTP_404_NOT_FOUND
        )
    
    # 权限检查
    if current_admin.role not in ['platform_admin', 'school_admin']:
        return error_response(
            message="无权限操作",
            code=403,
            status_code=status.HTTP_403_FORBIDDEN
        )
    
    if current_admin.role == 'school_admin':
        if pbl_class.school_id != current_admin.school_id:
            return error_response(
                message="无权限操作该班级",
                code=403,
                status_code=status.HTTP_403_FORBIDDEN
            )
    
    # 查找成员记录
    member = db.query(PBLClassMember).filter(
        PBLClassMember.class_id == pbl_class.id,
        PBLClassMember.student_id == student_id,
        PBLClassMember.is_active == 1
    ).first()
    
    if not member:
        return error_response(
            message="学生不在该班级中",
            code=404,
            status_code=status.HTTP_404_NOT_FOUND
        )
    
    # 软删除（标记为非活跃）
    member.is_active = 0
    member.left_at = datetime.now()
    db.commit()
    
    logger.info(f"从班级移除成员 - 班级UUID: {class_uuid}, 学生ID: {student_id}")
    
    return success_response(message="成员已从班级移除")


@router.put("/classes/{class_uuid}/members/{student_id}/role")
def update_member_role(
    class_uuid: str,
    student_id: int,
    role_data: MemberRoleUpdate,
    db: Session = Depends(get_db),
    current_admin: Admin = Depends(get_current_admin)
):
    """设置班级成员角色"""
    pbl_class = db.query(PBLClass).filter(PBLClass.uuid == class_uuid).first()
    if not pbl_class:
        return error_response(
            message="班级不存在",
            code=404,
            status_code=status.HTTP_404_NOT_FOUND
        )
    
    # 权限检查
    if current_admin.role not in ['platform_admin', 'school_admin']:
        return error_response(
            message="无权限操作",
            code=403,
            status_code=status.HTTP_403_FORBIDDEN
        )
    
    if current_admin.role == 'school_admin':
        if pbl_class.school_id != current_admin.school_id:
            return error_response(
                message="无权限操作该班级",
                code=403,
                status_code=status.HTTP_403_FORBIDDEN
            )
    
    # 查找成员记录
    member = db.query(PBLClassMember).filter(
        PBLClassMember.class_id == pbl_class.id,
        PBLClassMember.student_id == student_id,
        PBLClassMember.is_active == 1
    ).first()
    
    if not member:
        return error_response(
            message="学生不在该班级中",
            code=404,
            status_code=status.HTTP_404_NOT_FOUND
        )
    
    # 如果设置为班长，需要取消其他班长
    if role_data.role == 'leader':
        db.query(PBLClassMember).filter(
            PBLClassMember.class_id == pbl_class.id,
            PBLClassMember.role == 'leader',
            PBLClassMember.is_active == 1
        ).update({'role': 'member'})
    
    # 更新角色
    member.role = role_data.role
    db.commit()
    
    logger.info(f"更新成员角色 - 班级UUID: {class_uuid}, 学生ID: {student_id}, 角色: {role_data.role}")
    
    return success_response(message=f"成员角色已更新为 {role_data.role}")


# ===== 基于模板创建课程 =====

@router.get("/course-templates")
def get_course_templates(
    category: Optional[str] = None,
    difficulty: Optional[str] = None,
    db: Session = Depends(get_db),
    current_admin: Admin = Depends(get_current_admin)
):
    """获取课程模板列表"""
    query = db.query(PBLCourseTemplate).filter(PBLCourseTemplate.is_public == 1)
    
    if category:
        query = query.filter(PBLCourseTemplate.category == category)
    if difficulty:
        query = query.filter(PBLCourseTemplate.difficulty == difficulty)
    
    templates = query.order_by(PBLCourseTemplate.created_at.desc()).all()
    
    result = []
    for template in templates:
        result.append({
            'id': template.id,
            'uuid': template.uuid,
            'title': template.title,
            'description': template.description,
            'cover_image': template.cover_image,
            'duration': template.duration,
            'difficulty': template.difficulty,
            'category': template.category,
            'version': template.version,
            'usage_count': template.usage_count,
            'created_at': template.created_at.isoformat() if template.created_at else None
        })
    
    return success_response(data=result)


@router.post("/courses/create-from-template")
def create_course_from_template(
    course_data: CourseCreateFromTemplate,
    db: Session = Depends(get_db),
    current_admin: Admin = Depends(get_current_admin)
):
    """基于模板为班级创建课程（并自动为班级成员选课）"""
    # 权限检查
    if current_admin.role not in ['platform_admin', 'school_admin']:
        return error_response(
            message="无权限操作",
            code=403,
            status_code=status.HTTP_403_FORBIDDEN
        )
    
    # 检查模板是否存在
    template = db.query(PBLCourseTemplate).filter(
        PBLCourseTemplate.id == course_data.template_id
    ).first()
    if not template:
        return error_response(
            message="课程模板不存在",
            code=404,
            status_code=status.HTTP_404_NOT_FOUND
        )
    
    # 检查班级是否存在
    pbl_class = db.query(PBLClass).filter(PBLClass.id == course_data.class_id).first()
    if not pbl_class:
        return error_response(
            message="班级不存在",
            code=404,
            status_code=status.HTTP_404_NOT_FOUND
        )
    
    # 权限检查：学校管理员只能操作本校班级
    if current_admin.role == 'school_admin':
        if pbl_class.school_id != current_admin.school_id:
            return error_response(
                message="无权限操作该班级",
                code=403,
                status_code=status.HTTP_403_FORBIDDEN
            )
    
    # 创建课程
    course_title = course_data.title if course_data.title else f"{pbl_class.name}{template.title}"
    
    new_course = PBLCourse(
        template_id=template.id,
        template_version=template.version,
        is_customized=0,
        sync_with_template=1,
        class_id=pbl_class.id,
        class_name=pbl_class.name,
        title=course_title,
        description=template.description,
        cover_image=template.cover_image,
        duration=template.duration,
        difficulty=template.difficulty,
        status='published',
        creator_id=current_admin.id,
        school_id=pbl_class.school_id
    )
    db.add(new_course)
    db.flush()
    
    # TODO: 从模板复制单元、资源、任务（这里简化处理，实际需要完整的复制逻辑）
    units_count = 0
    resources_count = 0
    tasks_count = 0
    
    # 自动为班级成员选课
    enrolled_count = 0
    if course_data.auto_enroll:
        members = db.query(PBLClassMember).filter(
            PBLClassMember.class_id == pbl_class.id,
            PBLClassMember.is_active == 1
        ).all()
        
        for member in members:
            # 检查是否已选课
            existing = db.query(PBLCourseEnrollment).filter(
                PBLCourseEnrollment.course_id == new_course.id,
                PBLCourseEnrollment.user_id == member.student_id
            ).first()
            
            if not existing:
                enrollment = PBLCourseEnrollment(
                    course_id=new_course.id,
                    user_id=member.student_id,
                    class_id=pbl_class.id,
                    status='active',
                    enrolled_at=datetime.now()
                )
                db.add(enrollment)
                enrolled_count += 1
    
    # 更新模板使用次数
    template.usage_count += 1
    
    db.commit()
    db.refresh(new_course)
    
    logger.info(f"基于模板创建课程 - 模板ID: {template.id}, 班级ID: {pbl_class.id}, 课程ID: {new_course.id}")
    
    return success_response(
        data={
            'course_id': new_course.id,
            'course_uuid': new_course.uuid,
            'title': new_course.title,
            'class_name': pbl_class.name,
            'template_title': template.title,
            'units_count': units_count,
            'resources_count': resources_count,
            'tasks_count': tasks_count,
            'enrolled_students': enrolled_count
        },
        message="课程创建成功"
    )


# ===== 为课程的班级成员批量选课 =====

@router.post("/courses/{course_id}/enroll-class-members")
def enroll_class_members_to_course(
    course_id: int,
    db: Session = Depends(get_db),
    current_admin: Admin = Depends(get_current_admin)
):
    """为课程的班级成员批量选课"""
    # 检查课程是否存在
    course = db.query(PBLCourse).filter(PBLCourse.id == course_id).first()
    if not course:
        return error_response(
            message="课程不存在",
            code=404,
            status_code=status.HTTP_404_NOT_FOUND
        )
    
    if not course.class_id:
        return error_response(
            message="该课程未关联班级",
            code=400,
            status_code=status.HTTP_400_BAD_REQUEST
        )
    
    # 权限检查
    if current_admin.role not in ['platform_admin', 'school_admin']:
        return error_response(
            message="无权限操作",
            code=403,
            status_code=status.HTTP_403_FORBIDDEN
        )
    
    if current_admin.role == 'school_admin':
        if course.school_id != current_admin.school_id:
            return error_response(
                message="无权限操作该课程",
                code=403,
                status_code=status.HTTP_403_FORBIDDEN
            )
    
    # 获取班级所有成员
    members = db.query(PBLClassMember).filter(
        PBLClassMember.class_id == course.class_id,
        PBLClassMember.is_active == 1
    ).all()
    
    enrolled_count = 0
    for member in members:
        # 检查是否已选课
        existing = db.query(PBLCourseEnrollment).filter(
            PBLCourseEnrollment.course_id == course.id,
            PBLCourseEnrollment.user_id == member.student_id
        ).first()
        
        if not existing:
            enrollment = PBLCourseEnrollment(
                course_id=course.id,
                user_id=member.student_id,
                class_id=course.class_id,
                status='active',
                enrolled_at=datetime.now()
            )
            db.add(enrollment)
            enrolled_count += 1
    
    db.commit()
    
    logger.info(f"批量选课 - 课程ID: {course_id}, 班级ID: {course.class_id}, 选课人数: {enrolled_count}")
    
    return success_response(
        data={'enrolled_count': enrolled_count},
        message=f"成功为 {enrolled_count} 名学生选课"
    )
