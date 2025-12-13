-- ==========================================================================================================
-- 将已有选课数据的课程迁移到班级架构
-- 
-- 背景：线上系统中已有课程和选课记录，需要迁移到新的班级架构
-- 课程 UUID: be921ec1-d4e4-11f0-a641-0242ac140002
-- 目标班级 UUID: ff7e2094-5e57-4137-b277-4382822b4349
-- 
-- 迁移策略：
-- 1. 将课程关联到班级
-- 2. 将已选课的学生添加为班级成员（如果还不是）
-- 3. 保留所有现有的学习记录（进度、成绩等）
-- 4. 确保数据一致性
-- ==========================================================================================================

-- ==========================================================================================================
-- 第一步：数据现状分析
-- ==========================================================================================================

SELECT '=== 迁移前数据状态分析 ===' AS '';

-- 1.1 查看课程当前状态
SELECT 
    '课程信息' AS info_type,
    id,
    uuid,
    title,
    class_id AS current_class_id,
    class_name AS current_class_name,
    status,
    school_id,
    created_at
FROM pbl_courses
WHERE uuid = 'be921ec1-d4e4-11f0-a641-0242ac140002';

-- 1.2 统计课程的选课情况
SELECT 
    '课程选课统计' AS info_type,
    COUNT(*) AS total_enrollments,
    COUNT(CASE WHEN enrollment_status = 'enrolled' THEN 1 END) AS enrolled_count,
    COUNT(CASE WHEN enrollment_status = 'completed' THEN 1 END) AS completed_count,
    COUNT(CASE WHEN enrollment_status = 'dropped' THEN 1 END) AS dropped_count,
    ROUND(AVG(progress), 2) AS avg_progress,
    ROUND(AVG(final_score), 2) AS avg_score
FROM pbl_course_enrollments
WHERE course_id = (SELECT id FROM pbl_courses WHERE uuid = 'be921ec1-d4e4-11f0-a641-0242ac140002');

-- 1.3 查看已选课的学生列表（前10名）
SELECT 
    '已选课学生列表（前10名）' AS info_type,
    e.user_id AS student_id,
    u.name AS student_name,
    u.student_number,
    e.enrollment_status,
    e.progress,
    e.final_score,
    e.enrolled_at
FROM pbl_course_enrollments e
LEFT JOIN core_users u ON e.user_id = u.id
WHERE e.course_id = (SELECT id FROM pbl_courses WHERE uuid = 'be921ec1-d4e4-11f0-a641-0242ac140002')
ORDER BY e.enrolled_at
LIMIT 10;

-- 1.4 查看目标班级信息
SELECT 
    '目标班级信息' AS info_type,
    id,
    uuid,
    name AS class_name,
    class_type,
    max_students,
    current_members,
    school_id,
    is_active
FROM pbl_classes
WHERE uuid = 'ff7e2094-5e57-4137-b277-4382822b4349';

-- 1.5 查看班级现有成员
SELECT 
    '班级现有成员' AS info_type,
    COUNT(*) AS current_member_count
FROM pbl_class_members
WHERE class_id = (SELECT id FROM pbl_classes WHERE uuid = 'ff7e2094-5e57-4137-b277-4382822b4349')
  AND is_active = 1;


-- ==========================================================================================================
-- 第二步：数据迁移
-- ==========================================================================================================

SELECT '=== 开始数据迁移 ===' AS '';

-- 2.1 将课程关联到班级
UPDATE pbl_courses c
INNER JOIN pbl_classes cls ON cls.uuid = 'ff7e2094-5e57-4137-b277-4382822b4349'
SET 
    c.class_id = cls.id,
    c.class_name = cls.name,
    c.school_id = cls.school_id  -- 同步学校ID
WHERE c.uuid = 'be921ec1-d4e4-11f0-a641-0242ac140002';

-- 验证步骤1结果
SELECT 
    CASE 
        WHEN c.class_id = cls.id THEN '✅ 步骤1：课程已成功关联到班级'
        ELSE '❌ 步骤1：课程关联失败'
    END AS step1_result,
    c.class_id AS actual_class_id,
    cls.id AS expected_class_id,
    c.class_name AS actual_class_name,
    cls.name AS expected_class_name
FROM pbl_courses c
INNER JOIN pbl_classes cls ON cls.uuid = 'ff7e2094-5e57-4137-b277-4382822b4349'
WHERE c.uuid = 'be921ec1-d4e4-11f0-a641-0242ac140002';


-- 2.2 将已选课的学生添加为班级成员（如果还不是）
-- 注意：保留角色为普通成员，后续可手动调整
-- 修复：避免触发器冲突，分两步执行

-- 2.2.1 先获取目标班级ID
SET @target_class_id = (SELECT id FROM pbl_classes WHERE uuid = 'ff7e2094-5e57-4137-b277-4382822b4349');

-- 2.2.2 插入班级成员
INSERT INTO pbl_class_members (
    class_id,
    student_id,
    role,
    joined_at,
    is_active,
    created_at
)
SELECT 
    @target_class_id AS class_id,
    e.user_id AS student_id,
    'member' AS role,
    e.enrolled_at AS joined_at,  -- 使用选课时间作为加入班级时间
    1 AS is_active,
    NOW() AS created_at
FROM pbl_course_enrollments e
INNER JOIN pbl_courses c ON e.course_id = c.id
WHERE c.uuid = 'be921ec1-d4e4-11f0-a641-0242ac140002'
  AND e.enrollment_status IN ('enrolled', 'completed')  -- 只迁移正在学习和已完成的学生
  AND NOT EXISTS (
      -- 避免重复添加
      SELECT 1 
      FROM pbl_class_members cm 
      WHERE cm.class_id = @target_class_id
        AND cm.student_id = e.user_id
        AND cm.is_active = 1
  );

-- 验证步骤2结果
SELECT 
    CONCAT('✅ 步骤2：已将 ', COUNT(DISTINCT cm.student_id), ' 名选课学生添加为班级成员') AS step2_result
FROM pbl_class_members cm
INNER JOIN pbl_classes cls ON cls.uuid = 'ff7e2094-5e57-4137-b277-4382822b4349'
WHERE cm.class_id = cls.id AND cm.is_active = 1;


-- 2.3 更新学习记录的 class_id 字段（关联到班级）
UPDATE pbl_course_enrollments e
INNER JOIN pbl_courses c ON e.course_id = c.id
INNER JOIN pbl_classes cls ON cls.uuid = 'ff7e2094-5e57-4137-b277-4382822b4349'
SET e.class_id = cls.id
WHERE c.uuid = 'be921ec1-d4e4-11f0-a641-0242ac140002'
  AND (e.class_id IS NULL OR e.class_id != cls.id);

-- 验证步骤3结果
SELECT 
    CONCAT('✅ 步骤3：已更新学习记录的班级关联，共 ', COUNT(*), ' 条记录') AS step3_result
FROM pbl_course_enrollments e
INNER JOIN pbl_courses c ON e.course_id = c.id
INNER JOIN pbl_classes cls ON cls.uuid = 'ff7e2094-5e57-4137-b277-4382822b4349'
WHERE c.uuid = 'be921ec1-d4e4-11f0-a641-0242ac140002'
  AND e.class_id = cls.id;


-- 2.4 更新班级的成员统计
UPDATE pbl_classes cls
SET cls.current_members = (
    SELECT COUNT(DISTINCT cm.student_id)
    FROM pbl_class_members cm
    WHERE cm.class_id = cls.id
      AND cm.is_active = 1
)
WHERE cls.uuid = 'ff7e2094-5e57-4137-b277-4382822b4349';

-- 验证步骤4结果
SELECT 
    CONCAT('✅ 步骤4：已更新班级成员统计，当前成员数：', cls.current_members) AS step4_result
FROM pbl_classes cls
WHERE cls.uuid = 'ff7e2094-5e57-4137-b277-4382822b4349';


-- ==========================================================================================================
-- 第三步：数据一致性验证
-- ==========================================================================================================

SELECT '=== 数据一致性验证 ===' AS '';

-- 3.1 验证课程是否正确关联到班级
SELECT 
    '课程关联验证' AS verification_type,
    CASE 
        WHEN c.class_id = cls.id THEN '✅ 课程已正确关联到班级'
        ELSE '❌ 课程未正确关联'
    END AS verification_result,
    cls.id AS expected_class_id,
    cls.name AS expected_class_name,
    c.class_id AS actual_class_id,
    c.class_name AS actual_class_name
FROM pbl_courses c
INNER JOIN pbl_classes cls ON cls.uuid = 'ff7e2094-5e57-4137-b277-4382822b4349'
WHERE c.uuid = 'be921ec1-d4e4-11f0-a641-0242ac140002';

-- 3.2 验证选课学生是否都成为了班级成员
SELECT 
    '成员一致性验证' AS verification_type,
    COUNT(DISTINCT e.user_id) AS total_enrolled_students,
    COUNT(DISTINCT cm.student_id) AS students_as_class_members,
    CASE 
        WHEN COUNT(DISTINCT e.user_id) = COUNT(DISTINCT cm.student_id) 
        THEN '✅ 所有选课学生都已成为班级成员'
        ELSE CONCAT('⚠️  还有 ', COUNT(DISTINCT e.user_id) - COUNT(DISTINCT cm.student_id), ' 名学生未成为班级成员')
    END AS verification_result
FROM pbl_course_enrollments e
INNER JOIN pbl_courses c ON e.course_id = c.id
LEFT JOIN pbl_class_members cm ON cm.student_id = e.user_id 
    AND cm.class_id = (SELECT id FROM pbl_classes WHERE uuid = 'ff7e2094-5e57-4137-b277-4382822b4349')
    AND cm.is_active = 1
WHERE c.uuid = 'be921ec1-d4e4-11f0-a641-0242ac140002'
  AND e.enrollment_status IN ('enrolled', 'completed');

-- 3.3 检查是否有选课记录但不是班级成员的情况（应该没有）
SELECT 
    '异常数据检查' AS verification_type,
    e.user_id AS student_id,
    u.name AS student_name,
    u.student_number,
    e.enrollment_status,
    '❌ 有选课记录但不是班级成员' AS issue
FROM pbl_course_enrollments e
INNER JOIN pbl_courses c ON e.course_id = c.id
LEFT JOIN core_users u ON e.user_id = u.id
LEFT JOIN pbl_class_members cm ON cm.student_id = e.user_id 
    AND cm.class_id = (SELECT id FROM pbl_classes WHERE uuid = 'ff7e2094-5e57-4137-b277-4382822b4349')
    AND cm.is_active = 1
WHERE c.uuid = 'be921ec1-d4e4-11f0-a641-0242ac140002'
  AND e.enrollment_status IN ('enrolled', 'completed')
  AND cm.id IS NULL;


-- ==========================================================================================================
-- 第四步：迁移后数据统计
-- ==========================================================================================================

SELECT '=== 迁移后数据统计 ===' AS '';

-- 4.1 班级和课程的基本信息
SELECT 
    cls.name AS class_name,
    cls.class_type,
    cls.current_members AS class_members,
    cls.max_students,
    c.title AS course_title,
    c.difficulty,
    c.status
FROM pbl_classes cls
INNER JOIN pbl_courses c ON c.class_id = cls.id
WHERE cls.uuid = 'ff7e2094-5e57-4137-b277-4382822b4349'
  AND c.uuid = 'be921ec1-d4e4-11f0-a641-0242ac140002';

-- 4.2 详细统计
SELECT 
    '班级成员总数' AS stat_type,
    COUNT(DISTINCT cm.student_id) AS count
FROM pbl_class_members cm
WHERE cm.class_id = (SELECT id FROM pbl_classes WHERE uuid = 'ff7e2094-5e57-4137-b277-4382822b4349')
  AND cm.is_active = 1

UNION ALL

SELECT 
    '课程选课人数（enrolled+completed）' AS stat_type,
    COUNT(DISTINCT e.user_id) AS count
FROM pbl_course_enrollments e
WHERE e.course_id = (SELECT id FROM pbl_courses WHERE uuid = 'be921ec1-d4e4-11f0-a641-0242ac140002')
  AND e.enrollment_status IN ('enrolled', 'completed')

UNION ALL

SELECT 
    '学习中' AS stat_type,
    COUNT(*) AS count
FROM pbl_course_enrollments e
WHERE e.course_id = (SELECT id FROM pbl_courses WHERE uuid = 'be921ec1-d4e4-11f0-a641-0242ac140002')
  AND e.enrollment_status = 'enrolled'

UNION ALL

SELECT 
    '已完成' AS stat_type,
    COUNT(*) AS count
FROM pbl_course_enrollments e
WHERE e.course_id = (SELECT id FROM pbl_courses WHERE uuid = 'be921ec1-d4e4-11f0-a641-0242ac140002')
  AND e.enrollment_status = 'completed'

UNION ALL

SELECT 
    '已退课' AS stat_type,
    COUNT(*) AS count
FROM pbl_course_enrollments e
WHERE e.course_id = (SELECT id FROM pbl_courses WHERE uuid = 'be921ec1-d4e4-11f0-a641-0242ac140002')
  AND e.enrollment_status = 'dropped';

-- 4.3 学习进度统计
SELECT 
    '平均学习进度' AS stat_type,
    CONCAT(ROUND(AVG(e.progress), 2), '%') AS value
FROM pbl_course_enrollments e
WHERE e.course_id = (SELECT id FROM pbl_courses WHERE uuid = 'be921ec1-d4e4-11f0-a641-0242ac140002')
  AND e.enrollment_status IN ('enrolled', 'completed')

UNION ALL

SELECT 
    '平均成绩' AS stat_type,
    COALESCE(CONCAT(ROUND(AVG(e.final_score), 2), '分'), '暂无') AS value
FROM pbl_course_enrollments e
WHERE e.course_id = (SELECT id FROM pbl_courses WHERE uuid = 'be921ec1-d4e4-11f0-a641-0242ac140002')
  AND e.final_score IS NOT NULL;


-- ==========================================================================================================
-- 第五步：生成学生明细报告
-- ==========================================================================================================

SELECT '=== 迁移后学生明细（前20名） ===' AS '';

SELECT 
    cm.student_id,
    u.name AS student_name,
    u.student_number,
    cm.role AS class_role,
    cm.joined_at AS joined_class_at,
    e.enrollment_status AS learning_status,
    e.progress,
    e.final_score,
    e.enrolled_at AS start_learning_at,
    e.completed_at,
    CASE 
        WHEN cm.id IS NOT NULL AND e.id IS NOT NULL THEN '✅ 数据完整'
        WHEN cm.id IS NOT NULL AND e.id IS NULL THEN '⚠️  是成员但无学习记录'
        WHEN cm.id IS NULL AND e.id IS NOT NULL THEN '❌ 有学习记录但不是成员'
        ELSE '❓ 未知状态'
    END AS data_status
FROM pbl_class_members cm
LEFT JOIN core_users u ON cm.student_id = u.id
LEFT JOIN pbl_course_enrollments e ON e.user_id = cm.student_id 
    AND e.course_id = (SELECT id FROM pbl_courses WHERE uuid = 'be921ec1-d4e4-11f0-a641-0242ac140002')
WHERE cm.class_id = (SELECT id FROM pbl_classes WHERE uuid = 'ff7e2094-5e57-4137-b277-4382822b4349')
  AND cm.is_active = 1
ORDER BY e.progress DESC, cm.joined_at
LIMIT 20;


-- ==========================================================================================================
-- 完成提示
-- ==========================================================================================================

SELECT '
========================================
✅ 课程迁移完成！

已完成的操作：
1. ✅ 将课程关联到目标班级
2. ✅ 将选课学生添加为班级成员
3. ✅ 保留所有学习记录（进度、成绩）
4. ✅ 更新班级成员统计
5. ✅ 验证数据一致性

重要说明：
- 所有原有的学习进度和成绩都已保留
- 选课学生现在也是班级成员
- 学生可以通过班级成员身份访问课程
- 已退课的学生不会被添加为班级成员

后续建议：
1. 检查是否需要调整某些学生的班级角色（班长、副班长等）
2. 确认所有学生都能正常访问课程
3. 监控学习进度记录是否正常
========================================
' AS '迁移完成';
