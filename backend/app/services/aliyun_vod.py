"""
阿里云视频点播(VOD)服务
用于获取视频播放凭证、上传视频等操作
"""
from typing import Optional
import logging

from aliyunsdkcore.client import AcsClient
from aliyunsdkcore.request import CommonRequest
from aliyunsdkvod.request.v20170321 import GetVideoPlayAuthRequest

from ..core.config import settings

logger = logging.getLogger(__name__)


class AliyunVODService:
    """阿里云VOD服务类"""
    
    def __init__(self):
        """初始化阿里云VOD客户端"""
        self.access_key_id = settings.aliyun_access_key_id
        self.access_key_secret = settings.aliyun_access_key_secret
        self.region_id = settings.aliyun_vod_region_id
        
        # 检查配置是否完整
        if not self.access_key_id or not self.access_key_secret:
            logger.warning("⚠️ 阿里云VOD配置未设置，视频播放功能将不可用")
            self._client = None
        else:
            # 创建AcsClient时必须指定正确的region_id
            # 阿里云SDK会根据region_id自动设置对应的endpoint
            self._client = AcsClient(
                self.access_key_id,
                self.access_key_secret,
                self.region_id
            )
            logger.info(f"✅ 阿里云VOD客户端初始化成功")
            logger.info(f"   - Region ID: {self.region_id}")
            logger.info(f"   - Endpoint: vod.{self.region_id}.aliyuncs.com")
    
    def is_configured(self) -> bool:
        """检查阿里云VOD是否已配置"""
        return self._client is not None
    
    def get_video_play_auth(self, video_id: str, auth_timeout: int = 3000) -> Optional[dict]:
        """
        获取视频播放凭证
        
        Args:
            video_id: 视频ID（阿里云VOD的VideoId）
            auth_timeout: 凭证过期时间（秒），默认3000秒（50分钟）
        
        Returns:
            包含播放凭证的字典，包含以下字段：
            - play_auth: 播放凭证
            - video_meta: 视频元信息（标题、封面等）
            
        Raises:
            Exception: 当获取凭证失败时抛出异常
        """
        if not self.is_configured():
            raise Exception("阿里云VOD未配置，无法获取播放凭证")
        
        try:
            # 创建请求
            request = GetVideoPlayAuthRequest.GetVideoPlayAuthRequest()
            request.set_accept_format('json')
            request.set_VideoId(video_id)
            request.set_AuthInfoTimeout(auth_timeout)
            
            # 发送请求（region_id已在创建AcsClient时指定）
            response = self._client.do_action_with_exception(request)
            response_data = eval(response)
            
            logger.info(f"✅ 成功获取视频播放凭证: video_id={video_id}")
            
            return {
                "play_auth": response_data.get("PlayAuth"),
                "video_meta": {
                    "video_id": response_data.get("VideoMeta", {}).get("VideoId"),
                    "title": response_data.get("VideoMeta", {}).get("Title"),
                    "cover_url": response_data.get("VideoMeta", {}).get("CoverURL"),
                    "duration": response_data.get("VideoMeta", {}).get("Duration"),
                    "status": response_data.get("VideoMeta", {}).get("Status")
                }
            }
            
        except Exception as e:
            logger.error(f"❌ 获取视频播放凭证失败: video_id={video_id}, error={str(e)}")
            raise Exception(f"获取视频播放凭证失败: {str(e)}")
    
    def get_video_info(self, video_id: str) -> Optional[dict]:
        """
        获取视频信息
        
        Args:
            video_id: 视频ID
        
        Returns:
            视频信息字典
        """
        if not self.is_configured():
            raise Exception("阿里云VOD未配置")
        
        try:
            request = CommonRequest()
            request.set_accept_format('json')
            request.set_domain('vod.{}.aliyuncs.com'.format(self.region_id))
            request.set_method('POST')
            request.set_protocol_type('https')
            request.set_version('2017-03-21')
            request.set_action_name('GetVideoInfo')
            
            request.add_query_param('VideoId', video_id)
            
            response = self._client.do_action_with_exception(request)
            response_data = eval(response)
            
            video_info = response_data.get("Video", {})
            logger.info(f"✅ 成功获取视频信息: video_id={video_id}")
            
            return {
                "video_id": video_info.get("VideoId"),
                "title": video_info.get("Title"),
                "cover_url": video_info.get("CoverURL"),
                "duration": video_info.get("Duration"),
                "status": video_info.get("Status"),
                "create_time": video_info.get("CreationTime"),
                "size": video_info.get("Size")
            }
            
        except Exception as e:
            logger.error(f"❌ 获取视频信息失败: video_id={video_id}, error={str(e)}")
            raise Exception(f"获取视频信息失败: {str(e)}")


# 创建全局单例
aliyun_vod_service = AliyunVODService()
