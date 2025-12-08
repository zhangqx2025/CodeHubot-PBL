-- ==========================================
-- 17. 增强学习进度追踪功能
-- ==========================================
-- 说明：
--   为pbl_learning_progress表添加状态字段和完成时间
--   确保每个学生对每个资源/任务只有一条记录
--   支持学习进度的完整追踪
-- ==========================================

-- 1. 检查并添加status字段（如果不存在）
SET @column_exists = (
    SELECT COUNT(*) 
    FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'pbl_learning_progress'
    AND COLUMN_NAME = 'status'
);

SET @sql = IF(
    @column_exists = 0,
    'ALTER TABLE `pbl_learning_progress` 
     ADD COLUMN `status` ENUM(''in_progress'', ''completed'') NOT NULL DEFAULT ''in_progress'' COMMENT ''状态'' AFTER `progress_value`',
    'SELECT ''Column status already exists'' AS message'
);

PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 2. 检查并添加completed_at字段（如果不存在）
SET @column_exists = (
    SELECT COUNT(*) 
    FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'pbl_learning_progress'
    AND COLUMN_NAME = 'completed_at'
);

SET @sql = IF(
    @column_exists = 0,
    'ALTER TABLE `pbl_learning_progress` 
     ADD COLUMN `completed_at` TIMESTAMP NULL DEFAULT NULL COMMENT ''完成时间'' AFTER `status`',
    'SELECT ''Column completed_at already exists'' AS message'
);

PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 3. 检查并添加updated_at字段（如果不存在）
SET @column_exists = (
    SELECT COUNT(*) 
    FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'pbl_learning_progress'
    AND COLUMN_NAME = 'updated_at'
);

SET @sql = IF(
    @column_exists = 0,
    'ALTER TABLE `pbl_learning_progress` 
     ADD COLUMN `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT ''更新时间'' AFTER `completed_at`',
    'SELECT ''Column updated_at already exists'' AS message'
);

PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 4. 检查并添加task_id字段用于任务进度关联（如果不存在）
SET @column_exists = (
    SELECT COUNT(*) 
    FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'pbl_learning_progress'
    AND COLUMN_NAME = 'task_id'
);

SET @sql = IF(
    @column_exists = 0,
    'ALTER TABLE `pbl_learning_progress` 
     ADD COLUMN `task_id` BIGINT(20) DEFAULT NULL COMMENT ''任务ID'' AFTER `resource_id`,
     ADD KEY `idx_task_id` (`task_id`)',
    'SELECT ''Column task_id already exists'' AS message'
);

PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 5. 添加task_id外键约束（如果不存在）
SET @fk_exists = (
    SELECT COUNT(*)
    FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS
    WHERE CONSTRAINT_SCHEMA = DATABASE()
    AND TABLE_NAME = 'pbl_learning_progress'
    AND CONSTRAINT_NAME = 'fk_learning_progress_task'
);

SET @sql = IF(
    @fk_exists = 0 AND (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'pbl_learning_progress' AND COLUMN_NAME = 'task_id') > 0,
    'ALTER TABLE `pbl_learning_progress` 
     ADD CONSTRAINT `fk_learning_progress_task` FOREIGN KEY (`task_id`) REFERENCES `pbl_tasks` (`id`) ON DELETE CASCADE',
    'SELECT ''Foreign key fk_learning_progress_task already exists or task_id column not found'' AS message'
);

PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 6. 添加唯一索引，确保每个用户对每个资源/任务只有一条最新记录
-- 注意：这里我们不添加唯一约束，因为可能有多次学习记录，但会通过应用层保证查询最新记录

-- 7. 添加status索引以提高查询效率
SET @index_exists = (
    SELECT COUNT(*)
    FROM INFORMATION_SCHEMA.STATISTICS
    WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'pbl_learning_progress'
    AND INDEX_NAME = 'idx_status'
);

SET @sql = IF(
    @index_exists = 0,
    'ALTER TABLE `pbl_learning_progress` ADD KEY `idx_status` (`status`)',
    'SELECT ''Index idx_status already exists'' AS message'
);

PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 8. 添加组合索引以提高查询效率
SET @index_exists = (
    SELECT COUNT(*)
    FROM INFORMATION_SCHEMA.STATISTICS
    WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'pbl_learning_progress'
    AND INDEX_NAME = 'idx_user_resource_latest'
);

SET @sql = IF(
    @index_exists = 0,
    'ALTER TABLE `pbl_learning_progress` ADD KEY `idx_user_resource_latest` (`user_id`, `resource_id`, `created_at`)',
    'SELECT ''Index idx_user_resource_latest already exists'' AS message'
);

PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 9. 添加用户-任务组合索引
SET @index_exists = (
    SELECT COUNT(*)
    FROM INFORMATION_SCHEMA.STATISTICS
    WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'pbl_learning_progress'
    AND INDEX_NAME = 'idx_user_task_latest'
);

SET @sql = IF(
    @index_exists = 0,
    'ALTER TABLE `pbl_learning_progress` ADD KEY `idx_user_task_latest` (`user_id`, `task_id`, `created_at`)',
    'SELECT ''Index idx_user_task_latest already exists'' AS message'
);

PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 完成
SELECT 'pbl_learning_progress表增强完成：添加了status、completed_at、updated_at、task_id字段及相关索引' AS message;
