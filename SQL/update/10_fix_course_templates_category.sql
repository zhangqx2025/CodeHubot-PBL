-- ==========================================================================================================
-- 修复课程模板表字段 - 添加 category 字段
-- ==========================================================================================================
-- 
-- 脚本名称: 10_fix_course_templates_category.sql
-- 脚本版本: 1.0.0
-- 创建日期: 2025-12-11
-- 兼容版本: MySQL 5.7.x, 8.0.x
-- 字符集: utf8mb4
-- 排序规则: utf8mb4_unicode_ci
--
-- 问题描述:
-- 1. 数据库创建脚本中使用 category_id (INT) 关联到分类表
-- 2. 但代码模型中使用 category (VARCHAR) 作为简单的分类字符串
-- 3. 导致查询时出现 "Unknown column 'pbl_course_templates.category'" 错误
--
-- 解决方案:
-- 1. 添加 category (VARCHAR) 字段用于简单的分类标识
-- 2. 保留 category_id 字段以供未来可能的扩展使用
-- 3. 如果 category_id 有值，则将对应的分类 code 迁移到 category 字段
--
-- ==========================================================================================================

SET SQL_MODE = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION';
SET NAMES utf8mb4 COLLATE utf8mb4_unicode_ci;

-- ==========================================================================================================
-- 1. 添加 category 字段（如果不存在）
-- ==========================================================================================================

-- 创建临时存储过程来安全地添加字段（兼容MySQL 5.7）
DROP PROCEDURE IF EXISTS add_column_if_not_exists;

DELIMITER $$
CREATE PROCEDURE add_column_if_not_exists(
    IN tableName VARCHAR(128),
    IN columnName VARCHAR(128),
    IN columnDefinition TEXT
)
BEGIN
    DECLARE column_count INT;
    
    SELECT COUNT(*) INTO column_count
    FROM information_schema.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = tableName
      AND COLUMN_NAME = columnName;
    
    IF column_count = 0 THEN
        SET @sql = CONCAT('ALTER TABLE `', tableName, '` ADD COLUMN `', columnName, '` ', columnDefinition);
        PREPARE stmt FROM @sql;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;
        SELECT CONCAT('✓ 已添加字段: ', tableName, '.', columnName) AS 'Result';
    ELSE
        SELECT CONCAT('○ 字段已存在: ', tableName, '.', columnName) AS 'Result';
    END IF;
END$$
DELIMITER ;

-- 在 category_id 字段之后添加 category 字段
CALL add_column_if_not_exists('pbl_course_templates', 'category', 
    'VARCHAR(50) DEFAULT NULL COMMENT \'课程分类（如：人工智能、编程、设计等）\' AFTER `category_id`');

-- 清理临时存储过程
DROP PROCEDURE IF EXISTS add_column_if_not_exists;

-- ==========================================================================================================
-- 2. 数据迁移：如果有 category_id，则从分类表获取 code 填充到 category
-- ==========================================================================================================

-- 检查是否存在分类表以及是否有数据需要迁移
SELECT CASE 
    WHEN EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_schema = DATABASE() 
          AND table_name = 'pbl_template_categories'
    )
    THEN '✓ pbl_template_categories 表存在，可以进行数据迁移'
    ELSE '○ pbl_template_categories 表不存在，跳过数据迁移'
END AS '迁移检查';

-- 如果分类表存在，且有关联数据，则执行迁移
-- 注意：这里使用动态SQL来避免表不存在时的错误
SET @migration_sql = (
    SELECT IF(
        EXISTS (
            SELECT 1 FROM information_schema.tables 
            WHERE table_schema = DATABASE() 
              AND table_name = 'pbl_template_categories'
        ),
        CONCAT('UPDATE pbl_course_templates t ',
               'INNER JOIN pbl_template_categories c ON t.category_id = c.id ',
               'SET t.category = c.code ',
               'WHERE t.category_id IS NOT NULL AND (t.category IS NULL OR t.category = \'\')'),
        'SELECT "跳过数据迁移：分类表不存在" AS Result'
    )
);

PREPARE stmt FROM @migration_sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- ==========================================================================================================
-- 3. 添加索引（如果不存在）
-- ==========================================================================================================

SET @index_exists = (
    SELECT COUNT(*) FROM information_schema.STATISTICS 
    WHERE TABLE_SCHEMA = DATABASE() 
      AND TABLE_NAME = 'pbl_course_templates' 
      AND INDEX_NAME = 'idx_category'
);

SET @sql = IF(@index_exists = 0,
    'ALTER TABLE `pbl_course_templates` ADD KEY `idx_category` (`category`)',
    'SELECT "○ 索引 idx_category 已存在" AS Result');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- ==========================================================================================================
-- 4. 验证修复结果
-- ==========================================================================================================

SELECT '==========================================================================================================' AS ' ';
SELECT 'Field Verification' AS '验证结果';
SELECT '==========================================================================================================' AS ' ';

-- 验证字段是否存在
SELECT 
    table_name AS '表名',
    column_name AS '字段名',
    column_type AS '数据类型',
    is_nullable AS '允许NULL',
    column_comment AS '注释'
FROM information_schema.columns
WHERE table_schema = DATABASE()
  AND table_name = 'pbl_course_templates'
  AND column_name IN ('category_id', 'category')
ORDER BY ordinal_position;

-- 验证索引是否存在
SELECT 
    index_name AS '索引名',
    column_name AS '字段名',
    seq_in_index AS '顺序',
    index_type AS '索引类型'
FROM information_schema.statistics
WHERE table_schema = DATABASE()
  AND table_name = 'pbl_course_templates'
  AND index_name IN ('idx_category_id', 'idx_category')
ORDER BY index_name, seq_in_index;

SELECT '==========================================================================================================' AS ' ';
SELECT 'Fix Completed!' AS '修复完成';
SELECT '==========================================================================================================' AS ' ';

-- 显示修复说明
SELECT '字段说明:' AS ' ';
SELECT '1. category_id: INT类型，用于关联到 pbl_template_categories 表（可选功能）' AS 'Field 1';
SELECT '2. category: VARCHAR类型，用于简单的分类标识（当前代码使用）' AS 'Field 2';
SELECT '' AS ' ';
SELECT '建议:' AS ' ';
SELECT '- 当前代码使用 category 字段，可以直接存储分类名称（如：人工智能、编程等）' AS 'Suggestion 1';
SELECT '- category_id 字段保留，未来如需复杂分类管理可启用' AS 'Suggestion 2';
SELECT '- 两个字段可以同时使用，互不冲突' AS 'Suggestion 3';

SELECT '==========================================================================================================' AS ' ';

-- ==========================================================================================================
-- 脚本结束
-- ==========================================================================================================
