from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List, Optional

from ...db.session import SessionLocal
from ...core.response import success_response, error_response
from ...core.deps import get_db, get_current_admin
from ...models.admin import Admin
from ...models.pbl import PBLUnit, PBLCourse
from ...schemas.pbl import UnitCreate, UnitUpdate, Unit

router = APIRouter()

def serialize_unit(unit: PBLUnit) -> dict:
    """将 Unit 模型转换为字典"""
    return Unit.model_validate(unit).model_dump(mode='json')

def serialize_units(units: List[PBLUnit]) -> List[dict]:
    """将 Unit 模型列表转换为字典列表"""
    return [serialize_unit(unit) for unit in units]

@router.get("/course/{course_id}")
def get_units_by_course(
    course_id: int,
    db: Session = Depends(get_db),
    current_admin: Admin = Depends(get_current_admin)
):
    """获取课程下的所有学习单元"""
    # 验证课程是否存在
    course = db.query(PBLCourse).filter(PBLCourse.id == course_id).first()
    if not course:
        return error_response(
            message="课程不存在",
            code=404,
            status_code=status.HTTP_404_NOT_FOUND
        )
    
    units = db.query(PBLUnit).filter(PBLUnit.course_id == course_id).order_by(PBLUnit.order).all()
    return success_response(data=serialize_units(units))

@router.post("")
def create_unit(
    unit_data: UnitCreate,
    db: Session = Depends(get_db),
    current_admin: Admin = Depends(get_current_admin)
):
    """创建学习单元"""
    # 验证课程是否存在
    course = db.query(PBLCourse).filter(PBLCourse.id == unit_data.course_id).first()
    if not course:
        return error_response(
            message="课程不存在",
            code=404,
            status_code=status.HTTP_404_NOT_FOUND
        )
    
    new_unit = PBLUnit(
        course_id=unit_data.course_id,
        title=unit_data.title,
        description=unit_data.description,
        order=unit_data.order or 0,
        status=unit_data.status or 'locked',
        learning_guide=unit_data.learning_guide
    )
    
    db.add(new_unit)
    db.commit()
    db.refresh(new_unit)
    
    return success_response(data=serialize_unit(new_unit), message="学习单元创建成功")

@router.get("/{unit_id}")
def get_unit(
    unit_id: int,
    db: Session = Depends(get_db),
    current_admin: Admin = Depends(get_current_admin)
):
    """获取学习单元详情"""
    unit = db.query(PBLUnit).filter(PBLUnit.id == unit_id).first()
    if not unit:
        return error_response(
            message="学习单元不存在",
            code=404,
            status_code=status.HTTP_404_NOT_FOUND
        )
    
    return success_response(data=serialize_unit(unit))

@router.put("/{unit_id}")
def update_unit(
    unit_id: int,
    unit_data: UnitUpdate,
    db: Session = Depends(get_db),
    current_admin: Admin = Depends(get_current_admin)
):
    """更新学习单元"""
    unit = db.query(PBLUnit).filter(PBLUnit.id == unit_id).first()
    if not unit:
        return error_response(
            message="学习单元不存在",
            code=404,
            status_code=status.HTTP_404_NOT_FOUND
        )
    
    # 更新字段
    for field, value in unit_data.dict(exclude_unset=True).items():
        setattr(unit, field, value)
    
    db.commit()
    db.refresh(unit)
    
    return success_response(data=serialize_unit(unit), message="学习单元更新成功")

@router.delete("/{unit_id}")
def delete_unit(
    unit_id: int,
    db: Session = Depends(get_db),
    current_admin: Admin = Depends(get_current_admin)
):
    """删除学习单元"""
    unit = db.query(PBLUnit).filter(PBLUnit.id == unit_id).first()
    if not unit:
        return error_response(
            message="学习单元不存在",
            code=404,
            status_code=status.HTTP_404_NOT_FOUND
        )
    
    db.delete(unit)
    db.commit()
    
    return success_response(message="学习单元删除成功")

@router.patch("/{unit_id}/status")
def update_unit_status(
    unit_id: int,
    new_status: str,
    db: Session = Depends(get_db),
    current_admin: Admin = Depends(get_current_admin)
):
    """更新学习单元状态"""
    if new_status not in ['locked', 'available', 'completed']:
        return error_response(
            message="无效的状态值",
            code=400,
            status_code=status.HTTP_400_BAD_REQUEST
        )
    
    unit = db.query(PBLUnit).filter(PBLUnit.id == unit_id).first()
    if not unit:
        return error_response(
            message="学习单元不存在",
            code=404,
            status_code=status.HTTP_404_NOT_FOUND
        )
    
    unit.status = new_status
    db.commit()
    db.refresh(unit)
    
    return success_response(data=serialize_unit(unit), message="学习单元状态更新成功")
