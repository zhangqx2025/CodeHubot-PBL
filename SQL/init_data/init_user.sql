-- ==========================================================================================================
-- CodeHubot 系统初始数据脚本
-- ==========================================================================================================
-- 
-- 脚本名称: init_data.sql
-- 脚本版本: 1.0.0
-- 创建日期: 2025-12-09
-- 兼容版本: MySQL 5.7.x, 8.0.x
-- 字符集: utf8mb4
-- 排序规则: utf8mb4_unicode_ci
--
-- ==========================================================================================================
-- 脚本说明
-- ==========================================================================================================
--
-- 1. 用途说明:
--    本脚本用于初始化 CodeHubot 系统的初始数据，包含：
--    - 平台管理员账号
--    - 系统默认配置数据（如需要）
--
-- 2. 执行前提条件:
--    - 已执行 init_database.sql 创建所有表结构
--    - MySQL Server 5.7.x 或 8.0.x 已安装并正常运行
--    - 目标数据库已创建并指定正确的字符集
--
-- 3. 执行方式:
--    方式一 (推荐): 
--      mysql -h hostname -u username -p --default-character-set=utf8mb4 aiot_admin < init_data.sql
--    
--    方式二:
--      mysql> USE aiot_admin;
--      mysql> SOURCE /path/to/init_data.sql;
--
-- 4. 默认管理员账号信息:
--    用户名: admin
--    密码: Admin@123456
--    角色: platform_admin (平台管理员)
--    首次登录需修改密码: 是
--
-- 5. 安全提示:
--    ⚠️  请在首次登录后立即修改管理员密码！
--    ⚠️  建议在生产环境执行前修改默认密码！
--
-- ==========================================================================================================
-- 执行环境检查
-- ==========================================================================================================

-- 检查当前数据库
SELECT DATABASE() AS current_database;

-- 设置字符集
SET NAMES utf8mb4 COLLATE utf8mb4_unicode_ci;

-- 禁用外键检查（导入数据时提升性能）
SET FOREIGN_KEY_CHECKS = 0;

-- 开始事务（确保原子性）
START TRANSACTION;


-- ==========================================================================================================
-- 初始化数据
-- ==========================================================================================================

-- ----------------------------------------------------------------------------------------------------------
-- 1. 初始化平台管理员账号
-- ----------------------------------------------------------------------------------------------------------

-- 删除已存在的管理员账号（如果存在）
DELETE FROM `core_users` WHERE `username` = 'admin';

-- 插入平台管理员账号
-- 密码: Admin@123456
-- 密码哈希使用 bcrypt 算法 (cost=10)
-- 注意：这是 bcrypt 格式的密码哈希，对应明文密码 "Admin@123456"
INSERT INTO `core_users` (
    `username`,
    `nickname`,
    `email`,
    `phone`,
    `password_hash`,
    `role`,
    `is_active`,
    `need_change_password`,
    `created_at`,
    `updated_at`
) VALUES (
    'admin',                                                                    -- 用户名
    '平台管理员',                                                                  -- 昵称
    'admin@codehubot.com',                                                      -- 邮箱
    NULL,                                                                       -- 电话（可选）
    '$pbkdf2-sha256$29000$ec95L8WYU0qpdY7xXgtBaA$KwM5pek0WghVZDSeCCVkR.LrZU2PDOEvm5fgg7y0SjQ',           -- 密码哈希 (Admin@123456)
    'platform_admin',                                                           -- 角色：平台管理员
    1,                                                                          -- 是否激活：是
    1,                                                                          -- 首次登录需修改密码：是
    NOW(),                                                                      -- 创建时间
    NOW()                                                                       -- 更新时间
);

-- 获取插入的管理员用户ID
SET @admin_user_id = LAST_INSERT_ID();

-- 显示创建的管理员账号信息
SELECT 
    id,
    username,
    nickname,
    email,
    role,
    is_active,
    need_change_password,
    created_at
FROM `core_users` 
WHERE `username` = 'admin';


-- ----------------------------------------------------------------------------------------------------------
-- 2. 初始化系统默认配置（如需要可在此添加）
-- ----------------------------------------------------------------------------------------------------------

-- 示例：初始化默认的 LLM 提供商（可根据实际需求添加）
-- INSERT INTO `llm_providers` (...) VALUES (...);

-- 示例：初始化默认的知识库（可根据实际需求添加）
-- INSERT INTO `kb_main` (...) VALUES (...);


-- ==========================================================================================================
-- 执行后清理与验证
-- ==========================================================================================================

-- 重新启用外键检查
SET FOREIGN_KEY_CHECKS = 1;

-- 提交事务
COMMIT;

-- ==========================================================================================================
-- 数据验证
-- ==========================================================================================================

-- 验证管理员账号是否创建成功
SELECT 
    'Platform Administrator Account' AS info_type,
    COUNT(*) AS account_count
FROM `core_users` 
WHERE `role` = 'platform_admin' 
  AND `is_active` = 1;

-- 列出所有平台管理员账号
SELECT 
    id AS 'User ID',
    username AS 'Username',
    nickname AS 'Nickname',
    email AS 'Email',
    role AS 'Role',
    is_active AS 'Active',
    need_change_password AS 'Need Change Password',
    created_at AS 'Created At'
FROM `core_users` 
WHERE `role` = 'platform_admin'
ORDER BY id;

-- ==========================================================================================================
-- 执行完成信息
-- ==========================================================================================================

SELECT 
    '==========================================================================================================' AS ' ';

SELECT 
    'CodeHubot Initial Data Initialization Completed Successfully!' AS 'Status',
    DATABASE() AS 'Database Name',
    NOW() AS 'Completion Time';

SELECT 
    '==========================================================================================================' AS ' ';

SELECT 
    'Default Administrator Account Information:' AS 'Information';

SELECT 
    'Username: admin' AS 'Account Info 1';

SELECT 
    'Password: Admin@123456' AS 'Account Info 2';

SELECT 
    'Role: platform_admin (Platform Administrator)' AS 'Account Info 3';

SELECT 
    'Need Change Password: Yes (Must change on first login)' AS 'Account Info 4';

SELECT 
    '==========================================================================================================' AS ' ';

SELECT 
    '⚠️  SECURITY WARNING:' AS 'Security Notice';

SELECT 
    'Please change the default administrator password immediately after first login!' AS 'Warning 1';

SELECT 
    'It is recommended to modify the default password before deploying to production environment!' AS 'Warning 2';

SELECT 
    '==========================================================================================================' AS ' ';

-- ==========================================================================================================
-- 脚本结束
-- ==========================================================================================================
