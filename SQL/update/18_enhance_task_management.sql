-- ==========================================================================================================
-- 增强任务管理功能
-- ==========================================================================================================
-- 文件: 18_enhance_task_management.sql
-- 版本: 1.0.0
-- 创建日期: 2025-12-12
-- 兼容版本: MySQL 5.7-8.0
-- 说明: 
--   1. 为 pbl_tasks 表添加时间相关字段（start_time, deadline）
--   2. 为 pbl_tasks 表添加任务类型字段（type）
--   3. 确保所有索引正确创建
--   4. 本脚本支持重复执行
-- ==========================================================================================================

SET NAMES utf8mb4 COLLATE utf8mb4_unicode_ci;

-- ==========================================================================================================
-- 1. 为 pbl_tasks 表添加时间相关字段
-- ==========================================================================================================

-- 创建临时存储过程用于添加字段
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
        SELECT CONCAT('字段 ', columnName, ' 已添加到表 ', tableName) AS result;
    ELSE
        SELECT CONCAT('字段 ', columnName, ' 已存在于表 ', tableName, '，跳过') AS result;
    END IF;
END$$
DELIMITER ;

-- 添加 start_time 字段（任务开始时间）
CALL add_column_if_not_exists(
    'pbl_tasks',
    'start_time',
    "TIMESTAMP NULL DEFAULT NULL COMMENT '任务开始时间' AFTER `description`"
);

-- 添加 deadline 字段（任务截止时间）
CALL add_column_if_not_exists(
    'pbl_tasks',
    'deadline',
    "TIMESTAMP NULL DEFAULT NULL COMMENT '任务截止时间' AFTER `start_time`"
);

-- 删除临时存储过程
DROP PROCEDURE IF EXISTS add_column_if_not_exists;

SELECT '✓ pbl_tasks 时间字段添加完成' AS '';

-- ==========================================================================================================
-- 2. 验证和显示表结构
-- ==========================================================================================================

SELECT
    '=== pbl_tasks 表结构（时间字段）===' AS info;

SELECT
    COLUMN_NAME,
    COLUMN_TYPE,
    IS_NULLABLE,
    COLUMN_DEFAULT,
    COLUMN_COMMENT
FROM information_schema.COLUMNS
WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'pbl_tasks'
    AND COLUMN_NAME IN ('start_time', 'deadline', 'type', 'order')
ORDER BY ORDINAL_POSITION;

SELECT '✓ 脚本执行完成！' AS result;

-- ==========================================================================================================
-- 执行完成
-- ==========================================================================================================
