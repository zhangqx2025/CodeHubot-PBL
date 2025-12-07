from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from datetime import timedelta

from ...db.session import SessionLocal
from ...core.response import success_response, error_response
from ...core.security import verify_password, get_password_hash, create_access_token, create_refresh_token, verify_token
from ...core.deps import get_db, get_current_admin
from ...schemas.admin import AdminLogin, AdminCreate, AdminResponse, TokenResponse, RefreshTokenRequest, RefreshTokenResponse
from ...models.admin import Admin
from ...utils.timezone import get_beijing_time_naive

router = APIRouter()

@router.post("/login")
def admin_login(login_data: AdminLogin, db: Session = Depends(get_db)):
    """管理员登录（必须是 role='platform_admin' 的用户）"""
    # 先查找用户（不限制role）
    admin = db.query(Admin).filter(
        Admin.username == login_data.username
    ).first()
    
    # 检查用户是否存在
    if not admin:
        return error_response(
            message="用户名或密码错误",
            code=401,
            status_code=status.HTTP_401_UNAUTHORIZED
        )
    
    # 检查用户角色是否为平台管理员
    if admin.role != 'platform_admin':
        return error_response(
            message="该用户不是平台管理员，无法登录管理后台",
            code=403,
            status_code=status.HTTP_403_FORBIDDEN
        )
    
    # 验证密码
    if not verify_password(login_data.password, admin.password_hash):
        return error_response(
            message="用户名或密码错误",
            code=401,
            status_code=status.HTTP_401_UNAUTHORIZED
        )
    
    # 检查账户状态
    if not admin.is_active:
        return error_response(
            message="账户已被禁用",
            code=403,
            status_code=status.HTTP_403_FORBIDDEN
        )
    
    # 更新最后登录时间
    admin.last_login = get_beijing_time_naive()
    db.commit()
    
    # 创建访问令牌和刷新令牌
    access_token = create_access_token(data={"sub": str(admin.id)})
    refresh_token = create_refresh_token(data={"sub": str(admin.id)})
    
    return success_response(
        data={
            "access_token": access_token,
            "refresh_token": refresh_token,
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

@router.post("/refresh")
def refresh_access_token(request: RefreshTokenRequest, db: Session = Depends(get_db)):
    """
    使用refresh token刷新access token
    当access token过期时，客户端可以使用有效的refresh token获取新的access token和refresh token
    """
    # 验证refresh token（verify_token 现在会抛出异常）
    try:
        payload = verify_token(request.refresh_token, token_type="refresh")
    except HTTPException as e:
        # refresh token 无效或已过期
        return error_response(
            message="无效的刷新令牌或已过期",
            code=401,
            status_code=status.HTTP_401_UNAUTHORIZED
        )
    
    # 获取用户ID
    admin_id = payload.get("sub")
    if admin_id is None:
        return error_response(
            message="无效的刷新令牌",
            code=401,
            status_code=status.HTTP_401_UNAUTHORIZED
        )
    
    # 验证用户是否存在且为平台管理员
    admin = db.query(Admin).filter(
        Admin.id == int(admin_id),
        Admin.role == 'platform_admin'
    ).first()
    
    if admin is None:
        return error_response(
            message="用户不存在或不是平台管理员",
            code=401,
            status_code=status.HTTP_401_UNAUTHORIZED
        )
    
    if not admin.is_active:
        return error_response(
            message="账户已被禁用",
            code=403,
            status_code=status.HTTP_403_FORBIDDEN
        )
    
    # 生成新的access token和refresh token
    new_access_token = create_access_token(data={"sub": str(admin.id)})
    new_refresh_token = create_refresh_token(data={"sub": str(admin.id)})
    
    return success_response(
        data={
            "access_token": new_access_token,
            "refresh_token": new_refresh_token,
            "token_type": "bearer"
        },
        message="令牌刷新成功"
    )
