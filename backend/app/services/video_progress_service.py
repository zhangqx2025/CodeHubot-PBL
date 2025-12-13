"""
视频播放进度服务
提供视频播放进度追踪、统计、查询等功能

权限说明：
- 所有用户（学生、教师、管理员）可以创建播放会话和上报进度
- 学生只能查看自己的基础统计（不包括详细播放行为数据）
- 平台管理员可以查看所有用户的详细统计和播放行为数据
- 学校管理员和教师无法查看学生的详细播放记录
"""
from sqlalchemy.orm import Session
from sqlalchemy import func, and_, or_
from typing import Optional, Dict, Any, List
from datetime import datetime
from app.utils.timezone import get_beijing_time_naive
import json
import uuid

from ..models.pbl import (
    PBLResource, 
    PBLVideoPlayProgress, 
    PBLVideoPlayEvent,
    PBLVideoWatchRecord
)


class VideoProgressService:
    """视频播放进度服务类"""
    
    @staticmethod
    def create_session(
        db: Session,
        resource_id: int,
        user_id: int,
        duration: int,
        ip_address: Optional[str] = None,
        user_agent: Optional[str] = None,
        device_type: Optional[str] = None
    ) -> PBLVideoPlayProgress:
        """
        创建新的播放会话
        
        Args:
            db: 数据库会话
            resource_id: 资源ID
            user_id: 用户ID
            duration: 视频总时长（秒）
            ip_address: IP地址
            user_agent: 用户代理
            device_type: 设备类型
            
        Returns:
            播放进度对象
        """
        session_id = str(uuid.uuid4())
        
        progress = PBLVideoPlayProgress(
            uuid=str(uuid.uuid4()),
            resource_id=resource_id,
            user_id=user_id,
            session_id=session_id,
            duration=duration,
            ip_address=ip_address,
            user_agent=user_agent,
            device_type=device_type,
            status='playing',
            last_event='play',
            last_event_time=get_beijing_time_naive(),
            watched_ranges=json.dumps([])  # 初始化为空数组
        )
        
        db.add(progress)
        db.commit()
        db.refresh(progress)
        
        # 记录播放事件
        VideoProgressService.record_event(
            db=db,
            session_id=session_id,
            resource_id=resource_id,
            user_id=user_id,
            event_type='play',
            position=0
        )
        
        return progress
    
    @staticmethod
    def update_progress(
        db: Session,
        session_id: str,
        current_position: int,
        status: str = 'playing',
        event_type: str = 'progress'
    ) -> Optional[PBLVideoPlayProgress]:
        """
        更新播放进度
        
        Args:
            db: 数据库会话
            session_id: 会话ID
            current_position: 当前播放位置（秒）
            status: 播放状态
            event_type: 事件类型
            
        Returns:
            更新后的播放进度对象
        """
        progress = db.query(PBLVideoPlayProgress).filter(
            PBLVideoPlayProgress.session_id == session_id
        ).first()
        
        if not progress:
            return None
        
        # 更新播放位置和状态
        progress.current_position = current_position
        progress.status = status
        progress.last_event = event_type
        progress.last_event_time = get_beijing_time_naive()
        
        # 计算完成率
        if progress.duration > 0:
            progress.completion_rate = round((current_position / progress.duration) * 100, 2)
            
            # 判断是否完成（观看90%以上视为完成）
            if progress.completion_rate >= 90:
                progress.is_completed = 1
        
        # 更新观看时间段
        VideoProgressService._update_watched_ranges(progress, current_position)
        
        # 计算真实观看时长
        progress.real_watch_duration = VideoProgressService._calculate_real_duration(progress)
        
        db.commit()
        db.refresh(progress)
        
        # 记录事件
        if event_type != 'progress':  # 避免记录太多progress事件
            VideoProgressService.record_event(
                db=db,
                session_id=session_id,
                resource_id=progress.resource_id,
                user_id=progress.user_id,
                event_type=event_type,
                position=current_position
            )
        
        return progress
    
    @staticmethod
    def record_seek(
        db: Session,
        session_id: str,
        from_position: int,
        to_position: int
    ) -> Optional[PBLVideoPlayProgress]:
        """
        记录拖动事件
        
        Args:
            db: 数据库会话
            session_id: 会话ID
            from_position: 拖动前的位置（秒）
            to_position: 拖动后的位置（秒）
            
        Returns:
            更新后的播放进度对象
        """
        progress = db.query(PBLVideoPlayProgress).filter(
            PBLVideoPlayProgress.session_id == session_id
        ).first()
        
        if not progress:
            return None
        
        # 更新拖动次数和位置
        progress.seek_count += 1
        progress.current_position = to_position
        progress.last_event = 'seek'
        progress.last_event_time = get_beijing_time_naive()
        
        db.commit()
        db.refresh(progress)
        
        # 记录拖动事件
        VideoProgressService.record_event(
            db=db,
            session_id=session_id,
            resource_id=progress.resource_id,
            user_id=progress.user_id,
            event_type='seek',
            position=to_position,
            event_data=json.dumps({'from': from_position, 'to': to_position})
        )
        
        return progress
    
    @staticmethod
    def record_pause(
        db: Session,
        session_id: str,
        position: int
    ) -> Optional[PBLVideoPlayProgress]:
        """
        记录暂停事件
        
        Args:
            db: 数据库会话
            session_id: 会话ID
            position: 暂停位置（秒）
            
        Returns:
            更新后的播放进度对象
        """
        progress = db.query(PBLVideoPlayProgress).filter(
            PBLVideoPlayProgress.session_id == session_id
        ).first()
        
        if not progress:
            return None
        
        progress.pause_count += 1
        progress.current_position = position
        progress.status = 'paused'
        progress.last_event = 'pause'
        progress.last_event_time = get_beijing_time_naive()
        
        db.commit()
        db.refresh(progress)
        
        # 记录暂停事件
        VideoProgressService.record_event(
            db=db,
            session_id=session_id,
            resource_id=progress.resource_id,
            user_id=progress.user_id,
            event_type='pause',
            position=position
        )
        
        return progress
    
    @staticmethod
    def record_ended(
        db: Session,
        session_id: str,
        position: int
    ) -> Optional[PBLVideoPlayProgress]:
        """
        记录播放结束事件
        
        Args:
            db: 数据库会话
            session_id: 会话ID
            position: 结束位置（秒）
            
        Returns:
            更新后的播放进度对象
        """
        progress = db.query(PBLVideoPlayProgress).filter(
            PBLVideoPlayProgress.session_id == session_id
        ).first()
        
        if not progress:
            return None
        
        progress.current_position = position
        progress.status = 'ended'
        progress.last_event = 'ended'
        progress.last_event_time = get_beijing_time_naive()
        progress.end_time = get_beijing_time_naive()
        
        # 如果播放到90%以上，标记为完成
        if progress.duration > 0:
            completion_rate = (position / progress.duration) * 100
            if completion_rate >= 90:
                progress.is_completed = 1
        
        db.commit()
        db.refresh(progress)
        
        # 记录结束事件
        VideoProgressService.record_event(
            db=db,
            session_id=session_id,
            resource_id=progress.resource_id,
            user_id=progress.user_id,
            event_type='ended',
            position=position
        )
        
        return progress
    
    @staticmethod
    def record_event(
        db: Session,
        session_id: str,
        resource_id: int,
        user_id: int,
        event_type: str,
        position: int,
        event_data: Optional[str] = None
    ) -> PBLVideoPlayEvent:
        """
        记录播放事件
        
        Args:
            db: 数据库会话
            session_id: 会话ID
            resource_id: 资源ID
            user_id: 用户ID
            event_type: 事件类型
            position: 播放位置
            event_data: 事件数据（JSON字符串）
            
        Returns:
            播放事件对象
        """
        event = PBLVideoPlayEvent(
            session_id=session_id,
            resource_id=resource_id,
            user_id=user_id,
            event_type=event_type,
            position=position,
            event_data=event_data
        )
        
        db.add(event)
        db.commit()
        db.refresh(event)
        
        return event
    
    @staticmethod
    def get_session(
        db: Session,
        session_id: str
    ) -> Optional[PBLVideoPlayProgress]:
        """
        获取播放会话
        
        Args:
            db: 数据库会话
            session_id: 会话ID
            
        Returns:
            播放进度对象
        """
        return db.query(PBLVideoPlayProgress).filter(
            PBLVideoPlayProgress.session_id == session_id
        ).first()
    
    @staticmethod
    def get_last_position(
        db: Session,
        resource_id: int,
        user_id: int
    ) -> Dict[str, Any]:
        """
        获取用户最后的观看位置（用于断点续看）
        
        Args:
            db: 数据库会话
            resource_id: 资源ID
            user_id: 用户ID
            
        Returns:
            {
                "has_progress": bool,
                "session_id": str,
                "position": int,
                "completion_rate": float,
                "last_watch_time": datetime
            }
        """
        progress = db.query(PBLVideoPlayProgress).filter(
            PBLVideoPlayProgress.resource_id == resource_id,
            PBLVideoPlayProgress.user_id == user_id
        ).order_by(PBLVideoPlayProgress.updated_at.desc()).first()
        
        if not progress:
            return {
                "has_progress": False,
                "session_id": None,
                "position": 0,
                "completion_rate": 0,
                "last_watch_time": None
            }
        
        return {
            "has_progress": True,
            "session_id": progress.session_id,
            "position": progress.current_position,
            "completion_rate": float(progress.completion_rate or 0),
            "last_watch_time": progress.updated_at
        }
    
    @staticmethod
    def get_user_watch_stats(
        db: Session,
        resource_id: int,
        user_id: int
    ) -> Dict[str, Any]:
        """
        获取用户对某个视频的观看统计
        
        Args:
            db: 数据库会话
            resource_id: 资源ID
            user_id: 用户ID
            
        Returns:
            观看统计信息
        """
        # 查询所有会话
        sessions = db.query(PBLVideoPlayProgress).filter(
            PBLVideoPlayProgress.resource_id == resource_id,
            PBLVideoPlayProgress.user_id == user_id
        ).all()
        
        if not sessions:
            return {
                "session_count": 0,
                "total_play_duration": 0,
                "total_real_watch_duration": 0,
                "avg_completion_rate": 0,
                "max_completion_rate": 0,
                "total_seek_count": 0,
                "total_pause_count": 0,
                "completed_count": 0,
                "first_watch_time": None,
                "last_watch_time": None
            }
        
        return {
            "session_count": len(sessions),
            "total_play_duration": sum(s.play_duration for s in sessions),
            "total_real_watch_duration": sum(s.real_watch_duration for s in sessions),
            "avg_completion_rate": round(sum(float(s.completion_rate or 0) for s in sessions) / len(sessions), 2),
            "max_completion_rate": max(float(s.completion_rate or 0) for s in sessions),
            "total_seek_count": sum(s.seek_count for s in sessions),
            "total_pause_count": sum(s.pause_count for s in sessions),
            "completed_count": sum(1 for s in sessions if s.is_completed == 1),
            "first_watch_time": min(s.start_time for s in sessions),
            "last_watch_time": max(s.updated_at for s in sessions)
        }
    
    @staticmethod
    def get_video_watch_stats(
        db: Session,
        resource_id: int
    ) -> Dict[str, Any]:
        """
        获取某个视频的整体观看统计（所有学生）
        
        Args:
            db: 数据库会话
            resource_id: 资源ID
            
        Returns:
            视频观看统计信息
        """
        # 查询所有会话
        sessions = db.query(PBLVideoPlayProgress).filter(
            PBLVideoPlayProgress.resource_id == resource_id
        ).all()
        
        if not sessions:
            return {
                "total_students": 0,
                "total_sessions": 0,
                "total_play_duration": 0,
                "total_real_watch_duration": 0,
                "avg_completion_rate": 0,
                "completed_count": 0,
                "avg_seek_count": 0,
                "avg_pause_count": 0
            }
        
        # 统计不同的用户数
        unique_users = set(s.user_id for s in sessions)
        
        return {
            "total_students": len(unique_users),
            "total_sessions": len(sessions),
            "total_play_duration": sum(s.play_duration for s in sessions),
            "total_real_watch_duration": sum(s.real_watch_duration for s in sessions),
            "avg_completion_rate": round(sum(float(s.completion_rate or 0) for s in sessions) / len(sessions), 2),
            "completed_count": sum(1 for s in sessions if s.is_completed == 1),
            "avg_seek_count": round(sum(s.seek_count for s in sessions) / len(sessions), 2),
            "avg_pause_count": round(sum(s.pause_count for s in sessions) / len(sessions), 2)
        }
    
    @staticmethod
    def get_students_ranking(
        db: Session,
        resource_id: int,
        limit: int = 20
    ) -> List[Dict[str, Any]]:
        """
        获取学生观看排行榜（按真实观看时长排序）
        
        Args:
            db: 数据库会话
            resource_id: 资源ID
            limit: 返回数量
            
        Returns:
            学生排行榜列表
        """
        from ..models.user import User
        
        # 查询并分组统计
        result = db.query(
            PBLVideoPlayProgress.user_id,
            func.sum(PBLVideoPlayProgress.real_watch_duration).label('total_duration'),
            func.max(PBLVideoPlayProgress.completion_rate).label('max_completion'),
            func.count(PBLVideoPlayProgress.id).label('session_count')
        ).filter(
            PBLVideoPlayProgress.resource_id == resource_id
        ).group_by(
            PBLVideoPlayProgress.user_id
        ).order_by(
            func.sum(PBLVideoPlayProgress.real_watch_duration).desc()
        ).limit(limit).all()
        
        # 获取用户信息
        ranking = []
        for idx, row in enumerate(result, 1):
            user = db.query(User).filter(User.id == row.user_id).first()
            ranking.append({
                "rank": idx,
                "user_id": row.user_id,
                "username": user.username if user else "Unknown",
                "real_name": user.real_name if user else "Unknown",
                "total_watch_duration": row.total_duration,
                "max_completion_rate": float(row.max_completion or 0),
                "session_count": row.session_count
            })
        
        return ranking
    
    @staticmethod
    def _update_watched_ranges(progress: PBLVideoPlayProgress, current_position: int):
        """
        更新已观看的时间段
        
        内部方法，用于维护 watched_ranges 字段
        """
        try:
            watched_ranges = json.loads(progress.watched_ranges or '[]')
        except:
            watched_ranges = []
        
        # 简化处理：记录当前位置附近的时间段
        # 实际应用中可以实现更复杂的时间段合并逻辑
        range_size = 10  # 每10秒记录一个时间段
        range_start = (current_position // range_size) * range_size
        range_end = range_start + range_size
        
        # 检查是否已存在该时间段
        range_exists = False
        for r in watched_ranges:
            if len(r) == 2 and r[0] <= range_start < r[1]:
                range_exists = True
                # 扩展现有时间段
                r[1] = max(r[1], range_end)
                break
        
        if not range_exists:
            watched_ranges.append([range_start, range_end])
        
        # 排序并合并重叠的时间段
        watched_ranges.sort(key=lambda x: x[0])
        merged_ranges = []
        for r in watched_ranges:
            if not merged_ranges or merged_ranges[-1][1] < r[0]:
                merged_ranges.append(r)
            else:
                merged_ranges[-1][1] = max(merged_ranges[-1][1], r[1])
        
        progress.watched_ranges = json.dumps(merged_ranges)
    
    @staticmethod
    def _calculate_real_duration(progress: PBLVideoPlayProgress) -> int:
        """
        计算真实观看时长（基于观看时间段）
        
        内部方法，根据 watched_ranges 计算不重复的观看时长
        """
        try:
            watched_ranges = json.loads(progress.watched_ranges or '[]')
        except:
            return 0
        
        # 计算所有时间段的总长度
        total_duration = 0
        for r in watched_ranges:
            if len(r) == 2:
                total_duration += (r[1] - r[0])
        
        return total_duration


# 创建全局服务实例
video_progress_service = VideoProgressService()
