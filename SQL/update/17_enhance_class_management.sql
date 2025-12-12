-- ==========================================================================================================
-- 增强班级管理功能
-- ==========================================================================================================
-- 文件: 17_enhance_class_management.sql
-- 版本: 1.0.0
-- 创建日期: 2025-12-12
-- 兼容版本: MySQL 5.7-8.0
-- 说明: 
--   1. 为 pbl_class_teachers 表添加 role 字段，支持主讲教师和助教角色
--   2. 确保 pbl_classes 表有 uuid 字段
--   3. 为作业管理添加必要的索引和字段
--   4. 本脚本支持重复执行
-- ==========================================================================================================

SET NAMES utf8mb4 COLLATE utf8mb4_unicode_ci;

-- ==========================================================================================================
-- 1. 确保 pbl_class_teachers 表存在
-- ==========================================================================================================

-- 如果表不存在则创建
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
-- 2. 增强 pbl_class_teachers 表 - 添加教师角色字段
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

-- 添加 role 字段（教师角色：main-主讲教师，assistant-助教）
CALL add_column_if_not_exists(
    'pbl_class_teachers',
    'role',
    "ENUM('main', 'assistant') DEFAULT 'assistant' COMMENT '教师角色：main-主讲教师，assistant-助教' AFTER `teacher_id`"
);

-- 添加 added_at 字段（添加教师的时间）
CALL add_column_if_not_exists(
    'pbl_class_teachers',
    'added_at',
    "TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '添加时间' AFTER `is_primary`"
);

-- 删除临时存储过程
DROP PROCEDURE IF EXISTS add_column_if_not_exists;

-- ==========================================================================================================
-- 3. 为 pbl_class_teachers 添加索引
-- ==========================================================================================================

-- 创建临时存储过程用于添加索引
DROP PROCEDURE IF EXISTS add_index_if_not_exists;
DELIMITER $$
CREATE PROCEDURE add_index_if_not_exists(
    IN tableName VARCHAR(128),
    IN indexName VARCHAR(128),
    IN indexDefinition TEXT
)
BEGIN
    DECLARE index_count INT;
    SELECT COUNT(*) INTO index_count
    FROM information_schema.STATISTICS
    WHERE TABLE_SCHEMA = DATABASE()
        AND TABLE_NAME = tableName
        AND INDEX_NAME = indexName;
    
    IF index_count = 0 THEN
        SET @sql = CONCAT('ALTER TABLE `', tableName, '` ADD ', indexDefinition);
        PREPARE stmt FROM @sql;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;
        SELECT CONCAT('索引 ', indexName, ' 已添加到表 ', tableName) AS result;
    ELSE
        SELECT CONCAT('索引 ', indexName, ' 已存在于表 ', tableName, '，跳过') AS result;
    END IF;
END$$
DELIMITER ;

-- 添加角色索引
CALL add_index_if_not_exists(
    'pbl_class_teachers',
    'idx_role',
    "KEY `idx_role` (`role`)"
);

-- 删除临时存储过程
DROP PROCEDURE IF EXISTS add_index_if_not_exists;

-- ==========================================================================================================
-- 4. 确保 pbl_classes 表有 uuid 字段
-- ==========================================================================================================

-- 创建临时存储过程
DROP PROCEDURE IF EXISTS add_uuid_to_classes;
DELIMITER $$
CREATE PROCEDURE add_uuid_to_classes()
BEGIN
    DECLARE column_count INT;
    SELECT COUNT(*) INTO column_count
    FROM information_schema.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE()
        AND TABLE_NAME = 'pbl_classes'
        AND COLUMN_NAME = 'uuid';
    
    IF column_count = 0 THEN
        -- 添加 uuid 字段
        ALTER TABLE `pbl_classes` 
        ADD COLUMN `uuid` VARCHAR(36) NOT NULL COMMENT 'UUID，唯一标识' AFTER `id`;
        
        -- 为现有记录生成 UUID
        UPDATE `pbl_classes` SET `uuid` = UUID() WHERE `uuid` = '' OR `uuid` IS NULL;
        
        -- 添加唯一索引
        ALTER TABLE `pbl_classes` ADD UNIQUE KEY `uk_uuid` (`uuid`);
        
        SELECT '已为 pbl_classes 表添加 uuid 字段并生成 UUID' AS result;
    ELSE
        SELECT 'pbl_classes 表已有 uuid 字段，跳过' AS result;
    END IF;
END$$
DELIMITER ;

CALL add_uuid_to_classes();
DROP PROCEDURE IF EXISTS add_uuid_to_classes;

-- ==========================================================================================================
-- 5. 增强 pbl_tasks 表 - 添加作业相关字段
-- ==========================================================================================================

-- 创建临时存储过程
DROP PROCEDURE IF EXISTS enhance_tasks_table;
DELIMITER $$
CREATE PROCEDURE enhance_tasks_table()
BEGIN
    -- 添加 start_time 字段（作业开始时间）
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.COLUMNS
        WHERE TABLE_SCHEMA = DATABASE()
            AND TABLE_NAME = 'pbl_tasks'
            AND COLUMN_NAME = 'start_time'
    ) THEN
        ALTER TABLE `pbl_tasks` 
        ADD COLUMN `start_time` TIMESTAMP NULL COMMENT '作业开始时间' AFTER `order`;
        SELECT '已添加 start_time 字段' AS result;
    END IF;
    
    -- 添加 deadline 字段（作业截止时间）
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.COLUMNS
        WHERE TABLE_SCHEMA = DATABASE()
            AND TABLE_NAME = 'pbl_tasks'
            AND COLUMN_NAME = 'deadline'
    ) THEN
        ALTER TABLE `pbl_tasks` 
        ADD COLUMN `deadline` TIMESTAMP NULL COMMENT '作业截止时间' AFTER `start_time`;
        SELECT '已添加 deadline 字段' AS result;
    END IF;
    
    -- 添加 is_required 字段（是否必做）
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.COLUMNS
        WHERE TABLE_SCHEMA = DATABASE()
            AND TABLE_NAME = 'pbl_tasks'
            AND COLUMN_NAME = 'is_required'
    ) THEN
        ALTER TABLE `pbl_tasks` 
        ADD COLUMN `is_required` TINYINT(1) DEFAULT 1 COMMENT '是否必做：1-必做，0-选做' AFTER `deadline`;
        SELECT '已添加 is_required 字段' AS result;
    END IF;
    
    -- 添加 publish_status 字段（发布状态）
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.COLUMNS
        WHERE TABLE_SCHEMA = DATABASE()
            AND TABLE_NAME = 'pbl_tasks'
            AND COLUMN_NAME = 'publish_status'
    ) THEN
        ALTER TABLE `pbl_tasks` 
        ADD COLUMN `publish_status` ENUM('draft', 'published') DEFAULT 'draft' 
            COMMENT '发布状态：draft-草稿，published-已发布' AFTER `is_required`;
        SELECT '已添加 publish_status 字段' AS result;
    END IF;
END$$
DELIMITER ;

CALL enhance_tasks_table();
DROP PROCEDURE IF EXISTS enhance_tasks_table;

-- ==========================================================================================================
-- 6. 为 pbl_tasks 添加索引
-- ==========================================================================================================

-- 创建临时存储过程
DROP PROCEDURE IF EXISTS add_tasks_indexes;
DELIMITER $$
CREATE PROCEDURE add_tasks_indexes()
BEGIN
    -- 添加 deadline 索引
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.STATISTICS
        WHERE TABLE_SCHEMA = DATABASE()
            AND TABLE_NAME = 'pbl_tasks'
            AND INDEX_NAME = 'idx_deadline'
    ) THEN
        ALTER TABLE `pbl_tasks` ADD KEY `idx_deadline` (`deadline`);
        SELECT '已添加 idx_deadline 索引' AS result;
    END IF;
    
    -- 添加 publish_status 索引
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.STATISTICS
        WHERE TABLE_SCHEMA = DATABASE()
            AND TABLE_NAME = 'pbl_tasks'
            AND INDEX_NAME = 'idx_publish_status'
    ) THEN
        ALTER TABLE `pbl_tasks` ADD KEY `idx_publish_status` (`publish_status`);
        SELECT '已添加 idx_publish_status 索引' AS result;
    END IF;
END$$
DELIMITER ;

CALL add_tasks_indexes();
DROP PROCEDURE IF EXISTS add_tasks_indexes;

-- ==========================================================================================================
-- 7. 增强 pbl_task_progress 表 - 添加提交时间
-- ==========================================================================================================

-- 创建临时存储过程
DROP PROCEDURE IF EXISTS enhance_task_progress_table;
DELIMITER $$
CREATE PROCEDURE enhance_task_progress_table()
BEGIN
    -- 添加 submitted_at 字段
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.COLUMNS
        WHERE TABLE_SCHEMA = DATABASE()
            AND TABLE_NAME = 'pbl_task_progress'
            AND COLUMN_NAME = 'submitted_at'
    ) THEN
        ALTER TABLE `pbl_task_progress` 
        ADD COLUMN `submitted_at` TIMESTAMP NULL COMMENT '提交时间' AFTER `submission`;
        SELECT '已添加 submitted_at 字段' AS result;
    END IF;
END$$
DELIMITER ;

CALL enhance_task_progress_table();
DROP PROCEDURE IF EXISTS enhance_task_progress_table;

-- ==========================================================================================================
-- 8. 数据迁移：为现有教师设置默认角色
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
-- 9. 验证脚本执行结果
-- ==========================================================================================================

-- 显示 pbl_class_teachers 表结构
SELECT 
    '=== pbl_class_teachers 表结构 ===' AS info;
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
SELECT 
    '=== 统计信息 ===' AS info;

-- 只在表有数据时显示统计
SET @teacher_count = (SELECT COUNT(*) FROM `pbl_class_teachers`);

SELECT 
    CASE 
        WHEN @teacher_count > 0 THEN
            CONCAT('共有 ', @teacher_count, ' 位教师')
        ELSE 
            '暂无教师数据'
    END AS message;

-- 如果有数据，显示详细统计
SELECT 
    COUNT(*) AS total_class_teachers,
    SUM(CASE WHEN role = 'main' THEN 1 ELSE 0 END) AS main_teachers,
    SUM(CASE WHEN role = 'assistant' THEN 1 ELSE 0 END) AS assistant_teachers
FROM `pbl_class_teachers`
WHERE @teacher_count > 0;

SELECT '脚本执行完成！' AS result;

-- ==========================================================================================================
-- 执行完成
-- ==========================================================================================================
