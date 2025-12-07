#!/usr/bin/env python3
"""
测试学生登录功能

用于验证学生登录流程是否正常工作
"""

import sys
from pathlib import Path

# 添加项目路径
sys.path.insert(0, str(Path(__file__).parent))

from app.core.security import verify_password, get_password_hash

def test_password_hash():
    """测试密码哈希是否正确"""
    password = "123456"
    
    # 生成密码哈希
    password_hash = get_password_hash(password)
    print(f"密码: {password}")
    print(f"哈希: {password_hash}")
    print()
    
    # 验证密码
    is_valid = verify_password(password, password_hash)
    print(f"密码验证: {'✓ 成功' if is_valid else '✗ 失败'}")
    print()
    
    # 测试SQL脚本中的密码哈希
    sql_hash = "$pbkdf2-sha256$29000$5dw7J.Q8x7g3RgiBsFaqtQ$DheJmsxtRJstanFt1ht8qrCIpD5YeEOKnmEZt6INPLU"
    is_valid_sql = verify_password(password, sql_hash)
    print(f"SQL脚本中的密码哈希验证: {'✓ 成功' if is_valid_sql else '✗ 失败'}")
    print()

def test_login_endpoint():
    """测试登录端点"""
    from app.db.session import SessionLocal
    from app.models.admin import User
    from app.core.security import verify_password
    
    db = SessionLocal()
    try:
        # 查找测试用户
        username = "20240001@DEMO_SCHOOL"
        user = db.query(User).filter(User.username == username).first()
        
        if not user:
            print(f"✗ 未找到测试用户: {username}")
            print()
            print("请先执行 SQL/update/01_insert_test_student.sql 创建测试用户")
            return
        
        print(f"✓ 找到测试用户: {user.username}")
        print(f"  ID: {user.id}")
        print(f"  姓名: {user.name}")
        print(f"  角色: {user.role}")
        print(f"  学号: {user.student_number}")
        print(f"  学校: {user.school_name}")
        print(f"  激活状态: {'是' if user.is_active else '否'}")
        print()
        
        # 验证密码
        password = "123456"
        is_valid = verify_password(password, user.password_hash)
        print(f"密码验证 ({password}): {'✓ 成功' if is_valid else '✗ 失败'}")
        print()
        
        if is_valid and user.is_active:
            print("=" * 70)
            print("✓ 学生登录功能测试通过！")
            print("=" * 70)
            print()
            print("登录信息:")
            print(f"  用户名: {username}")
            print(f"  密码: {password}")
            print(f"  登录URL: http://localhost:8082/login")
        else:
            print("=" * 70)
            print("✗ 学生登录功能测试失败")
            print("=" * 70)
            
    finally:
        db.close()

if __name__ == "__main__":
    print("=" * 70)
    print("学生登录功能测试")
    print("=" * 70)
    print()
    
    try:
        # 测试密码哈希
        print("1. 测试密码哈希")
        print("-" * 70)
        test_password_hash()
        
        # 测试登录端点
        print("2. 测试数据库中的用户")
        print("-" * 70)
        test_login_endpoint()
        
    except ImportError as e:
        print(f"❌ 导入错误: {str(e)}")
        print()
        print("请确保已安装所有依赖:")
        print("  pip install -r requirements.txt")
        sys.exit(1)
    except Exception as e:
        print(f"❌ 测试过程中出现错误: {str(e)}")
        import traceback
        traceback.print_exc()
        sys.exit(1)
