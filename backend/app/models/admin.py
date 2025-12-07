from sqlalchemy import Column, Integer, String, Boolean, TIMESTAMP, DateTime
from sqlalchemy.sql import func
from ..db.base_class import Base
from ..utils.timezone import get_beijing_time_naive

class Admin(Base):
    """
    管理员模型，映射到 aiot_core_users 表
    只查询 role='platform_admin' 的用户
    """
    __tablename__ = "aiot_core_users"
    
    id = Column(Integer, primary_key=True, index=True)
    username = Column(String(50), unique=True, nullable=False, index=True)
    email = Column(String(255), unique=True, nullable=True, index=True)
    password_hash = Column(String(255), nullable=False)
    name = Column(String(100), nullable=True, comment='姓名')
    real_name = Column(String(100), nullable=True, comment='真实姓名')
    nickname = Column(String(50), nullable=True, comment='用户昵称')
    phone = Column(String(20), nullable=True, comment='手机号')
    role = Column(String(50), nullable=False, default='individual', comment='用户角色')
    is_active = Column(Boolean, default=True)
    last_login = Column(DateTime, nullable=True)
    last_login_ip = Column(String(50), nullable=True)
    # 时间戳 - 使用北京时间（与 CodeHubot 保持一致）
    created_at = Column(DateTime, default=get_beijing_time_naive)
    updated_at = Column(DateTime, default=get_beijing_time_naive, onupdate=get_beijing_time_naive)
    
    def __repr__(self):
        return f"<Admin(username='{self.username}', email='{self.email}', role='{self.role}')>"
    
    @property
    def full_name(self):
        """兼容性属性：返回 name 或 real_name"""
        return self.name or self.real_name or self.nickname or self.username
    
    @property
    def is_super_admin(self):
        """兼容性属性：platform_admin 角色视为超级管理员"""
        return self.role == 'platform_admin'
