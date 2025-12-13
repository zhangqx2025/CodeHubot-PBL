-- ==========================================================================================================
-- 增强班级管理功能
-- ==========================================================================================================
-- 文件: 17_enhance_class_management.sql
-- 版本: 1.0.1
-- 创建日期: 2025-12-12
-- 兼容版本: MySQL 5.7-8.0
-- 说明: 
--   1. 为 pbl_class_teachers 表添加 role 字段，支持主讲教师和助教角色
--   2. 确保 pbl_classes 表有 uuid 字段
--   3. 为作业管理添加必要的索引和字段
--   4. 本脚本支持重复执行，不使用存储过程
-- ==========================================================================================================

SET NAMES utf8mb4 COLLATE utf8mb4_unicode_ci;

-- ==========================================================================================================
-- 1. 确保 pbl_class_teachers 表存在
-- ==========================================================================================================

CREATE TABLE IF NOT EXISTS `pbl_class_teachers` (
  `id` INT(11) NOT NULL AUTO_INCREMENT PRIMARY KEY COMMENT '关联ID',
  `class_id` INT(11) NOT NULL COMMENT '班级ID',
  `teacher_id` INT(11) NOT NULL COMMENT '教师ID',
  `subject` VARCHAR(50) DEFAULT NULL COMMENT '教师在该班级教授的科目',
  `is_primary` TINYINT(1) DEFAULT 0 COMMENT '是否为班主任',
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  UNIQUE KEY `uk_class_teacher` (`class_id`, `teacher_id`),
  KEY `idx_class_id` (`class_id`),
  KEY `idx_teacher_id` (`teacher_id`),
  KEY `idx_is_primary` (`is_primary`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='PBL班级教师关联表（多对多）';

SELECT 'pbl_class_teachers 表已确保存在' AS result;

-- ==========================================================================================================
-- 2. 为 pbl_class_teachers 添加 role 字段
-- ==========================================================================================================

SET @column_exists = (
    SELECT COUNT(*) 
    FROM information_schema.COLUMNS 
    WHERE TABLE_SCHEMA = DATABASE() 
    AND TABLE_NAME = 'pbl_class_teachers' 
    AND COLUMN_NAME = 'role'
);

SET @sql = IF(@column_exists = 0,
    'ALTER TABLE `pbl_class_teachers` ADD COLUMN `role` ENUM(''main'', ''assistant'') DEFAULT ''assistant'' COMMENT ''教师角色：main-主讲教师，assistant-助教'' AFTER `teacher_id`',
    'SELECT ''role 字段已存在，跳过'' AS result'
);

PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- ==========================================================================================================
-- 3. 为 pbl_class_teachers 添加 added_at 字段
-- ==========================================================================================================

SET @column_exists = (
    SELECT COUNT(*) 
    FROM information_schema.COLUMNS 
    WHERE TABLE_SCHEMA = DATABASE() 
    AND TABLE_NAME = 'pbl_class_teachers' 
    AND COLUMN_NAME = 'added_at'
);

SET @sql = IF(@column_exists = 0,
    'ALTER TABLE `pbl_class_teachers` ADD COLUMN `added_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT ''添加时间'' AFTER `is_primary`',
    'SELECT ''added_at 字段已存在，跳过'' AS result'
);

PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- ==========================================================================================================
-- 4. 为 pbl_class_teachers 添加 role 索引
-- ==========================================================================================================

SET @index_exists = (
    SELECT COUNT(*) 
    FROM information_schema.STATISTICS 
    WHERE TABLE_SCHEMA = DATABASE() 
    AND TABLE_NAME = 'pbl_class_teachers' 
    AND INDEX_NAME = 'idx_role'
);

SET @sql = IF(@index_exists = 0,
    'ALTER TABLE `pbl_class_teachers` ADD KEY `idx_role` (`role`)',
    'SELECT ''idx_role 索引已存在，跳过'' AS result'
);

PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- ==========================================================================================================
-- 5. 为 pbl_classes 添加 uuid 字段
-- ==========================================================================================================

SET @column_exists = (
    SELECT COUNT(*) 
    FROM information_schema.COLUMNS 
    WHERE TABLE_SCHEMA = DATABASE() 
    AND TABLE_NAME = 'pbl_classes' 
    AND COLUMN_NAME = 'uuid'
);

SET @sql = IF(@column_exists = 0,
    'ALTER TABLE `pbl_classes` ADD COLUMN `uuid` VARCHAR(36) NOT NULL COMMENT ''UUID，唯一标识'' AFTER `id`',
    'SELECT ''uuid 字段已存在，跳过'' AS result'
);

PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 为现有记录生成 UUID（只有在字段刚添加或值为空时）
UPDATE `pbl_classes` SET `uuid` = UUID() WHERE `uuid` = '' OR `uuid` IS NULL;

-- 添加 uuid 唯一索引
SET @index_exists = (
    SELECT COUNT(*) 
    FROM information_schema.STATISTICS 
    WHERE TABLE_SCHEMA = DATABASE() 
    AND TABLE_NAME = 'pbl_classes' 
    AND INDEX_NAME = 'uk_uuid'
);

SET @sql = IF(@index_exists = 0,
    'ALTER TABLE `pbl_classes` ADD UNIQUE KEY `uk_uuid` (`uuid`)',
    'SELECT ''uk_uuid 索引已存在，跳过'' AS result'
);

PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- ==========================================================================================================
-- 6. 为 pbl_tasks 添加 start_time 字段
-- ==========================================================================================================

SET @column_exists = (
    SELECT COUNT(*) 
    FROM information_schema.COLUMNS 
    WHERE TABLE_SCHEMA = DATABASE() 
    AND TABLE_NAME = 'pbl_tasks' 
    AND COLUMN_NAME = 'start_time'
);

SET @sql = IF(@column_exists = 0,
    'ALTER TABLE `pbl_tasks` ADD COLUMN `start_time` TIMESTAMP NULL COMMENT ''作业开始时间'' AFTER `order`',
    'SELECT ''start_time 字段已存在，跳过'' AS result'
);

PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- ==========================================================================================================
-- 7. 为 pbl_tasks 添加 deadline 字段
-- ==========================================================================================================

SET @column_exists = (
    SELECT COUNT(*) 
    FROM information_schema.COLUMNS 
    WHERE TABLE_SCHEMA = DATABASE() 
    AND TABLE_NAME = 'pbl_tasks' 
    AND COLUMN_NAME = 'deadline'
);

SET @sql = IF(@column_exists = 0,
    'ALTER TABLE `pbl_tasks` ADD COLUMN `deadline` TIMESTAMP NULL COMMENT ''作业截止时间'' AFTER `start_time`',
    'SELECT ''deadline 字段已存在，跳过'' AS result'
);

PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- ==========================================================================================================
-- 8. 为 pbl_tasks 添加 is_required 字段
-- ==========================================================================================================

SET @column_exists = (
    SELECT COUNT(*) 
    FROM information_schema.COLUMNS 
    WHERE TABLE_SCHEMA = DATABASE() 
    AND TABLE_NAME = 'pbl_tasks' 
    AND COLUMN_NAME = 'is_required'
);

SET @sql = IF(@column_exists = 0,
    'ALTER TABLE `pbl_tasks` ADD COLUMN `is_required` TINYINT(1) DEFAULT 1 COMMENT ''是否必做：1-必做，0-选做'' AFTER `deadline`',
    'SELECT ''is_required 字段已存在，跳过'' AS result'
);

PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- ==========================================================================================================
-- 9. 为 pbl_tasks 添加 publish_status 字段
-- ==========================================================================================================

SET @column_exists = (
    SELECT COUNT(*) 
    FROM information_schema.COLUMNS 
    WHERE TABLE_SCHEMA = DATABASE() 
    AND TABLE_NAME = 'pbl_tasks' 
    AND COLUMN_NAME = 'publish_status'
);

SET @sql = IF(@column_exists = 0,
    'ALTER TABLE `pbl_tasks` ADD COLUMN `publish_status` ENUM(''draft'', ''published'') DEFAULT ''draft'' COMMENT ''发布状态：draft-草稿，published-已发布'' AFTER `is_required`',
    'SELECT ''publish_status 字段已存在，跳过'' AS result'
);

PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- ==========================================================================================================
-- 10. 为 pbl_tasks 添加 deadline 索引
-- ==========================================================================================================

SET @index_exists = (
    SELECT COUNT(*) 
    FROM information_schema.STATISTICS 
    WHERE TABLE_SCHEMA = DATABASE() 
    AND TABLE_NAME = 'pbl_tasks' 
    AND INDEX_NAME = 'idx_deadline'
);

SET @sql = IF(@index_exists = 0,
    'ALTER TABLE `pbl_tasks` ADD KEY `idx_deadline` (`deadline`)',
    'SELECT ''idx_deadline 索引已存在，跳过'' AS result'
);

PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- ==========================================================================================================
-- 11. 为 pbl_tasks 添加 publish_status 索引
-- ==========================================================================================================

SET @index_exists = (
    SELECT COUNT(*) 
    FROM information_schema.STATISTICS 
    WHERE TABLE_SCHEMA = DATABASE() 
    AND TABLE_NAME = 'pbl_tasks' 
    AND INDEX_NAME = 'idx_publish_status'
);

SET @sql = IF(@index_exists = 0,
    'ALTER TABLE `pbl_tasks` ADD KEY `idx_publish_status` (`publish_status`)',
    'SELECT ''idx_publish_status 索引已存在，跳过'' AS result'
);

PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- ==========================================================================================================
-- 12. 为 pbl_task_progress 添加 submitted_at 字段
-- ==========================================================================================================

SET @column_exists = (
    SELECT COUNT(*) 
    FROM information_schema.COLUMNS 
    WHERE TABLE_SCHEMA = DATABASE() 
    AND TABLE_NAME = 'pbl_task_progress' 
    AND COLUMN_NAME = 'submitted_at'
);

SET @sql = IF(@column_exists = 0,
    'ALTER TABLE `pbl_task_progress` ADD COLUMN `submitted_at` TIMESTAMP NULL COMMENT ''提交时间'' AFTER `submission`',
    'SELECT ''submitted_at 字段已存在，跳过'' AS result'
);

PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- ==========================================================================================================
-- 13. 数据迁移：为现有教师设置默认角色
-- ==========================================================================================================

-- 检查是否有教师角色为 NULL
UPDATE `pbl_class_teachers` 
SET `role` = 'assistant' 
WHERE `role` IS NULL;

-- 将班主任（is_primary=1）设置为主讲教师
UPDATE `pbl_class_teachers` 
SET `role` = 'main' 
WHERE `is_primary` = 1 AND `role` = 'assistant';

-- ==========================================================================================================
-- 14. 验证脚本执行结果
-- ==========================================================================================================

-- 显示 pbl_class_teachers 表结构
SELECT '=== pbl_class_teachers 表结构 ===' AS info;
SHOW CREATE TABLE `pbl_class_teachers`;

-- 显示 pbl_tasks 新增字段
SELECT 
    COLUMN_NAME,
    COLUMN_TYPE,
    COLUMN_COMMENT
FROM information_schema.COLUMNS
WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'pbl_tasks'
    AND COLUMN_NAME IN ('start_time', 'deadline', 'is_required', 'publish_status')
ORDER BY ORDINAL_POSITION;

-- 显示统计信息
SELECT '=== 统计信息 ===' AS info;

-- 显示教师统计（如果表为空会显示 0）
SELECT 
    COUNT(*) AS total_class_teachers,
    COALESCE(SUM(CASE WHEN role = 'main' THEN 1 ELSE 0 END), 0) AS main_teachers,
    COALESCE(SUM(CASE WHEN role = 'assistant' THEN 1 ELSE 0 END), 0) AS assistant_teachers
FROM `pbl_class_teachers`;

SELECT '脚本执行完成！' AS result;

-- ==========================================================================================================
-- 执行完成
-- ==========================================================================================================
