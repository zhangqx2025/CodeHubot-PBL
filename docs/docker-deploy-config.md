# Docker 容器化部署配置说明

## 配置文件说明

### 1. 环境变量配置

#### docker/.env
容器化部署的主配置文件，从 `docker/.env.example` 复制并修改。

```bash
# 复制示例配置
cd docker
cp .env.example .env
```

**主要配置项：**
- `FRONTEND_PORT`: 前端访问端口（默认 8082）
- `SECRET_KEY`: JWT密钥（务必修改为随机字符串）
- `MYSQL_HOST`: MySQL主机名（容器内使用服务名，如 `codehubot-mysql`）
- `MYSQL_PORT`: MySQL端口（默认 3306）
- `MYSQL_DATABASE`: 数据库名（默认 `aiot_pbl`）
- `MYSQL_USER`: 数据库用户名
- `MYSQL_PASSWORD`: 数据库密码

#### backend/env.example
后端独立部署时的环境变量示例（容器化部署时不直接使用）。

#### frontend/.env.production
前端生产环境配置，构建时自动读取。

**主要配置项：**
- `VITE_API_BASE_URL`: API基础URL（生产环境为空，通过nginx代理）
- `VITE_APP_TITLE`: 应用标题
- `VITE_MODE`: 运行模式

### 2. 网络配置

#### Nginx 配置 (frontend/nginx.conf)

前端容器使用 Nginx 作为 Web 服务器，主要配置：

```nginx
# API代理配置
location /api {
    proxy_pass http://pbl-backend:8000;
    # ... 其他代理配置
}
```

**说明：**
- 前端请求 `/api/*` 会被代理到后端容器的 `http://pbl-backend:8000/api/*`
- 后端路由已包含 `/api/v1` 前缀
- 前端代码使用相对路径 `/admin/auth/login` 等，由 axios baseURL 自动拼接

### 3. API 路径规则

#### 完整请求链路

1. **前端代码**: 
   ```javascript
   // baseURL: /api/v1
   httpClient.post('/admin/auth/login', data)
   ```

2. **浏览器发送**: 
   ```
   POST http://localhost:8082/api/v1/admin/auth/login
   ```

3. **Nginx 代理**:
   ```
   转发到: http://pbl-backend:8000/api/v1/admin/auth/login
   ```

4. **后端处理**:
   ```python
   @router.post("/api/v1/admin/auth/login")
   ```

#### 重要提醒

⚠️ **避免路径重复**：
- ✅ 正确：`httpClient.post('/admin/auth/login')`
- ❌ 错误：`httpClient.post('/api/v1/admin/auth/login')`

因为 axios 的 baseURL 已经包含了 `/api/v1`。

## 部署步骤

### 1. 准备环境

```bash
# 1. 确保 Docker 和 Docker Compose 已安装
docker --version
docker-compose --version

# 2. 确保 aiot-network 网络存在（与其他 CodeHubot 服务共享）
docker network create docker_aiot-network 2>/dev/null || true
```

### 2. 配置环境变量

```bash
# 进入 docker 目录
cd docker

# 复制环境变量配置
cp .env.example .env

# 编辑配置（重要！）
vim .env
```

**必须修改的配置：**
1. `SECRET_KEY`: 生成随机字符串
   ```bash
   openssl rand -hex 32
   ```
2. `MYSQL_*`: 根据实际数据库配置修改

### 3. 初始化数据库

```bash
# 在 MySQL 中执行初始化脚本
mysql -h <host> -u <user> -p < ../SQL/init_database.sql
```

### 4. 启动服务

```bash
# 在 docker 目录下
docker-compose up -d

# 查看服务状态
docker-compose ps

# 查看日志
docker-compose logs -f
```

### 5. 访问服务

- 前端访问：http://localhost:8082
- 管理后台：http://localhost:8082/admin/login

## 常见问题

### 1. API 请求返回 404

**可能原因：**
- 路径配置错误（如路径重复 `/api/v1/api/v1/...`）
- Nginx 代理配置错误
- 后端服务未启动

**解决方法：**
```bash
# 检查后端日志
docker logs pbl-backend

# 检查前端日志
docker logs pbl-frontend

# 验证路径配置
curl http://localhost:8082/api/v1/admin/auth/login
```

### 2. 数据库连接失败

**可能原因：**
- MySQL 服务未启动
- 网络配置错误
- 数据库凭证错误

**解决方法：**
```bash
# 检查 MySQL 容器
docker ps | grep mysql

# 测试网络连通性
docker exec pbl-backend ping codehubot-mysql

# 验证数据库连接
docker exec pbl-backend python -c "from app.db.session import engine; print(engine.connect())"
```

### 3. 前端无法连接后端

**可能原因：**
- 容器未在同一网络
- Nginx 配置错误

**解决方法：**
```bash
# 检查网络
docker network inspect docker_aiot-network

# 重启服务
docker-compose restart
```

## 维护操作

### 更新代码

```bash
# 拉取最新代码
git pull

# 重新构建并启动
cd docker
docker-compose up -d --build
```

### 查看日志

```bash
# 查看所有日志
docker-compose logs

# 实时跟踪日志
docker-compose logs -f

# 查看特定服务日志
docker-compose logs pbl-backend
docker-compose logs pbl-frontend
```

### 停止服务

```bash
# 停止服务
docker-compose stop

# 停止并删除容器
docker-compose down

# 删除容器和卷
docker-compose down -v
```

## 安全建议

1. **修改默认密钥**：务必修改 `SECRET_KEY`
2. **使用强密码**：数据库密码应足够复杂
3. **限制端口访问**：生产环境应配置防火墙
4. **定期备份**：定期备份数据库和配置文件
5. **更新依赖**：定期更新 Docker 镜像和依赖包
