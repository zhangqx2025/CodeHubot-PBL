-- ==========================================================================================================
-- 社团班课程系统数据库升级脚本
-- ==========================================================================================================
--
-- 脚本名称: 08_add_club_class_system.sql
-- 脚本版本: 1.0.0
-- 创建日期: 2025-12-11
-- 兼容版本: MySQL 5.7.x, 8.0.x
--
-- 脚本说明:
--   本脚本用于升级数据库以支持社团班课程系统，核心理念:
--   - 班级 = 社团班（不是行政班级）
--   - 一个学生可以加入多个班级（多对多关系）
--   - 一个课程对应一个班级（一对一关系）
--   - 学生通过班级自动获得课程（简单直接）
--
-- 主要变更:
--   1. 创建 pbl_class_members 表（班级成员多对多关系）
--   2. 修改 pbl_classes 表，添加社团班相关字段
--   3. 修改 pbl_courses 表，添加班级关联字段
--   4. 修改 pbl_course_enrollments 表，添加班级关联字段
--   5. 创建 pbl_course_templates 表（课程模板）
--
-- 使用方式:
--   mysql -h hostname -u username -p --default-character-set=utf8mb4 aiot_admin < 08_add_club_class_system.sql
--
-- ==========================================================================================================

-- 设置环境
SET NAMES utf8mb4 COLLATE utf8mb4_unicode_ci;
SET SQL_MODE = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION';
SET FOREIGN_KEY_CHECKS = 0;
SET UNIQUE_CHECKS = 0;

-- 开始事务
START TRANSACTION;

-- ==========================================================================================================
-- 1. 修改 pbl_classes 表 - 添加社团班相关字段
-- ==========================================================================================================

-- 创建临时存储过程用于添加字段（MySQL 5.7兼容）
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

-- 添加班级类型字段
CALL add_column_if_not_exists('pbl_classes', 'class_type',
    "ENUM('club', 'project', 'interest', 'competition', 'regular') DEFAULT 'regular' COMMENT '班级类型：club-社团班, project-项目班, interest-兴趣班, competition-竞赛班, regular-普通班' AFTER `name`");

-- 添加班级描述字段
CALL add_column_if_not_exists('pbl_classes', 'description',
    "TEXT COMMENT '班级描述' AFTER `class_type`");

-- 添加当前成员数字段
CALL add_column_if_not_exists('pbl_classes', 'current_members',
    "INT(11) DEFAULT 0 COMMENT '当前成员数' AFTER `max_students`");

-- 添加是否开放加入字段
CALL add_column_if_not_exists('pbl_classes', 'is_open',
    "TINYINT(1) DEFAULT 1 COMMENT '是否开放加入' AFTER `is_active`");

-- 添加索引
SET @index_exists = (
    SELECT COUNT(*) FROM information_schema.STATISTICS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = 'pbl_classes'
      AND INDEX_NAME = 'idx_class_type'
);
SET @sql = IF(@index_exists = 0,
    'ALTER TABLE `pbl_classes` ADD KEY `idx_class_type` (`class_type`)',
    'SELECT "Index idx_class_type already exists"');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- ==========================================================================================================
-- 2. 创建 pbl_class_members 表 - 班级成员多对多关系表
-- ==========================================================================================================

CREATE TABLE IF NOT EXISTS `pbl_class_members` (
  `id` INT(11) NOT NULL AUTO_INCREMENT COMMENT '成员记录ID',
  `class_id` INT(11) NOT NULL COMMENT '班级ID',
  `student_id` INT(11) NOT NULL COMMENT '学生ID',
  `role` ENUM('member', 'leader', 'deputy') DEFAULT 'member' COMMENT '成员角色：member-成员, leader-班长, deputy-副班长',
  `joined_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP COMMENT '加入时间',
  `left_at` TIMESTAMP NULL DEFAULT NULL COMMENT '离开时间（NULL表示仍在班级）',
  `is_active` TINYINT(1) DEFAULT 1 COMMENT '是否活跃（1-在班, 0-已离开）',
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_class_student_active` (`class_id`, `student_id`, `is_active`),
  KEY `idx_class_id` (`class_id`),
  KEY `idx_student_id` (`student_id`),
  KEY `idx_role` (`role`),
  KEY `idx_is_active` (`is_active`),
  CONSTRAINT `fk_class_members_class` FOREIGN KEY (`class_id`) REFERENCES `pbl_classes` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_class_members_student` FOREIGN KEY (`student_id`) REFERENCES `core_users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='PBL班级成员表（多对多关系）';

-- ==========================================================================================================
-- 3. 修改 pbl_courses 表 - 添加班级关联字段
-- ==========================================================================================================

-- 添加班级ID字段
CALL add_column_if_not_exists('pbl_courses', 'class_id',
    "INT(11) DEFAULT NULL COMMENT '关联班级ID（一个课程对应一个班级）' AFTER `uuid`");

-- 添加班级名称字段（冗余字段，便于查询）
CALL add_column_if_not_exists('pbl_courses', 'class_name',
    "VARCHAR(100) DEFAULT NULL COMMENT '班级名称（冗余字段）' AFTER `class_id`");

-- 添加课程模板ID字段
CALL add_column_if_not_exists('pbl_courses', 'template_id',
    "BIGINT(20) DEFAULT NULL COMMENT '课程模板ID' AFTER `uuid`");

-- 添加模板版本字段
CALL add_column_if_not_exists('pbl_courses', 'template_version',
    "VARCHAR(20) DEFAULT NULL COMMENT '使用的模板版本' AFTER `template_id`");

-- 添加是否定制化字段
CALL add_column_if_not_exists('pbl_courses', 'is_customized',
    "TINYINT(1) DEFAULT 0 COMMENT '是否定制化（相对于模板）' AFTER `template_version`");

-- 添加是否同步模板字段
CALL add_column_if_not_exists('pbl_courses', 'sync_with_template',
    "TINYINT(1) DEFAULT 1 COMMENT '是否与模板同步' AFTER `is_customized`");

-- 添加索引
SET @index_exists = (
    SELECT COUNT(*) FROM information_schema.STATISTICS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = 'pbl_courses'
      AND INDEX_NAME = 'idx_class_id'
);
SET @sql = IF(@index_exists = 0,
    'ALTER TABLE `pbl_courses` ADD KEY `idx_class_id` (`class_id`)',
    'SELECT "Index idx_class_id already exists"');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

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

-- ==========================================================================================================
-- 4. 修改 pbl_course_enrollments 表 - 添加班级关联字段
-- ==========================================================================================================

-- 添加班级ID字段（记录学生通过哪个班级获得的课程）
CALL add_column_if_not_exists('pbl_course_enrollments', 'class_id',
    "INT(11) DEFAULT NULL COMMENT '通过哪个班级获得此课程' AFTER `user_id`");

-- 修改状态字段默认值
SET @column_exists = (
    SELECT COUNT(*) FROM information_schema.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = 'pbl_course_enrollments'
      AND COLUMN_NAME = 'status'
);
SET @sql = IF(@column_exists > 0,
    "ALTER TABLE `pbl_course_enrollments` CHANGE COLUMN `enrollment_status` `status` ENUM('active', 'completed', 'dropped') DEFAULT 'active' COMMENT '状态：active-进行中, completed-已完成, dropped-已退出'",
    'SELECT "Column status not found"');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 添加索引
SET @index_exists = (
    SELECT COUNT(*) FROM information_schema.STATISTICS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = 'pbl_course_enrollments'
      AND INDEX_NAME = 'idx_class_id'
);
SET @sql = IF(@index_exists = 0,
    'ALTER TABLE `pbl_course_enrollments` ADD KEY `idx_class_id` (`class_id`)',
    'SELECT "Index idx_class_id already exists"');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- ==========================================================================================================
-- 5. 创建 pbl_course_templates 表 - 课程模板表
-- ==========================================================================================================

CREATE TABLE IF NOT EXISTS `pbl_course_templates` (
  `id` BIGINT(20) NOT NULL AUTO_INCREMENT COMMENT '模板ID',
  `uuid` VARCHAR(36) NOT NULL COMMENT 'UUID，唯一标识',
  `name` VARCHAR(200) NOT NULL COMMENT '模板名称',
  `description` TEXT COMMENT '模板描述',
  `cover_image` VARCHAR(255) DEFAULT NULL COMMENT '封面图URL',
  `duration` VARCHAR(50) DEFAULT NULL COMMENT '预计时长',
  `difficulty` ENUM('beginner', 'intermediate', 'advanced') DEFAULT 'beginner' COMMENT '难度等级',
  `category` VARCHAR(50) DEFAULT NULL COMMENT '分类（如：AI开发、机器人、编程基础等）',
  `version` VARCHAR(20) DEFAULT '1.0.0' COMMENT '当前版本',
  `is_public` TINYINT(1) DEFAULT 1 COMMENT '是否公开（可被学校使用）',
  `creator_id` INT(11) DEFAULT NULL COMMENT '创建者ID',
  `usage_count` INT(11) DEFAULT 0 COMMENT '使用次数',
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_uuid` (`uuid`),
  KEY `idx_category` (`category`),
  KEY `idx_difficulty` (`difficulty`),
  KEY `idx_is_public` (`is_public`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='PBL课程模板表';

-- ==========================================================================================================
-- 6. 修改 pbl_class_courses 表 - 简化班级课程关联
-- ==========================================================================================================

-- 该表主要用于记录课程分配历史，课程本身已通过 class_id 关联到班级
-- 添加自动选课字段
CALL add_column_if_not_exists('pbl_class_courses', 'auto_enroll',
    "TINYINT(1) DEFAULT 1 COMMENT '是否自动为班级成员选课' AFTER `course_id`");

-- ==========================================================================================================
-- 7. 创建触发器 - 自动更新班级成员数
-- ==========================================================================================================

-- 删除已存在的触发器
DROP TRIGGER IF EXISTS `trg_class_members_after_insert`;
DROP TRIGGER IF EXISTS `trg_class_members_after_update`;
DROP TRIGGER IF EXISTS `trg_class_members_after_delete`;

-- 添加成员时更新班级成员数
DELIMITER $$
CREATE TRIGGER `trg_class_members_after_insert`
AFTER INSERT ON `pbl_class_members`
FOR EACH ROW
BEGIN
    IF NEW.is_active = 1 THEN
        UPDATE `pbl_classes`
        SET `current_members` = (
            SELECT COUNT(*)
            FROM `pbl_class_members`
            WHERE `class_id` = NEW.class_id AND `is_active` = 1
        )
        WHERE `id` = NEW.class_id;
    END IF;
END$$
DELIMITER ;

-- 更新成员状态时更新班级成员数
DELIMITER $$
CREATE TRIGGER `trg_class_members_after_update`
AFTER UPDATE ON `pbl_class_members`
FOR EACH ROW
BEGIN
    IF OLD.is_active != NEW.is_active THEN
        UPDATE `pbl_classes`
        SET `current_members` = (
            SELECT COUNT(*)
            FROM `pbl_class_members`
            WHERE `class_id` = NEW.class_id AND `is_active` = 1
        )
        WHERE `id` = NEW.class_id;
    END IF;
END$$
DELIMITER ;

-- 删除成员时更新班级成员数
DELIMITER $$
CREATE TRIGGER `trg_class_members_after_delete`
AFTER DELETE ON `pbl_class_members`
FOR EACH ROW
BEGIN
    IF OLD.is_active = 1 THEN
        UPDATE `pbl_classes`
        SET `current_members` = (
            SELECT COUNT(*)
            FROM `pbl_class_members`
            WHERE `class_id` = OLD.class_id AND `is_active` = 1
        )
        WHERE `id` = OLD.class_id;
    END IF;
END$$
DELIMITER ;

-- ==========================================================================================================
-- 清理临时存储过程
-- ==========================================================================================================

DROP PROCEDURE IF EXISTS add_column_if_not_exists;

-- 恢复设置
SET FOREIGN_KEY_CHECKS = 1;
SET UNIQUE_CHECKS = 1;

-- 提交事务
COMMIT;

-- ==========================================================================================================
-- 验证脚本执行结果
-- ==========================================================================================================

SELECT 'Verifying pbl_class_members table...' AS status;
SELECT 
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = DATABASE() AND table_name = 'pbl_class_members') 
        THEN '✓ pbl_class_members table created successfully'
        ELSE '✗ ERROR: pbl_class_members table not found'
    END AS verification;

SELECT 'Verifying pbl_classes columns...' AS status;
SELECT 
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'pbl_classes' AND COLUMN_NAME = 'class_type') 
        THEN '✓ class_type column added'
        ELSE '✗ ERROR: class_type column not found'
    END AS verification;

SELECT 'Verifying pbl_courses columns...' AS status;
SELECT 
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'pbl_courses' AND COLUMN_NAME = 'class_id') 
        THEN '✓ class_id column added'
        ELSE '✗ ERROR: class_id column not found'
    END AS verification;

SELECT 'Verifying pbl_course_templates table...' AS status;
SELECT 
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = DATABASE() AND table_name = 'pbl_course_templates') 
        THEN '✓ pbl_course_templates table created successfully'
        ELSE '✗ ERROR: pbl_course_templates table not found'
    END AS verification;

SELECT 
    '==========================================================================================================' AS ' ';

SELECT 
    'Club Class System Database Upgrade Completed!' AS 'Status',
    VERSION() AS 'MySQL Version',
    DATABASE() AS 'Database Name',
    NOW() AS 'Completion Time';

SELECT 
    '==========================================================================================================' AS ' ';

-- ==========================================================================================================
-- 脚本结束
-- ==========================================================================================================
