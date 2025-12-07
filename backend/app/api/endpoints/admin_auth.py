from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from datetime import timedelta

from ...db.session import SessionLocal
from ...core.response import success_response, error_response
from ...core.security import verify_password, get_password_hash, create_access_token
from ...core.deps import get_db, get_current_admin
from ...schemas.admin import AdminLogin, AdminCreate, AdminResponse, TokenResponse
from ...models.admin import Admin

router = APIRouter()

@router.post("/login")
def admin_login(login_data: AdminLogin, db: Session = Depends(get_db)):
    """管理员登录（必须是 role='platform_admin' 的用户）"""
    # 查询用户，并且必须是 platform_admin 角色
    admin = db.query(Admin).filter(
        Admin.username == login_data.username,
        Admin.role == 'platform_admin'
    ).first()
    
    if not admin or not verify_password(login_data.password, admin.password_hash):
        return error_response(
            message="用户名或密码错误，或该用户不是平台管理员",
            code=401,
            status_code=status.HTTP_401_UNAUTHORIZED
        )
    
    if not admin.is_active:
        return error_response(
            message="账户已被禁用",
            code=403,
            status_code=status.HTTP_403_FORBIDDEN
        )
    
    # 创建访问令牌
    access_token = create_access_token(data={"sub": str(admin.id)})
    
    return success_response(
        data={
            "access_token": access_token,
            "token_type": "bearer",
            "admin": admin
        },
        message="登录成功"
    )

@router.get("/me")
def get_current_admin_info(current_admin: Admin = Depends(get_current_admin)):
    """获取当前管理员信息"""
    return success_response(data=current_admin)

@router.post("/register")
def admin_register(admin_data: AdminCreate, db: Session = Depends(get_db), current_admin: Admin = Depends(get_current_admin)):
    """注册新平台管理员（需要现有平台管理员权限）"""
    # 检查用户名是否已存在
    existing_user = db.query(Admin).filter(Admin.username == admin_data.username).first()
    if existing_user:
        return error_response(
            message="用户名已存在",
            code=400,
            status_code=status.HTTP_400_BAD_REQUEST
        )
    
    # 检查邮箱是否已存在
    if admin_data.email:
        existing_email = db.query(Admin).filter(Admin.email == admin_data.email).first()
        if existing_email:
            return error_response(
                message="邮箱已被使用",
                code=400,
                status_code=status.HTTP_400_BAD_REQUEST
            )
    
    # 创建新平台管理员用户
    new_admin = Admin(
        username=admin_data.username,
        email=admin_data.email,
        password_hash=get_password_hash(admin_data.password),
        name=admin_data.full_name,  # 使用 name 字段存储全名
        role='platform_admin',  # 设置为平台管理员角色
        is_active=True
    )
    
    db.add(new_admin)
    db.commit()
    db.refresh(new_admin)
    
    return success_response(data=new_admin, message="平台管理员创建成功")
