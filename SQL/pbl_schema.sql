-- CodeHubot PBL Platform Database Schema
-- Version: 1.1
-- Date: 2025-12-08
-- 更新内容：添加视频观看次数限制和个性化权限管理功能

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- ----------------------------
-- Table structure for pbl_courses
-- ----------------------------
DROP TABLE IF EXISTS `pbl_courses`;
CREATE TABLE `pbl_courses` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '课程ID',
  `uuid` varchar(36) NOT NULL COMMENT 'UUID，唯一标识',
  `title` varchar(200) NOT NULL COMMENT '课程标题',
  `description` text COMMENT '课程描述',
  `cover_image` varchar(255) DEFAULT NULL COMMENT '封面图URL',
  `duration` varchar(50) DEFAULT NULL COMMENT '时长',
  `difficulty` enum('beginner','intermediate','advanced') DEFAULT 'beginner' COMMENT '难度',
  `status` enum('draft','published','archived') DEFAULT 'draft' COMMENT '状态',
  `creator_id` int(11) DEFAULT NULL COMMENT '创建者ID',
  `school_id` int(11) DEFAULT NULL COMMENT '所属学校ID',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_uuid` (`uuid`),
  KEY `idx_school_id` (`school_id`),
  KEY `idx_creator_id` (`creator_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='PBL课程表';

-- ----------------------------
-- Table structure for pbl_units
-- ----------------------------
DROP TABLE IF EXISTS `pbl_units`;
CREATE TABLE `pbl_units` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '单元ID',
  `uuid` varchar(36) NOT NULL COMMENT 'UUID，唯一标识',
  `course_id` bigint(20) NOT NULL COMMENT '课程ID',
  `title` varchar(200) NOT NULL COMMENT '单元标题',
  `description` text COMMENT '单元描述',
  `order` int(11) NOT NULL DEFAULT '0' COMMENT '顺序',
  `status` enum('locked','available','completed') DEFAULT 'locked' COMMENT '状态',
  `learning_guide` json DEFAULT NULL COMMENT '学习导引配置',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_uuid` (`uuid`),
  KEY `idx_course_id` (`course_id`),
  CONSTRAINT `fk_units_course` FOREIGN KEY (`course_id`) REFERENCES `pbl_courses` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='PBL单元表';

-- ----------------------------
-- Table structure for pbl_resources
-- ----------------------------
DROP TABLE IF EXISTS `pbl_resources`;
CREATE TABLE `pbl_resources` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '资源ID',
  `uuid` varchar(36) NOT NULL COMMENT 'UUID，唯一标识',
  `unit_id` bigint(20) NOT NULL COMMENT '单元ID',
  `type` enum('video','document','link') NOT NULL COMMENT '资源类型',
  `title` varchar(200) NOT NULL COMMENT '资源标题',
  `description` text COMMENT '资源描述',
  `url` varchar(500) DEFAULT NULL COMMENT '资源URL',
  `content` longtext COMMENT '内容（Markdown格式，用于文档）',
  `duration` int(11) DEFAULT NULL COMMENT '时长（分钟，用于视频）',
  `order` int(11) DEFAULT '0' COMMENT '顺序',
  `video_id` varchar(100) DEFAULT NULL COMMENT '阿里云视频ID',
  `video_cover_url` varchar(255) DEFAULT NULL COMMENT '视频封面图URL',
  `max_views` int(11) DEFAULT NULL COMMENT '最大观看次数（NULL表示不限制，0表示禁止观看，大于0表示限制次数）',
  `valid_from` timestamp NULL DEFAULT NULL COMMENT '全局有效开始时间（NULL表示立即生效）',
  `valid_until` timestamp NULL DEFAULT NULL COMMENT '全局有效结束时间（NULL表示永久有效）',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_uuid` (`uuid`),
  KEY `idx_unit_id` (`unit_id`),
  KEY `idx_valid_period` (`valid_from`, `valid_until`),
  CONSTRAINT `fk_resources_unit` FOREIGN KEY (`unit_id`) REFERENCES `pbl_units` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='PBL资源表';

-- ----------------------------
-- Table structure for pbl_tasks
-- ----------------------------
DROP TABLE IF EXISTS `pbl_tasks`;
CREATE TABLE `pbl_tasks` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '任务ID',
  `uuid` varchar(36) NOT NULL COMMENT 'UUID，唯一标识',
  `unit_id` bigint(20) NOT NULL COMMENT '单元ID',
  `title` varchar(200) NOT NULL COMMENT '任务标题',
  `description` text COMMENT '任务描述',
  `type` enum('analysis','coding','design','deployment') DEFAULT 'analysis' COMMENT '任务类型',
  `difficulty` enum('easy','medium','hard') DEFAULT 'easy' COMMENT '难度',
  `estimated_time` varchar(50) DEFAULT NULL COMMENT '预计时长',
  `requirements` json DEFAULT NULL COMMENT '任务要求列表',
  `prerequisites` json DEFAULT NULL COMMENT '前置任务ID列表',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_uuid` (`uuid`),
  KEY `idx_unit_id` (`unit_id`),
  CONSTRAINT `fk_tasks_unit` FOREIGN KEY (`unit_id`) REFERENCES `pbl_units` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='PBL任务表';

-- ----------------------------
-- Table structure for pbl_projects
-- ----------------------------
DROP TABLE IF EXISTS `pbl_projects`;
CREATE TABLE `pbl_projects` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '项目ID',
  `uuid` varchar(36) NOT NULL COMMENT 'UUID，唯一标识',
  `group_id` int(11) DEFAULT NULL COMMENT '团队ID（关联 aiot_course_groups.id）',
  `course_id` bigint(20) NOT NULL COMMENT '课程ID',
  `title` varchar(200) NOT NULL COMMENT '项目标题',
  `description` text COMMENT '项目描述',
  `status` enum('planning','in-progress','review','completed') DEFAULT 'planning' COMMENT '状态',
  `progress` int(11) DEFAULT '0' COMMENT '进度 0-100',
  `repo_url` varchar(500) DEFAULT NULL COMMENT '代码仓库URL',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_uuid` (`uuid`),
  KEY `idx_group_id` (`group_id`),
  KEY `idx_course_id` (`course_id`),
  CONSTRAINT `fk_projects_course` FOREIGN KEY (`course_id`) REFERENCES `pbl_courses` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='PBL项目表';

-- ----------------------------
-- Table structure for pbl_task_progress
-- ----------------------------
DROP TABLE IF EXISTS `pbl_task_progress`;
CREATE TABLE `pbl_task_progress` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '进度ID',
  `task_id` bigint(20) NOT NULL COMMENT '任务ID',
  `user_id` int(11) NOT NULL COMMENT '用户ID（关联 aiot_core_users.id）',
  `status` enum('pending','in-progress','blocked','review','completed') DEFAULT 'pending' COMMENT '状态',
  `progress` int(11) DEFAULT '0' COMMENT '进度 0-100',
  `submission` json DEFAULT NULL COMMENT '提交内容',
  `score` int(11) DEFAULT NULL COMMENT '分数 0-100',
  `feedback` text COMMENT '评语',
  `graded_by` int(11) DEFAULT NULL COMMENT '批改人ID',
  `graded_at` timestamp NULL DEFAULT NULL COMMENT '批改时间',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_task_user` (`task_id`,`user_id`),
  KEY `idx_user_id` (`user_id`),
  CONSTRAINT `fk_progress_task` FOREIGN KEY (`task_id`) REFERENCES `pbl_tasks` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='PBL任务进度表';

-- ----------------------------
-- Table structure for pbl_ai_conversations
-- ----------------------------
DROP TABLE IF EXISTS `pbl_ai_conversations`;
CREATE TABLE `pbl_ai_conversations` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '主键',
  `uuid` varchar(36) NOT NULL COMMENT 'UUID，唯一标识',
  `user_id` int(11) NOT NULL COMMENT '用户ID',
  `unit_id` bigint(20) DEFAULT NULL COMMENT '关联学习单元',
  `task_id` bigint(20) DEFAULT NULL COMMENT '关联任务',
  `messages` json NOT NULL COMMENT '对话消息列表',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_uuid` (`uuid`),
  KEY `idx_user_id` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='PBL AI对话记录表';

-- ----------------------------
-- Table structure for pbl_learning_logs
-- ----------------------------
DROP TABLE IF EXISTS `pbl_learning_logs`;
CREATE TABLE `pbl_learning_logs` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '主键',
  `user_id` int(11) NOT NULL COMMENT '用户ID',
  `resource_id` bigint(20) NOT NULL COMMENT '资源ID',
  `action_type` enum('view','complete','download') NOT NULL COMMENT '操作类型',
  `duration` int(11) DEFAULT '0' COMMENT '学习时长(秒)',
  `progress` int(11) DEFAULT '0' COMMENT '进度 0-100',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  PRIMARY KEY (`id`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_resource_id` (`resource_id`),
  KEY `idx_user_resource_action` (`user_id`, `resource_id`, `action_type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='PBL学习日志表';

-- ----------------------------
-- Table structure for pbl_achievements
-- ----------------------------
DROP TABLE IF EXISTS `pbl_achievements`;
CREATE TABLE `pbl_achievements` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '主键',
  `uuid` varchar(36) NOT NULL COMMENT 'UUID',
  `name` varchar(100) NOT NULL COMMENT '成就名称',
  `description` text COMMENT '成就描述',
  `icon` varchar(255) DEFAULT NULL COMMENT '图标URL',
  `condition` json DEFAULT NULL COMMENT '解锁条件',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_uuid` (`uuid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='PBL成就表';

-- ----------------------------
-- Table structure for pbl_user_achievements
-- ----------------------------
DROP TABLE IF EXISTS `pbl_user_achievements`;
CREATE TABLE `pbl_user_achievements` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '主键',
  `user_id` int(11) NOT NULL COMMENT '用户ID',
  `achievement_id` bigint(20) NOT NULL COMMENT '成就ID',
  `unlocked_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '解锁时间',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_user_achievement` (`user_id`,`achievement_id`),
  CONSTRAINT `fk_ua_achievement` FOREIGN KEY (`achievement_id`) REFERENCES `pbl_achievements` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='PBL用户成就关联表';

-- ----------------------------
-- Table structure for pbl_video_watch_records
-- ----------------------------
-- 用于详细追踪每次视频观看行为
DROP TABLE IF EXISTS `pbl_video_watch_records`;
CREATE TABLE `pbl_video_watch_records` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '记录ID',
  `resource_id` bigint(20) NOT NULL COMMENT '视频资源ID',
  `user_id` int(11) NOT NULL COMMENT '用户ID（学生）',
  `watch_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '观看时间',
  `duration` int(11) DEFAULT 0 COMMENT '观看时长（秒）',
  `completed` tinyint(1) DEFAULT 0 COMMENT '是否观看完成',
  `ip_address` varchar(45) DEFAULT NULL COMMENT '观看IP地址',
  `user_agent` varchar(500) DEFAULT NULL COMMENT '用户代理',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  PRIMARY KEY (`id`),
  KEY `idx_resource_id` (`resource_id`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_watch_time` (`watch_time`),
  KEY `idx_resource_user` (`resource_id`, `user_id`),
  CONSTRAINT `fk_vwr_resource` FOREIGN KEY (`resource_id`) REFERENCES `pbl_resources` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='视频观看记录表';

-- ----------------------------
-- Table structure for pbl_video_user_permissions
-- ----------------------------
-- 为每个学生-视频组合设置个性化的观看权限
DROP TABLE IF EXISTS `pbl_video_user_permissions`;
CREATE TABLE `pbl_video_user_permissions` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '权限ID',
  `uuid` varchar(36) NOT NULL COMMENT 'UUID',
  `resource_id` bigint(20) NOT NULL COMMENT '视频资源ID',
  `user_id` int(11) NOT NULL COMMENT '用户ID（学生）',
  `max_views` int(11) DEFAULT NULL COMMENT '该学生对该视频的最大观看次数（NULL表示使用全局设置，0表示禁止，>0表示限制次数）',
  `valid_from` timestamp NULL DEFAULT NULL COMMENT '有效开始时间（NULL表示立即生效）',
  `valid_until` timestamp NULL DEFAULT NULL COMMENT '有效结束时间（NULL表示永久有效）',
  `reason` varchar(500) DEFAULT NULL COMMENT '设置原因（如：补课、奖励、考试限制等）',
  `created_by` int(11) NOT NULL COMMENT '创建者ID（管理员/教师）',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `is_active` tinyint(1) DEFAULT 1 COMMENT '是否启用',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_uuid` (`uuid`),
  UNIQUE KEY `uk_resource_user` (`resource_id`, `user_id`),
  KEY `idx_resource_id` (`resource_id`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_valid_period` (`valid_from`, `valid_until`),
  KEY `idx_created_by` (`created_by`),
  CONSTRAINT `fk_vup_resource` FOREIGN KEY (`resource_id`) REFERENCES `pbl_resources` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='视频用户权限表（个性化观看次数和有效期设置）';


-- ----------------------------
-- Table structure for pbl_course_enrollments
-- ----------------------------
DROP TABLE IF EXISTS `pbl_course_enrollments`;
CREATE TABLE `pbl_course_enrollments` (
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT '选课记录ID',
  `course_id` bigint(20) NOT NULL COMMENT '课程ID',
  `user_id` int(11) NOT NULL COMMENT '学生ID',
  `enrollment_status` enum('enrolled','dropped','completed') DEFAULT 'enrolled' COMMENT '选课状态',
  `enrolled_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP COMMENT '选课时间',
  `dropped_at` timestamp NULL DEFAULT NULL COMMENT '退课时间',
  `completed_at` timestamp NULL DEFAULT NULL COMMENT '完成时间',
  `final_score` int(11) DEFAULT NULL COMMENT '最终成绩',
  `progress` int(11) DEFAULT '0' COMMENT '课程进度（0-100）',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_course_user` (`course_id`,`user_id`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_enrollment_status` (`enrollment_status`),
  KEY `idx_enrolled_at` (`enrolled_at`),
  CONSTRAINT `fk_enrollments_course` FOREIGN KEY (`course_id`) REFERENCES `pbl_courses` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_enrollments_user` FOREIGN KEY (`user_id`) REFERENCES `aiot_core_users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='PBL课程选课记录表';

-- ----------------------------
-- Table structure for pbl_classes
-- ----------------------------
DROP TABLE IF EXISTS `pbl_classes`;
CREATE TABLE `pbl_classes` (
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT '班级ID',
  `uuid` varchar(36) NOT NULL COMMENT 'UUID唯一标识',
  `school_id` int(11) NOT NULL COMMENT '所属学校ID',
  `name` varchar(100) NOT NULL COMMENT '班级名称',
  `grade` varchar(50) DEFAULT NULL COMMENT '年级',
  `academic_year` varchar(20) DEFAULT NULL COMMENT '学年（如：2024-2025）',
  `class_teacher_id` int(11) DEFAULT NULL COMMENT '班主任ID',
  `max_students` int(11) DEFAULT '50' COMMENT '最大学生数',
  `is_active` tinyint(1) DEFAULT '1' COMMENT '是否激活',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_uuid` (`uuid`),
  KEY `idx_school_id` (`school_id`),
  KEY `idx_name` (`name`),
  KEY `idx_grade` (`grade`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='PBL班级表';

-- ----------------------------
-- Table structure for pbl_groups
-- ----------------------------
DROP TABLE IF EXISTS `pbl_groups`;
CREATE TABLE `pbl_groups` (
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT '小组ID',
  `uuid` varchar(36) NOT NULL COMMENT 'UUID唯一标识',
  `class_id` int(11) DEFAULT NULL COMMENT '所属班级ID',
  `course_id` bigint(20) DEFAULT NULL COMMENT '所属课程ID',
  `name` varchar(100) NOT NULL COMMENT '小组名称',
  `description` text COMMENT '小组描述',
  `leader_id` int(11) DEFAULT NULL COMMENT '组长ID',
  `max_members` int(11) DEFAULT '6' COMMENT '最大成员数',
  `is_active` tinyint(1) DEFAULT '1' COMMENT '是否激活',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_uuid` (`uuid`),
  KEY `idx_class_id` (`class_id`),
  KEY `idx_course_id` (`course_id`),
  KEY `idx_name` (`name`),
  CONSTRAINT `fk_groups_class` FOREIGN KEY (`class_id`) REFERENCES `pbl_classes` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_groups_course` FOREIGN KEY (`course_id`) REFERENCES `pbl_courses` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='PBL学习小组表';

-- ----------------------------
-- Table structure for pbl_group_members
-- ----------------------------
DROP TABLE IF EXISTS `pbl_group_members`;
CREATE TABLE `pbl_group_members` (
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT '成员记录ID',
  `group_id` int(11) NOT NULL COMMENT '小组ID',
  `user_id` int(11) NOT NULL COMMENT '学生ID',
  `role` enum('member','leader','deputy_leader') DEFAULT 'member' COMMENT '成员角色',
  `joined_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP COMMENT '加入时间',
  `is_active` tinyint(1) DEFAULT '1' COMMENT '是否激活',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_group_user` (`group_id`,`user_id`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_role` (`role`),
  CONSTRAINT `fk_group_members_group` FOREIGN KEY (`group_id`) REFERENCES `pbl_groups` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_group_members_user` FOREIGN KEY (`user_id`) REFERENCES `aiot_core_users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='PBL小组成员表';

-- ----------------------------
-- Table structure for pbl_learning_progress
-- ----------------------------
DROP TABLE IF EXISTS `pbl_learning_progress`;
CREATE TABLE `pbl_learning_progress` (
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT '进度记录ID',
  `user_id` int(11) NOT NULL COMMENT '学生ID',
  `course_id` bigint(20) NOT NULL COMMENT '课程ID',
  `unit_id` bigint(20) DEFAULT NULL COMMENT '单元ID',
  `resource_id` bigint(20) DEFAULT NULL COMMENT '资源ID',
  `progress_type` enum('resource_view','video_watch','document_read','task_submit','unit_complete') NOT NULL COMMENT '进度类型',
  `progress_value` int(11) DEFAULT '0' COMMENT '进度值（百分比或时长）',
  `time_spent` int(11) DEFAULT '0' COMMENT '花费时间（秒）',
  `meta_data` json DEFAULT NULL COMMENT '额外数据',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '记录时间',
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

-- ==========================================
-- 添加学校课程管理表
-- ==========================================
--
-- 说明：
--   本脚本用于添加学校课程管理功能，实现以下业务逻辑：
--   1. 平台管理员将课程分配给学校（pbl_school_courses）
--   2. 学校管理员从学校课程库中为学生分配课程（pbl_course_enrollments）
--
-- 业务流程：
--   平台管理员 → 为学校分配课程 → 学校课程库（pbl_school_courses）
--                                      ↓
--   学校管理员 → 为学生分配课程 → 学生选课记录（pbl_course_enrollments）
--
-- 使用方式：
--   1. 选择数据库：USE aiot_admin;
--   2. 执行本脚本：source /path/to/17_add_school_courses_management.sql;
--
-- ==========================================

-- ----------------------------
-- Table structure for pbl_school_courses
-- ----------------------------
DROP TABLE IF EXISTS `pbl_school_courses`;
CREATE TABLE `pbl_school_courses` (
  `id` BIGINT(20) NOT NULL AUTO_INCREMENT COMMENT '记录ID',
  `uuid` VARCHAR(36) NOT NULL COMMENT 'UUID，唯一标识',
  `school_id` INT(11) NOT NULL COMMENT '学校ID',
  `course_id` BIGINT(20) NOT NULL COMMENT '课程ID',
  `assigned_by` INT(11) DEFAULT NULL COMMENT '分配人ID（平台管理员）',
  `assigned_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '分配时间',
  `status` ENUM('active', 'inactive', 'archived') DEFAULT 'active' COMMENT '状态：active-启用，inactive-停用，archived-归档',
  `start_date` DATE DEFAULT NULL COMMENT '课程开始日期',
  `end_date` DATE DEFAULT NULL COMMENT '课程结束日期',
  `max_students` INT(11) DEFAULT NULL COMMENT '最大学生数限制（NULL表示无限制）',
  `current_students` INT(11) DEFAULT 0 COMMENT '当前选课学生数',
  `remarks` TEXT COMMENT '备注信息',
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_uuid` (`uuid`),
  UNIQUE KEY `uk_school_course` (`school_id`, `course_id`),
  KEY `idx_school_id` (`school_id`),
  KEY `idx_course_id` (`course_id`),
  KEY `idx_status` (`status`),
  KEY `idx_assigned_at` (`assigned_at`),
  CONSTRAINT `fk_school_courses_school` FOREIGN KEY (`school_id`) REFERENCES `aiot_schools` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_school_courses_course` FOREIGN KEY (`course_id`) REFERENCES `pbl_courses` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='学校课程分配表（平台管理员为学校分配课程）';

-- ----------------------------
-- 修改 pbl_courses 表的 school_id 注释
-- ----------------------------
-- 注意：school_id 字段保留，但语义调整为"课程创建者所属学校"
-- 课程可以由学校创建，也可以由平台创建（school_id为NULL表示平台课程）
ALTER TABLE `pbl_courses` 
  MODIFY COLUMN `school_id` INT(11) DEFAULT NULL COMMENT '课程创建者所属学校ID（NULL表示平台课程）';

-- ----------------------------
-- 为现有课程创建学校课程关联
-- ----------------------------
-- 说明：如果现有课程已经有 school_id，自动创建学校课程关联记录
INSERT INTO `pbl_school_courses` (`uuid`, `school_id`, `course_id`, `assigned_at`, `status`, `created_at`, `updated_at`)
SELECT 
  UUID() AS uuid,
  c.school_id,
  c.id AS course_id,
  c.created_at AS assigned_at,
  'active' AS status,
  NOW() AS created_at,
  NOW() AS updated_at
FROM `pbl_courses` c
WHERE c.school_id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM `pbl_school_courses` sc 
    WHERE sc.school_id = c.school_id AND sc.course_id = c.id
  );

-- ----------------------------
-- 更新 pbl_course_enrollments 表的约束
-- ----------------------------
-- 添加检查：学生选课前，课程必须已分配给学生所属学校
-- 注意：这个约束通过应用层逻辑实现，数据库层面添加索引优化查询

-- 添加索引以优化查询性能（先检查是否存在，不存在再创建）
SET @index_exists = (
  SELECT COUNT(1) 
  FROM information_schema.statistics 
  WHERE table_schema = DATABASE() 
    AND table_name = 'pbl_course_enrollments' 
    AND index_name = 'idx_course_user'
);

SET @sql_add_index = IF(
  @index_exists = 0,
  'ALTER TABLE `pbl_course_enrollments` ADD KEY `idx_course_user` (`course_id`, `user_id`)',
  'SELECT "索引 idx_course_user 已存在，跳过创建" AS info'
);

PREPARE stmt FROM @sql_add_index;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- ----------------------------
-- 显示统计信息
-- ----------------------------
SELECT 
  '学校课程分配表创建完成' AS step,
  COUNT(*) AS initialized_records
FROM `pbl_school_courses`;

SELECT 
  s.school_name,
  COUNT(sc.id) AS assigned_courses
FROM `aiot_schools` s
LEFT JOIN `pbl_school_courses` sc ON s.id = sc.school_id
GROUP BY s.id, s.school_name
ORDER BY assigned_courses DESC;

-- ----------------------------
-- 说明文档
-- ----------------------------
/*
数据表关系说明：

1. pbl_courses（课程表）
   - 存储所有课程信息
   - school_id：课程创建者所属学校（NULL表示平台课程）
   - 课程可以由平台创建，也可以由学校创建

2. pbl_school_courses（学校课程分配表）★ 新增
   - 记录平台管理员为学校分配的课程
   - 学校只能看到和使用已分配的课程
   - 支持设置课程有效期、学生数限制等

3. pbl_course_enrollments（学生选课表）
   - 记录学校管理员为学生分配的课程
   - 学生只能看到和学习已分配的课程

权限层级：
- 平台管理员：管理所有课程，为学校分配课程
- 学校管理员：查看学校已分配的课程，为学生分配课程
- 学生：查看和学习已分配的课程

业务流程：
1. 平台管理员创建课程 → pbl_courses
2. 平台管理员将课程分配给学校 → pbl_school_courses
3. 学校管理员从学校课程库中选择课程，分配给学生 → pbl_course_enrollments
4. 学生查看和学习已分配的课程

查询示例：
-- 查询某个学校可用的课程
SELECT c.* 
FROM pbl_courses c
INNER JOIN pbl_school_courses sc ON c.id = sc.course_id
WHERE sc.school_id = ? AND sc.status = 'active';

-- 查询某个学生可学习的课程
SELECT c.*, e.progress, e.enrollment_status
FROM pbl_courses c
INNER JOIN pbl_course_enrollments e ON c.id = e.course_id
WHERE e.user_id = ? AND e.enrollment_status = 'enrolled';

-- 检查学生是否可以选课（课程必须已分配给学生所属学校）
SELECT COUNT(*) 
FROM pbl_school_courses sc
INNER JOIN aiot_core_users u ON u.school_id = sc.school_id
WHERE sc.course_id = ? AND u.id = ? AND sc.status = 'active';
*/

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

-- ==========================================
-- 项目成果与评价体系
-- ==========================================

-- ----------------------------
-- Table structure for pbl_project_outputs
-- 项目成果表：存储学生的项目作品、报告、代码等成果
-- ----------------------------
DROP TABLE IF EXISTS `pbl_project_outputs`;
CREATE TABLE `pbl_project_outputs` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '成果ID',
  `uuid` varchar(36) NOT NULL COMMENT 'UUID，唯一标识',
  `project_id` bigint(20) NOT NULL COMMENT '项目ID',
  `task_id` bigint(20) DEFAULT NULL COMMENT '任务ID（可选，某个任务的提交物）',
  `user_id` int(11) NOT NULL COMMENT '提交学生ID',
  `group_id` int(11) DEFAULT NULL COMMENT '小组ID（小组作品）',
  `output_type` enum('report','code','design','video','presentation','model','dataset','other') NOT NULL COMMENT '成果类型',
  `title` varchar(200) NOT NULL COMMENT '成果标题',
  `description` text COMMENT '成果说明',
  `file_url` varchar(500) DEFAULT NULL COMMENT '文件URL（支持多个文件用JSON数组）',
  `file_size` bigint(20) DEFAULT NULL COMMENT '文件大小(字节)',
  `file_type` varchar(50) DEFAULT NULL COMMENT '文件类型',
  `repo_url` varchar(500) DEFAULT NULL COMMENT '代码仓库URL',
  `demo_url` varchar(500) DEFAULT NULL COMMENT '演示URL',
  `thumbnail` varchar(500) DEFAULT NULL COMMENT '缩略图URL',
  `meta_data` json DEFAULT NULL COMMENT '扩展元数据（如：技术栈、工具等）',
  `is_public` tinyint(1) DEFAULT '0' COMMENT '是否公开展示',
  `view_count` int(11) DEFAULT '0' COMMENT '浏览次数',
  `like_count` int(11) DEFAULT '0' COMMENT '点赞数',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_uuid` (`uuid`),
  KEY `idx_project_id` (`project_id`),
  KEY `idx_task_id` (`task_id`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_group_id` (`group_id`),
  KEY `idx_output_type` (`output_type`),
  KEY `idx_is_public` (`is_public`),
  CONSTRAINT `fk_outputs_project` FOREIGN KEY (`project_id`) REFERENCES `pbl_projects` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_outputs_task` FOREIGN KEY (`task_id`) REFERENCES `pbl_tasks` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='PBL项目成果表';

-- ----------------------------
-- Table structure for pbl_assessments
-- 评价表：多维度评价（教师评价+学生互评+专家评价+自评）
-- ----------------------------
DROP TABLE IF EXISTS `pbl_assessments`;
CREATE TABLE `pbl_assessments` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '评价ID',
  `uuid` varchar(36) NOT NULL COMMENT 'UUID',
  `assessor_id` int(11) NOT NULL COMMENT '评价人ID',
  `assessor_role` enum('teacher','student','expert','self') NOT NULL COMMENT '评价人角色',
  `target_type` enum('project','task','output','student') NOT NULL COMMENT '评价对象类型',
  `target_id` bigint(20) NOT NULL COMMENT '评价对象ID',
  `student_id` int(11) NOT NULL COMMENT '被评价学生ID',
  `group_id` int(11) DEFAULT NULL COMMENT '被评价小组ID（小组作品）',
  `assessment_type` enum('formative','summative') DEFAULT 'formative' COMMENT '评价类型：formative-过程性/summative-总结性',
  `dimensions` json NOT NULL COMMENT '评价维度与分数',
  `total_score` decimal(5,2) DEFAULT NULL COMMENT '总分',
  `max_score` decimal(5,2) DEFAULT '100.00' COMMENT '满分',
  `comments` text COMMENT '评语',
  `strengths` text COMMENT '优点',
  `improvements` text COMMENT '改进建议',
  `tags` json DEFAULT NULL COMMENT '标签',
  `is_public` tinyint(1) DEFAULT '0' COMMENT '是否公开',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '评价时间',
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_uuid` (`uuid`),
  KEY `idx_assessor` (`assessor_id`, `assessor_role`),
  KEY `idx_student` (`student_id`),
  KEY `idx_target` (`target_type`, `target_id`),
  KEY `idx_type` (`assessment_type`),
  KEY `idx_group` (`group_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='PBL评价表';

-- ----------------------------
-- Table structure for pbl_assessment_templates
-- 评价维度模板表：预定义的评价标准和维度
-- ----------------------------
DROP TABLE IF EXISTS `pbl_assessment_templates`;
CREATE TABLE `pbl_assessment_templates` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '模板ID',
  `uuid` varchar(36) NOT NULL COMMENT 'UUID',
  `name` varchar(100) NOT NULL COMMENT '模板名称',
  `description` text COMMENT '模板描述',
  `applicable_to` enum('project','task','output') NOT NULL COMMENT '适用对象',
  `grade_level` varchar(50) DEFAULT NULL COMMENT '适用学段',
  `dimensions` json NOT NULL COMMENT '评价维度配置',
  `created_by` int(11) DEFAULT NULL COMMENT '创建者ID',
  `is_system` tinyint(1) DEFAULT '0' COMMENT '是否系统模板',
  `is_active` tinyint(1) DEFAULT '1' COMMENT '是否启用',
  `usage_count` int(11) DEFAULT '0' COMMENT '使用次数',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_uuid` (`uuid`),
  KEY `idx_applicable` (`applicable_to`, `grade_level`),
  KEY `idx_is_active` (`is_active`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='PBL评价模板表';

-- ==========================================
-- 伦理教育与资源管理
-- ==========================================

-- ----------------------------
-- Table structure for pbl_ethics_cases
-- 伦理案例库表：存储AI伦理相关的教学案例
-- ----------------------------
DROP TABLE IF EXISTS `pbl_ethics_cases`;
CREATE TABLE `pbl_ethics_cases` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '案例ID',
  `uuid` varchar(36) NOT NULL COMMENT 'UUID',
  `title` varchar(200) NOT NULL COMMENT '案例标题',
  `description` text NOT NULL COMMENT '案例描述',
  `content` longtext COMMENT '案例内容（Markdown格式）',
  `grade_level` varchar(50) DEFAULT NULL COMMENT '适用学段',
  `ethics_topics` json NOT NULL COMMENT '涉及的伦理议题',
  `difficulty` enum('basic','intermediate','advanced') DEFAULT 'basic' COMMENT '难度等级',
  `discussion_questions` json DEFAULT NULL COMMENT '讨论问题列表',
  `reference_links` json DEFAULT NULL COMMENT '参考资料链接',
  `cover_image` varchar(255) DEFAULT NULL COMMENT '封面图URL',
  `author` varchar(100) DEFAULT NULL COMMENT '作者',
  `source` varchar(200) DEFAULT NULL COMMENT '来源',
  `is_published` tinyint(1) DEFAULT '1' COMMENT '是否发布',
  `view_count` int(11) DEFAULT '0' COMMENT '浏览次数',
  `like_count` int(11) DEFAULT '0' COMMENT '点赞数',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_uuid` (`uuid`),
  KEY `idx_grade_level` (`grade_level`),
  KEY `idx_difficulty` (`difficulty`),
  KEY `idx_is_published` (`is_published`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='PBL伦理案例库表';

-- ----------------------------
-- Table structure for pbl_ethics_activities
-- 伦理活动记录表：记录伦理思辨活动的过程和结果
-- ----------------------------
DROP TABLE IF EXISTS `pbl_ethics_activities`;
CREATE TABLE `pbl_ethics_activities` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '活动ID',
  `uuid` varchar(36) NOT NULL COMMENT 'UUID',
  `case_id` bigint(20) DEFAULT NULL COMMENT '关联案例ID',
  `course_id` bigint(20) DEFAULT NULL COMMENT '关联课程ID',
  `unit_id` bigint(20) DEFAULT NULL COMMENT '关联单元ID',
  `activity_type` enum('debate','case_analysis','role_play','discussion','reflection') NOT NULL COMMENT '活动类型',
  `title` varchar(200) NOT NULL COMMENT '活动标题',
  `description` text COMMENT '活动描述',
  `participants` json DEFAULT NULL COMMENT '参与学生ID列表',
  `group_id` int(11) DEFAULT NULL COMMENT '小组ID',
  `facilitator_id` int(11) DEFAULT NULL COMMENT '主持人/教师ID',
  `status` enum('planned','ongoing','completed','cancelled') DEFAULT 'planned' COMMENT '状态',
  `discussion_records` json DEFAULT NULL COMMENT '讨论记录',
  `conclusions` text COMMENT '活动总结',
  `reflections` json DEFAULT NULL COMMENT '学生反思记录',
  `scheduled_at` timestamp NULL DEFAULT NULL COMMENT '计划时间',
  `completed_at` timestamp NULL DEFAULT NULL COMMENT '完成时间',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_uuid` (`uuid`),
  KEY `idx_case` (`case_id`),
  KEY `idx_course` (`course_id`),
  KEY `idx_unit` (`unit_id`),
  KEY `idx_status` (`status`),
  CONSTRAINT `fk_ethics_case` FOREIGN KEY (`case_id`) REFERENCES `pbl_ethics_cases` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_ethics_course` FOREIGN KEY (`course_id`) REFERENCES `pbl_courses` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_ethics_unit` FOREIGN KEY (`unit_id`) REFERENCES `pbl_units` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='PBL伦理活动记录表';

-- ----------------------------
-- Table structure for pbl_datasets
-- 数据集管理表：管理用于AI模型训练的数据集
-- ----------------------------
DROP TABLE IF EXISTS `pbl_datasets`;
CREATE TABLE `pbl_datasets` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '数据集ID',
  `uuid` varchar(36) NOT NULL COMMENT 'UUID',
  `name` varchar(100) NOT NULL COMMENT '数据集名称',
  `description` text COMMENT '数据集描述',
  `data_type` enum('image','text','audio','video','tabular','mixed') NOT NULL COMMENT '数据类型',
  `category` varchar(50) DEFAULT NULL COMMENT '分类',
  `file_url` varchar(500) DEFAULT NULL COMMENT '数据集文件URL',
  `file_size` bigint(20) DEFAULT NULL COMMENT '文件大小(字节)',
  `sample_count` int(11) DEFAULT NULL COMMENT '样本数量',
  `class_count` int(11) DEFAULT NULL COMMENT '类别数量',
  `classes` json DEFAULT NULL COMMENT '类别列表',
  `is_labeled` tinyint(1) DEFAULT '0' COMMENT '是否已标注',
  `label_format` varchar(50) DEFAULT NULL COMMENT '标注格式',
  `split_ratio` json DEFAULT NULL COMMENT '数据集划分比例',
  `grade_level` varchar(50) DEFAULT NULL COMMENT '适用学段',
  `applicable_projects` json DEFAULT NULL COMMENT '适用项目列表',
  `source` varchar(200) DEFAULT NULL COMMENT '来源',
  `license` varchar(100) DEFAULT NULL COMMENT '许可协议',
  `preview_images` json DEFAULT NULL COMMENT '预览图URL列表',
  `download_count` int(11) DEFAULT '0' COMMENT '下载次数',
  `creator_id` int(11) DEFAULT NULL COMMENT '创建者ID',
  `school_id` int(11) DEFAULT NULL COMMENT '所属学校ID',
  `is_public` tinyint(1) DEFAULT '1' COMMENT '是否公开',
  `quality_score` decimal(3,2) DEFAULT NULL COMMENT '数据质量评分',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_uuid` (`uuid`),
  KEY `idx_data_type` (`data_type`),
  KEY `idx_grade_level` (`grade_level`),
  KEY `idx_category` (`category`),
  KEY `idx_is_public` (`is_public`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='PBL数据集管理表';

-- ==========================================
-- 家校社协同与成长档案
-- ==========================================

-- ----------------------------
-- Table structure for pbl_student_portfolios
-- 学生成长档案表：记录学生的学习轨迹和能力成长
-- ----------------------------
DROP TABLE IF EXISTS `pbl_student_portfolios`;
CREATE TABLE `pbl_student_portfolios` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '档案ID',
  `uuid` varchar(36) NOT NULL COMMENT 'UUID',
  `student_id` int(11) NOT NULL COMMENT '学生ID',
  `school_year` varchar(20) NOT NULL COMMENT '学年',
  `grade_level` varchar(50) NOT NULL COMMENT '学段',
  `completed_projects` json DEFAULT NULL COMMENT '完成的项目列表',
  `achievements` json DEFAULT NULL COMMENT '获得的成就列表',
  `skill_assessment` json DEFAULT NULL COMMENT '能力评估',
  `growth_trajectory` json DEFAULT NULL COMMENT '成长轨迹数据',
  `highlights` json DEFAULT NULL COMMENT '亮点作品ID列表',
  `total_learning_hours` int(11) DEFAULT '0' COMMENT '累计学习时长',
  `projects_count` int(11) DEFAULT '0' COMMENT '完成项目数',
  `avg_score` decimal(5,2) DEFAULT NULL COMMENT '平均分数',
  `teacher_comments` text COMMENT '教师综合评语',
  `self_reflection` text COMMENT '学生自我反思',
  `parent_feedback` text COMMENT '家长反馈',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_uuid` (`uuid`),
  UNIQUE KEY `uk_student_year` (`student_id`, `school_year`),
  KEY `idx_student` (`student_id`),
  KEY `idx_grade_level` (`grade_level`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='PBL学生成长档案表';

-- ----------------------------
-- Table structure for pbl_parent_relations
-- 家长关系表：建立家长与学生的关联
-- ----------------------------
DROP TABLE IF EXISTS `pbl_parent_relations`;
CREATE TABLE `pbl_parent_relations` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '关系ID',
  `parent_user_id` int(11) NOT NULL COMMENT '家长用户ID',
  `student_id` int(11) NOT NULL COMMENT '学生ID',
  `relationship` enum('father','mother','guardian','other') NOT NULL COMMENT '关系类型',
  `can_view_progress` tinyint(1) DEFAULT '1' COMMENT '可查看学习进度',
  `can_view_scores` tinyint(1) DEFAULT '1' COMMENT '可查看成绩',
  `can_view_projects` tinyint(1) DEFAULT '1' COMMENT '可查看项目',
  `notification_enabled` tinyint(1) DEFAULT '1' COMMENT '接收通知',
  `verified` tinyint(1) DEFAULT '0' COMMENT '是否已验证',
  `verified_at` timestamp NULL DEFAULT NULL COMMENT '验证时间',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_parent_student` (`parent_user_id`, `student_id`),
  KEY `idx_student` (`student_id`),
  KEY `idx_verified` (`verified`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='PBL家长关系表';

-- ----------------------------
-- Table structure for pbl_external_experts
-- 外部专家表：管理参与项目评审的外部专家
-- ----------------------------
DROP TABLE IF EXISTS `pbl_external_experts`;
CREATE TABLE `pbl_external_experts` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '专家ID',
  `uuid` varchar(36) NOT NULL COMMENT 'UUID',
  `name` varchar(100) NOT NULL COMMENT '姓名',
  `organization` varchar(200) DEFAULT NULL COMMENT '所属单位',
  `title` varchar(100) DEFAULT NULL COMMENT '职称/职位',
  `expertise_areas` json DEFAULT NULL COMMENT '专业领域',
  `bio` text COMMENT '个人简介',
  `email` varchar(255) DEFAULT NULL COMMENT '邮箱',
  `phone` varchar(20) DEFAULT NULL COMMENT '电话',
  `avatar` varchar(255) DEFAULT NULL COMMENT '头像URL',
  `is_active` tinyint(1) DEFAULT '1' COMMENT '是否活跃',
  `participated_projects` int(11) DEFAULT '0' COMMENT '参与评审项目数',
  `avg_rating` decimal(3,2) DEFAULT NULL COMMENT '平均评分',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_uuid` (`uuid`),
  KEY `idx_is_active` (`is_active`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='PBL外部专家表';

-- ----------------------------
-- Table structure for pbl_social_activities
-- 社会实践活动表：记录家校社协同的实践活动
-- ----------------------------
DROP TABLE IF EXISTS `pbl_social_activities`;
CREATE TABLE `pbl_social_activities` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '活动ID',
  `uuid` varchar(36) NOT NULL COMMENT 'UUID',
  `title` varchar(200) NOT NULL COMMENT '活动标题',
  `description` text COMMENT '活动描述',
  `activity_type` enum('company_visit','lab_tour','workshop','competition','exhibition','volunteer','lecture') NOT NULL COMMENT '活动类型',
  `organizer` varchar(200) DEFAULT NULL COMMENT '组织方',
  `partner_organization` varchar(200) DEFAULT NULL COMMENT '合作单位',
  `location` varchar(500) DEFAULT NULL COMMENT '活动地点',
  `scheduled_at` timestamp NULL DEFAULT NULL COMMENT '活动时间',
  `duration` int(11) DEFAULT NULL COMMENT '活动时长（分钟）',
  `max_participants` int(11) DEFAULT NULL COMMENT '最大参与人数',
  `current_participants` int(11) DEFAULT '0' COMMENT '当前参与人数',
  `participants` json DEFAULT NULL COMMENT '参与学生ID列表',
  `facilitators` json DEFAULT NULL COMMENT '带队教师ID列表',
  `status` enum('planned','registration','ongoing','completed','cancelled') DEFAULT 'planned' COMMENT '状态',
  `photos` json DEFAULT NULL COMMENT '活动照片URL列表',
  `summary` text COMMENT '活动总结',
  `feedback` json DEFAULT NULL COMMENT '学生反馈',
  `created_by` int(11) DEFAULT NULL COMMENT '创建者ID',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_uuid` (`uuid`),
  KEY `idx_type` (`activity_type`),
  KEY `idx_scheduled` (`scheduled_at`),
  KEY `idx_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='PBL社会实践活动表';

-- ==========================================
-- 视频播放进度追踪
-- ==========================================

-- ----------------------------
-- Table structure for pbl_video_play_progress
-- 视频播放进度表：详细记录学生观看视频的真实情况
-- ----------------------------
DROP TABLE IF EXISTS `pbl_video_play_progress`;
CREATE TABLE `pbl_video_play_progress` (
  `id` BIGINT(20) NOT NULL AUTO_INCREMENT COMMENT '记录ID',
  `uuid` VARCHAR(36) NOT NULL COMMENT 'UUID',
  `resource_id` BIGINT(20) NOT NULL COMMENT '视频资源ID',
  `user_id` INT(11) NOT NULL COMMENT '用户ID（学生）',
  `session_id` VARCHAR(64) NOT NULL COMMENT '播放会话ID',
  `current_position` INT DEFAULT 0 COMMENT '当前播放位置（秒）',
  `duration` INT DEFAULT 0 COMMENT '视频总时长（秒）',
  `play_duration` INT DEFAULT 0 COMMENT '本次会话累计播放时长（秒）',
  `real_watch_duration` INT DEFAULT 0 COMMENT '真实观看时长（秒）',
  `status` VARCHAR(20) DEFAULT 'playing' COMMENT '播放状态',
  `last_event` VARCHAR(50) DEFAULT NULL COMMENT '最后一次事件',
  `last_event_time` TIMESTAMP NULL DEFAULT NULL COMMENT '最后一次事件时间',
  `seek_count` INT DEFAULT 0 COMMENT '拖动次数',
  `pause_count` INT DEFAULT 0 COMMENT '暂停次数',
  `pause_duration` INT DEFAULT 0 COMMENT '累计暂停时长（秒）',
  `replay_count` INT DEFAULT 0 COMMENT '重播次数',
  `watched_ranges` TEXT DEFAULT NULL COMMENT '已观看的时间段（JSON）',
  `completion_rate` DECIMAL(5,2) DEFAULT 0.00 COMMENT '完成度（百分比）',
  `is_completed` TINYINT(1) DEFAULT 0 COMMENT '是否观看完成',
  `ip_address` VARCHAR(45) DEFAULT NULL COMMENT '客户端IP地址',
  `user_agent` VARCHAR(500) DEFAULT NULL COMMENT '用户代理',
  `device_type` VARCHAR(50) DEFAULT NULL COMMENT '设备类型',
  `start_time` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '开始播放时间',
  `end_time` TIMESTAMP NULL DEFAULT NULL COMMENT '结束播放时间',
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_uuid` (`uuid`),
  KEY `idx_resource_id` (`resource_id`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_session_id` (`session_id`),
  KEY `idx_resource_user` (`resource_id`, `user_id`),
  KEY `idx_start_time` (`start_time`),
  KEY `idx_status` (`status`),
  CONSTRAINT `fk_vpp_resource` FOREIGN KEY (`resource_id`) REFERENCES `pbl_resources` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='视频播放进度追踪表';

-- ----------------------------
-- Table structure for pbl_video_play_events
-- 视频播放事件表：详细日志
-- ----------------------------
DROP TABLE IF EXISTS `pbl_video_play_events`;
CREATE TABLE `pbl_video_play_events` (
  `id` BIGINT(20) NOT NULL AUTO_INCREMENT COMMENT '事件ID',
  `session_id` VARCHAR(64) NOT NULL COMMENT '播放会话ID',
  `resource_id` BIGINT(20) NOT NULL COMMENT '视频资源ID',
  `user_id` INT(11) NOT NULL COMMENT '用户ID',
  `event_type` VARCHAR(50) NOT NULL COMMENT '事件类型',
  `event_data` TEXT DEFAULT NULL COMMENT '事件数据（JSON格式）',
  `position` INT DEFAULT 0 COMMENT '事件发生时的播放位置（秒）',
  `timestamp` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '事件时间',
  PRIMARY KEY (`id`),
  KEY `idx_session_id` (`session_id`),
  KEY `idx_resource_id` (`resource_id`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_event_type` (`event_type`),
  KEY `idx_timestamp` (`timestamp`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='视频播放事件表';

-- ==========================================
-- 学校管理增强
-- ==========================================

-- ----------------------------
-- Table structure for pbl_import_logs
-- 批量导入日志表
-- ----------------------------
DROP TABLE IF EXISTS `pbl_import_logs`;
CREATE TABLE `pbl_import_logs` (
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

-- ==========================================
-- 视频观看统计和权限管理
-- ==========================================


SET FOREIGN_KEY_CHECKS = 1;
