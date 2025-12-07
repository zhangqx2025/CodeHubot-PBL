from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from sqlalchemy.orm import Session
from typing import Optional
from ..db.session import SessionLocal
from ..core.security import verify_token

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/api/v1/admin/auth/login")

def get_db():
    """数据库依赖"""
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

def get_current_admin(token: str = Depends(oauth2_scheme), db: Session = Depends(get_db)):
    """获取当前管理员用户（必须是 role='platform_admin' 的用户）"""
    from ..models.admin import Admin
    
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="无效的认证凭据",
        headers={"WWW-Authenticate": "Bearer"},
    )
    
    payload = verify_token(token)
    if payload is None:
        raise credentials_exception
    
    admin_id: Optional[int] = payload.get("sub")
    if admin_id is None:
        raise credentials_exception
    
    # 查询用户，并且必须是 platform_admin 角色
    admin = db.query(Admin).filter(
        Admin.id == int(admin_id),
        Admin.role == 'platform_admin'
    ).first()
    if admin is None:
        raise credentials_exception
    
    if not admin.is_active:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="账户已被禁用"
        )
    
    return admin
