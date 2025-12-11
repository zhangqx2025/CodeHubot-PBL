-- ==========================================================================================================
-- 班级课程分配表创建脚本
-- ==========================================================================================================
-- 
-- 脚本名称: 03_add_class_courses.sql
-- 创建日期: 2025-12-10
-- 用途: 添加班级课程分配功能，支持为班级统一分配课程
-- 兼容版本: MySQL 5.7.x, 8.0.x
--
-- ==========================================================================================================

SET NAMES utf8mb4 COLLATE utf8mb4_unicode_ci;
SET FOREIGN_KEY_CHECKS = 0;

-- 开始事务
START TRANSACTION;

-- ----------------------------
-- Table structure for pbl_class_courses
-- 班级课程分配表
-- ----------------------------
CREATE TABLE IF NOT EXISTS `pbl_class_courses` (
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT '分配记录ID',
  `uuid` varchar(36) NOT NULL COMMENT 'UUID唯一标识',
  `class_id` int(11) NOT NULL COMMENT '班级ID',
  `course_id` bigint(20) NOT NULL COMMENT '课程ID',
  `assigned_by` int(11) NOT NULL COMMENT '分配人ID（管理员/教师）',
  `assigned_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '分配时间',
  `start_date` timestamp NULL DEFAULT NULL COMMENT '课程开始时间（NULL表示立即生效）',
  `end_date` timestamp NULL DEFAULT NULL COMMENT '课程结束时间（NULL表示永久有效）',
  `status` enum('active','inactive','completed') DEFAULT 'active' COMMENT '状态：active-激活, inactive-停用, completed-已完成',
  `remarks` varchar(500) DEFAULT NULL COMMENT '备注',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_uuid` (`uuid`),
  UNIQUE KEY `uk_class_course` (`class_id`, `course_id`),
  KEY `idx_class_id` (`class_id`),
  KEY `idx_course_id` (`course_id`),
  KEY `idx_assigned_by` (`assigned_by`),
  KEY `idx_status` (`status`),
  CONSTRAINT `fk_class_courses_class` FOREIGN KEY (`class_id`) REFERENCES `pbl_classes` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_class_courses_course` FOREIGN KEY (`course_id`) REFERENCES `pbl_courses` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_class_courses_assigner` FOREIGN KEY (`assigned_by`) REFERENCES `core_users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='PBL班级课程分配表 - 为班级统一分配课程';

-- 提交事务
COMMIT;

-- 重新启用外键检查
SET FOREIGN_KEY_CHECKS = 1;

-- ==========================================================================================================
-- 验证
-- ==========================================================================================================

SELECT 
    'Table pbl_class_courses created successfully!' AS status,
    NOW() AS completion_time;

SELECT 
    COUNT(*) AS constraint_count
FROM information_schema.table_constraints 
WHERE constraint_schema = DATABASE() 
  AND table_name = 'pbl_class_courses'
  AND constraint_type = 'FOREIGN KEY';

-- ==========================================================================================================
-- 脚本结束
-- ==========================================================================================================
