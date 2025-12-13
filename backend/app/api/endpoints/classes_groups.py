from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from sqlalchemy import func, and_, or_
from typing import List, Optional
from datetime import datetime
from app.utils.timezone import get_beijing_time_naive

from ...db.session import SessionLocal
from ...core.response import success_response, error_response
from ...core.deps import get_db, get_current_admin
from ...models.admin import Admin, User
from ...models.pbl import (
    PBLClass, PBLGroup, PBLGroupMember, PBLClassMember,
    PBLClassTeacher, PBLClassCourse, PBLCourse,
    PBLLearningProgress,
    PBLTaskProgress, PBLTask, PBLUnit
)
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
    db: Session = Depends(get_db),
    current_admin: Admin = Depends(get_current_admin)
):
    """创建班级
    
    学校ID自动从当前登录管理员中获取，无需前端传递
    """
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
    class_id: str,
    db: Session = Depends(get_db),
    current_admin: Admin = Depends(get_current_admin)
):
    """获取班级学生列表"""
    # 根据UUID查询班级
    pbl_class = db.query(PBLClass).filter(PBLClass.uuid == class_id).first()
    if not pbl_class:
        return error_response(
            message="班级不存在",
            code=404,
            status_code=status.HTTP_404_NOT_FOUND
        )
    
    # 权限检查（学校管理员只能查看本校班级）
    if current_admin.role != 'platform_admin':
        if pbl_class.school_id != current_admin.school_id:
            return error_response(
                message="无权限查看该班级",
                code=403,
                status_code=status.HTTP_403_FORBIDDEN
            )
    
    # 查询班级中的学生
    students = db.query(User).filter(
        User.class_id == pbl_class.id,
        User.role == 'student',
        User.deleted_at == None
    ).all()
    
    result = []
    for student in students:
        # 性别转换
        gender_display = ''
        if student.gender == 'male':
            gender_display = '男'
        elif student.gender == 'female':
            gender_display = '女'
        else:
            gender_display = student.gender or ''
        
        result.append({
            'id': student.id,
            'username': student.username,
            'name': student.name or student.real_name,
            'student_number': student.student_number,
            'gender': gender_display
        })
    
    return success_response(data=result)

@router.post("/classes/{class_id}/add-students")
def add_students_to_class(
    class_id: str,
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
    
    # 根据UUID查询班级
    pbl_class = db.query(PBLClass).filter(PBLClass.uuid == class_id).first()
    if not pbl_class:
        return error_response(
            message="班级不存在",
            code=404,
            status_code=status.HTTP_404_NOT_FOUND
        )
    
    # 权限检查（学校管理员只能操作本校班级）
    if current_admin.role == 'school_admin':
        if pbl_class.school_id != current_admin.school_id:
            return error_response(
                message="无权限操作该班级",
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
            
            student.class_id = pbl_class.id
            success_count += 1
    
    db.commit()
    
    logger.info(f"添加学生到班级 - 班级UUID: {class_id}, 成功: {success_count}, 操作者: {current_admin.username}")
    
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

@router.get("/groups/{group_id}/available-students")
def get_available_students_for_group(
    group_id: str,
    keyword: Optional[str] = None,
    db: Session = Depends(get_db),
    current_admin: Admin = Depends(get_current_admin)
):
    """获取小组可添加的学生列表（班级中未分组的学生）"""
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
    
    # 必须有班级ID
    if not group.class_id:
        return success_response(data=[])
    
    # 查询该班级的所有学生
    query = db.query(User).filter(
        User.class_id == group.class_id,
        User.role == 'student',
        User.deleted_at == None
    )
    
    # 权限检查：学校管理员只能看本校学生
    if current_admin.role == 'school_admin':
        query = query.filter(User.school_id == current_admin.school_id)
    
    # 关键词搜索
    if keyword:
        keyword_pattern = f"%{keyword}%"
        query = query.filter(
            or_(
                User.name.like(keyword_pattern),
                User.real_name.like(keyword_pattern),
                User.student_number.like(keyword_pattern)
            )
        )
    
    class_students = query.all()
    
    # 获取已经在小组中的学生ID列表
    grouped_student_ids = db.query(PBLGroupMember.user_id).filter(
        PBLGroupMember.group_id == group.id,
        PBLGroupMember.is_active == True
    ).all()
    grouped_student_ids = [sid[0] for sid in grouped_student_ids]
    
    # 过滤出未分组的学生
    result = []
    for student in class_students:
        if student.id not in grouped_student_ids:
            result.append({
                'id': student.id,
                'username': student.username,
                'name': student.name or student.real_name,
                'student_number': student.student_number,
                'gender': student.gender
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

@router.delete("/groups/{group_id}")
def delete_group(
    group_id: str,
    db: Session = Depends(get_db),
    current_admin: Admin = Depends(get_current_admin)
):
    """删除小组"""
    # 权限检查
    if current_admin.role not in ['platform_admin', 'school_admin', 'teacher']:
        return error_response(
            message="无权限操作",
            code=403,
            status_code=status.HTTP_403_FORBIDDEN
        )
    
    # 查询小组
    group = db.query(PBLGroup).filter(PBLGroup.uuid == group_id).first()
    if not group:
        return error_response(
            message="小组不存在",
            code=404,
            status_code=status.HTTP_404_NOT_FOUND
        )
    
    # 软删除小组（标记为非激活状态）
    group.is_active = False
    
    # 同时软删除所有小组成员
    db.query(PBLGroupMember).filter(
        PBLGroupMember.group_id == group.id
    ).update({'is_active': False})
    
    db.commit()
    
    logger.info(f"删除小组 - 小组UUID: {group_id}, 操作者: {current_admin.username}")
    
    return success_response(message="小组已删除")


# ===== 班级教师管理 =====

@router.get("/classes/{class_id}/teachers")
def get_class_teachers(
    class_id: str,
    db: Session = Depends(get_db),
    current_admin: Admin = Depends(get_current_admin)
):
    """获取班级教师列表"""
    # 根据UUID查询班级
    pbl_class = db.query(PBLClass).filter(PBLClass.uuid == class_id).first()
    if not pbl_class:
        return error_response(
            message="班级不存在",
            code=404,
            status_code=status.HTTP_404_NOT_FOUND
        )
    
    # 权限检查（学校管理员只能查看本校班级）
    if current_admin.role != 'platform_admin':
        if pbl_class.school_id != current_admin.school_id:
            return error_response(
                message="无权限查看该班级",
                code=403,
                status_code=status.HTTP_403_FORBIDDEN
            )
    
    # 查询班级教师
    class_teachers = db.query(PBLClassTeacher).filter(
        PBLClassTeacher.class_id == pbl_class.id
    ).all()
    
    result = []
    for ct in class_teachers:
        teacher = db.query(User).filter(User.id == ct.teacher_id).first()
        if teacher:
            result.append({
                'id': ct.id,
                'teacher_id': teacher.id,
                'teacher_name': teacher.name or teacher.real_name,
                'teacher_number': teacher.teacher_number,
                'subject': ct.subject,
                'is_primary': ct.is_primary == 1,
                'created_at': ct.created_at.isoformat() if ct.created_at else None
            })
    
    return success_response(data=result)


@router.post("/classes/{class_id}/teachers")
def assign_teacher_to_class(
    class_id: str,
    teacher_id: int,
    subject: Optional[str] = None,
    is_primary: bool = False,
    db: Session = Depends(get_db),
    current_admin: Admin = Depends(get_current_admin)
):
    """为班级分配教师"""
    # 权限检查
    if current_admin.role not in ['platform_admin', 'school_admin']:
        return error_response(
            message="无权限操作",
            code=403,
            status_code=status.HTTP_403_FORBIDDEN
        )
    
    # 根据UUID查询班级
    pbl_class = db.query(PBLClass).filter(PBLClass.uuid == class_id).first()
    if not pbl_class:
        return error_response(
            message="班级不存在",
            code=404,
            status_code=status.HTTP_404_NOT_FOUND
        )
    
    # 权限检查（学校管理员只能操作本校班级）
    if current_admin.role == 'school_admin':
        if pbl_class.school_id != current_admin.school_id:
            return error_response(
                message="无权限操作该班级",
                code=403,
                status_code=status.HTTP_403_FORBIDDEN
            )
    
    # 验证教师存在且是教师角色
    teacher = db.query(User).filter(
        User.id == teacher_id,
        User.role == 'teacher'
    ).first()
    
    if not teacher:
        return error_response(
            message="教师不存在",
            code=404,
            status_code=status.HTTP_404_NOT_FOUND
        )
    
    # 检查是否已经分配
    existing = db.query(PBLClassTeacher).filter(
        PBLClassTeacher.class_id == pbl_class.id,
        PBLClassTeacher.teacher_id == teacher_id
    ).first()
    
    if existing:
        return error_response(
            message="该教师已分配到此班级",
            code=400,
            status_code=status.HTTP_400_BAD_REQUEST
        )
    
    # 如果设置为班主任，先取消其他班主任
    if is_primary:
        db.query(PBLClassTeacher).filter(
            PBLClassTeacher.class_id == pbl_class.id,
            PBLClassTeacher.is_primary == 1
        ).update({'is_primary': 0})
        
        # 同时更新班级表的class_teacher_id
        pbl_class.class_teacher_id = teacher_id
    
    # 创建班级教师关联记录
    class_teacher = PBLClassTeacher(
        class_id=pbl_class.id,
        teacher_id=teacher_id,
        subject=subject,
        is_primary=1 if is_primary else 0
    )
    db.add(class_teacher)
    db.commit()
    db.refresh(class_teacher)
    
    logger.info(f"为班级分配教师 - 班级UUID: {class_id}, 教师ID: {teacher_id}, 操作者: {current_admin.username}")
    
    return success_response(
        data={
            'id': class_teacher.id,
            'teacher_id': teacher_id,
            'teacher_name': teacher.name or teacher.real_name,
            'subject': subject,
            'is_primary': is_primary
        },
        message="教师分配成功"
    )


@router.delete("/classes/{class_id}/teachers/{teacher_id}")
def remove_teacher_from_class(
    class_id: str,
    teacher_id: int,
    db: Session = Depends(get_db),
    current_admin: Admin = Depends(get_current_admin)
):
    """从班级移除教师"""
    # 权限检查
    if current_admin.role not in ['platform_admin', 'school_admin']:
        return error_response(
            message="无权限操作",
            code=403,
            status_code=status.HTTP_403_FORBIDDEN
        )
    
    # 根据UUID查询班级
    pbl_class = db.query(PBLClass).filter(PBLClass.uuid == class_id).first()
    if not pbl_class:
        return error_response(
            message="班级不存在",
            code=404,
            status_code=status.HTTP_404_NOT_FOUND
        )
    
    # 查找班级教师记录
    class_teacher = db.query(PBLClassTeacher).filter(
        PBLClassTeacher.class_id == pbl_class.id,
        PBLClassTeacher.teacher_id == teacher_id
    ).first()
    
    if not class_teacher:
        return error_response(
            message="该教师未分配到此班级",
            code=404,
            status_code=status.HTTP_404_NOT_FOUND
        )
    
    # 如果是班主任，清除班级表的class_teacher_id
    if class_teacher.is_primary == 1:
        pbl_class.class_teacher_id = None
    
    # 删除关联记录
    db.delete(class_teacher)
    db.commit()
    
    logger.info(f"从班级移除教师 - 班级UUID: {class_id}, 教师ID: {teacher_id}, 操作者: {current_admin.username}")
    
    return success_response(message="教师已从班级移除")


# ===== 班级课程管理 =====

@router.get("/classes/{class_id}/courses")
def get_class_courses(
    class_id: str,
    db: Session = Depends(get_db),
    current_admin: Admin = Depends(get_current_admin)
):
    """获取班级课程列表"""
    # 根据UUID查询班级
    pbl_class = db.query(PBLClass).filter(PBLClass.uuid == class_id).first()
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
    
    # 查询班级课程
    class_courses = db.query(PBLClassCourse).filter(
        PBLClassCourse.class_id == pbl_class.id
    ).all()
    
    result = []
    for cc in class_courses:
        course = db.query(PBLCourse).filter(PBLCourse.id == cc.course_id).first()
        if course:
            # 统计班级成员数（所有班级成员自动拥有课程访问权限）
            enrolled_count = db.query(PBLClassMember).filter(
                PBLClassMember.class_id == pbl_class.id,
                PBLClassMember.is_active == 1
            ).count()

            result.append({
                'id': cc.id,
                'uuid': cc.uuid,
                'course_id': course.id,
                'course_uuid': course.uuid,
                'course_title': course.title,
                'course_description': course.description,
                'course_cover': course.cover_image,
                'status': cc.status,
                'start_date': cc.start_date.isoformat() if cc.start_date else None,
                'end_date': cc.end_date.isoformat() if cc.end_date else None,
                'assigned_at': cc.assigned_at.isoformat() if cc.assigned_at else None,
                'enrolled_count': enrolled_count,
                'remarks': cc.remarks
            })
    
    return success_response(data=result)


@router.post("/classes/{class_id}/courses")
def assign_course_to_class(
    class_id: str,
    course_id: int,
    start_date: Optional[str] = None,
    end_date: Optional[str] = None,
    remarks: Optional[str] = None,
    db: Session = Depends(get_db),
    current_admin: Admin = Depends(get_current_admin)
):
    """为班级分配课程（会自动为班级所有学生分配该课程）"""
    # 权限检查
    if current_admin.role not in ['platform_admin', 'school_admin']:
        return error_response(
            message="无权限操作",
            code=403,
            status_code=status.HTTP_403_FORBIDDEN
        )
    
    # 根据UUID查询班级
    pbl_class = db.query(PBLClass).filter(PBLClass.uuid == class_id).first()
    if not pbl_class:
        return error_response(
            message="班级不存在",
            code=404,
            status_code=status.HTTP_404_NOT_FOUND
        )
    
    # 权限检查
    if current_admin.role == 'school_admin':
        if pbl_class.school_id != current_admin.school_id:
            return error_response(
                message="无权限操作该班级",
                code=403,
                status_code=status.HTTP_403_FORBIDDEN
            )
    
    # 验证课程存在
    course = db.query(PBLCourse).filter(PBLCourse.id == course_id).first()
    if not course:
        return error_response(
            message="课程不存在",
            code=404,
            status_code=status.HTTP_404_NOT_FOUND
        )
    
    # 检查是否已经分配
    existing = db.query(PBLClassCourse).filter(
        PBLClassCourse.class_id == pbl_class.id,
        PBLClassCourse.course_id == course_id
    ).first()
    
    if existing:
        return error_response(
            message="该课程已分配给此班级",
            code=400,
            status_code=status.HTTP_400_BAD_REQUEST
        )
    
    # 创建班级课程分配记录
    class_course = PBLClassCourse(
        class_id=pbl_class.id,
        course_id=course_id,
        assigned_by=current_admin.id,
        start_date=datetime.fromisoformat(start_date) if start_date else None,
        end_date=datetime.fromisoformat(end_date) if end_date else None,
        status='active',
        remarks=remarks
    )
    db.add(class_course)
    db.flush()
    
    # 注意：班级成员自动拥有班级课程的访问权限，无需创建选课记录
    # 统计班级成员数量
    enrolled_count = db.query(PBLClassMember).filter(
        PBLClassMember.class_id == pbl_class.id,
        PBLClassMember.is_active == 1
    ).count()

    db.commit()
    db.refresh(class_course)
    
    logger.info(f"为班级分配课程 - 班级UUID: {class_id}, 课程ID: {course_id}, 自动分配学生数: {enrolled_count}, 操作者: {current_admin.username}")
    
    return success_response(
        data={
            'id': class_course.id,
            'uuid': class_course.uuid,
            'course_id': course_id,
            'course_title': course.title,
            'enrolled_students': enrolled_count
        },
        message=f"课程分配成功，已为 {enrolled_count} 名学生自动分配该课程"
    )


@router.delete("/classes/{class_id}/courses/{course_uuid}")
def remove_course_from_class(
    class_id: str,
    course_uuid: str,
    remove_student_enrollments: bool = False,
    db: Session = Depends(get_db),
    current_admin: Admin = Depends(get_current_admin)
):
    """从班级移除课程"""
    # 权限检查
    if current_admin.role not in ['platform_admin', 'school_admin']:
        return error_response(
            message="无权限操作",
            code=403,
            status_code=status.HTTP_403_FORBIDDEN
        )
    
    # 根据UUID查询班级
    pbl_class = db.query(PBLClass).filter(PBLClass.uuid == class_id).first()
    if not pbl_class:
        return error_response(
            message="班级不存在",
            code=404,
            status_code=status.HTTP_404_NOT_FOUND
        )
    
    # 查找班级课程记录
    class_course = db.query(PBLClassCourse).filter(
        PBLClassCourse.uuid == course_uuid,
        PBLClassCourse.class_id == pbl_class.id
    ).first()
    
    if not class_course:
        return error_response(
            message="该课程未分配给此班级",
            code=404,
            status_code=status.HTTP_404_NOT_FOUND
        )
    
    # 注意：不再需要删除选课记录，因为访问控制已改为基于班级成员关系
    
    # 删除班级课程分配记录
    db.delete(class_course)
    db.commit()
    
    logger.info(f"从班级移除课程 - 班级UUID: {class_id}, 课程UUID: {course_uuid}, 操作者: {current_admin.username}")
    
    return success_response(message="课程已从班级移除")


# ===== 班级学习进度查询 =====

@router.get("/classes/{class_id}/progress")
def get_class_learning_progress(
    class_id: str,
    course_id: Optional[int] = None,
    db: Session = Depends(get_db),
    current_admin: Admin = Depends(get_current_admin)
):
    """查看班级学生的课程学习进度"""
    # 根据UUID查询班级
    pbl_class = db.query(PBLClass).filter(PBLClass.uuid == class_id).first()
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
    
    # 查询班级所有学生
    students = db.query(User).filter(
        User.class_id == pbl_class.id,
        User.role == 'student',
        User.deleted_at == None
    ).all()
    
    # 如果指定了课程ID，只查询该课程的进度
    courses_query = db.query(PBLCourse)
    if course_id:
        courses_query = courses_query.filter(PBLCourse.id == course_id)
    else:
        # 否则查询班级所有分配的课程
        class_course_ids = db.query(PBLClassCourse.course_id).filter(
            PBLClassCourse.class_id == pbl_class.id
        ).all()
        course_ids = [cc[0] for cc in class_course_ids]
        courses_query = courses_query.filter(PBLCourse.id.in_(course_ids))
    
    courses = courses_query.all()
    
    result = []
    for student in students:
        student_data = {
            'student_id': student.id,
            'student_name': student.name or student.real_name,
            'student_number': student.student_number,
            'courses': []
        }
        
        for course in courses:
            # 统计课程单元数
            total_units = db.query(PBLUnit).filter(
                PBLUnit.course_id == course.id
            ).count()
            
            # 统计已完成单元数
            completed_units = db.query(PBLLearningProgress).filter(
                PBLLearningProgress.user_id == student.id,
                PBLLearningProgress.course_id == course.id,
                PBLLearningProgress.progress_type == 'unit_complete',
                PBLLearningProgress.status == 'completed'
            ).count()
            
            # 统计任务完成情况
            total_tasks = db.query(PBLTask).join(PBLUnit).filter(
                PBLUnit.course_id == course.id
            ).count()
            
            completed_tasks = db.query(PBLTaskProgress).join(PBLTask).join(PBLUnit).filter(
                PBLUnit.course_id == course.id,
                PBLTaskProgress.user_id == student.id,
                PBLTaskProgress.submission.isnot(None)  # 只要提交了就算完成
            ).count()
            
            # 计算平均分
            avg_score_result = db.query(func.avg(PBLTaskProgress.score)).join(PBLTask).join(PBLUnit).filter(
                PBLUnit.course_id == course.id,
                PBLTaskProgress.user_id == student.id,
                PBLTaskProgress.score != None
            ).scalar()
            
            avg_score = float(avg_score_result) if avg_score_result else None
            
            # 计算课程进度（基于完成的单元数）
            course_progress_percent = int((completed_units / total_units * 100)) if total_units > 0 else 0
            
            course_progress = {
                'course_id': course.id,
                'course_uuid': course.uuid,
                'course_title': course.title,
                'progress': course_progress_percent,
                'total_units': total_units,
                'completed_units': completed_units,
                'total_tasks': total_tasks,
                'completed_tasks': completed_tasks,
                'avg_score': round(avg_score, 2) if avg_score else None
            }
            
            student_data['courses'].append(course_progress)
        
        result.append(student_data)
    
    return success_response(data=result)
