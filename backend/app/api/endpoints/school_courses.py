"""
学校课程管理 API
用于平台管理员将课程分配给学校
"""
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List, Optional
from datetime import datetime

from ...db.session import SessionLocal
from ...core.response import success_response, error_response
from ...core.deps import get_db, get_current_admin
from ...models.admin import Admin
from ...models.pbl import PBLCourse, PBLSchoolCourse
from ...models.school import School
from ...schemas.pbl import SchoolCourseCreate, SchoolCourseUpdate, SchoolCourse, SchoolCourseWithDetails, Course
from ...core.logging_config import get_logger

router = APIRouter()
logger = get_logger(__name__)


def serialize_school_course(sc: PBLSchoolCourse) -> dict:
    """序列化学校课程"""
    return SchoolCourse.model_validate(sc).model_dump(mode='json')


@router.post("/assign")
def assign_course_to_school(
    data: SchoolCourseCreate,
    db: Session = Depends(get_db),
    current_admin: Admin = Depends(get_current_admin)
):
    """
    平台管理员为学校分配课程
    权限：仅平台管理员
    """
    # 权限检查
    if current_admin.role != 'platform_admin':
        return error_response(
            message="仅平台管理员可以为学校分配课程",
            code=403,
            status_code=status.HTTP_403_FORBIDDEN
        )
    
    # 检查课程是否存在
    course = db.query(PBLCourse).filter(PBLCourse.id == data.course_id).first()
    if not course:
        return error_response(
            message="课程不存在",
            code=404,
            status_code=status.HTTP_404_NOT_FOUND
        )
    
    # 检查是否已经分配
    existing = db.query(PBLSchoolCourse).filter(
        PBLSchoolCourse.school_id == data.school_id,
        PBLSchoolCourse.course_id == data.course_id
    ).first()
    
    if existing:
        return error_response(
            message="该课程已分配给该学校",
            code=400,
            status_code=status.HTTP_400_BAD_REQUEST
        )
    
    # 创建分配记录
    school_course = PBLSchoolCourse(
        school_id=data.school_id,
        course_id=data.course_id,
        assigned_by=current_admin.id,
        status=data.status or 'active',
        start_date=data.start_date,
        end_date=data.end_date,
        max_students=data.max_students,
        remarks=data.remarks
    )
    
    db.add(school_course)
    db.commit()
    db.refresh(school_course)
    
    logger.info(f"课程分配 - 课程: {course.title}, 学校: {data.school_id}, 操作者: {current_admin.username}")
    
    return success_response(
        data=serialize_school_course(school_course),
        message="课程分配成功"
    )


@router.post("/batch-assign")
def batch_assign_courses(
    school_id: int,
    course_ids: List[int],
    db: Session = Depends(get_db),
    current_admin: Admin = Depends(get_current_admin)
):
    """
    批量为学校分配课程
    权限：仅平台管理员
    """
    # 权限检查
    if current_admin.role != 'platform_admin':
        return error_response(
            message="仅平台管理员可以为学校分配课程",
            code=403,
            status_code=status.HTTP_403_FORBIDDEN
        )
    
    assigned_count = 0
    for course_id in course_ids:
        # 检查课程是否存在
        course = db.query(PBLCourse).filter(PBLCourse.id == course_id).first()
        if not course:
            continue
        
        # 检查是否已经分配
        existing = db.query(PBLSchoolCourse).filter(
            PBLSchoolCourse.school_id == school_id,
            PBLSchoolCourse.course_id == course_id
        ).first()
        
        if existing:
            continue
        
        # 创建分配记录
        school_course = PBLSchoolCourse(
            school_id=school_id,
            course_id=course_id,
            assigned_by=current_admin.id,
            status='active'
        )
        
        db.add(school_course)
        assigned_count += 1
    
    db.commit()
    
    logger.info(f"批量分配课程 - 学校: {school_id}, 课程数: {assigned_count}, 操作者: {current_admin.username}")
    
    return success_response(
        data={'assigned_count': assigned_count},
        message=f"成功分配 {assigned_count} 门课程"
    )


@router.get("/all")
def get_all_school_courses(
    skip: int = 0,
    limit: int = 20,
    school_id: Optional[int] = None,
    course_id: Optional[int] = None,
    status: Optional[str] = None,
    db: Session = Depends(get_db),
    current_admin: Admin = Depends(get_current_admin)
):
    """
    获取所有学校课程分配记录（带分页和筛选）
    权限：平台管理员可查看所有，学校管理员只能查看自己学校的
    """
    # 基础查询
    query = db.query(PBLSchoolCourse)
    
    # 权限检查和过滤
    if current_admin.role == 'school_admin':
        if not current_admin.school_id:
            return error_response(
                message="当前管理员未绑定学校",
                code=400,
                status_code=status.HTTP_400_BAD_REQUEST
            )
        query = query.filter(PBLSchoolCourse.school_id == current_admin.school_id)
    elif current_admin.role != 'platform_admin':
        return error_response(
            message="无权限访问",
            code=403,
            status_code=status.HTTP_403_FORBIDDEN
        )
    
    # 可选过滤条件
    if school_id:
        query = query.filter(PBLSchoolCourse.school_id == school_id)
    if course_id:
        query = query.filter(PBLSchoolCourse.course_id == course_id)
    if status:
        query = query.filter(PBLSchoolCourse.status == status)
    
    # 获取总数
    total = query.count()
    
    # 分页查询
    school_courses = query.offset(skip).limit(limit).all()
    
    # 获取详细信息
    result = []
    for sc in school_courses:
        course = db.query(PBLCourse).filter(PBLCourse.id == sc.course_id).first()
        school = db.query(School).filter(School.id == sc.school_id).first()
        
        sc_data = serialize_school_course(sc)
        if course:
            sc_data['course'] = Course.model_validate(course).model_dump(mode='json')
        if school:
            sc_data['school'] = {
                'id': school.id,
                'uuid': school.uuid,
                'school_code': school.school_code,
                'school_name': school.school_name,
                'province': school.province,
                'city': school.city,
                'district': school.district
            }
        result.append(sc_data)
    
    return success_response(data={
        'items': result,
        'total': total,
        'skip': skip,
        'limit': limit
    })


@router.get("/school/{school_id}/courses")
def get_school_courses(
    school_id: int,
    status: Optional[str] = None,
    skip: int = 0,
    limit: int = 100,
    db: Session = Depends(get_db),
    current_admin: Admin = Depends(get_current_admin)
):
    """
    获取学校已分配的课程列表
    权限：平台管理员可查看所有学校，学校管理员只能查看自己学校
    """
    # 权限检查
    if current_admin.role == 'school_admin' and current_admin.school_id != school_id:
        return error_response(
            message="无权限查看其他学校的课程",
            code=403,
            status_code=status.HTTP_403_FORBIDDEN
        )
    
    # 查询学校课程
    query = db.query(PBLSchoolCourse).filter(PBLSchoolCourse.school_id == school_id)
    
    if status:
        query = query.filter(PBLSchoolCourse.status == status)
    
    school_courses = query.offset(skip).limit(limit).all()
    
    # 获取课程详情
    result = []
    for sc in school_courses:
        course = db.query(PBLCourse).filter(PBLCourse.id == sc.course_id).first()
        if course:
            sc_data = serialize_school_course(sc)
            sc_data['course'] = Course.model_validate(course).model_dump(mode='json')
            result.append(sc_data)
    
    return success_response(data=result)


@router.get("/course/{course_id}/schools")
def get_course_schools(
    course_id: int,
    db: Session = Depends(get_db),
    current_admin: Admin = Depends(get_current_admin)
):
    """
    获取课程已分配的学校列表
    权限：仅平台管理员
    """
    # 权限检查
    if current_admin.role != 'platform_admin':
        return error_response(
            message="仅平台管理员可以查看课程分配情况",
            code=403,
            status_code=status.HTTP_403_FORBIDDEN
        )
    
    # 检查课程是否存在
    course = db.query(PBLCourse).filter(PBLCourse.id == course_id).first()
    if not course:
        return error_response(
            message="课程不存在",
            code=404,
            status_code=status.HTTP_404_NOT_FOUND
        )
    
    # 查询分配记录
    school_courses = db.query(PBLSchoolCourse).filter(
        PBLSchoolCourse.course_id == course_id
    ).all()
    
    result = [serialize_school_course(sc) for sc in school_courses]
    
    return success_response(data=result)


@router.put("/{school_course_uuid}")
def update_school_course(
    school_course_uuid: str,
    data: SchoolCourseUpdate,
    db: Session = Depends(get_db),
    current_admin: Admin = Depends(get_current_admin)
):
    """
    更新学校课程分配信息
    权限：平台管理员可更新所有，学校管理员只能更新自己学校的（部分字段）
    """
    # 查询记录
    school_course = db.query(PBLSchoolCourse).filter(
        PBLSchoolCourse.uuid == school_course_uuid
    ).first()
    
    if not school_course:
        return error_response(
            message="记录不存在",
            code=404,
            status_code=status.HTTP_404_NOT_FOUND
        )
    
    # 权限检查
    if current_admin.role == 'school_admin':
        if current_admin.school_id != school_course.school_id:
            return error_response(
                message="无权限修改其他学校的课程分配",
                code=403,
                status_code=status.HTTP_403_FORBIDDEN
            )
        # 学校管理员只能修改备注，不能修改状态和其他字段
        if data.status is not None or data.max_students is not None:
            return error_response(
                message="学校管理员只能修改备注信息",
                code=403,
                status_code=status.HTTP_403_FORBIDDEN
            )
    
    # 更新字段
    for field, value in data.model_dump(exclude_unset=True).items():
        if value is not None:
            setattr(school_course, field, value)
    
    db.commit()
    db.refresh(school_course)
    
    logger.info(f"更新学校课程 - UUID: {school_course_uuid}, 操作者: {current_admin.username}")
    
    return success_response(
        data=serialize_school_course(school_course),
        message="更新成功"
    )


@router.delete("/{school_course_uuid}")
def remove_school_course(
    school_course_uuid: str,
    db: Session = Depends(get_db),
    current_admin: Admin = Depends(get_current_admin)
):
    """
    取消学校课程分配
    权限：仅平台管理员
    """
    # 权限检查
    if current_admin.role != 'platform_admin':
        return error_response(
            message="仅平台管理员可以取消课程分配",
            code=403,
            status_code=status.HTTP_403_FORBIDDEN
        )
    
    # 查询记录
    school_course = db.query(PBLSchoolCourse).filter(
        PBLSchoolCourse.uuid == school_course_uuid
    ).first()
    
    if not school_course:
        return error_response(
            message="记录不存在",
            code=404,
            status_code=status.HTTP_404_NOT_FOUND
        )
    
    # 删除记录
    db.delete(school_course)
    db.commit()
    
    logger.info(f"取消学校课程分配 - UUID: {school_course_uuid}, 操作者: {current_admin.username}")
    
    return success_response(message="取消分配成功")


@router.get("/available-courses")
def get_available_courses_for_school(
    db: Session = Depends(get_db),
    current_admin: Admin = Depends(get_current_admin)
):
    """
    获取学校可用的课程列表（已分配且状态为active的课程）
    权限：学校管理员
    """
    if current_admin.role not in ['school_admin', 'teacher']:
        return error_response(
            message="仅学校管理员和教师可以访问",
            code=403,
            status_code=status.HTTP_403_FORBIDDEN
        )
    
    if not current_admin.school_id:
        return error_response(
            message="当前管理员未绑定学校",
            code=400,
            status_code=status.HTTP_400_BAD_REQUEST
        )
    
    # 查询学校已分配且状态为active的课程
    school_courses = db.query(PBLSchoolCourse).filter(
        PBLSchoolCourse.school_id == current_admin.school_id,
        PBLSchoolCourse.status == 'active'
    ).all()
    
    result = []
    for sc in school_courses:
        course = db.query(PBLCourse).filter(PBLCourse.id == sc.course_id).first()
        if course and course.status == 'published':
            course_data = Course.model_validate(course).model_dump(mode='json')
            course_data['school_course_info'] = {
                'uuid': sc.uuid,
                'assigned_at': sc.assigned_at.isoformat() if sc.assigned_at else None,
                'start_date': sc.start_date.isoformat() if sc.start_date else None,
                'end_date': sc.end_date.isoformat() if sc.end_date else None,
                'max_students': sc.max_students,
                'current_students': sc.current_students
            }
            result.append(course_data)
    
    return success_response(data=result)
