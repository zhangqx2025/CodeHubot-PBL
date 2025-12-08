from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from sqlalchemy.orm import Session
from typing import Optional
from ..db.session import SessionLocal
from ..core.security import verify_token

# 管理员认证
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/api/v1/admin/auth/login")

# 学生用户认证
oauth2_scheme_user = OAuth2PasswordBearer(tokenUrl="/api/v1/student/auth/login")

def get_db():
    """数据库依赖"""
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

def get_current_admin(token: str = Depends(oauth2_scheme), db: Session = Depends(get_db)):
    """获取当前管理员用户（支持 platform_admin、school_admin、teacher 角色）"""
    from ..models.admin import Admin
    
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="无效的认证凭据",
        headers={"WWW-Authenticate": "Bearer"},
    )
    
    try:
        # verify_token 现在会抛出异常而不是返回 None
        payload = verify_token(token, token_type="access")
        admin_id: Optional[int] = payload.get("sub")
        if admin_id is None:
            raise credentials_exception
    except HTTPException:
        # 重新抛出 HTTPException（token 类型不匹配或已过期）
        raise
    
    # 查询用户，允许 platform_admin、school_admin、teacher 角色
    admin = db.query(Admin).filter(
        Admin.id == int(admin_id),
        Admin.role.in_(['platform_admin', 'school_admin', 'teacher'])
    ).first()
    if admin is None:
        raise credentials_exception
    
    if not admin.is_active:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="账户已被禁用"
        )
    
    return admin

def get_current_user(token: str = Depends(oauth2_scheme_user), db: Session = Depends(get_db)):
    """获取当前学生用户（所有已登录的用户）"""
    from ..models.admin import User
    
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="无效的认证凭据",
        headers={"WWW-Authenticate": "Bearer"},
    )
    
    try:
        # verify_token 现在会抛出异常而不是返回 None
        payload = verify_token(token, token_type="access")
        user_id: Optional[int] = payload.get("sub")
        if user_id is None:
            raise credentials_exception
    except HTTPException:
        # 重新抛出 HTTPException（token 类型不匹配或已过期）
        raise
    
    # 查询用户
    user = db.query(User).filter(User.id == int(user_id)).first()
    if user is None:
        raise credentials_exception
    
    if not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="账户已被禁用"
        )
    
    return user

def get_current_user_flexible(
    token: Optional[str] = Depends(oauth2_scheme_user),
    db: Session = Depends(get_db)
):
    """
    灵活的用户认证：支持学生用户和管理员用户
    优先尝试作为学生用户认证，如果失败则尝试作为管理员认证
    """
    from ..models.admin import User, Admin
    
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="无效的认证凭据",
        headers={"WWW-Authenticate": "Bearer"},
    )
    
    if not token:
        raise credentials_exception
    
    try:
        # 验证token
        payload = verify_token(token, token_type="access")
        user_id: Optional[int] = payload.get("sub")
        if user_id is None:
            raise credentials_exception
        
        # 首先尝试作为学生用户查询
        user = db.query(User).filter(User.id == int(user_id)).first()
        if user and user.is_active:
            return user
        
        # 如果不是学生用户，尝试作为管理员查询
        admin = db.query(Admin).filter(
            Admin.id == int(user_id),
            Admin.role.in_(['platform_admin', 'school_admin', 'teacher'])
        ).first()
        if admin and admin.is_active:
            # 将管理员对象转换为用户对象格式，以便兼容现有代码
            # 管理员也可以查看项目，但没有group_id限制
            return admin
        
        raise credentials_exception
        
    except HTTPException:
        raise
    except Exception as e:
        raise credentials_exception
