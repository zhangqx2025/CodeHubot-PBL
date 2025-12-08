"""
视频播放相关接口
用于获取阿里云视频播放凭证
"""
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import Optional

from ...db.session import SessionLocal
from ...core.response import success_response, error_response
from ...core.deps import get_db, get_current_user_or_admin
from ...models.pbl import PBLResource
from ...services.aliyun_vod import aliyun_vod_service

router = APIRouter()


@router.get("/play-auth/{resource_uuid}")
def get_video_play_auth(
    resource_uuid: str,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user_or_admin)
):
    """
    获取视频播放凭证
    
    该接口用于获取阿里云视频点播(VOD)的播放凭证(PlayAuth)
    前端使用该凭证配合视频ID可以安全地播放视频
    
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
    
    try:
        # 获取播放凭证
        auth_data = aliyun_vod_service.get_video_play_auth(resource.video_id)
        
        return success_response(
            data={
                "play_auth": auth_data["play_auth"],
                "video_id": resource.video_id,
                "video_meta": auth_data["video_meta"]
            },
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
