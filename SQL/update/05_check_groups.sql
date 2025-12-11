-- ==========================================================================================================
-- 检查 pbl_groups 表的数据问题
-- ==========================================================================================================
-- 
-- 脚本名称: 05_check_groups.sql
-- 创建日期: 2024-12-11
-- 用途: 在执行 05 脚本前检查 pbl_groups 表的 course_id NULL 值
--
-- ==========================================================================================================

SET NAMES utf8mb4 COLLATE utf8mb4_unicode_ci;

-- ==========================================================================================================
-- 检查1：pbl_groups.course_id 的 NULL 值
-- ==========================================================================================================

SELECT 
    '检查 pbl_groups.course_id' AS check_item,
    COUNT(*) AS total_groups,
    SUM(CASE WHEN course_id IS NULL THEN 1 ELSE 0 END) AS null_count,
    SUM(CASE WHEN course_id IS NOT NULL THEN 1 ELSE 0 END) AS valid_count
FROM pbl_groups;

-- 如果有 NULL 值，显示详情
SELECT 
    '有 NULL 值的小组' AS info,
    id, uuid, name, class_id, course_id, leader_id, is_active, created_at
FROM pbl_groups 
WHERE course_id IS NULL;

-- ==========================================================================================================
-- 检查2：查看外键约束
-- ==========================================================================================================

SELECT 
    'pbl_groups 外键约束' AS info,
    CONSTRAINT_NAME,
    COLUMN_NAME,
    REFERENCED_TABLE_NAME,
    REFERENCED_COLUMN_NAME,
    (SELECT DELETE_RULE FROM information_schema.REFERENTIAL_CONSTRAINTS 
     WHERE CONSTRAINT_SCHEMA = DATABASE() 
       AND CONSTRAINT_NAME = tc.CONSTRAINT_NAME
       AND TABLE_NAME = 'pbl_groups') AS DELETE_RULE,
    (SELECT UPDATE_RULE FROM information_schema.REFERENTIAL_CONSTRAINTS 
     WHERE CONSTRAINT_SCHEMA = DATABASE() 
       AND CONSTRAINT_NAME = tc.CONSTRAINT_NAME
       AND TABLE_NAME = 'pbl_groups') AS UPDATE_RULE
FROM information_schema.TABLE_CONSTRAINTS tc
INNER JOIN information_schema.KEY_COLUMN_USAGE kcu 
    ON tc.CONSTRAINT_NAME = kcu.CONSTRAINT_NAME
    AND tc.TABLE_SCHEMA = kcu.TABLE_SCHEMA
WHERE tc.TABLE_SCHEMA = DATABASE()
  AND tc.TABLE_NAME = 'pbl_groups'
  AND tc.CONSTRAINT_TYPE = 'FOREIGN KEY';

-- ==========================================================================================================
-- 检查3：是否有小组成员数据
-- ==========================================================================================================

SELECT 
    '检查小组成员数据' AS info,
    g.id AS group_id,
    g.name AS group_name,
    g.course_id,
    COUNT(gm.id) AS member_count
FROM pbl_groups g
LEFT JOIN pbl_group_members gm ON gm.group_id = g.id
WHERE g.course_id IS NULL
GROUP BY g.id, g.name, g.course_id;

-- ==========================================================================================================
-- 修复建议
-- ==========================================================================================================

/*
根据检查结果，选择合适的修复方案：

方案A：如果 NULL 的小组没有成员，可以直接删除
DELETE FROM pbl_groups WHERE course_id IS NULL;

方案B：如果需要保留这些小组，需要为它们关联一个课程
-- 查看可用的课程
SELECT id, title, school_id, status FROM pbl_courses WHERE status = 'published' LIMIT 10;

-- 手动设置 course_id（将 999 替换为实际的课程ID）
UPDATE pbl_groups 
SET course_id = 999 
WHERE course_id IS NULL;

方案C：基于 class_id 自动关联课程（如果课程表中有 class_id 字段）
-- 注意：此方案需要先执行 05 脚本的前面部分，课程表已添加 class_id 字段
UPDATE pbl_groups g
INNER JOIN pbl_courses c ON c.class_id = g.class_id
SET g.course_id = c.id
WHERE g.course_id IS NULL 
  AND g.class_id IS NOT NULL;
*/

-- ==========================================================================================================
-- 脚本结束
-- ==========================================================================================================
