from pydantic import BaseModel, EmailStr
from typing import Optional
from datetime import datetime

class AdminLogin(BaseModel):
    username: str
    password: str

class AdminCreate(BaseModel):
    username: str
    email: Optional[EmailStr] = None
    password: str
    full_name: Optional[str] = None
    is_super_admin: bool = False

class AdminUpdate(BaseModel):
    email: Optional[EmailStr] = None
    full_name: Optional[str] = None
    password: Optional[str] = None
    is_active: Optional[bool] = None

class AdminResponse(BaseModel):
    id: int
    username: str
    email: Optional[str]
    name: Optional[str] = None  # 姓名
    real_name: Optional[str] = None  # 真实姓名
    nickname: Optional[str] = None  # 昵称
    full_name: Optional[str] = None  # 兼容性字段，优先使用 name 或 real_name
    is_active: bool
    is_super_admin: bool = True  # platform_admin 角色视为超级管理员
    role: str = 'platform_admin'  # 角色
    created_at: datetime
    updated_at: datetime
    
    class Config:
        from_attributes = True
        # 允许访问模型属性（如 full_name 和 is_super_admin 属性）
        populate_by_name = True

class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    admin: AdminResponse
