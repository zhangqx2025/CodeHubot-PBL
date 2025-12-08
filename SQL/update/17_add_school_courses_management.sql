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
