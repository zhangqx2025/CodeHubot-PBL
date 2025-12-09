-- ==========================================
-- 21. 增强学校管理功能
-- ==========================================
-- 说明：
--   为学校管理功能添加必要的字段和索引
--   支持以下功能：
--   1. 学校创建和管理
--   2. 学校管理员分配
--   3. 教师和学生容量限制
--   4. 课程分配到学校
--   5. 账号批量导入
-- ==========================================

USE aiot_admin;

-- 1. 确保 aiot_schools 表有必要的字段
-- 检查并添加当前教师数和学生数统计字段
SET @column_exists = (
    SELECT COUNT(*) 
    FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'aiot_schools'
    AND COLUMN_NAME = 'current_teachers'
);

SET @sql = IF(
    @column_exists = 0,
    'ALTER TABLE `aiot_schools` 
     ADD COLUMN `current_teachers` INT(11) DEFAULT 0 COMMENT ''当前教师数'' AFTER `max_teachers`,
     ADD COLUMN `current_students` INT(11) DEFAULT 0 COMMENT ''当前学生数'' AFTER `max_students`',
    'SELECT ''Columns current_teachers and current_students already exist'' AS message'
);

PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 2. 为 aiot_schools 表添加管理员信息字段
SET @column_exists = (
    SELECT COUNT(*) 
    FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'aiot_schools'
    AND COLUMN_NAME = 'admin_user_id'
);

SET @sql = IF(
    @column_exists = 0,
    'ALTER TABLE `aiot_schools` 
     ADD COLUMN `admin_user_id` INT(11) DEFAULT NULL COMMENT ''学校管理员用户ID'' AFTER `contact_email`,
     ADD COLUMN `admin_username` VARCHAR(100) DEFAULT NULL COMMENT ''学校管理员用户名'' AFTER `admin_user_id`',
    'SELECT ''Columns admin_user_id and admin_username already exist'' AS message'
);

PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 3. 添加学校状态描述字段
SET @column_exists = (
    SELECT COUNT(*) 
    FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'aiot_schools'
    AND COLUMN_NAME = 'description'
);

SET @sql = IF(
    @column_exists = 0,
    'ALTER TABLE `aiot_schools` 
     ADD COLUMN `description` TEXT COMMENT ''学校描述'' AFTER `school_name`',
    'SELECT ''Column description already exists'' AS message'
);

PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 4. 添加学校索引以优化查询
SET @index_exists = (
    SELECT COUNT(*)
    FROM INFORMATION_SCHEMA.STATISTICS
    WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'aiot_schools'
    AND INDEX_NAME = 'idx_is_active'
);

SET @sql = IF(
    @index_exists = 0,
    'ALTER TABLE `aiot_schools` ADD KEY `idx_is_active` (`is_active`)',
    'SELECT ''Index idx_is_active already exists'' AS message'
);

PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 5. 添加学校代码索引
SET @index_exists = (
    SELECT COUNT(*)
    FROM INFORMATION_SCHEMA.STATISTICS
    WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'aiot_schools'
    AND INDEX_NAME = 'uk_school_code'
);

SET @sql = IF(
    @index_exists = 0,
    'ALTER TABLE `aiot_schools` ADD UNIQUE KEY `uk_school_code` (`school_code`)',
    'SELECT ''Index uk_school_code already exists'' AS message'
);

PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 6. 为 aiot_core_users 表添加导入批次字段（用于批量导入追踪）
SET @column_exists = (
    SELECT COUNT(*) 
    FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'aiot_core_users'
    AND COLUMN_NAME = 'import_batch_id'
);

SET @sql = IF(
    @column_exists = 0,
    'ALTER TABLE `aiot_core_users` 
     ADD COLUMN `import_batch_id` VARCHAR(50) DEFAULT NULL COMMENT ''批量导入批次ID'' AFTER `student_number`,
     ADD COLUMN `import_time` DATETIME DEFAULT NULL COMMENT ''导入时间'' AFTER `import_batch_id`',
    'SELECT ''Columns import_batch_id and import_time already exist'' AS message'
);

PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 7. 添加用户角色和学校ID的组合索引
SET @index_exists = (
    SELECT COUNT(*)
    FROM INFORMATION_SCHEMA.STATISTICS
    WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'aiot_core_users'
    AND INDEX_NAME = 'idx_school_role'
);

SET @sql = IF(
    @index_exists = 0,
    'ALTER TABLE `aiot_core_users` ADD KEY `idx_school_role` (`school_id`, `role`)',
    'SELECT ''Index idx_school_role already exists'' AS message'
);

PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 8. 创建批量导入日志表
CREATE TABLE IF NOT EXISTS `pbl_import_logs` (
  `id` BIGINT(20) NOT NULL AUTO_INCREMENT COMMENT '日志ID',
  `uuid` VARCHAR(36) NOT NULL COMMENT 'UUID',
  `batch_id` VARCHAR(50) NOT NULL COMMENT '批次ID',
  `import_type` ENUM('student', 'teacher') NOT NULL COMMENT '导入类型',
  `school_id` INT(11) NOT NULL COMMENT '学校ID',
  `operator_id` INT(11) NOT NULL COMMENT '操作人ID',
  `operator_name` VARCHAR(100) DEFAULT NULL COMMENT '操作人姓名',
  `file_name` VARCHAR(255) DEFAULT NULL COMMENT '导入文件名',
  `total_count` INT(11) DEFAULT 0 COMMENT '总记录数',
  `success_count` INT(11) DEFAULT 0 COMMENT '成功数',
  `failed_count` INT(11) DEFAULT 0 COMMENT '失败数',
  `error_message` TEXT COMMENT '错误信息',
  `status` ENUM('processing', 'completed', 'failed') DEFAULT 'processing' COMMENT '状态',
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `completed_at` TIMESTAMP NULL DEFAULT NULL COMMENT '完成时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_uuid` (`uuid`),
  UNIQUE KEY `uk_batch_id` (`batch_id`),
  KEY `idx_school_id` (`school_id`),
  KEY `idx_operator_id` (`operator_id`),
  KEY `idx_import_type` (`import_type`),
  KEY `idx_created_at` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='批量导入日志表';

-- 9. 更新现有学校的教师和学生计数
UPDATE `aiot_schools` s
SET 
  `current_teachers` = (
    SELECT COUNT(*) 
    FROM `aiot_core_users` u 
    WHERE u.school_id = s.id 
      AND u.role IN ('teacher', 'school_admin')
      AND u.deleted_at IS NULL
      AND u.is_active = 1
  ),
  `current_students` = (
    SELECT COUNT(*) 
    FROM `aiot_core_users` u 
    WHERE u.school_id = s.id 
      AND u.role = 'student'
      AND u.deleted_at IS NULL
      AND u.is_active = 1
  )
WHERE s.id > 0;

-- 10. 为学校添加管理员信息（如果存在学校管理员）
UPDATE `aiot_schools` s
INNER JOIN (
  SELECT school_id, id, username
  FROM `aiot_core_users`
  WHERE role = 'school_admin'
    AND deleted_at IS NULL
    AND is_active = 1
  GROUP BY school_id
) u ON s.id = u.school_id
SET 
  s.admin_user_id = u.id,
  s.admin_username = u.username
WHERE s.admin_user_id IS NULL;

-- 11. 为学校添加视频权限控制字段
SET @column_exists = (
    SELECT COUNT(*) 
    FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'aiot_schools'
    AND COLUMN_NAME = 'video_student_view_limit'
);

SET @sql = IF(
    @column_exists = 0,
    'ALTER TABLE `aiot_schools` 
     ADD COLUMN `video_student_view_limit` INT(11) DEFAULT NULL COMMENT ''学生视频观看次数限制（NULL表示不限制）'' AFTER `admin_username`,
     ADD COLUMN `video_teacher_view_limit` INT(11) DEFAULT NULL COMMENT ''教师视频观看次数限制（NULL表示不限制）'' AFTER `video_student_view_limit`',
    'SELECT ''Columns video_student_view_limit and video_teacher_view_limit already exist'' AS message'
);

PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 完成
SELECT '学校管理功能增强完成（含视频权限控制）' AS message;

-- 显示统计信息
SELECT 
  '学校数量' AS metric,
  COUNT(*) AS value
FROM `aiot_schools`
WHERE is_active = 1;

SELECT 
  s.school_name,
  s.current_teachers,
  s.max_teachers,
  s.current_students,
  s.max_students,
  s.admin_username
FROM `aiot_schools` s
WHERE s.is_active = 1
ORDER BY s.created_at DESC
LIMIT 10;
