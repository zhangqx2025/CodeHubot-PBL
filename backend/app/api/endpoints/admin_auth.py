from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from datetime import timedelta

from ...db.session import SessionLocal
from ...core.response import success_response, error_response
from ...core.security import verify_password, get_password_hash, create_access_token, create_refresh_token, verify_token
from ...core.deps import get_db, get_current_admin
from ...core.logging_config import get_logger
from ...schemas.admin import AdminLogin, AdminCreate, AdminResponse, TokenResponse, RefreshTokenRequest, RefreshTokenResponse
from ...models.admin import Admin
from ...utils.timezone import get_beijing_time_naive

router = APIRouter()
logger = get_logger(__name__)

@router.post("/login")
def admin_login(login_data: AdminLogin, db: Session = Depends(get_db)):
    """管理员登录（必须是 role='platform_admin' 的用户）"""
    logger.info(f"收到管理员登录请求 - 用户名: {login_data.username}")
    
    # 先查找用户（不限制role）
    admin = db.query(Admin).filter(
        Admin.username == login_data.username
    ).first()
    
    # 检查用户是否存在
    if not admin:
        logger.warning(f"登录失败 - 用户不存在: {login_data.username}")
        return error_response(
            message="用户名或密码错误",
            code=401,
            status_code=status.HTTP_401_UNAUTHORIZED
        )
    
    logger.debug(f"找到用户 - ID: {admin.id}, 用户名: {admin.username}, 角色: {admin.role}, 激活状态: {admin.is_active}")
    
    # 检查用户角色是否为平台管理员
    if admin.role != 'platform_admin':
        logger.warning(f"登录失败 - 用户 {login_data.username} 不是平台管理员，当前角色: {admin.role}")
        return error_response(
            message="该用户不是平台管理员，无法登录管理后台",
            code=403,
            status_code=status.HTTP_403_FORBIDDEN
        )
    
    # 验证密码
    logger.debug(f"验证用户 {login_data.username} 的密码...")
    password_valid = verify_password(login_data.password, admin.password_hash)
    
    if not password_valid:
        logger.warning(f"登录失败 - 用户 {login_data.username} 密码错误")
        return error_response(
            message="用户名或密码错误",
            code=401,
            status_code=status.HTTP_401_UNAUTHORIZED
        )
    
    logger.debug(f"用户 {login_data.username} 密码验证通过")
    
    # 检查账户状态
    if not admin.is_active:
        logger.warning(f"登录失败 - 用户 {login_data.username} 账户已被禁用")
        return error_response(
            message="账户已被禁用",
            code=403,
            status_code=status.HTTP_403_FORBIDDEN
        )
    
    # 更新最后登录时间
    admin.last_login = get_beijing_time_naive()
    db.commit()
    logger.debug(f"已更新用户 {login_data.username} 的最后登录时间")
    
    # 创建访问令牌和刷新令牌
    access_token = create_access_token(data={"sub": str(admin.id)})
    refresh_token = create_refresh_token(data={"sub": str(admin.id)})
    
    logger.info(f"用户 {login_data.username} (ID: {admin.id}) 登录成功")
    
    # 将 Admin 模型转换为 AdminResponse schema
    admin_response = AdminResponse.model_validate(admin)
    
    return success_response(
        data={
            "access_token": access_token,
            "refresh_token": refresh_token,
            "token_type": "bearer",
            "admin": admin_response.model_dump(mode='json')
        },
        message="登录成功"
    )

@router.get("/me")
def get_current_admin_info(current_admin: Admin = Depends(get_current_admin)):
    """获取当前管理员信息"""
    logger.debug(f"获取管理员信息 - 用户名: {current_admin.username}, ID: {current_admin.id}")
    admin_response = AdminResponse.model_validate(current_admin)
    return success_response(data=admin_response.model_dump(mode='json'))

@router.post("/register")
def admin_register(admin_data: AdminCreate, db: Session = Depends(get_db), current_admin: Admin = Depends(get_current_admin)):
    """注册新平台管理员（需要现有平台管理员权限）"""
    logger.info(f"收到注册平台管理员请求 - 新用户名: {admin_data.username}, 操作者: {current_admin.username}")
    
    # 检查用户名是否已存在
    existing_user = db.query(Admin).filter(Admin.username == admin_data.username).first()
    if existing_user:
        logger.warning(f"注册失败 - 用户名已存在: {admin_data.username}")
        return error_response(
            message="用户名已存在",
            code=400,
            status_code=status.HTTP_400_BAD_REQUEST
        )
    
    # 检查邮箱是否已存在
    if admin_data.email:
        existing_email = db.query(Admin).filter(Admin.email == admin_data.email).first()
        if existing_email:
            logger.warning(f"注册失败 - 邮箱已被使用: {admin_data.email}")
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
    
    logger.info(f"平台管理员创建成功 - 新用户名: {admin_data.username}, ID: {new_admin.id}, 操作者: {current_admin.username}")
    
    # 将 Admin 模型转换为 AdminResponse schema
    admin_response = AdminResponse.model_validate(new_admin)
    return success_response(data=admin_response.model_dump(mode='json'), message="平台管理员创建成功")

@router.post("/refresh")
def refresh_access_token(request: RefreshTokenRequest, db: Session = Depends(get_db)):
    """
    使用refresh token刷新access token
    当access token过期时，客户端可以使用有效的refresh token获取新的access token和refresh token
    """
    logger.info("收到刷新令牌请求")
    
    # 验证refresh token（verify_token 现在会抛出异常）
    try:
        payload = verify_token(request.refresh_token, token_type="refresh")
    except HTTPException as e:
        # refresh token 无效或已过期
        logger.warning(f"刷新令牌验证失败: {str(e)}")
        return error_response(
            message="无效的刷新令牌或已过期",
            code=401,
            status_code=status.HTTP_401_UNAUTHORIZED
        )
    
    # 获取用户ID
    admin_id = payload.get("sub")
    if admin_id is None:
        logger.warning("刷新令牌中没有用户ID")
        return error_response(
            message="无效的刷新令牌",
            code=401,
            status_code=status.HTTP_401_UNAUTHORIZED
        )
    
    logger.debug(f"刷新令牌解析成功 - 用户ID: {admin_id}")
    
    # 验证用户是否存在且为平台管理员
    admin = db.query(Admin).filter(
        Admin.id == int(admin_id),
        Admin.role == 'platform_admin'
    ).first()
    
    if admin is None:
        logger.warning(f"刷新令牌失败 - 用户不存在或不是平台管理员: {admin_id}")
        return error_response(
            message="用户不存在或不是平台管理员",
            code=401,
            status_code=status.HTTP_401_UNAUTHORIZED
        )
    
    if not admin.is_active:
        logger.warning(f"刷新令牌失败 - 用户账户已禁用: {admin.username}")
        return error_response(
            message="账户已被禁用",
            code=403,
            status_code=status.HTTP_403_FORBIDDEN
        )
    
    # 生成新的access token和refresh token
    new_access_token = create_access_token(data={"sub": str(admin.id)})
    new_refresh_token = create_refresh_token(data={"sub": str(admin.id)})
    
    logger.info(f"令牌刷新成功 - 用户: {admin.username} (ID: {admin.id})")
    
    return success_response(
        data={
            "access_token": new_access_token,
            "refresh_token": new_refresh_token,
            "token_type": "bearer"
        },
        message="令牌刷新成功"
    )
