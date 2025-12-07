# 日志系统使用指南

## 概述

CodeHubot-PBL 后端现在已经配置了完善的日志系统，用于调试和监控应用程序的运行状态。

## 日志功能特性

### 1. 彩色日志输出

日志系统使用不同的颜色标识不同的日志级别：
- **DEBUG** - 青色：详细的调试信息
- **INFO** - 绿色：常规信息
- **WARNING** - 黄色：警告信息
- **ERROR** - 红色：错误信息
- **CRITICAL** - 紫色：严重错误

### 2. 请求追踪中间件

每个HTTP请求都会被记录，包括：
- 请求方法和路径
- 请求头信息（DEBUG级别）
- 响应状态码
- 请求处理时间

### 3. 管理员认证日志

在 `admin_auth.py` 中的所有端点都添加了详细的日志输出：

#### 登录端点 (`/api/v1/admin/auth/login`)
记录以下信息：
- 收到登录请求时的用户名
- 用户查询结果（用户ID、角色、激活状态）
- 密码验证过程
- 角色检查结果
- 账户状态检查
- 登录成功或失败的原因

#### 注册端点 (`/api/v1/admin/auth/register`)
记录以下信息：
- 新管理员注册请求
- 操作者信息
- 用户名和邮箱冲突检查
- 创建成功的管理员信息

#### 令牌刷新端点 (`/api/v1/admin/auth/refresh`)
记录以下信息：
- 刷新令牌请求
- 令牌验证过程
- 用户查询结果
- 刷新成功或失败的原因

## 日志输出示例

### 应用启动时

```
2025-12-07 20:00:00 - __main__ - INFO - 正在启动 CodeHubot PBL System API...
2025-12-07 20:00:00 - __main__ - INFO - 数据库表初始化完成
2025-12-07 20:00:00 - __main__ - INFO - FastAPI 应用初始化完成
2025-12-07 20:00:00 - __main__ - INFO - CORS 中间件配置完成
2025-12-07 20:00:00 - __main__ - INFO - 所有路由注册完成
```

### 登录请求（成功）

```
2025-12-07 20:00:05 - __main__ - INFO - 收到请求: POST /api/v1/admin/auth/login
2025-12-07 20:00:05 - app.api.endpoints.admin_auth - INFO - 收到管理员登录请求 - 用户名: admin
2025-12-07 20:00:05 - app.api.endpoints.admin_auth - DEBUG - 找到用户 - ID: 1, 用户名: admin, 角色: platform_admin, 激活状态: True
2025-12-07 20:00:05 - app.api.endpoints.admin_auth - DEBUG - 验证用户 admin 的密码...
2025-12-07 20:00:05 - app.api.endpoints.admin_auth - DEBUG - 用户 admin 密码验证通过
2025-12-07 20:00:05 - app.api.endpoints.admin_auth - DEBUG - 已更新用户 admin 的最后登录时间
2025-12-07 20:00:05 - app.api.endpoints.admin_auth - INFO - 用户 admin (ID: 1) 登录成功
2025-12-07 20:00:05 - __main__ - INFO - 响应: POST /api/v1/admin/auth/login - 状态码: 200 - 耗时: 0.125秒
```

### 登录请求（失败 - 用户不存在）

```
2025-12-07 20:00:10 - __main__ - INFO - 收到请求: POST /api/v1/admin/auth/login
2025-12-07 20:00:10 - app.api.endpoints.admin_auth - INFO - 收到管理员登录请求 - 用户名: wronguser
2025-12-07 20:00:10 - app.api.endpoints.admin_auth - WARNING - 登录失败 - 用户不存在: wronguser
2025-12-07 20:00:10 - __main__ - INFO - 响应: POST /api/v1/admin/auth/login - 状态码: 401 - 耗时: 0.015秒
```

### 登录请求（失败 - 密码错误）

```
2025-12-07 20:00:15 - __main__ - INFO - 收到请求: POST /api/v1/admin/auth/login
2025-12-07 20:00:15 - app.api.endpoints.admin_auth - INFO - 收到管理员登录请求 - 用户名: admin
2025-12-07 20:00:15 - app.api.endpoints.admin_auth - DEBUG - 找到用户 - ID: 1, 用户名: admin, 角色: platform_admin, 激活状态: True
2025-12-07 20:00:15 - app.api.endpoints.admin_auth - DEBUG - 验证用户 admin 的密码...
2025-12-07 20:00:15 - app.api.endpoints.admin_auth - WARNING - 登录失败 - 用户 admin 密码错误
2025-12-07 20:00:15 - __main__ - INFO - 响应: POST /api/v1/admin/auth/login - 状态码: 401 - 耗时: 0.082秒
```

### 登录请求（失败 - 角色不匹配）

```
2025-12-07 20:00:20 - __main__ - INFO - 收到请求: POST /api/v1/admin/auth/login
2025-12-07 20:00:20 - app.api.endpoints.admin_auth - INFO - 收到管理员登录请求 - 用户名: teacher
2025-12-07 20:00:20 - app.api.endpoints.admin_auth - DEBUG - 找到用户 - ID: 2, 用户名: teacher, 角色: teacher, 激活状态: True
2025-12-07 20:00:20 - app.api.endpoints.admin_auth - WARNING - 登录失败 - 用户 teacher 不是平台管理员，当前角色: teacher
2025-12-07 20:00:20 - __main__ - INFO - 响应: POST /api/v1/admin/auth/login - 状态码: 403 - 耗时: 0.018秒
```

## 日志级别配置

当前日志级别设置为 `DEBUG`，这会输出所有级别的日志。在生产环境中，建议将日志级别设置为 `INFO` 或 `WARNING`。

可以在 `backend/main.py` 中修改日志级别：

```python
# 修改这一行来改变日志级别
setup_logging(level="DEBUG")  # 可选值: DEBUG, INFO, WARNING, ERROR, CRITICAL
```

## 调试指南

当遇到 401 Unauthorized 错误时，查看日志可以快速定位问题：

1. **用户不存在**: 日志会显示 "登录失败 - 用户不存在: xxx"
2. **密码错误**: 日志会显示 "登录失败 - 用户 xxx 密码错误"
3. **角色不匹配**: 日志会显示 "登录失败 - 用户 xxx 不是平台管理员，当前角色: xxx"
4. **账户被禁用**: 日志会显示 "登录失败 - 用户 xxx 账户已被禁用"

## 如何使用

1. **重启后端服务**：
   ```bash
   cd backend
   uvicorn main:app --reload --port 8082
   ```

2. **查看实时日志**：日志会直接输出到控制台

3. **发送登录请求**：使用浏览器或API工具发送登录请求

4. **分析日志输出**：根据日志中的详细信息判断问题所在

## 注意事项

- 在生产环境中，应该将敏感信息（如密码）从日志中移除或脱敏
- 建议在生产环境使用 INFO 或 WARNING 级别的日志
- 可以配置日志输出到文件以便长期保存和分析
- 当前配置主要用于开发和调试，生产环境可能需要更复杂的日志配置

## 后续改进建议

1. **日志文件输出**：将日志同时输出到文件，便于历史记录查询
2. **日志轮转**：配置日志文件大小限制和自动轮转
3. **结构化日志**：使用JSON格式输出，便于日志分析工具处理
4. **请求ID追踪**：为每个请求分配唯一ID，便于追踪整个请求链路
5. **敏感信息脱敏**：自动检测并脱敏密码、token等敏感信息
