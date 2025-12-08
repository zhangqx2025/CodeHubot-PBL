-- ==========================================
-- 添加平台管理员测试账号
-- ==========================================
-- 说明：
--   本脚本用于添加平台管理员测试账号
--   平台管理员不归属于任何学校，使用用户名+密码登录
--
-- 使用方式：
--   mysql -u username -p aiot_admin < 04_add_platform_admin.sql
--
-- 注意事项：
--   - 使用 INSERT IGNORE 避免重复插入
--   - 密码为 admin123，已使用 bcrypt 加密
--   - 平台管理员的 school_id 为 NULL
-- ==========================================

-- 插入平台管理员账号
-- 用户名: admin
-- 密码: admin123 (bcrypt hash)
INSERT IGNORE INTO `aiot_core_users` (
    `username`,
    `email`,
    `phone`,
    `real_name`,
    `nickname`,
    `name`,
    `gender`,
    `password_hash`,
    `role`,
    `school_id`,
    `school_name`,
    `is_active`,
    `need_change_password`,
    `created_at`,
    `updated_at`
) VALUES (
    'admin',
    'admin@codehubot.com',
    '13800000000',
    '系统管理员',
    '管理员',
    '系统管理员',
    'male',
    '$2b$12$hFzyUt3C.vmS81iRSlq50.ljh64N6MI04/fyylWRExYSlnfYWbBSi',
    'platform_admin',
    NULL,
    NULL,
    1,
    0,
    NOW(),
    NOW()
);

-- ==========================================
-- 测试账号信息
-- ==========================================
-- 
-- 平台管理员账号:
--   用户名: admin
--   密码: admin123
--   登录接口: POST /api/v1/admin/auth/platform-login
--   请求体: {"username": "admin", "password": "admin123"}
--
-- ==========================================
