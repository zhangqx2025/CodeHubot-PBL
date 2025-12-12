-- =====================================================
-- 为 pbl_courses 表添加教师和起止时间字段
-- 创建时间: 2025-12-12
-- 说明: 
--   1. 添加授课教师字段（teacher_id 和 teacher_name）
--   2. 添加课程起止时间字段（start_date 和 end_date）
--   3. 兼容 MySQL 5.7-8.0 版本
-- =====================================================

-- 创建临时存储过程用于添加字段（兼容 MySQL 5.7）
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
    END IF;
END$$
DELIMITER ;

-- 添加授课教师ID字段
CALL add_column_if_not_exists(
    'pbl_courses', 
    'teacher_id', 
    'INT DEFAULT NULL COMMENT \'授课教师ID（关联core_users）\' AFTER `creator_id`'
);

-- 添加授课教师姓名字段（冗余字段，便于查询）
CALL add_column_if_not_exists(
    'pbl_courses', 
    'teacher_name', 
    'VARCHAR(100) DEFAULT NULL COMMENT \'授课教师姓名（冗余字段）\' AFTER `teacher_id`'
);

-- 添加课程开始时间字段
CALL add_column_if_not_exists(
    'pbl_courses', 
    'start_date', 
    'DATE DEFAULT NULL COMMENT \'课程开始时间\' AFTER `school_id`'
);

-- 添加课程结束时间字段
CALL add_column_if_not_exists(
    'pbl_courses', 
    'end_date', 
    'DATE DEFAULT NULL COMMENT \'课程结束时间\' AFTER `start_date`'
);

-- 创建索引（如果不存在）
SET @index_exists = (
    SELECT COUNT(*) FROM information_schema.STATISTICS 
    WHERE TABLE_SCHEMA = DATABASE() 
      AND TABLE_NAME = 'pbl_courses' 
      AND INDEX_NAME = 'idx_teacher_id'
);
SET @sql = IF(@index_exists = 0,
    'ALTER TABLE `pbl_courses` ADD INDEX `idx_teacher_id` (`teacher_id`)',
    'SELECT "Index idx_teacher_id already exists"');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @index_exists = (
    SELECT COUNT(*) FROM information_schema.STATISTICS 
    WHERE TABLE_SCHEMA = DATABASE() 
      AND TABLE_NAME = 'pbl_courses' 
      AND INDEX_NAME = 'idx_start_date'
);
SET @sql = IF(@index_exists = 0,
    'ALTER TABLE `pbl_courses` ADD INDEX `idx_start_date` (`start_date`)',
    'SELECT "Index idx_start_date already exists"');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 清理临时存储过程
DROP PROCEDURE IF EXISTS add_column_if_not_exists;

-- 查看执行结果
SELECT 'pbl_courses 表字段更新完成' AS message;
SHOW COLUMNS FROM `pbl_courses` WHERE Field IN ('teacher_id', 'teacher_name', 'start_date', 'end_date');
