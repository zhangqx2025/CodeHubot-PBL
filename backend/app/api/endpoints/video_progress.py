"""
视频播放进度追踪API
提供视频播放进度上报、查询、统计等接口

权限控制说明：
1. 播放进度上报（所有已登录用户）：
   - POST /session/create - 创建播放会话
   - POST /progress/update - 更新播放进度
   - POST /event/seek - 记录拖动事件
   - POST /event/pause - 记录暂停事件
   - POST /event/ended - 记录播放结束事件

2. 个人统计查询（所有已登录用户）：
   - GET /last-position/{resource_uuid} - 获取最后观看位置（断点续看）
   - GET /stats/user/{resource_uuid} - 获取个人观看统计
     * 学生：只能查看自己的基础统计（观看次数、完成率等）
     * 平台管理员：可以查看任何用户的详细统计

3. 整体统计查询（仅平台管理员）：
   - GET /stats/video/{resource_uuid} - 获取视频整体观看统计
   - GET /stats/ranking/{resource_uuid} - 获取学生观看排行榜
   
4. 会话信息查询：
   - GET /session/{session_id} - 获取播放会话信息
     * 学生：只能查看自己的会话基本信息
     * 平台管理员：可以查看任何会话的详细信息

注意：学校管理员和教师无法查看学生的详细播放记录，保护学生隐私
"""
from fastapi import APIRouter, Depends, HTTPException, status, Request
from sqlalchemy.orm import Session
from typing import Optional, List
from datetime import datetime
from pydantic import BaseModel

from ...db.session import SessionLocal
from ...core.response import success_response, error_response
from ...core.deps import get_db, get_current_user_or_admin
from ...models.pbl import PBLResource
from ...services.video_progress_service import video_progress_service

router = APIRouter()


# ========== Pydantic 模型定义 ==========

class CreateSessionRequest(BaseModel):
    """创建播放会话请求"""
    resource_uuid: str
    duration: int
    device_type: Optional[str] = None


class UpdateProgressRequest(BaseModel):
    """更新播放进度请求"""
    session_id: str
    current_position: int
    status: str = 'playing'
    event_type: str = 'progress'


class SeekEventRequest(BaseModel):
    """拖动事件请求"""
    session_id: str
    from_position: int
    to_position: int


class PauseEventRequest(BaseModel):
    """暂停事件请求"""
    session_id: str
    position: int


class EndEventRequest(BaseModel):
    """播放结束事件请求"""
    session_id: str
    position: int


# ========== 播放进度上报接口 ==========

@router.post("/session/create")
def create_play_session(
    request_data: CreateSessionRequest,
    request: Request,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user_or_admin)
):
    """
    创建新的播放会话
    
    前端在开始播放视频时调用此接口创建会话
    
    Args:
        request_data: 会话创建请求
        
    Returns:
        {
            "session_id": "会话ID",
            "uuid": "记录UUID",
            "resource_id": 资源ID,
            "duration": 视频时长
        }
    """
    # 查询资源
    resource = db.query(PBLResource).filter(
        PBLResource.uuid == request_data.resource_uuid
    ).first()
    
    if not resource:
        return error_response(
            message="视频资源不存在",
            code=404,
            status_code=status.HTTP_404_NOT_FOUND
        )
    
    # 检查资源类型
    if resource.type != 'video':
        return error_response(
            message="该资源不是视频类型",
            code=400,
            status_code=status.HTTP_400_BAD_REQUEST
        )
    
    try:
        # 获取客户端信息
        client_ip = request.client.host if request.client else None
        user_agent = request.headers.get("user-agent", "")
        
        # 创建播放会话
        progress = video_progress_service.create_session(
            db=db,
            resource_id=resource.id,
            user_id=current_user.id,
            duration=request_data.duration,
            ip_address=client_ip,
            user_agent=user_agent,
            device_type=request_data.device_type
        )
        
        return success_response(
            data={
                "session_id": progress.session_id,
                "uuid": progress.uuid,
                "resource_id": progress.resource_id,
                "duration": progress.duration
            },
            message="创建播放会话成功"
        )
        
    except Exception as e:
        return error_response(
            message=f"创建播放会话失败: {str(e)}",
            code=500,
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR
        )


@router.post("/progress/update")
def update_play_progress(
    request_data: UpdateProgressRequest,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user_or_admin)
):
    """
    更新播放进度
    
    前端定期（如每10秒）调用此接口上报播放进度
    
    Args:
        request_data: 进度更新请求
        
    Returns:
        {
            "session_id": "会话ID",
            "current_position": 当前位置,
            "completion_rate": 完成率,
            "is_completed": 是否完成
        }
    """
    try:
        # 更新进度
        progress = video_progress_service.update_progress(
            db=db,
            session_id=request_data.session_id,
            current_position=request_data.current_position,
            status=request_data.status,
            event_type=request_data.event_type
        )
        
        if not progress:
            return error_response(
                message="播放会话不存在",
                code=404,
                status_code=status.HTTP_404_NOT_FOUND
            )
        
        return success_response(
            data={
                "session_id": progress.session_id,
                "current_position": progress.current_position,
                "completion_rate": float(progress.completion_rate or 0),
                "is_completed": bool(progress.is_completed)
            },
            message="更新播放进度成功"
        )
        
    except Exception as e:
        return error_response(
            message=f"更新播放进度失败: {str(e)}",
            code=500,
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR
        )


@router.post("/event/seek")
def record_seek_event(
    request_data: SeekEventRequest,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user_or_admin)
):
    """
    记录拖动事件
    
    前端在用户拖动进度条时调用此接口
    
    Args:
        request_data: 拖动事件请求
        
    Returns:
        操作结果
    """
    try:
        progress = video_progress_service.record_seek(
            db=db,
            session_id=request_data.session_id,
            from_position=request_data.from_position,
            to_position=request_data.to_position
        )
        
        if not progress:
            return error_response(
                message="播放会话不存在",
                code=404,
                status_code=status.HTTP_404_NOT_FOUND
            )
        
        return success_response(
            data={
                "session_id": progress.session_id,
                "seek_count": progress.seek_count,
                "current_position": progress.current_position
            },
            message="记录拖动事件成功"
        )
        
    except Exception as e:
        return error_response(
            message=f"记录拖动事件失败: {str(e)}",
            code=500,
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR
        )


@router.post("/event/pause")
def record_pause_event(
    request_data: PauseEventRequest,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user_or_admin)
):
    """
    记录暂停事件
    
    前端在用户暂停播放时调用此接口
    
    Args:
        request_data: 暂停事件请求
        
    Returns:
        操作结果
    """
    try:
        progress = video_progress_service.record_pause(
            db=db,
            session_id=request_data.session_id,
            position=request_data.position
        )
        
        if not progress:
            return error_response(
                message="播放会话不存在",
                code=404,
                status_code=status.HTTP_404_NOT_FOUND
            )
        
        return success_response(
            data={
                "session_id": progress.session_id,
                "pause_count": progress.pause_count,
                "status": progress.status
            },
            message="记录暂停事件成功"
        )
        
    except Exception as e:
        return error_response(
            message=f"记录暂停事件失败: {str(e)}",
            code=500,
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR
        )


@router.post("/event/ended")
def record_end_event(
    request_data: EndEventRequest,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user_or_admin)
):
    """
    记录播放结束事件
    
    前端在视频播放结束时调用此接口
    
    Args:
        request_data: 播放结束事件请求
        
    Returns:
        操作结果
    """
    try:
        progress = video_progress_service.record_ended(
            db=db,
            session_id=request_data.session_id,
            position=request_data.position
        )
        
        if not progress:
            return error_response(
                message="播放会话不存在",
                code=404,
                status_code=status.HTTP_404_NOT_FOUND
            )
        
        return success_response(
            data={
                "session_id": progress.session_id,
                "is_completed": bool(progress.is_completed),
                "completion_rate": float(progress.completion_rate or 0)
            },
            message="记录播放结束事件成功"
        )
        
    except Exception as e:
        return error_response(
            message=f"记录播放结束事件失败: {str(e)}",
            code=500,
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR
        )


# ========== 播放进度查询接口 ==========

@router.get("/last-position/{resource_uuid}")
def get_last_position(
    resource_uuid: str,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user_or_admin)
):
    """
    获取最后观看位置（用于断点续看）
    
    Args:
        resource_uuid: 资源UUID
        
    Returns:
        {
            "has_progress": bool,
            "position": int,
            "completion_rate": float,
            "last_watch_time": datetime
        }
    """
    # 查询资源
    resource = db.query(PBLResource).filter(
        PBLResource.uuid == resource_uuid
    ).first()
    
    if not resource:
        return error_response(
            message="视频资源不存在",
            code=404,
            status_code=status.HTTP_404_NOT_FOUND
        )
    
    try:
        # 获取最后观看位置
        last_position = video_progress_service.get_last_position(
            db=db,
            resource_id=resource.id,
            user_id=current_user.id
        )
        
        return success_response(
            data={
                "has_progress": last_position["has_progress"],
                "position": last_position["position"],
                "completion_rate": last_position["completion_rate"],
                "last_watch_time": last_position["last_watch_time"].isoformat() if last_position["last_watch_time"] else None
            },
            message="获取最后观看位置成功"
        )
        
    except Exception as e:
        return error_response(
            message=f"获取最后观看位置失败: {str(e)}",
            code=500,
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR
        )


@router.get("/stats/user/{resource_uuid}")
def get_user_watch_stats(
    resource_uuid: str,
    user_id: Optional[int] = None,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user_or_admin)
):
    """
    获取用户观看统计
    
    学生只能查看自己的基础统计（不包括详细播放记录）
    只有平台管理员可以查看所有人的详细统计
    
    Args:
        resource_uuid: 资源UUID
        user_id: 用户ID（可选，平台管理员可指定）
        
    Returns:
        观看统计信息
    """
    # 查询资源
    resource = db.query(PBLResource).filter(
        PBLResource.uuid == resource_uuid
    ).first()
    
    if not resource:
        return error_response(
            message="视频资源不存在",
            code=404,
            status_code=status.HTTP_404_NOT_FOUND
        )
    
    # 权限检查
    is_platform_admin = hasattr(current_user, 'role') and current_user.role == 'platform_admin'
    target_user_id = user_id
    
    # 学生和学校管理员只能查看自己的统计
    if not is_platform_admin:
        target_user_id = current_user.id
    elif not target_user_id:
        target_user_id = current_user.id
    
    try:
        # 获取观看统计
        stats = video_progress_service.get_user_watch_stats(
            db=db,
            resource_id=resource.id,
            user_id=target_user_id
        )
        
        # 如果不是平台管理员，只返回基础统计，隐藏详细信息
        if not is_platform_admin:
            # 只返回简化的统计信息
            stats = {
                "session_count": stats.get("session_count", 0),
                "max_completion_rate": stats.get("max_completion_rate", 0),
                "completed_count": stats.get("completed_count", 0),
                "first_watch_time": stats.get("first_watch_time"),
                "last_watch_time": stats.get("last_watch_time")
            }
        
        # 格式化时间
        if stats.get("first_watch_time"):
            stats["first_watch_time"] = stats["first_watch_time"].isoformat()
        if stats.get("last_watch_time"):
            stats["last_watch_time"] = stats["last_watch_time"].isoformat()
        
        return success_response(
            data=stats,
            message="获取观看统计成功"
        )
        
    except Exception as e:
        return error_response(
            message=f"获取观看统计失败: {str(e)}",
            code=500,
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR
        )


@router.get("/stats/video/{resource_uuid}")
def get_video_watch_stats(
    resource_uuid: str,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user_or_admin)
):
    """
    获取视频整体观看统计（所有学生）
    
    只有平台管理员可以查看
    
    Args:
        resource_uuid: 资源UUID
        
    Returns:
        视频观看统计信息
    """
    # 权限检查：只有平台管理员可以查看
    if not hasattr(current_user, 'role') or current_user.role != 'platform_admin':
        return error_response(
            message="无权限查看整体统计，仅平台管理员可查看",
            code=403,
            status_code=status.HTTP_403_FORBIDDEN
        )
    
    # 查询资源
    resource = db.query(PBLResource).filter(
        PBLResource.uuid == resource_uuid
    ).first()
    
    if not resource:
        return error_response(
            message="视频资源不存在",
            code=404,
            status_code=status.HTTP_404_NOT_FOUND
        )
    
    try:
        # 获取视频观看统计
        stats = video_progress_service.get_video_watch_stats(
            db=db,
            resource_id=resource.id
        )
        
        return success_response(
            data=stats,
            message="获取视频观看统计成功"
        )
        
    except Exception as e:
        return error_response(
            message=f"获取视频观看统计失败: {str(e)}",
            code=500,
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR
        )


@router.get("/stats/ranking/{resource_uuid}")
def get_students_ranking(
    resource_uuid: str,
    limit: int = 20,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user_or_admin)
):
    """
    获取学生观看排行榜（按真实观看时长排序）
    
    只有平台管理员可以查看
    
    Args:
        resource_uuid: 资源UUID
        limit: 返回数量（默认20）
        
    Returns:
        学生排行榜列表
    """
    # 权限检查：只有平台管理员可以查看
    if not hasattr(current_user, 'role') or current_user.role != 'platform_admin':
        return error_response(
            message="无权限查看排行榜，仅平台管理员可查看",
            code=403,
            status_code=status.HTTP_403_FORBIDDEN
        )
    
    # 查询资源
    resource = db.query(PBLResource).filter(
        PBLResource.uuid == resource_uuid
    ).first()
    
    if not resource:
        return error_response(
            message="视频资源不存在",
            code=404,
            status_code=status.HTTP_404_NOT_FOUND
        )
    
    try:
        # 获取排行榜
        ranking = video_progress_service.get_students_ranking(
            db=db,
            resource_id=resource.id,
            limit=limit
        )
        
        return success_response(
            data={
                "total": len(ranking),
                "ranking": ranking
            },
            message="获取学生排行榜成功"
        )
        
    except Exception as e:
        return error_response(
            message=f"获取学生排行榜失败: {str(e)}",
            code=500,
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR
        )


@router.get("/session/{session_id}")
def get_session_info(
    session_id: str,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user_or_admin)
):
    """
    获取播放会话信息
    
    学生只能查看自己的会话基本信息
    平台管理员可以查看所有会话的详细信息
    
    Args:
        session_id: 会话ID
        
    Returns:
        会话详细信息
    """
    try:
        progress = video_progress_service.get_session(
            db=db,
            session_id=session_id
        )
        
        if not progress:
            return error_response(
                message="播放会话不存在",
                code=404,
                status_code=status.HTTP_404_NOT_FOUND
            )
        
        # 权限检查
        is_platform_admin = hasattr(current_user, 'role') and current_user.role == 'platform_admin'
        
        # 非平台管理员只能查看自己的会话
        if not is_platform_admin and progress.user_id != current_user.id:
            return error_response(
                message="无权限查看其他用户的会话",
                code=403,
                status_code=status.HTTP_403_FORBIDDEN
            )
        
        # 返回数据：平台管理员看到完整信息，其他用户看到简化信息
        data = {
            "session_id": progress.session_id,
            "resource_id": progress.resource_id,
            "current_position": progress.current_position,
            "duration": progress.duration,
            "status": progress.status,
            "completion_rate": float(progress.completion_rate or 0),
            "is_completed": bool(progress.is_completed),
            "start_time": progress.start_time.isoformat() if progress.start_time else None,
            "end_time": progress.end_time.isoformat() if progress.end_time else None
        }
        
        # 只有平台管理员可以看到详细的播放行为数据
        if is_platform_admin:
            data.update({
                "user_id": progress.user_id,
                "play_duration": progress.play_duration,
                "real_watch_duration": progress.real_watch_duration,
                "seek_count": progress.seek_count,
                "pause_count": progress.pause_count,
                "last_event": progress.last_event,
                "last_event_time": progress.last_event_time.isoformat() if progress.last_event_time else None,
                "ip_address": progress.ip_address,
                "device_type": progress.device_type
            })
        
        return success_response(
            data=data,
            message="获取会话信息成功"
        )
        
    except Exception as e:
        return error_response(
            message=f"获取会话信息失败: {str(e)}",
            code=500,
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR
        )
