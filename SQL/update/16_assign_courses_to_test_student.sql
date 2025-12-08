-- ==========================================
-- 为测试学生分配课程
-- ==========================================
--
-- 说明：
--   本脚本用于为测试学生 20240001@DEMO_SCHOOL 分配课程
--   学生默认只能看到分配给他的课程
--
-- 使用方式：
--   1. 确保已执行 01_insert_test_student.sql 创建测试学生
--   2. 确保已执行 11_insert_test_data.sql 创建课程数据
--   3. 确保已执行 12_add_pbl_course_enrollments_table.sql 创建选课表
--   4. 选择数据库：USE aiot_admin;
--   5. 执行本脚本：source /path/to/16_assign_courses_to_test_student.sql;
--
-- ==========================================

-- 获取测试学生的用户ID
SET @student_user_id = (SELECT id FROM aiot_core_users WHERE username = '20240001@DEMO_SCHOOL' LIMIT 1);

-- 获取课程ID
SET @course1_id = (SELECT id FROM pbl_courses WHERE title = 'AI图像识别入门' LIMIT 1);
SET @course2_id = (SELECT id FROM pbl_courses WHERE title = 'AI智能垃圾分类系统' LIMIT 1);
SET @course3_id = (SELECT id FROM pbl_courses WHERE title = '智能家居控制系统' LIMIT 1);
SET @course4_id = (SELECT id FROM pbl_courses WHERE title = '智慧校园AI助手开发' LIMIT 1);

-- 检查变量是否获取成功
SELECT 
    '检查数据是否存在' AS step,
    @student_user_id AS student_user_id,
    @course1_id AS course1_id,
    @course2_id AS course2_id,
    @course3_id AS course3_id,
    @course4_id AS course4_id;

-- 如果学生用户不存在，显示错误提示并退出
SELECT 
    CASE 
        WHEN @student_user_id IS NULL THEN '错误：测试学生用户不存在！请先执行 01_insert_test_student.sql'
        ELSE '学生用户存在，继续执行...'
    END AS user_check_result;

-- 如果课程不存在，显示警告
SELECT 
    CASE 
        WHEN @course1_id IS NULL THEN '警告：课程"AI图像识别入门"不存在！'
        WHEN @course2_id IS NULL THEN '警告：课程"AI智能垃圾分类系统"不存在！'
        WHEN @course3_id IS NULL THEN '警告：课程"智能家居控制系统"不存在！'
        WHEN @course4_id IS NULL THEN '警告：课程"智慧校园AI助手开发"不存在！'
        ELSE '所有课程都存在，继续执行...'
    END AS course_check_result;

-- 删除已存在的选课记录（如果有）
DELETE FROM pbl_course_enrollments WHERE user_id = @student_user_id AND @student_user_id IS NOT NULL;

-- 为学生分配课程（只有在学生用户和课程都存在时才执行）

-- 课程1: AI图像识别入门 (初级课程，进度20%)
INSERT INTO pbl_course_enrollments (
    course_id,
    user_id,
    enrollment_status,
    enrolled_at,
    progress,
    created_at,
    updated_at
)
SELECT 
    @course1_id,
    @student_user_id,
    'enrolled',
    NOW() - INTERVAL 14 DAY,  -- 14天前选课
    20,
    NOW() - INTERVAL 14 DAY,
    NOW()
WHERE @student_user_id IS NOT NULL AND @course1_id IS NOT NULL;

-- 课程2: AI智能垃圾分类系统 (中级课程，进度10%)
INSERT INTO pbl_course_enrollments (
    course_id,
    user_id,
    enrollment_status,
    enrolled_at,
    progress,
    created_at,
    updated_at
)
SELECT 
    @course2_id,
    @student_user_id,
    'enrolled',
    NOW() - INTERVAL 10 DAY,  -- 10天前选课
    10,
    NOW() - INTERVAL 10 DAY,
    NOW()
WHERE @student_user_id IS NOT NULL AND @course2_id IS NOT NULL;

-- 课程3: 智能家居控制系统 (中级课程，进度5%)
INSERT INTO pbl_course_enrollments (
    course_id,
    user_id,
    enrollment_status,
    enrolled_at,
    progress,
    created_at,
    updated_at
)
SELECT 
    @course3_id,
    @student_user_id,
    'enrolled',
    NOW() - INTERVAL 7 DAY,   -- 7天前选课
    5,
    NOW() - INTERVAL 7 DAY,
    NOW()
WHERE @student_user_id IS NOT NULL AND @course3_id IS NOT NULL;

-- 课程4: 智慧校园AI助手开发 (高级课程，进度0% - 刚选课)
INSERT INTO pbl_course_enrollments (
    course_id,
    user_id,
    enrollment_status,
    enrolled_at,
    progress,
    created_at,
    updated_at
)
SELECT 
    @course4_id,
    @student_user_id,
    'enrolled',
    NOW() - INTERVAL 1 DAY,   -- 1天前选课
    0,
    NOW() - INTERVAL 1 DAY,
    NOW()
WHERE @student_user_id IS NOT NULL AND @course4_id IS NOT NULL;

-- 验证插入结果
SELECT 
    CASE 
        WHEN @student_user_id IS NULL THEN '错误：学生用户不存在，无法分配课程！'
        WHEN (SELECT COUNT(*) FROM pbl_course_enrollments WHERE user_id = @student_user_id) = 0 THEN '警告：没有成功分配任何课程，请检查课程数据！'
        ELSE CONCAT('成功为学生分配了 ', (SELECT COUNT(*) FROM pbl_course_enrollments WHERE user_id = @student_user_id), ' 门课程')
    END AS execution_result;

-- 显示分配的课程详情
SELECT 
    e.id,
    c.title AS course_title,
    c.difficulty,
    u.username AS student_username,
    u.name AS student_name,
    e.enrollment_status,
    e.progress,
    e.enrolled_at,
    e.created_at
FROM pbl_course_enrollments e
INNER JOIN pbl_courses c ON e.course_id = c.id
INNER JOIN aiot_core_users u ON e.user_id = u.id
WHERE u.username = '20240001@DEMO_SCHOOL'
ORDER BY e.enrolled_at DESC;

-- 统计信息
SELECT 
    COUNT(*) AS total_courses,
    SUM(CASE WHEN enrollment_status = 'enrolled' THEN 1 ELSE 0 END) AS enrolled_courses,
    SUM(CASE WHEN enrollment_status = 'completed' THEN 1 ELSE 0 END) AS completed_courses
FROM pbl_course_enrollments
WHERE user_id = @student_user_id;
