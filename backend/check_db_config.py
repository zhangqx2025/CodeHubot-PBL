#!/usr/bin/env python3
"""
数据库配置检查工具

用于检查当前的数据库配置是否正确
"""

import os
import sys
from pathlib import Path

# 添加项目路径
sys.path.insert(0, str(Path(__file__).parent))

def check_env_file():
    """检查 .env 文件是否存在"""
    env_file = Path(__file__).parent / ".env"
    env_example = Path(__file__).parent / "env.example"
    
    print("=" * 70)
    print("数据库配置检查工具")
    print("=" * 70)
    print()
    
    if not env_file.exists():
        print("❌ 未找到 .env 文件")
        print()
        if env_example.exists():
            print("建议操作:")
            print(f"  1. 复制示例配置: cp {env_example} {env_file}")
            print(f"  2. 编辑 .env 文件，填写正确的数据库配置")
            print(f"  3. 重新运行本检查工具")
        return False
    else:
        print(f"✓ 找到 .env 文件: {env_file}")
        print()
    
    return True

def check_database_config():
    """检查数据库配置"""
    # 尝试加载 .env 文件
    env_file = Path(__file__).parent / ".env"
    if env_file.exists():
        from dotenv import load_dotenv
        load_dotenv(env_file)
        print("✓ 已加载 .env 文件")
        print()
    
    # 检查数据库相关环境变量
    print("数据库配置检查:")
    print("-" * 70)
    
    # 检查 DATABASE_URL
    database_url = os.getenv("DATABASE_URL")
    if database_url:
        print("✓ DATABASE_URL: 已配置")
        # 隐藏密码
        if '@' in database_url:
            safe_url = database_url.split('://')[0] + '://' + database_url.split('@')[1]
            print(f"  值: {safe_url}")
        return True
    else:
        print("○ DATABASE_URL: 未配置 (将使用单独的配置项)")
    
    print()
    
    # 检查单独的配置项（支持两种前缀）
    configs = {
        "主机地址": os.getenv("MYSQL_HOST") or os.getenv("DB_HOST"),
        "端口": os.getenv("MYSQL_PORT") or os.getenv("DB_PORT", "3306"),
        "数据库名": os.getenv("MYSQL_DATABASE") or os.getenv("DB_NAME"),
        "用户名": os.getenv("MYSQL_USER") or os.getenv("DB_USER"),
        "密码": os.getenv("MYSQL_PASSWORD") or os.getenv("DB_PASSWORD"),
    }
    
    all_configured = True
    for name, value in configs.items():
        if value and value != "3306":  # 3306 是默认值，不算已配置
            if name == "密码":
                print(f"  ✓ {name}: {'*' * 8}")
            else:
                print(f"  ✓ {name}: {value}")
        else:
            print(f"  ✗ {name}: 未配置")
            all_configured = False
    
    print()
    
    if all_configured:
        print("=" * 70)
        print("✓ MySQL 数据库配置完整！")
        print("=" * 70)
        
        # 测试数据库连接
        print()
        print("正在测试数据库连接...")
        try:
            from app.db.session import engine
            with engine.connect() as conn:
                result = conn.execute("SELECT 1")
                print("✓ 数据库连接成功！")
                print()
                print("当前使用的数据库:")
                print(f"  引擎: {engine.url.drivername}")
                print(f"  主机: {engine.url.host}:{engine.url.port}")
                print(f"  数据库: {engine.url.database}")
        except Exception as e:
            print(f"✗ 数据库连接失败: {str(e)}")
            print()
            print("可能的原因:")
            print("  1. MySQL 服务未启动")
            print("  2. 数据库配置信息错误（主机、端口、用户名、密码）")
            print("  3. 数据库不存在（请先创建数据库）")
            print("  4. 用户权限不足")
            print()
            return False
    else:
        print("=" * 70)
        print("❌ MySQL 数据库配置不完整")
        print("=" * 70)
        print()
        print("本系统只支持 MySQL 数据库，请在 .env 文件中配置以下环境变量:")
        print()
        print("# 数据库配置")
        print("MYSQL_HOST=localhost          # 数据库主机地址")
        print("MYSQL_PORT=3306               # 数据库端口")
        print("MYSQL_DATABASE=aiot_admin     # 数据库名称")
        print("MYSQL_USER=aiot_user          # 数据库用户名")
        print("MYSQL_PASSWORD=your_password  # 数据库密码")
        print()
        print("或者使用 DB_* 前缀的环境变量:")
        print("DB_HOST, DB_PORT, DB_NAME, DB_USER, DB_PASSWORD")
        print()
        return False
    
    return True

def main():
    """主函数"""
    try:
        if not check_env_file():
            sys.exit(1)
        
        if check_database_config():
            print()
            print("=" * 70)
            print("✓ 所有检查通过！可以正常使用 MySQL 数据库。")
            print("=" * 70)
            sys.exit(0)
        else:
            sys.exit(1)
    except ImportError as e:
        print(f"❌ 导入错误: {str(e)}")
        print()
        print("请确保已安装所有依赖:")
        print("  pip install -r requirements.txt")
        sys.exit(1)
    except Exception as e:
        print(f"❌ 检查过程中出现错误: {str(e)}")
        import traceback
        traceback.print_exc()
        sys.exit(1)

if __name__ == "__main__":
    main()
