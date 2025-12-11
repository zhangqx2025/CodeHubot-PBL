-- ==========================================================================================================
-- 课程模板库功能 - 数据库更新脚本
-- ==========================================================================================================
-- 
-- 脚本名称: 04_add_course_templates.sql
-- 创建日期: 2024-12-11
-- 兼容版本: MySQL 5.7.x, 8.0.x
-- 字符集: utf8mb4
-- 排序规则: utf8mb4_unicode_ci
--
-- ==========================================================================================================
-- 功能说明:
-- ==========================================================================================================
--
-- 1. 创建课程模板库功能，包含以下表：
--    - pbl_course_templates: 课程模板表
--    - pbl_unit_templates: 单元模板表
--    - pbl_resource_templates: 资源模板表
--    - pbl_task_templates: 任务模板表
--    - pbl_template_categories: 模板分类表
--
-- 2. 修改现有表，添加模板关联字段：
--    - pbl_courses: 添加 template_id 字段
--    - pbl_units: 添加 template_id 字段
--    - pbl_resources: 添加 template_id 字段
--    - pbl_tasks: 添加 template_id 字段
--
-- 3. 设计特点：
--    - 模板与实例分离，便于复用和管理
--    - 支持多层级结构（课程->单元->资源/任务）
--    - 支持版本管理，可追踪模板变更
--    - 支持分类和标签，便于检索
--    - 向后兼容，现有数据不受影响（template_id 可为 NULL）
--
-- 4. 使用场景：
--    - 平台创建标准课程模板
--    - 学校基于模板创建课程实例
--    - 学校可以定制模板内容
--    - 模板更新时可选择是否同步到实例
--
-- ==========================================================================================================

-- 设置字符集
SET NAMES utf8mb4 COLLATE utf8mb4_unicode_ci;

-- 禁用外键检查
SET FOREIGN_KEY_CHECKS = 0;

-- 开始事务
START TRANSACTION;

-- ==========================================================================================================
-- 1. 创建模板分类表
-- ==========================================================================================================

CREATE TABLE IF NOT EXISTS `pbl_template_categories` (
  `id` INT(11) NOT NULL AUTO_INCREMENT PRIMARY KEY COMMENT '分类ID',
  `uuid` CHAR(36) NOT NULL COMMENT 'UUID',
  `name` VARCHAR(100) NOT NULL COMMENT '分类名称',
  `code` VARCHAR(50) NOT NULL COMMENT '分类编码',
  `description` TEXT COMMENT '分类描述',
  `icon` VARCHAR(255) COMMENT '分类图标',
  `parent_id` INT(11) DEFAULT NULL COMMENT '父分类ID（支持二级分类）',
  `level` TINYINT(1) DEFAULT 1 COMMENT '分类层级（1-一级，2-二级）',
  `sort_order` INT(11) DEFAULT 0 COMMENT '排序顺序',
  `is_active` TINYINT(1) DEFAULT 1 COMMENT '是否启用',
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  
  UNIQUE KEY `uk_uuid` (`uuid`),
  UNIQUE KEY `uk_code` (`code`),
  KEY `idx_parent_id` (`parent_id`),
  KEY `idx_level` (`level`),
  KEY `idx_sort_order` (`sort_order`),
  KEY `idx_is_active` (`is_active`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='模板分类表';


-- ==========================================================================================================
-- 2. 创建课程模板表
-- ==========================================================================================================

CREATE TABLE IF NOT EXISTS `pbl_course_templates` (
  `id` BIGINT(20) NOT NULL AUTO_INCREMENT PRIMARY KEY COMMENT '模板ID',
  `uuid` CHAR(36) NOT NULL COMMENT 'UUID',
  `template_code` VARCHAR(50) NOT NULL COMMENT '模板编码（唯一标识）',
  `title` VARCHAR(200) NOT NULL COMMENT '课程标题',
  `subtitle` VARCHAR(200) COMMENT '副标题',
  `description` TEXT COMMENT '课程描述',
  `cover_image` VARCHAR(500) COMMENT '封面图片URL',
  
  -- 分类和标签
  `category_id` INT(11) COMMENT '分类ID',
  `tags` JSON COMMENT '标签列表',
  `keywords` VARCHAR(500) COMMENT '关键词（便于搜索）',
  
  -- 课程属性
  `duration` VARCHAR(50) COMMENT '课程时长（如：8周、16学时）',
  `difficulty` ENUM('beginner', 'intermediate', 'advanced') DEFAULT 'beginner' COMMENT '难度等级',
  `grade_level` VARCHAR(50) COMMENT '适用年级（如：初中、高中）',
  `subject` VARCHAR(50) COMMENT '学科（如：人工智能、编程）',
  
  -- 课程目标
  `learning_objectives` JSON COMMENT '学习目标',
  `skill_points` JSON COMMENT '技能点',
  `prerequisite_knowledge` JSON COMMENT '先修知识',
  
  -- 版本管理
  `version` VARCHAR(20) DEFAULT '1.0.0' COMMENT '版本号',
  `version_notes` TEXT COMMENT '版本说明',
  `parent_template_id` BIGINT(20) DEFAULT NULL COMMENT '父模板ID（用于版本继承）',
  
  -- 状态和权限
  `status` ENUM('draft', 'published', 'archived', 'deprecated') DEFAULT 'draft' COMMENT '状态',
  `is_system` TINYINT(1) DEFAULT 0 COMMENT '是否系统内置',
  `is_public` TINYINT(1) DEFAULT 1 COMMENT '是否公开（学校可见）',
  `access_level` ENUM('public', 'restricted', 'private') DEFAULT 'public' COMMENT '访问级别',
  
  -- 使用统计
  `usage_count` INT(11) DEFAULT 0 COMMENT '使用次数（创建实例数量）',
  `rating` DECIMAL(3, 2) DEFAULT 0.00 COMMENT '评分（0-5）',
  `rating_count` INT(11) DEFAULT 0 COMMENT '评分人数',
  
  -- 创建者信息
  `creator_id` INT(11) NOT NULL COMMENT '创建者ID',
  `creator_type` ENUM('platform_admin', 'content_provider', 'teacher') DEFAULT 'platform_admin' COMMENT '创建者类型',
  
  -- 扩展信息
  `meta_data` JSON COMMENT '扩展元数据',
  `settings` JSON COMMENT '模板设置',
  
  -- 时间字段
  `published_at` TIMESTAMP NULL COMMENT '发布时间',
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted_at` TIMESTAMP NULL COMMENT '软删除时间',
  
  UNIQUE KEY `uk_uuid` (`uuid`),
  UNIQUE KEY `uk_template_code` (`template_code`),
  KEY `idx_category_id` (`category_id`),
  KEY `idx_difficulty` (`difficulty`),
  KEY `idx_grade_level` (`grade_level`),
  KEY `idx_subject` (`subject`),
  KEY `idx_status` (`status`),
  KEY `idx_creator_id` (`creator_id`),
  KEY `idx_parent_template_id` (`parent_template_id`),
  KEY `idx_usage_count` (`usage_count`),
  KEY `idx_is_public` (`is_public`),
  KEY `idx_deleted_at` (`deleted_at`),
  
  CONSTRAINT `fk_course_template_category` FOREIGN KEY (`category_id`) REFERENCES `pbl_template_categories` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_course_template_parent` FOREIGN KEY (`parent_template_id`) REFERENCES `pbl_course_templates` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='课程模板表';


-- ==========================================================================================================
-- 3. 创建单元模板表
-- ==========================================================================================================

CREATE TABLE IF NOT EXISTS `pbl_unit_templates` (
  `id` BIGINT(20) NOT NULL AUTO_INCREMENT PRIMARY KEY COMMENT '单元模板ID',
  `uuid` CHAR(36) NOT NULL COMMENT 'UUID',
  `template_code` VARCHAR(50) NOT NULL COMMENT '模板编码',
  `course_template_id` BIGINT(20) NOT NULL COMMENT '课程模板ID',
  
  -- 基本信息
  `title` VARCHAR(200) NOT NULL COMMENT '单元标题',
  `description` TEXT COMMENT '单元描述',
  `order` INT(11) DEFAULT 0 COMMENT '排序顺序',
  
  -- 学习内容
  `learning_objectives` JSON COMMENT '学习目标',
  `learning_guide` JSON COMMENT '学习指南',
  `key_concepts` JSON COMMENT '关键概念',
  
  -- 时间安排
  `estimated_hours` INT(11) COMMENT '预计学时',
  `recommended_duration` VARCHAR(50) COMMENT '建议时长',
  
  -- 资源统计
  `resource_count` INT(11) DEFAULT 0 COMMENT '资源数量',
  `task_count` INT(11) DEFAULT 0 COMMENT '任务数量',
  
  -- 扩展信息
  `meta_data` JSON COMMENT '扩展元数据',
  
  -- 时间字段
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted_at` TIMESTAMP NULL COMMENT '软删除时间',
  
  UNIQUE KEY `uk_uuid` (`uuid`),
  UNIQUE KEY `uk_course_template_code` (`course_template_id`, `template_code`),
  KEY `idx_course_template_id` (`course_template_id`),
  KEY `idx_order` (`order`),
  KEY `idx_deleted_at` (`deleted_at`),
  
  CONSTRAINT `fk_unit_template_course` FOREIGN KEY (`course_template_id`) REFERENCES `pbl_course_templates` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='单元模板表';


-- ==========================================================================================================
-- 4. 创建资源模板表
-- ==========================================================================================================

CREATE TABLE IF NOT EXISTS `pbl_resource_templates` (
  `id` BIGINT(20) NOT NULL AUTO_INCREMENT PRIMARY KEY COMMENT '资源模板ID',
  `uuid` CHAR(36) NOT NULL COMMENT 'UUID',
  `template_code` VARCHAR(50) NOT NULL COMMENT '模板编码',
  `unit_template_id` BIGINT(20) NOT NULL COMMENT '单元模板ID',
  
  -- 基本信息
  `type` ENUM('video', 'document', 'link', 'interactive', 'quiz') NOT NULL COMMENT '资源类型',
  `title` VARCHAR(200) NOT NULL COMMENT '资源标题',
  `description` TEXT COMMENT '资源描述',
  `order` INT(11) DEFAULT 0 COMMENT '排序顺序',
  
  -- 资源内容
  `url` VARCHAR(500) COMMENT '资源URL',
  `content` LONGTEXT COMMENT '资源内容（文本、Markdown等）',
  
  -- 视频相关
  `video_id` VARCHAR(100) COMMENT '视频ID（阿里云VOD）',
  `video_cover_url` VARCHAR(500) COMMENT '视频封面',
  `duration` INT(11) COMMENT '时长（秒）',
  
  -- 访问控制（模板级默认值）
  `default_max_views` INT(11) DEFAULT NULL COMMENT '默认最大观看次数',
  `is_preview_allowed` TINYINT(1) DEFAULT 1 COMMENT '是否允许预览',
  
  -- 扩展信息
  `meta_data` JSON COMMENT '扩展元数据',
  
  -- 时间字段
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted_at` TIMESTAMP NULL COMMENT '软删除时间',
  
  UNIQUE KEY `uk_uuid` (`uuid`),
  UNIQUE KEY `uk_unit_template_code` (`unit_template_id`, `template_code`),
  KEY `idx_unit_template_id` (`unit_template_id`),
  KEY `idx_type` (`type`),
  KEY `idx_order` (`order`),
  KEY `idx_deleted_at` (`deleted_at`),
  
  CONSTRAINT `fk_resource_template_unit` FOREIGN KEY (`unit_template_id`) REFERENCES `pbl_unit_templates` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='资源模板表';


-- ==========================================================================================================
-- 5. 创建任务模板表
-- ==========================================================================================================

CREATE TABLE IF NOT EXISTS `pbl_task_templates` (
  `id` BIGINT(20) NOT NULL AUTO_INCREMENT PRIMARY KEY COMMENT '任务模板ID',
  `uuid` CHAR(36) NOT NULL COMMENT 'UUID',
  `template_code` VARCHAR(50) NOT NULL COMMENT '模板编码',
  `unit_template_id` BIGINT(20) NOT NULL COMMENT '单元模板ID',
  
  -- 基本信息
  `title` VARCHAR(200) NOT NULL COMMENT '任务标题',
  `description` TEXT COMMENT '任务描述',
  `type` ENUM('analysis', 'coding', 'design', 'deployment', 'research', 'presentation') DEFAULT 'analysis' COMMENT '任务类型',
  `difficulty` ENUM('easy', 'medium', 'hard') DEFAULT 'easy' COMMENT '难度',
  `order` INT(11) DEFAULT 0 COMMENT '排序顺序',
  
  -- 任务要求
  `requirements` JSON COMMENT '任务要求',
  `deliverables` JSON COMMENT '交付物要求',
  `evaluation_criteria` JSON COMMENT '评价标准',
  
  -- 时间安排
  `estimated_time` VARCHAR(50) COMMENT '预计完成时间',
  `estimated_hours` INT(11) COMMENT '预计工时',
  
  -- 前置条件
  `prerequisites` JSON COMMENT '前置条件',
  `required_resources` JSON COMMENT '所需资源',
  
  -- 扩展信息
  `hints` JSON COMMENT '提示信息',
  `reference_materials` JSON COMMENT '参考资料',
  `meta_data` JSON COMMENT '扩展元数据',
  
  -- 时间字段
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted_at` TIMESTAMP NULL COMMENT '软删除时间',
  
  UNIQUE KEY `uk_uuid` (`uuid`),
  UNIQUE KEY `uk_unit_template_code` (`unit_template_id`, `template_code`),
  KEY `idx_unit_template_id` (`unit_template_id`),
  KEY `idx_type` (`type`),
  KEY `idx_difficulty` (`difficulty`),
  KEY `idx_order` (`order`),
  KEY `idx_deleted_at` (`deleted_at`),
  
  CONSTRAINT `fk_task_template_unit` FOREIGN KEY (`unit_template_id`) REFERENCES `pbl_unit_templates` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='任务模板表';


-- ==========================================================================================================
-- 6. 修改现有课程表，添加模板关联字段
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
    END IF;
END$$
DELIMITER ;

-- 添加字段到 pbl_courses 表
CALL add_column_if_not_exists('pbl_courses', 'template_id', 
    'BIGINT(20) DEFAULT NULL COMMENT \'课程模板ID（NULL表示非基于模板创建）\' AFTER `uuid`');
    
CALL add_column_if_not_exists('pbl_courses', 'template_version', 
    'VARCHAR(20) DEFAULT NULL COMMENT \'使用的模板版本\' AFTER `template_id`');
    
CALL add_column_if_not_exists('pbl_courses', 'is_customized', 
    'TINYINT(1) DEFAULT 0 COMMENT \'是否已定制（偏离模板）\' AFTER `template_version`');
    
CALL add_column_if_not_exists('pbl_courses', 'sync_with_template', 
    'TINYINT(1) DEFAULT 1 COMMENT \'是否与模板同步更新\' AFTER `is_customized`');
    
CALL add_column_if_not_exists('pbl_courses', 'customization_notes', 
    'TEXT COMMENT \'定制说明\' AFTER `sync_with_template`');

-- 添加索引（如果不存在）
SET @index_exists = (
    SELECT COUNT(*) FROM information_schema.STATISTICS 
    WHERE TABLE_SCHEMA = DATABASE() 
      AND TABLE_NAME = 'pbl_courses' 
      AND INDEX_NAME = 'idx_template_id'
);

SET @sql = IF(@index_exists = 0,
    'ALTER TABLE `pbl_courses` ADD KEY `idx_template_id` (`template_id`)',
    'SELECT "Index idx_template_id already exists"');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 添加外键（如果不存在）
SET @fk_exists = (
    SELECT COUNT(*) FROM information_schema.KEY_COLUMN_USAGE
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = 'pbl_courses'
      AND CONSTRAINT_NAME = 'fk_course_template'
);

SET @sql = IF(@fk_exists = 0,
    'ALTER TABLE `pbl_courses` ADD CONSTRAINT `fk_course_template` FOREIGN KEY (`template_id`) REFERENCES `pbl_course_templates` (`id`) ON DELETE SET NULL',
    'SELECT "Foreign key fk_course_template already exists"');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;


-- ==========================================================================================================
-- 7. 修改单元表，添加模板关联字段
-- ==========================================================================================================

CALL add_column_if_not_exists('pbl_units', 'template_id', 
    'BIGINT(20) DEFAULT NULL COMMENT \'单元模板ID\' AFTER `uuid`');
    
CALL add_column_if_not_exists('pbl_units', 'is_customized', 
    'TINYINT(1) DEFAULT 0 COMMENT \'是否已定制\' AFTER `template_id`');

-- 添加索引
SET @index_exists = (
    SELECT COUNT(*) FROM information_schema.STATISTICS 
    WHERE TABLE_SCHEMA = DATABASE() 
      AND TABLE_NAME = 'pbl_units' 
      AND INDEX_NAME = 'idx_template_id'
);
SET @sql = IF(@index_exists = 0,
    'ALTER TABLE `pbl_units` ADD KEY `idx_template_id` (`template_id`)',
    'SELECT "Index already exists"');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 添加外键
SET @fk_exists = (
    SELECT COUNT(*) FROM information_schema.KEY_COLUMN_USAGE
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = 'pbl_units'
      AND CONSTRAINT_NAME = 'fk_unit_template'
);
SET @sql = IF(@fk_exists = 0,
    'ALTER TABLE `pbl_units` ADD CONSTRAINT `fk_unit_template` FOREIGN KEY (`template_id`) REFERENCES `pbl_unit_templates` (`id`) ON DELETE SET NULL',
    'SELECT "Foreign key already exists"');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;


-- ==========================================================================================================
-- 8. 修改资源表，添加模板关联字段
-- ==========================================================================================================

CALL add_column_if_not_exists('pbl_resources', 'template_id', 
    'BIGINT(20) DEFAULT NULL COMMENT \'资源模板ID\' AFTER `uuid`');
    
CALL add_column_if_not_exists('pbl_resources', 'is_customized', 
    'TINYINT(1) DEFAULT 0 COMMENT \'是否已定制\' AFTER `template_id`');

-- 添加索引
SET @index_exists = (
    SELECT COUNT(*) FROM information_schema.STATISTICS 
    WHERE TABLE_SCHEMA = DATABASE() 
      AND TABLE_NAME = 'pbl_resources' 
      AND INDEX_NAME = 'idx_template_id'
);
SET @sql = IF(@index_exists = 0,
    'ALTER TABLE `pbl_resources` ADD KEY `idx_template_id` (`template_id`)',
    'SELECT "Index already exists"');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 添加外键
SET @fk_exists = (
    SELECT COUNT(*) FROM information_schema.KEY_COLUMN_USAGE
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = 'pbl_resources'
      AND CONSTRAINT_NAME = 'fk_resource_template'
);
SET @sql = IF(@fk_exists = 0,
    'ALTER TABLE `pbl_resources` ADD CONSTRAINT `fk_resource_template` FOREIGN KEY (`template_id`) REFERENCES `pbl_resource_templates` (`id`) ON DELETE SET NULL',
    'SELECT "Foreign key already exists"');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;


-- ==========================================================================================================
-- 9. 修改任务表，添加模板关联字段
-- ==========================================================================================================

CALL add_column_if_not_exists('pbl_tasks', 'template_id', 
    'BIGINT(20) DEFAULT NULL COMMENT \'任务模板ID\' AFTER `uuid`');
    
CALL add_column_if_not_exists('pbl_tasks', 'is_customized', 
    'TINYINT(1) DEFAULT 0 COMMENT \'是否已定制\' AFTER `template_id`');

-- 添加索引
SET @index_exists = (
    SELECT COUNT(*) FROM information_schema.STATISTICS 
    WHERE TABLE_SCHEMA = DATABASE() 
      AND TABLE_NAME = 'pbl_tasks' 
      AND INDEX_NAME = 'idx_template_id'
);
SET @sql = IF(@index_exists = 0,
    'ALTER TABLE `pbl_tasks` ADD KEY `idx_template_id` (`template_id`)',
    'SELECT "Index already exists"');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 添加外键
SET @fk_exists = (
    SELECT COUNT(*) FROM information_schema.KEY_COLUMN_USAGE
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = 'pbl_tasks'
      AND CONSTRAINT_NAME = 'fk_task_template'
);
SET @sql = IF(@fk_exists = 0,
    'ALTER TABLE `pbl_tasks` ADD CONSTRAINT `fk_task_template` FOREIGN KEY (`template_id`) REFERENCES `pbl_task_templates` (`id`) ON DELETE SET NULL',
    'SELECT "Foreign key already exists"');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 清理临时存储过程
DROP PROCEDURE IF EXISTS add_column_if_not_exists;


-- ==========================================================================================================
-- 10. 创建模板使用记录表（可选，用于统计和审计）
-- ==========================================================================================================

CREATE TABLE IF NOT EXISTS `pbl_template_usage_logs` (
  `id` BIGINT(20) NOT NULL AUTO_INCREMENT PRIMARY KEY COMMENT '记录ID',
  `template_id` BIGINT(20) NOT NULL COMMENT '模板ID',
  `template_type` ENUM('course', 'unit', 'resource', 'task') NOT NULL COMMENT '模板类型',
  `instance_id` BIGINT(20) NOT NULL COMMENT '实例ID（课程/单元/资源/任务ID）',
  `school_id` INT(11) NOT NULL COMMENT '学校ID',
  `creator_id` INT(11) NOT NULL COMMENT '创建者ID',
  `action` ENUM('create', 'update', 'customize', 'sync') NOT NULL COMMENT '操作类型',
  `changes` JSON COMMENT '变更内容',
  `notes` TEXT COMMENT '备注',
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  
  KEY `idx_template` (`template_id`, `template_type`),
  KEY `idx_instance` (`instance_id`, `template_type`),
  KEY `idx_school_id` (`school_id`),
  KEY `idx_creator_id` (`creator_id`),
  KEY `idx_action` (`action`),
  KEY `idx_created_at` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='模板使用记录表';


-- ==========================================================================================================
-- 执行后清理
-- ==========================================================================================================

-- 重新启用外键检查
SET FOREIGN_KEY_CHECKS = 1;

-- 提交事务
COMMIT;


-- ==========================================================================================================
-- 验证脚本执行结果
-- ==========================================================================================================

-- 检查新增的表
SELECT 
    'New Template Tables' AS info_type,
    table_name AS 'Table Name',
    table_rows AS 'Rows',
    ROUND((data_length + index_length) / 1024, 2) AS 'Size (KB)'
FROM information_schema.tables 
WHERE table_schema = DATABASE() 
  AND table_name IN (
    'pbl_course_templates',
    'pbl_unit_templates',
    'pbl_resource_templates',
    'pbl_task_templates',
    'pbl_template_categories',
    'pbl_template_usage_logs'
  )
ORDER BY table_name;

-- 检查修改的表的新增字段
SELECT 
    'Modified Tables - New Columns' AS info_type,
    table_name AS 'Table Name',
    column_name AS 'New Column',
    column_type AS 'Data Type',
    column_comment AS 'Comment'
FROM information_schema.columns
WHERE table_schema = DATABASE()
  AND table_name IN ('pbl_courses', 'pbl_units', 'pbl_resources', 'pbl_tasks')
  AND column_name IN ('template_id', 'template_version', 'is_customized', 'sync_with_template', 'customization_notes')
ORDER BY table_name, ordinal_position;


-- ==========================================================================================================
-- 使用说明
-- ==========================================================================================================

SELECT '==========================================================================================================' AS ' ';

SELECT 'Course Template System Installation Completed!' AS 'Status';

SELECT '==========================================================================================================' AS ' ';

SELECT 'Usage Instructions:' AS ' ';

SELECT '1. 创建模板分类：在 pbl_template_categories 表中添加分类' AS 'Step 1';
SELECT '2. 创建课程模板：在 pbl_course_templates 表中创建模板' AS 'Step 2';
SELECT '3. 添加单元模板：在 pbl_unit_templates 表中添加单元' AS 'Step 3';
SELECT '4. 添加资源和任务模板：完善单元内容' AS 'Step 4';
SELECT '5. 学校创建课程：基于模板创建课程实例，设置 template_id' AS 'Step 5';

SELECT '==========================================================================================================' AS ' ';

SELECT 'Key Features:' AS ' ';

SELECT '✓ 模板与实例分离，便于管理和复用' AS 'Feature 1';
SELECT '✓ 支持版本管理和更新同步' AS 'Feature 2';
SELECT '✓ 支持定制化，学校可修改模板内容' AS 'Feature 3';
SELECT '✓ 完全向后兼容，现有数据不受影响' AS 'Feature 4';
SELECT '✓ 支持分类和标签，便于检索' AS 'Feature 5';

SELECT '==========================================================================================================' AS ' ';

-- ==========================================================================================================
-- 脚本结束
-- ==========================================================================================================
