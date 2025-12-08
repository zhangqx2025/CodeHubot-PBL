# 平台管理员登录功能部署指南

## 功能概述

本次更新为 PBL 系统添加了平台管理员独立登录功能，区分了两种管理员登录方式：

### 1. 机构管理员登录（教师/学校管理员）
- **登录地址**：`/admin/login`
- **登录格式**：工号@学校代码（如：`T001@DEMO_SCHOOL`）
- **适用角色**：`teacher`、`school_admin`
- **API 接口**：`POST /api/v1/admin/auth/login`

### 2. 平台管理员登录
- **登录地址**：`/platform-admin/login`
- **登录格式**：用户名+密码（如：`admin` / `admin123`）
- **适用角色**：`platform_admin`
- **API 接口**：`POST /api/v1/admin/auth/platform-login`

## 部署步骤

### 第一步：数据库更新

在远程服务器上执行数据库更新脚本，创建平台管理员测试账号：

```bash
# 连接到 MySQL 数据库
mysql -u your_username -p aiot_admin

# 或者直接执行 SQL 文件
mysql -u your_username -p aiot_admin < SQL/update/04_add_platform_admin.sql
```

创建的测试账号信息：
- **用户名**：`admin`
- **密码**：`admin123`
- **角色**：`platform_admin`
- **邮箱**：`admin@codehubot.com`

### 第二步：更新后端代码

```bash
# 在服务器上进入项目目录
cd /path/to/CodeHubot-PBL

# 拉取最新代码
git pull origin main

# 如果使用虚拟环境，激活虚拟环境
source venv/bin/activate  # Linux/Mac
# 或
venv\Scripts\activate  # Windows

# 安装依赖（如有更新）
pip install -r backend/requirements.txt

# 重启后端服务
# 如果使用 systemd
sudo systemctl restart codehubot-pbl-backend

# 或者使用 docker
docker-compose restart backend

# 或者使用 supervisor
supervisorctl restart codehubot-pbl-backend
```

### 第三步：更新前端代码

```bash
# 在前端项目目录
cd frontend

# 安装依赖（如有更新）
npm install

# 构建前端代码
npm run build

# 部署构建后的文件到 Web 服务器
# 具体方式取决于你的部署配置
```

如果使用 nginx，确保新的路由能够正确处理：

```nginx
location / {
    try_files $uri $uri/ /index.html;
}
```

### 第四步：验证功能

#### 1. 验证平台管理员登录

访问平台管理员登录页面：
```
http://your-domain:port/platform-admin/login
```

使用测试账号登录：
- 用户名：`admin`
- 密码：`admin123`

#### 2. 验证机构管理员登录

访问机构管理员登录页面：
```
http://your-domain:port/admin/login
```

使用教师账号登录：
- 工号@学校代码：`T001@DEMO_SCHOOL`
- 密码：`123456`

#### 3. 验证权限控制

登录后，检查以下功能：
- ✅ 能否访问管理后台首页
- ✅ 能否查看课程列表
- ✅ 能否管理学习单元
- ✅ 能否管理资料

## 代码变更说明

### 后端变更

1. **新增接口**：`backend/app/api/endpoints/admin_auth.py`
   - `POST /api/v1/admin/auth/platform-login` - 平台管理员登录接口

2. **权限扩展**：`backend/app/core/deps.py`
   - `get_current_admin` 函数现在支持三种角色：`platform_admin`、`school_admin`、`teacher`

3. **数据库脚本**：`SQL/update/04_add_platform_admin.sql`
   - 添加平台管理员测试账号

### 前端变更

1. **新增页面**：`frontend/src/views/PlatformAdminLogin.vue`
   - 平台管理员登录页面

2. **API 接口**：`frontend/src/api/admin.js`
   - 新增 `platformAdminLogin` 函数

3. **路由配置**：`frontend/src/router/index.js`
   - 新增 `/platform-admin/login` 路由

4. **页面调整**：`frontend/src/views/AdminLogin.vue`
   - 添加切换到平台管理员登录的链接

## 安全建议

1. **修改默认密码**：首次登录后，建议立即修改 `admin` 账号的默认密码

2. **生产环境账号**：在生产环境中，建议创建专用的平台管理员账号，不要使用测试账号

3. **密码策略**：建议设置强密码（至少 12 位，包含大小写字母、数字和特殊字符）

4. **创建新的平台管理员**（可选）：
```sql
-- 生成新密码哈希（在 Python 环境中）
python3 -c "import bcrypt; print(bcrypt.hashpw('your_password'.encode('utf-8'), bcrypt.gensalt()).decode('utf-8'))"

-- 插入新管理员账号
INSERT INTO `aiot_core_users` (
    username, email, password_hash, real_name, name, role, 
    is_active, need_change_password, created_at, updated_at
) VALUES (
    'your_username',
    'your_email@example.com',
    'your_bcrypt_hash',
    '管理员姓名',
    '管理员姓名',
    'platform_admin',
    1,
    0,
    NOW(),
    NOW()
);
```

## 故障排查

### 问题1：前端无法访问 /platform-admin/login

**原因**：前端路由配置未更新或 nginx 配置问题

**解决**：
1. 确认前端已重新构建并部署
2. 检查 nginx 配置是否有 `try_files` 指令

### 问题2：登录时提示"用户名或密码错误"

**原因**：数据库中没有平台管理员账号

**解决**：执行 `SQL/update/04_add_platform_admin.sql` 脚本

### 问题3：登录成功但访问接口返回 401

**原因**：权限验证逻辑未更新

**解决**：
1. 确认后端代码已更新到最新版本
2. 重启后端服务
3. 检查 `backend/app/core/deps.py` 中的 `get_current_admin` 函数

## 相关分支

- **功能分支**：`feature/platform-admin-login`
- **权限修复分支**：`fix/admin-auth-permission`

## 联系支持

如有问题，请查看项目 GitHub Issues 或联系开发团队。
