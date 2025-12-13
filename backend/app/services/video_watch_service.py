"""
视频观看次数管理服务
提供视频观看次数检查、记录等功能
支持个性化观看次数和有效期设置
"""
from sqlalchemy.orm import Session
from sqlalchemy import func
from typing import Optional, Dict, Any
from datetime import datetime
from app.utils.timezone import get_beijing_time_naive

from ..models.pbl import PBLResource, PBLVideoWatchRecord, PBLVideoUserPermission


class VideoWatchService:
    """视频观看服务类"""
    
    @staticmethod
    def check_watch_permission(
        db: Session,
        resource_id: int,
        user_id: int
    ) -> Dict[str, Any]:
        """
        检查用户是否有权限观看视频
        支持个性化权限配置和有效期检查
        
        优先级：个性化配置 > 全局配置
        
        Args:
            db: 数据库会话
            resource_id: 资源ID
            user_id: 用户ID
            
        Returns:
            {
                "can_watch": bool,         # 是否可以观看
                "reason": str,             # 如果不能观看，返回原因
                "watch_count": int,        # 已观看次数
                "max_views": int,          # 最大观看次数限制
                "remaining": int,          # 剩余可观看次数
                "valid_from": datetime,    # 有效开始时间
                "valid_until": datetime,   # 有效结束时间
                "has_custom_permission": bool,  # 是否有个性化配置
                "permission_reason": str   # 个性化配置的原因
            }
        """
        # 查询资源
        resource = db.query(PBLResource).filter(PBLResource.id == resource_id).first()
        if not resource:
            return {
                "can_watch": False,
                "reason": "视频资源不存在",
                "watch_count": 0,
                "max_views": None,
                "remaining": 0,
                "valid_from": None,
                "valid_until": None,
                "has_custom_permission": False,
                "permission_reason": None
            }
        
        # 检查是否是视频类型
        if resource.type != 'video':
            return {
                "can_watch": False,
                "reason": "该资源不是视频类型",
                "watch_count": 0,
                "max_views": None,
                "remaining": 0,
                "valid_from": None,
                "valid_until": None,
                "has_custom_permission": False,
                "permission_reason": None
            }
        
        # ========== 查询个性化权限配置 ==========
        user_permission = db.query(PBLVideoUserPermission).filter(
            PBLVideoUserPermission.resource_id == resource_id,
            PBLVideoUserPermission.user_id == user_id,
            PBLVideoUserPermission.is_active == 1
        ).first()
        
        # 确定生效的配置（个性化 > 全局）
        if user_permission:
            # 使用个性化配置
            effective_max_views = user_permission.max_views
            effective_valid_from = user_permission.valid_from
            effective_valid_until = user_permission.valid_until
            has_custom_permission = True
            permission_reason = user_permission.reason
        else:
            # 使用全局配置
            effective_max_views = resource.max_views
            effective_valid_from = resource.valid_from
            effective_valid_until = resource.valid_until
            has_custom_permission = False
            permission_reason = None
        
        # 查询用户已观看次数
        watch_count = VideoWatchService.get_watch_count(db, resource_id, user_id)
        
        # ========== 检查有效期 ==========
        current_time = get_beijing_time_naive()
        
        # 检查是否未到开始时间
        if effective_valid_from and current_time < effective_valid_from:
            return {
                "can_watch": False,
                "reason": f"视频将于 {effective_valid_from.strftime('%Y-%m-%d %H:%M')} 开放",
                "watch_count": watch_count,
                "max_views": effective_max_views,
                "remaining": 0,
                "valid_from": effective_valid_from,
                "valid_until": effective_valid_until,
                "has_custom_permission": has_custom_permission,
                "permission_reason": permission_reason
            }
        
        # 检查是否已过期
        if effective_valid_until and current_time > effective_valid_until:
            return {
                "can_watch": False,
                "reason": f"视频观看期限已于 {effective_valid_until.strftime('%Y-%m-%d %H:%M')} 结束",
                "watch_count": watch_count,
                "max_views": effective_max_views,
                "remaining": 0,
                "valid_from": effective_valid_from,
                "valid_until": effective_valid_until,
                "has_custom_permission": has_custom_permission,
                "permission_reason": permission_reason
            }
        
        # ========== 检查观看次数限制 ==========
        # 如果 max_views 为 NULL，表示不限制观看次数
        if effective_max_views is None:
            return {
                "can_watch": True,
                "reason": "",
                "watch_count": watch_count,
                "max_views": None,
                "remaining": -1,  # -1 表示无限制
                "valid_from": effective_valid_from,
                "valid_until": effective_valid_until,
                "has_custom_permission": has_custom_permission,
                "permission_reason": permission_reason
            }
        
        # 如果 max_views = 0，表示禁止观看
        if effective_max_views == 0:
            return {
                "can_watch": False,
                "reason": "该视频已被禁止观看",
                "watch_count": watch_count,
                "max_views": 0,
                "remaining": 0,
                "valid_from": effective_valid_from,
                "valid_until": effective_valid_until,
                "has_custom_permission": has_custom_permission,
                "permission_reason": permission_reason
            }
        
        # 检查是否超过限制
        if watch_count >= effective_max_views:
            return {
                "can_watch": False,
                "reason": f"已达到观看次数上限（{effective_max_views}次）",
                "watch_count": watch_count,
                "max_views": effective_max_views,
                "remaining": 0,
                "valid_from": effective_valid_from,
                "valid_until": effective_valid_until,
                "has_custom_permission": has_custom_permission,
                "permission_reason": permission_reason
            }
        
        # 允许观看
        return {
            "can_watch": True,
            "reason": "",
            "watch_count": watch_count,
            "max_views": effective_max_views,
            "remaining": effective_max_views - watch_count,
            "valid_from": effective_valid_from,
            "valid_until": effective_valid_until,
            "has_custom_permission": has_custom_permission,
            "permission_reason": permission_reason
        }
    
    @staticmethod
    def get_watch_count(db: Session, resource_id: int, user_id: int) -> int:
        """
        获取用户对指定视频的观看次数
        
        Args:
            db: 数据库会话
            resource_id: 资源ID
            user_id: 用户ID
            
        Returns:
            观看次数
        """
        count = db.query(func.count(PBLVideoWatchRecord.id)).filter(
            PBLVideoWatchRecord.resource_id == resource_id,
            PBLVideoWatchRecord.user_id == user_id
        ).scalar()
        
        return count or 0
    
    @staticmethod
    def record_watch(
        db: Session,
        resource_id: int,
        user_id: int,
        duration: int = 0,
        completed: bool = False,
        ip_address: Optional[str] = None,
        user_agent: Optional[str] = None
    ) -> PBLVideoWatchRecord:
        """
        记录一次视频观看行为
        
        Args:
            db: 数据库会话
            resource_id: 资源ID
            user_id: 用户ID
            duration: 观看时长（秒）
            completed: 是否观看完成
            ip_address: IP地址
            user_agent: 用户代理
            
        Returns:
            观看记录对象
        """
        watch_record = PBLVideoWatchRecord(
            resource_id=resource_id,
            user_id=user_id,
            duration=duration,
            completed=1 if completed else 0,
            ip_address=ip_address,
            user_agent=user_agent
        )
        
        db.add(watch_record)
        db.commit()
        db.refresh(watch_record)
        
        return watch_record
    
    @staticmethod
    def get_watch_history(
        db: Session,
        resource_id: Optional[int] = None,
        user_id: Optional[int] = None,
        limit: int = 100
    ) -> list:
        """
        获取观看历史记录
        
        Args:
            db: 数据库会话
            resource_id: 资源ID（可选）
            user_id: 用户ID（可选）
            limit: 返回记录数限制
            
        Returns:
            观看记录列表
        """
        query = db.query(PBLVideoWatchRecord)
        
        if resource_id:
            query = query.filter(PBLVideoWatchRecord.resource_id == resource_id)
        
        if user_id:
            query = query.filter(PBLVideoWatchRecord.user_id == user_id)
        
        query = query.order_by(PBLVideoWatchRecord.watch_time.desc()).limit(limit)
        
        return query.all()
    
    @staticmethod
    def get_watch_stats(
        db: Session,
        resource_id: int,
        user_id: int
    ) -> Dict[str, Any]:
        """
        获取用户对指定视频的观看统计信息
        
        Args:
            db: 数据库会话
            resource_id: 资源ID
            user_id: 用户ID
            
        Returns:
            {
                "watch_count": int,          # 观看次数
                "total_duration": int,       # 总观看时长（秒）
                "completed_count": int,      # 完整观看次数
                "last_watch_time": datetime, # 最后观看时间
                "first_watch_time": datetime # 首次观看时间
            }
        """
        records = db.query(PBLVideoWatchRecord).filter(
            PBLVideoWatchRecord.resource_id == resource_id,
            PBLVideoWatchRecord.user_id == user_id
        ).all()
        
        if not records:
            return {
                "watch_count": 0,
                "total_duration": 0,
                "completed_count": 0,
                "last_watch_time": None,
                "first_watch_time": None
            }
        
        watch_count = len(records)
        total_duration = sum(r.duration for r in records)
        completed_count = sum(1 for r in records if r.completed == 1)
        last_watch_time = max(r.watch_time for r in records)
        first_watch_time = min(r.watch_time for r in records)
        
        return {
            "watch_count": watch_count,
            "total_duration": total_duration,
            "completed_count": completed_count,
            "last_watch_time": last_watch_time,
            "first_watch_time": first_watch_time
        }


    @staticmethod
    def set_user_permission(
        db: Session,
        resource_id: int,
        user_id: int,
        max_views: Optional[int] = None,
        valid_from: Optional[datetime] = None,
        valid_until: Optional[datetime] = None,
        reason: Optional[str] = None,
        created_by: int = None
    ) -> PBLVideoUserPermission:
        """
        为指定学生设置视频观看权限（个性化配置）
        
        Args:
            db: 数据库会话
            resource_id: 资源ID
            user_id: 用户ID（学生）
            max_views: 最大观看次数（None表示使用全局设置）
            valid_from: 有效开始时间
            valid_until: 有效结束时间
            reason: 设置原因
            created_by: 创建者ID
            
        Returns:
            权限对象
        """
        # 查询是否已存在权限配置
        existing_permission = db.query(PBLVideoUserPermission).filter(
            PBLVideoUserPermission.resource_id == resource_id,
            PBLVideoUserPermission.user_id == user_id
        ).first()
        
        if existing_permission:
            # 更新现有配置
            existing_permission.max_views = max_views
            existing_permission.valid_from = valid_from
            existing_permission.valid_until = valid_until
            existing_permission.reason = reason
            existing_permission.is_active = 1
            db.commit()
            db.refresh(existing_permission)
            return existing_permission
        else:
            # 创建新配置
            import uuid
            permission = PBLVideoUserPermission(
                uuid=str(uuid.uuid4()),
                resource_id=resource_id,
                user_id=user_id,
                max_views=max_views,
                valid_from=valid_from,
                valid_until=valid_until,
                reason=reason,
                created_by=created_by,
                is_active=1
            )
            db.add(permission)
            db.commit()
            db.refresh(permission)
            return permission
    
    @staticmethod
    def get_user_permission(
        db: Session,
        resource_id: int,
        user_id: int
    ) -> Optional[PBLVideoUserPermission]:
        """
        获取用户的个性化权限配置
        
        Args:
            db: 数据库会话
            resource_id: 资源ID
            user_id: 用户ID
            
        Returns:
            权限对象或None
        """
        return db.query(PBLVideoUserPermission).filter(
            PBLVideoUserPermission.resource_id == resource_id,
            PBLVideoUserPermission.user_id == user_id
        ).first()
    
    @staticmethod
    def delete_user_permission(
        db: Session,
        resource_id: int,
        user_id: int
    ) -> bool:
        """
        删除用户的个性化权限配置（恢复使用全局设置）
        
        Args:
            db: 数据库会话
            resource_id: 资源ID
            user_id: 用户ID
            
        Returns:
            是否删除成功
        """
        permission = db.query(PBLVideoUserPermission).filter(
            PBLVideoUserPermission.resource_id == resource_id,
            PBLVideoUserPermission.user_id == user_id
        ).first()
        
        if permission:
            db.delete(permission)
            db.commit()
            return True
        return False
    
    @staticmethod
    def disable_user_permission(
        db: Session,
        resource_id: int,
        user_id: int
    ) -> bool:
        """
        禁用用户的个性化权限配置（不删除，只是禁用）
        
        Args:
            db: 数据库会话
            resource_id: 资源ID
            user_id: 用户ID
            
        Returns:
            是否禁用成功
        """
        permission = db.query(PBLVideoUserPermission).filter(
            PBLVideoUserPermission.resource_id == resource_id,
            PBLVideoUserPermission.user_id == user_id
        ).first()
        
        if permission:
            permission.is_active = 0
            db.commit()
            return True
        return False
    
    @staticmethod
    def batch_set_permissions(
        db: Session,
        resource_id: int,
        user_ids: list,
        max_views: Optional[int] = None,
        valid_from: Optional[datetime] = None,
        valid_until: Optional[datetime] = None,
        reason: Optional[str] = None,
        created_by: int = None
    ) -> list:
        """
        批量为多个学生设置相同的权限
        
        Args:
            db: 数据库会话
            resource_id: 资源ID
            user_ids: 用户ID列表
            max_views: 最大观看次数
            valid_from: 有效开始时间
            valid_until: 有效结束时间
            reason: 设置原因
            created_by: 创建者ID
            
        Returns:
            权限对象列表
        """
        permissions = []
        for user_id in user_ids:
            permission = VideoWatchService.set_user_permission(
                db=db,
                resource_id=resource_id,
                user_id=user_id,
                max_views=max_views,
                valid_from=valid_from,
                valid_until=valid_until,
                reason=reason,
                created_by=created_by
            )
            permissions.append(permission)
        return permissions


# 创建全局服务实例
video_watch_service = VideoWatchService()
