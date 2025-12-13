"""
学生端社团班课程系统API
- 查看自己的班级列表
- 查看自己的课程列表
- 加入开放的班级
"""
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from sqlalchemy import func
from typing import List, Optional
from datetime import datetime
from app.utils.timezone import get_beijing_time_naive
from pydantic import BaseModel

from ...db.session import SessionLocal
from ...core.response import success_response, error_response
from ...core.deps import get_db, get_current_user
from ...models.admin import User
from ...models.pbl import (
    PBLClass, PBLClassMember, PBLCourse
)
from ...core.logging_config import get_logger

router = APIRouter()
logger = get_logger(__name__)

# ===== Pydantic 模型 =====

class JoinClassRequest(BaseModel):
    class_id: int

# ===== 学生班级 =====

@router.get("/my-classes")
def get_my_classes(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """获取学生自己的班级列表"""
    # 查询学生所在的班级
    memberships = db.query(PBLClassMember, PBLClass).join(
        PBLClass, PBLClassMember.class_id == PBLClass.id
    ).filter(
        PBLClassMember.student_id == current_user.id,
        PBLClassMember.is_active == 1,
        PBLClass.is_active == 1
    ).all()
    
    result = []
    for membership, cls in memberships:
        result.append({
            'id': cls.id,
            'uuid': cls.uuid,
            'name': cls.name,
            'class_type': cls.class_type,
            'description': cls.description,
            'role': membership.role,
            'joined_at': membership.joined_at.isoformat() if membership.joined_at else None,
            'current_members': cls.current_members,
            'max_students': cls.max_students
        })
    
    return success_response(data=result)


@router.get("/my-courses")
def get_my_courses(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """获取学生自己的课程列表"""
    # 查询学生所在班级的所有已发布课程
    class_members = db.query(PBLClassMember).filter(
        PBLClassMember.student_id == current_user.id,
        PBLClassMember.is_active == 1
    ).all()
    
    if not class_members:
        return success_response(data=[])
    
    # 获取所有班级ID
    class_ids = [cm.class_id for cm in class_members]
    
    # 查询这些班级的所有已发布课程
    courses = db.query(PBLCourse).filter(
        PBLCourse.class_id.in_(class_ids),
        PBLCourse.status == 'published'
    ).all()

    result = []
    for course in courses:
        result.append({
            'id': course.id,
            'uuid': course.uuid,
            'title': course.title,
            'description': course.description,
            'cover_image': course.cover_image,
            'class_name': course.class_name,
            'difficulty': course.difficulty,
            'status': 'published',  # 课程状态
            'progress': 0  # 进度需要从 pbl_learning_progress 表计算
        })
    
    return success_response(data=result)


@router.get("/available-classes")
def get_available_classes(
    class_type: Optional[str] = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """获取可加入的班级列表（开放加入的班级）"""
    query = db.query(PBLClass).filter(
        PBLClass.school_id == current_user.school_id,
        PBLClass.is_active == 1,
        PBLClass.is_open == 1
    )
    
    if class_type:
        query = query.filter(PBLClass.class_type == class_type)
    
    classes = query.order_by(PBLClass.created_at.desc()).all()
    
    result = []
    for cls in classes:
        # 检查学生是否已在班级中
        is_member = db.query(PBLClassMember).filter(
            PBLClassMember.class_id == cls.id,
            PBLClassMember.student_id == current_user.id,
            PBLClassMember.is_active == 1
        ).first() is not None
        
        # 检查班级是否已满
        is_full = cls.current_members >= cls.max_students if cls.max_students > 0 else False
        
        result.append({
            'id': cls.id,
            'uuid': cls.uuid,
            'name': cls.name,
            'class_type': cls.class_type,
            'description': cls.description,
            'current_members': cls.current_members,
            'max_students': cls.max_students,
            'is_member': is_member,
            'is_full': is_full,
            'can_join': not is_member and not is_full
        })
    
    return success_response(data=result)


@router.post("/join-class")
def join_class(
    request: JoinClassRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """学生加入开放的班级"""
    # 检查班级是否存在
    pbl_class = db.query(PBLClass).filter(PBLClass.id == request.class_id).first()
    if not pbl_class:
        return error_response(
            message="班级不存在",
            code=404,
            status_code=status.HTTP_404_NOT_FOUND
        )
    
    # 检查班级是否开放加入
    if pbl_class.is_open != 1:
        return error_response(
            message="该班级未开放加入",
            code=400,
            status_code=status.HTTP_400_BAD_REQUEST
        )
    
    # 检查是否是同一学校
    if pbl_class.school_id != current_user.school_id:
        return error_response(
            message="只能加入本校班级",
            code=403,
            status_code=status.HTTP_403_FORBIDDEN
        )
    
    # 检查是否已在班级中
    existing = db.query(PBLClassMember).filter(
        PBLClassMember.class_id == pbl_class.id,
        PBLClassMember.student_id == current_user.id,
        PBLClassMember.is_active == 1
    ).first()
    
    if existing:
        return error_response(
            message="您已在该班级中",
            code=400,
            status_code=status.HTTP_400_BAD_REQUEST
        )
    
    # 检查班级是否已满
    if pbl_class.max_students > 0 and pbl_class.current_members >= pbl_class.max_students:
        return error_response(
            message="班级人数已满",
            code=400,
            status_code=status.HTTP_400_BAD_REQUEST
        )
    
    # 加入班级
    member = PBLClassMember(
        class_id=pbl_class.id,
        student_id=current_user.id,
        role='member',
        is_active=1
    )
    db.add(member)
    
    # 自动为该学生选上班级的所有课程
    courses = db.query(PBLCourse).filter(
        PBLCourse.class_id == pbl_class.id,
        PBLCourse.status == 'published'
    ).all()
    
    # 注意：班级成员自动拥有班级课程的访问权限，无需创建选课记录
    enrolled_courses = []
    for course in courses:
        enrolled_courses.append({
            db.add(enrollment)
            enrolled_courses.append(course.id)
    
    db.commit()
    
    logger.info(f"学生加入班级 - 学生ID: {current_user.id}, 班级ID: {pbl_class.id}")
    
    return success_response(
        data={
            'class_id': pbl_class.id,
            'enrolled_courses': enrolled_courses
        },
        message=f"成功加入班级，已自动选上 {len(enrolled_courses)} 门课程"
    )


@router.get("/class/{class_uuid}")
def get_class_detail(
    class_uuid: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """获取班级详情（学生视角）"""
    pbl_class = db.query(PBLClass).filter(PBLClass.uuid == class_uuid).first()
    if not pbl_class:
        return error_response(
            message="班级不存在",
            code=404,
            status_code=status.HTTP_404_NOT_FOUND
        )
    
    # 检查学生是否在班级中
    membership = db.query(PBLClassMember).filter(
        PBLClassMember.class_id == pbl_class.id,
        PBLClassMember.student_id == current_user.id,
        PBLClassMember.is_active == 1
    ).first()
    
    if not membership:
        return error_response(
            message="您不在该班级中",
            code=403,
            status_code=status.HTTP_403_FORBIDDEN
        )
    
    # 获取班级课程
    courses = db.query(PBLCourse).filter(
        PBLCourse.class_id == pbl_class.id,
        PBLCourse.status == 'published'
    ).all()
    
    course_list = []
    for course in courses:
        course_list.append({
            'id': course.id,
            'uuid': course.uuid,
            'title': course.title,
            'description': course.description,
            'cover_image': course.cover_image,
            'difficulty': course.difficulty,
            'progress': 0,  # 进度需要从 pbl_learning_progress 表计算
            'status': 'published'  # 课程状态
        })
    
    return success_response(data={
        'id': pbl_class.id,
        'uuid': pbl_class.uuid,
        'name': pbl_class.name,
        'class_type': pbl_class.class_type,
        'description': pbl_class.description,
        'current_members': pbl_class.current_members,
        'max_students': pbl_class.max_students,
        'my_role': membership.role,
        'joined_at': membership.joined_at.isoformat() if membership.joined_at else None,
        'courses': course_list
    })
