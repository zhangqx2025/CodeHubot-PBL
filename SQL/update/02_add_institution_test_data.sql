-- ==========================================
-- CodeHubot-PBL 机构登录测试数据
-- ==========================================
-- 说明：
--   本脚本用于为 PBL 系统添加机构登录测试数据
--   包括测试学校、测试学生用户、测试教师用户
--
-- 使用方式：
--   mysql -u username -p aiot_admin < 02_add_institution_test_data.sql
--
-- 注意事项：
--   - 脚本使用 INSERT IGNORE 避免重复插入
--   - 密码为 123456，已使用 bcrypt 加密（$2b$12$...）
--   - school_code 必须大写
-- ==========================================

-- 1. 插入测试学校
INSERT IGNORE INTO `aiot_schools` (
    `uuid`,
    `school_code`,
    `school_name`,
    `province`,
    `city`,
    `district`,
    `address`,
    `contact_person`,
    `contact_phone`,
    `contact_email`,
    `is_active`,
    `license_expire_at`,
    `max_teachers`,
    `max_students`,
    `max_devices`,
    `created_at`,
    `updated_at`
) VALUES (
    UUID(),
    'DEMO_SCHOOL',
    '演示学校',
    '北京市',
    '北京市',
    '海淀区',
    '中关村大街1号',
    '张老师',
    '13800138000',
    'demo@school.com',
    1,
    '2026-12-31',
    100,
    1000,
    500,
    NOW(),
    NOW()
);

-- 获取学校ID（用于后续插入用户）
SET @school_id = (SELECT id FROM `aiot_schools` WHERE school_code = 'DEMO_SCHOOL');
SET @school_name = (SELECT school_name FROM `aiot_schools` WHERE school_code = 'DEMO_SCHOOL');

-- 2. 插入测试学生用户
-- 密码: 123456 (bcrypt hash)
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
    `student_number`,
    `is_active`,
    `need_change_password`,
    `created_at`,
    `updated_at`
) VALUES (
    'student_20240001',
    'student001@demo.com',
    '13800000001',
    '张三',
    '小张',
    '张三',
    'male',
    '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewY5NU7xnd6VUQre',
    'student',
    @school_id,
    @school_name,
    '20240001',
    1,
    0,
    NOW(),
    NOW()
);

-- 3. 插入测试教师用户
-- 密码: 123456 (bcrypt hash)
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
    `teacher_number`,
    `subject`,
    `is_active`,
    `need_change_password`,
    `created_at`,
    `updated_at`
) VALUES (
    'teacher_t001',
    'teacher001@demo.com',
    '13900000001',
    '李老师',
    '李老师',
    '李老师',
    'female',
    '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewY5NU7xnd6VUQre',
    'teacher',
    @school_id,
    @school_name,
    'T001',
    '信息技术',
    1,
    0,
    NOW(),
    NOW()
);

-- 4. 插入测试学校管理员用户
-- 密码: 123456 (bcrypt hash)
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
    `teacher_number`,
    `is_active`,
    `need_change_password`,
    `created_at`,
    `updated_at`
) VALUES (
    'school_admin_a001',
    'admin@demo.com',
    '13700000001',
    '王主任',
    '王主任',
    '王主任',
    'male',
    '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewY5NU7xnd6VUQre',
    'school_admin',
    @school_id,
    @school_name,
    'A001',
    1,
    0,
    NOW(),
    NOW()
);

-- ==========================================
-- 测试账号信息
-- ==========================================
-- 
-- 学校代码: DEMO_SCHOOL
--
-- 学生账号:
--   学号: 20240001
--   密码: 123456
--   格式: 20240001@DEMO_SCHOOL
--
-- 教师账号:
--   工号: T001
--   密码: 123456
--   格式: T001@DEMO_SCHOOL
--
-- 学校管理员账号:
--   工号: A001
--   密码: 123456
--   格式: A001@DEMO_SCHOOL
--
-- ==========================================
