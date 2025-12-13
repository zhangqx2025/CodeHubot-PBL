"""
PBL伦理教育API端点
"""
from typing import Optional
from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.orm import Session
import json

from app.core.deps import get_db, get_current_user
from app.models.pbl import PBLEthicsCase, PBLEthicsActivity
from app.models.admin import User

router = APIRouter()


# ==================== 伦理案例 ====================

@router.get("/ethics-cases")
async def get_ethics_cases(
    skip: int = Query(0, ge=0),
    limit: int = Query(10, ge=1, le=100),
    difficulty: Optional[str] = None,
    grade_level: Optional[str] = None,
    topic: Optional[str] = None,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """
    获取伦理案例列表
    """
    # 管理员可以查看所有案例（包括未发布的）
    query = db.query(PBLEthicsCase)
    
    if difficulty:
        query = query.filter(PBLEthicsCase.difficulty == difficulty)
    if grade_level:
        query = query.filter(PBLEthicsCase.grade_level == grade_level)
    if topic:
        # 搜索 ethics_topics JSON 字段
        query = query.filter(PBLEthicsCase.ethics_topics.contains(topic))
    
    total = query.count()
    cases = query.offset(skip).limit(limit).all()
    
    items = []
    for case in cases:
        items.append({
            "id": case.id,
            "uuid": case.uuid,
            "title": case.title,
            "description": case.description,
            "grade_level": case.grade_level,
            "ethics_topics": case.ethics_topics,
            "difficulty": case.difficulty,
            "cover_image": case.cover_image,
            "author": case.author,
            "source": case.source,
            "view_count": case.view_count,
            "like_count": case.like_count,
            "is_published": case.is_published,
            "created_at": case.created_at.isoformat() if case.created_at else None
        })
    
    return {
        "items": items,
        "total": total
    }


@router.get("/ethics-cases/{case_uuid}")
async def get_ethics_case_detail(
    case_uuid: str,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """
    获取伦理案例详情
    """
    case = db.query(PBLEthicsCase).filter(PBLEthicsCase.uuid == case_uuid).first()
    
    if not case:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="伦理案例不存在")
    
    # 增加浏览次数
    case.view_count += 1
    db.commit()
    
    return {
        "id": case.id,
        "uuid": case.uuid,
        "title": case.title,
        "description": case.description,
        "content": case.content,
        "grade_level": case.grade_level,
        "ethics_topics": case.ethics_topics,
        "difficulty": case.difficulty,
        "discussion_questions": case.discussion_questions,
        "reference_links": case.reference_links,
        "cover_image": case.cover_image,
        "author": case.author,
        "source": case.source,
        "view_count": case.view_count,
        "like_count": case.like_count,
        "created_at": case.created_at.isoformat() if case.created_at else None,
        "updated_at": case.updated_at.isoformat() if case.updated_at else None
    }


@router.post("/ethics-cases")
async def create_ethics_case(
    case_data: dict,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """
    创建伦理案例
    """
    new_case = PBLEthicsCase(
        title=case_data.get("title"),
        description=case_data.get("description"),
        content=case_data.get("content"),
        grade_level=case_data.get("grade_level"),
        ethics_topics=case_data.get("ethics_topics", []),
        difficulty=case_data.get("difficulty", "basic"),
        discussion_questions=case_data.get("discussion_questions"),
        reference_links=case_data.get("reference_links"),
        cover_image=case_data.get("cover_image"),
        author=case_data.get("author"),
        source=case_data.get("source"),
        is_published=case_data.get("is_published", True)
    )
    
    db.add(new_case)
    db.commit()
    db.refresh(new_case)
    
    return {
        "id": new_case.id,
        "uuid": new_case.uuid,
        "title": new_case.title,
        "created_at": new_case.created_at.isoformat() if new_case.created_at else None
    }


@router.put("/ethics-cases/{case_uuid}")
async def update_ethics_case(
    case_uuid: str,
    case_data: dict,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """
    更新伦理案例
    """
    case = db.query(PBLEthicsCase).filter(PBLEthicsCase.uuid == case_uuid).first()
    
    if not case:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="伦理案例不存在")
    
    # 更新字段
    if "title" in case_data:
        case.title = case_data["title"]
    if "description" in case_data:
        case.description = case_data["description"]
    if "content" in case_data:
        case.content = case_data["content"]
    if "grade_level" in case_data:
        case.grade_level = case_data["grade_level"]
    if "ethics_topics" in case_data:
        case.ethics_topics = case_data["ethics_topics"]
    if "difficulty" in case_data:
        case.difficulty = case_data["difficulty"]
    if "discussion_questions" in case_data:
        case.discussion_questions = case_data["discussion_questions"]
    if "reference_links" in case_data:
        case.reference_links = case_data["reference_links"]
    if "cover_image" in case_data:
        case.cover_image = case_data["cover_image"]
    if "author" in case_data:
        case.author = case_data["author"]
    if "source" in case_data:
        case.source = case_data["source"]
    if "is_published" in case_data:
        case.is_published = case_data["is_published"]
    
    db.commit()
    db.refresh(case)
    
    return {
        "id": case.id,
        "uuid": case.uuid,
        "title": case.title,
        "updated_at": case.updated_at.isoformat() if case.updated_at else None
    }


@router.delete("/ethics-cases/{case_uuid}")
async def delete_ethics_case(
    case_uuid: str,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """
    删除伦理案例
    """
    case = db.query(PBLEthicsCase).filter(PBLEthicsCase.uuid == case_uuid).first()
    
    if not case:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="伦理案例不存在")
    
    db.delete(case)
    db.commit()
    
    return {"message": "删除成功"}


@router.post("/ethics-cases/{case_uuid}/like")
async def like_ethics_case(
    case_uuid: str,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """
    点赞伦理案例
    """
    case = db.query(PBLEthicsCase).filter(PBLEthicsCase.uuid == case_uuid).first()
    
    if not case:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="伦理案例不存在")
    
    case.like_count += 1
    db.commit()
    
    return {"message": "点赞成功", "like_count": case.like_count}


# ==================== 伦理活动 ====================

@router.get("/ethics-activities")
async def get_ethics_activities(
    skip: int = Query(0, ge=0),
    limit: int = Query(10, ge=1, le=100),
    activity_type: Optional[str] = None,
    status: Optional[str] = None,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """
    获取伦理活动列表
    """
    query = db.query(PBLEthicsActivity)
    
    if activity_type:
        query = query.filter(PBLEthicsActivity.activity_type == activity_type)
    if status:
        query = query.filter(PBLEthicsActivity.status == status)
    
    total = query.count()
    activities = query.offset(skip).limit(limit).all()
    
    items = []
    for activity in activities:
        case = None
        if activity.case_id:
            case = db.query(PBLEthicsCase).filter(PBLEthicsCase.id == activity.case_id).first()
        
        items.append({
            "id": activity.id,
            "uuid": activity.uuid,
            "title": activity.title,
            "description": activity.description,
            "activity_type": activity.activity_type,
            "case_id": activity.case_id,
            "case_title": case.title if case else None,
            "status": activity.status,
            "scheduled_at": activity.scheduled_at.isoformat() if activity.scheduled_at else None,
            "participants": activity.participants,
            "group_id": activity.group_id,
            "facilitator_id": activity.facilitator_id,
            "created_at": activity.created_at.isoformat() if activity.created_at else None
        })
    
    return {
        "items": items,
        "total": total
    }


@router.get("/ethics-activities/{activity_uuid}")
async def get_ethics_activity_detail(
    activity_uuid: str,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """
    获取伦理活动详情
    """
    activity = db.query(PBLEthicsActivity).filter(PBLEthicsActivity.uuid == activity_uuid).first()
    
    if not activity:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="伦理活动不存在")
    
    case = None
    if activity.case_id:
        case = db.query(PBLEthicsCase).filter(PBLEthicsCase.id == activity.case_id).first()
    
    return {
        "id": activity.id,
        "uuid": activity.uuid,
        "title": activity.title,
        "description": activity.description,
        "activity_type": activity.activity_type,
        "case_id": activity.case_id,
        "case_title": case.title if case else None,
        "course_id": activity.course_id,
        "unit_id": activity.unit_id,
        "status": activity.status,
        "participants": activity.participants,
        "group_id": activity.group_id,
        "facilitator_id": activity.facilitator_id,
        "discussion_records": activity.discussion_records,
        "conclusions": activity.conclusions,
        "reflections": activity.reflections,
        "scheduled_at": activity.scheduled_at.isoformat() if activity.scheduled_at else None,
        "completed_at": activity.completed_at.isoformat() if activity.completed_at else None,
        "created_at": activity.created_at.isoformat() if activity.created_at else None,
        "updated_at": activity.updated_at.isoformat() if activity.updated_at else None
    }


@router.post("/ethics-activities")
async def create_ethics_activity(
    activity_data: dict,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """
    创建伦理活动
    """
    new_activity = PBLEthicsActivity(
        case_id=activity_data.get("case_id"),
        course_id=activity_data.get("course_id"),
        unit_id=activity_data.get("unit_id"),
        activity_type=activity_data.get("activity_type"),
        title=activity_data.get("title"),
        description=activity_data.get("description"),
        participants=activity_data.get("participants", []),
        group_id=activity_data.get("group_id"),
        facilitator_id=activity_data.get("facilitator_id", current_user.id),
        status=activity_data.get("status", "planned"),
        scheduled_at=activity_data.get("scheduled_at")
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


@router.put("/ethics-activities/{activity_uuid}")
async def update_ethics_activity(
    activity_uuid: str,
    activity_data: dict,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """
    更新伦理活动
    """
    activity = db.query(PBLEthicsActivity).filter(PBLEthicsActivity.uuid == activity_uuid).first()
    
    if not activity:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="伦理活动不存在")
    
    # 更新字段
    if "title" in activity_data:
        activity.title = activity_data["title"]
    if "description" in activity_data:
        activity.description = activity_data["description"]
    if "status" in activity_data:
        activity.status = activity_data["status"]
    if "participants" in activity_data:
        activity.participants = activity_data["participants"]
    if "discussion_records" in activity_data:
        activity.discussion_records = activity_data["discussion_records"]
    if "conclusions" in activity_data:
        activity.conclusions = activity_data["conclusions"]
    if "reflections" in activity_data:
        activity.reflections = activity_data["reflections"]
    if "scheduled_at" in activity_data:
        activity.scheduled_at = activity_data["scheduled_at"]
    if "completed_at" in activity_data:
        activity.completed_at = activity_data["completed_at"]
    
    db.commit()
    db.refresh(activity)
    
    return {
        "id": activity.id,
        "uuid": activity.uuid,
        "status": activity.status,
        "updated_at": activity.updated_at.isoformat() if activity.updated_at else None
    }


@router.delete("/ethics-activities/{activity_uuid}")
async def delete_ethics_activity(
    activity_uuid: str,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """
    删除伦理活动
    """
    activity = db.query(PBLEthicsActivity).filter(PBLEthicsActivity.uuid == activity_uuid).first()
    
    if not activity:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="伦理活动不存在")
    
    db.delete(activity)
    db.commit()
    
    return {"message": "删除成功"}


@router.post("/ethics-activities/{activity_uuid}/join")
async def join_ethics_activity(
    activity_uuid: str,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """
    参与伦理活动
    """
    activity = db.query(PBLEthicsActivity).filter(PBLEthicsActivity.uuid == activity_uuid).first()
    
    if not activity:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="伦理活动不存在")
    
    # 添加参与者
    participants = activity.participants or []
    if current_user.id not in participants:
        participants.append(current_user.id)
        activity.participants = participants
        db.commit()
    
    return {"message": "参与成功"}


@router.post("/ethics-activities/{activity_uuid}/discussion")
async def submit_discussion(
    activity_uuid: str,
    discussion_data: dict,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """
    提交讨论记录
    """
    activity = db.query(PBLEthicsActivity).filter(PBLEthicsActivity.uuid == activity_uuid).first()
    
    if not activity:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="伦理活动不存在")
    
    # 添加讨论记录
    from datetime import datetime
    discussion_records = activity.discussion_records or []
    discussion_records.append({
        "student_id": current_user.id,
        "student_name": current_user.name,
        "viewpoint": discussion_data.get("viewpoint"),
        "time": get_beijing_time_naive().isoformat()
    })
    activity.discussion_records = discussion_records
    db.commit()
    
    return {"message": "提交成功"}


@router.post("/ethics-activities/{activity_uuid}/reflection")
async def submit_reflection(
    activity_uuid: str,
    reflection_data: dict,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """
    提交反思
    """
    activity = db.query(PBLEthicsActivity).filter(PBLEthicsActivity.uuid == activity_uuid).first()
    
    if not activity:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="伦理活动不存在")
    
    # 添加反思记录
    reflections = activity.reflections or []
    reflections.append({
        "student_id": current_user.id,
        "student_name": current_user.name,
        "content": reflection_data.get("content"),
        "insights": reflection_data.get("insights", [])
    })
    activity.reflections = reflections
    db.commit()
    
    return {"message": "提交成功"}
