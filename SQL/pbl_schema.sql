-- ==========================================================================================================
-- CodeHubot PBL 模块数据库初始化脚本
-- ==========================================================================================================
-- 
-- 脚本名称: pbl_schema.sql
-- 脚本版本: 2.0.0
-- 数据库版本: 2.0
-- 创建日期: 2025-01-01
-- 最后更新: 2025-12-09
-- 兼容版本: MySQL 5.7.x, 8.0.x
-- 字符集: utf8mb4
-- 排序规则: utf8mb4_unicode_ci
--
-- ==========================================================================================================
-- 脚本说明
-- ==========================================================================================================
--
-- 1. 用途说明:
--    本脚本用于初始化 CodeHubot 系统的 PBL（项目制学习）模块数据库结构，包含以下功能模块：
--    - 课程管理: 课程、单元、资源、任务
--    - 学习管理: 学习进度、观看记录、播放进度追踪
--    - 项目管理: 项目、项目成果、评价体系
--    - 班级管理: 班级、教师关联、小组、成员
--    - 选课管理: 学校课程分配、学生选课
--    - 伦理教育: 伦理案例、伦理活动
--    - 资源管理: 数据集管理
--    - 家校社协同: 学生档案、家长关系、外部专家、社会实践
--    - 学校管理: 批量导入日志
--
-- 2. 前置条件:
--    - 必须先执行 init_database.sql 创建核心表（core_users, core_schools 等）
--    - MySQL Server 5.7.x 或 8.0.x 已安装并正常运行
--    - 目标数据库 aiot_admin 已创建并包含核心模块表
--    - 执行用户拥有 CREATE, ALTER, INDEX, REFERENCES 等权限
--
-- 3. 执行方式:
--    方式一 (推荐): 
--      mysql -h hostname -u username -p --default-character-set=utf8mb4 aiot_admin < pbl_schema.sql
--    
--    方式二:
--      mysql> USE aiot_admin;
--      mysql> SOURCE /path/to/pbl_schema.sql;
--    
--    方式三 (检查模式):
--      mysql -u username -p aiot_admin < pbl_schema.sql > pbl_output.log 2>&1
--
-- 4. 执行后验证:
--    - 检查输出日志中是否有错误信息
--    - 验证 PBL 表数量: SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'aiot_admin' AND table_name LIKE 'pbl_%';
--    - 验证外键约束完整性
--
-- 5. 回滚说明:
--    如需完全移除 PBL 模块，按以下顺序删除表:
--    - 先删除有外键依赖的表（子表）
--    - 最后删除被依赖的表（父表）
--    - 建议使用专门的回滚脚本
--
-- 6. 重要提示:
--    - 本脚本使用 CREATE TABLE IF NOT EXISTS，可安全重复执行
--    - 不包含 DROP TABLE 语句，避免误删数据
--    - 所有表使用 InnoDB 引擎，支持事务和外键
--    - 建议在生产环境执行前先在测试环境验证
--
-- 7. 表命名规范:
--    所有表名统一使用 pbl_ 前缀，采用下划线分隔单词
--
-- 8. 技术规范:
--    - 存储引擎: InnoDB
--    - 字符集: utf8mb4
--    - 排序规则: utf8mb4_unicode_ci
--    - 时间戳: 自动维护 created_at 和 updated_at
--
-- ==========================================================================================================
-- 执行环境检查
-- ==========================================================================================================

-- 检查当前数据库
SELECT 
    DATABASE() AS current_database,
    VERSION() AS mysql_version,
    NOW() AS execution_start_time;

-- 验证核心表是否存在
SELECT 
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = DATABASE() AND table_name = 'core_users') 
        THEN 'OK: core_users table exists'
        ELSE 'ERROR: core_users table not found. Please execute init_database.sql first!'
    END AS prerequisite_check_1;

SELECT 
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = DATABASE() AND table_name = 'core_schools') 
        THEN 'OK: core_schools table exists'
        ELSE 'ERROR: core_schools table not found. Please execute init_database.sql first!'
    END AS prerequisite_check_2;

-- 设置执行环境
SET NAMES utf8mb4 COLLATE utf8mb4_unicode_ci;
SET SQL_MODE = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION';
SET FOREIGN_KEY_CHECKS = 0;
SET UNIQUE_CHECKS = 0;

-- 开始事务
START TRANSACTION;

-- ==========================================================================================================
-- 课程管理模块
-- ==========================================================================================================

-- ----------------------------
-- Table structure for pbl_courses
-- 课程基础信息表
-- ----------------------------
CREATE TABLE IF NOT EXISTS `pbl_courses` (
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
-- Table structure for pbl_course_teachers
-- 课程教师关联表（多对多关系）
-- ----------------------------
CREATE TABLE IF NOT EXISTS `pbl_course_teachers` (
  `id` int(11) NOT NULL AUTO_INCREMENT PRIMARY KEY COMMENT '关联ID',
  `course_id` bigint(20) NOT NULL COMMENT '课程ID',
  `teacher_id` int(11) NOT NULL COMMENT '教师ID',
  `subject` varchar(50) DEFAULT NULL COMMENT '教师在该课程教授的科目',
  `is_primary` tinyint(1) DEFAULT '0' COMMENT '是否为主讲教师',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  UNIQUE KEY `uk_course_teacher` (`course_id`, `teacher_id`),
  KEY `idx_course_id` (`course_id`),
  KEY `idx_teacher_id` (`teacher_id`),
  KEY `idx_is_primary` (`is_primary`),
  CONSTRAINT `fk_course_teachers_course` FOREIGN KEY (`course_id`) REFERENCES `pbl_courses` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_course_teachers_teacher` FOREIGN KEY (`teacher_id`) REFERENCES `core_users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='PBL课程教师关联表（多对多）';

-- ----------------------------
-- Table structure for pbl_units
-- 课程单元表
-- ----------------------------
CREATE TABLE IF NOT EXISTS `pbl_units` (
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
-- DROP TABLE IF EXISTS (Removed for safety) `pbl_resources`;
CREATE TABLE IF NOT EXISTS `pbl_resources` (
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
-- DROP TABLE IF EXISTS (Removed for safety) `pbl_tasks`;
CREATE TABLE IF NOT EXISTS `pbl_tasks` (
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
-- DROP TABLE IF EXISTS (Removed for safety) `pbl_projects`;
CREATE TABLE IF NOT EXISTS `pbl_projects` (
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
-- DROP TABLE IF EXISTS (Removed for safety) `pbl_task_progress`;
CREATE TABLE IF NOT EXISTS `pbl_task_progress` (
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
-- DROP TABLE IF EXISTS (Removed for safety) `pbl_ai_conversations`;
CREATE TABLE IF NOT EXISTS `pbl_ai_conversations` (
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
-- DROP TABLE IF EXISTS (Removed for safety) `pbl_learning_logs`;
CREATE TABLE IF NOT EXISTS `pbl_learning_logs` (
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
-- DROP TABLE IF EXISTS (Removed for safety) `pbl_achievements`;
CREATE TABLE IF NOT EXISTS `pbl_achievements` (
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
-- DROP TABLE IF EXISTS (Removed for safety) `pbl_user_achievements`;
CREATE TABLE IF NOT EXISTS `pbl_user_achievements` (
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
-- DROP TABLE IF EXISTS (Removed for safety) `pbl_video_watch_records`;
CREATE TABLE IF NOT EXISTS `pbl_video_watch_records` (
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
-- DROP TABLE IF EXISTS (Removed for safety) `pbl_video_user_permissions`;
CREATE TABLE IF NOT EXISTS `pbl_video_user_permissions` (
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
-- DROP TABLE IF EXISTS (Removed for safety) `pbl_course_enrollments`;
CREATE TABLE IF NOT EXISTS `pbl_course_enrollments` (
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
  CONSTRAINT `fk_enrollments_user` FOREIGN KEY (`user_id`) REFERENCES `core_users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='PBL课程选课记录表';

-- ----------------------------
-- Table structure for pbl_classes
-- ----------------------------
-- DROP TABLE IF EXISTS (Removed for safety) `pbl_classes`;
CREATE TABLE IF NOT EXISTS `pbl_classes` (
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
-- Table structure for pbl_class_teachers
-- ----------------------------
-- DROP TABLE IF EXISTS (Removed for safety) `pbl_class_teachers`;
CREATE TABLE IF NOT EXISTS `pbl_class_teachers` (
  `id` int(11) NOT NULL AUTO_INCREMENT PRIMARY KEY COMMENT '关联ID',
  `class_id` int(11) NOT NULL COMMENT '班级ID',
  `teacher_id` int(11) NOT NULL COMMENT '教师ID',
  `subject` varchar(50) DEFAULT NULL COMMENT '教师在该班级教授的科目',
  `is_primary` tinyint(1) DEFAULT '0' COMMENT '是否为班主任',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  UNIQUE KEY `uk_class_teacher` (`class_id`, `teacher_id`),
  KEY `idx_class_id` (`class_id`),
  KEY `idx_teacher_id` (`teacher_id`),
  KEY `idx_is_primary` (`is_primary`),
  CONSTRAINT `fk_class_teachers_class` FOREIGN KEY (`class_id`) REFERENCES `pbl_classes` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_class_teachers_teacher` FOREIGN KEY (`teacher_id`) REFERENCES `core_users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='PBL班级教师关联表（多对多）';

-- ----------------------------
-- Table structure for pbl_groups
-- ----------------------------
-- DROP TABLE IF EXISTS (Removed for safety) `pbl_groups`;
CREATE TABLE IF NOT EXISTS `pbl_groups` (
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
-- DROP TABLE IF EXISTS (Removed for safety) `pbl_group_members`;
CREATE TABLE IF NOT EXISTS `pbl_group_members` (
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
  CONSTRAINT `fk_group_members_user` FOREIGN KEY (`user_id`) REFERENCES `core_users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='PBL小组成员表';

-- ----------------------------
-- Table structure for pbl_learning_progress
-- ----------------------------
CREATE TABLE IF NOT EXISTS `pbl_learning_progress` (
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT '进度记录ID',
  `user_id` int(11) NOT NULL COMMENT '学生ID',
  `course_id` bigint(20) NOT NULL COMMENT '课程ID',
  `unit_id` bigint(20) DEFAULT NULL COMMENT '单元ID',
  `resource_id` bigint(20) DEFAULT NULL COMMENT '资源ID',
  `task_id` bigint(20) DEFAULT NULL COMMENT '任务ID',
  `progress_type` enum('resource_view','video_watch','document_read','task_submit','unit_complete') NOT NULL COMMENT '进度类型',
  `progress_value` int(11) DEFAULT '0' COMMENT '进度值（百分比或时长）',
  `status` enum('in_progress','completed') NOT NULL DEFAULT 'in_progress' COMMENT '状态',
  `completed_at` timestamp NULL DEFAULT NULL COMMENT '完成时间',
  `time_spent` int(11) DEFAULT '0' COMMENT '花费时间（秒）',
  `meta_data` json DEFAULT NULL COMMENT '额外数据',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '记录时间',
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_course_id` (`course_id`),
  KEY `idx_unit_id` (`unit_id`),
  KEY `idx_resource_id` (`resource_id`),
  KEY `idx_task_id` (`task_id`),
  KEY `idx_progress_type` (`progress_type`),
  KEY `idx_status` (`status`),
  KEY `idx_created_at` (`created_at`),
  KEY `idx_user_resource_latest` (`user_id`, `resource_id`, `created_at`),
  KEY `idx_user_task_latest` (`user_id`, `task_id`, `created_at`),
  CONSTRAINT `fk_learning_progress_user` FOREIGN KEY (`user_id`) REFERENCES `core_users` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_learning_progress_course` FOREIGN KEY (`course_id`) REFERENCES `pbl_courses` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_learning_progress_unit` FOREIGN KEY (`unit_id`) REFERENCES `pbl_units` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_learning_progress_resource` FOREIGN KEY (`resource_id`) REFERENCES `pbl_resources` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_learning_progress_task` FOREIGN KEY (`task_id`) REFERENCES `pbl_tasks` (`id`) ON DELETE CASCADE
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
-- DROP TABLE IF EXISTS (Removed for safety) `pbl_school_courses`;
CREATE TABLE IF NOT EXISTS `pbl_school_courses` (
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
  CONSTRAINT `fk_school_courses_school` FOREIGN KEY (`school_id`) REFERENCES `core_schools` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_school_courses_course` FOREIGN KEY (`course_id`) REFERENCES `pbl_courses` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='学校课程分配表（平台管理员为学校分配课程）';

-- ----------------------------
-- 课程表字段说明更新
-- ----------------------------
-- 注意：school_id 字段语义为"课程创建者所属学校"
-- NULL 表示平台课程，非 NULL 表示学校课程

-- ==========================================================================================================
-- 学习进度追踪增强说明
-- ==========================================================================================================
-- 
-- pbl_learning_progress 表已包含以下增强字段：
--   - status: 学习状态（in_progress/completed）
--   - completed_at: 完成时间
--   - updated_at: 最后更新时间
--   - task_id: 关联任务ID
-- 
-- 相关索引已在表定义中包含，无需额外添加
-- ==========================================================================================================

-- ==========================================
-- 项目成果与评价体系
-- ==========================================

-- ----------------------------
-- Table structure for pbl_project_outputs
-- 项目成果表：存储学生的项目作品、报告、代码等成果
-- ----------------------------
-- DROP TABLE IF EXISTS (Removed for safety) `pbl_project_outputs`;
CREATE TABLE IF NOT EXISTS `pbl_project_outputs` (
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
-- DROP TABLE IF EXISTS (Removed for safety) `pbl_assessments`;
CREATE TABLE IF NOT EXISTS `pbl_assessments` (
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
-- DROP TABLE IF EXISTS (Removed for safety) `pbl_assessment_templates`;
CREATE TABLE IF NOT EXISTS `pbl_assessment_templates` (
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
-- DROP TABLE IF EXISTS (Removed for safety) `pbl_ethics_cases`;
CREATE TABLE IF NOT EXISTS `pbl_ethics_cases` (
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
-- DROP TABLE IF EXISTS (Removed for safety) `pbl_ethics_activities`;
CREATE TABLE IF NOT EXISTS `pbl_ethics_activities` (
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
-- DROP TABLE IF EXISTS (Removed for safety) `pbl_datasets`;
CREATE TABLE IF NOT EXISTS `pbl_datasets` (
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
-- DROP TABLE IF EXISTS (Removed for safety) `pbl_student_portfolios`;
CREATE TABLE IF NOT EXISTS `pbl_student_portfolios` (
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
-- DROP TABLE IF EXISTS (Removed for safety) `pbl_parent_relations`;
CREATE TABLE IF NOT EXISTS `pbl_parent_relations` (
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
-- DROP TABLE IF EXISTS (Removed for safety) `pbl_external_experts`;
CREATE TABLE IF NOT EXISTS `pbl_external_experts` (
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
-- DROP TABLE IF EXISTS (Removed for safety) `pbl_social_activities`;
CREATE TABLE IF NOT EXISTS `pbl_social_activities` (
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
-- DROP TABLE IF EXISTS (Removed for safety) `pbl_video_play_progress`;
CREATE TABLE IF NOT EXISTS `pbl_video_play_progress` (
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
-- DROP TABLE IF EXISTS (Removed for safety) `pbl_video_play_events`;
CREATE TABLE IF NOT EXISTS `pbl_video_play_events` (
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
-- DROP TABLE IF EXISTS (Removed for safety) `pbl_import_logs`;
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

-- ==========================================
-- 视频观看统计和权限管理
-- ==========================================

-- ==========================================================================================================
-- 跨模块外键约束
-- ==========================================================================================================

-- kb_sharing 表的 course_id 外键约束
-- 注意：如果 kb_sharing 表存在且没有此外键，需要手动执行以下语句：
-- ALTER TABLE `kb_sharing` MODIFY COLUMN `course_id` BIGINT(20) DEFAULT NULL COMMENT '共享给课程ID';
-- ALTER TABLE `kb_sharing` ADD CONSTRAINT `fk_kbs_course` FOREIGN KEY (`course_id`) REFERENCES `pbl_courses` (`id`) ON DELETE CASCADE;

-- 恢复外键检查
SET FOREIGN_KEY_CHECKS = 1;
SET UNIQUE_CHECKS = 1;

-- 提交事务
COMMIT;


-- ==========================================================================================================
-- 数据库结构验证
-- ==========================================================================================================

-- 验证 PBL 模块表数量
SELECT 
    'PBL Module Tables Summary' AS info_type,
    COUNT(*) AS total_pbl_tables
FROM information_schema.tables 
WHERE table_schema = DATABASE() 
  AND table_type = 'BASE TABLE'
  AND table_name LIKE 'pbl_%';

-- 验证 PBL 模块外键约束数量
SELECT 
    'PBL Module Foreign Key Constraints Summary' AS info_type,
    COUNT(*) AS total_foreign_keys
FROM information_schema.table_constraints 
WHERE constraint_schema = DATABASE() 
  AND constraint_type = 'FOREIGN KEY'
  AND table_name LIKE 'pbl_%';

-- 验证 PBL 模块索引数量
SELECT 
    'PBL Module Index Summary' AS info_type,
    COUNT(DISTINCT index_name) AS total_indexes
FROM information_schema.statistics 
WHERE table_schema = DATABASE()
  AND table_name LIKE 'pbl_%';

-- 按功能模块统计表数量
SELECT 
    'PBL Tables by Sub-Module' AS info_type,
    CASE 
        WHEN table_name IN ('pbl_courses', 'pbl_course_teachers', 'pbl_units', 'pbl_resources', 'pbl_tasks', 'pbl_school_courses') THEN 'Course Management'
        WHEN table_name IN ('pbl_projects', 'pbl_project_outputs') THEN 'Project Management'
        WHEN table_name IN ('pbl_classes', 'pbl_class_teachers', 'pbl_groups', 'pbl_group_members') THEN 'Class & Group Management'
        WHEN table_name IN ('pbl_course_enrollments', 'pbl_task_progress', 'pbl_learning_progress', 'pbl_learning_logs') THEN 'Learning Management'
        WHEN table_name IN ('pbl_video_watch_records', 'pbl_video_user_permissions', 'pbl_video_play_progress', 'pbl_video_play_events') THEN 'Video Management'
        WHEN table_name IN ('pbl_assessments', 'pbl_assessment_templates') THEN 'Assessment System'
        WHEN table_name IN ('pbl_ethics_cases', 'pbl_ethics_activities') THEN 'Ethics Education'
        WHEN table_name IN ('pbl_student_portfolios', 'pbl_parent_relations', 'pbl_external_experts', 'pbl_social_activities') THEN 'Home-School-Society'
        WHEN table_name IN ('pbl_datasets') THEN 'Resource Management'
        WHEN table_name IN ('pbl_achievements', 'pbl_user_achievements') THEN 'Gamification'
        WHEN table_name IN ('pbl_ai_conversations') THEN 'AI Interaction'
        WHEN table_name IN ('pbl_import_logs') THEN 'School Administration'
        ELSE 'Other'
    END AS sub_module,
    COUNT(*) AS table_count
FROM information_schema.tables 
WHERE table_schema = DATABASE() 
  AND table_type = 'BASE TABLE'
  AND table_name LIKE 'pbl_%'
GROUP BY sub_module
ORDER BY table_count DESC;

-- 列出所有创建的 PBL 表
SELECT 
    table_name AS 'Created PBL Tables',
    ROUND(((data_length + index_length) / 1024), 2) AS 'Size (KB)',
    table_rows AS 'Rows',
    engine AS 'Engine',
    table_collation AS 'Collation',
    CASE 
        WHEN table_comment = '' THEN 'No Comment'
        ELSE table_comment
    END AS 'Comment'
FROM information_schema.tables 
WHERE table_schema = DATABASE() 
  AND table_type = 'BASE TABLE'
  AND table_name LIKE 'pbl_%'
ORDER BY table_name;


-- ==========================================================================================================
-- 执行完成信息
-- ==========================================================================================================

SELECT 
    '==========================================================================================================' AS ' ';

SELECT 
    'CodeHubot PBL Module Initialization Completed Successfully!' AS 'Status',
    VERSION() AS 'MySQL Version',
    DATABASE() AS 'Database Name',
    NOW() AS 'Completion Time';

SELECT 
    '==========================================================================================================' AS ' ';

SELECT 
    'PBL Module Features:' AS 'Information';

SELECT '✓ Course Management (Courses, Units, Resources, Tasks)' AS 'Feature 1';
SELECT '✓ Project Management (Projects, Outputs, Assessments)' AS 'Feature 2';
SELECT '✓ Class & Group Management (Classes, Groups, Members)' AS 'Feature 3';
SELECT '✓ Learning Progress Tracking (Progress, Logs, Video Tracking)' AS 'Feature 4';
SELECT '✓ Video Viewing Management (Watch Records, Permissions)' AS 'Feature 5';
SELECT '✓ Assessment System (Multi-dimensional Evaluation)' AS 'Feature 6';
SELECT '✓ Ethics Education (Cases, Activities)' AS 'Feature 7';
SELECT '✓ Dataset Management (AI Training Resources)' AS 'Feature 8';
SELECT '✓ Home-School-Society Collaboration (Portfolios, Parents, Experts)' AS 'Feature 9';
SELECT '✓ Gamification System (Achievements, Badges)' AS 'Feature 10';

SELECT 
    '==========================================================================================================' AS ' ';

SELECT 
    'Next Steps:' AS 'Information';

SELECT 
    '1. Verify all PBL tables were created correctly' AS 'Step 1';

SELECT 
    '2. Check foreign key constraints are properly established' AS 'Step 2';

SELECT 
    '3. Initialize system data (default settings, templates, etc.)' AS 'Step 3';

SELECT 
    '4. Configure video permissions and viewing limits for schools' AS 'Step 4';

SELECT 
    '5. Import ethics cases and assessment templates' AS 'Step 5';

SELECT 
    '6. Test all PBL module features' AS 'Step 6';

SELECT 
    '7. Backup the complete database structure' AS 'Step 7';

SELECT 
    '==========================================================================================================' AS ' ';

-- ==========================================================================================================
-- 脚本结束
-- ==========================================================================================================
