-- CodeHubot PBL Platform Database Schema
-- Version: 1.0
-- Date: 2025-12-06

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
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_uuid` (`uuid`),
  KEY `idx_unit_id` (`unit_id`),
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
  KEY `idx_resource_id` (`resource_id`)
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

SET FOREIGN_KEY_CHECKS = 1;
