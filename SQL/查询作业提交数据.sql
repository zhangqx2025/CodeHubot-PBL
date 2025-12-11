-- 1. 查询作业提交数据，检查submission字段的内容
SELECT 
    id,
    task_id,
    user_id,
    status,
    progress,
    submission,
    score,
    feedback,
    created_at,
    updated_at
FROM pbl_task_progress
WHERE submission IS NOT NULL
ORDER BY updated_at DESC
LIMIT 10;

-- 2. 查看submission字段的JSON结构
SELECT 
    id,
    task_id,
    user_id,
    status,
    JSON_EXTRACT(submission, '$.content') as content,
    JSON_EXTRACT(submission, '$.attachment_url') as attachment_url,
    updated_at
FROM pbl_task_progress
WHERE submission IS NOT NULL
ORDER BY updated_at DESC
LIMIT 10;

-- 3. 检查submission字段的类型和格式
SELECT 
    id,
    task_id,
    user_id,
    status,
    JSON_TYPE(submission) as submission_type,
    JSON_VALID(submission) as is_valid_json,
    CHAR_LENGTH(submission) as submission_length,
    submission,
    updated_at
FROM pbl_task_progress
WHERE submission IS NOT NULL
ORDER BY updated_at DESC
LIMIT 5;

-- 4. 查看最近一条有submission的记录的完整信息
SELECT 
    tp.id,
    tp.task_id,
    tp.user_id,
    tp.status,
    tp.progress,
    tp.submission,
    tp.score,
    tp.feedback,
    t.title as task_title,
    tp.updated_at
FROM pbl_task_progress tp
LEFT JOIN pbl_tasks t ON tp.task_id = t.id
WHERE tp.submission IS NOT NULL
ORDER BY tp.updated_at DESC
LIMIT 1;



