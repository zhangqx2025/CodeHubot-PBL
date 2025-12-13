"""
PBL成长档案API端点
"""
from typing import Optional
from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.orm import Session
from sqlalchemy import func
from datetime import datetime
from app.utils.timezone import get_beijing_time_naive

from app.core.deps import get_db, get_current_user, get_current_admin
from app.models.pbl import PBLStudentPortfolio, PBLUserAchievement, PBLAchievement
from app.models.admin import User

router = APIRouter()


@router.get("/admin/portfolios")
async def get_all_portfolios(
    skip: int = Query(0, ge=0),
    limit: int = Query(20, ge=1, le=100),
    school_year: Optional[str] = None,
    grade_level: Optional[str] = None,
    db: Session = Depends(get_db),
    current_admin = Depends(get_current_admin)
):
    """
    管理员获取所有学生成长档案列表
    """
    query = db.query(PBLStudentPortfolio)
    
    # 过滤条件
    if school_year:
        query = query.filter(PBLStudentPortfolio.school_year == school_year)
    if grade_level:
        query = query.filter(PBLStudentPortfolio.grade_level == grade_level)
    
    # 获取总数
    total = query.count()
    
    # 分页查询
    portfolios = query.offset(skip).limit(limit).all()
    
    # 获取学生信息
    items = []
    for portfolio in portfolios:
        student = db.query(User).filter(User.id == portfolio.student_id).first()
        items.append({
            "uuid": portfolio.uuid,
            "student_id": portfolio.student_id,
            "student_name": student.full_name if student else "未知",
            "school_year": portfolio.school_year,
            "grade_level": portfolio.grade_level,
            "projects_count": portfolio.projects_count,
            "total_learning_hours": portfolio.total_learning_hours,
            "avg_score": float(portfolio.avg_score) if portfolio.avg_score else 0.0,
            "created_at": portfolio.created_at.isoformat() if portfolio.created_at else None,
            "updated_at": portfolio.updated_at.isoformat() if portfolio.updated_at else None
        })
    
    return {
        "items": items,
        "total": total,
        "skip": skip,
        "limit": limit
    }


@router.get("/my-portfolio")
async def get_my_portfolio(
    school_year: Optional[str] = None,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """
    获取当前用户的成长档案
    """
    if not school_year:
        school_year = "2024-2025"  # 默认当前学年
    
    portfolio = db.query(PBLStudentPortfolio).filter(
        PBLStudentPortfolio.student_id == current_user.id,
        PBLStudentPortfolio.school_year == school_year
    ).first()
    
    if not portfolio:
        # 创建新档案
        portfolio = PBLStudentPortfolio(
            student_id=current_user.id,
            school_year=school_year,
            grade_level="5-6年级",  # 默认值,应根据实际情况设置
            projects_count=0,
            total_learning_hours=0
        )
        db.add(portfolio)
        db.commit()
        db.refresh(portfolio)
    
    return {
        "uuid": portfolio.uuid,
        "student_id": portfolio.student_id,
        "school_year": portfolio.school_year,
        "grade_level": portfolio.grade_level,
        "projects_count": portfolio.projects_count,
        "total_learning_hours": portfolio.total_learning_hours,
        "avg_score": float(portfolio.avg_score) if portfolio.avg_score else 0,
        "skill_assessment": portfolio.skill_assessment or {},
        "achievements": portfolio.achievements or [],
        "completed_projects": portfolio.completed_projects or [],
        "growth_trajectory": portfolio.growth_trajectory,
        "highlights": portfolio.highlights,
        "teacher_comments": portfolio.teacher_comments,
        "self_reflection": portfolio.self_reflection,
        "parent_feedback": portfolio.parent_feedback,
        "created_at": portfolio.created_at.isoformat() if portfolio.created_at else None,
        "updated_at": portfolio.updated_at.isoformat() if portfolio.updated_at else None
    }


@router.get("/students/{student_id}/portfolio")
async def get_student_portfolio(
    student_id: int,
    school_year: Optional[str] = None,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """
    获取指定学生的成长档案
    """
    if not school_year:
        school_year = "2024-2025"
    
    portfolio = db.query(PBLStudentPortfolio).filter(
        PBLStudentPortfolio.student_id == student_id,
        PBLStudentPortfolio.school_year == school_year
    ).first()
    
    if not portfolio:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="成长档案不存在")
    
    student = db.query(User).filter(User.id == student_id).first()
    
    return {
        "uuid": portfolio.uuid,
        "student_id": portfolio.student_id,
        "student_name": student.full_name if student else None,
        "school_year": portfolio.school_year,
        "grade_level": portfolio.grade_level,
        "projects_count": portfolio.projects_count,
        "total_learning_hours": portfolio.total_learning_hours,
        "avg_score": float(portfolio.avg_score) if portfolio.avg_score else 0,
        "skill_assessment": portfolio.skill_assessment or {},
        "achievements": portfolio.achievements or [],
        "completed_projects": portfolio.completed_projects or [],
        "growth_trajectory": portfolio.growth_trajectory,
        "highlights": portfolio.highlights,
        "teacher_comments": portfolio.teacher_comments,
        "self_reflection": portfolio.self_reflection,
        "parent_feedback": portfolio.parent_feedback
    }


@router.put("/portfolios/{portfolio_uuid}/reflection")
async def update_self_reflection(
    portfolio_uuid: str,
    reflection_data: dict,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """
    更新自我反思
    """
    portfolio = db.query(PBLStudentPortfolio).filter(PBLStudentPortfolio.uuid == portfolio_uuid).first()
    
    if not portfolio:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="成长档案不存在")
    
    # 权限检查
    if portfolio.student_id != current_user.id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="无权限修改此档案")
    
    portfolio.self_reflection = reflection_data.get("content")
    db.commit()
    
    return {"message": "更新成功"}


@router.put("/portfolios/{portfolio_uuid}/teacher-comments")
async def update_teacher_comments(
    portfolio_uuid: str,
    comments_data: dict,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """
    更新教师评语
    """
    portfolio = db.query(PBLStudentPortfolio).filter(PBLStudentPortfolio.uuid == portfolio_uuid).first()
    
    if not portfolio:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="成长档案不存在")
    
    portfolio.teacher_comments = comments_data.get("comments")
    db.commit()
    
    return {"message": "更新成功"}


@router.get("/students/{student_id}/achievements")
async def get_student_achievements(
    student_id: int,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """
    获取学生成就列表
    """
    # 这里需要PBLUserAchievement和PBLAchievement模型,暂时返回空
    # 实际应该查询 pbl_user_achievements 表
    return []


@router.get("/achievements")
async def get_achievements(
    skip: int = Query(0, ge=0),
    limit: int = Query(10, ge=1, le=100),
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """
    获取成就列表
    """
    # 这里需要PBLAchievement模型,暂时返回空
    # 实际应该查询 pbl_achievements 表
    return {
        "items": [],
        "total": 0
    }


@router.get("/portfolios/{portfolio_uuid}/export")
async def export_portfolio(
    portfolio_uuid: str,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """
    导出成长档案
    """
    portfolio = db.query(PBLStudentPortfolio).filter(PBLStudentPortfolio.uuid == portfolio_uuid).first()
    
    if not portfolio:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="成长档案不存在")
    
    # 简单实现:返回JSON数据
    # 实际应该生成PDF或其他格式
    return {
        "portfolio_data": {
            "student_id": portfolio.student_id,
            "school_year": portfolio.school_year,
            "grade_level": portfolio.grade_level,
            "projects_count": portfolio.projects_count,
            "total_learning_hours": portfolio.total_learning_hours,
            "avg_score": float(portfolio.avg_score) if portfolio.avg_score else 0,
            "completed_projects": portfolio.completed_projects,
            "achievements": portfolio.achievements,
            "skill_assessment": portfolio.skill_assessment
        },
        "export_format": "json",
        "export_time": get_beijing_time_naive().isoformat()
    }
