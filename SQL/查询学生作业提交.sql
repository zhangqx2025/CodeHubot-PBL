-- ====================================================================
-- 查询学生提交的作业数据
-- ====================================================================
-- 说明：此脚本用于查询和检查学生在 PBL 系统中提交的作业内容
-- 创建时间：2025-12-09
-- ====================================================================

-- 1. 查询所有学生的作业提交记录（包含提交内容）
SELECT 
    tp.id AS '进度ID',
    tp.task_id AS '任务ID',
    t.title AS '任务标题',
    tp.user_id AS '学生ID',
    u.username AS '学生用户名',
    u.real_name AS '学生姓名',
    u.student_number AS '学号',
    tp.status AS '状态',
    tp.progress AS '进度(%)',
    tp.submission AS '提交内容(JSON)',
    tp.score AS '得分',
    tp.feedback AS '教师反馈',
    tp.graded_by AS '批改教师ID',
    tp.graded_at AS '批改时间',
    tp.created_at AS '创建时间',
    tp.updated_at AS '最后更新时间'
FROM 
    pbl_task_progress tp
LEFT JOIN 
    pbl_tasks t ON tp.task_id = t.id
LEFT JOIN 
    core_users u ON tp.user_id = u.id
WHERE 
    tp.submission IS NOT NULL  -- 只查询有提交内容的记录
ORDER BY 
    tp.updated_at DESC;

-- ====================================================================

-- 2. 查询特定学生的作业提交记录
-- 使用方法：将下面的 YOUR_STUDENT_ID 替换为实际的学生ID
-- SELECT 
--     tp.id AS '进度ID',
--     t.title AS '任务标题',
--     tp.status AS '状态',
--     JSON_EXTRACT(tp.submission, '$.content') AS '提交内容',
--     JSON_EXTRACT(tp.submission, '$.attachment_url') AS '附件链接',
--     tp.score AS '得分',
--     tp.updated_at AS '提交时间'
-- FROM 
--     pbl_task_progress tp
-- LEFT JOIN 
--     pbl_tasks t ON tp.task_id = t.id
-- WHERE 
--     tp.user_id = YOUR_STUDENT_ID
--     AND tp.submission IS NOT NULL
-- ORDER BY 
--     tp.updated_at DESC;

-- ====================================================================

-- 3. 查询特定任务的所有学生提交
-- 使用方法：将下面的 YOUR_TASK_ID 替换为实际的任务ID
-- SELECT 
--     u.real_name AS '学生姓名',
--     u.student_number AS '学号',
--     tp.status AS '状态',
--     JSON_EXTRACT(tp.submission, '$.content') AS '提交内容',
--     JSON_EXTRACT(tp.submission, '$.attachment_url') AS '附件链接',
--     tp.score AS '得分',
--     tp.updated_at AS '提交时间'
-- FROM 
--     pbl_task_progress tp
-- LEFT JOIN 
--     core_users u ON tp.user_id = u.id
-- WHERE 
--     tp.task_id = YOUR_TASK_ID
--     AND tp.submission IS NOT NULL
-- ORDER BY 
--     tp.updated_at DESC;

-- ====================================================================

-- 4. 统计各任务的提交情况
SELECT 
    t.id AS '任务ID',
    t.title AS '任务标题',
    t.type AS '任务类型',
    COUNT(tp.id) AS '总进度记录数',
    SUM(CASE WHEN tp.submission IS NOT NULL THEN 1 ELSE 0 END) AS '已提交作业数',
    SUM(CASE WHEN tp.submission IS NULL THEN 1 ELSE 0 END) AS '未提交作业数',
    SUM(CASE WHEN tp.status = 'review' THEN 1 ELSE 0 END) AS '待审核数',
    SUM(CASE WHEN tp.status = 'completed' THEN 1 ELSE 0 END) AS '已完成数',
    ROUND(AVG(tp.score), 2) AS '平均分'
FROM 
    pbl_tasks t
LEFT JOIN 
    pbl_task_progress tp ON t.id = tp.task_id
GROUP BY 
    t.id, t.title, t.type
ORDER BY 
    t.id;

-- ====================================================================

-- 5. 查询最近提交的作业（最近10条）
SELECT 
    tp.id AS '进度ID',
    t.title AS '任务标题',
    u.real_name AS '学生姓名',
    u.student_number AS '学号',
    tp.status AS '状态',
    JSON_EXTRACT(tp.submission, '$.content') AS '提交内容',
    JSON_EXTRACT(tp.submission, '$.attachment_url') AS '附件链接',
    tp.updated_at AS '提交时间'
FROM 
    pbl_task_progress tp
LEFT JOIN 
    pbl_tasks t ON tp.task_id = t.id
LEFT JOIN 
    core_users u ON tp.user_id = u.id
WHERE 
    tp.submission IS NOT NULL
ORDER BY 
    tp.updated_at DESC
LIMIT 10;

-- ====================================================================

-- 6. 检查 submission 字段是否为空的记录
SELECT 
    tp.id AS '进度ID',
    t.title AS '任务标题',
    u.real_name AS '学生姓名',
    tp.status AS '状态',
    tp.progress AS '进度',
    tp.submission AS '提交内容',
    tp.created_at AS '创建时间',
    tp.updated_at AS '更新时间'
FROM 
    pbl_task_progress tp
LEFT JOIN 
    pbl_tasks t ON tp.task_id = t.id
LEFT JOIN 
    core_users u ON tp.user_id = u.id
WHERE 
    tp.submission IS NULL OR tp.submission = 'null' OR JSON_LENGTH(tp.submission) = 0
ORDER BY 
    tp.updated_at DESC;

-- ====================================================================

-- 7. 查询提交内容的详细信息（JSON 解析）
SELECT 
    tp.id AS '进度ID',
    t.title AS '任务标题',
    u.real_name AS '学生姓名',
    tp.submission AS '完整提交内容(JSON)',
    JSON_EXTRACT(tp.submission, '$.content') AS '文本内容',
    JSON_EXTRACT(tp.submission, '$.attachment_url') AS '附件URL',
    JSON_TYPE(tp.submission) AS 'JSON类型',
    JSON_LENGTH(tp.submission) AS 'JSON字段数',
    tp.updated_at AS '提交时间'
FROM 
    pbl_task_progress tp
LEFT JOIN 
    pbl_tasks t ON tp.task_id = t.id
LEFT JOIN 
    core_users u ON tp.user_id = u.id
WHERE 
    tp.submission IS NOT NULL
ORDER BY 
    tp.updated_at DESC
LIMIT 20;

-- ====================================================================
-- 使用说明：
-- 1. 执行第1个查询可以看到所有学生的作业提交记录
-- 2. 如果要查询特定学生，取消注释第2个查询并替换 YOUR_STUDENT_ID
-- 3. 如果要查询特定任务，取消注释第3个查询并替换 YOUR_TASK_ID
-- 4. 第4个查询可以看到各任务的提交统计情况
-- 5. 第5个查询可以快速查看最近提交的作业
-- 6. 第6个查询用于检查是否有空的提交记录
-- 7. 第7个查询可以看到 JSON 字段的详细解析
-- ====================================================================



