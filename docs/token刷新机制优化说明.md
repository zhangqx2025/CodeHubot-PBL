# Token刷新机制优化说明

## 问题背景

在之前的实现中，refresh token只包含用户ID（`sub`字段），但没有包含用户类型（`user_role`）信息。这导致在刷新token时无法准确判断token属于哪种类型的用户，可能出现以下问题：

1. **管理员刷新endpoint**（`/api/admin/auth/refresh`）只验证用户是否为`platform_admin`，导致教师（teacher）和学校管理员（school_admin）无法使用该endpoint刷新token
2. **学生刷新endpoint**（`/api/student/auth/refresh`）只从User表查询，但没有验证用户类型，可能导致类型混淆
3. **缺乏类型验证**：没有机制防止使用错误类型的token进行刷新操作

## 解决方案

### 1. Token中添加用户角色字段

在创建access token和refresh token时，添加`user_role`字段到payload中：

```python
# 管理员登录
access_token = create_access_token(data={"sub": str(admin.id), "user_role": admin.role})
refresh_token = create_refresh_token(data={"sub": str(admin.id), "user_role": admin.role})

# 学生登录
access_token = create_access_token(data={"sub": str(user.id), "user_role": user.role})
refresh_token = create_refresh_token(data={"sub": str(user.id), "user_role": user.role})
```

### 2. 管理员刷新endpoint优化

**修改文件**：`backend/app/api/endpoints/admin_auth.py`

**主要改进**：
- 支持所有管理员类型（`platform_admin`、`school_admin`、`teacher`）
- 从refresh token中获取`user_role`字段
- 验证token中的角色是否为管理员类型
- 验证token中的角色与数据库中的实际角色是否匹配
- 生成新token时继续包含用户角色信息

### 3. 学生刷新endpoint优化

**修改文件**：`backend/app/api/endpoints/student_auth.py`

**主要改进**：
- 仅支持学生类型（`student`）
- 从refresh token中获取`user_role`字段
- 验证token中的角色是否为学生类型
- 验证token中的角色与数据库中的实际角色是否匹配
- 生成新token时继续包含用户角色信息

## Token Payload结构

### 旧版本
```json
{
  "sub": "123",
  "type": "refresh",
  "exp": 1234567890
}
```

### 新版本
```json
{
  "sub": "123",
  "user_role": "teacher",
  "type": "refresh",
  "exp": 1234567890
}
```

## 刷新流程

### 管理员刷新流程

1. 客户端发送refresh token到 `/api/admin/auth/refresh`
2. 服务端验证refresh token的有效性和类型
3. 从payload中提取`user_id`和`user_role`
4. 验证`user_role`是否为管理员类型（`platform_admin`/`school_admin`/`teacher`）
5. 从Admin表查询用户
6. 验证token中的角色与数据库中的实际角色是否匹配
7. 验证用户状态是否活跃
8. 生成新的access token和refresh token（包含用户角色信息）
9. 返回新的token对

### 学生刷新流程

1. 客户端发送refresh token到 `/api/student/auth/refresh`
2. 服务端验证refresh token的有效性和类型
3. 从payload中提取`user_id`和`user_role`
4. 验证`user_role`是否为学生类型（`student`）
5. 从User表查询用户
6. 验证token中的角色与数据库中的实际角色是否匹配
7. 验证用户状态是否活跃
8. 生成新的access token和refresh token（包含用户角色信息）
9. 返回新的token对

## 错误处理

系统会在以下情况返回401错误：

- Refresh token无效或已过期
- Token中缺少用户ID
- Token中的用户类型不匹配（如在管理员endpoint使用学生token）
- 用户不存在
- Token中的角色与数据库中的实际角色不匹配

系统会在以下情况返回403错误：

- 用户账户已被禁用

## 兼容性说明

### 向后兼容性

对于使用旧版本token（不包含`user_role`字段）的客户端：

1. **access token验证**：仍然可以正常工作，因为`get_current_admin`和`get_current_user`依赖项只使用`sub`字段
2. **refresh token刷新**：会失败，因为新的刷新逻辑要求token中必须包含`user_role`字段

**建议**：用户需要重新登录以获取包含`user_role`的新token。

### 前端调整建议

前端代码通常不需要修改，因为：
1. Token的创建和验证都在后端完成
2. 前端只需要存储和发送token
3. Token的payload对前端是透明的

## 安全性增强

1. **类型隔离**：防止使用管理员token访问学生endpoint，反之亦然
2. **角色验证**：确保token中声明的角色与数据库中的实际角色一致，防止权限提升
3. **精确匹配**：不仅验证用户存在，还验证角色匹配，增加了安全性

## 部署建议

1. **部署新版本后端代码**
2. **通知用户**：告知用户可能需要重新登录
3. **监控日志**：关注刷新令牌失败的日志，及时发现问题

## 测试建议

1. 测试平台管理员登录和刷新
2. 测试学校管理员登录和刷新
3. 测试教师登录和刷新
4. 测试学生登录和刷新
5. 测试使用错误类型的token进行刷新（应该失败）
6. 测试角色被修改后的token刷新（应该失败）
