"""
PBL评价管理API端点
"""
from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.orm import Session
from sqlalchemy import func

from app.core.deps import get_db, get_current_user
from app.models.pbl import PBLAssessment
from app.models.admin import User

router = APIRouter()


@router.get("/assessments")
async def get_assessments(
    skip: int = Query(0, ge=0),
    limit: int = Query(10, ge=1, le=100),
    target_type: Optional[str] = None,
    assessor_role: Optional[str] = None,
    assessment_type: Optional[str] = None,
    student_id: Optional[int] = None,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """
    获取评价列表
    """
    query = db.query(PBLAssessment)
    
    if target_type:
        query = query.filter(PBLAssessment.target_type == target_type)
    if assessor_role:
        query = query.filter(PBLAssessment.assessor_role == assessor_role)
    if assessment_type:
        query = query.filter(PBLAssessment.assessment_type == assessment_type)
    if student_id:
        query = query.filter(PBLAssessment.student_id == student_id)
    
    total = query.count()
    assessments = query.offset(skip).limit(limit).all()
    
    items = []
    for assessment in assessments:
        assessor = db.query(User).filter(User.id == assessment.assessor_id).first()
        student = db.query(User).filter(User.id == assessment.student_id).first()
        
        items.append({
            "id": assessment.id,
            "uuid": assessment.uuid,
            "assessor_id": assessment.assessor_id,
            "assessor_name": assessor.full_name if assessor else None,
            "assessor_role": assessment.assessor_role,
            "target_type": assessment.target_type,
            "target_id": assessment.target_id,
            "student_id": assessment.student_id,
            "student_name": student.full_name if student else None,
            "assessment_type": assessment.assessment_type,
            "dimensions": assessment.dimensions,
            "total_score": float(assessment.total_score) if assessment.total_score else None,
            "max_score": float(assessment.max_score) if assessment.max_score else 100.0,
            "comments": assessment.comments,
            "tags": assessment.tags,
            "is_public": assessment.is_public,
            "created_at": assessment.created_at.isoformat() if assessment.created_at else None
        })
    
    return {
        "items": items,
        "total": total,
        "page": skip // limit + 1,
        "size": limit
    }


@router.post("/assessments")
async def create_assessment(
    assessment_data: dict,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """
    创建评价
    """
    # 计算总分
    dimensions = assessment_data.get("dimensions", [])
    total_score = 0
    if dimensions:
        for dim in dimensions:
            score = dim.get("score", 0)
            weight = dim.get("weight", 0)
            total_score += score * weight
    
    new_assessment = PBLAssessment(
        assessor_id=current_user.id,
        assessor_role=assessment_data.get("assessor_role", "teacher"),
        target_type=assessment_data.get("target_type"),
        target_id=assessment_data.get("target_id"),
        student_id=assessment_data.get("student_id"),
        group_id=assessment_data.get("group_id"),
        assessment_type=assessment_data.get("assessment_type", "formative"),
        dimensions=dimensions,
        total_score=total_score,
        max_score=assessment_data.get("max_score", 100.00),
        comments=assessment_data.get("comments"),
        strengths=assessment_data.get("strengths"),
        improvements=assessment_data.get("improvements"),
        tags=assessment_data.get("tags"),
        is_public=assessment_data.get("is_public", False)
    )
    
    db.add(new_assessment)
    db.commit()
    db.refresh(new_assessment)
    
    return {
        "id": new_assessment.id,
        "uuid": new_assessment.uuid,
        "assessor_id": new_assessment.assessor_id,
        "target_type": new_assessment.target_type,
        "target_id": new_assessment.target_id,
        "student_id": new_assessment.student_id,
        "total_score": float(new_assessment.total_score) if new_assessment.total_score else None,
        "created_at": new_assessment.created_at.isoformat() if new_assessment.created_at else None
    }


@router.get("/assessments/{assessment_uuid}")
async def get_assessment_detail(
    assessment_uuid: str,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """
    获取评价详情
    """
    assessment = db.query(PBLAssessment).filter(PBLAssessment.uuid == assessment_uuid).first()
    
    if not assessment:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="评价不存在")
    
    assessor = db.query(User).filter(User.id == assessment.assessor_id).first()
    student = db.query(User).filter(User.id == assessment.student_id).first()
    
    return {
        "id": assessment.id,
        "uuid": assessment.uuid,
        "assessor_id": assessment.assessor_id,
        "assessor_name": assessor.full_name if assessor else None,
        "assessor_role": assessment.assessor_role,
        "target_type": assessment.target_type,
        "target_id": assessment.target_id,
        "student_id": assessment.student_id,
        "student_name": student.full_name if student else None,
        "group_id": assessment.group_id,
        "assessment_type": assessment.assessment_type,
        "dimensions": assessment.dimensions,
        "total_score": float(assessment.total_score) if assessment.total_score else None,
        "max_score": float(assessment.max_score) if assessment.max_score else 100.0,
        "comments": assessment.comments,
        "strengths": assessment.strengths,
        "improvements": assessment.improvements,
        "tags": assessment.tags,
        "is_public": assessment.is_public,
        "created_at": assessment.created_at.isoformat() if assessment.created_at else None,
        "updated_at": assessment.updated_at.isoformat() if assessment.updated_at else None
    }


@router.put("/assessments/{assessment_uuid}")
async def update_assessment(
    assessment_uuid: str,
    assessment_data: dict,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """
    更新评价
    """
    assessment = db.query(PBLAssessment).filter(PBLAssessment.uuid == assessment_uuid).first()
    
    if not assessment:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="评价不存在")
    
    # 权限检查:只有评价者可以修改
    if assessment.assessor_id != current_user.id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="无权限修改此评价")
    
    # 更新字段
    if "dimensions" in assessment_data:
        assessment.dimensions = assessment_data["dimensions"]
        # 重新计算总分
        total_score = 0
        for dim in assessment_data["dimensions"]:
            score = dim.get("score", 0)
            weight = dim.get("weight", 0)
            total_score += score * weight
        assessment.total_score = total_score
    
    if "comments" in assessment_data:
        assessment.comments = assessment_data["comments"]
    if "strengths" in assessment_data:
        assessment.strengths = assessment_data["strengths"]
    if "improvements" in assessment_data:
        assessment.improvements = assessment_data["improvements"]
    if "tags" in assessment_data:
        assessment.tags = assessment_data["tags"]
    if "is_public" in assessment_data:
        assessment.is_public = assessment_data["is_public"]
    
    db.commit()
    db.refresh(assessment)
    
    return {
        "id": assessment.id,
        "uuid": assessment.uuid,
        "total_score": float(assessment.total_score) if assessment.total_score else None,
        "updated_at": assessment.updated_at.isoformat() if assessment.updated_at else None
    }


@router.delete("/assessments/{assessment_uuid}")
async def delete_assessment(
    assessment_uuid: str,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """
    删除评价
    """
    assessment = db.query(PBLAssessment).filter(PBLAssessment.uuid == assessment_uuid).first()
    
    if not assessment:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="评价不存在")
    
    # 权限检查
    if assessment.assessor_id != current_user.id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="无权限删除此评价")
    
    db.delete(assessment)
    db.commit()
    
    return {"message": "删除成功"}


@router.get("/students/{student_id}/assessment-stats")
async def get_student_assessment_stats(
    student_id: int,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """
    获取学生评价统计
    """
    assessments = db.query(PBLAssessment).filter(PBLAssessment.student_id == student_id).all()
    
    total_assessments = len(assessments)
    
    # 计算平均分
    scores = [float(a.total_score) for a in assessments if a.total_score]
    avg_score = sum(scores) / len(scores) if scores else 0
    
    # 统计各维度平均分
    dimension_scores = {}
    dimension_counts = {}
    
    for assessment in assessments:
        if assessment.dimensions:
            for dim in assessment.dimensions:
                dim_name = dim.get("name")
                dim_score = dim.get("score", 0)
                
                if dim_name:
                    if dim_name not in dimension_scores:
                        dimension_scores[dim_name] = 0
                        dimension_counts[dim_name] = 0
                    
                    dimension_scores[dim_name] += dim_score
                    dimension_counts[dim_name] += 1
    
    # 计算各维度平均分
    for dim_name in dimension_scores:
        if dimension_counts[dim_name] > 0:
            dimension_scores[dim_name] = round(dimension_scores[dim_name] / dimension_counts[dim_name], 2)
    
    return {
        "total_assessments": total_assessments,
        "avg_score": round(avg_score, 2),
        "dimension_scores": dimension_scores
    }
