# 数据库配置指南

## 问题说明

如果你在使用 CodeHubot-PBL 后端时发现系统总是生成 `pbl.db` 文件（SQLite 数据库），而你希望使用 MySQL 数据库，这说明 MySQL 数据库配置没有正确设置。

## 快速诊断

运行数据库配置检查工具：

```bash
cd backend
python check_db_config.py
```

这个工具会检查你的数据库配置是否正确，并提供详细的诊断信息。

## 配置步骤

### 1. 创建 .env 文件

如果还没有 `.env` 文件，复制示例配置：

```bash
cd backend
cp env.example .env
```

### 2. 编辑 .env 文件

打开 `.env` 文件，确保包含以下 MySQL 配置：

```bash
# 数据库配置
DB_HOST=localhost          # 你的 MySQL 服务器地址
DB_PORT=3306              # MySQL 端口（默认 3306）
DB_NAME=aiot_admin        # 数据库名称
DB_USER=aiot_user         # 数据库用户名
DB_PASSWORD=your_password # 数据库密码
```

**重要提示**：
- 请将 `DB_PASSWORD` 改为你的实际密码
- 如果 MySQL 在远程服务器上，将 `DB_HOST` 改为服务器 IP 地址
- 确保数据库 `aiot_admin` 已经创建（如果没有，请先创建）

### 3. 验证配置

运行检查工具验证配置是否正确：

```bash
python check_db_config.py
```

如果配置正确，你会看到：

```
✓ 找到 .env 文件
✓ 已加载 .env 文件

数据库配置检查:
----------------------------------------------------------------------
○ DATABASE_URL: 未配置 (将使用单独的配置项)

  ✓ 主机地址: localhost
  ✓ 端口: 3306
  ✓ 数据库名: aiot_admin
  ✓ 用户名: aiot_user
  ✓ 密码: ********

======================================================================
✓ MySQL 数据库配置完整！
======================================================================

正在测试数据库连接...
✓ 数据库连接成功！
```

### 4. 启动后端服务

配置完成后，启动后端服务：

```bash
uvicorn main:app --reload --port 8082
```

现在你应该能看到类似这样的输出：

```
✓ 使用 MySQL 数据库配置:
  主机: localhost:3306
  数据库: aiot_admin
  用户: aiot_user
INFO:     正在启动 CodeHubot PBL System API...
INFO:     使用生产数据库: mysql+pymysql://localhost/aiot_admin
INFO:     生产环境请手动执行 SQL/init_database.sql 初始化数据库
```

而**不会**再看到关于 SQLite 的警告信息。

## 数据库初始化

### 首次使用（MySQL）

如果是首次使用 MySQL 数据库，需要初始化数据库结构：

1. **创建数据库**：

```sql
CREATE DATABASE aiot_admin CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
```

2. **创建用户并授权**（可选，如果用户不存在）：

```sql
CREATE USER 'aiot_user'@'localhost' IDENTIFIED BY 'your_password';
GRANT ALL PRIVILEGES ON aiot_admin.* TO 'aiot_user'@'localhost';
FLUSH PRIVILEGES;
```

3. **执行初始化 SQL 脚本**：

```bash
mysql -u aiot_user -p aiot_admin < SQL/init_database.sql
```

## 环境变量说明

### 方式一：使用单独的配置项（推荐）

```bash
DB_HOST=localhost          # 数据库主机
DB_PORT=3306              # 数据库端口
DB_NAME=aiot_admin        # 数据库名称
DB_USER=aiot_user         # 数据库用户名
DB_PASSWORD=your_password # 数据库密码
```

**或者使用 MYSQL_ 前缀**（两种方式等效）：

```bash
MYSQL_HOST=localhost
MYSQL_PORT=3306
MYSQL_DATABASE=aiot_admin
MYSQL_USER=aiot_user
MYSQL_PASSWORD=your_password
```

### 方式二：使用 DATABASE_URL（高级）

如果你更喜欢使用单个连接字符串：

```bash
DATABASE_URL=mysql+pymysql://aiot_user:your_password@localhost:3306/aiot_admin?charset=utf8mb4
```

**注意**：如果设置了 `DATABASE_URL`，会优先使用它，其他单独的配置项会被忽略。

## 优先级说明

数据库配置的优先级顺序：

1. `DATABASE_URL` 环境变量（最高优先级）
2. `DB_*` 或 `MYSQL_*` 单独配置项
3. SQLite (`pbl.db`) - 仅作为开发环境的后备方案

## 常见问题

### Q1: 我已经配置了 .env，为什么还是使用 SQLite？

**A**: 可能的原因：

1. `.env` 文件位置不对（应该在 `backend/` 目录下）
2. 环境变量名称写错了（检查是否是 `DB_HOST` 而不是 `HOST` 等）
3. 某个必需的配置项缺失（必须同时配置 HOST、NAME、USER、PASSWORD）
4. `.env` 文件没有被正确加载（确保安装了 `python-dotenv`）

**解决方法**：运行 `python check_db_config.py` 诊断具体问题。

### Q2: 提示 "数据库连接失败"

**A**: 请检查：

1. MySQL 服务是否已启动
2. 数据库名称、用户名、密码是否正确
3. 数据库是否已创建
4. 用户是否有足够的权限访问该数据库
5. 防火墙是否阻止了连接（如果是远程数据库）

### Q3: 如何确认当前使用的是哪个数据库？

**A**: 启动后端时，会在控制台输出数据库配置信息：

- 使用 MySQL：会显示 "✓ 使用 MySQL 数据库配置"
- 使用 SQLite：会显示 "⚠️ 警告: 未检测到 MySQL 数据库配置，使用 SQLite 作为后备数据库"

### Q4: 我在远程服务器上部署，如何配置？

**A**: 在远程服务器上：

1. 编辑 `.env` 文件（如果使用 Docker，可能在 docker-compose.yml 中配置）
2. 将 `DB_HOST` 设置为 MySQL 服务器的地址（可能是 `localhost`、IP 地址或域名）
3. 确保网络连接正常
4. 确保 MySQL 允许远程连接（如果需要）

### Q5: pbl.db 文件已经生成了，切换到 MySQL 后它还有用吗？

**A**: 不会再使用 `pbl.db` 文件了。切换到 MySQL 后：

1. 系统会使用 MySQL 数据库
2. `pbl.db` 可以安全删除（但建议先备份，以防数据丢失）
3. 确保已经在 MySQL 中执行了初始化脚本

## 生产环境注意事项

1. **不要使用 create_all 自动创建表**：生产环境应该手动执行 SQL 脚本
2. **使用强密码**：数据库密码应该足够复杂
3. **限制数据库用户权限**：只授予必要的权限
4. **备份数据库**：定期备份数据库数据
5. **使用环境变量**：不要在代码中硬编码数据库密码

## 开发 vs 生产

| 环境 | 推荐数据库 | 配置方式 | 表创建方式 |
|------|-----------|---------|-----------|
| 开发 | SQLite 或 MySQL | `.env` 文件 | 自动创建 (create_all) 或手动 SQL |
| 生产 | MySQL | 环境变量或配置文件 | 手动执行 SQL 脚本 |

## 相关文件

- `backend/.env` - 环境变量配置文件（需要手动创建）
- `backend/env.example` - 环境变量示例文件
- `backend/app/db/session.py` - 数据库连接配置
- `backend/check_db_config.py` - 数据库配置检查工具
- `SQL/init_database.sql` - 数据库初始化脚本
