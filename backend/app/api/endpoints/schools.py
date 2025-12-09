"""
学校管理 API
用于平台管理员管理学校
"""
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from sqlalchemy import func
from typing import List, Optional
from datetime import datetime, date
import uuid as uuid_lib

from ...db.session import SessionLocal
from ...core.response import success_response, error_response
from ...core.deps import get_db, get_current_admin
from ...core.security import get_password_hash
from ...models.admin import Admin, User
from ...models.school import School
from ...core.logging_config import get_logger

router = APIRouter()
logger = get_logger(__name__)


@router.get("/list")
def get_schools(
    is_active: Optional[bool] = None,
    search: Optional[str] = None,
    skip: int = 0,
    limit: int = 100,
    db: Session = Depends(get_db),
    current_admin: Admin = Depends(get_current_admin)
):
    """
    获取学校列表
    权限：仅平台管理员
    """
    # 权限检查
    if current_admin.role != 'platform_admin':
        return error_response(
            message="仅平台管理员可以查看学校列表",
            code=403,
            status_code=status.HTTP_403_FORBIDDEN
        )
    
    # 构建查询
    query = db.query(School)
    
    # 筛选条件
    if is_active is not None:
        query = query.filter(School.is_active == is_active)
    
    if search:
        query = query.filter(
            (School.school_name.like(f'%{search}%')) |
            (School.school_code.like(f'%{search}%')) |
            (School.city.like(f'%{search}%'))
        )
    
    # 总数
    total = query.count()
    
    # 分页
    schools = query.offset(skip).limit(limit).all()
    
    # 序列化结果
    result = []
    for school in schools:
        result.append({
            'id': school.id,
            'uuid': school.uuid,
            'school_code': school.school_code,
            'school_name': school.school_name,
            'province': school.province,
            'city': school.city,
            'district': school.district,
            'address': school.address,
            'contact_person': school.contact_person,
            'contact_phone': school.contact_phone,
            'contact_email': school.contact_email,
            'is_active': school.is_active,
            'license_expire_at': school.license_expire_at.isoformat() if school.license_expire_at else None,
            'max_teachers': school.max_teachers,
            'current_teachers': getattr(school, 'current_teachers', 0),
            'max_students': school.max_students,
            'current_students': getattr(school, 'current_students', 0),
            'max_devices': school.max_devices,
            'admin_user_id': getattr(school, 'admin_user_id', None),
            'admin_username': getattr(school, 'admin_username', None),
            'description': getattr(school, 'description', None),
            'created_at': school.created_at.isoformat() if school.created_at else None,
            'updated_at': school.updated_at.isoformat() if school.updated_at else None
        })
    
    return success_response(data={
        'total': total,
        'items': result
    })


@router.get("/{school_id}")
def get_school(
    school_id: int,
    db: Session = Depends(get_db),
    current_admin: Admin = Depends(get_current_admin)
):
    """
    获取学校详情
    权限：平台管理员可查看所有，学校管理员只能查看自己的学校
    """
    # 权限检查
    if current_admin.role == 'school_admin' and current_admin.school_id != school_id:
        return error_response(
            message="无权限查看其他学校信息",
            code=403,
            status_code=status.HTTP_403_FORBIDDEN
        )
    
    school = db.query(School).filter(School.id == school_id).first()
    
    if not school:
        return error_response(
            message="学校不存在",
            code=404,
            status_code=status.HTTP_404_NOT_FOUND
        )
    
    # 获取学校管理员信息
    admin_user = None
    if hasattr(school, 'admin_user_id') and school.admin_user_id:
        admin_user = db.query(User).filter(User.id == school.admin_user_id).first()
    
    # 统计当前教师和学生数
    teacher_count = db.query(func.count(User.id)).filter(
        User.school_id == school_id,
        User.role.in_(['teacher', 'school_admin']),
        User.deleted_at == None,
        User.is_active == True
    ).scalar()
    
    student_count = db.query(func.count(User.id)).filter(
        User.school_id == school_id,
        User.role == 'student',
        User.deleted_at == None,
        User.is_active == True
    ).scalar()
    
    result = {
        'id': school.id,
        'uuid': school.uuid,
        'school_code': school.school_code,
        'school_name': school.school_name,
        'province': school.province,
        'city': school.city,
        'district': school.district,
        'address': school.address,
        'contact_person': school.contact_person,
        'contact_phone': school.contact_phone,
        'contact_email': school.contact_email,
        'is_active': school.is_active,
        'license_expire_at': school.license_expire_at.isoformat() if school.license_expire_at else None,
        'max_teachers': school.max_teachers,
        'current_teachers': teacher_count,
        'max_students': school.max_students,
        'current_students': student_count,
        'max_devices': school.max_devices,
        'description': getattr(school, 'description', None),
        'created_at': school.created_at.isoformat() if school.created_at else None,
        'updated_at': school.updated_at.isoformat() if school.updated_at else None,
        'admin_user': None
    }
    
    if admin_user:
        result['admin_user'] = {
            'id': admin_user.id,
            'username': admin_user.username,
            'name': admin_user.name or admin_user.real_name,
            'phone': admin_user.phone,
            'email': admin_user.email
        }
    
    return success_response(data=result)


@router.post("")
def create_school(
    school_code: str,
    school_name: str,
    province: Optional[str] = None,
    city: Optional[str] = None,
    district: Optional[str] = None,
    address: Optional[str] = None,
    contact_person: Optional[str] = None,
    contact_phone: Optional[str] = None,
    contact_email: Optional[str] = None,
    max_teachers: int = 100,
    max_students: int = 1000,
    max_devices: int = 500,
    license_expire_at: Optional[str] = None,
    description: Optional[str] = None,
    admin_username: Optional[str] = None,
    admin_password: Optional[str] = None,
    admin_name: Optional[str] = None,
    admin_phone: Optional[str] = None,
    admin_email: Optional[str] = None,
    db: Session = Depends(get_db),
    current_admin: Admin = Depends(get_current_admin)
):
    """
    创建学校
    权限：仅平台管理员
    可同时创建学校管理员账号
    """
    # 权限检查
    if current_admin.role != 'platform_admin':
        return error_response(
            message="仅平台管理员可以创建学校",
            code=403,
            status_code=status.HTTP_403_FORBIDDEN
        )
    
    # 检查学校代码是否已存在
    existing_school = db.query(School).filter(School.school_code == school_code).first()
    if existing_school:
        return error_response(
            message="学校代码已存在",
            code=400,
            status_code=status.HTTP_400_BAD_REQUEST
        )
    
    # 检查学校名称是否已存在
    existing_name = db.query(School).filter(School.school_name == school_name).first()
    if existing_name:
        return error_response(
            message="学校名称已存在",
            code=400,
            status_code=status.HTTP_400_BAD_REQUEST
        )
    
    # 转换日期
    license_date = None
    if license_expire_at:
        try:
            license_date = datetime.fromisoformat(license_expire_at).date()
        except:
            pass
    
    # 创建学校
    new_school = School(
        uuid=str(uuid_lib.uuid4()),
        school_code=school_code,
        school_name=school_name,
        province=province,
        city=city,
        district=district,
        address=address,
        contact_person=contact_person,
        contact_phone=contact_phone,
        contact_email=contact_email,
        is_active=True,
        license_expire_at=license_date,
        max_teachers=max_teachers,
        max_students=max_students,
        max_devices=max_devices
    )
    
    # 如果有description字段，设置它
    if hasattr(new_school, 'description'):
        new_school.description = description
    
    db.add(new_school)
    db.flush()  # 获取school的id
    
    # 如果提供了管理员信息，创建学校管理员账号
    admin_user = None
    if admin_username and admin_password:
        # 检查用户名是否已存在
        existing_user = db.query(User).filter(User.username == admin_username).first()
        if existing_user:
            db.rollback()
            return error_response(
                message=f"用户名 {admin_username} 已存在",
                code=400,
                status_code=status.HTTP_400_BAD_REQUEST
            )
        
        # 创建管理员账号
        admin_user = User(
            username=admin_username,
            password_hash=get_password_hash(admin_password),
            name=admin_name or admin_username,
            phone=admin_phone,
            email=admin_email,
            role='school_admin',
            school_id=new_school.id,
            school_name=new_school.school_name,
            is_active=True,
            need_change_password=True
        )
        db.add(admin_user)
        db.flush()
        
        # 更新学校的管理员信息
        if hasattr(new_school, 'admin_user_id'):
            new_school.admin_user_id = admin_user.id
            new_school.admin_username = admin_user.username
    
    db.commit()
    db.refresh(new_school)
    
    logger.info(f"创建学校成功 - 学校: {school_name}, 代码: {school_code}, 操作者: {current_admin.username}")
    if admin_user:
        logger.info(f"创建学校管理员成功 - 用户名: {admin_username}, 学校: {school_name}")
    
    result = {
        'id': new_school.id,
        'uuid': new_school.uuid,
        'school_code': new_school.school_code,
        'school_name': new_school.school_name,
        'is_active': new_school.is_active
    }
    
    if admin_user:
        result['admin_user'] = {
            'id': admin_user.id,
            'username': admin_user.username,
            'name': admin_user.name
        }
    
    return success_response(
        data=result,
        message="学校创建成功" + ("，管理员账号已创建" if admin_user else "")
    )


@router.put("/{school_id}")
def update_school(
    school_id: int,
    school_name: Optional[str] = None,
    province: Optional[str] = None,
    city: Optional[str] = None,
    district: Optional[str] = None,
    address: Optional[str] = None,
    contact_person: Optional[str] = None,
    contact_phone: Optional[str] = None,
    contact_email: Optional[str] = None,
    max_teachers: Optional[int] = None,
    max_students: Optional[int] = None,
    max_devices: Optional[int] = None,
    license_expire_at: Optional[str] = None,
    description: Optional[str] = None,
    video_student_view_limit: Optional[int] = None,
    video_teacher_view_limit: Optional[int] = None,
    db: Session = Depends(get_db),
    current_admin: Admin = Depends(get_current_admin)
):
    """
    更新学校信息
    权限：仅平台管理员
    """
    # 权限检查
    if current_admin.role != 'platform_admin':
        return error_response(
            message="仅平台管理员可以修改学校信息",
            code=403,
            status_code=status.HTTP_403_FORBIDDEN
        )
    
    school = db.query(School).filter(School.id == school_id).first()
    
    if not school:
        return error_response(
            message="学校不存在",
            code=404,
            status_code=status.HTTP_404_NOT_FOUND
        )
    
    # 更新字段
    if school_name is not None:
        # 检查名称是否与其他学校重复
        existing = db.query(School).filter(
            School.school_name == school_name,
            School.id != school_id
        ).first()
        if existing:
            return error_response(
                message="学校名称已被其他学校使用",
                code=400,
                status_code=status.HTTP_400_BAD_REQUEST
            )
        school.school_name = school_name
    
    if province is not None:
        school.province = province
    if city is not None:
        school.city = city
    if district is not None:
        school.district = district
    if address is not None:
        school.address = address
    if contact_person is not None:
        school.contact_person = contact_person
    if contact_phone is not None:
        school.contact_phone = contact_phone
    if contact_email is not None:
        school.contact_email = contact_email
    if max_teachers is not None:
        school.max_teachers = max_teachers
    if max_students is not None:
        school.max_students = max_students
    if max_devices is not None:
        school.max_devices = max_devices
    if license_expire_at is not None:
        try:
            school.license_expire_at = datetime.fromisoformat(license_expire_at).date()
        except:
            pass
    if description is not None and hasattr(school, 'description'):
        school.description = description
    
    db.commit()
    db.refresh(school)
    
    logger.info(f"更新学校信息 - 学校: {school.school_name}, ID: {school_id}, 操作者: {current_admin.username}")
    
    return success_response(message="学校信息更新成功")


@router.patch("/{school_id}/toggle-active")
def toggle_school_active(
    school_id: int,
    db: Session = Depends(get_db),
    current_admin: Admin = Depends(get_current_admin)
):
    """
    启用/禁用学校
    权限：仅平台管理员
    """
    # 权限检查
    if current_admin.role != 'platform_admin':
        return error_response(
            message="仅平台管理员可以操作",
            code=403,
            status_code=status.HTTP_403_FORBIDDEN
        )
    
    school = db.query(School).filter(School.id == school_id).first()
    
    if not school:
        return error_response(
            message="学校不存在",
            code=404,
            status_code=status.HTTP_404_NOT_FOUND
        )
    
    # 切换状态
    school.is_active = not school.is_active
    db.commit()
    
    status_text = "启用" if school.is_active else "禁用"
    logger.info(f"{status_text}学校 - 学校: {school.school_name}, ID: {school_id}, 操作者: {current_admin.username}")
    
    return success_response(
        data={'is_active': school.is_active},
        message=f"学校已{status_text}"
    )


@router.post("/{school_id}/assign-admin")
def assign_school_admin(
    school_id: int,
    user_id: int,
    db: Session = Depends(get_db),
    current_admin: Admin = Depends(get_current_admin)
):
    """
    为学校分配管理员
    权限：仅平台管理员
    """
    # 权限检查
    if current_admin.role != 'platform_admin':
        return error_response(
            message="仅平台管理员可以分配学校管理员",
            code=403,
            status_code=status.HTTP_403_FORBIDDEN
        )
    
    # 检查学校是否存在
    school = db.query(School).filter(School.id == school_id).first()
    if not school:
        return error_response(
            message="学校不存在",
            code=404,
            status_code=status.HTTP_404_NOT_FOUND
        )
    
    # 检查用户是否存在
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        return error_response(
            message="用户不存在",
            code=404,
            status_code=status.HTTP_404_NOT_FOUND
        )
    
    # 检查用户角色
    if user.role != 'school_admin':
        return error_response(
            message="只能分配学校管理员角色的用户",
            code=400,
            status_code=status.HTTP_400_BAD_REQUEST
        )
    
    # 更新用户的学校ID
    user.school_id = school_id
    user.school_name = school.school_name
    
    # 更新学校的管理员信息
    school.admin_user_id = user_id
    school.admin_username = user.username
    
    db.commit()
    
    logger.info(f"分配学校管理员 - 学校: {school.school_name}, 管理员: {user.username}, 操作者: {current_admin.username}")
    
    return success_response(message="学校管理员分配成功")


@router.delete("/{school_id}")
def delete_school(
    school_id: int,
    db: Session = Depends(get_db),
    current_admin: Admin = Depends(get_current_admin)
):
    """
    删除学校（仅在学校没有关联数据时允许删除）
    权限：仅平台管理员
    """
    # 权限检查
    if current_admin.role != 'platform_admin':
        return error_response(
            message="仅平台管理员可以删除学校",
            code=403,
            status_code=status.HTTP_403_FORBIDDEN
        )
    
    school = db.query(School).filter(School.id == school_id).first()
    
    if not school:
        return error_response(
            message="学校不存在",
            code=404,
            status_code=status.HTTP_404_NOT_FOUND
        )
    
    # 检查是否有关联的用户
    user_count = db.query(func.count(User.id)).filter(
        User.school_id == school_id,
        User.deleted_at == None
    ).scalar()
    
    if user_count > 0:
        return error_response(
            message=f"该学校还有 {user_count} 个用户，无法删除",
            code=400,
            status_code=status.HTTP_400_BAD_REQUEST
        )
    
    # 删除学校
    db.delete(school)
    db.commit()
    
    logger.info(f"删除学校 - 学校: {school.school_name}, ID: {school_id}, 操作者: {current_admin.username}")
    
    return success_response(message="学校删除成功")


@router.get("/{school_id}/statistics")
def get_school_statistics(
    school_id: int,
    db: Session = Depends(get_db),
    current_admin: Admin = Depends(get_current_admin)
):
    """
    获取学校统计信息
    权限：平台管理员可查看所有，学校管理员只能查看自己的学校
    """
    # 权限检查
    if current_admin.role == 'school_admin' and current_admin.school_id != school_id:
        return error_response(
            message="无权限查看其他学校信息",
            code=403,
            status_code=status.HTTP_403_FORBIDDEN
        )
    
    # 检查学校是否存在
    school = db.query(School).filter(School.id == school_id).first()
    if not school:
        return error_response(
            message="学校不存在",
            code=404,
            status_code=status.HTTP_404_NOT_FOUND
        )
    
    # 统计教师数
    teacher_count = db.query(func.count(User.id)).filter(
        User.school_id == school_id,
        User.role == 'teacher',
        User.deleted_at == None,
        User.is_active == True
    ).scalar()
    
    # 统计学生数
    student_count = db.query(func.count(User.id)).filter(
        User.school_id == school_id,
        User.role == 'student',
        User.deleted_at == None,
        User.is_active == True
    ).scalar()
    
    # 统计学校管理员数
    admin_count = db.query(func.count(User.id)).filter(
        User.school_id == school_id,
        User.role == 'school_admin',
        User.deleted_at == None,
        User.is_active == True
    ).scalar()
    
    result = {
        'school_id': school_id,
        'school_name': school.school_name,
        'teacher_count': teacher_count,
        'max_teachers': school.max_teachers,
        'student_count': student_count,
        'max_students': school.max_students,
        'admin_count': admin_count,
        'capacity_usage': {
            'teachers': {
                'current': teacher_count,
                'max': school.max_teachers,
                'percentage': round(teacher_count / school.max_teachers * 100, 2) if school.max_teachers > 0 else 0
            },
            'students': {
                'current': student_count,
                'max': school.max_students,
                'percentage': round(student_count / school.max_students * 100, 2) if school.max_students > 0 else 0
            }
        }
    }
    
    return success_response(data=result)
