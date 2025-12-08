-- ==========================================
-- 插入测试学生用户
-- ==========================================
--
-- 说明：
--   本脚本用于插入测试学生用户数据，用于开发和测试
--
-- 使用方式：
--   1. 确保已执行 init_database.sql 初始化数据库
--   2. 选择数据库：USE aiot_admin;
--   3. 执行本脚本：source /path/to/01_insert_test_student.sql;
--
-- 测试账号信息：
--   用户名: 20240001@DEMO_SCHOOL
--   学号: 20240001
--   学校代码: DEMO_SCHOOL
--   密码: 123456
--   角色: student (学生)
--
-- ==========================================

-- 检查是否已存在该测试用户，如果存在则删除
DELETE FROM aiot_core_users WHERE username = '20240001@DEMO_SCHOOL';

-- 插入测试学生用户
INSERT INTO aiot_core_users (
    username,
    email,
    phone,
    nickname,
    name,
    real_name,
    gender,
    password_hash,
    role,
    school_id,
    school_name,
    student_number,
    is_active,
    need_change_password,
    created_at,
    updated_at
) VALUES (
    '20240001@DEMO_SCHOOL',                                                                     -- username: 学号@学校代码格式
    'student001@demo.school',                                                                   -- email: 测试邮箱
    '13800138001',                                                                              -- phone: 测试手机号
    '张三',                                                                                      -- nickname: 昵称
    '张三',                                                                                      -- name: 姓名
    '张三',                                                                                      -- real_name: 真实姓名
    'male',                                                                                      -- gender: 性别
    '$pbkdf2-sha256$29000$5dw7J.Q8x7g3RgiBsFaqtQ$DheJmsxtRJstanFt1ht8qrCIpD5YeEOKnmEZt6INPLU', -- password_hash: 密码123456的哈希
    'student',                                                                                   -- role: 学生角色
    1,                                                                                           -- school_id: 学校ID（演示学校）
    '演示学校',                                                                                  -- school_name: 学校名称
    '20240001',                                                                                  -- student_number: 学号
    1,                                                                                           -- is_active: 激活状态
    0,                                                                                           -- need_change_password: 不需要修改密码
    NOW(),                                                                                       -- created_at: 创建时间
    NOW()                                                                                        -- updated_at: 更新时间
);

-- 插入更多测试学生（可选）
INSERT INTO aiot_core_users (
    username,
    email,
    nickname,
    name,
    real_name,
    gender,
    password_hash,
    role,
    school_id,
    school_name,
    student_number,
    is_active,
    need_change_password,
    created_at,
    updated_at
) VALUES 
(
    '20240002@DEMO_SCHOOL',
    'student002@demo.school',
    '李四',
    '李四',
    '李四',
    'female',
    '$pbkdf2-sha256$29000$5dw7J.Q8x7g3RgiBsFaqtQ$DheJmsxtRJstanFt1ht8qrCIpD5YeEOKnmEZt6INPLU',
    'student',
    1,
    '演示学校',
    '20240002',
    1,
    0,
    NOW(),
    NOW()
),
(
    '20240003@DEMO_SCHOOL',
    'student003@demo.school',
    '王五',
    '王五',
    '王五',
    'male',
    '$pbkdf2-sha256$29000$5dw7J.Q8x7g3RgiBsFaqtQ$DheJmsxtRJstanFt1ht8qrCIpD5YeEOKnmEZt6INPLU',
    'student',
    1,
    '演示学校',
    '20240003',
    1,
    0,
    NOW(),
    NOW()
);

-- 验证插入结果
SELECT 
    id,
    username,
    name,
    role,
    school_name,
    student_number,
    is_active,
    created_at
FROM aiot_core_users 
WHERE username LIKE '%@DEMO_SCHOOL'
ORDER BY id;

-- 提示信息
SELECT '测试学生用户插入完成！' AS message;
SELECT '登录信息：用户名=20240001@DEMO_SCHOOL, 密码=123456' AS login_info;

