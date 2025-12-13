-- ==========================================================================================================
-- 验证和处理特定班级和课程的数据
-- 班级 UUID: ff7e2094-5e57-4137-b277-4382822b4349
-- 课程 UUID: be921ec1-d4e4-11f0-a641-0242ac140002
-- ==========================================================================================================

-- ==========================================================================================================
-- 第一步：查看当前数据状态
-- ==========================================================================================================

SELECT '=== 班级信息 ===' AS '';

-- 1.1 查看班级基本信息
SELECT 
    id,
    uuid,
    name AS class_name,
    class_type,
    school_id,
    max_students,
    current_members,
    is_active,
    is_open,
    created_at
FROM pbl_classes
WHERE uuid = 'ff7e2094-5e57-4137-b277-4382822b4349';

-- 1.2 查看班级成员列表
SELECT 
    cm.id AS member_id,
    cm.student_id,
    u.name AS student_name,
    u.student_number,
    cm.role,
    cm.is_active,
    cm.joined_at
FROM pbl_class_members cm
LEFT JOIN core_users u ON cm.student_id = u.id
WHERE cm.class_id = (
    SELECT id FROM pbl_classes WHERE uuid = 'ff7e2094-5e57-4137-b277-4382822b4349'
)
ORDER BY cm.joined_at DESC;


SELECT '=== 课程信息 ===' AS '';

-- 1.3 查看课程基本信息
SELECT 
    id,
    uuid,
    title AS course_title,
    class_id,
    class_name,
    difficulty,
    status,
    school_id,
    created_at
FROM pbl_courses
WHERE uuid = 'be921ec1-d4e4-11f0-a641-0242ac140002';

-- 1.4 验证课程是否关联到该班级
SELECT 
    CASE 
        WHEN c.class_id = cls.id THEN '✅ 课程已正确关联到班级'
        WHEN c.class_id IS NULL THEN '❌ 课程未关联任何班级'
        ELSE '❌ 课程关联到其他班级'
    END AS verification_result,
    cls.id AS expected_class_id,
    cls.name AS expected_class_name,
    c.class_id AS actual_class_id,
    c.class_name AS actual_class_name
FROM pbl_courses c
CROSS JOIN pbl_classes cls
WHERE c.uuid = 'be921ec1-d4e4-11f0-a641-0242ac140002'
  AND cls.uuid = 'ff7e2094-5e57-4137-b277-4382822b4349';


SELECT '=== 选课/学习记录情况 ===' AS '';

-- 1.5 查看该课程的选课记录
SELECT 
    e.id AS enrollment_id,
    e.user_id AS student_id,
    u.name AS student_name,
    u.student_number,
    e.enrollment_status,
    e.progress,
    e.final_score,
    e.enrolled_at,
    e.completed_at,
    CASE 
        WHEN cm.id IS NOT NULL THEN '✅ 是班级成员'
        ELSE '❌ 不是班级成员'
    END AS member_status
FROM pbl_course_enrollments e
LEFT JOIN core_users u ON e.user_id = u.id
LEFT JOIN pbl_class_members cm ON cm.student_id = e.user_id 
    AND cm.class_id = (SELECT id FROM pbl_classes WHERE uuid = 'ff7e2094-5e57-4137-b277-4382822b4349')
    AND cm.is_active = 1
WHERE e.course_id = (
    SELECT id FROM pbl_courses WHERE uuid = 'be921ec1-d4e4-11f0-a641-0242ac140002'
)
ORDER BY e.enrolled_at DESC;


SELECT '=== 数据一致性检查 ===' AS '';

-- 1.6 检查是否有班级成员没有学习记录
SELECT 
    '班级成员缺少学习记录' AS issue_type,
    cm.student_id,
    u.name AS student_name,
    u.student_number
FROM pbl_class_members cm
LEFT JOIN core_users u ON cm.student_id = u.id
LEFT JOIN pbl_course_enrollments e ON e.user_id = cm.student_id 
    AND e.course_id = (SELECT id FROM pbl_courses WHERE uuid = 'be921ec1-d4e4-11f0-a641-0242ac140002')
WHERE cm.class_id = (SELECT id FROM pbl_classes WHERE uuid = 'ff7e2094-5e57-4137-b277-4382822b4349')
  AND cm.is_active = 1
  AND e.id IS NULL;

-- 1.7 检查是否有学习记录但不是班级成员（脏数据）
SELECT 
    '存在无效学习记录（不是班级成员）' AS issue_type,
    e.user_id AS student_id,
    u.name AS student_name,
    u.student_number,
    e.enrollment_status,
    e.progress
FROM pbl_course_enrollments e
LEFT JOIN core_users u ON e.user_id = u.id
LEFT JOIN pbl_class_members cm ON cm.student_id = e.user_id 
    AND cm.class_id = (SELECT id FROM pbl_classes WHERE uuid = 'ff7e2094-5e57-4137-b277-4382822b4349')
    AND cm.is_active = 1
WHERE e.course_id = (SELECT id FROM pbl_courses WHERE uuid = 'be921ec1-d4e4-11f0-a641-0242ac140002')
  AND cm.id IS NULL;


-- ==========================================================================================================
-- 第二步：数据修复（如果课程未正确关联到班级）
-- ==========================================================================================================

SELECT '=== 数据修复 ===' AS '';

-- 2.1 如果课程未关联到该班级，则更新关联关系
UPDATE pbl_courses c
INNER JOIN pbl_classes cls ON cls.uuid = 'ff7e2094-5e57-4137-b277-4382822b4349'
SET 
    c.class_id = cls.id,
    c.class_name = cls.name
WHERE c.uuid = 'be921ec1-d4e4-11f0-a641-0242ac140002'
  AND (c.class_id != cls.id OR c.class_id IS NULL);

-- 显示修复结果
SELECT 
    CASE WHEN ROW_COUNT() > 0 
        THEN CONCAT('✅ 已将课程关联到班级（更新了 ', ROW_COUNT(), ' 条记录）')
        ELSE '✅ 课程已正确关联，无需修复'
    END AS fix_result;


-- ==========================================================================================================
-- 第三步：为班级成员创建学习记录（如果不存在）
-- ==========================================================================================================

SELECT '=== 创建学习记录 ===' AS '';

-- 3.1 为所有班级成员创建学习记录
INSERT INTO pbl_course_enrollments (
    course_id,
    user_id,
    class_id,
    enrollment_status,
    enrolled_at,
    progress,
    created_at
)
SELECT 
    c.id AS course_id,
    cm.student_id AS user_id,
    cls.id AS class_id,
    'enrolled' AS enrollment_status,
    NOW() AS enrolled_at,
    0 AS progress,
    NOW() AS created_at
FROM pbl_classes cls
INNER JOIN pbl_class_members cm ON cm.class_id = cls.id AND cm.is_active = 1
INNER JOIN pbl_courses c ON c.class_id = cls.id
WHERE cls.uuid = 'ff7e2094-5e57-4137-b277-4382822b4349'
  AND c.uuid = 'be921ec1-d4e4-11f0-a641-0242ac140002'
  AND NOT EXISTS (
      SELECT 1 
      FROM pbl_course_enrollments e 
      WHERE e.course_id = c.id 
        AND e.user_id = cm.student_id
  );

-- 显示创建结果
SELECT 
    CASE WHEN ROW_COUNT() > 0 
        THEN CONCAT('✅ 已为 ', ROW_COUNT(), ' 名班级成员创建学习记录')
        ELSE '✅ 所有班级成员都已有学习记录，无需创建'
    END AS creation_result;


-- ==========================================================================================================
-- 第四步：清理无效数据（不是班级成员但有学习记录）
-- ==========================================================================================================

SELECT '=== 数据清理 ===' AS '';

-- 4.1 清理无效的学习记录
DELETE e
FROM pbl_course_enrollments e
WHERE e.course_id = (SELECT id FROM pbl_courses WHERE uuid = 'be921ec1-d4e4-11f0-a641-0242ac140002')
  AND NOT EXISTS (
      SELECT 1 
      FROM pbl_class_members cm 
      WHERE cm.class_id = (SELECT id FROM pbl_classes WHERE uuid = 'ff7e2094-5e57-4137-b277-4382822b4349')
        AND cm.student_id = e.user_id 
        AND cm.is_active = 1
  );

-- 显示清理结果
SELECT 
    CASE WHEN ROW_COUNT() > 0 
        THEN CONCAT('⚠️  已清理 ', ROW_COUNT(), ' 条无效学习记录（学生不是班级成员）')
        ELSE '✅ 无需清理，所有学习记录都有效'
    END AS cleanup_result;


-- ==========================================================================================================
-- 第五步：验证修复后的数据
-- ==========================================================================================================

SELECT '=== 最终验证 ===' AS '';

-- 5.1 统计信息
SELECT 
    cls.name AS class_name,
    c.title AS course_title,
    COUNT(DISTINCT cm.student_id) AS total_members,
    COUNT(DISTINCT e.user_id) AS has_learning_record,
    COUNT(DISTINCT CASE WHEN e.enrollment_status = 'enrolled' THEN e.user_id END) AS learning,
    COUNT(DISTINCT CASE WHEN e.enrollment_status = 'completed' THEN e.user_id END) AS completed,
    ROUND(AVG(CASE WHEN e.progress IS NOT NULL THEN e.progress ELSE 0 END), 2) AS avg_progress
FROM pbl_classes cls
INNER JOIN pbl_courses c ON c.class_id = cls.id
LEFT JOIN pbl_class_members cm ON cm.class_id = cls.id AND cm.is_active = 1
LEFT JOIN pbl_course_enrollments e ON e.course_id = c.id AND e.user_id = cm.student_id
WHERE cls.uuid = 'ff7e2094-5e57-4137-b277-4382822b4349'
  AND c.uuid = 'be921ec1-d4e4-11f0-a641-0242ac140002'
GROUP BY cls.name, c.title;

-- 5.2 数据一致性验证
SELECT 
    CASE 
        WHEN missing_count = 0 AND invalid_count = 0 THEN '✅ 数据完全一致，所有班级成员都有学习记录'
        WHEN missing_count > 0 AND invalid_count = 0 THEN CONCAT('⚠️  还有 ', missing_count, ' 名班级成员缺少学习记录')
        WHEN missing_count = 0 AND invalid_count > 0 THEN CONCAT('⚠️  存在 ', invalid_count, ' 条无效学习记录')
        ELSE CONCAT('❌ 数据不一致：缺少 ', missing_count, ' 条，无效 ', invalid_count, ' 条')
    END AS consistency_status
FROM (
    SELECT 
        (SELECT COUNT(*)
         FROM pbl_class_members cm
         WHERE cm.class_id = (SELECT id FROM pbl_classes WHERE uuid = 'ff7e2094-5e57-4137-b277-4382822b4349')
           AND cm.is_active = 1
           AND NOT EXISTS (
               SELECT 1 FROM pbl_course_enrollments e 
               WHERE e.course_id = (SELECT id FROM pbl_courses WHERE uuid = 'be921ec1-d4e4-11f0-a641-0242ac140002')
                 AND e.user_id = cm.student_id
           )
        ) AS missing_count,
        (SELECT COUNT(*)
         FROM pbl_course_enrollments e
         WHERE e.course_id = (SELECT id FROM pbl_courses WHERE uuid = 'be921ec1-d4e4-11f0-a641-0242ac140002')
           AND NOT EXISTS (
               SELECT 1 FROM pbl_class_members cm 
               WHERE cm.class_id = (SELECT id FROM pbl_classes WHERE uuid = 'ff7e2094-5e57-4137-b277-4382822b4349')
                 AND cm.student_id = e.user_id 
                 AND cm.is_active = 1
           )
        ) AS invalid_count
) AS counts;


-- ==========================================================================================================
-- 第六步：生成详细报告
-- ==========================================================================================================

SELECT '=== 详细报告 ===' AS '';

-- 6.1 班级成员学习状态明细
SELECT 
    cm.student_id,
    u.name AS student_name,
    u.student_number,
    cm.role AS class_role,
    CASE 
        WHEN e.id IS NULL THEN '❌ 无学习记录'
        WHEN e.enrollment_status = 'completed' THEN '✅ 已完成'
        WHEN e.enrollment_status = 'enrolled' THEN '📖 学习中'
        ELSE e.enrollment_status
    END AS learning_status,
    COALESCE(e.progress, 0) AS progress,
    e.final_score,
    e.enrolled_at AS start_learning_at,
    e.completed_at
FROM pbl_class_members cm
LEFT JOIN core_users u ON cm.student_id = u.id
LEFT JOIN pbl_course_enrollments e ON e.user_id = cm.student_id 
    AND e.course_id = (SELECT id FROM pbl_courses WHERE uuid = 'be921ec1-d4e4-11f0-a641-0242ac140002')
WHERE cm.class_id = (SELECT id FROM pbl_classes WHERE uuid = 'ff7e2094-5e57-4137-b277-4382822b4349')
  AND cm.is_active = 1
ORDER BY e.progress DESC, cm.joined_at DESC;


-- ==========================================================================================================
-- 完成提示
-- ==========================================================================================================

SELECT '
========================================
处理完成！

已执行的操作：
1. ✅ 验证班级和课程的关联关系
2. ✅ 修复课程关联（如有需要）
3. ✅ 为班级成员创建学习记录
4. ✅ 清理无效的学习记录
5. ✅ 验证数据一致性

请查看上面的报告了解详细情况。

重要提示：
- 所有班级成员现在都应该有该课程的学习记录
- 学生可以通过班级成员身份直接访问课程
- 无需"选课"操作
========================================
' AS '处理完成';
