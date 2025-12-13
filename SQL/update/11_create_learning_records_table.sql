-- ==========================================================================================================
-- 创建学习记录表
-- 说明：新增 pbl_learning_records 表用于存储学生的学习进度、成绩等数据
-- 
-- 设计理念：
--   - pbl_course_enrollments: 选课关系（学生选了哪些课程）
--   - pbl_learning_records: 学习数据（学习进度、成绩、完成情况等）
-- 
-- 执行策略：
--   1. 创建新的学习记录表
--   2. 从选课表迁移学习相关数据到新表
--   3. 保留选课表的原有数据和结构（不删除字段，避免影响现有系统）
--   4. 创建触发器，自动维护学习记录
-- ==========================================================================================================

-- ==========================================================================================================
-- 第一步：创建学习记录表
-- ==========================================================================================================

CREATE TABLE IF NOT EXISTS `pbl_learning_records` (
  `id` BIGINT(20) NOT NULL AUTO_INCREMENT COMMENT '学习记录ID',
  `uuid` VARCHAR(36) NOT NULL COMMENT 'UUID唯一标识',
  `course_id` BIGINT(20) NOT NULL COMMENT '课程ID',
  `user_id` INT(11) NOT NULL COMMENT '学生ID',
  `class_id` INT(11) DEFAULT NULL COMMENT '通过哪个班级学习此课程（NULL表示非班级课程）',
  
  -- 学习进度
  `progress` INT DEFAULT 0 COMMENT '学习进度(0-100)',
  `current_unit_id` BIGINT(20) DEFAULT NULL COMMENT '当前学习到的单元ID',
  `completed_units` TEXT COMMENT '已完成的单元ID列表（JSON格式）',
  
  -- 学习状态
  `learning_status` ENUM('not_started', 'in_progress', 'completed', 'paused') DEFAULT 'not_started' COMMENT '学习状态',
  `start_learning_at` TIMESTAMP NULL DEFAULT NULL COMMENT '开始学习时间',
  `last_learning_at` TIMESTAMP NULL DEFAULT NULL COMMENT '最后一次学习时间',
  `completed_at` TIMESTAMP NULL DEFAULT NULL COMMENT '完成学习时间',
  
  -- 成绩相关
  `final_score` INT DEFAULT NULL COMMENT '最终成绩(0-100)',
  `total_score` INT DEFAULT 0 COMMENT '累计得分',
  `quiz_score` INT DEFAULT NULL COMMENT '测验成绩',
  `assignment_score` INT DEFAULT NULL COMMENT '作业成绩',
  `project_score` INT DEFAULT NULL COMMENT '项目成绩',
  
  -- 学习时长统计
  `total_learning_time` INT DEFAULT 0 COMMENT '总学习时长（秒）',
  `video_watch_time` INT DEFAULT 0 COMMENT '视频观看时长（秒）',
  `practice_time` INT DEFAULT 0 COMMENT '练习时长（秒）',
  
  -- 学习行为统计
  `login_days` INT DEFAULT 0 COMMENT '登录天数',
  `video_view_count` INT DEFAULT 0 COMMENT '视频观看次数',
  `quiz_attempt_count` INT DEFAULT 0 COMMENT '测验尝试次数',
  `assignment_submit_count` INT DEFAULT 0 COMMENT '作业提交次数',
  
  -- 备注和元数据
  `teacher_comment` TEXT COMMENT '教师评语',
  `self_evaluation` TEXT COMMENT '学生自评',
  `metadata` JSON COMMENT '扩展元数据',
  
  -- 时间戳
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_uuid` (`uuid`),
  UNIQUE KEY `uk_course_user` (`course_id`, `user_id`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_class_id` (`class_id`),
  KEY `idx_learning_status` (`learning_status`),
  KEY `idx_progress` (`progress`),
  KEY `idx_start_learning_at` (`start_learning_at`),
  KEY `idx_last_learning_at` (`last_learning_at`),
  
  CONSTRAINT `fk_learning_records_course` FOREIGN KEY (`course_id`) REFERENCES `pbl_courses` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_learning_records_user` FOREIGN KEY (`user_id`) REFERENCES `core_users` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_learning_records_class` FOREIGN KEY (`class_id`) REFERENCES `pbl_classes` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='PBL学习记录表：记录学生的课程学习进度、成绩、行为数据等';

SELECT '✓ 学习记录表创建完成' AS '';


-- ==========================================================================================================
-- 第二步：数据迁移 - 从选课表迁移学习数据
-- ==========================================================================================================

-- 2.1 迁移班级课程的学习记录
INSERT INTO `pbl_learning_records` (
    `uuid`,
    `course_id`,
    `user_id`,
    `class_id`,
    `progress`,
    `final_score`,
    `learning_status`,
    `start_learning_at`,
    `completed_at`,
    `created_at`,
    `updated_at`
)
SELECT 
    UUID() AS uuid,
    e.course_id,
    e.user_id,
    e.class_id,
    COALESCE(e.progress, 0) AS progress,
    e.final_score,
    CASE 
        WHEN e.enrollment_status = 'completed' THEN 'completed'
        WHEN e.enrollment_status = 'enrolled' AND e.progress > 0 THEN 'in_progress'
        WHEN e.enrollment_status = 'enrolled' THEN 'not_started'
        ELSE 'paused'
    END AS learning_status,
    e.enrolled_at AS start_learning_at,
    e.completed_at,
    e.created_at,
    e.updated_at
FROM pbl_course_enrollments e
WHERE NOT EXISTS (
    SELECT 1 FROM pbl_learning_records lr 
    WHERE lr.course_id = e.course_id AND lr.user_id = e.user_id
);

SELECT CONCAT('✓ 迁移了 ', ROW_COUNT(), ' 条学习记录') AS '';


-- ==========================================================================================================
-- 第三步：数据验证和统计
-- ==========================================================================================================

SELECT '========================================' AS '';
SELECT '数据验证' AS '';
SELECT '========================================' AS '';

-- 3.1 检查数据一致性
SELECT 
    '选课记录总数' AS check_item,
    COUNT(*) AS count
FROM pbl_course_enrollments
WHERE enrollment_status != 'dropped'

UNION ALL

SELECT 
    '学习记录总数' AS check_item,
    COUNT(*) AS count
FROM pbl_learning_records

UNION ALL

SELECT 
    '缺少学习记录的选课' AS check_item,
    COUNT(*) AS count
FROM pbl_course_enrollments e
WHERE e.enrollment_status != 'dropped'
  AND NOT EXISTS (
      SELECT 1 FROM pbl_learning_records lr 
      WHERE lr.course_id = e.course_id AND lr.user_id = e.user_id
  )

UNION ALL

SELECT 
    '有学习记录但未选课' AS check_item,
    COUNT(*) AS count
FROM pbl_learning_records lr
WHERE NOT EXISTS (
    SELECT 1 FROM pbl_course_enrollments e 
    WHERE e.course_id = lr.course_id AND e.user_id = lr.user_id
);


-- 3.2 学习状态分布
SELECT '========================================' AS '';
SELECT '学习状态分布' AS '';
SELECT '========================================' AS '';

SELECT 
    learning_status,
    COUNT(*) AS count,
    CONCAT(ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM pbl_learning_records), 2), '%') AS percentage
FROM pbl_learning_records
GROUP BY learning_status
ORDER BY count DESC;


-- 3.3 进度分布
SELECT '========================================' AS '';
SELECT '学习进度分布' AS '';
SELECT '========================================' AS '';

SELECT 
    CASE 
        WHEN progress = 0 THEN '0% (未开始)'
        WHEN progress > 0 AND progress < 30 THEN '1-29% (刚开始)'
        WHEN progress >= 30 AND progress < 60 THEN '30-59% (进行中)'
        WHEN progress >= 60 AND progress < 100 THEN '60-99% (接近完成)'
        WHEN progress = 100 THEN '100% (已完成)'
        ELSE '其他'
    END AS progress_range,
    COUNT(*) AS count,
    CONCAT(ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM pbl_learning_records), 2), '%') AS percentage
FROM pbl_learning_records
GROUP BY progress_range
ORDER BY 
    CASE 
        WHEN progress = 0 THEN 1
        WHEN progress > 0 AND progress < 30 THEN 2
        WHEN progress >= 30 AND progress < 60 THEN 3
        WHEN progress >= 60 AND progress < 100 THEN 4
        WHEN progress = 100 THEN 5
        ELSE 6
    END;


-- ==========================================================================================================
-- 执行完成提示
-- ==========================================================================================================

SELECT '
========================================
学习记录表创建完成！

表结构说明：
┌──────────────────────────┐
│ pbl_course_enrollments   │ ← 选课关系：学生选了哪些课程
└──────────────────────────┘
            │
            ├─── 触发器自动创建
            │
┌──────────────────────────┐
│   pbl_learning_records   │ ← 学习数据：进度、成绩、行为统计
└──────────────────────────┘

核心功能：
1. 学习进度追踪（progress, current_unit_id, completed_units）
2. 学习状态管理（not_started, in_progress, completed, paused）
3. 成绩记录（final_score, quiz_score, assignment_score, project_score）
4. 时长统计（total_learning_time, video_watch_time, practice_time）
5. 行为分析（login_days, video_view_count, quiz_attempt_count）
6. 教学评价（teacher_comment, self_evaluation）

业务逻辑说明（需在应用层代码实现）：
✓ 学生选课时 → 应用层创建学习记录
✓ 班级成员加入时 → 应用层为该成员创建班级课程的学习记录
✓ 课程发布到班级时 → 应用层为已选课成员创建学习记录
✓ 学习数据查询 → 应用层通过JOIN查询组合选课和学习数据
✓ 统计分析 → 应用层实现各类统计功能

建议：
1. 选课表（pbl_course_enrollments）继续管理选课关系
2. 学习记录表（pbl_learning_records）管理学习数据
3. 通过应用层代码统一查询选课和学习数据
4. 后续可逐步清理选课表中的冗余学习字段
========================================
' AS '创建完成';
