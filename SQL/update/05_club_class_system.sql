-- ==========================================================================================================
-- 社团班课程系统
-- ==========================================================================================================
-- 
-- 脚本名称: 05_club_class_system.sql
-- 创建日期: 2024-12-11
-- 兼容版本: MySQL 5.7.x, 8.0.x
--
-- ==========================================================================================================
-- ✅ 数据安全性说明:
-- ==========================================================================================================
--
-- 本脚本对现有数据的影响：
--
-- ✅ 安全操作：
--    1. 只创建新表：pbl_class_members（班级成员表）
--    2. 只添加可选字段到现有表（使用 ADD COLUMN IF NOT EXISTS ... DEFAULT NULL）
--    3. 不删除任何数据
--    4. 不修改现有数据（数据迁移部分已注释）
--
-- ⚠️ 需要注意：
--    1. pbl_courses 表添加了 class_id 字段（默认为 NULL，兼容现有课程）
--    2. pbl_course_enrollments 表添加了 class_id 字段（默认为 NULL）
--    3. 数据迁移SQL已注释，需要手动评估是否执行
--
-- 📝 执行建议：
--    1. 可以直接在生产环境执行此脚本（只添加新表和字段）
--    2. 现有课程 class_id 为 NULL，不影响运行
--    3. 新创建的课程需要指定 class_id
--    4. 如需迁移现有数据，请参考脚本末尾的注释SQL
--
-- ==========================================================================================================
-- 核心设计理念:
-- ==========================================================================================================
--
-- 1. 班级 = 社团班（不是行政班级）
--    - 一个学生可以加入多个社团班
--    - 类似于兴趣小组、社团、项目组
--
-- 2. 课程与班级一对一
--    - 每个课程对应一个班级
--    - 多个班级上同一课程 = 创建多个课程实例
--    - 例如：0501班智能体开发、0502班智能体开发
--
-- 3. 学生通过班级获得课程
--    - 学生加入班级 → 自动获得班级的课程
--    - 简单直接，无需额外的标签或选课流程
--
-- ==========================================================================================================

SET NAMES utf8mb4 COLLATE utf8mb4_unicode_ci;
SET FOREIGN_KEY_CHECKS = 0;
START TRANSACTION;

-- ==========================================================================================================
-- 辅助存储过程：安全添加字段（兼容MySQL 5.7）
-- ==========================================================================================================

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

-- ==========================================================================================================
-- 1. 调整班级表（重新定义为社团班）
-- ==========================================================================================================

-- 修改现有的 pbl_classes 表
ALTER TABLE `pbl_classes`
  -- 重新定义用途
  MODIFY COLUMN `name` VARCHAR(100) NOT NULL COMMENT '社团班名称（如：0501班、AI兴趣班）',
  
  -- 简化字段
  MODIFY COLUMN `grade` VARCHAR(50) COMMENT '年级（可选）',
  MODIFY COLUMN `academic_year` VARCHAR(20) COMMENT '学年（可选）',
  MODIFY COLUMN `class_teacher_id` INT(11) COMMENT '班级负责人ID（可选）';

-- 添加社团班特有字段
CALL add_column_if_not_exists('pbl_classes', 'class_type',
    'ENUM(\'club\', \'project\', \'interest\', \'competition\') DEFAULT \'club\' COMMENT \'班级类型：club-社团班，project-项目班，interest-兴趣班，competition-竞赛班\' AFTER `name`');

CALL add_column_if_not_exists('pbl_classes', 'description',
    'TEXT COMMENT \'班级描述\' AFTER `class_type`');

-- 注意：max_students 在原表中已存在，这里添加 current_members 字段
-- 如果 max_students 不存在才会创建（兼容旧版本）
CALL add_column_if_not_exists('pbl_classes', 'max_students',
    'INT(11) DEFAULT 50 COMMENT \'最大学生数\' AFTER `description`');

CALL add_column_if_not_exists('pbl_classes', 'current_members',
    'INT(11) DEFAULT 0 COMMENT \'当前成员数\' AFTER `max_students`');

CALL add_column_if_not_exists('pbl_classes', 'is_open',
    'TINYINT(1) DEFAULT 1 COMMENT \'是否开放（允许学生加入）\' AFTER `is_active`');

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

SET @index_exists = (
    SELECT COUNT(*) FROM information_schema.STATISTICS 
    WHERE TABLE_SCHEMA = DATABASE() 
      AND TABLE_NAME = 'pbl_classes' 
      AND INDEX_NAME = 'idx_is_open'
);
SET @sql = IF(@index_exists = 0,
    'ALTER TABLE `pbl_classes` ADD KEY `idx_is_open` (`is_open`)',
    'SELECT "Index idx_is_open already exists"');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;


-- ==========================================================================================================
-- 2. 创建班级成员表（学生与班级的多对多关系）
-- ==========================================================================================================

CREATE TABLE IF NOT EXISTS `pbl_class_members` (
  `id` BIGINT(20) NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `class_id` INT(11) NOT NULL COMMENT '班级ID',
  `student_id` INT(11) NOT NULL COMMENT '学生ID',
  `role` ENUM('member', 'leader', 'deputy') DEFAULT 'member' 
    COMMENT '角色：member-成员，leader-班长，deputy-副班长',
  `joined_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '加入时间',
  `left_at` TIMESTAMP NULL COMMENT '离开时间（NULL表示仍在班级中）',
  `is_active` TINYINT(1) DEFAULT 1 COMMENT '是否活跃',
  `notes` VARCHAR(500) COMMENT '备注',
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  
  UNIQUE KEY `uk_class_student_active` (`class_id`, `student_id`, `is_active`),
  KEY `idx_class_id` (`class_id`),
  KEY `idx_student_id` (`student_id`),
  KEY `idx_role` (`role`),
  KEY `idx_joined_at` (`joined_at`),
  KEY `idx_left_at` (`left_at`),
  
  CONSTRAINT `fk_member_class` FOREIGN KEY (`class_id`) REFERENCES `pbl_classes` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_member_student` FOREIGN KEY (`student_id`) REFERENCES `core_users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci 
COMMENT='班级成员表（学生可以加入多个班级）';


-- ==========================================================================================================
-- 3. 调整课程表（一个课程对应一个班级，基于模板创建）
-- ==========================================================================================================

-- 先处理 school_id 为 NULL 的记录
-- 检查是否存在 school_id 为 NULL 的课程
SET @null_school_count = (SELECT COUNT(*) FROM pbl_courses WHERE school_id IS NULL);

-- 如果存在 NULL 值，设置为默认值 0（表示未分配学校）
-- 注意：实际生产环境中，应该根据实际情况设置正确的 school_id
UPDATE pbl_courses 
SET school_id = 0 
WHERE school_id IS NULL;

-- 现在可以安全地将 school_id 设置为 NOT NULL
-- 强化班级关联
ALTER TABLE `pbl_courses`
  MODIFY COLUMN `school_id` INT(11) NOT NULL COMMENT '学校ID';

-- 添加字段
CALL add_column_if_not_exists('pbl_courses', 'template_id',
    'BIGINT(20) DEFAULT NULL COMMENT \'课程模板ID（基于哪个模板创建）\' AFTER `uuid`');

CALL add_column_if_not_exists('pbl_courses', 'template_version',
    'VARCHAR(20) DEFAULT NULL COMMENT \'使用的模板版本\' AFTER `template_id`');

CALL add_column_if_not_exists('pbl_courses', 'class_id',
    'INT(11) DEFAULT NULL COMMENT \'班级ID（一个课程对应一个班级，现有课程可为NULL）\' AFTER `school_id`');

CALL add_column_if_not_exists('pbl_courses', 'class_name',
    'VARCHAR(100) COMMENT \'班级名称（冗余字段）\' AFTER `class_id`');

CALL add_column_if_not_exists('pbl_courses', 'is_customized',
    'TINYINT(1) DEFAULT 0 COMMENT \'是否已定制（偏离模板）\' AFTER `class_name`');

CALL add_column_if_not_exists('pbl_courses', 'sync_with_template',
    'TINYINT(1) DEFAULT 1 COMMENT \'是否与模板同步更新\' AFTER `is_customized`');

-- 添加索引
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
      AND INDEX_NAME = 'idx_school_class'
);
SET @sql = IF(@index_exists = 0,
    'ALTER TABLE `pbl_courses` ADD KEY `idx_school_class` (`school_id`, `class_id`)',
    'SELECT "Index idx_school_class already exists"');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 添加外键约束（需要先执行04_add_course_templates.sql）
-- ALTER TABLE `pbl_courses`
--   ADD CONSTRAINT `fk_course_template` FOREIGN KEY (`template_id`) REFERENCES `pbl_course_templates` (`id`) ON DELETE SET NULL,
--   ADD CONSTRAINT `fk_course_class` FOREIGN KEY (`class_id`) REFERENCES `pbl_classes` (`id`) ON DELETE RESTRICT;


-- ==========================================================================================================
-- 4. 调整选课表（兼容现有数据）
-- ==========================================================================================================

-- ⚠️ 注意：不删除或重建选课表，只添加新字段
-- 如果需要完全重构，请先备份数据：
-- CREATE TABLE pbl_course_enrollments_backup AS SELECT * FROM pbl_course_enrollments;

-- 添加班级ID字段
CALL add_column_if_not_exists('pbl_course_enrollments', 'class_id',
    'INT(11) DEFAULT NULL COMMENT \'班级ID（冗余，便于查询，现有数据可为NULL）\' AFTER `user_id`');

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
-- 5. 废弃原来的班级课程关联表
-- ==========================================================================================================

-- 标记为废弃
CALL add_column_if_not_exists('pbl_class_courses', 'is_deprecated',
    'TINYINT(1) DEFAULT 1 COMMENT \'已废弃：新设计中课程直接关联班级\' AFTER `id`');


-- ==========================================================================================================
-- 6. 调整小组表（基于课程和班级）
-- ==========================================================================================================

-- 先检查并处理 course_id 为 NULL 的记录
SET @null_course_groups = (SELECT COUNT(*) FROM pbl_groups WHERE course_id IS NULL);

-- ⚠️ 如果存在 NULL 值，需要先处理这些记录
-- 方案1：如果小组没有成员，可以安全删除
DELETE g FROM pbl_groups g
LEFT JOIN pbl_group_members gm ON gm.group_id = g.id
WHERE g.course_id IS NULL 
  AND gm.id IS NULL;

-- 方案2：如果小组有成员但没有课程，尝试根据 class_id 自动关联课程
-- 注意：此步骤依赖于课程表已经有 class_id 字段
UPDATE pbl_groups g
INNER JOIN pbl_courses c ON c.class_id = g.class_id
SET g.course_id = c.id
WHERE g.course_id IS NULL 
  AND g.class_id IS NOT NULL
LIMIT 1000;  -- 限制更新数量，防止意外大量更新

-- 检查是否还有未处理的 NULL 值
SET @remaining_nulls = (SELECT COUNT(*) FROM pbl_groups WHERE course_id IS NULL);

-- 如果还有 NULL 值，脚本会在后面的 NOT NULL 约束处失败
-- 这是安全机制，确保不会丢失有成员的小组数据

-- 先删除现有的外键约束
SET @fk_exists = (
    SELECT COUNT(*) FROM information_schema.TABLE_CONSTRAINTS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = 'pbl_groups'
      AND CONSTRAINT_NAME = 'fk_groups_course'
      AND CONSTRAINT_TYPE = 'FOREIGN KEY'
);
SET @sql = IF(@fk_exists > 0,
    'ALTER TABLE `pbl_groups` DROP FOREIGN KEY `fk_groups_course`',
    'SELECT "Foreign key fk_groups_course does not exist"');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 修改列定义
ALTER TABLE `pbl_groups`
  -- 保留班级和课程双重关联
  MODIFY COLUMN `class_id` INT(11) COMMENT '班级ID',
  MODIFY COLUMN `course_id` BIGINT(20) NOT NULL COMMENT '课程ID（必填）';

-- 重新创建外键约束（使用 CASCADE，因为小组是课程的一部分）
SET @sql = IF(@fk_exists > 0,
    'ALTER TABLE `pbl_groups` ADD CONSTRAINT `fk_groups_course` FOREIGN KEY (`course_id`) REFERENCES `pbl_courses` (`id`) ON DELETE CASCADE',
    'SELECT "Skip adding foreign key fk_groups_course"');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;


-- ==========================================================================================================
-- 7. 数据迁移（可选，根据实际需要执行）
-- ==========================================================================================================

-- ⚠️ 注意：以下SQL会修改现有数据，请谨慎执行！
-- ⚠️ 建议：在测试环境验证后再在生产环境执行

/*
-- 7.1 将现有的行政班级转换为社团班（可选）
UPDATE pbl_classes 
SET class_type = 'club',
    description = CONCAT(name, '（从行政班级转换）'),
    is_open = 1
WHERE is_active = 1;

-- 7.2 从 core_users.class_id 创建班级成员关系（可选）
INSERT IGNORE INTO pbl_class_members (class_id, student_id, role, joined_at, is_active)
SELECT 
  u.class_id,
  u.id,
  'member',
  NOW(),
  1
FROM core_users u
WHERE u.role = 'student'
  AND u.is_active = 1
  AND u.class_id IS NOT NULL;

-- 7.3 更新班级成员数（可选）
UPDATE pbl_classes c
SET current_members = (
  SELECT COUNT(*) 
  FROM pbl_class_members m 
  WHERE m.class_id = c.id AND m.is_active = 1
);
*/


-- ==========================================================================================================
-- 清理临时存储过程
-- ==========================================================================================================

DROP PROCEDURE IF EXISTS add_column_if_not_exists;


-- ==========================================================================================================
-- 提交
-- ==========================================================================================================

SET FOREIGN_KEY_CHECKS = 1;
COMMIT;


-- ==========================================================================================================
-- 验证和使用说明
-- ==========================================================================================================

SELECT '======================================' AS ' ';
SELECT '社团班课程系统安装完成！' AS 'Status';
SELECT '======================================' AS ' ';

SELECT '核心表：' AS ' ';
SELECT '1. pbl_classes - 班级表（社团班）' AS 'Table 1';
SELECT '2. pbl_class_members - 班级成员表（多对多）' AS 'Table 2';
SELECT '3. pbl_courses - 课程表（新增class_id字段）' AS 'Table 3';
SELECT '4. pbl_course_enrollments - 选课表（简化版）' AS 'Table 4';

SELECT '======================================' AS ' ';
SELECT '使用流程：' AS ' ';
SELECT '' AS ' ';

SELECT '-- Step 1: 创建社团班' AS 'Step 1';
SELECT 'INSERT INTO pbl_classes (uuid, school_id, name, class_type, max_students)' AS 'SQL 1';
SELECT 'VALUES (UUID(), 1, "0501班", "club", 30);' AS 'SQL 1b';
SELECT '' AS ' ';

SELECT '-- Step 2: 添加班级成员' AS 'Step 2';
SELECT 'INSERT INTO pbl_class_members (class_id, student_id, role)' AS 'SQL 2';
SELECT 'VALUES (1, 学生ID, "member");' AS 'SQL 2b';
SELECT '' AS ' ';

SELECT '-- Step 3: 创建课程（指定班级）' AS 'Step 3';
SELECT 'INSERT INTO pbl_courses (uuid, title, school_id, class_id, class_name, creator_id)' AS 'SQL 3';
SELECT 'VALUES (UUID(), "0501班智能体开发", 1, 1, "0501班", 1);' AS 'SQL 3b';
SELECT '' AS ' ';

SELECT '-- Step 4: 自动生成选课记录（班级成员 → 课程）' AS 'Step 4';
SELECT 'INSERT INTO pbl_course_enrollments (course_id, student_id, class_id, status)' AS 'SQL 4';
SELECT 'SELECT c.id, m.student_id, c.class_id, "active"' AS 'SQL 4b';
SELECT 'FROM pbl_courses c' AS 'SQL 4c';
SELECT 'INNER JOIN pbl_class_members m ON m.class_id = c.class_id' AS 'SQL 4d';
SELECT 'WHERE c.id = 课程ID AND m.is_active = 1;' AS 'SQL 4e';

SELECT '======================================' AS ' ';

-- ==========================================================================================================
-- 脚本结束
-- ==========================================================================================================
