from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from datetime import timedelta

from ...core.response import success_response, error_response
from ...core.security import verify_password, get_password_hash, create_access_token, create_refresh_token, verify_token
from ...core.deps import get_db, get_current_user
from ...core.logging_config import get_logger
from ...schemas.user import UserLogin, UserCreate, UserResponse, TokenResponse, RefreshTokenRequest, RefreshTokenResponse, InstitutionLoginRequest
from ...models.admin import User
from ...models.school import School
from ...utils.timezone import get_beijing_time_naive

router = APIRouter()
logger = get_logger(__name__)

@router.post("/login")
def student_login(login_data: InstitutionLoginRequest, db: Session = Depends(get_db)):
    """学生用户登录 - 机构登录方式（学校代码+学号+密码）"""
    logger.info(f"收到学生登录请求 - 学校代码: {login_data.school_code}, 学号: {login_data.number}")
    
    # 1. 查找学校
    school = db.query(School).filter(
        School.school_code == login_data.school_code.upper()
    ).first()
    
    if not school:
        logger.warning(f"机构登录失败：学校不存在 - {login_data.school_code}")
        return error_response(
            message="学校不存在",
            code=404,
            status_code=status.HTTP_404_NOT_FOUND
        )
    
    if not school.is_active:
        logger.warning(f"机构登录失败：学校已禁用 - {login_data.school_code}")
        return error_response(
            message="学校已禁用",
            code=400,
            status_code=status.HTTP_400_BAD_REQUEST
        )
    
    # 2. 查找用户（通过学号，role为student）
    user = db.query(User).filter(
        User.school_id == school.id,
        User.student_number == login_data.number,
        User.role == 'student'
    ).first()
    
    if not user:
        logger.warning(f"机构登录失败：学生用户不存在 - {login_data.school_code}/{login_data.number}")
        return error_response(
            message="学号或密码错误",
            code=401,
            status_code=status.HTTP_401_UNAUTHORIZED
        )
    
    logger.debug(f"找到用户 - ID: {user.id}, 用户名: {user.username}, 角色: {user.role}, 激活状态: {user.is_active}")
    
    # 3. 验证密码
    logger.debug(f"验证用户 {login_data.number} 的密码...")
    password_valid = verify_password(login_data.password, user.password_hash)
    
    if not password_valid:
        logger.warning(f"登录失败 - 用户 {login_data.number} 密码错误")
        return error_response(
            message="学号或密码错误",
            code=401,
            status_code=status.HTTP_401_UNAUTHORIZED
        )
    
    logger.debug(f"用户 {login_data.number} 密码验证通过")
    
    # 4. 检查账户状态
    if not user.is_active:
        logger.warning(f"登录失败 - 用户 {login_data.number} 账户已被禁用")
        return error_response(
            message="账户已被禁用",
            code=403,
            status_code=status.HTTP_403_FORBIDDEN
        )
    
    # 5. 更新最后登录时间
    user.last_login = get_beijing_time_naive()
    db.commit()
    logger.debug(f"已更新用户 {login_data.number} 的最后登录时间")
    
    # 6. 创建访问令牌和刷新令牌
    access_token = create_access_token(data={"sub": str(user.id)})
    refresh_token = create_refresh_token(data={"sub": str(user.id)})
    
    logger.info(f"✅ 学生用户登录成功: {user.username} ({user.role}) - {school.school_name} (ID: {user.id})")
    
    # 将 User 模型转换为 UserResponse schema
    user_response = UserResponse.model_validate(user)
    
    return success_response(
        data={
            "access_token": access_token,
            "refresh_token": refresh_token,
            "token_type": "bearer",
            "user": user_response.model_dump(mode='json')
        },
        message="登录成功"
    )

@router.get("/me")
def get_current_user_info(current_user: User = Depends(get_current_user)):
    """获取当前用户信息"""
    logger.debug(f"获取用户信息 - 用户名: {current_user.username}, ID: {current_user.id}")
    user_response = UserResponse.model_validate(current_user)
    return success_response(data=user_response.model_dump(mode='json'))

@router.post("/register")
def student_register(user_data: UserCreate, db: Session = Depends(get_db)):
    """学生用户注册"""
    logger.info(f"收到学生注册请求 - 用户名: {user_data.username}")
    
    # 检查用户名是否已存在
    existing_user = db.query(User).filter(User.username == user_data.username).first()
    if existing_user:
        logger.warning(f"注册失败 - 用户名已存在: {user_data.username}")
        return error_response(
            message="用户名已存在",
            code=400,
            status_code=status.HTTP_400_BAD_REQUEST
        )
    
    # 检查邮箱是否已存在（如果提供）
    if user_data.email:
        existing_email = db.query(User).filter(User.email == user_data.email).first()
        if existing_email:
            logger.warning(f"注册失败 - 邮箱已被使用: {user_data.email}")
            return error_response(
                message="邮箱已被使用",
                code=400,
                status_code=status.HTTP_400_BAD_REQUEST
            )
    
    # 创建新用户
    new_user = User(
        username=user_data.username,
        email=user_data.email,
        phone=user_data.phone,
        nickname=user_data.nickname,
        name=user_data.name,
        real_name=user_data.real_name,
        gender=user_data.gender,
        password_hash=get_password_hash(user_data.password),
        role=user_data.role if user_data.role else 'student',
        school_id=user_data.school_id,
        class_id=user_data.class_id,
        group_id=user_data.group_id,
        school_name=user_data.school_name,
        student_number=user_data.student_number,
        is_active=True
    )
    
    db.add(new_user)
    db.commit()
    db.refresh(new_user)
    
    logger.info(f"学生用户创建成功 - 用户名: {user_data.username}, ID: {new_user.id}")
    
    # 将 User 模型转换为 UserResponse schema
    user_response = UserResponse.model_validate(new_user)
    return success_response(data=user_response.model_dump(mode='json'), message="注册成功")

@router.post("/refresh")
def refresh_access_token(request: RefreshTokenRequest, db: Session = Depends(get_db)):
    """
    使用refresh token刷新access token
    当access token过期时，客户端可以使用有效的refresh token获取新的access token和refresh token
    """
    logger.info("收到刷新令牌请求")
    
    # 验证refresh token
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
    user_id = payload.get("sub")
    if user_id is None:
        logger.warning("刷新令牌中没有用户ID")
        return error_response(
            message="无效的刷新令牌",
            code=401,
            status_code=status.HTTP_401_UNAUTHORIZED
        )
    
    logger.debug(f"刷新令牌解析成功 - 用户ID: {user_id}")
    
    # 验证用户是否存在
    user = db.query(User).filter(User.id == int(user_id)).first()
    
    if user is None:
        logger.warning(f"刷新令牌失败 - 用户不存在: {user_id}")
        return error_response(
            message="用户不存在",
            code=401,
            status_code=status.HTTP_401_UNAUTHORIZED
        )
    
    if not user.is_active:
        logger.warning(f"刷新令牌失败 - 用户账户已禁用: {user.username}")
        return error_response(
            message="账户已被禁用",
            code=403,
            status_code=status.HTTP_403_FORBIDDEN
        )
    
    # 生成新的access token和refresh token
    new_access_token = create_access_token(data={"sub": str(user.id)})
    new_refresh_token = create_refresh_token(data={"sub": str(user.id)})
    
    logger.info(f"令牌刷新成功 - 用户: {user.username} (ID: {user.id})")
    
    return success_response(
        data={
            "access_token": new_access_token,
            "refresh_token": new_refresh_token,
            "token_type": "bearer"
        },
        message="令牌刷新成功"
    )
