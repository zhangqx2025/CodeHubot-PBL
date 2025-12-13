-- ==========================================================================================================
-- 验证视图创建脚本
-- 用于验证 11_refactor_enrollment_to_learning_record.sql 中的视图是否创建成功
-- ==========================================================================================================

-- 检查视图是否存在
SELECT '=== 检查视图是否存在 ===' AS '';

SELECT 
    TABLE_NAME AS view_name,
    TABLE_TYPE,
    'EXISTS' AS status
FROM information_schema.TABLES
WHERE TABLE_SCHEMA = DATABASE()
  AND TABLE_TYPE = 'VIEW'
  AND TABLE_NAME IN ('view_student_accessible_courses', 'view_class_course_learning_stats')

UNION ALL

SELECT 
    'view_student_accessible_courses' AS view_name,
    'VIEW' AS TABLE_TYPE,
    'NOT FOUND' AS status
WHERE NOT EXISTS (
    SELECT 1 FROM information_schema.TABLES
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_TYPE = 'VIEW'
      AND TABLE_NAME = 'view_student_accessible_courses'
)

UNION ALL

SELECT 
    'view_class_course_learning_stats' AS view_name,
    'VIEW' AS TABLE_TYPE,
    'NOT FOUND' AS status
WHERE NOT EXISTS (
    SELECT 1 FROM information_schema.TABLES
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_TYPE = 'VIEW'
      AND TABLE_NAME = 'view_class_course_learning_stats'
);


-- 测试视图查询
SELECT '=== 测试视图1：学生可访问的课程列表 ===' AS '';

SELECT 
    student_id,
    course_title,
    class_name,
    difficulty,
    progress,
    learning_status
FROM view_student_accessible_courses
LIMIT 5;


SELECT '=== 测试视图2：班级课程学习统计 ===' AS '';

SELECT 
    class_name,
    course_title,
    total_members,
    learning_count,
    completed_count,
    avg_progress,
    avg_score
FROM view_class_course_learning_stats
LIMIT 5;


-- 显示所有视图
SELECT '=== 数据库中所有视图列表 ===' AS '';

SELECT 
    TABLE_NAME AS view_name,
    CREATE_TIME,
    UPDATE_TIME
FROM information_schema.TABLES
WHERE TABLE_SCHEMA = DATABASE()
  AND TABLE_TYPE = 'VIEW'
ORDER BY TABLE_NAME;


SELECT '
========================================
视图验证完成！

如果看到上面的数据，说明视图创建成功。
如果显示 "NOT FOUND"，说明视图未创建，
需要重新执行 11_refactor_enrollment_to_learning_record.sql
========================================
' AS '验证完成';
