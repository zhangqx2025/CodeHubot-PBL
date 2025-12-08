from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List, Optional
from datetime import datetime

from ...db.session import SessionLocal
from ...core.response import success_response, error_response
from ...core.deps import get_db, get_current_admin
from ...models.admin import Admin, User
from ...models.pbl import PBLClass, PBLGroup, PBLGroupMember
from ...core.logging_config import get_logger

router = APIRouter()
logger = get_logger(__name__)

# ===== 班级管理 =====

@router.get("/classes")
def get_classes(
    school_id: Optional[int] = None,
    db: Session = Depends(get_db),
    current_admin: Admin = Depends(get_current_admin)
):
    """获取班级列表"""
    # 权限控制
    if current_admin.role != 'platform_admin':
        school_id = current_admin.school_id
    
    # 查询班级
    query = db.query(PBLClass).filter(PBLClass.is_active == True)
    if school_id:
        query = query.filter(PBLClass.school_id == school_id)
    
    classes = query.all()
    
    result = []
    for cls in classes:
        # 统计班级学生数
        student_count = db.query(User).filter(
            User.class_id == cls.id,
            User.role == 'student',
            User.deleted_at == None
        ).count()
        
        result.append({
            'id': cls.id,
            'uuid': cls.uuid,
            'name': cls.name,
            'grade': cls.grade,
            'school_id': cls.school_id,
            'academic_year': cls.academic_year,
            'class_teacher_id': cls.class_teacher_id,
            'max_students': cls.max_students,
            'student_count': student_count,
            'created_at': cls.created_at.isoformat() if cls.created_at else None
        })
    
    return success_response(data=result)

@router.post("/classes")
def create_class(
    name: str,
    grade: Optional[str] = None,
    school_id: Optional[int] = None,
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
    
    # 学校管理员只能创建本校班级
    if current_admin.role == 'school_admin':
        school_id = current_admin.school_id
    
    if not school_id:
        return error_response(
            message="必须指定学校ID",
            code=400,
            status_code=status.HTTP_400_BAD_REQUEST
        )
    
    # 创建班级记录
    new_class = PBLClass(
        school_id=school_id,
        name=name,
        grade=grade,
        is_active=True
    )
    db.add(new_class)
    db.commit()
    db.refresh(new_class)
    
    logger.info(f"创建班级 - 名称: {name}, 学校ID: {school_id}, 操作者: {current_admin.username}")
    
    return success_response(
        data={
            'id': new_class.id,
            'uuid': new_class.uuid,
            'name': new_class.name,
            'grade': new_class.grade,
            'school_id': new_class.school_id,
            'created_at': new_class.created_at.isoformat() if new_class.created_at else None
        },
        message="班级创建成功"
    )

@router.get("/classes/{class_id}/students")
def get_class_students(
    class_id: int,
    db: Session = Depends(get_db),
    current_admin: Admin = Depends(get_current_admin)
):
    """获取班级学生列表"""
    # 查询班级中的学生
    students = db.query(User).filter(
        User.class_id == class_id,
        User.role == 'student',
        User.deleted_at == None
    ).all()
    
    # 权限检查（学校管理员只能查看本校班级）
    if current_admin.role != 'platform_admin' and students:
        if students[0].school_id != current_admin.school_id:
            return error_response(
                message="无权限查看该班级",
                code=403,
                status_code=status.HTTP_403_FORBIDDEN
            )
    
    result = []
    for student in students:
        result.append({
            'id': student.id,
            'username': student.username,
            'name': student.name or student.real_name,
            'student_number': student.student_number,
            'gender': student.gender,
            'phone': student.phone,
            'email': student.email
        })
    
    return success_response(data=result)

@router.post("/classes/{class_id}/add-students")
def add_students_to_class(
    class_id: int,
    student_ids: List[int],
    db: Session = Depends(get_db),
    current_admin: Admin = Depends(get_current_admin)
):
    """批量添加学生到班级"""
    # 权限检查
    if current_admin.role not in ['platform_admin', 'school_admin']:
        return error_response(
            message="无权限操作",
            code=403,
            status_code=status.HTTP_403_FORBIDDEN
        )
    
    success_count = 0
    for student_id in student_ids:
        student = db.query(User).filter(
            User.id == student_id,
            User.role == 'student'
        ).first()
        
        if student:
            # 权限检查：学校管理员只能操作本校学生
            if current_admin.role == 'school_admin':
                if student.school_id != current_admin.school_id:
                    continue
            
            student.class_id = class_id
            success_count += 1
    
    db.commit()
    
    logger.info(f"添加学生到班级 - 班级ID: {class_id}, 成功: {success_count}, 操作者: {current_admin.username}")
    
    return success_response(
        data={'added_count': success_count},
        message=f"成功添加 {success_count} 名学生到班级"
    )

# ===== 小组管理 =====

@router.get("/groups")
def get_groups(
    class_id: Optional[int] = None,
    course_id: Optional[int] = None,
    db: Session = Depends(get_db),
    current_admin: Admin = Depends(get_current_admin)
):
    """获取小组列表"""
    # 查询小组
    query = db.query(PBLGroup).filter(PBLGroup.is_active == True)
    
    if class_id:
        query = query.filter(PBLGroup.class_id == class_id)
    if course_id:
        query = query.filter(PBLGroup.course_id == course_id)
    
    groups = query.all()
    
    result = []
    for group in groups:
        # 统计小组成员数
        member_count = db.query(PBLGroupMember).filter(
            PBLGroupMember.group_id == group.id,
            PBLGroupMember.is_active == True
        ).count()
        
        # 获取组长信息
        leader = None
        if group.leader_id:
            leader_user = db.query(User).filter(User.id == group.leader_id).first()
            if leader_user:
                leader = {
                    'id': leader_user.id,
                    'name': leader_user.name or leader_user.real_name
                }
        
        result.append({
            'id': group.id,
            'uuid': group.uuid,
            'name': group.name,
            'description': group.description,
            'class_id': group.class_id,
            'course_id': group.course_id,
            'leader': leader,
            'max_members': group.max_members,
            'member_count': member_count,
            'created_at': group.created_at.isoformat() if group.created_at else None
        })
    
    return success_response(data=result)

@router.post("/groups")
def create_group(
    name: str,
    class_id: Optional[int] = None,
    course_id: Optional[int] = None,
    max_members: int = 6,
    db: Session = Depends(get_db),
    current_admin: Admin = Depends(get_current_admin)
):
    """创建小组"""
    # 权限检查
    if current_admin.role not in ['platform_admin', 'school_admin', 'teacher']:
        return error_response(
            message="无权限操作",
            code=403,
            status_code=status.HTTP_403_FORBIDDEN
        )
    
    # 创建小组记录
    new_group = PBLGroup(
        name=name,
        class_id=class_id,
        course_id=course_id,
        max_members=max_members,
        is_active=True
    )
    db.add(new_group)
    db.commit()
    db.refresh(new_group)
    
    logger.info(f"创建小组 - 名称: {name}, 班级ID: {class_id}, 操作者: {current_admin.username}")
    
    return success_response(
        data={
            'id': new_group.id,
            'uuid': new_group.uuid,
            'name': new_group.name,
            'class_id': new_group.class_id,
            'course_id': new_group.course_id,
            'max_members': new_group.max_members,
            'created_at': new_group.created_at.isoformat() if new_group.created_at else None
        },
        message="小组创建成功"
    )

@router.get("/groups/{group_id}/members")
def get_group_members(
    group_id: str,
    db: Session = Depends(get_db),
    current_admin: Admin = Depends(get_current_admin)
):
    """获取小组成员列表"""
    # 查询小组
    group = db.query(PBLGroup).filter(PBLGroup.uuid == group_id).first()
    if not group:
        return error_response(
            message="小组不存在",
            code=404,
            status_code=status.HTTP_404_NOT_FOUND
        )
    
    # 查询小组成员
    group_members = db.query(PBLGroupMember).filter(
        PBLGroupMember.group_id == group.id,
        PBLGroupMember.is_active == True
    ).all()
    
    result = []
    for gm in group_members:
        member = db.query(User).filter(
            User.id == gm.user_id,
            User.deleted_at == None
        ).first()
        
        if member:
            result.append({
                'id': member.id,
                'username': member.username,
                'name': member.name or member.real_name,
                'student_number': member.student_number,
                'gender': member.gender,
                'role': gm.role,
                'joined_at': gm.joined_at.isoformat() if gm.joined_at else None
            })
    
    return success_response(data=result)

@router.post("/groups/{group_id}/add-members")
def add_members_to_group(
    group_id: str,
    student_ids: List[int],
    db: Session = Depends(get_db),
    current_admin: Admin = Depends(get_current_admin)
):
    """批量添加成员到小组"""
    # 权限检查
    if current_admin.role not in ['platform_admin', 'school_admin', 'teacher']:
        return error_response(
            message="无权限操作",
            code=403,
            status_code=status.HTTP_403_FORBIDDEN
        )
    
    # 检查小组是否存在
    group = db.query(PBLGroup).filter(PBLGroup.uuid == group_id).first()
    if not group:
        return error_response(
            message="小组不存在",
            code=404,
            status_code=status.HTTP_404_NOT_FOUND
        )
    
    success_count = 0
    for student_id in student_ids:
        student = db.query(User).filter(
            User.id == student_id,
            User.role == 'student'
        ).first()
        
        if not student:
            continue
        
        # 权限检查
        if current_admin.role == 'school_admin':
            if student.school_id != current_admin.school_id:
                continue
        
        # 检查是否已经在小组中
        existing_member = db.query(PBLGroupMember).filter(
            PBLGroupMember.group_id == group.id,
            PBLGroupMember.user_id == student_id,
            PBLGroupMember.is_active == True
        ).first()
        
        if existing_member:
            continue
        
        # 添加成员
        member = PBLGroupMember(
            group_id=group.id,
            user_id=student_id,
            role='member',
            is_active=True
        )
        db.add(member)
        success_count += 1
    
    db.commit()
    
    logger.info(f"添加成员到小组 - 小组UUID: {group_id}, 成功: {success_count}, 操作者: {current_admin.username}")
    
    return success_response(
        data={'added_count': success_count},
        message=f"成功添加 {success_count} 名成员到小组"
    )

@router.delete("/groups/{group_id}/members/{student_id}")
def remove_member_from_group(
    group_id: str,
    student_id: int,
    db: Session = Depends(get_db),
    current_admin: Admin = Depends(get_current_admin)
):
    """从小组移除成员"""
    # 查询小组
    group = db.query(PBLGroup).filter(PBLGroup.uuid == group_id).first()
    if not group:
        return error_response(
            message="小组不存在",
            code=404,
            status_code=status.HTTP_404_NOT_FOUND
        )
    
    # 查找小组成员记录
    member = db.query(PBLGroupMember).filter(
        PBLGroupMember.group_id == group.id,
        PBLGroupMember.user_id == student_id,
        PBLGroupMember.is_active == True
    ).first()
    
    if not member:
        return error_response(
            message="学生不在该小组中",
            code=404,
            status_code=status.HTTP_404_NOT_FOUND
        )
    
    # 权限检查
    if current_admin.role not in ['platform_admin', 'school_admin', 'teacher']:
        return error_response(
            message="无权限操作",
            code=403,
            status_code=status.HTTP_403_FORBIDDEN
        )
    
    # 将成员标记为非激活状态（软删除）
    member.is_active = False
    db.commit()
    
    logger.info(f"从小组移除成员 - 小组UUID: {group_id}, 学生ID: {student_id}, 操作者: {current_admin.username}")
    
    return success_response(message="成员已从小组移除")
