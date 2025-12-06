from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
import os

def get_database_url() -> str:
    """
    获取数据库连接URL
    优先级：
    1. DATABASE_URL 环境变量（如果提供）
    2. 从单独的配置项构建（MYSQL_* 或 DB_*）
    3. 默认使用 SQLite（仅用于开发）
    """
    # 优先使用 DATABASE_URL
    database_url = os.getenv("DATABASE_URL")
    if database_url:
        return database_url
    
    # 从单独的配置项构建（支持 MYSQL_* 和 DB_* 两种前缀）
    db_host = os.getenv("MYSQL_HOST") or os.getenv("DB_HOST")
    db_port = os.getenv("MYSQL_PORT") or os.getenv("DB_PORT", "3306")
    db_name = os.getenv("MYSQL_DATABASE") or os.getenv("DB_NAME")
    db_user = os.getenv("MYSQL_USER") or os.getenv("DB_USER")
    db_password = os.getenv("MYSQL_PASSWORD") or os.getenv("DB_PASSWORD")
    
    # 如果所有必需的配置项都存在，构建 MySQL 连接字符串
    if all([db_host, db_name, db_user, db_password]):
        return f"mysql+pymysql://{db_user}:{db_password}@{db_host}:{db_port}/{db_name}?charset=utf8mb4"
    
    # 默认使用 SQLite（仅用于开发环境）
    return "sqlite:///./pbl.db"

SQLALCHEMY_DATABASE_URL = get_database_url()

engine = create_engine(
    SQLALCHEMY_DATABASE_URL, 
    pool_pre_ping=True,
    # connect_args only for sqlite
    connect_args={"check_same_thread": False} if "sqlite" in SQLALCHEMY_DATABASE_URL else {}
)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
