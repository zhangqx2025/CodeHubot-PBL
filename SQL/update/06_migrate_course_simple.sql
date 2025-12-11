-- ==========================================================================================================
-- 课程迁移到模板 - 纯SQL版本（不使用存储过程）
-- ==========================================================================================================
-- 
-- 脚本名称: 06_migrate_course_simple.sql
-- 创建日期: 2024-12-11
-- 兼容版本: MySQL 5.7.x, 8.0.x
-- 用途: 将课程ID=2的"智能家居控制智能体"课程迁移为模板
--
-- ==========================================================================================================

SET NAMES utf8mb4 COLLATE utf8mb4_unicode_ci;
SET FOREIGN_KEY_CHECKS = 0;

-- ==========================================================================================================
-- 步骤1：确认课程信息
-- ==========================================================================================================

SELECT '========================================' AS '';
SELECT '步骤1：确认课程信息' AS '';
SELECT '========================================' AS '';

SELECT 
    c.id AS 课程ID,
    c.uuid AS 课程UUID,
    c.title AS 课程标题,
    c.difficulty AS 难度,
    c.duration AS 时长,
    c.status AS 状态,
    (SELECT COUNT(*) FROM pbl_units WHERE course_id = c.id) AS 单元数,
    (SELECT COUNT(*) FROM pbl_resources r 
     INNER JOIN pbl_units u ON u.id = r.unit_id 
     WHERE u.course_id = c.id) AS 资源数,
    (SELECT COUNT(*) FROM pbl_tasks t 
     INNER JOIN pbl_units u ON u.id = t.unit_id 
     WHERE u.course_id = c.id) AS 任务数
FROM pbl_courses c
WHERE c.id = 2;

-- ==========================================================================================================
-- 步骤2：创建课程模板
-- ==========================================================================================================

SELECT '========================================' AS '';
SELECT '步骤2：创建课程模板' AS '';
SELECT '========================================' AS '';

-- 2.1 插入课程模板
INSERT INTO pbl_course_templates (
    uuid,
    template_code,
    title,
    subtitle,
    description,
    cover_image,
    difficulty,
    grade_level,
    subject,
    duration,
    learning_objectives,
    prerequisite_knowledge,
    tags,
    category_id,
    version,
    status,
    creator_id,
    is_public,
    usage_count,
    created_at,
    updated_at
)
SELECT 
    UUID() AS uuid,
    'IOT-AI-SMARTHOME-001' AS template_code,
    title,
    NULL AS subtitle,
    description,
    cover_image,
    difficulty,
    '高中' AS grade_level,
    '人工智能+物联网' AS subject,
    duration,
    JSON_ARRAY(
        '掌握AI智能体开发基础',
        '理解自然语言处理',
        '学会物联网设备控制',
        '培养项目实践能力'
    ) AS learning_objectives,
    JSON_ARRAY('Python基础', '基本编程概念') AS prerequisite_knowledge,
    JSON_ARRAY('人工智能', '物联网', 'PBL', '智能家居') AS tags,
    NULL AS category_id,
    '1.0.0' AS version,
    'published' AS status,
    creator_id,
    1 AS is_public,
    0 AS usage_count,
    NOW() AS created_at,
    NOW() AS updated_at
FROM pbl_courses
WHERE id = 2;

-- 2.2 获取刚创建的模板ID
SET @template_id = LAST_INSERT_ID();

SELECT 
    @template_id AS '创建的模板ID',
    ct.template_code AS '模板编码',
    ct.title AS '模板标题'
FROM pbl_course_templates ct
WHERE ct.id = @template_id;

-- ==========================================================================================================
-- 步骤3：复制单元模板
-- ==========================================================================================================

SELECT '========================================' AS '';
SELECT '步骤3：复制单元模板' AS '';
SELECT '========================================' AS '';

INSERT INTO pbl_unit_templates (
    uuid,
    template_code,
    course_template_id,
    title,
    description,
    learning_guide,
    `order`,
    estimated_hours,
    created_at,
    updated_at
)
SELECT 
    UUID() AS uuid,
    CONCAT('UNIT-', LPAD(u.`order`, 3, '0')) AS template_code,
    @template_id AS course_template_id,
    u.title,
    u.description,
    u.learning_guide,
    u.`order`,
    NULL AS estimated_hours,
    NOW() AS created_at,
    NOW() AS updated_at
FROM pbl_units u
WHERE u.course_id = 2
ORDER BY u.`order`;

SELECT CONCAT('成功复制 ', ROW_COUNT(), ' 个单元模板') AS '单元模板';

-- ==========================================================================================================
-- 步骤4：复制资源模板
-- ==========================================================================================================

SELECT '========================================' AS '';
SELECT '步骤4：复制资源模板' AS '';
SELECT '========================================' AS '';

INSERT INTO pbl_resource_templates (
    uuid,
    template_code,
    unit_template_id,
    type,
    title,
    description,
    `order`,
    url,
    content,
    video_id,
    video_cover_url,
    duration,
    default_max_views,
    is_preview_allowed,
    meta_data,
    created_at,
    updated_at
)
SELECT 
    UUID() AS uuid,
    CONCAT('RES-', LPAD(r.`order`, 3, '0')) AS template_code,
    ut.id AS unit_template_id,
    r.type,
    r.title,
    r.description,
    r.`order`,
    r.url,
    r.content,
    r.video_id,
    r.video_cover_url,
    r.duration,
    r.max_views AS default_max_views,
    1 AS is_preview_allowed,
    NULL AS meta_data,
    NOW() AS created_at,
    NOW() AS updated_at
FROM pbl_resources r
INNER JOIN pbl_units u ON u.id = r.unit_id
INNER JOIN pbl_unit_templates ut ON ut.course_template_id = @template_id 
    AND ut.`order` = u.`order`
WHERE u.course_id = 2
ORDER BY r.unit_id, r.`order`;

SELECT CONCAT('成功复制 ', ROW_COUNT(), ' 个资源模板') AS '资源模板';

-- ==========================================================================================================
-- 步骤5：复制任务模板
-- ==========================================================================================================

SELECT '========================================' AS '';
SELECT '步骤5：复制任务模板' AS '';
SELECT '========================================' AS '';

INSERT INTO pbl_task_templates (
    uuid,
    template_code,
    unit_template_id,
    title,
    description,
    type,
    difficulty,
    `order`,
    requirements,
    deliverables,
    evaluation_criteria,
    estimated_time,
    estimated_hours,
    prerequisites,
    required_resources,
    hints,
    reference_materials,
    meta_data,
    created_at,
    updated_at
)
SELECT 
    UUID() AS uuid,
    CONCAT('TASK-', LPAD(t.`order`, 3, '0')) AS template_code,
    ut.id AS unit_template_id,
    t.title,
    t.description,
    t.type,
    t.difficulty,
    t.`order`,
    t.requirements,
    NULL AS deliverables,
    NULL AS evaluation_criteria,
    t.estimated_time,
    NULL AS estimated_hours,
    t.prerequisites,
    NULL AS required_resources,
    NULL AS hints,
    NULL AS reference_materials,
    NULL AS meta_data,
    NOW() AS created_at,
    NOW() AS updated_at
FROM pbl_tasks t
INNER JOIN pbl_units u ON u.id = t.unit_id
INNER JOIN pbl_unit_templates ut ON ut.course_template_id = @template_id 
    AND ut.`order` = u.`order`
WHERE u.course_id = 2
ORDER BY t.unit_id, t.`order`;

SELECT CONCAT('成功复制 ', ROW_COUNT(), ' 个任务模板') AS '任务模板';

-- ==========================================================================================================
-- 步骤6：更新原课程，关联到模板
-- ==========================================================================================================

SELECT '========================================' AS '';
SELECT '步骤6：关联课程到模板' AS '';
SELECT '========================================' AS '';

UPDATE pbl_courses
SET template_id = @template_id,
    template_version = '1.0.0',
    is_customized = 0,
    sync_with_template = 0
WHERE id = 2;

SELECT '成功关联课程到模板' AS '课程关联';

-- ==========================================================================================================
-- 步骤7：更新单元关联
-- ==========================================================================================================

SELECT '========================================' AS '';
SELECT '步骤7：关联单元到模板' AS '';
SELECT '========================================' AS '';

UPDATE pbl_units u
INNER JOIN pbl_unit_templates ut ON ut.course_template_id = @template_id 
    AND ut.`order` = u.`order`
SET u.template_id = ut.id,
    u.is_customized = 0
WHERE u.course_id = 2;

SELECT CONCAT('成功关联 ', ROW_COUNT(), ' 个单元到模板') AS '单元关联';

-- ==========================================================================================================
-- 步骤8：更新资源关联
-- ==========================================================================================================

SELECT '========================================' AS '';
SELECT '步骤8：关联资源到模板' AS '';
SELECT '========================================' AS '';

UPDATE pbl_resources r
INNER JOIN pbl_units u ON u.id = r.unit_id
INNER JOIN pbl_unit_templates ut ON ut.course_template_id = @template_id 
    AND ut.`order` = u.`order`
INNER JOIN pbl_resource_templates rt ON rt.unit_template_id = ut.id 
    AND rt.`order` = r.`order`
SET r.template_id = rt.id,
    r.is_customized = 0
WHERE u.course_id = 2;

SELECT CONCAT('成功关联 ', ROW_COUNT(), ' 个资源到模板') AS '资源关联';

-- ==========================================================================================================
-- 步骤9：更新任务关联
-- ==========================================================================================================

SELECT '========================================' AS '';
SELECT '步骤9：关联任务到模板' AS '';
SELECT '========================================' AS '';

UPDATE pbl_tasks t
INNER JOIN pbl_units u ON u.id = t.unit_id
INNER JOIN pbl_unit_templates ut ON ut.course_template_id = @template_id 
    AND ut.`order` = u.`order`
INNER JOIN pbl_task_templates tt ON tt.unit_template_id = ut.id 
    AND tt.`order` = t.`order`
SET t.template_id = tt.id,
    t.is_customized = 0
WHERE u.course_id = 2;

SELECT CONCAT('成功关联 ', ROW_COUNT(), ' 个任务到模板') AS '任务关联';

-- ==========================================================================================================
-- 步骤10：记录使用日志
-- ==========================================================================================================

SELECT '========================================' AS '';
SELECT '步骤10：记录使用日志' AS '';
SELECT '========================================' AS '';

INSERT INTO pbl_template_usage_logs (
    template_id,
    template_type,
    instance_id,
    school_id,
    creator_id,
    action,
    changes,
    notes,
    created_at
)
SELECT 
    @template_id AS template_id,
    'course' AS template_type,
    c.id AS instance_id,
    c.school_id,
    c.creator_id,
    'create' AS action,
    JSON_OBJECT(
        'version', '1.0.0',
        'action', 'migrate',
        'source_course_id', c.id,
        'template_code', 'IOT-AI-SMARTHOME-001'
    ) AS changes,
    CONCAT('从课程ID ', c.id, ' 迁移为模板') AS notes,
    NOW() AS created_at
FROM pbl_courses c
WHERE c.id = 2;

SELECT '成功记录使用日志' AS '日志记录';

-- ==========================================================================================================
-- 步骤11：验证迁移结果
-- ==========================================================================================================

SELECT '========================================' AS '';
SELECT '步骤11：验证迁移结果' AS '';
SELECT '========================================' AS '';

-- 11.1 查看创建的模板
SELECT 
    ct.id AS 模板ID,
    ct.uuid AS 模板UUID,
    ct.template_code AS 模板编码,
    ct.title AS 模板标题,
    ct.version AS 版本,
    ct.status AS 状态,
    ct.is_public AS 是否公开
FROM pbl_course_templates ct
WHERE ct.id = @template_id;

-- 11.2 验证课程关联
SELECT 
    c.id AS 课程ID,
    c.title AS 课程标题,
    c.template_id AS 模板ID,
    c.template_version AS 模板版本,
    c.is_customized AS 是否自定义,
    ct.template_code AS 模板编码
FROM pbl_courses c
LEFT JOIN pbl_course_templates ct ON ct.id = c.template_id
WHERE c.id = 2;

-- 11.3 对比数据量（确认数据完整性）
SELECT 
    '数据完整性检查' AS 检查项,
    (SELECT COUNT(*) FROM pbl_units WHERE course_id = 2) AS 课程单元数,
    (SELECT COUNT(*) FROM pbl_unit_templates WHERE course_template_id = @template_id) AS 模板单元数,
    (SELECT COUNT(*) FROM pbl_resources r 
     INNER JOIN pbl_units u ON u.id = r.unit_id 
     WHERE u.course_id = 2) AS 课程资源数,
    (SELECT COUNT(*) FROM pbl_resource_templates rt 
     INNER JOIN pbl_unit_templates ut ON ut.id = rt.unit_template_id 
     WHERE ut.course_template_id = @template_id) AS 模板资源数,
    (SELECT COUNT(*) FROM pbl_tasks t 
     INNER JOIN pbl_units u ON u.id = t.unit_id 
     WHERE u.course_id = 2) AS 课程任务数,
    (SELECT COUNT(*) FROM pbl_task_templates tt 
     INNER JOIN pbl_unit_templates ut ON ut.id = tt.unit_template_id 
     WHERE ut.course_template_id = @template_id) AS 模板任务数;

-- 11.4 查看单元详情对比
SELECT 
    u.`order` AS 序号,
    u.title AS 课程单元,
    ut.title AS 模板单元,
    u.template_id AS 单元模板ID,
    CASE WHEN u.title = ut.title THEN '✓' ELSE '✗' END AS 标题匹配
FROM pbl_units u
INNER JOIN pbl_unit_templates ut ON ut.id = u.template_id
WHERE u.course_id = 2
ORDER BY u.`order`;

SET FOREIGN_KEY_CHECKS = 1;

SELECT '========================================' AS '';
SELECT '✓ 迁移完成！' AS '';
SELECT '========================================' AS '';
