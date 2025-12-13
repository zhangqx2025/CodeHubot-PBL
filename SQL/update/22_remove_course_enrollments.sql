-- ==========================================================================================================
-- 删除选课表 pbl_course_enrollments
-- ==========================================================================================================
-- 文件: 22_remove_course_enrollments.sql
-- 版本: 1.0.0
-- 创建日期: 2025-12-13
-- 兼容版本: MySQL 5.7-8.0
-- 说明: 
--   1. 删除 pbl_course_enrollments 表及其所有相关约束、触发器、视图
--   2. 访问控制逻辑改为基于 pbl_class_members 表
--   3. 学习进度、成绩等数据由其他表（如 pbl_task_progress、pbl_learning_progress）记录
--   4. 不再需要"选课"操作，课程由管理员/教师分配给班级
--   5. 本脚本执行前请确保已备份数据
-- ==========================================================================================================

SET NAMES utf8mb4 COLLATE utf8mb4_unicode_ci;

-- ==========================================================================================================
-- 第一步：删除相关触发器
-- ==========================================================================================================

SELECT '开始删除相关触发器...' AS status;

-- 删除班级成员加入时自动创建学习记录的触发器
DROP TRIGGER IF EXISTS `trg_after_class_member_insert`;
SELECT '已删除触发器: trg_after_class_member_insert' AS status;

-- 删除课程发布时自动创建学习记录的触发器
DROP TRIGGER IF EXISTS `trg_after_course_publish`;
SELECT '已删除触发器: trg_after_course_publish' AS status;

-- ==========================================================================================================
-- 第二步：删除相关视图
-- ==========================================================================================================

SELECT '开始删除相关视图...' AS status;

-- 删除学生可访问课程列表视图
DROP VIEW IF EXISTS `view_student_accessible_courses`;
SELECT '已删除视图: view_student_accessible_courses' AS status;

-- 删除班级课程学习统计视图
DROP VIEW IF EXISTS `view_class_course_learning_stats`;
SELECT '已删除视图: view_class_course_learning_stats' AS status;

-- ==========================================================================================================
-- 第三步：检查并显示将要删除的数据
-- ==========================================================================================================

SELECT '检查将要删除的数据...' AS status;

-- 统计选课记录总数
SELECT 
    '选课记录总数' AS item,
    COUNT(*) AS count
FROM `pbl_course_enrollments`;

-- 按状态统计
SELECT 
    enrollment_status AS status,
    COUNT(*) AS count
FROM `pbl_course_enrollments`
GROUP BY enrollment_status;

-- ==========================================================================================================
-- 第四步：删除 pbl_course_enrollments 表
-- ==========================================================================================================

SELECT '开始删除 pbl_course_enrollments 表...' AS status;

-- 删除表（会自动删除所有外键约束）
DROP TABLE IF EXISTS `pbl_course_enrollments`;

SELECT '已删除表: pbl_course_enrollments' AS status;

-- ==========================================================================================================
-- 第五步：验证删除结果
-- ==========================================================================================================

SELECT '验证删除结果...' AS status;

-- 检查表是否已删除
SET @table_exists = (
    SELECT COUNT(*)
    FROM information_schema.TABLES
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = 'pbl_course_enrollments'
);

SELECT 
    CASE 
        WHEN @table_exists = 0 THEN '✓ pbl_course_enrollments 表已成功删除'
        ELSE '✗ pbl_course_enrollments 表仍然存在'
    END AS verification_result;

-- 检查触发器是否已删除
SELECT 
    CASE 
        WHEN COUNT(*) = 0 THEN '✓ 所有相关触发器已成功删除'
        ELSE CONCAT('✗ 仍有 ', COUNT(*), ' 个相关触发器存在')
    END AS trigger_verification
FROM information_schema.TRIGGERS
WHERE TRIGGER_SCHEMA = DATABASE()
  AND (TRIGGER_NAME LIKE '%enrollment%' OR TRIGGER_NAME LIKE '%class_member%');

-- 检查视图是否已删除
SELECT 
    CASE 
        WHEN COUNT(*) = 0 THEN '✓ 所有相关视图已成功删除'
        ELSE CONCAT('✗ 仍有 ', COUNT(*), ' 个相关视图存在')
    END AS view_verification
FROM information_schema.VIEWS
WHERE TABLE_SCHEMA = DATABASE()
  AND (TABLE_NAME LIKE '%enrollment%' OR TABLE_NAME LIKE '%accessible_courses%');

-- ==========================================================================================================
-- 第六步：说明新的访问控制逻辑
-- ==========================================================================================================

SELECT '
========================================
删除完成！新的访问控制逻辑：
========================================

✓ 课程访问权限：
  - 班级课程：基于 pbl_class_members 表判断
  - 学生自动可以访问其所在班级的所有课程
  - 不再需要"选课"操作

✓ 学习数据记录：
  - 任务进度：pbl_task_progress 表
  - 学习行为：pbl_learning_progress 表
  - 作业提交：pbl_homework_submissions 表
  - 成绩评定：pbl_homework_submissions 表的 grade 字段

✓ 课程分配：
  - 由管理员或教师将课程分配给班级
  - 班级成员自动获得访问权限

✓ 后续工作：
  1. 更新后端API代码，移除所有 PBLCourseEnrollment 模型的引用
  2. 删除或标记废弃 enrollments.py 中的选课API
  3. 修改 student_courses.py 中的查询逻辑
  4. 修改 learning_progress.py 中的进度统计逻辑
  5. 更新前端代码，移除"选课"相关UI和逻辑

========================================
' AS completion_message;
