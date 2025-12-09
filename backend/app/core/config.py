from pydantic_settings import BaseSettings
from pydantic import Field, AliasChoices
from typing import Optional
import logging

logger = logging.getLogger(__name__)

class Settings(BaseSettings):
    """CodeHubot-PBL 配置类"""
    
    # 数据库配置（必须配置）
    # 支持 DB_HOST 或 MYSQL_HOST 两种环境变量名
    db_host: str = Field(
        validation_alias=AliasChoices('db_host', 'mysql_host'),
        description="数据库主机地址"
    )
    db_port: int = Field(
        default=3306,
        validation_alias=AliasChoices('db_port', 'mysql_port'),
        description="数据库端口"
    )
    db_user: str = Field(
        validation_alias=AliasChoices('db_user', 'mysql_user'),
        description="数据库用户名"
    )
    db_password: str = Field(
        validation_alias=AliasChoices('db_password', 'mysql_password'),
        description="数据库密码"
    )
    db_name: str = Field(
        validation_alias=AliasChoices('db_name', 'mysql_database'),
        description="数据库名称"
    )
    
    # 数据库连接URL（自动构建，无需手动配置）
    database_url: Optional[str] = None
    
    # JWT配置（必须从环境变量读取）
    secret_key: str
    algorithm: str = "HS256"
    access_token_expire_minutes: int = Field(
        default=15,
        validation_alias="ACCESS_TOKEN_EXPIRE_MINUTES",
        description="access token有效期（分钟）"
    )
    refresh_token_expire_minutes: int = Field(
        default=45,
        validation_alias="REFRESH_TOKEN_EXPIRE_MINUTES",
        description="refresh token有效期（分钟）"
    )
    
    # 环境配置
    environment: str = "development"  # development, production, testing
    
    # 日志级别配置
    log_level: str = "INFO"  # DEBUG, INFO, WARNING, ERROR, CRITICAL
    
    # 阿里云VOD配置（可选，如果不使用阿里云视频则不需要配置）
    aliyun_access_key_id: Optional[str] = None
    aliyun_access_key_secret: Optional[str] = None
    aliyun_vod_region_id: str = Field(
        default="cn-beijing",
        validation_alias=AliasChoices('aliyun_vod_region_id', 'ALIYUN_VOD_REGION_ID'),
        description="阿里云VOD区域ID，默认北京区域"
    )
    
    class Config:
        env_file = ".env"
        case_sensitive = False
        extra = "ignore"  # 忽略额外的环境变量，避免部署时出错
    
    def model_post_init(self, __context):
        """初始化后处理"""
        # 构建数据库URL
        self.database_url = f"mysql+pymysql://{self.db_user}:{self.db_password}@{self.db_host}:{self.db_port}/{self.db_name}"
        
        # 验证安全配置
        self._validate_security_settings()
    
    def _validate_security_settings(self):
        """验证安全配置"""
        # 验证JWT密钥强度
        if len(self.secret_key) < 32:
            logger.error("SECRET_KEY必须至少32个字符！")
            raise ValueError("SECRET_KEY必须至少32个字符以确保安全性")
        
        # 生产环境必须使用强密钥
        if self.environment == "production":
            if "your-secret-key" in self.secret_key.lower() or "change" in self.secret_key.lower():
                raise ValueError("生产环境禁止使用默认密钥！")
        
        # 输出Token配置信息（用于调试）
        logger.info(f"🔑 Token有效期 - Access: {self.access_token_expire_minutes}分钟, Refresh: {self.refresh_token_expire_minutes}分钟")
        
        logger.info("✅ 安全配置验证通过")

# 创建全局settings实例
try:
    settings = Settings()
except Exception as e:
    logger.error(f"❌ 配置加载失败: {e}")
    logger.info("💡 提示：请确保 .env 文件已正确配置所有必需的环境变量")
    raise
