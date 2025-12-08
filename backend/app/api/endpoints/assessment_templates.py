"""
PBL评价模板API端点
"""
from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.orm import Session

from app.core.deps import get_db, get_current_user
from app.models.pbl import PBLAssessmentTemplate
from app.models.admin import User

router = APIRouter()


@router.get("/assessment-templates")
async def get_assessment_templates(
    skip: int = Query(0, ge=0),
    limit: int = Query(10, ge=1, le=100),
    applicable_to: Optional[str] = None,
    grade_level: Optional[str] = None,
    is_active: Optional[bool] = None,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """
    获取评价模板列表
    """
    query = db.query(PBLAssessmentTemplate)
    
    if applicable_to:
        query = query.filter(PBLAssessmentTemplate.applicable_to == applicable_to)
    if grade_level:
        query = query.filter(PBLAssessmentTemplate.grade_level == grade_level)
    if is_active is not None:
        query = query.filter(PBLAssessmentTemplate.is_active == is_active)
    
    total = query.count()
    templates = query.offset(skip).limit(limit).all()
    
    items = []
    for template in templates:
        items.append({
            "id": template.id,
            "uuid": template.uuid,
            "name": template.name,
            "description": template.description,
            "applicable_to": template.applicable_to,
            "grade_level": template.grade_level,
            "dimensions": template.dimensions,
            "is_system": template.is_system,
            "is_active": template.is_active,
            "created_at": template.created_at.isoformat() if template.created_at else None
        })
    
    return {
        "items": items,
        "total": total
    }


@router.post("/assessment-templates")
async def create_assessment_template(
    template_data: dict,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """
    创建评价模板
    """
    new_template = PBLAssessmentTemplate(
        name=template_data.get("name"),
        description=template_data.get("description"),
        applicable_to=template_data.get("applicable_to"),
        grade_level=template_data.get("grade_level"),
        dimensions=template_data.get("dimensions"),
        created_by=current_user.id,
        is_system=False,
        is_active=template_data.get("is_active", True)
    )
    
    db.add(new_template)
    db.commit()
    db.refresh(new_template)
    
    return {
        "id": new_template.id,
        "uuid": new_template.uuid,
        "name": new_template.name,
        "description": new_template.description,
        "applicable_to": new_template.applicable_to,
        "grade_level": new_template.grade_level,
        "dimensions": new_template.dimensions,
        "created_at": new_template.created_at.isoformat() if new_template.created_at else None
    }


@router.get("/assessment-templates/{template_uuid}")
async def get_assessment_template_detail(
    template_uuid: str,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """
    获取评价模板详情
    """
    template = db.query(PBLAssessmentTemplate).filter(PBLAssessmentTemplate.uuid == template_uuid).first()
    
    if not template:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="评价模板不存在")
    
    creator = None
    if template.created_by:
        creator = db.query(User).filter(User.id == template.created_by).first()
    
    return {
        "id": template.id,
        "uuid": template.uuid,
        "name": template.name,
        "description": template.description,
        "applicable_to": template.applicable_to,
        "grade_level": template.grade_level,
        "dimensions": template.dimensions,
        "is_system": template.is_system,
        "is_active": template.is_active,
        "created_by": template.created_by,
        "creator_name": creator.full_name if creator else None,
        "created_at": template.created_at.isoformat() if template.created_at else None,
        "updated_at": template.updated_at.isoformat() if template.updated_at else None
    }


@router.put("/assessment-templates/{template_uuid}")
async def update_assessment_template(
    template_uuid: str,
    template_data: dict,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """
    更新评价模板
    """
    template = db.query(PBLAssessmentTemplate).filter(PBLAssessmentTemplate.uuid == template_uuid).first()
    
    if not template:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="评价模板不存在")
    
    # 系统模板不能修改
    if template.is_system:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="系统模板不可修改")
    
    # 权限检查:只有创建者可以修改
    if template.created_by != current_user.id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="无权限修改此模板")
    
    # 更新字段
    if "name" in template_data:
        template.name = template_data["name"]
    if "description" in template_data:
        template.description = template_data["description"]
    if "applicable_to" in template_data:
        template.applicable_to = template_data["applicable_to"]
    if "grade_level" in template_data:
        template.grade_level = template_data["grade_level"]
    if "dimensions" in template_data:
        template.dimensions = template_data["dimensions"]
    if "is_active" in template_data:
        template.is_active = template_data["is_active"]
    
    db.commit()
    db.refresh(template)
    
    return {
        "id": template.id,
        "uuid": template.uuid,
        "name": template.name,
        "updated_at": template.updated_at.isoformat() if template.updated_at else None
    }


@router.delete("/assessment-templates/{template_uuid}")
async def delete_assessment_template(
    template_uuid: str,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """
    删除评价模板
    """
    template = db.query(PBLAssessmentTemplate).filter(PBLAssessmentTemplate.uuid == template_uuid).first()
    
    if not template:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="评价模板不存在")
    
    # 系统模板不能删除
    if template.is_system:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="系统模板不可删除")
    
    # 权限检查
    if template.created_by != current_user.id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="无权限删除此模板")
    
    db.delete(template)
    db.commit()
    
    return {"message": "删除成功"}
