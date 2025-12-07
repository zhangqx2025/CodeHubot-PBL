-- ==========================================
-- 修复测试用户密码哈希
-- ==========================================
-- 说明：
--   本脚本用于修复测试用户的密码哈希
--   旧的密码哈希不正确，导致无法登录
--   新的密码哈希使用 bcrypt 生成，密码为: 123456
--
-- 使用方式：
--   mysql -u username -p aiot_admin < 03_fix_test_user_passwords.sql
--
-- 注意事项：
--   - 仅更新测试账号的密码
--   - 新密码哈希: $2b$12$O8lVakoEEhNZxLwJu7PIo.2kQ87zX4awBUn7Nt.NTGfFQ99Dby1fS
--   - 对应明文密码: 123456
-- ==========================================

-- 更新学生用户密码
UPDATE `aiot_core_users`
SET 
    `password_hash` = '$2b$12$O8lVakoEEhNZxLwJu7PIo.2kQ87zX4awBUn7Nt.NTGfFQ99Dby1fS',
    `updated_at` = NOW()
WHERE 
    `username` = 'student_20240001' 
    AND `role` = 'student';

-- 更新教师用户密码
UPDATE `aiot_core_users`
SET 
    `password_hash` = '$2b$12$O8lVakoEEhNZxLwJu7PIo.2kQ87zX4awBUn7Nt.NTGfFQ99Dby1fS',
    `updated_at` = NOW()
WHERE 
    `username` = 'teacher_t001' 
    AND `role` = 'teacher';

-- 更新学校管理员用户密码
UPDATE `aiot_core_users`
SET 
    `password_hash` = '$2b$12$O8lVakoEEhNZxLwJu7PIo.2kQ87zX4awBUn7Nt.NTGfFQ99Dby1fS',
    `updated_at` = NOW()
WHERE 
    `username` = 'school_admin_a001' 
    AND `role` = 'school_admin';

-- 验证更新结果
SELECT 
    id,
    username,
    role,
    student_number,
    teacher_number,
    school_name,
    LEFT(password_hash, 30) AS password_hash_preview,
    is_active,
    updated_at
FROM 
    `aiot_core_users`
WHERE 
    username IN ('student_20240001', 'teacher_t001', 'school_admin_a001')
ORDER BY 
    role, username;

-- ==========================================
-- 更新完成说明
-- ==========================================
-- 
-- 测试账号信息（密码已更新为正确的哈希）:
--
-- 学校代码: DEMO_SCHOOL
--
-- 学生账号:
--   学号: 20240001
--   密码: 123456
--   登录格式: 学校代码 + 学号 + 密码
--
-- 教师账号:
--   工号: T001
--   密码: 123456
--   登录格式: 学校代码 + 工号 + 密码
--
-- 学校管理员账号:
--   工号: A001
--   密码: 123456
--   登录格式: 学校代码 + 工号 + 密码
--
-- ==========================================
