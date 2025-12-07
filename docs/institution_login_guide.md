# PBL 系统机构登录功能说明

## 概述

CodeHubot-PBL 系统已升级为机构登录方式，与 CodeHubot 主系统共享同一套用户数据库（`aiot_core_users` 和 `aiot_schools` 表）。

## 主要变更

### 1. 后端变更

#### 新增 Schema
- 添加 `InstitutionLoginRequest` Schema，包含字段：
  - `school_code`: 学校代码（必填，2-50字符）
  - `number`: 工号或学号（必填）
  - `password`: 密码（必填）

#### 新增模型
- 添加 `School` 模型 (`app/models/school.py`)，映射到 `aiot_schools` 表

#### 修改登录 API

**学生端登录** (`/auth/student/login`)
- 改为机构登录方式
- 通过 `school_code` 查找学校
- 通过 `student_number` 查找学生用户
- 验证密码并返回 JWT token

**教师端登录** (`/admin/auth/login`)
- 改为机构登录方式
- 通过 `school_code` 查找学校
- 通过 `teacher_number` 查找教师用户
- 排除学生用户登录教师端
- 验证密码并返回 JWT token

### 2. 前端变更

#### 学生端登录 (`/login`)
- 输入格式：`学号@学校代码`（如：`20240001@DEMO_SCHOOL`）
- 前端解析后发送：
  ```javascript
  {
    school_code: "DEMO_SCHOOL",
    number: "20240001",
    password: "123456"
  }
  ```

#### 教师端登录 (`/admin/login`)
- 输入格式：`工号@学校代码`（如：`T001@DEMO_SCHOOL`）
- 前端解析后发送：
  ```javascript
  {
    school_code: "DEMO_SCHOOL",
    number: "T001",
    password: "123456"
  }
  ```

### 3. 数据库变更

#### 新增测试数据
执行 SQL 脚本：`SQL/update/02_add_institution_test_data.sql`

添加的测试数据：
- **测试学校**
  - 学校代码：`DEMO_SCHOOL`
  - 学校名称：演示学校

- **测试学生**
  - 学号：`20240001`
  - 密码：`123456`
  - 登录格式：`20240001@DEMO_SCHOOL`

- **测试教师**
  - 工号：`T001`
  - 密码：`123456`
  - 登录格式：`T001@DEMO_SCHOOL`

- **测试学校管理员**
  - 工号：`A001`
  - 密码：`123456`
  - 登录格式：`A001@DEMO_SCHOOL`

## 使用说明

### 部署步骤

1. **更新数据库**
   ```bash
   mysql -u your_username -p aiot_admin < SQL/update/02_add_institution_test_data.sql
   ```

2. **重启后端服务**
   ```bash
   cd backend
   python main.py
   ```

3. **重启前端服务**
   ```bash
   cd frontend
   npm run dev
   ```

### 测试登录

#### 学生端测试
1. 访问：`http://localhost:5173/login`
2. 输入：`20240001@DEMO_SCHOOL`
3. 密码：`123456`
4. 点击"登录"或使用"一键填入演示账号"

#### 教师端测试
1. 访问：`http://localhost:5173/admin/login`
2. 输入：`T001@DEMO_SCHOOL`
3. 密码：`123456`
4. 点击"登录"或使用"一键填入演示账号"

## 兼容性说明

### 与 CodeHubot 主系统的关系
- **共享数据库表**：
  - `aiot_core_users`：用户表
  - `aiot_schools`：学校表
  
- **用户角色**：
  - `student`：学生（PBL 系统学生端）
  - `teacher`：教师（PBL 系统教师端）
  - `school_admin`：学校管理员（PBL 系统管理员）
  - `platform_admin`：平台管理员（CodeHubot 主系统）
  - `individual`：独立用户（CodeHubot 主系统）

### 数据隔离
- 每个学校的用户通过 `school_id` 进行隔离
- 学生只能使用 `student_number` 登录学生端
- 教师只能使用 `teacher_number` 登录教师端
- 学生用户无法登录教师端

## 安全性

### 密码加密
- 使用 bcrypt 算法加密
- 密码哈希存储在 `password_hash` 字段

### Token 认证
- 使用 JWT (JSON Web Token)
- Access Token 有效期：可配置
- Refresh Token 有效期：可配置

### 学校验证
- 登录时验证学校是否存在
- 验证学校是否激活（`is_active = 1`）

## 故障排查

### 常见问题

1. **学校不存在**
   - 检查学校代码是否正确（必须大写）
   - 确认 `aiot_schools` 表中存在该学校

2. **用户不存在**
   - 确认学号/工号是否正确
   - 确认用户的 `school_id` 与学校 ID 匹配
   - 确认学生用户有 `student_number`
   - 确认教师用户有 `teacher_number`

3. **密码错误**
   - 确认密码是否正确
   - 检查 `password_hash` 字段是否正确生成

4. **账户已禁用**
   - 检查用户的 `is_active` 字段是否为 1
   - 检查学校的 `is_active` 字段是否为 1

## 技术细节

### API 端点

#### 学生登录
```
POST /auth/student/login
Content-Type: application/json

{
  "school_code": "DEMO_SCHOOL",
  "number": "20240001",
  "password": "123456"
}
```

#### 教师登录
```
POST /admin/auth/login
Content-Type: application/json

{
  "school_code": "DEMO_SCHOOL",
  "number": "T001",
  "password": "123456"
}
```

### 响应格式
```json
{
  "code": 200,
  "message": "登录成功",
  "data": {
    "access_token": "eyJ...",
    "refresh_token": "eyJ...",
    "token_type": "bearer",
    "user": {
      "id": 1,
      "username": "student_20240001",
      "role": "student",
      "school_id": 1,
      "school_name": "演示学校",
      "student_number": "20240001",
      ...
    }
  }
}
```

## 开发者注意事项

1. **添加新学校**
   - 必须在 `aiot_schools` 表中添加学校
   - `school_code` 必须唯一且大写
   - 设置 `is_active = 1` 启用学校

2. **添加新用户**
   - 学生用户必须设置 `student_number` 和 `role = 'student'`
   - 教师用户必须设置 `teacher_number` 和 `role = 'teacher'` 或 `'school_admin'`
   - 用户必须关联 `school_id`

3. **密码生成**
   ```python
   from app.core.security import get_password_hash
   password_hash = get_password_hash("123456")
   ```

## 版本历史

- **v1.0** (2025-12-07)
  - 初始版本
  - 实现机构登录功能
  - 添加测试数据
  - 完善文档

## 相关文档

- [CodeHubot 主系统文档](../../CodeHubot/README.md)
- [数据库初始化脚本](../SQL/init_database.sql)
- [数据库更新脚本](../SQL/update/02_add_institution_test_data.sql)
