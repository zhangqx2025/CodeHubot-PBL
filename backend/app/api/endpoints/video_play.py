"""
视频播放相关接口
用于获取阿里云视频播放凭证
支持个性化观看次数和有效期设置
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
from ...services.aliyun_vod import aliyun_vod_service
from ...services.video_watch_service import video_watch_service

router = APIRouter()


# ========== Pydantic 模型定义 ==========
class SetUserPermissionRequest(BaseModel):
    """设置用户权限请求"""
    user_id: int
    max_views: Optional[int] = None
    valid_from: Optional[datetime] = None
    valid_until: Optional[datetime] = None
    reason: Optional[str] = None


class BatchSetPermissionsRequest(BaseModel):
    """批量设置权限请求"""
    user_ids: List[int]
    max_views: Optional[int] = None
    valid_from: Optional[datetime] = None
    valid_until: Optional[datetime] = None
    reason: Optional[str] = None


@router.get("/play-auth/{resource_uuid}")
def get_video_play_auth(
    resource_uuid: str,
    request: Request,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user_or_admin)
):
    """
    获取视频播放凭证
    
    该接口用于获取阿里云视频点播(VOD)的播放凭证(PlayAuth)
    前端使用该凭证配合视频ID可以安全地播放视频
    
    注意：该接口会检查学生的观看次数限制，如果超过限制，将拒绝提供播放凭证
    
    Args:
        resource_uuid: 资源UUID
        
    Returns:
        {
            "play_auth": "播放凭证字符串",
            "video_id": "视频ID",
            "video_meta": {
                "title": "视频标题",
                "cover_url": "封面URL",
                "duration": "时长（秒）"
            },
            "watch_info": {
                "watch_count": 已观看次数,
                "max_views": 最大观看次数限制,
                "remaining": 剩余可观看次数
            }
        }
    """
    # 检查阿里云VOD是否已配置
    if not aliyun_vod_service.is_configured():
        return error_response(
            message="阿里云VOD服务未配置，无法播放视频",
            code=503,
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE
        )
    
    # 查询资源
    resource = db.query(PBLResource).filter(PBLResource.uuid == resource_uuid).first()
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
    
    # 检查视频ID
    if not resource.video_id:
        return error_response(
            message="该视频资源未关联阿里云视频ID",
            code=400,
            status_code=status.HTTP_400_BAD_REQUEST
        )
    
    # ========== 观看次数限制检查 ==========
    # 检查用户角色，只对学生进行观看次数限制
    if hasattr(current_user, 'role') and current_user.role == 'student':
        # 检查观看权限
        permission = video_watch_service.check_watch_permission(
            db=db,
            resource_id=resource.id,
            user_id=current_user.id
        )
        
        if not permission["can_watch"]:
            return error_response(
                message=permission["reason"],
                code=403,
                status_code=status.HTTP_403_FORBIDDEN,
                data={
                    "watch_count": permission["watch_count"],
                    "max_views": permission["max_views"],
                    "remaining": permission["remaining"]
                }
            )
        
        # 记录观看行为（获取播放凭证时即记录一次观看）
        try:
            # 获取客户端IP和User-Agent
            client_ip = request.client.host if request.client else None
            user_agent = request.headers.get("user-agent", "")
            
            video_watch_service.record_watch(
                db=db,
                resource_id=resource.id,
                user_id=current_user.id,
                ip_address=client_ip,
                user_agent=user_agent
            )
        except Exception as e:
            # 记录失败不影响播放凭证获取
            print(f"记录观看行为失败: {str(e)}")
    
    # ========== 获取播放凭证 ==========
    try:
        # 获取播放凭证
        auth_data = aliyun_vod_service.get_video_play_auth(resource.video_id)
        
        # 构建返回数据
        response_data = {
            "play_auth": auth_data["play_auth"],
            "video_id": resource.video_id,
            "video_meta": auth_data["video_meta"]
        }
        
        # 如果是学生，添加观看信息
        if hasattr(current_user, 'role') and current_user.role == 'student':
            # 重新获取观看次数（因为刚刚记录了一次）
            updated_permission = video_watch_service.check_watch_permission(
                db=db,
                resource_id=resource.id,
                user_id=current_user.id
            )
            response_data["watch_info"] = {
                "watch_count": updated_permission["watch_count"],
                "max_views": updated_permission["max_views"],
                "remaining": updated_permission["remaining"]
            }
        
        return success_response(
            data=response_data,
            message="获取播放凭证成功"
        )
        
    except Exception as e:
        return error_response(
            message=f"获取播放凭证失败: {str(e)}",
            code=500,
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR
        )


@router.get("/info/{resource_uuid}")
def get_video_info(
    resource_uuid: str,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user_or_admin)
):
    """
    获取视频信息
    
    Args:
        resource_uuid: 资源UUID
        
    Returns:
        视频的详细信息
    """
    # 检查阿里云VOD是否已配置
    if not aliyun_vod_service.is_configured():
        return error_response(
            message="阿里云VOD服务未配置",
            code=503,
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE
        )
    
    # 查询资源
    resource = db.query(PBLResource).filter(PBLResource.uuid == resource_uuid).first()
    if not resource:
        return error_response(
            message="视频资源不存在",
            code=404,
            status_code=status.HTTP_404_NOT_FOUND
        )
    
    # 检查视频ID
    if not resource.video_id:
        return error_response(
            message="该视频资源未关联阿里云视频ID",
            code=400,
            status_code=status.HTTP_400_BAD_REQUEST
        )
    
    try:
        # 获取视频信息
        video_info = aliyun_vod_service.get_video_info(resource.video_id)
        
        return success_response(
            data=video_info,
            message="获取视频信息成功"
        )
        
    except Exception as e:
        return error_response(
            message=f"获取视频信息失败: {str(e)}",
            code=500,
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR
        )


@router.get("/watch-stats/{resource_uuid}")
def get_watch_stats(
    resource_uuid: str,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user_or_admin)
):
    """
    获取视频观看统计信息
    
    学生只能查看自己的观看统计，管理员可以查看所有统计
    
    Args:
        resource_uuid: 资源UUID
        
    Returns:
        {
            "watch_count": 观看次数,
            "total_duration": 总观看时长,
            "completed_count": 完整观看次数,
            "last_watch_time": 最后观看时间,
            "first_watch_time": 首次观看时间,
            "max_views": 最大观看次数限制,
            "remaining": 剩余可观看次数
        }
    """
    # 查询资源
    resource = db.query(PBLResource).filter(PBLResource.uuid == resource_uuid).first()
    if not resource:
        return error_response(
            message="视频资源不存在",
            code=404,
            status_code=status.HTTP_404_NOT_FOUND
        )
    
    try:
        # 获取观看统计
        stats = video_watch_service.get_watch_stats(
            db=db,
            resource_id=resource.id,
            user_id=current_user.id
        )
        
        # 获取观看权限信息
        permission = video_watch_service.check_watch_permission(
            db=db,
            resource_id=resource.id,
            user_id=current_user.id
        )
        
        # 合并数据
        stats.update({
            "max_views": permission["max_views"],
            "remaining": permission["remaining"],
            "can_watch": permission["can_watch"]
        })
        
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


@router.get("/watch-history/{resource_uuid}")
def get_watch_history(
    resource_uuid: str,
    limit: int = 50,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user_or_admin)
):
    """
    获取视频观看历史记录
    
    学生只能查看自己的观看历史，管理员可以查看所有历史
    
    Args:
        resource_uuid: 资源UUID
        limit: 返回记录数限制（默认50条）
        
    Returns:
        观看历史记录列表
    """
    # 查询资源
    resource = db.query(PBLResource).filter(PBLResource.uuid == resource_uuid).first()
    if not resource:
        return error_response(
            message="视频资源不存在",
            code=404,
            status_code=status.HTTP_404_NOT_FOUND
        )
    
    try:
        # 学生只能查看自己的历史
        user_id = current_user.id if hasattr(current_user, 'role') and current_user.role == 'student' else None
        
        # 获取观看历史
        history = video_watch_service.get_watch_history(
            db=db,
            resource_id=resource.id,
            user_id=user_id,
            limit=limit
        )
        
        # 转换为字典格式
        history_list = [
            {
                "id": record.id,
                "watch_time": record.watch_time.isoformat() if record.watch_time else None,
                "duration": record.duration,
                "completed": bool(record.completed),
                "ip_address": record.ip_address
            }
            for record in history
        ]
        
        return success_response(
            data={
                "total": len(history_list),
                "records": history_list
            },
            message="获取观看历史成功"
        )
        
    except Exception as e:
        return error_response(
            message=f"获取观看历史失败: {str(e)}",
            code=500,
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR
        )


# ========== 管理API：设置学生观看权限 ==========

@router.post("/permission/{resource_uuid}")
def set_user_permission(
    resource_uuid: str,
    request_data: SetUserPermissionRequest,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user_or_admin)
):
    """
    为指定学生设置视频观看权限（个性化配置）
    
    只有管理员和教师可以调用此接口
    
    Args:
        resource_uuid: 视频资源UUID
        request_data: 权限设置请求数据
        
    Request Body:
        {
            "user_id": 123,
            "max_views": 10,  // 可选，最大观看次数
            "valid_from": "2025-12-10 00:00:00",  // 可选，开始时间
            "valid_until": "2025-12-31 23:59:59",  // 可选，结束时间
            "reason": "补课学生额外观看次数"  // 可选，设置原因
        }
        
    Returns:
        设置成功的权限信息
    """
    # 检查权限：只有管理员和教师可以设置
    if not hasattr(current_user, 'role') or current_user.role not in ['platform_admin', 'school_admin', 'teacher']:
        return error_response(
            message="无权限操作",
            code=403,
            status_code=status.HTTP_403_FORBIDDEN
        )
    
    # 查询资源
    resource = db.query(PBLResource).filter(PBLResource.uuid == resource_uuid).first()
    if not resource:
        return error_response(
            message="视频资源不存在",
            code=404,
            status_code=status.HTTP_404_NOT_FOUND
        )
    
    try:
        # 设置权限
        permission = video_watch_service.set_user_permission(
            db=db,
            resource_id=resource.id,
            user_id=request_data.user_id,
            max_views=request_data.max_views,
            valid_from=request_data.valid_from,
            valid_until=request_data.valid_until,
            reason=request_data.reason,
            created_by=current_user.id
        )
        
        return success_response(
            data={
                "id": permission.id,
                "uuid": permission.uuid,
                "resource_id": permission.resource_id,
                "user_id": permission.user_id,
                "max_views": permission.max_views,
                "valid_from": permission.valid_from.isoformat() if permission.valid_from else None,
                "valid_until": permission.valid_until.isoformat() if permission.valid_until else None,
                "reason": permission.reason,
                "is_active": bool(permission.is_active),
                "created_at": permission.created_at.isoformat() if permission.created_at else None
            },
            message="设置权限成功"
        )
        
    except Exception as e:
        return error_response(
            message=f"设置权限失败: {str(e)}",
            code=500,
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR
        )


@router.post("/permission/{resource_uuid}/batch")
def batch_set_permissions(
    resource_uuid: str,
    request_data: BatchSetPermissionsRequest,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user_or_admin)
):
    """
    批量为多个学生设置相同的观看权限
    
    只有管理员和教师可以调用此接口
    
    Args:
        resource_uuid: 视频资源UUID
        request_data: 批量权限设置请求数据
        
    Request Body:
        {
            "user_ids": [123, 456, 789],
            "max_views": 5,
            "valid_from": "2025-12-10 00:00:00",
            "valid_until": "2025-12-31 23:59:59",
            "reason": "期末复习专用"
        }
        
    Returns:
        批量设置结果
    """
    # 检查权限
    if not hasattr(current_user, 'role') or current_user.role not in ['platform_admin', 'school_admin', 'teacher']:
        return error_response(
            message="无权限操作",
            code=403,
            status_code=status.HTTP_403_FORBIDDEN
        )
    
    # 查询资源
    resource = db.query(PBLResource).filter(PBLResource.uuid == resource_uuid).first()
    if not resource:
        return error_response(
            message="视频资源不存在",
            code=404,
            status_code=status.HTTP_404_NOT_FOUND
        )
    
    try:
        # 批量设置权限
        permissions = video_watch_service.batch_set_permissions(
            db=db,
            resource_id=resource.id,
            user_ids=request_data.user_ids,
            max_views=request_data.max_views,
            valid_from=request_data.valid_from,
            valid_until=request_data.valid_until,
            reason=request_data.reason,
            created_by=current_user.id
        )
        
        return success_response(
            data={
                "success_count": len(permissions),
                "total_count": len(request_data.user_ids),
                "permissions": [
                    {
                        "user_id": p.user_id,
                        "max_views": p.max_views,
                        "valid_from": p.valid_from.isoformat() if p.valid_from else None,
                        "valid_until": p.valid_until.isoformat() if p.valid_until else None
                    }
                    for p in permissions
                ]
            },
            message=f"成功为 {len(permissions)} 个学生设置权限"
        )
        
    except Exception as e:
        return error_response(
            message=f"批量设置权限失败: {str(e)}",
            code=500,
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR
        )


@router.get("/permission/{resource_uuid}/user/{user_id}")
def get_user_permission(
    resource_uuid: str,
    user_id: int,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user_or_admin)
):
    """
    查询指定学生对指定视频的个性化权限配置
    
    Args:
        resource_uuid: 视频资源UUID
        user_id: 用户ID
        
    Returns:
        权限配置信息（如果有个性化配置）
    """
    # 学生只能查看自己的权限
    if hasattr(current_user, 'role') and current_user.role == 'student':
        if current_user.id != user_id:
            return error_response(
                message="无权限查看其他学生的权限",
                code=403,
                status_code=status.HTTP_403_FORBIDDEN
            )
    
    # 查询资源
    resource = db.query(PBLResource).filter(PBLResource.uuid == resource_uuid).first()
    if not resource:
        return error_response(
            message="视频资源不存在",
            code=404,
            status_code=status.HTTP_404_NOT_FOUND
        )
    
    try:
        # 查询个性化权限
        permission = video_watch_service.get_user_permission(
            db=db,
            resource_id=resource.id,
            user_id=user_id
        )
        
        if not permission:
            return success_response(
                data={
                    "has_custom_permission": False,
                    "message": "该用户使用全局配置"
                },
                message="未找到个性化权限配置"
            )
        
        return success_response(
            data={
                "has_custom_permission": True,
                "permission": {
                    "id": permission.id,
                    "uuid": permission.uuid,
                    "max_views": permission.max_views,
                    "valid_from": permission.valid_from.isoformat() if permission.valid_from else None,
                    "valid_until": permission.valid_until.isoformat() if permission.valid_until else None,
                    "reason": permission.reason,
                    "is_active": bool(permission.is_active),
                    "created_at": permission.created_at.isoformat() if permission.created_at else None,
                    "updated_at": permission.updated_at.isoformat() if permission.updated_at else None
                }
            },
            message="查询成功"
        )
        
    except Exception as e:
        return error_response(
            message=f"查询权限失败: {str(e)}",
            code=500,
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR
        )


@router.delete("/permission/{resource_uuid}/user/{user_id}")
def delete_user_permission(
    resource_uuid: str,
    user_id: int,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user_or_admin)
):
    """
    删除指定学生的个性化权限配置（恢复使用全局设置）
    
    只有管理员和教师可以调用此接口
    
    Args:
        resource_uuid: 视频资源UUID
        user_id: 用户ID
        
    Returns:
        删除结果
    """
    # 检查权限
    if not hasattr(current_user, 'role') or current_user.role not in ['platform_admin', 'school_admin', 'teacher']:
        return error_response(
            message="无权限操作",
            code=403,
            status_code=status.HTTP_403_FORBIDDEN
        )
    
    # 查询资源
    resource = db.query(PBLResource).filter(PBLResource.uuid == resource_uuid).first()
    if not resource:
        return error_response(
            message="视频资源不存在",
            code=404,
            status_code=status.HTTP_404_NOT_FOUND
        )
    
    try:
        # 删除权限
        success = video_watch_service.delete_user_permission(
            db=db,
            resource_id=resource.id,
            user_id=user_id
        )
        
        if success:
            return success_response(
                message="删除权限成功，该用户将使用全局配置"
            )
        else:
            return error_response(
                message="未找到该用户的个性化权限配置",
                code=404,
                status_code=status.HTTP_404_NOT_FOUND
            )
        
    except Exception as e:
        return error_response(
            message=f"删除权限失败: {str(e)}",
            code=500,
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR
        )
