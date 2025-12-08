"""
PBL专家管理API端点
"""
from typing import Optional
from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.orm import Session

from app.core.deps import get_db, get_current_user
from app.models.pbl import PBLExternalExpert, PBLAssessment
from app.models.admin import User

router = APIRouter()


@router.get("/experts")
async def get_experts(
    skip: int = Query(0, ge=0),
    limit: int = Query(10, ge=1, le=100),
    is_active: Optional[bool] = None,
    expertise_area: Optional[str] = None,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """
    获取专家列表
    """
    query = db.query(PBLExternalExpert)
    
    if is_active is not None:
        query = query.filter(PBLExternalExpert.is_active == is_active)
    if expertise_area:
        query = query.filter(PBLExternalExpert.expertise_areas.contains(expertise_area))
    
    total = query.count()
    experts = query.offset(skip).limit(limit).all()
    
    items = []
    for expert in experts:
        items.append({
            "id": expert.id,
            "uuid": expert.uuid,
            "name": expert.name,
            "organization": expert.organization,
            "title": expert.title,
            "expertise_areas": expert.expertise_areas,
            "bio": expert.bio,
            "email": expert.email,
            "phone": expert.phone,
            "avatar": expert.avatar,
            "is_active": expert.is_active,
            "participated_projects": expert.participated_projects,
            "avg_rating": float(expert.avg_rating) if expert.avg_rating else None,
            "created_at": expert.created_at.isoformat() if expert.created_at else None
        })
    
    return {
        "items": items,
        "total": total
    }


@router.get("/experts/{expert_uuid}")
async def get_expert_detail(
    expert_uuid: str,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """
    获取专家详情
    """
    expert = db.query(PBLExternalExpert).filter(PBLExternalExpert.uuid == expert_uuid).first()
    
    if not expert:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="专家不存在")
    
    return {
        "id": expert.id,
        "uuid": expert.uuid,
        "name": expert.name,
        "organization": expert.organization,
        "title": expert.title,
        "expertise_areas": expert.expertise_areas,
        "bio": expert.bio,
        "email": expert.email,
        "phone": expert.phone,
        "avatar": expert.avatar,
        "is_active": expert.is_active,
        "participated_projects": expert.participated_projects,
        "avg_rating": float(expert.avg_rating) if expert.avg_rating else None,
        "created_at": expert.created_at.isoformat() if expert.created_at else None,
        "updated_at": expert.updated_at.isoformat() if expert.updated_at else None
    }


@router.post("/experts")
async def create_expert(
    expert_data: dict,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """
    创建专家
    """
    new_expert = PBLExternalExpert(
        name=expert_data.get("name"),
        organization=expert_data.get("organization"),
        title=expert_data.get("title"),
        expertise_areas=expert_data.get("expertise_areas", []),
        bio=expert_data.get("bio"),
        email=expert_data.get("email"),
        phone=expert_data.get("phone"),
        avatar=expert_data.get("avatar"),
        is_active=expert_data.get("is_active", True)
    )
    
    db.add(new_expert)
    db.commit()
    db.refresh(new_expert)
    
    return {
        "id": new_expert.id,
        "uuid": new_expert.uuid,
        "name": new_expert.name,
        "created_at": new_expert.created_at.isoformat() if new_expert.created_at else None
    }


@router.put("/experts/{expert_uuid}")
async def update_expert(
    expert_uuid: str,
    expert_data: dict,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """
    更新专家信息
    """
    expert = db.query(PBLExternalExpert).filter(PBLExternalExpert.uuid == expert_uuid).first()
    
    if not expert:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="专家不存在")
    
    # 更新字段
    if "name" in expert_data:
        expert.name = expert_data["name"]
    if "organization" in expert_data:
        expert.organization = expert_data["organization"]
    if "title" in expert_data:
        expert.title = expert_data["title"]
    if "expertise_areas" in expert_data:
        expert.expertise_areas = expert_data["expertise_areas"]
    if "bio" in expert_data:
        expert.bio = expert_data["bio"]
    if "email" in expert_data:
        expert.email = expert_data["email"]
    if "phone" in expert_data:
        expert.phone = expert_data["phone"]
    if "avatar" in expert_data:
        expert.avatar = expert_data["avatar"]
    if "is_active" in expert_data:
        expert.is_active = expert_data["is_active"]
    
    db.commit()
    db.refresh(expert)
    
    return {
        "id": expert.id,
        "uuid": expert.uuid,
        "name": expert.name,
        "updated_at": expert.updated_at.isoformat() if expert.updated_at else None
    }


@router.delete("/experts/{expert_uuid}")
async def delete_expert(
    expert_uuid: str,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """
    删除专家
    """
    expert = db.query(PBLExternalExpert).filter(PBLExternalExpert.uuid == expert_uuid).first()
    
    if not expert:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="专家不存在")
    
    db.delete(expert)
    db.commit()
    
    return {"message": "删除成功"}


# ==================== 专家评审 ====================

@router.post("/expert-reviews/invite")
async def invite_expert_review(
    invite_data: dict,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """
    邀请专家评审
    """
    expert_id = invite_data.get("expert_id")
    project_id = invite_data.get("project_id")
    
    expert = db.query(PBLExternalExpert).filter(PBLExternalExpert.id == expert_id).first()
    if not expert:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="专家不存在")
    
    # 这里应该发送邀请通知或邮件
    # 实际实现时需要添加通知功能
    
    return {"message": "邀请成功", "expert_name": expert.name}


@router.get("/expert-reviews")
async def get_expert_reviews(
    skip: int = Query(0, ge=0),
    limit: int = Query(10, ge=1, le=100),
    project_id: Optional[int] = None,
    expert_id: Optional[int] = None,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """
    获取专家评审列表
    """
    # 查询专家评价(assessor_role='expert')
    query = db.query(PBLAssessment).filter(PBLAssessment.assessor_role == "expert")
    
    if project_id:
        query = query.filter(
            PBLAssessment.target_type == "project",
            PBLAssessment.target_id == project_id
        )
    if expert_id:
        query = query.filter(PBLAssessment.assessor_id == expert_id)
    
    total = query.count()
    assessments = query.offset(skip).limit(limit).all()
    
    items = []
    for assessment in assessments:
        # 注意:这里 assessor_id 应该对应 expert 的 user_id,但专家可能没有 user 账号
        # 实际实现时需要建立专家和评价的关联
        items.append({
            "id": assessment.id,
            "uuid": assessment.uuid,
            "expert_id": assessment.assessor_id,
            "target_type": assessment.target_type,
            "target_id": assessment.target_id,
            "student_id": assessment.student_id,
            "dimensions": assessment.dimensions,
            "total_score": float(assessment.total_score) if assessment.total_score else None,
            "comments": assessment.comments,
            "created_at": assessment.created_at.isoformat() if assessment.created_at else None
        })
    
    return {
        "items": items,
        "total": total
    }


@router.post("/expert-reviews")
async def submit_expert_review(
    review_data: dict,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """
    提交专家评审
    """
    # 创建评价记录,角色为 expert
    dimensions = review_data.get("dimensions", [])
    total_score = 0
    if dimensions:
        for dim in dimensions:
            score = dim.get("score", 0)
            weight = dim.get("weight", 0)
            total_score += score * weight
    
    new_assessment = PBLAssessment(
        assessor_id=current_user.id,  # 这里应该是专家的ID
        assessor_role="expert",
        target_type=review_data.get("target_type", "project"),
        target_id=review_data.get("target_id"),
        student_id=review_data.get("student_id"),
        group_id=review_data.get("group_id"),
        assessment_type="summative",  # 专家评审通常是总结性评价
        dimensions=dimensions,
        total_score=total_score,
        max_score=review_data.get("max_score", 100.00),
        comments=review_data.get("comments"),
        strengths=review_data.get("strengths"),
        improvements=review_data.get("improvements"),
        tags=review_data.get("tags"),
        is_public=review_data.get("is_public", True)
    )
    
    db.add(new_assessment)
    db.commit()
    db.refresh(new_assessment)
    
    # 更新专家的参与项目数
    # 这里需要建立专家和user的关联
    
    return {
        "id": new_assessment.id,
        "uuid": new_assessment.uuid,
        "total_score": float(new_assessment.total_score) if new_assessment.total_score else None,
        "created_at": new_assessment.created_at.isoformat() if new_assessment.created_at else None
    }
