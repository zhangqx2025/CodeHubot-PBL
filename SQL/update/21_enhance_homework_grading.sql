-- ==========================================================================================================
-- 增强作业批改功能
-- ==========================================================================================================
-- 文件: 21_enhance_homework_grading.sql
-- 版本: 1.0.0
-- 创建日期: 2025-12-13
-- 兼容版本: MySQL 5.7-8.0
-- 说明: 
--   1. 为 pbl_task_progress 表添加作业等级字段 (grade)
--   2. 创建评语模板表 (pbl_feedback_templates)
--   3. 优化作业批改功能，支持等级评定和评语模板
--   4. 本脚本支持重复执行
-- ==========================================================================================================

SET NAMES utf8mb4 COLLATE utf8mb4_unicode_ci;

-- ==========================================================================================================
-- 1. 为 pbl_task_progress 表添加等级字段（使用动态SQL，支持重复执行）
-- ==========================================================================================================

-- 检查 grade 字段是否存在，如果不存在则添加
SET @column_exists = (
    SELECT COUNT(*) 
    FROM information_schema.COLUMNS 
    WHERE TABLE_SCHEMA = DATABASE() 
    AND TABLE_NAME = 'pbl_task_progress' 
    AND COLUMN_NAME = 'grade'
);

SET @sql = IF(@column_exists = 0,
    "ALTER TABLE `pbl_task_progress` ADD COLUMN `grade` ENUM('excellent', 'good', 'pass', 'fail') DEFAULT NULL COMMENT '作业等级：excellent-优秀，good-良好，pass-及格，fail-不及格' AFTER `score`",
    'SELECT "⊙ 字段 grade 已存在，跳过" AS result'
);

PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SELECT '✓ pbl_task_progress 表字段添加完成' AS '';

-- ==========================================================================================================
-- 2. 创建评语模板表
-- ==========================================================================================================

-- 创建评语模板表（如果不存在）
CREATE TABLE IF NOT EXISTS `pbl_feedback_templates` (
  `id` BIGINT(20) NOT NULL AUTO_INCREMENT COMMENT '模板ID',
  `uuid` VARCHAR(36) NOT NULL COMMENT 'UUID，唯一标识',
  `school_id` INT(11) NOT NULL COMMENT '学校ID',
  `category` VARCHAR(50) NOT NULL COMMENT '模板分类：general-通用，excellent-优秀，good-良好，pass-及格，fail-不及格',
  `title` VARCHAR(100) NOT NULL COMMENT '模板标题',
  `content` TEXT NOT NULL COMMENT '模板内容',
  `is_active` TINYINT(1) NOT NULL DEFAULT 1 COMMENT '是否启用：1-启用，0-禁用',
  `created_by` INT(11) DEFAULT NULL COMMENT '创建者ID',
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_uuid` (`uuid`),
  KEY `idx_school_id` (`school_id`),
  KEY `idx_category` (`category`),
  KEY `idx_is_active` (`is_active`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='PBL评语模板表';

SELECT '✓ pbl_feedback_templates 表创建完成' AS '';

-- ==========================================================================================================
-- 3. 插入默认评语模板
-- ==========================================================================================================

-- 清除可能存在的临时表
DROP TEMPORARY TABLE IF EXISTS temp_school_ids;

-- 创建临时表存储学校ID
CREATE TEMPORARY TABLE temp_school_ids AS
SELECT DISTINCT school_id 
FROM pbl_classes
WHERE school_id IS NOT NULL;

-- 为每个学校插入默认评语模板
INSERT INTO `pbl_feedback_templates` (`uuid`, `school_id`, `category`, `title`, `content`, `is_active`, `created_at`, `updated_at`)
SELECT 
    UUID(),
    ts.school_id,
    '优秀' AS category,
    '优秀-全面完成' AS title,
    '作业完成度高，思路清晰，逻辑严谨，展现了扎实的基础知识和较强的实践能力。继续保持！' AS content,
    1,
    NOW(),
    NOW()
FROM temp_school_ids ts
WHERE NOT EXISTS (
    SELECT 1 FROM pbl_feedback_templates 
    WHERE school_id = ts.school_id AND category = '优秀' AND title = '优秀-全面完成'
);

INSERT INTO `pbl_feedback_templates` (`uuid`, `school_id`, `category`, `title`, `content`, `is_active`, `created_at`, `updated_at`)
SELECT 
    UUID(),
    ts.school_id,
    '优秀' AS category,
    '优秀-创新突出' AS title,
    '作业展现了很强的创新意识和独立思考能力，解决方案独特且有效。非常优秀！' AS content,
    1,
    NOW(),
    NOW()
FROM temp_school_ids ts
WHERE NOT EXISTS (
    SELECT 1 FROM pbl_feedback_templates 
    WHERE school_id = ts.school_id AND category = '优秀' AND title = '优秀-创新突出'
);

INSERT INTO `pbl_feedback_templates` (`uuid`, `school_id`, `category`, `title`, `content`, `is_active`, `created_at`, `updated_at`)
SELECT 
    UUID(),
    ts.school_id,
    '良好' AS category,
    '良好-基本完成' AS title,
    '作业完成较好，基本达到要求，思路清晰。如果能在细节上更加完善，会更加出色。' AS content,
    1,
    NOW(),
    NOW()
FROM temp_school_ids ts
WHERE NOT EXISTS (
    SELECT 1 FROM pbl_feedback_templates 
    WHERE school_id = ts.school_id AND category = '良好' AND title = '良好-基本完成'
);

INSERT INTO `pbl_feedback_templates` (`uuid`, `school_id`, `category`, `title`, `content`, `is_active`, `created_at`, `updated_at`)
SELECT 
    UUID(),
    ts.school_id,
    '良好' AS category,
    '良好-需改进' AS title,
    '作业完成度不错，但在某些环节还有提升空间。建议加强对细节的把控，进一步优化解决方案。' AS content,
    1,
    NOW(),
    NOW()
FROM temp_school_ids ts
WHERE NOT EXISTS (
    SELECT 1 FROM pbl_feedback_templates 
    WHERE school_id = ts.school_id AND category = '良好' AND title = '良好-需改进'
);

INSERT INTO `pbl_feedback_templates` (`uuid`, `school_id`, `category`, `title`, `content`, `is_active`, `created_at`, `updated_at`)
SELECT 
    UUID(),
    ts.school_id,
    '及格' AS category,
    '及格-基本合格' AS title,
    '作业基本符合要求，但存在一些不足之处。建议进一步学习相关知识，加强练习。' AS content,
    1,
    NOW(),
    NOW()
FROM temp_school_ids ts
WHERE NOT EXISTS (
    SELECT 1 FROM pbl_feedback_templates 
    WHERE school_id = ts.school_id AND category = '及格' AND title = '及格-基本合格'
);

INSERT INTO `pbl_feedback_templates` (`uuid`, `school_id`, `category`, `title`, `content`, `is_active`, `created_at`, `updated_at`)
SELECT 
    UUID(),
    ts.school_id,
    '及格' AS category,
    '及格-需努力' AS title,
    '作业刚刚达到及格线，还有较大提升空间。建议加强基础知识学习，多做练习，遇到问题及时请教老师。' AS content,
    1,
    NOW(),
    NOW()
FROM temp_school_ids ts
WHERE NOT EXISTS (
    SELECT 1 FROM pbl_feedback_templates 
    WHERE school_id = ts.school_id AND category = '及格' AND title = '及格-需努力'
);

INSERT INTO `pbl_feedback_templates` (`uuid`, `school_id`, `category`, `title`, `content`, `is_active`, `created_at`, `updated_at`)
SELECT 
    UUID(),
    ts.school_id,
    '不及格' AS category,
    '不及格-需重做' AS title,
    '作业未达到要求，存在较多问题。建议重新审题，加强基础知识学习，完成后重新提交。' AS content,
    1,
    NOW(),
    NOW()
FROM temp_school_ids ts
WHERE NOT EXISTS (
    SELECT 1 FROM pbl_feedback_templates 
    WHERE school_id = ts.school_id AND category = '不及格' AND title = '不及格-需重做'
);

INSERT INTO `pbl_feedback_templates` (`uuid`, `school_id`, `category`, `title`, `content`, `is_active`, `created_at`, `updated_at`)
SELECT 
    UUID(),
    ts.school_id,
    '不及格' AS category,
    '不及格-未完成' AS title,
    '作业未完成或严重偏离要求。请认真对待作业，仔细阅读要求，如有困难请及时向老师求助。' AS content,
    1,
    NOW(),
    NOW()
FROM temp_school_ids ts
WHERE NOT EXISTS (
    SELECT 1 FROM pbl_feedback_templates 
    WHERE school_id = ts.school_id AND category = '不及格' AND title = '不及格-未完成'
);

-- 清理临时表
DROP TEMPORARY TABLE IF EXISTS temp_school_ids;

SELECT '✓ 默认评语模板插入完成' AS '';

-- ==========================================================================================================
-- 4. 验证和显示结果
-- ==========================================================================================================

-- 显示 pbl_task_progress 表新增字段
SELECT '=== pbl_task_progress 表新增字段 ===' AS '';

SELECT
    COLUMN_NAME,
    COLUMN_TYPE,
    IS_NULLABLE,
    COLUMN_DEFAULT,
    COLUMN_COMMENT
FROM information_schema.COLUMNS
WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'pbl_task_progress'
    AND COLUMN_NAME = 'grade'
ORDER BY ORDINAL_POSITION;

-- 显示评语模板统计（先检查表是否存在）
SELECT '=== 评语模板统计 ===' AS '';

SET @table_exists = (
    SELECT COUNT(*) 
    FROM information_schema.TABLES 
    WHERE TABLE_SCHEMA = DATABASE() 
    AND TABLE_NAME = 'pbl_feedback_templates'
);

SET @sql = IF(@table_exists > 0,
    "SELECT category AS '分类', COUNT(*) AS '模板数量' FROM pbl_feedback_templates WHERE is_active = 1 GROUP BY category ORDER BY FIELD(category, '优秀', '良好', '及格', '不及格')",
    'SELECT "⊙ pbl_feedback_templates 表不存在" AS result'
);

PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SELECT '✓ 脚本执行完成！' AS result;

-- ==========================================================================================================
-- 执行完成
-- ==========================================================================================================
