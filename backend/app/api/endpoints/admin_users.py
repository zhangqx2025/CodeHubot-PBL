from fastapi import APIRouter, Depends, HTTPException, status, UploadFile, File
from sqlalchemy.orm import Session
from typing import List, Optional
import csv
import io
from datetime import datetime
from app.utils.timezone import get_beijing_time_naive

from ...db.session import SessionLocal
from ...core.response import success_response, error_response
from ...core.deps import get_db, get_current_admin
from ...core.security import get_password_hash
from ...models.admin import Admin, User
from ...models.school import School
from ...models.pbl import PBLClass
from ...schemas.user import UserCreate, UserResponse, UserUpdate, ResetPasswordRequest
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
    
    # 权限检查和学校ID确定
    school_id = None
    
    # 学校管理员只能创建教师和学生，且自动使用其所属学校
    if current_admin.role == 'school_admin':
        if user_data.role == 'school_admin':
            return error_response(
                message="学校管理员不能创建学校管理员账号",
                code=403,
                status_code=status.HTTP_403_FORBIDDEN
            )
        if not current_admin.school_id:
            return error_response(
                message="您的账号未关联学校，无法创建用户",
                code=403,
                status_code=status.HTTP_403_FORBIDDEN
            )
        # 学校管理员创建用户时，自动使用其所属学校
        school_id = current_admin.school_id
    
    # 平台管理员可以创建任意角色，但必须指定学校
    elif current_admin.role == 'platform_admin':
        if not user_data.school_id:
            return error_response(
                message="平台管理员创建用户时必须指定学校",
                code=400,
                status_code=status.HTTP_400_BAD_REQUEST
            )
        school_id = user_data.school_id
    
    else:
        return error_response(
            message="无权限创建用户",
            code=403,
            status_code=status.HTTP_403_FORBIDDEN
        )
    
    # 验证学校是否存在，并获取学校编码
    school = db.query(School).filter(School.id == school_id).first()
    if not school:
        return error_response(
            message="学校不存在",
            code=404,
            status_code=status.HTTP_404_NOT_FOUND
        )
    
    # 根据角色验证职工号或学号是否填写
    if user_data.role == 'teacher' or user_data.role == 'school_admin':
        if not user_data.teacher_number:
            return error_response(
                message="教师和学校管理员必须填写职工号",
                code=400,
                status_code=status.HTTP_400_BAD_REQUEST
            )
        # 自动生成用户名：职工号 + 学校编码
        username = f"{user_data.teacher_number}@{school.school_code}"
    elif user_data.role == 'student':
        if not user_data.student_number:
            return error_response(
                message="学生必须填写学号",
                code=400,
                status_code=status.HTTP_400_BAD_REQUEST
            )
        # 自动生成用户名：学号 + 学校编码
        username = f"{user_data.student_number}@{school.school_code}"
    else:
        return error_response(
            message="无效的角色",
            code=400,
            status_code=status.HTTP_400_BAD_REQUEST
        )
    
    # 检查用户名是否已存在
    existing_user = db.query(User).filter(User.username == username).first()
    if existing_user:
        return error_response(
            message="该职工号/学号在本校已存在",
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
        username=username,  # 使用自动生成的用户名
        email=user_data.email,
        password_hash=get_password_hash(user_data.password),
        name=user_data.name,
        real_name=user_data.real_name,
        nickname=user_data.nickname,
        phone=user_data.phone,
        role=user_data.role or 'student',
        school_id=school_id,  # 使用验证后的学校ID
        class_id=user_data.class_id,
        group_id=user_data.group_id,
        school_name=school.school_name,
        teacher_number=user_data.teacher_number,
        student_number=user_data.student_number,
        subject=user_data.subject,
        gender=user_data.gender,
        is_active=True
    )
    
    db.add(new_user)
    db.commit()
    db.refresh(new_user)
    
    logger.info(f"创建用户成功 - 用户名: {username}, ID: {new_user.id}, 操作者: {current_admin.username}")
    
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
    user.deleted_at = get_beijing_time_naive()
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
    
    # 防止管理员禁用自己的账号
    if user.role == 'school_admin' and user.id == current_admin.id and user.is_active:
        return error_response(
            message="不能禁用自己的账号",
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
    request: ResetPasswordRequest,
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
    user.password_hash = get_password_hash(request.new_password)
    user.need_change_password = True  # 标记需要修改密码
    db.commit()
    
    logger.info(f"重置用户密码 - 用户名: {user.username}, ID: {user.id}, 操作者: {current_admin.username}")
    
    return success_response(message="密码重置成功")

@router.post("/batch-import/students")
async def batch_import_students(
    file: UploadFile = File(...),
    school_id: Optional[int] = None,
    db: Session = Depends(get_db),
    current_admin: Admin = Depends(get_current_admin)
):
    """批量导入学生（CSV格式）
    
    CSV格式要求：
    name,student_number,class_id,gender,phone,email,password
    注意：用户名将自动生成为 学号@学校编码
    
    学校ID获取逻辑：
    - 学校管理员：自动使用其所属学校ID（忽略参数中的 school_id）
    - 平台管理员：必须通过参数指定 school_id
    """
    # 权限检查和确定学校ID
    if current_admin.role == 'school_admin':
        if not current_admin.school_id:
            return error_response(
                message="您的账号未关联学校，无法导入学生",
                code=403,
                status_code=status.HTTP_403_FORBIDDEN
            )
        # 学校管理员自动使用其所属学校
        target_school_id = current_admin.school_id
    elif current_admin.role == 'platform_admin':
        if not school_id:
            return error_response(
                message="平台管理员必须指定学校ID",
                code=400,
                status_code=status.HTTP_400_BAD_REQUEST
            )
        target_school_id = school_id
    else:
        return error_response(
            message="无权限操作",
            code=403,
            status_code=status.HTTP_403_FORBIDDEN
        )
    
    # 验证学校是否存在
    school = db.query(School).filter(School.id == target_school_id).first()
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
        
        # 尝试多种编码格式解码
        decoded = None
        encodings = ['utf-8-sig', 'utf-8', 'gbk', 'gb2312', 'gb18030']
        for encoding in encodings:
            try:
                decoded = contents.decode(encoding)
                break
            except (UnicodeDecodeError, LookupError):
                continue
        
        if decoded is None:
            return error_response(
                message="无法识别文件编码，请确保CSV文件使用UTF-8或GBK编码",
                code=400,
                status_code=status.HTTP_400_BAD_REQUEST
            )
        
        csv_reader = csv.DictReader(io.StringIO(decoded))
        
        success_count = 0
        error_list = []
        
        # 获取该学校的所有班级，用于名称查找
        classes_dict = {}
        classes = db.query(PBLClass).filter(
            PBLClass.school_id == target_school_id,
            PBLClass.is_active == 1
        ).all()
        for cls in classes:
            classes_dict[cls.name] = cls.id
        
        for row_num, row in enumerate(csv_reader, start=2):  # 从第2行开始（第1行是标题）
            try:
                # 验证必填字段
                if not row.get('student_number') or not row.get('name') or not row.get('gender'):
                    error_list.append({
                        'row': row_num,
                        'error': '缺少必填字段（student_number, name, gender）'
                    })
                    continue
                
                # 自动生成用户名：学号 + 学校编码
                username = f"{row['student_number']}@{school.school_code}"
                
                # 检查用户名是否已存在
                if db.query(User).filter(User.username == username).first():
                    error_list.append({
                        'row': row_num,
                        'student_number': row['student_number'],
                        'error': '该学号在本校已存在'
                    })
                    continue
                
                # 转换性别：男->male, 女->female
                gender_map = {
                    '男': 'male',
                    '女': 'female',
                    'male': 'male',
                    'female': 'female'
                }
                gender = gender_map.get(row.get('gender', '').strip())
                if not gender:
                    error_list.append({
                        'row': row_num,
                        'error': '性别格式错误，请填写"男"或"女"'
                    })
                    continue
                
                # 处理班级：如果提供了班级名称，查找对应的班级ID
                # 如果班级名称为空，则不分配班级但允许导入
                class_id = None
                if row.get('class_name'):
                    class_name = row['class_name'].strip()
                    if class_name:  # 班级名称不为空
                        if class_name in classes_dict:
                            class_id = classes_dict[class_name]
                        else:
                            # 班级不存在，给出警告但不阻止导入
                            error_list.append({
                                'row': row_num,
                                'warning': f'班级"{class_name}"不存在，已导入但未分配班级'
                            })
                
                # 生成默认密码（如果没有提供）
                password = row.get('password') or '123456'
                
                # 创建学生用户（不收集电话和邮箱）
                new_student = User(
                    username=username,
                    name=row['name'],
                    student_number=row['student_number'],
                    class_id=class_id,
                    gender=gender,
                    password_hash=get_password_hash(password),
                    role='student',
                    school_id=target_school_id,
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
    file: UploadFile = File(...),
    school_id: Optional[int] = None,
    db: Session = Depends(get_db),
    current_admin: Admin = Depends(get_current_admin)
):
    """批量导入教师（CSV格式）
    
    CSV格式要求：
    name,teacher_number,subject,gender,phone,email,password
    注意：用户名将自动生成为 工号@学校编码
    
    学校ID获取逻辑：
    - 学校管理员：自动使用其所属学校ID（忽略参数中的 school_id）
    - 平台管理员：必须通过参数指定 school_id
    """
    # 权限检查和确定学校ID
    if current_admin.role == 'school_admin':
        if not current_admin.school_id:
            return error_response(
                message="您的账号未关联学校，无法导入教师",
                code=403,
                status_code=status.HTTP_403_FORBIDDEN
            )
        # 学校管理员自动使用其所属学校
        target_school_id = current_admin.school_id
    elif current_admin.role == 'platform_admin':
        if not school_id:
            return error_response(
                message="平台管理员必须指定学校ID",
                code=400,
                status_code=status.HTTP_400_BAD_REQUEST
            )
        target_school_id = school_id
    else:
        return error_response(
            message="无权限操作",
            code=403,
            status_code=status.HTTP_403_FORBIDDEN
        )
    
    # 验证学校是否存在
    school = db.query(School).filter(School.id == target_school_id).first()
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
        
        # 尝试多种编码格式解码
        decoded = None
        encodings = ['utf-8-sig', 'utf-8', 'gbk', 'gb2312', 'gb18030']
        for encoding in encodings:
            try:
                decoded = contents.decode(encoding)
                break
            except (UnicodeDecodeError, LookupError):
                continue
        
        if decoded is None:
            return error_response(
                message="无法识别文件编码，请确保CSV文件使用UTF-8或GBK编码",
                code=400,
                status_code=status.HTTP_400_BAD_REQUEST
            )
        
        csv_reader = csv.DictReader(io.StringIO(decoded))
        
        success_count = 0
        error_list = []
        
        for row_num, row in enumerate(csv_reader, start=2):
            try:
                # 验证必填字段
                if not row.get('teacher_number') or not row.get('name') or not row.get('gender'):
                    error_list.append({
                        'row': row_num,
                        'error': '缺少必填字段（teacher_number, name, gender）'
                    })
                    continue
                
                # 自动生成用户名：工号 + 学校编码
                username = f"{row['teacher_number']}@{school.school_code}"
                
                # 检查用户名是否已存在
                if db.query(User).filter(User.username == username).first():
                    error_list.append({
                        'row': row_num,
                        'teacher_number': row['teacher_number'],
                        'error': '该工号在本校已存在'
                    })
                    continue
                
                # 生成默认密码
                password = row.get('password') or '123456'
                
                # 创建教师用户
                new_teacher = User(
                    username=username,
                    name=row['name'],
                    teacher_number=row['teacher_number'],
                    subject=row.get('subject'),
                    gender=row.get('gender'),
                    phone=row.get('phone'),
                    email=row.get('email') if row.get('email') else None,
                    password_hash=get_password_hash(password),
                    role='teacher',
                    school_id=target_school_id,
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

