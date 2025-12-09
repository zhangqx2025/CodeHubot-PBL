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


CREATE TABLE IF NOT EXISTS `pbl_course_enrollments` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `course_id` INT NOT NULL COMMENT '课程ID',
  `user_id` INT NOT NULL COMMENT '学生用户ID',
  `enrollment_status` ENUM('enrolled', 'dropped', 'completed') NOT NULL DEFAULT 'enrolled' COMMENT '选课状态: enrolled-已选课, dropped-已退课, completed-已完成',
  `enrolled_at` TIMESTAMP NULL COMMENT '选课时间',
  `dropped_at` TIMESTAMP NULL COMMENT '退课时间',
  `completed_at` TIMESTAMP NULL COMMENT '完成时间',
  `progress` INT NOT NULL DEFAULT 0 COMMENT '学习进度(0-100)',
  `final_score` INT NULL COMMENT '最终成绩',
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  INDEX `idx_course_id` (`course_id`),
  INDEX `idx_user_id` (`user_id`),
  INDEX `idx_enrollment_status` (`enrollment_status`),
  CONSTRAINT `fk_pbl_enrollments_course` FOREIGN KEY (`course_id`) REFERENCES `pbl_courses` (`id`) ON DELETE CASCADE,
  CONSTRAINT `uk_course_user` UNIQUE (`course_id`, `user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='PBL课程选课表';


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
-- 视频观看统计和权限管理视图
-- ==========================================


SET FOREIGN_KEY_CHECKS = 1;
