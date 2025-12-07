# 登录逻辑统一修改说明

## 修改日期
2025-12-07

## 修改目的
统一 CodeHubot-PBL 和 CodeHubot 两个项目的管理员登录逻辑，确保使用相同的数据库表时保持一致的行为。

## 主要问题
1. **配置管理不一致**：CodeHubot 使用统一的 `config.py` 和 `settings` 对象，而 CodeHubot-PBL 直接使用环境变量
2. **verify_token 行为不同**：CodeHubot 抛出 HTTPException，CodeHubot-PBL 返回 None
3. **缺少 last_login 更新**：CodeHubot 在登录时更新 `last_login` 字段，CodeHubot-PBL 没有
4. **时区处理不统一**：需要统一使用北京时间(UTC+8)

## 修改内容

### 1. 新增文件

#### `backend/app/core/config.py`
- 创建统一的配置管理类 `Settings`
- 使用 pydantic-settings 从环境变量读取配置
- 自动构建数据库连接 URL
- 验证安全配置（JWT 密钥强度等）
- 支持的配置项：
  - 数据库配置（db_host, db_port, db_user, db_password, db_name）
  - JWT 配置（secret_key, algorithm, access_token_expire_minutes, refresh_token_expire_minutes）
  - 环境配置（environment, log_level）

#### `backend/app/utils/timezone.py`
- 统一时区处理工具模块
- 定义北京时区（UTC+8）
- 提供时区转换函数：
  - `get_beijing_time()`: 获取带时区信息的北京时间
  - `get_beijing_time_naive()`: 获取不带时区信息的北京时间（用于数据库存储）
  - `utc_to_beijing()`: UTC 转北京时间
  - `beijing_to_utc()`: 北京时间转 UTC
  - `format_datetime_beijing()`: 格式化为 ISO 8601 格式

### 2. 修改文件

#### `backend/app/core/security.py`
**主要改动：**
- 引入 `settings` 配置对象，替换直接读取环境变量
- 统一 `verify_token` 函数行为，改为抛出 HTTPException 而不是返回 None
- 更新 `create_access_token` 和 `create_refresh_token`，使用 settings 中的配置
- 改进错误处理和日志记录

**关键变更：**
```python
# 之前
SECRET_KEY = os.getenv("SECRET_KEY", "your-secret-key-change-in-production")
ACCESS_TOKEN_EXPIRE_MINUTES = int(os.getenv("ACCESS_TOKEN_EXPIRE_MINUTES", "15"))

def verify_token(token: str, token_type: str = None) -> Optional[dict]:
    # 返回 None 或 payload
    
# 之后
from app.core.config import settings

def verify_token(token: str, token_type: Optional[str] = "access") -> dict:
    # 抛出 HTTPException
```

#### `backend/app/core/deps.py`
**主要改动：**
- 更新 `get_current_admin` 函数，适配 `verify_token` 的新行为
- 添加异常处理逻辑

**关键变更：**
```python
# 之前
payload = verify_token(token)
if payload is None:
    raise credentials_exception

# 之后
try:
    payload = verify_token(token, token_type="access")
except HTTPException:
    raise
```

#### `backend/app/api/endpoints/admin_auth.py`
**主要改动：**
1. 引入时区工具模块
2. 在管理员登录时更新 `last_login` 字段
3. 更新 `refresh_access_token` 函数，适配 `verify_token` 的新行为

**关键变更：**
```python
# 添加导入
from ...utils.timezone import get_beijing_time_naive

# 在登录成功后添加
admin.last_login = get_beijing_time_naive()
db.commit()

# refresh token 验证改为捕获异常
try:
    payload = verify_token(request.refresh_token, token_type="refresh")
except HTTPException as e:
    return error_response(...)
```

#### `backend/app/models/admin.py`
**主要改动：**
- 引入时区工具模块
- 更新 `created_at` 和 `updated_at` 字段，使用北京时间

**关键变更：**
```python
# 之前
created_at = Column(DateTime, server_default=func.now())
updated_at = Column(DateTime, server_default=func.now(), onupdate=func.now())

# 之后
from ..utils.timezone import get_beijing_time_naive

created_at = Column(DateTime, default=get_beijing_time_naive)
updated_at = Column(DateTime, default=get_beijing_time_naive, onupdate=get_beijing_time_naive)
```

## 与 CodeHubot 的一致性对比

| 特性 | CodeHubot | CodeHubot-PBL（修改前） | CodeHubot-PBL（修改后） |
|------|-----------|------------------------|------------------------|
| 配置管理 | settings 对象 | 直接读环境变量 | ✅ settings 对象 |
| verify_token 行为 | 抛出异常 | 返回 None | ✅ 抛出异常 |
| last_login 更新 | ✅ 更新 | ❌ 不更新 | ✅ 更新 |
| 时区处理 | 北京时间 (UTC+8) | 未统一 | ✅ 北京时间 (UTC+8) |
| 密码加密算法 | pbkdf2_sha256 | pbkdf2_sha256 | ✅ pbkdf2_sha256 |
| JWT 配置 | 可配置 | 可配置 | ✅ 可配置 |

## 兼容性说明

### 数据库兼容性
- 两个项目使用同一个数据库表 `aiot_core_users`
- 字段结构完全兼容
- 时间字段现在统一使用北京时间存储

### API 兼容性
- 对外 API 接口保持不变
- Token 格式和验证逻辑统一
- 错误响应格式保持一致

### 环境变量要求
修改后需要确保以下环境变量已配置：
```env
# 数据库配置
DB_HOST=localhost
DB_PORT=3306
DB_USER=root
DB_PASSWORD=your_password
DB_NAME=aiot_admin

# JWT 配置
SECRET_KEY=your-secret-key-at-least-32-characters
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=15
REFRESH_TOKEN_EXPIRE_MINUTES=45

# 可选配置
ENVIRONMENT=development
LOG_LEVEL=INFO
```

## 测试建议

1. **登录测试**
   - 测试管理员用户登录
   - 验证 `last_login` 字段是否正确更新
   - 检查时区是否正确（应为北京时间）

2. **Token 测试**
   - 测试 access token 和 refresh token 的生成
   - 测试 token 过期处理
   - 测试 token 类型验证

3. **配置测试**
   - 验证环境变量是否正确加载
   - 测试配置验证逻辑（如密钥强度检查）

4. **异常处理测试**
   - 测试无效 token 的错误响应
   - 测试过期 token 的错误响应
   - 测试禁用账户的访问限制

## 迁移注意事项

1. **环境变量**：确保所有必需的环境变量已配置
2. **数据库**：无需修改数据库结构，现有数据完全兼容
3. **已有 Token**：已签发的 token 仍然有效，使用相同的验证逻辑
4. **日志**：注意查看启动日志，确认配置加载成功

## 后续建议

1. 考虑为两个项目共享配置模块，避免代码重复
2. 统一错误处理和响应格式
3. 考虑添加单元测试，确保登录逻辑的稳定性
4. 监控 `last_login` 字段的更新，用于用户活跃度分析

## 相关文件

- `backend/app/core/config.py` - 配置管理
- `backend/app/core/security.py` - 安全相关函数
- `backend/app/core/deps.py` - 依赖注入
- `backend/app/api/endpoints/admin_auth.py` - 管理员认证端点
- `backend/app/models/admin.py` - 管理员模型
- `backend/app/utils/timezone.py` - 时区工具

