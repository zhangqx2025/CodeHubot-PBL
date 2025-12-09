from fastapi import APIRouter, Depends, HTTPException, status, UploadFile, File
from sqlalchemy.orm import Session
from typing import List, Optional
import csv
import io
from datetime import datetime

from ...db.session import SessionLocal
from ...core.response import success_response, error_response
from ...core.deps import get_db, get_current_admin
from ...core.security import get_password_hash
from ...models.admin import Admin, User
from ...models.school import School
from ...schemas.user import UserCreate, UserResponse, UserUpdate
from ...core.logging_config import get_logger

router = APIRouter()
logger = get_logger(__name__)

@router.get("/list")
def get_users(
    role: Optional[str] = None,
    school_id: Optional[int] = None,
    skip: int = 0,
    limit: int = 100,
    db: Session = Depends(get_db),
    current_admin: Admin = Depends(get_current_admin)
):
    """获取用户列表（仅显示PBL相关角色用户）"""
    query = db.query(User)
    
    # 只显示 PBL 管理后台相关的角色：school_admin, teacher, student
    # 排除个人用户(individual)和其他角色
    pbl_roles = ['school_admin', 'teacher', 'student']
    query = query.filter(User.role.in_(pbl_roles))
    
    # 权限控制：非平台管理员只能查看本校用户
    if current_admin.role != 'platform_admin':
        query = query.filter(User.school_id == current_admin.school_id)
    elif school_id:
        query = query.filter(User.school_id == school_id)
    
    # 按角色筛选
    if role:
        query = query.filter(User.role == role)
    
    # 排除软删除的用户
    query = query.filter(User.deleted_at == None)
    
    total = query.count()
    users = query.offset(skip).limit(limit).all()
    
    result = []
    for user in users:
        user_response = UserResponse.model_validate(user)
        result.append(user_response.model_dump(mode='json'))
    
    return success_response(data={
        'total': total,
        'items': result
    })

@router.get("/{user_id}")
def get_user(
    user_id: int,
    db: Session = Depends(get_db),
    current_admin: Admin = Depends(get_current_admin)
):
    """获取用户详情（仅限PBL相关角色）"""
    user = db.query(User).filter(User.id == user_id).first()
    
    if not user:
        return error_response(
            message="用户不存在",
            code=404,
            status_code=status.HTTP_404_NOT_FOUND
        )
    
    # 只允许查看 PBL 相关角色的用户
    pbl_roles = ['school_admin', 'teacher', 'student']
    if user.role not in pbl_roles:
        return error_response(
            message="该用户不在管理范围内",
            code=403,
            status_code=status.HTTP_403_FORBIDDEN
        )
    
    # 权限控制：非平台管理员只能查看本校用户
    if current_admin.role != 'platform_admin':
        if user.school_id != current_admin.school_id:
            return error_response(
                message="无权限查看该用户",
                code=403,
                status_code=status.HTTP_403_FORBIDDEN
            )
    
    user_response = UserResponse.model_validate(user)
    return success_response(data=user_response.model_dump(mode='json'))

@router.post("")
def create_user(
    user_data: UserCreate,
    db: Session = Depends(get_db),
    current_admin: Admin = Depends(get_current_admin)
):
    """创建用户（仅限PBL相关角色）"""
    # 只允许创建 PBL 相关角色的用户
    pbl_roles = ['school_admin', 'teacher', 'student']
    if user_data.role not in pbl_roles:
        return error_response(
            message="只能创建学校管理员、教师或学生账号",
            code=403,
            status_code=status.HTTP_403_FORBIDDEN
        )
    
    # 权限检查
    if user_data.role == 'school_admin' and current_admin.role != 'platform_admin':
        return error_response(
            message="只有平台管理员可以创建学校管理员账号",
            code=403,
            status_code=status.HTTP_403_FORBIDDEN
        )
    
    if user_data.role == 'teacher':
        if current_admin.role not in ['platform_admin', 'school_admin']:
            return error_response(
                message="只有平台管理员和学校管理员可以创建教师账号",
                code=403,
                status_code=status.HTTP_403_FORBIDDEN
            )
        # 学校管理员只能创建本校教师
        if current_admin.role == 'school_admin' and user_data.school_id != current_admin.school_id:
            return error_response(
                message="只能创建本校教师账号",
                code=403,
                status_code=status.HTTP_403_FORBIDDEN
            )
    
    # 检查用户名是否已存在
    existing_user = db.query(User).filter(User.username == user_data.username).first()
    if existing_user:
        return error_response(
            message="用户名已存在",
            code=400,
            status_code=status.HTTP_400_BAD_REQUEST
        )
    
    # 检查邮箱是否已存在
    if user_data.email:
        existing_email = db.query(User).filter(User.email == user_data.email).first()
        if existing_email:
            return error_response(
                message="邮箱已被使用",
                code=400,
                status_code=status.HTTP_400_BAD_REQUEST
            )
    
    # 创建新用户
    new_user = User(
        username=user_data.username,
        email=user_data.email,
        password_hash=get_password_hash(user_data.password),
        name=user_data.name,
        real_name=user_data.real_name,
        nickname=user_data.nickname,
        phone=user_data.phone,
        role=user_data.role or 'student',
        school_id=user_data.school_id,
        class_id=user_data.class_id,
        group_id=user_data.group_id,
        school_name=user_data.school_name,
        teacher_number=user_data.teacher_number,
        student_number=user_data.student_number,
        subject=user_data.subject,
        gender=user_data.gender,
        is_active=True
    )
    
    db.add(new_user)
    db.commit()
    db.refresh(new_user)
    
    logger.info(f"创建用户成功 - 用户名: {user_data.username}, ID: {new_user.id}, 操作者: {current_admin.username}")
    
    user_response = UserResponse.model_validate(new_user)
    return success_response(data=user_response.model_dump(mode='json'), message="用户创建成功")

@router.put("/{user_id}")
def update_user(
    user_id: int,
    user_data: UserUpdate,
    db: Session = Depends(get_db),
    current_admin: Admin = Depends(get_current_admin)
):
    """更新用户信息（仅限PBL相关角色）"""
    user = db.query(User).filter(User.id == user_id).first()
    
    if not user:
        return error_response(
            message="用户不存在",
            code=404,
            status_code=status.HTTP_404_NOT_FOUND
        )
    
    # 只允许管理 PBL 相关角色的用户
    pbl_roles = ['school_admin', 'teacher', 'student']
    if user.role not in pbl_roles:
        return error_response(
            message="该用户不在管理范围内",
            code=403,
            status_code=status.HTTP_403_FORBIDDEN
        )
    
    # 权限控制：非平台管理员只能管理本校用户
    if current_admin.role != 'platform_admin':
        if user.school_id != current_admin.school_id:
            return error_response(
                message="无权限编辑该用户",
                code=403,
                status_code=status.HTTP_403_FORBIDDEN
            )
    
    # 更新字段
    update_data = user_data.dict(exclude_unset=True)
    for field, value in update_data.items():
        if field == 'password' and value:
            setattr(user, 'password_hash', get_password_hash(value))
        else:
            setattr(user, field, value)
    
    db.commit()
    db.refresh(user)
    
    logger.info(f"更新用户成功 - 用户名: {user.username}, ID: {user.id}, 操作者: {current_admin.username}")
    
    user_response = UserResponse.model_validate(user)
    return success_response(data=user_response.model_dump(mode='json'), message="用户信息更新成功")

@router.delete("/{user_id}")
def delete_user(
    user_id: int,
    db: Session = Depends(get_db),
    current_admin: Admin = Depends(get_current_admin)
):
    """删除用户（软删除，仅限PBL相关角色）"""
    user = db.query(User).filter(User.id == user_id).first()
    
    if not user:
        return error_response(
            message="用户不存在",
            code=404,
            status_code=status.HTTP_404_NOT_FOUND
        )
    
    # 只允许删除 PBL 相关角色的用户
    pbl_roles = ['school_admin', 'teacher', 'student']
    if user.role not in pbl_roles:
        return error_response(
            message="该用户不在管理范围内",
            code=403,
            status_code=status.HTTP_403_FORBIDDEN
        )
    
    # 权限控制
    if current_admin.role != 'platform_admin':
        if user.school_id != current_admin.school_id:
            return error_response(
                message="无权限删除该用户",
                code=403,
                status_code=status.HTTP_403_FORBIDDEN
            )
    
    # 不能删除自己
    if user.id == current_admin.id:
        return error_response(
            message="不能删除自己的账号",
            code=400,
            status_code=status.HTTP_400_BAD_REQUEST
        )
    
    # 软删除
    user.deleted_at = datetime.now()
    user.is_active = False
    db.commit()
    
    logger.info(f"删除用户成功 - 用户名: {user.username}, ID: {user.id}, 操作者: {current_admin.username}")
    
    return success_response(message="用户删除成功")

@router.patch("/{user_id}/toggle-active")
def toggle_user_active(
    user_id: int,
    db: Session = Depends(get_db),
    current_admin: Admin = Depends(get_current_admin)
):
    """启用/禁用用户（仅限PBL相关角色）"""
    user = db.query(User).filter(User.id == user_id).first()
    
    if not user:
        return error_response(
            message="用户不存在",
            code=404,
            status_code=status.HTTP_404_NOT_FOUND
        )
    
    # 只允许操作 PBL 相关角色的用户
    pbl_roles = ['school_admin', 'teacher', 'student']
    if user.role not in pbl_roles:
        return error_response(
            message="该用户不在管理范围内",
            code=403,
            status_code=status.HTTP_403_FORBIDDEN
        )
    
    # 权限控制
    if current_admin.role not in ['platform_admin', 'school_admin']:
        return error_response(
            message="无权限操作",
            code=403,
            status_code=status.HTTP_403_FORBIDDEN
        )
    
    if current_admin.role == 'school_admin' and user.school_id != current_admin.school_id:
        return error_response(
            message="无权限操作该用户",
            code=403,
            status_code=status.HTTP_403_FORBIDDEN
        )
    
    # 切换状态
    user.is_active = not user.is_active
    db.commit()
    
    status_text = "启用" if user.is_active else "禁用"
    logger.info(f"{status_text}用户 - 用户名: {user.username}, ID: {user.id}, 操作者: {current_admin.username}")
    
    return success_response(
        data={'is_active': user.is_active},
        message=f"用户已{status_text}"
    )

@router.post("/{user_id}/reset-password")
def reset_user_password(
    user_id: int,
    new_password: str,
    db: Session = Depends(get_db),
    current_admin: Admin = Depends(get_current_admin)
):
    """重置用户密码（仅限PBL相关角色）"""
    user = db.query(User).filter(User.id == user_id).first()
    
    if not user:
        return error_response(
            message="用户不存在",
            code=404,
            status_code=status.HTTP_404_NOT_FOUND
        )
    
    # 只允许重置 PBL 相关角色用户的密码
    pbl_roles = ['school_admin', 'teacher', 'student']
    if user.role not in pbl_roles:
        return error_response(
            message="该用户不在管理范围内",
            code=403,
            status_code=status.HTTP_403_FORBIDDEN
        )
    
    # 权限控制
    if current_admin.role not in ['platform_admin', 'school_admin']:
        return error_response(
            message="无权限操作",
            code=403,
            status_code=status.HTTP_403_FORBIDDEN
        )
    
    if current_admin.role == 'school_admin' and user.school_id != current_admin.school_id:
        return error_response(
            message="无权限重置该用户密码",
            code=403,
            status_code=status.HTTP_403_FORBIDDEN
        )
    
    # 重置密码
    user.password_hash = get_password_hash(new_password)
    user.need_change_password = True  # 标记需要修改密码
    db.commit()
    
    logger.info(f"重置用户密码 - 用户名: {user.username}, ID: {user.id}, 操作者: {current_admin.username}")
    
    return success_response(message="密码重置成功")

@router.post("/batch-import/students")
async def batch_import_students(
    school_id: int,
    file: UploadFile = File(...),
    db: Session = Depends(get_db),
    current_admin: Admin = Depends(get_current_admin)
):
    """批量导入学生（CSV格式）
    
    CSV格式要求：
    username,name,student_number,class_id,gender,phone,email,password
    """
    # 权限检查
    if current_admin.role not in ['platform_admin', 'school_admin']:
        return error_response(
            message="无权限操作",
            code=403,
            status_code=status.HTTP_403_FORBIDDEN
        )
    
    if current_admin.role == 'school_admin' and school_id != current_admin.school_id:
        return error_response(
            message="只能导入本校学生",
            code=403,
            status_code=status.HTTP_403_FORBIDDEN
        )
    
    # 验证学校是否存在
    school = db.query(School).filter(School.id == school_id).first()
    if not school:
        return error_response(
            message="学校不存在",
            code=404,
            status_code=status.HTTP_404_NOT_FOUND
        )
    
    # 检查文件类型
    if not file.filename.endswith('.csv'):
        return error_response(
            message="只支持CSV文件格式",
            code=400,
            status_code=status.HTTP_400_BAD_REQUEST
        )
    
    try:
        # 读取CSV文件
        contents = await file.read()
        decoded = contents.decode('utf-8-sig')  # 支持带BOM的UTF-8
        csv_reader = csv.DictReader(io.StringIO(decoded))
        
        success_count = 0
        error_list = []
        
        for row_num, row in enumerate(csv_reader, start=2):  # 从第2行开始（第1行是标题）
            try:
                # 验证必填字段
                if not row.get('username') or not row.get('name'):
                    error_list.append({
                        'row': row_num,
                        'error': '缺少必填字段（username, name）'
                    })
                    continue
                
                # 检查用户名是否已存在
                if db.query(User).filter(User.username == row['username']).first():
                    error_list.append({
                        'row': row_num,
                        'username': row['username'],
                        'error': '用户名已存在'
                    })
                    continue
                
                # 生成默认密码（如果没有提供）
                password = row.get('password') or '123456'
                
                # 创建学生用户
                new_student = User(
                    username=row['username'],
                    name=row['name'],
                    student_number=row.get('student_number'),
                    class_id=int(row['class_id']) if row.get('class_id') else None,
                    gender=row.get('gender'),
                    phone=row.get('phone'),
                    email=row.get('email'),
                    password_hash=get_password_hash(password),
                    role='student',
                    school_id=school_id,
                    school_name=school.school_name,
                    is_active=True,
                    need_change_password=True  # 首次登录需要修改密码
                )
                
                db.add(new_student)
                success_count += 1
                
            except Exception as e:
                error_list.append({
                    'row': row_num,
                    'error': str(e)
                })
        
        # 提交所有成功的记录
        db.commit()
        
        logger.info(f"批量导入学生完成 - 成功: {success_count}, 失败: {len(error_list)}, 操作者: {current_admin.username}")
        
        return success_response(
            data={
                'success_count': success_count,
                'error_count': len(error_list),
                'errors': error_list[:10]  # 只返回前10个错误
            },
            message=f"导入完成：成功 {success_count} 条，失败 {len(error_list)} 条"
        )
        
    except Exception as e:
        logger.error(f"批量导入学生失败: {str(e)}", exc_info=True)
        return error_response(
            message=f"导入失败：{str(e)}",
            code=500,
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR
        )

@router.post("/batch-import/teachers")
async def batch_import_teachers(
    school_id: int,
    file: UploadFile = File(...),
    db: Session = Depends(get_db),
    current_admin: Admin = Depends(get_current_admin)
):
    """批量导入教师（CSV格式）
    
    CSV格式要求：
    username,name,teacher_number,subject,gender,phone,email,password
    """
    # 权限检查
    if current_admin.role not in ['platform_admin', 'school_admin']:
        return error_response(
            message="无权限操作",
            code=403,
            status_code=status.HTTP_403_FORBIDDEN
        )
    
    if current_admin.role == 'school_admin' and school_id != current_admin.school_id:
        return error_response(
            message="只能导入本校教师",
            code=403,
            status_code=status.HTTP_403_FORBIDDEN
        )
    
    # 验证学校是否存在
    school = db.query(School).filter(School.id == school_id).first()
    if not school:
        return error_response(
            message="学校不存在",
            code=404,
            status_code=status.HTTP_404_NOT_FOUND
        )
    
    # 检查文件类型
    if not file.filename.endswith('.csv'):
        return error_response(
            message="只支持CSV文件格式",
            code=400,
            status_code=status.HTTP_400_BAD_REQUEST
        )
    
    try:
        # 读取CSV文件
        contents = await file.read()
        decoded = contents.decode('utf-8-sig')
        csv_reader = csv.DictReader(io.StringIO(decoded))
        
        success_count = 0
        error_list = []
        
        for row_num, row in enumerate(csv_reader, start=2):
            try:
                # 验证必填字段
                if not row.get('username') or not row.get('name'):
                    error_list.append({
                        'row': row_num,
                        'error': '缺少必填字段（username, name）'
                    })
                    continue
                
                # 检查用户名是否已存在
                if db.query(User).filter(User.username == row['username']).first():
                    error_list.append({
                        'row': row_num,
                        'username': row['username'],
                        'error': '用户名已存在'
                    })
                    continue
                
                # 生成默认密码
                password = row.get('password') or '123456'
                
                # 创建教师用户
                new_teacher = User(
                    username=row['username'],
                    name=row['name'],
                    teacher_number=row.get('teacher_number'),
                    subject=row.get('subject'),
                    gender=row.get('gender'),
                    phone=row.get('phone'),
                    email=row.get('email'),
                    password_hash=get_password_hash(password),
                    role='teacher',
                    school_id=school_id,
                    school_name=school.school_name,
                    is_active=True,
                    need_change_password=True
                )
                
                db.add(new_teacher)
                success_count += 1
                
            except Exception as e:
                error_list.append({
                    'row': row_num,
                    'error': str(e)
                })
        
        db.commit()
        
        logger.info(f"批量导入教师完成 - 成功: {success_count}, 失败: {len(error_list)}, 操作者: {current_admin.username}")
        
        return success_response(
            data={
                'success_count': success_count,
                'error_count': len(error_list),
                'errors': error_list[:10]
            },
            message=f"导入完成：成功 {success_count} 条，失败 {len(error_list)} 条"
        )
        
    except Exception as e:
        logger.error(f"批量导入教师失败: {str(e)}", exc_info=True)
        return error_response(
            message=f"导入失败：{str(e)}",
            code=500,
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR
        )

