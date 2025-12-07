from pydantic import BaseModel, EmailStr, ConfigDict, Field
from typing import Optional
from datetime import datetime

class UserBase(BaseModel):
    """用户基础 Schema"""
    username: str
    email: Optional[EmailStr] = None
    phone: Optional[str] = None
    nickname: Optional[str] = None
    name: Optional[str] = None
    real_name: Optional[str] = None
    gender: Optional[str] = None
    role: str = "student"
    school_id: Optional[int] = None
    class_id: Optional[int] = None
    group_id: Optional[int] = None
    school_name: Optional[str] = None
    student_number: Optional[str] = None
    teacher_number: Optional[str] = None

class UserLogin(BaseModel):
    """用户登录 Schema"""
    username: str
    password: str

class InstitutionLoginRequest(BaseModel):
    """机构登录请求 Schema"""
    school_code: str = Field(..., min_length=2, max_length=50, description="学校代码")
    number: str = Field(..., min_length=1, max_length=50, description="工号或学号")
    password: str = Field(..., min_length=1, description="密码")

class UserCreate(UserBase):
    """用户创建 Schema"""
    password: str

class UserResponse(UserBase):
    """用户响应 Schema"""
    id: int
    is_active: bool
    need_change_password: bool
    last_login: Optional[datetime] = None
    created_at: datetime
    updated_at: datetime
    
    model_config = ConfigDict(from_attributes=True)

class TokenResponse(BaseModel):
    """Token响应"""
    access_token: str
    refresh_token: str
    token_type: str
    user: UserResponse

class RefreshTokenRequest(BaseModel):
    """刷新令牌请求"""
    refresh_token: str

class RefreshTokenResponse(BaseModel):
    """刷新令牌响应"""
    access_token: str
    refresh_token: str
    token_type: str
