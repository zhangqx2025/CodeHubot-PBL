from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List, Optional
from datetime import datetime
from app.utils.timezone import get_beijing_time_naive
from pydantic import BaseModel

from ...db.session import SessionLocal
from ...core.response import success_response, error_response
from ...core.deps import get_db, get_current_admin, get_current_user
from ...models.admin import Admin, User
from ...models.pbl import PBLCourse, PBLCourseEnrollment, PBLSchoolCourse
from ...core.logging_config import get_logger

router = APIRouter()
logger = get_logger(__name__)

# Pydantic 模型
class BatchEnrollRequest(BaseModel):
    student_ids: List[int]

@router.post("/enroll/{course_id}")
def enroll_course(
    course_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """学生选课"""
    # 检查课程是否存在
    course = db.query(PBLCourse).filter(PBLCourse.id == course_id).first()
    if not course:
        return error_response(
            message="课程不存在",
            code=404,
            status_code=status.HTTP_404_NOT_FOUND
        )
    
    # 检查课程状态
    if course.status != 'published':
        return error_response(
            message="该课程暂未开放选课",
            code=400,
            status_code=status.HTTP_400_BAD_REQUEST
        )
    
    # ★ 新增：检查课程是否已分配给学生所属学校
    if current_user.school_id:
        school_course = db.query(PBLSchoolCourse).filter(
            PBLSchoolCourse.school_id == current_user.school_id,
            PBLSchoolCourse.course_id == course_id,
            PBLSchoolCourse.status == 'active'
        ).first()
        
        if not school_course:
            return error_response(
                message="该课程未开放给您所在的学校",
                code=403,
                status_code=status.HTTP_403_FORBIDDEN
            )
        
        # 检查是否超过学生数限制
        if school_course.max_students:
            if school_course.current_students >= school_course.max_students:
                return error_response(
                    message="该课程选课人数已满",
                    code=400,
                    status_code=status.HTTP_400_BAD_REQUEST
                )
    
    # 检查是否已经有选课记录(不论状态)
    existing_enrollment = db.query(PBLCourseEnrollment).filter(
        PBLCourseEnrollment.course_id == course_id,
        PBLCourseEnrollment.user_id == current_user.id
    ).first()
    
    is_new_enrollment = False
    if existing_enrollment:
        # 如果已经是enrolled状态,返回错误
        if existing_enrollment.enrollment_status == 'enrolled':
            return error_response(
                message="您已选修该课程",
                code=400,
                status_code=status.HTTP_400_BAD_REQUEST
            )
        # 如果是其他状态(如dropped),更新为enrolled
        existing_enrollment.enrollment_status = 'enrolled'
        existing_enrollment.enrolled_at = get_beijing_time_naive()
        existing_enrollment.dropped_at = None
        enrollment = existing_enrollment
        is_new_enrollment = True  # 重新选课，需要更新计数
    else:
        # 创建新的选课记录
        enrollment = PBLCourseEnrollment(
            course_id=course_id,
            user_id=current_user.id,
            enrollment_status='enrolled',
            enrolled_at=get_beijing_time_naive()
        )
        db.add(enrollment)
        is_new_enrollment = True
    
    # ★ 新增：更新学校课程的当前学生数（只在新选课或重新选课时更新）
    if is_new_enrollment and current_user.school_id:
        school_course = db.query(PBLSchoolCourse).filter(
            PBLSchoolCourse.school_id == current_user.school_id,
            PBLSchoolCourse.course_id == course_id
        ).first()
        if school_course:
            school_course.current_students += 1
    
    db.commit()
    db.refresh(enrollment)
    
    logger.info(f"学生选课 - 用户: {current_user.username}, 课程: {course.title}")
    
    return success_response(
        data={
            'course_id': course_id,
            'course_uuid': course.uuid,
            'user_id': current_user.id,
            'enrolled_at': enrollment.enrolled_at.isoformat()
        },
        message="选课成功"
    )

@router.delete("/unenroll/{course_id}")
def unenroll_course(
    course_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """学生退课"""
    # 检查课程是否存在
    course = db.query(PBLCourse).filter(PBLCourse.id == course_id).first()
    if not course:
        return error_response(
            message="课程不存在",
            code=404,
            status_code=status.HTTP_404_NOT_FOUND
        )
    
    # 检查是否已选课
    enrollment = db.query(PBLCourseEnrollment).filter(
        PBLCourseEnrollment.course_id == course_id,
        PBLCourseEnrollment.user_id == current_user.id,
        PBLCourseEnrollment.enrollment_status == 'enrolled'
    ).first()
    
    if not enrollment:
        return error_response(
            message="您未选修该课程",
            code=400,
            status_code=status.HTTP_400_BAD_REQUEST
        )
    
    # 更新选课状态为已退课
    enrollment.enrollment_status = 'dropped'
    enrollment.dropped_at = get_beijing_time_naive()
    
    # ★ 新增：更新学校课程的当前学生数
    if current_user.school_id:
        school_course = db.query(PBLSchoolCourse).filter(
            PBLSchoolCourse.school_id == current_user.school_id,
            PBLSchoolCourse.course_id == course_id
        ).first()
        if school_course and school_course.current_students > 0:
            school_course.current_students -= 1
    
    db.commit()
    
    logger.info(f"学生退课 - 用户: {current_user.username}, 课程: {course.title}")
    
    return success_response(message="退课成功")

@router.get("/my-enrollments")
def get_my_enrollments(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """获取我的选课列表"""
    # 从选课表查询
    enrollments = db.query(PBLCourseEnrollment).join(
        PBLCourse, PBLCourse.id == PBLCourseEnrollment.course_id
    ).filter(
        PBLCourseEnrollment.user_id == current_user.id,
        PBLCourseEnrollment.enrollment_status == 'enrolled'
    ).all()
    
    result = []
    for enrollment in enrollments:
        course = db.query(PBLCourse).filter(PBLCourse.id == enrollment.course_id).first()
        if course:
            result.append({
                'enrollment_id': enrollment.id,
                'course_id': course.id,
                'course_uuid': course.uuid,
                'title': course.title,
                'description': course.description,
                'cover_image': course.cover_image,
                'difficulty': course.difficulty,
                'duration': course.duration,
                'enrolled_at': enrollment.enrolled_at.isoformat() if enrollment.enrolled_at else None,
                'progress': enrollment.progress
            })
    
    return success_response(data=result)

@router.get("/course/{course_id}/students")
def get_course_students(
    course_id: int,
    db: Session = Depends(get_db),
    current_admin: Admin = Depends(get_current_admin)
):
    """获取课程的选课学生列表（管理员）"""
    # 检查课程是否存在
    course = db.query(PBLCourse).filter(PBLCourse.id == course_id).first()
    if not course:
        return error_response(
            message="课程不存在",
            code=404,
            status_code=status.HTTP_404_NOT_FOUND
        )
    
    # 权限检查 - 对于学校管理员，检查该课程是否分配给其学校
    if current_admin.role != 'platform_admin':
        # 检查课程是否已分配给管理员所在的学校
        school_course = db.query(PBLSchoolCourse).filter(
            PBLSchoolCourse.school_id == current_admin.school_id,
            PBLSchoolCourse.course_id == course_id
        ).first()
        
        if not school_course:
            return error_response(
                message="该课程未分配给您的学校",
                code=403,
                status_code=status.HTTP_403_FORBIDDEN
            )
    
    # 从选课表查询 - 如果是学校管理员，只返回本校学生
    query = db.query(PBLCourseEnrollment).join(
        User, User.id == PBLCourseEnrollment.user_id
    ).filter(
        PBLCourseEnrollment.course_id == course_id,
        PBLCourseEnrollment.enrollment_status == 'enrolled'
    )
    
    # 学校管理员只能查看本校学生
    if current_admin.role != 'platform_admin':
        query = query.filter(User.school_id == current_admin.school_id)
    
    enrollments = query.all()
    
    result = []
    for enrollment in enrollments:
        student = db.query(User).filter(User.id == enrollment.user_id).first()
        if student:
            result.append({
                'enrollment_id': enrollment.id,
                'student_id': student.id,
                'student_name': student.name or student.real_name,
                'student_number': student.student_number,
                'enrolled_at': enrollment.enrolled_at.isoformat() if enrollment.enrolled_at else None,
                'progress': enrollment.progress,
                'final_score': enrollment.final_score
            })
    
    return success_response(data=result)

@router.post("/course/{course_id}/batch-enroll")
def batch_enroll_students(
    course_id: int,
    request: BatchEnrollRequest,
    db: Session = Depends(get_db),
    current_admin: Admin = Depends(get_current_admin)
):
    """批量为学生选课（学校管理员）"""
    student_ids = request.student_ids
    # 检查课程是否存在
    course = db.query(PBLCourse).filter(PBLCourse.id == course_id).first()
    if not course:
        return error_response(
            message="课程不存在",
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
    
    # ★ 新增：学校管理员只能为本校学生分配本校课程
    if current_admin.role in ['school_admin', 'teacher'] and current_admin.school_id:
        # 检查课程是否已分配给学校
        school_course = db.query(PBLSchoolCourse).filter(
            PBLSchoolCourse.school_id == current_admin.school_id,
            PBLSchoolCourse.course_id == course_id,
            PBLSchoolCourse.status == 'active'
        ).first()
        
        if not school_course:
            return error_response(
                message="该课程未分配给您的学校",
                code=403,
                status_code=status.HTTP_403_FORBIDDEN
            )
    
    # 批量创建选课记录
    enrolled_count = 0
    school_courses_to_update = {}  # 记录需要更新的学校课程
    
    for student_id in student_ids:
        # 检查学生是否存在
        student = db.query(User).filter(
            User.id == student_id,
            User.role == 'student'
        ).first()
        
        if not student:
            continue
        
        # ★ 新增：学校管理员只能为本校学生分配课程
        if current_admin.role in ['school_admin', 'teacher']:
            if student.school_id != current_admin.school_id:
                continue
        
        # 检查是否已经有选课记录(不论状态)
        existing_enrollment = db.query(PBLCourseEnrollment).filter(
            PBLCourseEnrollment.course_id == course_id,
            PBLCourseEnrollment.user_id == student_id
        ).first()
        
        if existing_enrollment:
            # 如果已经是enrolled状态,跳过
            if existing_enrollment.enrollment_status == 'enrolled':
                continue
            # 如果是其他状态(如dropped),更新为enrolled
            existing_enrollment.enrollment_status = 'enrolled'
            existing_enrollment.enrolled_at = get_beijing_time_naive()
            existing_enrollment.dropped_at = None
            enrolled_count += 1
        else:
            # 创建新的选课记录
            enrollment = PBLCourseEnrollment(
                course_id=course_id,
                user_id=student_id,
                enrollment_status='enrolled',
                enrolled_at=get_beijing_time_naive()
            )
            db.add(enrollment)
            enrolled_count += 1
        
        # ★ 新增：记录需要更新的学校课程
        if student.school_id:
            if student.school_id not in school_courses_to_update:
                school_courses_to_update[student.school_id] = 0
            school_courses_to_update[student.school_id] += 1
    
    # ★ 新增：更新学校课程的当前学生数
    for school_id, count in school_courses_to_update.items():
        school_course = db.query(PBLSchoolCourse).filter(
            PBLSchoolCourse.school_id == school_id,
            PBLSchoolCourse.course_id == course_id
        ).first()
        if school_course:
            school_course.current_students += count
    
    db.commit()
    
    logger.info(f"批量选课 - 课程: {course.title}, 学生数: {enrolled_count}, 操作者: {current_admin.username}")
    
    return success_response(
        data={'enrolled_count': enrolled_count},
        message=f"成功为 {enrolled_count} 名学生选课"
    )
