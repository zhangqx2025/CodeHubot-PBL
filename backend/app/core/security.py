from datetime import datetime, timedelta
from typing import Optional
from jose import JWTError, jwt
from passlib.context import CryptContext
from fastapi import HTTPException, status
import logging
from app.core.config import settings

logger = logging.getLogger(__name__)

# 密码加密上下文 - 支持bcrypt和pbkdf2_sha256算法（与CodeHubot系统保持一致）
# bcrypt 用于新密码（更安全），pbkdf2_sha256 用于兼容旧密码
pwd_context = CryptContext(
    schemes=["bcrypt", "pbkdf2_sha256"],
    deprecated="auto"
)

def verify_password(plain_password: str, hashed_password: str) -> bool:
    """验证密码
    
    Args:
        plain_password: 明文密码
        hashed_password: 哈希后的密码
        
    Returns:
        bool: 密码是否匹配
    """
    try:
        return pwd_context.verify(plain_password, hashed_password)
    except Exception as e:
        logger.error(f"密码验证失败: {e}", exc_info=True)
        return False

def get_password_hash(password: str) -> str:
    """生成密码哈希
    
    Args:
        password: 明文密码
        
    Returns:
        str: 哈希后的密码
    """
    try:
        return pwd_context.hash(password)
    except Exception as e:
        logger.error(f"密码哈希失败: {e}", exc_info=True)
        raise ValueError("密码哈希失败")

def create_access_token(data: dict, expires_delta: Optional[timedelta] = None) -> str:
    """创建访问令牌（access token）
    
    注意：如果 data 中已包含 "type" 字段，将使用该值，否则默认为 "access"
    """
    to_encode = data.copy()
    if expires_delta:
        expire = datetime.utcnow() + expires_delta
    else:
        expire = datetime.utcnow() + timedelta(minutes=settings.access_token_expire_minutes)
    
    # 如果 data 中没有 type 字段，才设置为 "access"
    if "type" not in to_encode:
        to_encode["type"] = "access"
    
    to_encode["exp"] = expire
    encoded_jwt = jwt.encode(to_encode, settings.secret_key, algorithm=settings.algorithm)
    return encoded_jwt

def create_refresh_token(data: dict, expires_delta: Optional[timedelta] = None) -> str:
    """创建刷新令牌（refresh token）
    
    Args:
        data: token中包含的数据
        expires_delta: 自定义过期时间
        
    Returns:
        str: 编码后的JWT token
    """
    to_encode = data.copy()
    if expires_delta:
        expire = datetime.utcnow() + expires_delta
    else:
        expire = datetime.utcnow() + timedelta(minutes=settings.refresh_token_expire_minutes)
    to_encode.update({
        "exp": expire,
        "type": "refresh"
    })
    encoded_jwt = jwt.encode(to_encode, settings.secret_key, algorithm=settings.algorithm)
    return encoded_jwt

def verify_token(token: str, token_type: Optional[str] = "access") -> dict:
    """验证token
    
    Args:
        token: JWT token
        token_type: token类型（access、refresh 等）。如果为 None，则不验证类型
        
    Returns:
        dict: token payload
        
    Raises:
        HTTPException: token无效或类型不匹配
    """
    try:
        payload = jwt.decode(token, settings.secret_key, algorithms=[settings.algorithm])
        
        # 如果指定了 token_type，验证类型是否匹配
        if token_type is not None:
            payload_type = payload.get("type")
            if payload_type != token_type:
                raise HTTPException(
                    status_code=status.HTTP_401_UNAUTHORIZED,
                    detail=f"无效的token类型，期望: {token_type}，实际: {payload_type}",
                    headers={"WWW-Authenticate": "Bearer"},
                )
        
        return payload
    except HTTPException:
        # 重新抛出 HTTPException（类型不匹配）
        raise
    except JWTError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="无效的认证凭据",
            headers={"WWW-Authenticate": "Bearer"},
        )
