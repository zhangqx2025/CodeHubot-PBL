-- ====================================================================
-- 测试作业提交数据写入
-- ====================================================================
-- 说明：此脚本用于测试和验证作业提交功能是否正常写入数据库
-- ====================================================================

-- 1. 查看当前的任务进度记录
SELECT 
    id,
    task_id,
    user_id,
    status,
    progress,
    submission,
    created_at,
    updated_at
FROM 
    pbl_task_progress
ORDER BY 
    updated_at DESC
LIMIT 10;

-- ====================================================================

-- 2. 手动插入一条测试数据（验证 JSON 字段是否正常工作）
-- 注意：请先确保 task_id 和 user_id 存在

-- 查找一个有效的任务ID
SELECT id, title FROM pbl_tasks LIMIT 1;

-- 查找一个有效的学生用户ID
SELECT id, username, real_name FROM core_users WHERE role = 'student' LIMIT 1;

-- 手动插入测试数据（替换下面的 TASK_ID 和 USER_ID）
-- INSERT INTO pbl_task_progress (
--     task_id,
--     user_id,
--     status,
--     progress,
--     submission,
--     created_at,
--     updated_at
-- ) VALUES (
--     TASK_ID,  -- 替换为实际的任务ID
--     USER_ID,  -- 替换为实际的用户ID
--     'review',
--     100,
--     JSON_OBJECT(
--         'content', '这是一条手动插入的测试作业内容',
--         'attachment_url', 'https://example.com/test.pdf'
--     ),
--     NOW(),
--     NOW()
-- );

-- ====================================================================

-- 3. 查询刚插入的测试数据
-- SELECT 
--     id,
--     task_id,
--     user_id,
--     submission,
--     JSON_EXTRACT(submission, '$.content') AS content,
--     JSON_EXTRACT(submission, '$.attachment_url') AS attachment_url,
--     updated_at
-- FROM 
--     pbl_task_progress
-- WHERE 
--     JSON_EXTRACT(submission, '$.content') = '这是一条手动插入的测试作业内容';

-- ====================================================================

-- 4. 删除测试数据
-- DELETE FROM pbl_task_progress 
-- WHERE JSON_EXTRACT(submission, '$.content') = '这是一条手动插入的测试作业内容';

-- ====================================================================

-- 5. 检查表结构（确认 submission 字段类型）
SHOW CREATE TABLE pbl_task_progress;

-- ====================================================================

-- 6. 查看最近5分钟内的所有变更
SELECT 
    id,
    task_id,
    user_id,
    status,
    JSON_EXTRACT(submission, '$.content') AS content,
    created_at,
    updated_at
FROM 
    pbl_task_progress
WHERE 
    updated_at >= DATE_SUB(NOW(), INTERVAL 5 MINUTE)
ORDER BY 
    updated_at DESC;

-- ====================================================================

-- 7. 检查是否有状态为 review 但 submission 为空的记录
SELECT 
    id,
    task_id,
    user_id,
    status,
    progress,
    submission,
    updated_at
FROM 
    pbl_task_progress
WHERE 
    status = 'review'
    AND (submission IS NULL OR submission = 'null');

-- ====================================================================
-- 使用说明：
-- 1. 先执行查询1，看看当前有哪些记录
-- 2. 执行查询5，确认 submission 字段类型是 json
-- 3. 如果要测试手动插入，取消注释相关 SQL 并替换 ID
-- 4. 执行查询6，查看最近的变更
-- 5. 执行查询7，检查是否有异常的空提交记录
-- ====================================================================



