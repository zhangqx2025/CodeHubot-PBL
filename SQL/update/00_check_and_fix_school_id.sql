-- ==========================================================================================================
-- 检查并修复 pbl_courses 表的 school_id 字段
-- ==========================================================================================================
-- 
-- 脚本名称: 00_check_and_fix_school_id.sql
-- 创建日期: 2024-12-11
-- 兼容版本: MySQL 5.7.x, 8.0.x
--
-- 功能说明：
-- 在执行 05_club_class_system.sql 之前，先执行此脚本
-- 用于检查和修复 pbl_courses 表中 school_id 为 NULL 的记录
--
-- ==========================================================================================================

SET NAMES utf8mb4 COLLATE utf8mb4_unicode_ci;

-- ==========================================================================================================
-- 步骤1: 检查当前状态
-- ==========================================================================================================

-- 1.1 检查 school_id 为 NULL 的课程数量
SELECT 
    '检查 school_id 为 NULL 的课程' AS check_item,
    COUNT(*) AS null_count
FROM pbl_courses 
WHERE school_id IS NULL;

-- 1.2 查看所有 school_id 为 NULL 的课程详情
SELECT 
    id,
    uuid,
    title,
    school_id,
    creator_id,
    status,
    created_at
FROM pbl_courses 
WHERE school_id IS NULL
ORDER BY id;

-- 1.3 检查是否有对应的创建者所属学校
SELECT 
    c.id AS course_id,
    c.title AS course_title,
    c.school_id AS current_school_id,
    c.creator_id,
    u.username AS creator_username,
    u.school_id AS creator_school_id
FROM pbl_courses c
LEFT JOIN core_users u ON u.id = c.creator_id
WHERE c.school_id IS NULL;

-- ==========================================================================================================
-- 步骤2: 修复方案（根据实际情况选择其一执行）
-- ==========================================================================================================

-- 方案A：根据创建者的 school_id 修复（推荐）
-- 如果创建者有 school_id，则使用创建者的 school_id
/*
UPDATE pbl_courses c
INNER JOIN core_users u ON u.id = c.creator_id
SET c.school_id = u.school_id
WHERE c.school_id IS NULL 
  AND u.school_id IS NOT NULL;
*/

-- 方案B：设置为默认学校ID（如果所有课程都属于同一学校）
-- 请将 1 替换为实际的默认学校ID
/*
UPDATE pbl_courses 
SET school_id = 1
WHERE school_id IS NULL;
*/

-- 方案C：设置为0（表示未分配学校，后续手动处理）
/*
UPDATE pbl_courses 
SET school_id = 0
WHERE school_id IS NULL;
*/

-- ==========================================================================================================
-- 步骤3: 验证修复结果
-- ==========================================================================================================

-- 3.1 再次检查是否还有 NULL 值
SELECT 
    '修复后检查' AS check_item,
    COUNT(*) AS null_count
FROM pbl_courses 
WHERE school_id IS NULL;

-- 3.2 查看修复后的数据分布
SELECT 
    school_id,
    COUNT(*) AS course_count
FROM pbl_courses
GROUP BY school_id
ORDER BY school_id;

-- ==========================================================================================================
-- 步骤4: 手动执行建议
-- ==========================================================================================================

/*
执行顺序：

1. 先执行"步骤1"的检查SQL，了解当前数据状态
2. 根据检查结果，选择合适的修复方案（方案A/B/C）
3. 取消对应方案的注释，执行UPDATE语句
4. 执行"步骤3"的验证SQL，确认修复成功
5. 确认 school_id 无 NULL 值后，再执行 05_club_class_system.sql

注意事项：
- 方案A最安全，会根据创建者的学校自动设置
- 方案B适用于所有课程都属于同一学校的情况
- 方案C是临时方案，需要后续手动处理
- 修复前建议先备份数据
*/

-- ==========================================================================================================
-- 脚本结束
-- ==========================================================================================================
