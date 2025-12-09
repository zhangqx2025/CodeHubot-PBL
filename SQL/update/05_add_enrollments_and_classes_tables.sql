-- =============================================
-- 05_add_enrollments_and_classes_tables.sql
-- 添加选课管理和班级小组管理相关表
-- 创建时间: 2024-12-08
-- =============================================

-- 1. 创建班级表
CREATE TABLE IF NOT EXISTS `pbl_classes` (
  `id` INT NOT NULL AUTO_INCREMENT COMMENT '班级ID',
  `uuid` VARCHAR(36) NOT NULL COMMENT 'UUID唯一标识',
  `school_id` INT NOT NULL COMMENT '所属学校ID',
  `name` VARCHAR(100) NOT NULL COMMENT '班级名称',
  `grade` VARCHAR(50) DEFAULT NULL COMMENT '年级',
  `academic_year` VARCHAR(20) DEFAULT NULL COMMENT '学年（如：2024-2025）',
  `class_teacher_id` INT DEFAULT NULL COMMENT '班主任ID',
  `max_students` INT DEFAULT 50 COMMENT '最大学生数',
  `is_active` TINYINT(1) DEFAULT 1 COMMENT '是否激活',
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_uuid` (`uuid`),
  KEY `idx_school_id` (`school_id`),
  KEY `idx_name` (`name`),
  KEY `idx_grade` (`grade`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='PBL班级表';

-- 2. 创建小组表
CREATE TABLE IF NOT EXISTS `pbl_groups` (
  `id` INT NOT NULL AUTO_INCREMENT COMMENT '小组ID',
  `uuid` VARCHAR(36) NOT NULL COMMENT 'UUID唯一标识',
  `class_id` INT DEFAULT NULL COMMENT '所属班级ID',
  `course_id` BIGINT(20) DEFAULT NULL COMMENT '所属课程ID',
  `name` VARCHAR(100) NOT NULL COMMENT '小组名称',
  `description` TEXT COMMENT '小组描述',
  `leader_id` INT DEFAULT NULL COMMENT '组长ID',
  `max_members` INT DEFAULT 6 COMMENT '最大成员数',
  `is_active` TINYINT(1) DEFAULT 1 COMMENT '是否激活',
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_uuid` (`uuid`),
  KEY `idx_class_id` (`class_id`),
  KEY `idx_course_id` (`course_id`),
  KEY `idx_name` (`name`),
  CONSTRAINT `fk_groups_class` FOREIGN KEY (`class_id`) REFERENCES `pbl_classes` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_groups_course` FOREIGN KEY (`course_id`) REFERENCES `pbl_courses` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='PBL学习小组表';

-- 3. 创建选课记录表
CREATE TABLE IF NOT EXISTS `pbl_course_enrollments` (
  `id` INT NOT NULL AUTO_INCREMENT COMMENT '选课记录ID',
  `course_id` BIGINT(20) NOT NULL COMMENT '课程ID',
  `user_id` INT NOT NULL COMMENT '学生ID',
  `enrollment_status` ENUM('enrolled', 'dropped', 'completed') DEFAULT 'enrolled' COMMENT '选课状态',
  `enrolled_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '选课时间',
  `dropped_at` TIMESTAMP NULL DEFAULT NULL COMMENT '退课时间',
  `completed_at` TIMESTAMP NULL DEFAULT NULL COMMENT '完成时间',
  `final_score` INT DEFAULT NULL COMMENT '最终成绩',
  `progress` INT DEFAULT 0 COMMENT '课程进度（0-100）',
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_course_user` (`course_id`, `user_id`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_enrollment_status` (`enrollment_status`),
  KEY `idx_enrolled_at` (`enrolled_at`),
  CONSTRAINT `fk_enrollments_course` FOREIGN KEY (`course_id`) REFERENCES `pbl_courses` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_enrollments_user` FOREIGN KEY (`user_id`) REFERENCES `aiot_core_users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='PBL课程选课记录表';

-- 4. 创建小组成员表（可选，如果不使用 aiot_core_users.group_id）
CREATE TABLE IF NOT EXISTS `pbl_group_members` (
  `id` INT NOT NULL AUTO_INCREMENT COMMENT '成员记录ID',
  `group_id` INT NOT NULL COMMENT '小组ID',
  `user_id` INT NOT NULL COMMENT '学生ID',
  `role` ENUM('member', 'leader', 'deputy_leader') DEFAULT 'member' COMMENT '成员角色',
  `joined_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '加入时间',
  `is_active` TINYINT(1) DEFAULT 1 COMMENT '是否激活',
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_group_user` (`group_id`, `user_id`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_role` (`role`),
  CONSTRAINT `fk_group_members_group` FOREIGN KEY (`group_id`) REFERENCES `pbl_groups` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_group_members_user` FOREIGN KEY (`user_id`) REFERENCES `aiot_core_users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='PBL小组成员表';

-- 5. 创建学习进度追踪表（详细记录）
CREATE TABLE IF NOT EXISTS `pbl_learning_progress` (
  `id` INT NOT NULL AUTO_INCREMENT COMMENT '进度记录ID',
  `user_id` INT NOT NULL COMMENT '学生ID',
  `course_id` BIGINT(20) NOT NULL COMMENT '课程ID',
  `unit_id` BIGINT(20) DEFAULT NULL COMMENT '单元ID',
  `resource_id` BIGINT(20) DEFAULT NULL COMMENT '资源ID',
  `progress_type` ENUM('resource_view', 'video_watch', 'document_read', 'task_submit', 'unit_complete') NOT NULL COMMENT '进度类型',
  `progress_value` INT DEFAULT 0 COMMENT '进度值（百分比或时长）',
  `time_spent` INT DEFAULT 0 COMMENT '花费时间（秒）',
  `meta_data` JSON DEFAULT NULL COMMENT '额外数据',
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '记录时间',
  PRIMARY KEY (`id`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_course_id` (`course_id`),
  KEY `idx_unit_id` (`unit_id`),
  KEY `idx_resource_id` (`resource_id`),
  KEY `idx_progress_type` (`progress_type`),
  KEY `idx_created_at` (`created_at`),
  CONSTRAINT `fk_learning_progress_user` FOREIGN KEY (`user_id`) REFERENCES `aiot_core_users` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_learning_progress_course` FOREIGN KEY (`course_id`) REFERENCES `pbl_courses` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_learning_progress_unit` FOREIGN KEY (`unit_id`) REFERENCES `pbl_units` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_learning_progress_resource` FOREIGN KEY (`resource_id`) REFERENCES `pbl_resources` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='PBL学习进度详细追踪表';

-- 6. 插入示例班级数据（可选）
INSERT INTO `pbl_classes` (`uuid`, `school_id`, `name`, `grade`, `academic_year`) VALUES
(UUID(), 1, '高一(1)班', '高一', '2024-2025'),
(UUID(), 1, '高一(2)班', '高一', '2024-2025'),
(UUID(), 1, '高二(1)班', '高二', '2024-2025')
ON DUPLICATE KEY UPDATE name=name;

-- 完成提示
SELECT '✅ 数据库更新脚本 05 执行完成：选课管理和班级小组管理表已创建' AS status;
