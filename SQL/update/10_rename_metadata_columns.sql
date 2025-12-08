-- ==========================================
-- 修复 metadata 列名冲突问题
-- ==========================================
-- 说明：
--   在 SQLAlchemy 的 Declarative API 中，metadata 是保留属性名，
--   需要将相关表的 metadata 列重命名为 meta_data
--
-- 使用方式：
--   mysql -u username -p database_name < 10_rename_metadata_columns.sql
--
-- 版本：v1.0
-- 日期：2024-12-08
-- ==========================================

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- 检查并重命名 pbl_project_outputs 表的 metadata 列
SET @table_exists = (
    SELECT COUNT(*)
    FROM information_schema.TABLES 
    WHERE TABLE_SCHEMA = DATABASE() 
    AND TABLE_NAME = 'pbl_project_outputs'
);

SET @column_exists = (
    SELECT COUNT(*)
    FROM information_schema.COLUMNS 
    WHERE TABLE_SCHEMA = DATABASE() 
    AND TABLE_NAME = 'pbl_project_outputs'
    AND COLUMN_NAME = 'metadata'
);

SET @sql = IF(@table_exists > 0 AND @column_exists > 0,
    'ALTER TABLE `pbl_project_outputs` CHANGE COLUMN `metadata` `meta_data` json DEFAULT NULL COMMENT ''扩展元数据（如：技术栈、工具等）'';',
    'SELECT ''Table pbl_project_outputs does not exist or metadata column already renamed'' AS message;'
);

PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 检查并重命名 pbl_learning_progress 表的 metadata 列
SET @table_exists = (
    SELECT COUNT(*)
    FROM information_schema.TABLES 
    WHERE TABLE_SCHEMA = DATABASE() 
    AND TABLE_NAME = 'pbl_learning_progress'
);

SET @column_exists = (
    SELECT COUNT(*)
    FROM information_schema.COLUMNS 
    WHERE TABLE_SCHEMA = DATABASE() 
    AND TABLE_NAME = 'pbl_learning_progress'
    AND COLUMN_NAME = 'metadata'
);

SET @sql = IF(@table_exists > 0 AND @column_exists > 0,
    'ALTER TABLE `pbl_learning_progress` CHANGE COLUMN `metadata` `meta_data` json DEFAULT NULL COMMENT ''扩展元数据'';',
    'SELECT ''Table pbl_learning_progress does not exist or metadata column already renamed'' AS message;'
);

PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET FOREIGN_KEY_CHECKS = 1;

-- 显示执行结果
SELECT '数据库列名修改完成' AS status;
SELECT 'pbl_project_outputs 和 pbl_learning_progress 表的 metadata 列已重命名为 meta_data' AS message;
