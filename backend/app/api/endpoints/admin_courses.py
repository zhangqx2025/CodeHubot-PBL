from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List, Optional

from ...db.session import SessionLocal
from ...core.response import success_response, error_response
from ...core.deps import get_db, get_current_admin
from ...models.admin import Admin
from ...models.pbl import PBLCourse
from ...schemas.pbl import CourseBase, Course

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

@router.get("/{course_id}")
def get_course(
    course_id: int,
    db: Session = Depends(get_db),
    current_admin: Admin = Depends(get_current_admin)
):
    """获取课程详情"""
    course = db.query(PBLCourse).filter(PBLCourse.id == course_id).first()
    if not course:
        return error_response(
            message="课程不存在",
            code=404,
            status_code=status.HTTP_404_NOT_FOUND
        )
    
    return success_response(data=serialize_course(course))

@router.put("/{course_id}")
def update_course(
    course_id: int,
    course_data: CourseBase,
    db: Session = Depends(get_db),
    current_admin: Admin = Depends(get_current_admin)
):
    """更新课程"""
    course = db.query(PBLCourse).filter(PBLCourse.id == course_id).first()
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

@router.delete("/{course_id}")
def delete_course(
    course_id: int,
    db: Session = Depends(get_db),
    current_admin: Admin = Depends(get_current_admin)
):
    """删除课程"""
    course = db.query(PBLCourse).filter(PBLCourse.id == course_id).first()
    if not course:
        return error_response(
            message="课程不存在",
            code=404,
            status_code=status.HTTP_404_NOT_FOUND
        )
    
    db.delete(course)
    db.commit()
    
    return success_response(message="课程删除成功")

@router.patch("/{course_id}/status")
def update_course_status(
    course_id: int,
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
    
    course = db.query(PBLCourse).filter(PBLCourse.id == course_id).first()
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
