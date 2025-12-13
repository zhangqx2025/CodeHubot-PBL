"""
PBL社会实践活动API端点
"""
from typing import Optional
from fastapi import APIRouter, Depends, HTTPException, Query, File, UploadFile, status
from sqlalchemy.orm import Session
import os
from datetime import datetime
from app.utils.timezone import get_beijing_time_naive

from app.core.deps import get_db, get_current_user
from app.models.pbl import PBLSocialActivity
from app.models.admin import User

router = APIRouter()


@router.get("/social-activities")
async def get_social_activities(
    skip: int = Query(0, ge=0),
    limit: int = Query(10, ge=1, le=100),
    activity_type: Optional[str] = None,
    status: Optional[str] = None,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """
    获取社会实践活动列表
    """
    query = db.query(PBLSocialActivity)
    
    if activity_type:
        query = query.filter(PBLSocialActivity.activity_type == activity_type)
    if status:
        query = query.filter(PBLSocialActivity.status == status)
    
    total = query.count()
    activities = query.offset(skip).limit(limit).all()
    
    items = []
    for activity in activities:
        items.append({
            "id": activity.id,
            "uuid": activity.uuid,
            "title": activity.title,
            "description": activity.description,
            "activity_type": activity.activity_type,
            "organizer": activity.organizer,
            "partner_organization": activity.partner_organization,
            "location": activity.location,
            "scheduled_at": activity.scheduled_at.isoformat() if activity.scheduled_at else None,
            "duration": activity.duration,
            "max_participants": activity.max_participants,
            "current_participants": activity.current_participants,
            "status": activity.status,
            "created_at": activity.created_at.isoformat() if activity.created_at else None
        })
    
    return {
        "items": items,
        "total": total
    }


@router.get("/my-social-activities")
async def get_my_social_activities(
    skip: int = Query(0, ge=0),
    limit: int = Query(10, ge=1, le=100),
    status: Optional[str] = None,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """
    获取我的社会实践活动
    """
    query = db.query(PBLSocialActivity)
    
    # 查询我参与的活动
    query = query.filter(PBLSocialActivity.participants.contains(str(current_user.id)))
    
    if status:
        query = query.filter(PBLSocialActivity.status == status)
    
    total = query.count()
    activities = query.offset(skip).limit(limit).all()
    
    items = []
    for activity in activities:
        items.append({
            "id": activity.id,
            "uuid": activity.uuid,
            "title": activity.title,
            "description": activity.description,
            "activity_type": activity.activity_type,
            "organizer": activity.organizer,
            "location": activity.location,
            "scheduled_at": activity.scheduled_at.isoformat() if activity.scheduled_at else None,
            "duration": activity.duration,
            "status": activity.status
        })
    
    return {
        "items": items,
        "total": total
    }


@router.get("/social-activities/{activity_uuid}")
async def get_social_activity_detail(
    activity_uuid: str,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """
    获取活动详情
    """
    activity = db.query(PBLSocialActivity).filter(PBLSocialActivity.uuid == activity_uuid).first()
    
    if not activity:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="活动不存在")
    
    return {
        "id": activity.id,
        "uuid": activity.uuid,
        "title": activity.title,
        "description": activity.description,
        "activity_type": activity.activity_type,
        "organizer": activity.organizer,
        "partner_organization": activity.partner_organization,
        "location": activity.location,
        "scheduled_at": activity.scheduled_at.isoformat() if activity.scheduled_at else None,
        "duration": activity.duration,
        "max_participants": activity.max_participants,
        "current_participants": activity.current_participants,
        "participants": activity.participants,
        "facilitators": activity.facilitators,
        "status": activity.status,
        "photos": activity.photos,
        "summary": activity.summary,
        "feedback": activity.feedback,
        "created_by": activity.created_by,
        "created_at": activity.created_at.isoformat() if activity.created_at else None,
        "updated_at": activity.updated_at.isoformat() if activity.updated_at else None
    }


@router.post("/social-activities")
async def create_social_activity(
    activity_data: dict,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """
    创建活动
    """
    new_activity = PBLSocialActivity(
        title=activity_data.get("title"),
        description=activity_data.get("description"),
        activity_type=activity_data.get("activity_type"),
        organizer=activity_data.get("organizer"),
        partner_organization=activity_data.get("partner_organization"),
        location=activity_data.get("location"),
        scheduled_at=activity_data.get("scheduled_at"),
        duration=activity_data.get("duration"),
        max_participants=activity_data.get("max_participants"),
        facilitators=activity_data.get("facilitators", []),
        status=activity_data.get("status", "planned"),
        created_by=current_user.id
    )
    
    db.add(new_activity)
    db.commit()
    db.refresh(new_activity)
    
    return {
        "id": new_activity.id,
        "uuid": new_activity.uuid,
        "title": new_activity.title,
        "created_at": new_activity.created_at.isoformat() if new_activity.created_at else None
    }


@router.put("/social-activities/{activity_uuid}")
async def update_social_activity(
    activity_uuid: str,
    activity_data: dict,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """
    更新活动
    """
    activity = db.query(PBLSocialActivity).filter(PBLSocialActivity.uuid == activity_uuid).first()
    
    if not activity:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="活动不存在")
    
    # 更新字段
    if "title" in activity_data:
        activity.title = activity_data["title"]
    if "description" in activity_data:
        activity.description = activity_data["description"]
    if "organizer" in activity_data:
        activity.organizer = activity_data["organizer"]
    if "partner_organization" in activity_data:
        activity.partner_organization = activity_data["partner_organization"]
    if "location" in activity_data:
        activity.location = activity_data["location"]
    if "scheduled_at" in activity_data:
        activity.scheduled_at = activity_data["scheduled_at"]
    if "duration" in activity_data:
        activity.duration = activity_data["duration"]
    if "max_participants" in activity_data:
        activity.max_participants = activity_data["max_participants"]
    if "status" in activity_data:
        activity.status = activity_data["status"]
    if "summary" in activity_data:
        activity.summary = activity_data["summary"]
    if "photos" in activity_data:
        activity.photos = activity_data["photos"]
    
    db.commit()
    db.refresh(activity)
    
    return {
        "id": activity.id,
        "uuid": activity.uuid,
        "updated_at": activity.updated_at.isoformat() if activity.updated_at else None
    }


@router.delete("/social-activities/{activity_uuid}")
async def delete_social_activity(
    activity_uuid: str,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """
    删除活动
    """
    activity = db.query(PBLSocialActivity).filter(PBLSocialActivity.uuid == activity_uuid).first()
    
    if not activity:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="活动不存在")
    
    db.delete(activity)
    db.commit()
    
    return {"message": "删除成功"}


@router.post("/social-activities/{activity_uuid}/register")
async def register_activity(
    activity_uuid: str,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """
    报名参加活动
    """
    activity = db.query(PBLSocialActivity).filter(PBLSocialActivity.uuid == activity_uuid).first()
    
    if not activity:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="活动不存在")
    
    # 检查是否已满员
    if activity.max_participants and activity.current_participants >= activity.max_participants:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="活动已满员")
    
    # 添加参与者
    participants = activity.participants or []
    if current_user.id not in participants:
        participants.append(current_user.id)
        activity.participants = participants
        activity.current_participants += 1
        db.commit()
    
    return {"message": "报名成功"}


@router.post("/social-activities/{activity_uuid}/cancel")
async def cancel_registration(
    activity_uuid: str,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """
    取消报名
    """
    activity = db.query(PBLSocialActivity).filter(PBLSocialActivity.uuid == activity_uuid).first()
    
    if not activity:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="活动不存在")
    
    # 移除参与者
    participants = activity.participants or []
    if current_user.id in participants:
        participants.remove(current_user.id)
        activity.participants = participants
        activity.current_participants -= 1
        db.commit()
    
    return {"message": "取消成功"}


@router.post("/social-activities/{activity_uuid}/feedback")
async def submit_activity_feedback(
    activity_uuid: str,
    feedback_data: dict,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """
    提交活动反馈
    """
    activity = db.query(PBLSocialActivity).filter(PBLSocialActivity.uuid == activity_uuid).first()
    
    if not activity:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="活动不存在")
    
    # 添加反馈
    feedback = activity.feedback or []
    feedback.append({
        "student_id": current_user.id,
        "student_name": current_user.name,
        "rating": feedback_data.get("rating"),
        "comment": feedback_data.get("comment"),
        "submitted_at": get_beijing_time_naive().isoformat()
    })
    activity.feedback = feedback
    db.commit()
    
    return {"message": "提交成功"}


@router.post("/social-activities/{activity_uuid}/photos")
async def upload_activity_photos(
    activity_uuid: str,
    file: UploadFile = File(...),
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """
    上传活动照片
    """
    activity = db.query(PBLSocialActivity).filter(PBLSocialActivity.uuid == activity_uuid).first()
    
    if not activity:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="活动不存在")
    
    # 创建上传目录
    upload_dir = "uploads/social-activities"
    os.makedirs(upload_dir, exist_ok=True)
    
    # 生成唯一文件名
    timestamp = get_beijing_time_naive().strftime("%Y%m%d%H%M%S")
    file_extension = os.path.splitext(file.filename)[1]
    filename = f"{activity.id}_{timestamp}{file_extension}"
    file_path = os.path.join(upload_dir, filename)
    
    # 保存文件
    with open(file_path, "wb") as buffer:
        content = await file.read()
        buffer.write(content)
    
    photo_url = f"/{file_path}"
    
    # 添加到活动照片列表
    photos = activity.photos or []
    photos.append(photo_url)
    activity.photos = photos
    db.commit()
    
    return {
        "photo_url": photo_url,
        "message": "上传成功"
    }
