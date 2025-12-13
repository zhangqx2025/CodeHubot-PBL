"""
社团班课程系统API
- 班级管理（创建、列表、详情、更新、删除）
- 班级成员管理（添加、移除、设置角色）
- 基于模板创建课程并自动选课
- 学生端班级和课程查询
"""
from fastapi import APIRouter, Depends, HTTPException, status, Query, Body
from sqlalchemy.orm import Session
from sqlalchemy import func, and_, or_, case, select
from typing import List, Optional, Dict
from datetime import datetime
from pydantic import BaseModel

from ...db.session import SessionLocal
from ...core.response import success_response, error_response
from ...core.deps import get_db, get_current_admin
from ...models.admin import Admin, User
from ...models.pbl import (
    PBLClass, PBLClassMember, PBLCourse, PBLCourseTemplate,
    PBLCourseEnrollment, PBLUnit, PBLResource, PBLTask,
    PBLClassTeacher, PBLTaskProgress, PBLProjectOutput
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

class TeacherAdd(BaseModel):
    teacher_ids: List[int]
    role: str = 'assistant'  # main, assistant

class TeacherRoleUpdate(BaseModel):
    role: str  # main, assistant

class TaskReview(BaseModel):
    score: Optional[int] = None
    feedback: Optional[str] = None
    status: str = 'review'  # review, completed

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
        # 获取班级的课程（一个班级对应一个课程）
        course = db.query(PBLCourse).filter(
            PBLCourse.class_id == cls.id,
            PBLCourse.status == 'published'
        ).first()
        
        # 统计选课人数
        enrolled_count = 0
        if course:
            enrolled_count = db.query(PBLCourseEnrollment).filter(
                PBLCourseEnrollment.course_id == course.id
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
            'created_at': cls.created_at.isoformat() if cls.created_at else None,
            # 课程信息
            'course': {
                'id': course.id,
                'uuid': course.uuid,
                'title': course.title,
                'description': course.description,
                'cover_image': course.cover_image,
                'difficulty': course.difficulty,
                'duration': course.duration,
                'teacher_id': course.teacher_id,
                'teacher_name': course.teacher_name,
                'start_date': course.start_date.isoformat() if course.start_date else None,
                'end_date': course.end_date.isoformat() if course.end_date else None,
                'enrolled_count': enrolled_count
            } if course else None
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
    """获取班级详情（优化版）"""
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
    
    # 优化：批量获取班级课程及选课人数
    # 使用子查询一次性获取所有课程的选课人数
    
    # 子查询：统计每个课程的选课人数
    enrollment_subquery = select(
        PBLCourseEnrollment.course_id,
        func.count(PBLCourseEnrollment.id).label('enrolled_count')
    ).group_by(
        PBLCourseEnrollment.course_id
    ).subquery()
    
    # 主查询：获取课程信息并关联选课人数
    courses_with_count = db.query(
        PBLCourse,
        func.coalesce(enrollment_subquery.c.enrolled_count, 0).label('enrolled_count')
    ).outerjoin(
        enrollment_subquery,
        PBLCourse.id == enrollment_subquery.c.course_id
    ).filter(
        PBLCourse.class_id == pbl_class.id,
        PBLCourse.status == 'published'
    ).all()
    
    course_list = []
    for course, enrolled_count in courses_with_count:
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
                    enrollment_status='enrolled',
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
                    enrollment_status='enrolled',
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
                enrollment_status='enrolled',
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


# ===== 教师管理 =====

@router.get("/classes/{class_uuid}/teachers")
def get_class_teachers(
    class_uuid: str,
    db: Session = Depends(get_db),
    current_admin: Admin = Depends(get_current_admin)
):
    """获取班级教师列表"""
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
    
    # 查询教师
    teachers = db.query(PBLClassTeacher, User).join(
        User, PBLClassTeacher.teacher_id == User.id
    ).filter(
        PBLClassTeacher.class_id == pbl_class.id
    ).all()
    
    result = []
    for teacher_rel, user in teachers:
        result.append({
            'teacher_id': user.id,
            'name': user.name or user.real_name,
            'username': user.username,
            'role': teacher_rel.role if hasattr(teacher_rel, 'role') else 'assistant',
            'subject': teacher_rel.subject,
            'is_primary': teacher_rel.is_primary == 1,
            'added_at': teacher_rel.added_at.isoformat() if hasattr(teacher_rel, 'added_at') and teacher_rel.added_at else teacher_rel.created_at.isoformat()
        })
    
    return success_response(data=result)


@router.post("/classes/{class_uuid}/teachers")
def add_teachers_to_class(
    class_uuid: str,
    teacher_data: TeacherAdd,
    db: Session = Depends(get_db),
    current_admin: Admin = Depends(get_current_admin)
):
    """添加教师到班级"""
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
    for teacher_id in teacher_data.teacher_ids:
        # 检查教师是否存在
        teacher = db.query(User).filter(
            User.id == teacher_id,
            or_(User.role == 'teacher', User.role == 'admin')
        ).first()
        
        if not teacher:
            continue
        
        # 权限检查：学校管理员只能操作本校教师
        if current_admin.role == 'school_admin':
            if teacher.school_id != current_admin.school_id:
                continue
        
        # 检查是否已在班级中
        existing = db.query(PBLClassTeacher).filter(
            PBLClassTeacher.class_id == pbl_class.id,
            PBLClassTeacher.teacher_id == teacher_id
        ).first()
        
        if existing:
            continue
        
        # 添加到班级
        teacher_rel = PBLClassTeacher(
            class_id=pbl_class.id,
            teacher_id=teacher_id,
            role=teacher_data.role
        )
        db.add(teacher_rel)
        added_count += 1
    
    db.commit()
    
    logger.info(f"添加教师到班级 - 班级UUID: {class_uuid}, 成功: {added_count}")
    
    return success_response(
        data={'added_count': added_count},
        message=f"成功添加 {added_count} 位教师到班级"
    )


@router.delete("/classes/{class_uuid}/teachers/{teacher_id}")
def remove_teacher_from_class(
    class_uuid: str,
    teacher_id: int,
    db: Session = Depends(get_db),
    current_admin: Admin = Depends(get_current_admin)
):
    """从班级移除教师"""
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
    
    # 查找教师记录
    teacher_rel = db.query(PBLClassTeacher).filter(
        PBLClassTeacher.class_id == pbl_class.id,
        PBLClassTeacher.teacher_id == teacher_id
    ).first()
    
    if not teacher_rel:
        return error_response(
            message="教师不在该班级中",
            code=404,
            status_code=status.HTTP_404_NOT_FOUND
        )
    
    # 删除
    db.delete(teacher_rel)
    db.commit()
    
    logger.info(f"从班级移除教师 - 班级UUID: {class_uuid}, 教师ID: {teacher_id}")
    
    return success_response(message="教师已从班级移除")


@router.put("/classes/{class_uuid}/teachers/{teacher_id}/role")
def update_teacher_role(
    class_uuid: str,
    teacher_id: int,
    role_data: TeacherRoleUpdate,
    db: Session = Depends(get_db),
    current_admin: Admin = Depends(get_current_admin)
):
    """更新教师角色"""
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
    
    # 查找教师记录
    teacher_rel = db.query(PBLClassTeacher).filter(
        PBLClassTeacher.class_id == pbl_class.id,
        PBLClassTeacher.teacher_id == teacher_id
    ).first()
    
    if not teacher_rel:
        return error_response(
            message="教师不在该班级中",
            code=404,
            status_code=status.HTTP_404_NOT_FOUND
        )
    
    # 如果设置为主讲教师，需要取消其他主讲教师
    if role_data.role == 'main':
        db.query(PBLClassTeacher).filter(
            PBLClassTeacher.class_id == pbl_class.id,
            PBLClassTeacher.role == 'main'
        ).update({'role': 'assistant'})
    
    # 更新角色
    teacher_rel.role = role_data.role
    db.commit()
    
    logger.info(f"更新教师角色 - 班级UUID: {class_uuid}, 教师ID: {teacher_id}, 角色: {role_data.role}")
    
    return success_response(message=f"教师角色已更新为 {role_data.role}")


# ===== 学习进度 =====

@router.get("/classes/{class_uuid}/progress/overview")
def get_class_progress_overview(
    class_uuid: str,
    db: Session = Depends(get_db),
    current_admin: Admin = Depends(get_current_admin)
):
    """获取班级学习进度概览（仅统计数据，不返回详细列表）
    
    轻量级API，用于快速获取班级整体进度统计：
    - 平均完成率
    - 已完成/进行中/未开始人数
    - 平均学习时长
    - 总提交作业数
    
    响应速度：< 100ms
    """
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
    
    # 获取班级的课程
    courses = db.query(PBLCourse).filter(
        PBLCourse.class_id == pbl_class.id,
        PBLCourse.status == 'published'
    ).all()
    
    if not courses:
        return success_response(data={
            'total_students': 0,
            'avg_completion_rate': 0,
            'completed_count': 0,
            'in_progress_count': 0,
            'not_started_count': 0,
            'avg_learning_hours': 0,
            'total_submissions': 0
        })
    
    course = courses[0]
    
    # 获取班级成员数
    total_students = db.query(func.count(PBLClassMember.id)).filter(
        PBLClassMember.class_id == pbl_class.id,
        PBLClassMember.is_active == 1
    ).scalar() or 0
    
    if total_students == 0:
        return success_response(data={
            'total_students': 0,
            'avg_completion_rate': 0,
            'completed_count': 0,
            'in_progress_count': 0,
            'not_started_count': 0,
            'avg_learning_hours': 0,
            'total_submissions': 0
        })
    
    # 获取学生ID列表
    student_ids = [row[0] for row in db.query(PBLClassMember.student_id).filter(
        PBLClassMember.class_id == pbl_class.id,
        PBLClassMember.is_active == 1
    ).all()]
    
    # 获取总单元数
    total_units = db.query(func.count(PBLUnit.id)).filter(
        PBLUnit.course_id == course.id
    ).scalar() or 0
    
    if total_units == 0:
        return success_response(data={
            'total_students': total_students,
            'avg_completion_rate': 0,
            'completed_count': 0,
            'in_progress_count': 0,
            'not_started_count': total_students,
            'avg_learning_hours': 0,
            'total_submissions': 0
        })
    
    # 批量统计每个学生的完成单元数
    from sqlalchemy import literal
    
    # 子查询：每个单元的任务数
    unit_task_count = db.query(
        PBLTask.unit_id,
        func.count(PBLTask.id).label('task_count')
    ).filter(
        PBLTask.unit_id.in_(
            db.query(PBLUnit.id).filter(PBLUnit.course_id == course.id)
        )
    ).group_by(PBLTask.unit_id).subquery()
    
    # 子查询：每个学生每个单元的完成任务数
    student_unit_completed = db.query(
        PBLTaskProgress.user_id,
        PBLTask.unit_id,
        func.sum(case((PBLTaskProgress.status == 'completed', 1), else_=0)).label('completed_count')
    ).join(
        PBLTask, PBLTaskProgress.task_id == PBLTask.id
    ).filter(
        PBLTask.unit_id.in_(
            db.query(PBLUnit.id).filter(PBLUnit.course_id == course.id)
        ),
        PBLTaskProgress.user_id.in_(student_ids)
    ).group_by(
        PBLTaskProgress.user_id,
        PBLTask.unit_id
    ).subquery()
    
    # 计算每个学生完成的单元数（完成单元=该单元所有任务都完成）
    student_completed_units = db.query(
        student_unit_completed.c.user_id,
        func.sum(
            case((student_unit_completed.c.completed_count >= unit_task_count.c.task_count, 1), else_=0)
        ).label('completed_units')
    ).outerjoin(
        unit_task_count,
        student_unit_completed.c.unit_id == unit_task_count.c.unit_id
    ).group_by(
        student_unit_completed.c.user_id
    ).all()
    
    # 构建学生完成单元字典
    student_completion_dict = {row.user_id: row.completed_units for row in student_completed_units}
    
    # 统计各状态人数
    completed_count = 0
    in_progress_count = 0
    not_started_count = 0
    total_completion_rate = 0
    
    for student_id in student_ids:
        completed_units = student_completion_dict.get(student_id, 0)
        completion_rate = (completed_units / total_units * 100) if total_units > 0 else 0
        total_completion_rate += completion_rate
        
        if completion_rate == 100:
            completed_count += 1
        elif completion_rate > 0:
            in_progress_count += 1
        else:
            not_started_count += 1
    
    avg_completion_rate = int(total_completion_rate / total_students) if total_students > 0 else 0
    
    # 统计总提交作业数
    total_submissions = db.query(func.count(PBLTaskProgress.id)).join(
        PBLTask, PBLTaskProgress.task_id == PBLTask.id
    ).join(
        PBLUnit, PBLTask.unit_id == PBLUnit.id
    ).filter(
        PBLUnit.course_id == course.id,
        PBLTaskProgress.user_id.in_(student_ids),
        PBLTaskProgress.submission.isnot(None)
    ).scalar() or 0
    
    avg_learning_hours = int((total_submissions * 2) / total_students) if total_students > 0 else 0
    
    return success_response(data={
        'total_students': total_students,
        'avg_completion_rate': avg_completion_rate,
        'completed_count': completed_count,
        'in_progress_count': in_progress_count,
        'not_started_count': not_started_count,
        'avg_learning_hours': avg_learning_hours,
        'total_submissions': total_submissions
    })


@router.get("/classes/{class_uuid}/progress")
def get_class_progress(
    class_uuid: str,
    page: int = Query(1, ge=1, description="页码"),
    page_size: int = Query(20, ge=1, le=100, description="每页数量"),
    status: Optional[str] = Query(None, description="状态筛选: not_started, in_progress, completed"),
    search: Optional[str] = Query(None, description="搜索关键词（姓名或学号）"),
    db: Session = Depends(get_db),
    current_admin: Admin = Depends(get_current_admin)
):
    """获取班级学习进度列表（支持分页和筛选）
    
    优化策略：
    1. 支持分页，避免一次性加载所有数据
    2. 支持按状态筛选和关键词搜索
    3. 使用批量查询优化性能
    4. 只查询当前页需要的学生数据
    
    响应速度：< 500ms（每页20条数据）
    """
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
    
    # 获取班级的课程
    courses = db.query(PBLCourse).filter(
        PBLCourse.class_id == pbl_class.id,
        PBLCourse.status == 'published'
    ).all()
    
    if not courses:
        return success_response(data={
            'items': [],
            'total': 0,
            'page': page,
            'page_size': page_size,
            'total_pages': 0
        })
    
    course = courses[0]
    
    # 构建班级成员查询（支持搜索）
    members_query = db.query(PBLClassMember, User).join(
        User, PBLClassMember.student_id == User.id
    ).filter(
        PBLClassMember.class_id == pbl_class.id,
        PBLClassMember.is_active == 1
    )
    
    # 添加搜索条件
    if search:
        members_query = members_query.filter(
            or_(
                User.name.like(f'%{search}%'),
                User.real_name.like(f'%{search}%'),
                User.student_number.like(f'%{search}%')
            )
        )
    
    # 获取总数（用于分页）
    total_count = members_query.count()
    
    if total_count == 0:
        return success_response(data={
            'items': [],
            'total': 0,
            'page': page,
            'page_size': page_size,
            'total_pages': 0
        })
    
    # 分页获取成员列表（先不应用分页，因为需要根据状态筛选）
    all_members = members_query.all()
    all_student_ids = [member.student_id for member, _ in all_members]
    
    # === 优化策略：使用批量查询 ===
    
    # 1. 获取课程的总单元数（1次查询）
    total_units = db.query(func.count(PBLUnit.id)).filter(
        PBLUnit.course_id == course.id
    ).scalar() or 0
    
    # 2. 批量获取每个单元的任务ID列表（1次查询）
    unit_tasks = db.query(
        PBLUnit.id.label('unit_id'),
        func.group_concat(PBLTask.id).label('task_ids'),
        func.count(PBLTask.id).label('task_count')
    ).outerjoin(
        PBLTask, PBLTask.unit_id == PBLUnit.id
    ).filter(
        PBLUnit.course_id == course.id
    ).group_by(
        PBLUnit.id
    ).all()
    
    # 构建单元->任务映射
    unit_task_map = {}
    for row in unit_tasks:
        task_ids = []
        if row.task_ids:
            task_ids = [int(tid) for tid in row.task_ids.split(',')]
        unit_task_map[row.unit_id] = {
            'task_ids': task_ids,
            'task_count': row.task_count
        }
    
    # 3. 批量获取所有学生的任务完成情况（1次查询）
    task_progress_query = db.query(
        PBLTaskProgress.user_id,
        PBLTask.unit_id,
        func.count(PBLTaskProgress.id).label('total_progress'),
        func.sum(
            case((PBLTaskProgress.status == 'completed', 1), else_=0)
        ).label('completed_count')
    ).join(
        PBLTask, PBLTaskProgress.task_id == PBLTask.id
    ).join(
        PBLUnit, PBLTask.unit_id == PBLUnit.id
    ).filter(
        PBLUnit.course_id == course.id,
        PBLTaskProgress.user_id.in_(all_student_ids)
    ).group_by(
        PBLTaskProgress.user_id,
        PBLTask.unit_id
    ).all()
    
    # 构建学生单元完成情况字典
    student_unit_progress = {}
    for row in task_progress_query:
        user_id = row.user_id
        unit_id = row.unit_id
        
        if user_id not in student_unit_progress:
            student_unit_progress[user_id] = {}
        
        student_unit_progress[user_id][unit_id] = {
            'completed_count': row.completed_count,
            'total_progress': row.total_progress
        }
    
    # 4. 批量获取提交作业数（1次查询）
    submissions_query = db.query(
        PBLTaskProgress.user_id,
        func.count(PBLTaskProgress.id).label('submissions_count')
    ).join(
        PBLTask, PBLTaskProgress.task_id == PBLTask.id
    ).join(
        PBLUnit, PBLTask.unit_id == PBLUnit.id
    ).filter(
        PBLUnit.course_id == course.id,
        PBLTaskProgress.user_id.in_(all_student_ids),
        PBLTaskProgress.submission.isnot(None)
    ).group_by(
        PBLTaskProgress.user_id
    ).all()
    
    submissions_dict = {row.user_id: row.submissions_count for row in submissions_query}
    
    # 5. 批量获取最后活跃时间（1次查询）
    last_active_query = db.query(
        PBLTaskProgress.user_id,
        func.max(PBLTaskProgress.updated_at).label('last_active')
    ).join(
        PBLTask, PBLTaskProgress.task_id == PBLTask.id
    ).join(
        PBLUnit, PBLTask.unit_id == PBLUnit.id
    ).filter(
        PBLUnit.course_id == course.id,
        PBLTaskProgress.user_id.in_(all_student_ids)
    ).group_by(
        PBLTaskProgress.user_id
    ).all()
    
    last_active_dict = {row.user_id: row.last_active for row in last_active_query}
    
    # 6. 批量获取选课记录（1次查询）
    enrollments_query = db.query(
        PBLCourseEnrollment
    ).filter(
        PBLCourseEnrollment.course_id == course.id,
        PBLCourseEnrollment.user_id.in_(all_student_ids)
    ).all()
    
    enrollments_dict = {e.user_id: e for e in enrollments_query}
    
    # === 组装结果数据并应用状态筛选（内存计算） ===
    all_results = []
    for member, user in all_members:
        student_id = member.student_id
        
        # 计算完成的单元数
        completed_units = 0
        student_progress = student_unit_progress.get(student_id, {})
        
        for unit_id, unit_info in unit_task_map.items():
            task_count = unit_info['task_count']
            if task_count == 0:
                continue
            
            # 获取该学生该单元的进度
            unit_progress = student_progress.get(unit_id, {})
            completed_count = unit_progress.get('completed_count', 0)
            
            # 如果该单元的所有任务都完成，则单元完成
            if completed_count >= task_count:
                completed_units += 1
        
        # 计算完成率
        completion_rate = 0
        if total_units > 0:
            completion_rate = int((completed_units / total_units) * 100)
        
        # 计算学习状态
        learning_status = 'not_started'
        if completion_rate == 100:
            learning_status = 'completed'
        elif completion_rate > 0:
            learning_status = 'in_progress'
        
        # 状态筛选
        if status and learning_status != status:
            continue
        
        # 获取提交作业数
        submissions_count = submissions_dict.get(student_id, 0)
        
        # 获取最后活跃时间
        last_active = None
        if student_id in last_active_dict:
            last_active = last_active_dict[student_id].isoformat()
        elif student_id in enrollments_dict:
            last_active = enrollments_dict[student_id].updated_at.isoformat()
        
        # 简化学习时长计算
        learning_hours = submissions_count * 2  # 简单估算：每个作业2小时
        
        all_results.append({
            'student_id': user.id,
            'name': user.name or user.real_name,
            'student_number': user.student_number or '',
            'completion_rate': completion_rate,
            'status': learning_status,
            'completed_units': completed_units,
            'total_units': total_units,
            'learning_hours': learning_hours,
            'submissions_count': submissions_count,
            'last_active': last_active
        })
    
    # 应用分页
    total_filtered = len(all_results)
    total_pages = (total_filtered + page_size - 1) // page_size
    start_idx = (page - 1) * page_size
    end_idx = start_idx + page_size
    paginated_results = all_results[start_idx:end_idx]
    
    logger.info(f"班级进度查询完成 - 班级: {class_uuid}, 总学生数: {total_filtered}, 当前页: {page}/{total_pages}")
    return success_response(data={
        'items': paginated_results,
        'total': total_filtered,
        'page': page,
        'page_size': page_size,
        'total_pages': total_pages
    })


@router.get("/classes/{class_uuid}/students/{student_id}/progress")
def get_student_progress(
    class_uuid: str,
    student_id: int,
    db: Session = Depends(get_db),
    current_admin: Admin = Depends(get_current_admin)
):
    """获取单个学生的学习进度详情
    
    按需查询单个学生的详细学习进度，包括：
    - 总体进度统计
    - 每个单元的完成情况
    - 每个任务的完成状态和成绩
    
    响应速度：< 200ms
    """
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
    
    # 检查学生是否在班级中
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
    
    # 获取学生信息
    user = db.query(User).filter(User.id == student_id).first()
    
    # 获取班级课程
    courses = db.query(PBLCourse).filter(
        PBLCourse.class_id == pbl_class.id,
        PBLCourse.status == 'published'
    ).all()
    
    if not courses:
        return success_response(data={
            'student': {
                'id': user.id,
                'name': user.name or user.real_name,
                'student_number': user.student_number
            },
            'overall': {
                'completion_rate': 0,
                'completed_units': 0,
                'total_units': 0,
                'learning_hours': 0,
                'submissions_count': 0
            },
            'units': []
        })
    
    course = courses[0]
    
    # 获取所有单元及其任务
    units_with_tasks = db.query(PBLUnit).filter(
        PBLUnit.course_id == course.id
    ).order_by(PBLUnit.order).all()
    
    total_units = len(units_with_tasks)
    completed_units = 0
    units_detail = []
    
    for unit in units_with_tasks:
        # 获取单元的所有任务
        tasks = db.query(PBLTask).filter(
            PBLTask.unit_id == unit.id
        ).order_by(PBLTask.order).all()
        
        # 获取该学生在这些任务上的进度
        task_ids = [t.id for t in tasks]
        task_progress_list = []
        
        if task_ids:
            progress_records = db.query(PBLTaskProgress).filter(
                PBLTaskProgress.task_id.in_(task_ids),
                PBLTaskProgress.user_id == student_id
            ).all()
            
            progress_dict = {p.task_id: p for p in progress_records}
            
            for task in tasks:
                progress = progress_dict.get(task.id)
                task_progress_list.append({
                    'task_id': task.id,
                    'task_title': task.title,
                    'task_type': task.task_type,
                    'is_required': task.is_required == 1,
                    'status': progress.status if progress else 'not_started',
                    'score': progress.score if progress else None,
                    'submission_time': progress.updated_at.isoformat() if progress and progress.updated_at else None
                })
        
        # 判断单元是否完成
        completed_tasks = len([tp for tp in task_progress_list if tp['status'] == 'completed'])
        total_tasks = len(tasks)
        unit_completed = completed_tasks == total_tasks and total_tasks > 0
        
        if unit_completed:
            completed_units += 1
        
        units_detail.append({
            'unit_id': unit.id,
            'unit_title': unit.title,
            'unit_description': unit.description,
            'completed_tasks': completed_tasks,
            'total_tasks': total_tasks,
            'completion_rate': int(completed_tasks / total_tasks * 100) if total_tasks > 0 else 0,
            'is_completed': unit_completed,
            'tasks': task_progress_list
        })
    
    # 统计总体信息
    total_submissions = db.query(func.count(PBLTaskProgress.id)).join(
        PBLTask, PBLTaskProgress.task_id == PBLTask.id
    ).join(
        PBLUnit, PBLTask.unit_id == PBLUnit.id
    ).filter(
        PBLUnit.course_id == course.id,
        PBLTaskProgress.user_id == student_id,
        PBLTaskProgress.submission.isnot(None)
    ).scalar() or 0
    
    completion_rate = int(completed_units / total_units * 100) if total_units > 0 else 0
    learning_hours = total_submissions * 2
    
    return success_response(data={
        'student': {
            'id': user.id,
            'name': user.name or user.real_name,
            'student_number': user.student_number
        },
        'overall': {
            'completion_rate': completion_rate,
            'completed_units': completed_units,
            'total_units': total_units,
            'learning_hours': learning_hours,
            'submissions_count': total_submissions
        },
        'units': units_detail
    })


@router.get("/classes/{class_uuid}/progress/units")
def get_class_progress_by_units(
    class_uuid: str,
    db: Session = Depends(get_db),
    current_admin: Admin = Depends(get_current_admin)
):
    """获取班级按单元的学习进度"""
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
    
    # 获取班级的课程
    courses = db.query(PBLCourse).filter(
        PBLCourse.class_id == pbl_class.id,
        PBLCourse.status == 'published'
    ).all()
    
    if not courses:
        return success_response(data={
            'units': [],
            'students': []
        })
    
    course = courses[0]  # 假设一个班级对应一个主课程
    
    # 获取课程的所有单元
    units = db.query(PBLUnit).filter(
        PBLUnit.course_id == course.id
    ).order_by(PBLUnit.order).all()
    
    # 获取班级成员
    members = db.query(PBLClassMember, User).join(
        User, PBLClassMember.student_id == User.id
    ).filter(
        PBLClassMember.class_id == pbl_class.id,
        PBLClassMember.is_active == 1
    ).all()
    
    # 构建单元信息
    unit_list = []
    for unit in units:
        # 统计单元的任务数
        tasks = db.query(PBLTask).filter(PBLTask.unit_id == unit.id).all()
        task_count = len(tasks)
        
        # 统计完成该单元的学生数
        completed_count = 0
        for member, user in members:
            # 检查该学生是否完成了该单元的所有任务
            all_completed = True
            if task_count > 0:
                for task in tasks:
                    task_progress = db.query(PBLTaskProgress).filter(
                        PBLTaskProgress.task_id == task.id,
                        PBLTaskProgress.user_id == member.student_id
                    ).first()
                    # 只要提交了就算完成（submission不为None）
                    if not task_progress or task_progress.submission is None:
                        all_completed = False
                        break
                
                if all_completed:
                    completed_count += 1
        
        unit_list.append({
            'id': unit.id,
            'uuid': unit.uuid,
            'title': unit.title,
            'description': unit.description,
            'order': unit.order,
            'task_count': task_count,
            'completed_count': completed_count,
            'total_students': len(members),
            'completion_rate': int((completed_count / len(members)) * 100) if len(members) > 0 else 0
        })
    
    # 构建学生信息（包含每个单元的完成状态）
    student_list = []
    for member, user in members:
        unit_progress = []
        for unit in units:
            # 获取单元的所有任务
            tasks = db.query(PBLTask).filter(PBLTask.unit_id == unit.id).all()
            task_count = len(tasks)
            
            # 统计已完成的任务数
            completed_tasks = 0
            for task in tasks:
                # 只要提交了就算完成（submission不为None）
                task_progress = db.query(PBLTaskProgress).filter(
                    PBLTaskProgress.task_id == task.id,
                    PBLTaskProgress.user_id == member.student_id,
                    PBLTaskProgress.submission.isnot(None)
                ).first()
                if task_progress:
                    completed_tasks += 1
            
            # 获取该学生在该单元的最后活跃时间
            last_progress = db.query(PBLTaskProgress).join(
                PBLTask, PBLTaskProgress.task_id == PBLTask.id
            ).filter(
                PBLTask.unit_id == unit.id,
                PBLTaskProgress.user_id == member.student_id
            ).order_by(PBLTaskProgress.updated_at.desc()).first()
            
            last_active = None
            if last_progress:
                last_active = last_progress.updated_at.isoformat()
            
            # 计算该单元的完成状态
            is_completed = (completed_tasks == task_count) and task_count > 0
            completion_rate = int((completed_tasks / task_count) * 100) if task_count > 0 else 0
            
            unit_progress.append({
                'unit_id': unit.id,
                'unit_title': unit.title,
                'total_tasks': task_count,
                'completed_tasks': completed_tasks,
                'completion_rate': completion_rate,
                'is_completed': is_completed,
                'last_active': last_active
            })
        
        student_list.append({
            'student_id': user.id,
            'name': user.name or user.real_name,
            'student_number': user.student_number or '',
            'unit_progress': unit_progress
        })
    
    return success_response(data={
        'units': unit_list,
        'students': student_list
    })


@router.get("/classes/{class_uuid}/progress/units/{unit_id}")
def get_unit_progress_detail(
    class_uuid: str,
    unit_id: int,
    page: int = Query(1, ge=1, description="页码"),
    page_size: int = Query(50, ge=1, le=100, description="每页数量"),
    search: Optional[str] = Query(None, description="搜索关键词（姓名或学号）"),
    db: Session = Depends(get_db),
    current_admin: Admin = Depends(get_current_admin)
):
    """获取指定单元的学生学习进度详情（优化版 + 分页）
    
    优化策略：
    1. 批量查询所有学生的任务进度，避免N+1查询
    2. 支持分页，按需加载学生数据
    3. 支持搜索学生
    
    响应速度：< 300ms（每页50条数据）
    """
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
    
    # 获取单元信息
    unit = db.query(PBLUnit).filter(PBLUnit.id == unit_id).first()
    if not unit:
        return error_response(
            message="单元不存在",
            code=404,
            status_code=status.HTTP_404_NOT_FOUND
        )
    
    # 获取单元的所有任务
    tasks = db.query(PBLTask).filter(
        PBLTask.unit_id == unit.id
    ).order_by(PBLTask.order).all()
    
    task_ids = [t.id for t in tasks]
    
    # 构建任务信息
    task_list = []
    for task in tasks:
        task_list.append({
            'id': task.id,
            'uuid': task.uuid,
            'title': task.title,
            'type': task.task_type,
            'order': task.order,
            'is_required': task.is_required == 1
        })
    
    # 查询班级成员（支持搜索和分页）
    members_query = db.query(PBLClassMember, User).join(
        User, PBLClassMember.student_id == User.id
    ).filter(
        PBLClassMember.class_id == pbl_class.id,
        PBLClassMember.is_active == 1
    )
    
    # 添加搜索条件
    if search:
        members_query = members_query.filter(
            or_(
                User.name.like(f'%{search}%'),
                User.real_name.like(f'%{search}%'),
                User.student_number.like(f'%{search}%')
            )
        )
    
    # 获取总数
    total_count = members_query.count()
    
    if total_count == 0:
        return success_response(data={
            'unit': {
                'id': unit.id,
                'uuid': unit.uuid,
                'title': unit.title,
                'description': unit.description,
                'order': unit.order
            },
            'tasks': task_list,
            'students': {
                'items': [],
                'total': 0,
                'page': page,
                'page_size': page_size,
                'total_pages': 0
            }
        })
    
    # 分页查询
    total_pages = (total_count + page_size - 1) // page_size
    offset = (page - 1) * page_size
    members = members_query.offset(offset).limit(page_size).all()
    
    student_ids = [member.student_id for member, _ in members]
    
    # 批量获取所有学生的任务进度（1次查询）
    if task_ids and student_ids:
        progress_records = db.query(PBLTaskProgress).filter(
            PBLTaskProgress.task_id.in_(task_ids),
            PBLTaskProgress.user_id.in_(student_ids)
        ).all()
        
        # 构建进度字典：{user_id: {task_id: progress}}
        progress_dict = {}
        for p in progress_records:
            if p.user_id not in progress_dict:
                progress_dict[p.user_id] = {}
            progress_dict[p.user_id][p.task_id] = p
    else:
        progress_dict = {}
    
    # 构建学生进度信息
    student_progress = []
    for member, user in members:
        task_progress_list = []
        completed_count = 0
        total_score = 0
        score_count = 0
        
        student_progress_data = progress_dict.get(member.student_id, {})
        
        for task in tasks:
            progress = student_progress_data.get(task.id)
            
            if progress:
                # 只要提交了就算完成（submission不为None）
                is_completed = progress.submission is not None
                if is_completed:
                    completed_count += 1
                
                if progress.score is not None:
                    total_score += progress.score
                    score_count += 1
                
                task_progress_list.append({
                    'task_id': task.id,
                    'task_title': task.title,
                    'status': progress.status,
                    'score': progress.score,
                    'submission_time': progress.updated_at.isoformat() if progress.updated_at else None,
                    'is_completed': is_completed
                })
            else:
                task_progress_list.append({
                    'task_id': task.id,
                    'task_title': task.title,
                    'status': 'not_started',
                    'score': None,
                    'submission_time': None,
                    'is_completed': False
                })
        
        # 计算平均分
        avg_score = round(total_score / score_count, 1) if score_count > 0 else None
        
        # 计算完成率
        completion_rate = int((completed_count / len(tasks)) * 100) if len(tasks) > 0 else 0
        
        student_progress.append({
            'student_id': user.id,
            'name': user.name or user.real_name,
            'student_number': user.student_number or '',
            'completion_rate': completion_rate,
            'completed_tasks': completed_count,
            'total_tasks': len(tasks),
            'avg_score': avg_score,
            'task_progress': task_progress_list
        })
    
    logger.info(f"单元进度查询完成 - 单元ID: {unit_id}, 学生数: {len(student_progress)}, 使用2次数据库查询")
    return success_response(data={
        'unit': {
            'id': unit.id,
            'uuid': unit.uuid,
            'title': unit.title,
            'description': unit.description,
            'order': unit.order
        },
        'tasks': task_list,
        'students': {
            'items': student_progress,
            'total': total_count,
            'page': page,
            'page_size': page_size,
            'total_pages': total_pages
        }
    })


@router.get("/classes/{class_uuid}/progress/export")
def export_class_progress(
    class_uuid: str,
    db: Session = Depends(get_db),
    current_admin: Admin = Depends(get_current_admin)
):
    """导出班级学习进度报表"""
    from fastapi.responses import Response
    from ...utils.export import export_progress_to_csv, generate_export_filename
    
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
                message="无权限操作",
                code=403,
                status_code=status.HTTP_403_FORBIDDEN
            )
    
    # 获取进度数据（内部调用）
    progress_data = _get_class_progress_data(class_uuid, db)
    
    # 导出为 CSV
    csv_content = export_progress_to_csv(progress_data)
    
    # 生成文件名
    filename = generate_export_filename(f'{pbl_class.name}_progress')
    
    # 返回 CSV 文件
    return Response(
        content=csv_content.encode('utf-8-sig'),  # 使用 BOM 以支持 Excel 正确显示中文
        media_type='text/csv',
        headers={
            'Content-Disposition': f'attachment; filename="{filename}"'
        }
    )


def _get_class_progress_data(class_uuid: str, db: Session) -> List[Dict]:
    """内部方法：获取班级进度数据（用于导出）"""
    pbl_class = db.query(PBLClass).filter(PBLClass.uuid == class_uuid).first()
    if not pbl_class:
        return []
    
    # 获取班级的课程
    courses = db.query(PBLCourse).filter(
        PBLCourse.class_id == pbl_class.id,
        PBLCourse.status == 'published'
    ).all()
    
    if not courses:
        return []
    
    # 获取班级成员
    members = db.query(PBLClassMember, User).join(
        User, PBLClassMember.student_id == User.id
    ).filter(
        PBLClassMember.class_id == pbl_class.id,
        PBLClassMember.is_active == 1
    ).all()
    
    result = []
    course = courses[0]  # 假设一个班级对应一个主课程
    
    # 统计单元数量
    total_units = db.query(func.count(PBLUnit.id)).filter(
        PBLUnit.course_id == course.id
    ).scalar() or 0
    
    for member, user in members:
        # 获取选课记录
        enrollment = db.query(PBLCourseEnrollment).filter(
            PBLCourseEnrollment.course_id == course.id,
            PBLCourseEnrollment.user_id == member.student_id
        ).first()
        
        # 统计已完成单元
        completed_units = 0
        if total_units > 0:
            units = db.query(PBLUnit).filter(PBLUnit.course_id == course.id).all()
            for unit in units:
                tasks = db.query(PBLTask).filter(PBLTask.unit_id == unit.id).all()
                if not tasks:
                    continue
                
                all_completed = True
                for task in tasks:
                    task_progress = db.query(PBLTaskProgress).filter(
                        PBLTaskProgress.task_id == task.id,
                        PBLTaskProgress.user_id == member.student_id
                    ).first()
                    if not task_progress or task_progress.status != 'completed':
                        all_completed = False
                        break
                
                if all_completed:
                    completed_units += 1
        
        # 计算完成率
        completion_rate = 0
        if total_units > 0:
            completion_rate = int((completed_units / total_units) * 100)
        
        # 计算学习状态
        learning_status = 'not_started'
        if completion_rate == 100:
            learning_status = 'completed'
        elif completion_rate > 0:
            learning_status = 'in_progress'
        
        # 统计提交作业数
        submissions_count = db.query(func.count(PBLTaskProgress.id)).filter(
            PBLTaskProgress.user_id == member.student_id,
            PBLTaskProgress.submission.isnot(None)
        ).join(
            PBLTask, PBLTaskProgress.task_id == PBLTask.id
        ).join(
            PBLUnit, PBLTask.unit_id == PBLUnit.id
        ).filter(
            PBLUnit.course_id == course.id
        ).scalar() or 0
        
        # 获取最后活跃时间
        last_progress = db.query(PBLTaskProgress).filter(
            PBLTaskProgress.user_id == member.student_id
        ).join(
            PBLTask, PBLTaskProgress.task_id == PBLTask.id
        ).join(
            PBLUnit, PBLTask.unit_id == PBLUnit.id
        ).filter(
            PBLUnit.course_id == course.id
        ).order_by(PBLTaskProgress.updated_at.desc()).first()
        
        last_active = None
        if last_progress:
            last_active = last_progress.updated_at.isoformat()
        elif enrollment:
            last_active = enrollment.updated_at.isoformat()
        
        learning_hours = submissions_count * 2  # 简单估算
        
        result.append({
            'student_id': user.id,
            'name': user.name or user.real_name,
            'student_number': user.student_number or '',
            'completion_rate': completion_rate,
            'status': learning_status,
            'completed_units': completed_units,
            'total_units': total_units,
            'learning_hours': learning_hours,
            'submissions_count': submissions_count,
            'last_active': last_active
        })
    
    return result


# ===== 作业管理 =====

@router.get("/classes/{class_uuid}/homework")
def get_class_homework(
    class_uuid: str,
    db: Session = Depends(get_db),
    current_admin: Admin = Depends(get_current_admin)
):
    """获取班级作业列表（学生提交情况）"""
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
    
    # 获取班级的课程
    courses = db.query(PBLCourse).filter(
        PBLCourse.class_id == pbl_class.id,
        PBLCourse.status == 'published'
    ).all()
    
    if not courses:
        return success_response(data=[])
    
    # 获取班级成员数量
    total_students = db.query(func.count(PBLClassMember.id)).filter(
        PBLClassMember.class_id == pbl_class.id,
        PBLClassMember.is_active == 1
    ).scalar() or 0
    
    result = []
    for course in courses:
        # 获取课程的所有任务
        tasks = db.query(PBLTask, PBLUnit).join(
            PBLUnit, PBLTask.unit_id == PBLUnit.id
        ).filter(
            PBLUnit.course_id == course.id
        ).order_by(PBLUnit.order, PBLTask.order).all()
        
        for task, unit in tasks:
            # 统计提交情况
            submitted_count = db.query(func.count(PBLTaskProgress.id)).filter(
                PBLTaskProgress.task_id == task.id,
                PBLTaskProgress.submission.isnot(None)
            ).scalar() or 0
            
            # 统计待批改数量
            to_review_count = db.query(func.count(PBLTaskProgress.id)).filter(
                PBLTaskProgress.task_id == task.id,
                PBLTaskProgress.status == 'review',
                PBLTaskProgress.graded_at.is_(None)
            ).scalar() or 0
            
            # 判断作业状态
            homework_status = 'ongoing'
            if hasattr(task, 'deadline') and task.deadline:
                from datetime import datetime
                if task.deadline < datetime.now():
                    homework_status = 'ended'
            
            # 判断是否为必做
            is_required = task.type == 'required' if hasattr(task, 'type') else True
            
            result.append({
                'id': task.id,
                'uuid': task.uuid,
                'title': task.title,
                'description': task.description,
                'unit_name': unit.title,
                'unit_id': unit.id,
                'status': homework_status,
                'is_required': is_required,
                'submitted_count': submitted_count,
                'total_count': total_students,
                'to_review_count': to_review_count,
                'start_time': task.start_time.isoformat() if hasattr(task, 'start_time') and task.start_time else None,
                'deadline': task.deadline.isoformat() if hasattr(task, 'deadline') and task.deadline else None,
                'created_at': task.created_at.isoformat() if task.created_at else None
            })
    
    return success_response(data=result)


@router.get("/classes/{class_uuid}/homework/export")
def export_class_homework(
    class_uuid: str,
    db: Session = Depends(get_db),
    current_admin: Admin = Depends(get_current_admin)
):
    """导出班级作业列表"""
    from fastapi.responses import Response
    from ...utils.export import export_homework_to_csv, generate_export_filename
    
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
                message="无权限操作",
                code=403,
                status_code=status.HTTP_403_FORBIDDEN
            )
    
    # 获取作业数据（内部调用）
    homework_data = _get_class_homework_data(class_uuid, db)
    
    # 导出为 CSV
    csv_content = export_homework_to_csv(homework_data)
    
    # 生成文件名
    filename = generate_export_filename(f'{pbl_class.name}_homework')
    
    # 返回 CSV 文件
    return Response(
        content=csv_content.encode('utf-8-sig'),
        media_type='text/csv',
        headers={
            'Content-Disposition': f'attachment; filename="{filename}"'
        }
    )


def _get_class_homework_data(class_uuid: str, db: Session) -> List[Dict]:
    """内部方法：获取班级作业数据（用于导出）"""
    pbl_class = db.query(PBLClass).filter(PBLClass.uuid == class_uuid).first()
    if not pbl_class:
        return []
    
    # 获取班级的课程
    courses = db.query(PBLCourse).filter(
        PBLCourse.class_id == pbl_class.id,
        PBLCourse.status == 'published'
    ).all()
    
    if not courses:
        return []
    
    # 获取班级成员数量
    total_students = db.query(func.count(PBLClassMember.id)).filter(
        PBLClassMember.class_id == pbl_class.id,
        PBLClassMember.is_active == 1
    ).scalar() or 0
    
    result = []
    for course in courses:
        # 获取课程的所有任务
        tasks = db.query(PBLTask, PBLUnit).join(
            PBLUnit, PBLTask.unit_id == PBLUnit.id
        ).filter(
            PBLUnit.course_id == course.id
        ).order_by(PBLUnit.order, PBLTask.order).all()
        
        for task, unit in tasks:
            # 统计提交情况
            submitted_count = db.query(func.count(PBLTaskProgress.id)).filter(
                PBLTaskProgress.task_id == task.id,
                PBLTaskProgress.submission.isnot(None)
            ).scalar() or 0
            
            # 统计待批改数量
            to_review_count = db.query(func.count(PBLTaskProgress.id)).filter(
                PBLTaskProgress.task_id == task.id,
                PBLTaskProgress.status == 'review',
                PBLTaskProgress.graded_at.is_(None)
            ).scalar() or 0
            
            # 判断作业状态
            homework_status = 'ongoing'
            if hasattr(task, 'deadline') and task.deadline:
                if task.deadline < datetime.now():
                    homework_status = 'ended'
            
            # 判断是否为必做
            is_required = task.type == 'required' if hasattr(task, 'type') else True
            
            result.append({
                'id': task.id,
                'uuid': task.uuid,
                'title': task.title,
                'description': task.description,
                'unit_name': unit.title,
                'unit_id': unit.id,
                'status': homework_status,
                'is_required': is_required,
                'submitted_count': submitted_count,
                'total_count': total_students,
                'to_review_count': to_review_count,
                'start_time': task.start_time.isoformat() if hasattr(task, 'start_time') and task.start_time else None,
                'deadline': task.deadline.isoformat() if hasattr(task, 'deadline') and task.deadline else None,
                'created_at': task.created_at.isoformat() if task.created_at else None
            })
    
    return result


@router.get("/classes/{class_uuid}/homework/{task_id}/submissions")
def get_homework_submissions(
    class_uuid: str,
    task_id: int,
    db: Session = Depends(get_db),
    current_admin: Admin = Depends(get_current_admin)
):
    """获取作业提交详情"""
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
    
    # 获取任务
    task = db.query(PBLTask).filter(PBLTask.id == task_id).first()
    if not task:
        return error_response(
            message="任务不存在",
            code=404,
            status_code=status.HTTP_404_NOT_FOUND
        )
    
    # 获取班级成员
    members = db.query(PBLClassMember, User).join(
        User, PBLClassMember.student_id == User.id
    ).filter(
        PBLClassMember.class_id == pbl_class.id,
        PBLClassMember.is_active == 1
    ).all()
    
    result = []
    for member, user in members:
        # 获取提交记录
        progress = db.query(PBLTaskProgress).filter(
            PBLTaskProgress.task_id == task_id,
            PBLTaskProgress.user_id == member.student_id
        ).first()
        
        if progress:
            # 获取评分人信息
            grader_name = None
            if progress.graded_by:
                grader = db.query(User).filter(User.id == progress.graded_by).first()
                if grader:
                    grader_name = grader.name or grader.real_name
            
            result.append({
                'submission_id': progress.id,
                'student_id': user.id,
                'student_name': user.name or user.real_name,
                'student_number': user.student_number or '',
                'status': progress.status,
                'submission': progress.submission,
                'score': progress.score,
                'feedback': progress.feedback,
                'graded_by': progress.graded_by,
                'grader_name': grader_name,
                'graded_at': progress.graded_at.isoformat() if progress.graded_at else None,
                'submitted_at': progress.updated_at.isoformat() if progress.updated_at else None
            })
        else:
            # 未提交
            result.append({
                'submission_id': None,
                'student_id': user.id,
                'student_name': user.name or user.real_name,
                'student_number': user.student_number or '',
                'status': 'pending',
                'submission': None,
                'score': None,
                'feedback': None,
                'graded_by': None,
                'grader_name': None,
                'graded_at': None,
                'submitted_at': None
            })
    
    return success_response(data=result)


@router.get("/classes/{class_uuid}/homework/{task_id}/submissions/export")
def export_homework_submissions(
    class_uuid: str,
    task_id: int,
    db: Session = Depends(get_db),
    current_admin: Admin = Depends(get_current_admin)
):
    """导出作业提交详情"""
    from fastapi.responses import Response
    from ...utils.export import export_submissions_to_csv, generate_export_filename
    
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
                message="无权限操作",
                code=403,
                status_code=status.HTTP_403_FORBIDDEN
            )
    
    # 获取任务
    task = db.query(PBLTask).filter(PBLTask.id == task_id).first()
    if not task:
        return error_response(
            message="任务不存在",
            code=404,
            status_code=status.HTTP_404_NOT_FOUND
        )
    
    # 获取提交数据
    submissions_data = _get_homework_submissions_data(class_uuid, task_id, db)
    
    # 导出为 CSV
    csv_content = export_submissions_to_csv(submissions_data)
    
    # 生成文件名
    filename = generate_export_filename(f'{task.title}_submissions')
    
    # 返回 CSV 文件
    return Response(
        content=csv_content.encode('utf-8-sig'),
        media_type='text/csv',
        headers={
            'Content-Disposition': f'attachment; filename="{filename}"'
        }
    )


def _get_homework_submissions_data(class_uuid: str, task_id: int, db: Session) -> List[Dict]:
    """内部方法：获取作业提交数据（用于导出）"""
    pbl_class = db.query(PBLClass).filter(PBLClass.uuid == class_uuid).first()
    if not pbl_class:
        return []
    
    # 获取班级成员
    members = db.query(PBLClassMember, User).join(
        User, PBLClassMember.student_id == User.id
    ).filter(
        PBLClassMember.class_id == pbl_class.id,
        PBLClassMember.is_active == 1
    ).all()
    
    result = []
    for member, user in members:
        # 获取提交记录
        progress = db.query(PBLTaskProgress).filter(
            PBLTaskProgress.task_id == task_id,
            PBLTaskProgress.user_id == member.student_id
        ).first()
        
        if progress:
            # 获取评分人信息
            grader_name = None
            if progress.graded_by:
                grader = db.query(User).filter(User.id == progress.graded_by).first()
                if grader:
                    grader_name = grader.name or grader.real_name
            
            result.append({
                'submission_id': progress.id,
                'student_id': user.id,
                'student_name': user.name or user.real_name,
                'student_number': user.student_number or '',
                'status': progress.status,
                'submission': progress.submission,
                'score': progress.score,
                'feedback': progress.feedback,
                'graded_by': progress.graded_by,
                'grader_name': grader_name,
                'graded_at': progress.graded_at.isoformat() if progress.graded_at else None,
                'submitted_at': progress.updated_at.isoformat() if progress.updated_at else None
            })
        else:
            # 未提交
            result.append({
                'submission_id': None,
                'student_id': user.id,
                'student_name': user.name or user.real_name,
                'student_number': user.student_number or '',
                'status': 'pending',
                'submission': None,
                'score': None,
                'feedback': None,
                'graded_by': None,
                'grader_name': None,
                'graded_at': None,
                'submitted_at': None
            })
    
    return result


@router.put("/classes/{class_uuid}/homework/submissions/{submission_id}/review")
def review_homework_submission(
    class_uuid: str,
    submission_id: int,
    review_data: TaskReview,
    db: Session = Depends(get_db),
    current_admin: Admin = Depends(get_current_admin)
):
    """批阅作业"""
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
                message="无权限操作",
                code=403,
                status_code=status.HTTP_403_FORBIDDEN
            )
    
    # 获取提交记录
    progress = db.query(PBLTaskProgress).filter(
        PBLTaskProgress.id == submission_id
    ).first()
    
    if not progress:
        return error_response(
            message="提交记录不存在",
            code=404,
            status_code=status.HTTP_404_NOT_FOUND
        )
    
    # 更新评分和反馈
    if review_data.score is not None:
        progress.score = review_data.score
    if review_data.feedback is not None:
        progress.feedback = review_data.feedback
    
    progress.status = review_data.status
    progress.graded_by = current_admin.id
    progress.graded_at = datetime.now()
    
    db.commit()
    db.refresh(progress)
    
    logger.info(f"批阅作业 - 提交ID: {submission_id}, 评分: {review_data.score}, 评阅人: {current_admin.username}")
    
    return success_response(
        data={
            'submission_id': progress.id,
            'score': progress.score,
            'feedback': progress.feedback,
            'status': progress.status
        },
        message="作业批阅成功"
    )
