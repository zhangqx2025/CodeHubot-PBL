-- ==========================================
-- PBL 系统增强表结构更新脚本
-- ==========================================
-- 说明：
--   本脚本用于添加符合《北京市中小学人工智能教育地方课程纲要（试行）（2025年版）》
--   要求的PBL系统增强功能表，包括：
--   1. 项目成果管理
--   2. 多维度评价体系
--   3. 伦理教育支持
--   4. 数据集管理
--   5. 学生成长档案
--   6. 家校社协同
--
-- 使用方式：
--   mysql -u username -p database_name < 09_add_pbl_enhancement_tables.sql
--
-- 版本：v1.0
-- 日期：2024-12-08
-- ==========================================

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- ==========================================
-- P0 核心表：项目成果与评价体系
-- ==========================================

-- ----------------------------
-- Table structure for pbl_project_outputs
-- 项目成果表：存储学生的项目作品、报告、代码等成果
-- 对应课纲要求：完整的项目周期体验、成果展示与答辩
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
-- 对应课纲要求：过程性评价(60%)+总结性评价(40%)、多元评价主体
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
  `dimensions` json NOT NULL COMMENT '评价维度与分数 [{"dimension":"技术能力","score":85,"weight":0.3,"comment":"..."},...]',
  `total_score` decimal(5,2) DEFAULT NULL COMMENT '总分',
  `max_score` decimal(5,2) DEFAULT '100.00' COMMENT '满分',
  `comments` text COMMENT '评语',
  `strengths` text COMMENT '优点',
  `improvements` text COMMENT '改进建议',
  `tags` json DEFAULT NULL COMMENT '标签（如：创新性强、团队协作好）',
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
-- 对应课纲要求：不同学段的差异化评价标准
-- ----------------------------
DROP TABLE IF EXISTS `pbl_assessment_templates`;
CREATE TABLE `pbl_assessment_templates` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '模板ID',
  `uuid` varchar(36) NOT NULL COMMENT 'UUID',
  `name` varchar(100) NOT NULL COMMENT '模板名称',
  `description` text COMMENT '模板描述',
  `applicable_to` enum('project','task','output') NOT NULL COMMENT '适用对象',
  `grade_level` varchar(50) DEFAULT NULL COMMENT '适用学段（如：1-2年级、3-4年级、5-6年级、7-9年级、10-12年级）',
  `dimensions` json NOT NULL COMMENT '评价维度配置 [{"name":"技术能力","weight":0.3,"criteria":"掌握基本编程","levels":[...]},...]',
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
-- P1 重要表：伦理教育与资源管理
-- ==========================================

-- ----------------------------
-- Table structure for pbl_ethics_cases
-- 伦理案例库表：存储AI伦理相关的教学案例
-- 对应课纲要求：人工智能伦理与社会责任（三大培养目标之一）
-- ----------------------------
DROP TABLE IF EXISTS `pbl_ethics_cases`;
CREATE TABLE `pbl_ethics_cases` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '案例ID',
  `uuid` varchar(36) NOT NULL COMMENT 'UUID',
  `title` varchar(200) NOT NULL COMMENT '案例标题',
  `description` text NOT NULL COMMENT '案例描述',
  `content` longtext COMMENT '案例内容（Markdown格式）',
  `grade_level` varchar(50) DEFAULT NULL COMMENT '适用学段（如：1-2年级）',
  `ethics_topics` json NOT NULL COMMENT '涉及的伦理议题 ["数据隐私","算法偏见","技术滥用","AI幻觉","认知外包"]',
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
-- 对应课纲要求：伦理思辨讨论、批判性思维培养
-- ----------------------------
DROP TABLE IF EXISTS `pbl_ethics_activities`;
CREATE TABLE `pbl_ethics_activities` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '活动ID',
  `uuid` varchar(36) NOT NULL COMMENT 'UUID',
  `case_id` bigint(20) DEFAULT NULL COMMENT '关联案例ID',
  `course_id` bigint(20) DEFAULT NULL COMMENT '关联课程ID',
  `unit_id` bigint(20) DEFAULT NULL COMMENT '关联单元ID',
  `activity_type` enum('debate','case_analysis','role_play','discussion','reflection') NOT NULL COMMENT '活动类型：辩论/案例分析/角色扮演/讨论/反思',
  `title` varchar(200) NOT NULL COMMENT '活动标题',
  `description` text COMMENT '活动描述',
  `participants` json DEFAULT NULL COMMENT '参与学生ID列表',
  `group_id` int(11) DEFAULT NULL COMMENT '小组ID',
  `facilitator_id` int(11) DEFAULT NULL COMMENT '主持人/教师ID',
  `status` enum('planned','ongoing','completed','cancelled') DEFAULT 'planned' COMMENT '状态',
  `discussion_records` json DEFAULT NULL COMMENT '讨论记录 [{"student_id":1,"viewpoint":"...","time":"..."}]',
  `conclusions` text COMMENT '活动总结',
  `reflections` json DEFAULT NULL COMMENT '学生反思记录 [{"student_id":1,"content":"...","insights":["..."]}]',
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
-- 对应课纲要求：数据采集与处理、数据集构建、数据对AI的重要性
-- ----------------------------
DROP TABLE IF EXISTS `pbl_datasets`;
CREATE TABLE `pbl_datasets` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '数据集ID',
  `uuid` varchar(36) NOT NULL COMMENT 'UUID',
  `name` varchar(100) NOT NULL COMMENT '数据集名称',
  `description` text COMMENT '数据集描述',
  `data_type` enum('image','text','audio','video','tabular','mixed') NOT NULL COMMENT '数据类型',
  `category` varchar(50) DEFAULT NULL COMMENT '分类（如：垃圾分类、植物识别、情绪识别）',
  `file_url` varchar(500) DEFAULT NULL COMMENT '数据集文件URL',
  `file_size` bigint(20) DEFAULT NULL COMMENT '文件大小(字节)',
  `sample_count` int(11) DEFAULT NULL COMMENT '样本数量',
  `class_count` int(11) DEFAULT NULL COMMENT '类别数量',
  `classes` json DEFAULT NULL COMMENT '类别列表 ["可回收","有害垃圾","厨余垃圾","其他垃圾"]',
  `is_labeled` tinyint(1) DEFAULT '0' COMMENT '是否已标注',
  `label_format` varchar(50) DEFAULT NULL COMMENT '标注格式（如：COCO、YOLO、CSV）',
  `split_ratio` json DEFAULT NULL COMMENT '数据集划分比例 {"train":0.7,"val":0.15,"test":0.15}',
  `grade_level` varchar(50) DEFAULT NULL COMMENT '适用学段',
  `applicable_projects` json DEFAULT NULL COMMENT '适用项目列表',
  `source` varchar(200) DEFAULT NULL COMMENT '来源',
  `license` varchar(100) DEFAULT NULL COMMENT '许可协议',
  `preview_images` json DEFAULT NULL COMMENT '预览图URL列表',
  `download_count` int(11) DEFAULT '0' COMMENT '下载次数',
  `creator_id` int(11) DEFAULT NULL COMMENT '创建者ID',
  `school_id` int(11) DEFAULT NULL COMMENT '所属学校ID（学校自建数据集）',
  `is_public` tinyint(1) DEFAULT '1' COMMENT '是否公开',
  `quality_score` decimal(3,2) DEFAULT NULL COMMENT '数据质量评分（0-5分）',
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
-- P2 增强表：家校社协同与成长档案
-- ==========================================

-- ----------------------------
-- Table structure for pbl_student_portfolios
-- 学生成长档案表：记录学生的学习轨迹和能力成长
-- 对应课纲要求：电子学习档案、智能学习分析工具、可视化动态发展记录
-- ----------------------------
DROP TABLE IF EXISTS `pbl_student_portfolios`;
CREATE TABLE `pbl_student_portfolios` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '档案ID',
  `uuid` varchar(36) NOT NULL COMMENT 'UUID',
  `student_id` int(11) NOT NULL COMMENT '学生ID',
  `school_year` varchar(20) NOT NULL COMMENT '学年（如：2024-2025）',
  `grade_level` varchar(50) NOT NULL COMMENT '学段（如：5-6年级）',
  `completed_projects` json DEFAULT NULL COMMENT '完成的项目列表 [{"project_id":1,"title":"...","score":85}]',
  `achievements` json DEFAULT NULL COMMENT '获得的成就列表',
  `skill_assessment` json DEFAULT NULL COMMENT '能力评估 {"技术能力":85,"创新能力":90,"协作能力":88,"伦理意识":92}',
  `growth_trajectory` json DEFAULT NULL COMMENT '成长轨迹数据（用于雷达图等可视化）',
  `highlights` json DEFAULT NULL COMMENT '亮点作品ID列表',
  `total_learning_hours` int(11) DEFAULT '0' COMMENT '累计学习时长（小时）',
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
-- 对应课纲要求：家校社的整体协同、家长参与机制
-- ----------------------------
DROP TABLE IF EXISTS `pbl_parent_relations`;
CREATE TABLE `pbl_parent_relations` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '关系ID',
  `parent_user_id` int(11) NOT NULL COMMENT '家长用户ID（关联aiot_core_users，role需为parent）',
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
-- 对应课纲要求：多元评价主体、行业专家参与
-- ----------------------------
DROP TABLE IF EXISTS `pbl_external_experts`;
CREATE TABLE `pbl_external_experts` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '专家ID',
  `uuid` varchar(36) NOT NULL COMMENT 'UUID',
  `name` varchar(100) NOT NULL COMMENT '姓名',
  `organization` varchar(200) DEFAULT NULL COMMENT '所属单位',
  `title` varchar(100) DEFAULT NULL COMMENT '职称/职位',
  `expertise_areas` json DEFAULT NULL COMMENT '专业领域 ["人工智能","机器学习","计算机视觉"]',
  `bio` text COMMENT '个人简介',
  `email` varchar(255) DEFAULT NULL COMMENT '邮箱',
  `phone` varchar(20) DEFAULT NULL COMMENT '电话',
  `avatar` varchar(255) DEFAULT NULL COMMENT '头像URL',
  `is_active` tinyint(1) DEFAULT '1' COMMENT '是否活跃',
  `participated_projects` int(11) DEFAULT '0' COMMENT '参与评审项目数',
  `avg_rating` decimal(3,2) DEFAULT NULL COMMENT '平均评分（学生对专家的评价）',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_uuid` (`uuid`),
  KEY `idx_is_active` (`is_active`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='PBL外部专家表';

-- ----------------------------
-- Table structure for pbl_social_activities
-- 社会实践活动表：记录家校社协同的实践活动
-- 对应课纲要求：拓展教育场域、高校企业资源、社会协同育人
-- ----------------------------
DROP TABLE IF EXISTS `pbl_social_activities`;
CREATE TABLE `pbl_social_activities` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '活动ID',
  `uuid` varchar(36) NOT NULL COMMENT 'UUID',
  `title` varchar(200) NOT NULL COMMENT '活动标题',
  `description` text COMMENT '活动描述',
  `activity_type` enum('company_visit','lab_tour','workshop','competition','exhibition','volunteer','lecture') NOT NULL COMMENT '活动类型',
  `organizer` varchar(200) DEFAULT NULL COMMENT '组织方',
  `partner_organization` varchar(200) DEFAULT NULL COMMENT '合作单位（高校/科研院所/企业）',
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
  `feedback` json DEFAULT NULL COMMENT '学生反馈 [{"student_id":1,"rating":5,"comment":"..."}]',
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
-- 初始化数据：插入系统预设的评价模板
-- ==========================================

-- 插入第一学段（1-2年级）评价模板
INSERT INTO `pbl_assessment_templates` (`uuid`, `name`, `description`, `applicable_to`, `grade_level`, `dimensions`, `is_system`, `is_active`) VALUES
(UUID(), '第一学段项目评价模板', '适用于1-2年级学生的PBL项目评价', 'project', '1-2年级', 
'[
  {"name":"AI认知","weight":0.3,"criteria":"能够识别身边的AI产品，了解AI基本概念","levels":["优秀","良好","合格","需改进"]},
  {"name":"动手实践","weight":0.3,"criteria":"能够在教师指导下体验AI工具","levels":["优秀","良好","合格","需改进"]},
  {"name":"兴趣培养","weight":0.2,"criteria":"对AI表现出好奇心和探索热情","levels":["优秀","良好","合格","需改进"]},
  {"name":"团队协作","weight":0.2,"criteria":"能够与同学合作完成简单任务","levels":["优秀","良好","合格","需改进"]}
]', 1, 1);

-- 插入第二学段（3-4年级）评价模板
INSERT INTO `pbl_assessment_templates` (`uuid`, `name`, `description`, `applicable_to`, `grade_level`, `dimensions`, `is_system`, `is_active`) VALUES
(UUID(), '第二学段项目评价模板', '适用于3-4年级学生的PBL项目评价', 'project', '3-4年级', 
'[
  {"name":"技术理解","weight":0.25,"criteria":"理解AI技术的基本原理和工作方式","levels":["优秀","良好","合格","需改进"]},
  {"name":"实践能力","weight":0.25,"criteria":"能够使用简单的AI工具实现基础应用","levels":["优秀","良好","合格","需改进"]},
  {"name":"问题解决","weight":0.2,"criteria":"能够用AI技术解决简单的实际问题","levels":["优秀","良好","合格","需改进"]},
  {"name":"创新思维","weight":0.15,"criteria":"能够提出创新的想法和解决方案","levels":["优秀","良好","合格","需改进"]},
  {"name":"团队协作","weight":0.15,"criteria":"在小组中积极参与和贡献","levels":["优秀","良好","合格","需改进"]}
]', 1, 1);

-- 插入第三学段（5-6年级）评价模板
INSERT INTO `pbl_assessment_templates` (`uuid`, `name`, `description`, `applicable_to`, `grade_level`, `dimensions`, `is_system`, `is_active`) VALUES
(UUID(), '第三学段项目评价模板', '适用于5-6年级学生的PBL项目评价', 'project', '5-6年级', 
'[
  {"name":"技术能力","weight":0.25,"criteria":"掌握数据采集、模型训练的基本方法","levels":["优秀","良好","合格","需改进"]},
  {"name":"应用能力","weight":0.25,"criteria":"能够开发简单的AI应用系统","levels":["优秀","良好","合格","需改进"]},
  {"name":"创新能力","weight":0.2,"criteria":"能够创造性地应用AI技术解决问题","levels":["优秀","良好","合格","需改进"]},
  {"name":"系统思维","weight":0.15,"criteria":"具备初步的系统设计思维","levels":["优秀","良好","合格","需改进"]},
  {"name":"伦理意识","weight":0.15,"criteria":"认识到AI应用中的伦理问题","levels":["优秀","良好","合格","需改进"]}
]', 1, 1);

-- 插入第四学段（7-9年级）评价模板
INSERT INTO `pbl_assessment_templates` (`uuid`, `name`, `description`, `applicable_to`, `grade_level`, `dimensions`, `is_system`, `is_active`) VALUES
(UUID(), '第四学段项目评价模板', '适用于7-9年级学生的PBL项目评价', 'project', '7-9年级', 
'[
  {"name":"技术实现","weight":0.3,"criteria":"掌握机器学习算法和模型训练","levels":["优秀","良好","合格","需改进"]},
  {"name":"系统设计","weight":0.25,"criteria":"能够完成需求分析到部署的完整流程","levels":["优秀","良好","合格","需改进"]},
  {"name":"创新性","weight":0.2,"criteria":"解决方案具有创新性和实用性","levels":["优秀","良好","合格","需改进"]},
  {"name":"工程能力","weight":0.15,"criteria":"代码规范、文档完整、可维护性好","levels":["优秀","良好","合格","需改进"]},
  {"name":"伦理思考","weight":0.1,"criteria":"深入思考技术应用的伦理和社会影响","levels":["优秀","良好","合格","需改进"]}
]', 1, 1);

-- 插入高中学段（10-12年级）评价模板
INSERT INTO `pbl_assessment_templates` (`uuid`, `name`, `description`, `applicable_to`, `grade_level`, `dimensions`, `is_system`, `is_active`) VALUES
(UUID(), '高中学段项目评价模板', '适用于10-12年级学生的PBL项目评价', 'project', '10-12年级', 
'[
  {"name":"技术深度","weight":0.3,"criteria":"深度学习、强化学习等前沿技术的掌握","levels":["优秀","良好","合格","需改进"]},
  {"name":"创新突破","weight":0.25,"criteria":"项目具有技术创新或应用创新","levels":["优秀","良好","合格","需改进"]},
  {"name":"系统完整性","weight":0.2,"criteria":"系统设计完整、功能实现完善","levels":["优秀","良好","合格","需改进"]},
  {"name":"工程质量","weight":0.15,"criteria":"代码质量高、文档规范、可扩展性好","levels":["优秀","良好","合格","需改进"]},
  {"name":"社会价值","weight":0.1,"criteria":"关注技术的社会影响和伦理责任","levels":["优秀","良好","合格","需改进"]}
]', 1, 1);

-- ==========================================
-- 索引优化说明
-- ==========================================
-- 已为所有表添加适当的索引以优化查询性能：
-- 1. 主键索引（自动创建）
-- 2. UUID唯一索引（保证全局唯一性）
-- 3. 外键索引（提升JOIN性能）
-- 4. 常用查询字段索引（如：学段、状态、类型等）
-- 5. 组合索引（用于复合条件查询）

SET FOREIGN_KEY_CHECKS = 1;

-- ==========================================
-- 脚本执行完成
-- ==========================================
-- 提示：
-- 1. 执行后请检查所有表是否创建成功
-- 2. 检查外键约束是否正确建立
-- 3. 查看评价模板是否正确插入
-- 4. 建议在测试环境先验证后再应用到生产环境
-- ==========================================
