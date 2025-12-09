-- ==========================================
-- 为现有记录生成UUID（如果缺失）
-- ==========================================
-- 
-- 说明：此脚本用于为所有PBL表中缺少UUID的记录生成UUID
-- 支持 MySQL 5.7-8.0
-- 
-- 执行前请备份数据库！
-- ==========================================

-- 1. 为 pbl_courses 表生成UUID
UPDATE pbl_courses 
SET uuid = UUID() 
WHERE uuid IS NULL OR uuid = '';

-- 2. 为 pbl_units 表生成UUID
UPDATE pbl_units 
SET uuid = UUID() 
WHERE uuid IS NULL OR uuid = '';

-- 3. 为 pbl_resources 表生成UUID
UPDATE pbl_resources 
SET uuid = UUID() 
WHERE uuid IS NULL OR uuid = '';

-- 4. 为 pbl_tasks 表生成UUID
UPDATE pbl_tasks 
SET uuid = UUID() 
WHERE uuid IS NULL OR uuid = '';

-- 5. 为 pbl_projects 表生成UUID
UPDATE pbl_projects 
SET uuid = UUID() 
WHERE uuid IS NULL OR uuid = '';

-- 6. 为 pbl_ai_conversations 表生成UUID
UPDATE pbl_ai_conversations 
SET uuid = UUID() 
WHERE uuid IS NULL OR uuid = '';

-- 7. 为 pbl_achievements 表生成UUID
UPDATE pbl_achievements 
SET uuid = UUID() 
WHERE uuid IS NULL OR uuid = '';

-- 8. 为 pbl_classes 表生成UUID（如果表存在）
UPDATE pbl_classes 
SET uuid = UUID() 
WHERE uuid IS NULL OR uuid = '';

-- 9. 为 pbl_groups 表生成UUID（如果表存在）
UPDATE pbl_groups 
SET uuid = UUID() 
WHERE uuid IS NULL OR uuid = '';

-- 10. 确保所有UUID字段都有唯一索引（如果还没有的话）
-- MySQL 不支持 ALTER TABLE ADD UNIQUE KEY IF NOT EXISTS 语法
-- 使用准备语句来安全地创建唯一索引

-- pbl_courses
SET @index_exists = (
    SELECT COUNT(*) 
    FROM information_schema.statistics 
    WHERE table_schema = DATABASE() 
    AND table_name = 'pbl_courses' 
    AND index_name = 'uk_uuid'
);

SET @sql = IF(
    @index_exists = 0,
    'ALTER TABLE pbl_courses ADD UNIQUE KEY uk_uuid (uuid)',
    'SELECT ''Index uk_uuid already exists on pbl_courses'' AS message'
);

PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- pbl_units
SET @index_exists = (
    SELECT COUNT(*) 
    FROM information_schema.statistics 
    WHERE table_schema = DATABASE() 
    AND table_name = 'pbl_units' 
    AND index_name = 'uk_uuid'
);

SET @sql = IF(
    @index_exists = 0,
    'ALTER TABLE pbl_units ADD UNIQUE KEY uk_uuid (uuid)',
    'SELECT ''Index uk_uuid already exists on pbl_units'' AS message'
);

PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- pbl_resources
SET @index_exists = (
    SELECT COUNT(*) 
    FROM information_schema.statistics 
    WHERE table_schema = DATABASE() 
    AND table_name = 'pbl_resources' 
    AND index_name = 'uk_uuid'
);

SET @sql = IF(
    @index_exists = 0,
    'ALTER TABLE pbl_resources ADD UNIQUE KEY uk_uuid (uuid)',
    'SELECT ''Index uk_uuid already exists on pbl_resources'' AS message'
);

PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- pbl_tasks
SET @index_exists = (
    SELECT COUNT(*) 
    FROM information_schema.statistics 
    WHERE table_schema = DATABASE() 
    AND table_name = 'pbl_tasks' 
    AND index_name = 'uk_uuid'
);

SET @sql = IF(
    @index_exists = 0,
    'ALTER TABLE pbl_tasks ADD UNIQUE KEY uk_uuid (uuid)',
    'SELECT ''Index uk_uuid already exists on pbl_tasks'' AS message'
);

PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- pbl_projects
SET @index_exists = (
    SELECT COUNT(*) 
    FROM information_schema.statistics 
    WHERE table_schema = DATABASE() 
    AND table_name = 'pbl_projects' 
    AND index_name = 'uk_uuid'
);

SET @sql = IF(
    @index_exists = 0,
    'ALTER TABLE pbl_projects ADD UNIQUE KEY uk_uuid (uuid)',
    'SELECT ''Index uk_uuid already exists on pbl_projects'' AS message'
);

PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- pbl_ai_conversations
SET @index_exists = (
    SELECT COUNT(*) 
    FROM information_schema.statistics 
    WHERE table_schema = DATABASE() 
    AND table_name = 'pbl_ai_conversations' 
    AND index_name = 'uk_uuid'
);

SET @sql = IF(
    @index_exists = 0,
    'ALTER TABLE pbl_ai_conversations ADD UNIQUE KEY uk_uuid (uuid)',
    'SELECT ''Index uk_uuid already exists on pbl_ai_conversations'' AS message'
);

PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- pbl_achievements
SET @index_exists = (
    SELECT COUNT(*) 
    FROM information_schema.statistics 
    WHERE table_schema = DATABASE() 
    AND table_name = 'pbl_achievements' 
    AND index_name = 'uk_uuid'
);

SET @sql = IF(
    @index_exists = 0,
    'ALTER TABLE pbl_achievements ADD UNIQUE KEY uk_uuid (uuid)',
    'SELECT ''Index uk_uuid already exists on pbl_achievements'' AS message'
);

PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- pbl_classes
SET @index_exists = (
    SELECT COUNT(*) 
    FROM information_schema.statistics 
    WHERE table_schema = DATABASE() 
    AND table_name = 'pbl_classes' 
    AND index_name = 'uk_uuid'
);

SET @sql = IF(
    @index_exists = 0,
    'ALTER TABLE pbl_classes ADD UNIQUE KEY uk_uuid (uuid)',
    'SELECT ''Index uk_uuid already exists on pbl_classes'' AS message'
);

PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- pbl_groups
SET @index_exists = (
    SELECT COUNT(*) 
    FROM information_schema.statistics 
    WHERE table_schema = DATABASE() 
    AND table_name = 'pbl_groups' 
    AND index_name = 'uk_uuid'
);

SET @sql = IF(
    @index_exists = 0,
    'ALTER TABLE pbl_groups ADD UNIQUE KEY uk_uuid (uuid)',
    'SELECT ''Index uk_uuid already exists on pbl_groups'' AS message'
);

PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 验证UUID生成情况
SELECT 'pbl_courses' as table_name, COUNT(*) as total_records, 
       SUM(CASE WHEN uuid IS NULL OR uuid = '' THEN 1 ELSE 0 END) as missing_uuid
FROM pbl_courses
UNION ALL
SELECT 'pbl_units', COUNT(*), SUM(CASE WHEN uuid IS NULL OR uuid = '' THEN 1 ELSE 0 END)
FROM pbl_units
UNION ALL
SELECT 'pbl_resources', COUNT(*), SUM(CASE WHEN uuid IS NULL OR uuid = '' THEN 1 ELSE 0 END)
FROM pbl_resources
UNION ALL
SELECT 'pbl_tasks', COUNT(*), SUM(CASE WHEN uuid IS NULL OR uuid = '' THEN 1 ELSE 0 END)
FROM pbl_tasks
UNION ALL
SELECT 'pbl_projects', COUNT(*), SUM(CASE WHEN uuid IS NULL OR uuid = '' THEN 1 ELSE 0 END)
FROM pbl_projects
UNION ALL
SELECT 'pbl_classes', COUNT(*), SUM(CASE WHEN uuid IS NULL OR uuid = '' THEN 1 ELSE 0 END)
FROM pbl_classes
UNION ALL
SELECT 'pbl_groups', COUNT(*), SUM(CASE WHEN uuid IS NULL OR uuid = '' THEN 1 ELSE 0 END)
FROM pbl_groups;

COMMIT;
