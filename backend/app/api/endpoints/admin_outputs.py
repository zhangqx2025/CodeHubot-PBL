"""
管理员端 - 成果管理 API
"""
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from sqlalchemy import and_, or_, desc
from typing import Optional, List
from datetime import datetime

from app.core.deps import get_db, get_current_admin
from app.models.pbl import PBLProjectOutput, PBLProject
from app.models.admin import User
from pydantic import BaseModel, Field

router = APIRouter(prefix="/admin/outputs", tags=["管理员-成果管理"])


class OutputResponse(BaseModel):
    """成果响应模型"""
    id: int
    uuid: str
    title: str
    description: Optional[str]
    output_type: str
    file_url: Optional[str]
    file_size: Optional[int]
    file_type: Optional[str]
    repo_url: Optional[str]
    demo_url: Optional[str]
    thumbnail: Optional[str]
    is_public: bool
    view_count: int
    like_count: int
    created_at: datetime
    
    # 关联信息
    student_name: Optional[str]
    student_id: Optional[int]
    project_title: Optional[str]
    project_uuid: Optional[str]
    
    class Config:
        from_attributes = True


class UpdateOutputStatusRequest(BaseModel):
    """更新成果状态请求"""
    is_public: bool = Field(..., description="是否公开展示")


class OutputReviewRequest(BaseModel):
    """成果评审请求"""
    score: float = Field(..., ge=0, le=100, description="评分")
    feedback: str = Field(..., description="评审反馈")
    is_approved: bool = Field(True, description="是否通过")


@router.get("", response_model=dict)
async def get_outputs(
    db: Session = Depends(get_db),
    current_admin: User = Depends(get_current_admin),
    page: int = Query(1, ge=1, description="页码"),
    page_size: int = Query(20, ge=1, le=100, description="每页数量"),
    output_type: Optional[str] = Query(None, description="成果类型"),
    is_public: Optional[bool] = Query(None, description="是否公开"),
    search: Optional[str] = Query(None, description="搜索关键词"),
    project_uuid: Optional[str] = Query(None, description="项目UUID"),
    student_id: Optional[int] = Query(None, description="学生ID")
):
    """
    获取成果列表
    """
    # 构建查询
    query = db.query(
        PBLProjectOutput,
        User.name.label("student_name"),
        PBLProject.title.label("project_title"),
        PBLProject.uuid.label("project_uuid")
    ).join(
        PBLProject, PBLProjectOutput.project_id == PBLProject.id
    ).outerjoin(
        User, PBLProjectOutput.user_id == User.id
    )
    
    # 应用筛选条件
    if output_type:
        query = query.filter(PBLProjectOutput.output_type == output_type)
    
    if is_public is not None:
        query = query.filter(PBLProjectOutput.is_public == is_public)
    
    if project_uuid:
        query = query.filter(PBLProject.uuid == project_uuid)
    
    if student_id:
        query = query.filter(PBLProjectOutput.user_id == student_id)
    
    if search:
        search_filter = or_(
            PBLProjectOutput.title.like(f"%{search}%"),
            PBLProjectOutput.description.like(f"%{search}%"),
            User.name.like(f"%{search}%"),
            PBLProject.title.like(f"%{search}%")
        )
        query = query.filter(search_filter)
    
    # 排序
    query = query.order_by(desc(PBLProjectOutput.created_at))
    
    # 分页
    total = query.count()
    offset = (page - 1) * page_size
    items = query.offset(offset).limit(page_size).all()
    
    # 组装响应数据
    outputs = []
    for output, student_name, project_title, project_uuid in items:
        output_dict = {
            "id": output.id,
            "uuid": output.uuid,
            "title": output.title,
            "description": output.description,
            "output_type": output.output_type,
            "file_url": output.file_url,
            "file_size": output.file_size,
            "file_type": output.file_type,
            "repo_url": output.repo_url,
            "demo_url": output.demo_url,
            "thumbnail": output.thumbnail,
            "is_public": output.is_public,
            "view_count": output.view_count,
            "like_count": output.like_count,
            "created_at": output.created_at,
            "student_name": student_name,
            "student_id": output.user_id,
            "project_title": project_title,
            "project_uuid": project_uuid
        }
        outputs.append(output_dict)
    
    return {
        "total": total,
        "page": page,
        "page_size": page_size,
        "items": outputs
    }


@router.get("/{uuid}", response_model=OutputResponse)
async def get_output_detail(
    uuid: str,
    db: Session = Depends(get_db),
    current_admin: User = Depends(get_current_admin)
):
    """
    获取成果详情
    """
    result = db.query(
        PBLProjectOutput,
        User.name.label("student_name"),
        PBLProject.title.label("project_title"),
        PBLProject.uuid.label("project_uuid")
    ).join(
        PBLProject, PBLProjectOutput.project_id == PBLProject.id
    ).outerjoin(
        User, PBLProjectOutput.user_id == User.id
    ).filter(PBLProjectOutput.uuid == uuid).first()
    
    if not result:
        raise HTTPException(status_code=404, detail="成果不存在")
    
    output, student_name, project_title, project_uuid = result
    
    return OutputResponse(
        id=output.id,
        uuid=output.uuid,
        title=output.title,
        description=output.description,
        output_type=output.output_type,
        file_url=output.file_url,
        file_size=output.file_size,
        file_type=output.file_type,
        repo_url=output.repo_url,
        demo_url=output.demo_url,
        thumbnail=output.thumbnail,
        is_public=output.is_public,
        view_count=output.view_count,
        like_count=output.like_count,
        created_at=output.created_at,
        student_name=student_name,
        student_id=output.user_id,
        project_title=project_title,
        project_uuid=project_uuid
    )


@router.put("/{uuid}/status")
async def update_output_status(
    uuid: str,
    request: UpdateOutputStatusRequest,
    db: Session = Depends(get_db),
    current_admin: User = Depends(get_current_admin)
):
    """
    更新成果公开状态
    """
    output = db.query(PBLProjectOutput).filter(
        PBLProjectOutput.uuid == uuid
    ).first()
    
    if not output:
        raise HTTPException(status_code=404, detail="成果不存在")
    
    output.is_public = request.is_public
    db.commit()
    
    return {
        "message": "状态更新成功",
        "uuid": uuid,
        "is_public": request.is_public
    }


@router.post("/{uuid}/review")
async def review_output(
    uuid: str,
    request: OutputReviewRequest,
    db: Session = Depends(get_db),
    current_admin: User = Depends(get_current_admin)
):
    """
    评审成果
    """
    output = db.query(PBLProjectOutput).filter(
        PBLProjectOutput.uuid == uuid
    ).first()
    
    if not output:
        raise HTTPException(status_code=404, detail="成果不存在")
    
    # TODO: 创建评审记录（需要先实现评审表相关功能）
    # 这里先返回成功
    
    return {
        "message": "评审成功",
        "uuid": uuid,
        "score": request.score,
        "is_approved": request.is_approved
    }


@router.delete("/{uuid}")
async def delete_output(
    uuid: str,
    db: Session = Depends(get_db),
    current_admin: User = Depends(get_current_admin)
):
    """
    删除成果
    """
    output = db.query(PBLProjectOutput).filter(
        PBLProjectOutput.uuid == uuid
    ).first()
    
    if not output:
        raise HTTPException(status_code=404, detail="成果不存在")
    
    # TODO: 删除关联的文件
    
    db.delete(output)
    db.commit()
    
    return {
        "message": "成果删除成功",
        "uuid": uuid
    }


@router.get("/statistics/overview")
async def get_output_statistics(
    db: Session = Depends(get_db),
    current_admin: User = Depends(get_current_admin)
):
    """
    获取成果统计数据
    """
    from sqlalchemy import func
    
    # 总成果数
    total_outputs = db.query(func.count(PBLProjectOutput.id)).scalar()
    
    # 公开成果数
    public_outputs = db.query(func.count(PBLProjectOutput.id)).filter(
        PBLProjectOutput.is_public == True
    ).scalar()
    
    # 按类型统计
    type_stats = db.query(
        PBLProjectOutput.output_type,
        func.count(PBLProjectOutput.id).label('count')
    ).group_by(PBLProjectOutput.output_type).all()
    
    # 热门成果（按浏览量）
    hot_outputs = db.query(
        PBLProjectOutput.uuid,
        PBLProjectOutput.title,
        PBLProjectOutput.view_count,
        PBLProjectOutput.like_count
    ).order_by(desc(PBLProjectOutput.view_count)).limit(10).all()
    
    return {
        "total_outputs": total_outputs,
        "public_outputs": public_outputs,
        "private_outputs": total_outputs - public_outputs,
        "type_statistics": [
            {"type": t[0], "count": t[1]} for t in type_stats
        ],
        "hot_outputs": [
            {
                "uuid": h[0],
                "title": h[1],
                "view_count": h[2],
                "like_count": h[3]
            } for h in hot_outputs
        ]
    }
