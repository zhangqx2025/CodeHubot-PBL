"""
PBL数据集管理API端点
"""
from typing import Optional
from fastapi import APIRouter, Depends, HTTPException, Query, File, UploadFile, status
from sqlalchemy.orm import Session
import os
from datetime import datetime
from app.utils.timezone import get_beijing_time_naive

from app.core.deps import get_db, get_current_user
from app.models.pbl import PBLDataset
from app.models.admin import User

router = APIRouter()


@router.get("/datasets")
async def get_datasets(
    skip: int = Query(0, ge=0),
    limit: int = Query(10, ge=1, le=100),
    data_type: Optional[str] = None,
    category: Optional[str] = None,
    grade_level: Optional[str] = None,
    is_public: Optional[bool] = None,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """
    获取数据集列表
    """
    query = db.query(PBLDataset)
    
    if data_type:
        query = query.filter(PBLDataset.data_type == data_type)
    if category:
        query = query.filter(PBLDataset.category == category)
    if grade_level:
        query = query.filter(PBLDataset.grade_level == grade_level)
    if is_public is not None:
        query = query.filter(PBLDataset.is_public == is_public)
    
    total = query.count()
    datasets = query.offset(skip).limit(limit).all()
    
    items = []
    for dataset in datasets:
        creator = db.query(User).filter(User.id == dataset.creator_id).first() if dataset.creator_id else None
        items.append({
            "id": dataset.id,
            "uuid": dataset.uuid,
            "name": dataset.name,
            "description": dataset.description,
            "data_type": dataset.data_type,
            "category": dataset.category,
            "file_url": dataset.file_url,
            "file_size": dataset.file_size,
            "sample_count": dataset.sample_count,
            "class_count": dataset.class_count,
            "classes": dataset.classes,
            "is_labeled": dataset.is_labeled,
            "grade_level": dataset.grade_level,
            "is_public": dataset.is_public,
            "download_count": dataset.download_count,
            "quality_score": float(dataset.quality_score) if dataset.quality_score else None,
            "creator_name": creator.full_name if creator else None,
            "created_at": dataset.created_at.isoformat() if dataset.created_at else None
        })
    
    return {
        "items": items,
        "total": total
    }


@router.get("/datasets/{dataset_uuid}")
async def get_dataset_detail(
    dataset_uuid: str,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """
    获取数据集详情
    """
    dataset = db.query(PBLDataset).filter(PBLDataset.uuid == dataset_uuid).first()
    
    if not dataset:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="数据集不存在")
    
    creator = db.query(User).filter(User.id == dataset.creator_id).first() if dataset.creator_id else None
    
    return {
        "id": dataset.id,
        "uuid": dataset.uuid,
        "name": dataset.name,
        "description": dataset.description,
        "data_type": dataset.data_type,
        "category": dataset.category,
        "file_url": dataset.file_url,
        "file_size": dataset.file_size,
        "sample_count": dataset.sample_count,
        "class_count": dataset.class_count,
        "classes": dataset.classes,
        "is_labeled": dataset.is_labeled,
        "label_format": dataset.label_format,
        "split_ratio": dataset.split_ratio,
        "grade_level": dataset.grade_level,
        "applicable_projects": dataset.applicable_projects,
        "source": dataset.source,
        "license": dataset.license,
        "preview_images": dataset.preview_images,
        "download_count": dataset.download_count,
        "is_public": dataset.is_public,
        "quality_score": float(dataset.quality_score) if dataset.quality_score else None,
        "creator_id": dataset.creator_id,
        "creator_name": creator.full_name if creator else None,
        "school_id": dataset.school_id,
        "created_at": dataset.created_at.isoformat() if dataset.created_at else None,
        "updated_at": dataset.updated_at.isoformat() if dataset.updated_at else None
    }


@router.post("/datasets")
async def create_dataset(
    dataset_data: dict,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """
    创建数据集
    """
    new_dataset = PBLDataset(
        name=dataset_data.get("name"),
        description=dataset_data.get("description"),
        data_type=dataset_data.get("data_type"),
        category=dataset_data.get("category"),
        file_url=dataset_data.get("file_url"),
        file_size=dataset_data.get("file_size"),
        sample_count=dataset_data.get("sample_count"),
        class_count=dataset_data.get("class_count"),
        classes=dataset_data.get("classes"),
        is_labeled=dataset_data.get("is_labeled", False),
        label_format=dataset_data.get("label_format"),
        split_ratio=dataset_data.get("split_ratio"),
        grade_level=dataset_data.get("grade_level"),
        applicable_projects=dataset_data.get("applicable_projects"),
        source=dataset_data.get("source"),
        license=dataset_data.get("license"),
        preview_images=dataset_data.get("preview_images"),
        creator_id=current_user.id,
        school_id=current_user.school_id,
        is_public=dataset_data.get("is_public", True)
    )
    
    db.add(new_dataset)
    db.commit()
    db.refresh(new_dataset)
    
    return {
        "id": new_dataset.id,
        "uuid": new_dataset.uuid,
        "name": new_dataset.name,
        "created_at": new_dataset.created_at.isoformat() if new_dataset.created_at else None
    }


@router.put("/datasets/{dataset_uuid}")
async def update_dataset(
    dataset_uuid: str,
    dataset_data: dict,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """
    更新数据集
    """
    dataset = db.query(PBLDataset).filter(PBLDataset.uuid == dataset_uuid).first()
    
    if not dataset:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="数据集不存在")
    
    # 权限检查
    if dataset.creator_id != current_user.id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="无权限修改此数据集")
    
    # 更新字段
    if "name" in dataset_data:
        dataset.name = dataset_data["name"]
    if "description" in dataset_data:
        dataset.description = dataset_data["description"]
    if "category" in dataset_data:
        dataset.category = dataset_data["category"]
    if "sample_count" in dataset_data:
        dataset.sample_count = dataset_data["sample_count"]
    if "class_count" in dataset_data:
        dataset.class_count = dataset_data["class_count"]
    if "classes" in dataset_data:
        dataset.classes = dataset_data["classes"]
    if "is_labeled" in dataset_data:
        dataset.is_labeled = dataset_data["is_labeled"]
    if "label_format" in dataset_data:
        dataset.label_format = dataset_data["label_format"]
    if "split_ratio" in dataset_data:
        dataset.split_ratio = dataset_data["split_ratio"]
    if "applicable_projects" in dataset_data:
        dataset.applicable_projects = dataset_data["applicable_projects"]
    if "preview_images" in dataset_data:
        dataset.preview_images = dataset_data["preview_images"]
    
    db.commit()
    db.refresh(dataset)
    
    return {
        "id": dataset.id,
        "uuid": dataset.uuid,
        "name": dataset.name,
        "updated_at": dataset.updated_at.isoformat() if dataset.updated_at else None
    }


@router.delete("/datasets/{dataset_uuid}")
async def delete_dataset(
    dataset_uuid: str,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """
    删除数据集
    """
    dataset = db.query(PBLDataset).filter(PBLDataset.uuid == dataset_uuid).first()
    
    if not dataset:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="数据集不存在")
    
    # 权限检查
    if dataset.creator_id != current_user.id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="无权限删除此数据集")
    
    db.delete(dataset)
    db.commit()
    
    return {"message": "删除成功"}


@router.post("/datasets/upload")
async def upload_dataset_file(
    file: UploadFile = File(...),
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """
    上传数据集文件
    """
    # 创建上传目录
    upload_dir = "uploads/datasets"
    os.makedirs(upload_dir, exist_ok=True)
    
    # 生成唯一文件名
    timestamp = get_beijing_time_naive().strftime("%Y%m%d%H%M%S")
    file_extension = os.path.splitext(file.filename)[1]
    filename = f"{current_user.id}_{timestamp}{file_extension}"
    file_path = os.path.join(upload_dir, filename)
    
    # 保存文件
    with open(file_path, "wb") as buffer:
        content = await file.read()
        buffer.write(content)
    
    file_size = len(content)
    file_url = f"/{file_path}"
    
    return {
        "file_url": file_url,
        "file_size": file_size,
        "message": "上传成功"
    }


@router.get("/datasets/{dataset_uuid}/download")
async def download_dataset(
    dataset_uuid: str,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """
    下载数据集
    """
    dataset = db.query(PBLDataset).filter(PBLDataset.uuid == dataset_uuid).first()
    
    if not dataset:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="数据集不存在")
    
    # 增加下载次数
    dataset.download_count += 1
    db.commit()
    
    return {
        "file_url": dataset.file_url,
        "file_name": dataset.name,
        "file_size": dataset.file_size
    }


@router.put("/datasets/{dataset_uuid}/public")
async def update_dataset_public_status(
    dataset_uuid: str,
    public_data: dict,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """
    更新数据集公开状态
    """
    dataset = db.query(PBLDataset).filter(PBLDataset.uuid == dataset_uuid).first()
    
    if not dataset:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="数据集不存在")
    
    # 权限检查
    if dataset.creator_id != current_user.id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="无权限修改此数据集")
    
    dataset.is_public = public_data.get("is_public", True)
    db.commit()
    
    return {"message": "更新成功", "is_public": dataset.is_public}


@router.post("/datasets/{dataset_uuid}/rate")
async def rate_dataset(
    dataset_uuid: str,
    rate_data: dict,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """
    评价数据集质量
    """
    dataset = db.query(PBLDataset).filter(PBLDataset.uuid == dataset_uuid).first()
    
    if not dataset:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="数据集不存在")
    
    # 简单实现:直接设置评分
    # 实际应该计算多个用户的平均评分
    quality_score = rate_data.get("quality_score")
    if quality_score and 0 <= quality_score <= 5:
        dataset.quality_score = quality_score
        db.commit()
    
    return {"message": "评分成功", "quality_score": float(dataset.quality_score) if dataset.quality_score else None}
