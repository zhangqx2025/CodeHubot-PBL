from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
import os
import sys

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
        print(f"✓ 使用 DATABASE_URL 环境变量配置数据库")
        # 隐藏密码部分
        safe_url = database_url.split('@')[1] if '@' in database_url else database_url
        print(f"  数据库地址: {safe_url}")
        return database_url
    
    # 从单独的配置项构建（支持 MYSQL_* 和 DB_* 两种前缀）
    db_host = os.getenv("MYSQL_HOST") or os.getenv("DB_HOST")
    db_port = os.getenv("MYSQL_PORT") or os.getenv("DB_PORT", "3306")
    db_name = os.getenv("MYSQL_DATABASE") or os.getenv("DB_NAME")
    db_user = os.getenv("MYSQL_USER") or os.getenv("DB_USER")
    db_password = os.getenv("MYSQL_PASSWORD") or os.getenv("DB_PASSWORD")
    
    # 如果所有必需的配置项都存在，构建 MySQL 连接字符串
    if all([db_host, db_name, db_user, db_password]):
        print(f"✓ 使用 MySQL 数据库配置:")
        print(f"  主机: {db_host}:{db_port}")
        print(f"  数据库: {db_name}")
        print(f"  用户: {db_user}")
        return f"mysql+pymysql://{db_user}:{db_password}@{db_host}:{db_port}/{db_name}?charset=utf8mb4"
    
    # 默认使用 SQLite（仅用于开发环境）
    print("=" * 60)
    print("⚠️  警告: 未检测到 MySQL 数据库配置，使用 SQLite 作为后备数据库")
    print("=" * 60)
    print("请检查以下环境变量是否已正确配置:")
    print("  - DB_HOST (或 MYSQL_HOST): 数据库主机地址")
    print("  - DB_PORT (或 MYSQL_PORT): 数据库端口 (默认 3306)")
    print("  - DB_NAME (或 MYSQL_DATABASE): 数据库名称")
    print("  - DB_USER (或 MYSQL_USER): 数据库用户名")
    print("  - DB_PASSWORD (或 MYSQL_PASSWORD): 数据库密码")
    print()
    print("当前环境变量状态:")
    print(f"  DB_HOST: {'✓ 已设置' if db_host else '✗ 未设置'}")
    print(f"  DB_PORT: {db_port if db_port else '✗ 未设置'}")
    print(f"  DB_NAME: {'✓ 已设置' if db_name else '✗ 未设置'}")
    print(f"  DB_USER: {'✓ 已设置' if db_user else '✗ 未设置'}")
    print(f"  DB_PASSWORD: {'✓ 已设置' if db_password else '✗ 未设置'}")
    print()
    print("如果您希望使用 MySQL，请:")
    print("  1. 复制 env.example 为 .env: cp env.example .env")
    print("  2. 编辑 .env 文件，填写正确的数据库配置")
    print("  3. 重启应用")
    print("=" * 60)
    
    return "sqlite:///./pbl.db"

SQLALCHEMY_DATABASE_URL = get_database_url()

engine = create_engine(
    SQLALCHEMY_DATABASE_URL, 
    pool_pre_ping=True,
    # connect_args only for sqlite
    connect_args={"check_same_thread": False} if "sqlite" in SQLALCHEMY_DATABASE_URL else {}
)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
