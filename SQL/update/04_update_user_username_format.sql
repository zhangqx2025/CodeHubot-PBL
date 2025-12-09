-- ============================================
-- 用户名格式变更说明
-- ============================================
-- 更新时间: 2025-12-09
-- 更新内容: 用户名自动生成规则变更
--
-- 变更说明：
-- 1. 创建学校用户（管理员、教师、学生）时，不再需要手动输入用户名
-- 2. 用户名将自动生成为：学号/职工号 + @ + 学校编码
-- 3. 职工号或学号变为必填字段
--
-- 新规则：
-- - 教师/学校管理员：用户名 = teacher_number@school_code
-- - 学生：用户名 = student_number@school_code
--
-- 示例：
-- - 学校编码：BJ-YCZX
-- - 教师工号：T001 -> 用户名：T001@BJ-YCZX
-- - 学生学号：20240101 -> 用户名：20240101@BJ-YCZX
-- ============================================

-- 注意：此更新仅影响新创建的用户
-- 已存在的用户数据不受影响，可以继续正常使用
-- 如需更新现有用户的用户名格式，请根据实际情况谨慎操作

-- ============================================
-- 可选：批量更新现有用户的用户名格式
-- ============================================
-- 警告：执行此操作前请务必备份数据库！
-- 此操作会修改所有现有用户的用户名

-- 步骤1：检查哪些用户需要更新
-- 查看教师和学校管理员
SELECT 
    u.id,
    u.username AS old_username,
    CONCAT(u.teacher_number, '@', s.school_code) AS new_username,
    u.role,
    u.teacher_number,
    s.school_code,
    s.school_name
FROM core_users u
INNER JOIN core_schools s ON u.school_id = s.id
WHERE u.role IN ('teacher', 'school_admin')
    AND u.teacher_number IS NOT NULL
    AND u.teacher_number != ''
    AND u.username NOT LIKE CONCAT('%@', s.school_code);

-- 查看学生
SELECT 
    u.id,
    u.username AS old_username,
    CONCAT(u.student_number, '@', s.school_code) AS new_username,
    u.role,
    u.student_number,
    s.school_code,
    s.school_name
FROM core_users u
INNER JOIN core_schools s ON u.school_id = s.id
WHERE u.role = 'student'
    AND u.student_number IS NOT NULL
    AND u.student_number != ''
    AND u.username NOT LIKE CONCAT('%@', s.school_code);

-- 步骤2：执行更新（请谨慎操作，务必先备份！）
-- 更新教师和学校管理员的用户名
/*
UPDATE core_users u
INNER JOIN core_schools s ON u.school_id = s.id
SET u.username = CONCAT(u.teacher_number, '@', s.school_code)
WHERE u.role IN ('teacher', 'school_admin')
    AND u.teacher_number IS NOT NULL
    AND u.teacher_number != ''
    AND u.username NOT LIKE CONCAT('%@', s.school_code);
*/

-- 更新学生的用户名
/*
UPDATE core_users u
INNER JOIN core_schools s ON u.school_id = s.id
SET u.username = CONCAT(u.student_number, '@', s.school_code)
WHERE u.role = 'student'
    AND u.student_number IS NOT NULL
    AND u.student_number != ''
    AND u.username NOT LIKE CONCAT('%@', s.school_code);
*/

-- 步骤3：验证更新结果
-- 检查是否还有不符合新格式的用户
/*
SELECT 
    u.id,
    u.username,
    u.role,
    u.teacher_number,
    u.student_number,
    s.school_code,
    s.school_name
FROM core_users u
INNER JOIN core_schools s ON u.school_id = s.id
WHERE u.role IN ('teacher', 'school_admin', 'student')
    AND (
        (u.role IN ('teacher', 'school_admin') AND u.teacher_number IS NOT NULL AND u.username NOT LIKE CONCAT('%@', s.school_code))
        OR
        (u.role = 'student' AND u.student_number IS NOT NULL AND u.username NOT LIKE CONCAT('%@', s.school_code))
    );
*/
