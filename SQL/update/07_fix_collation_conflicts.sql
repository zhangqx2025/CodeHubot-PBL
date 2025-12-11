-- ==========================================================================================================
-- 统一数据库表排序规则脚本
-- ==========================================================================================================
-- 
-- 脚本名称: 07_fix_collation_conflicts.sql
-- 脚本版本: 1.0.0
-- 创建日期: 2025-12-11
-- 兼容版本: MySQL 5.7.x, 8.0.x
-- 
-- ==========================================================================================================
-- 脚本说明
-- ==========================================================================================================
-- 
-- 1. 问题背景:
--    在 MySQL 8.0 环境中，某些表可能使用了 utf8mb4_0900_ai_ci 排序规则（MySQL 8.0 默认值），
--    而其他表使用了 utf8mb4_unicode_ci 排序规则（MySQL 5.7 默认值）。
--    当跨表查询时，会出现 "Illegal mix of collations" 错误。
-- 
-- 2. 解决方案:
--    统一所有 PBL 相关表及其字段的排序规则为 utf8mb4_unicode_ci，
--    这是 MySQL 5.7 和 8.0 都兼容的标准排序规则。
-- 
-- 3. 影响范围:
--    - 所有 pbl_* 开头的表
--    - 所有字符串类型字段 (VARCHAR, TEXT, CHAR, ENUM, JSON)
-- 
-- 4. 执行方式:
--    方式一 (推荐):
--      mysql -h hostname -u username -p --default-character-set=utf8mb4 aiot_admin < 07_fix_collation_conflicts.sql
--    
--    方式二:
--      mysql> USE aiot_admin;
--      mysql> SOURCE /path/to/07_fix_collation_conflicts.sql;
-- 
-- 5. 注意事项:
--    - 本脚本使用临时存储过程，执行完成后会自动清理
--    - 脚本可以重复执行，不会产生错误
--    - 建议在业务低峰期执行，避免影响线上服务
--    - 执行前请先备份数据库
-- 
-- ==========================================================================================================

-- 设置执行环境
SET NAMES utf8mb4 COLLATE utf8mb4_unicode_ci;
SET FOREIGN_KEY_CHECKS = 0;

-- ==========================================================================================================
-- 第一部分：统一表级别的默认排序规则
-- ==========================================================================================================

SELECT '开始统一表级别排序规则...' AS '执行状态';

-- 统一课程管理模块表
ALTER TABLE `pbl_courses` CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
ALTER TABLE `pbl_course_teachers` CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
ALTER TABLE `pbl_units` CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
ALTER TABLE `pbl_resources` CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
ALTER TABLE `pbl_tasks` CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
ALTER TABLE `pbl_school_courses` CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- 统一项目管理模块表
ALTER TABLE `pbl_projects` CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
ALTER TABLE `pbl_project_outputs` CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- 统一班级和小组管理模块表
ALTER TABLE `pbl_classes` CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
ALTER TABLE `pbl_class_teachers` CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
ALTER TABLE `pbl_groups` CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
ALTER TABLE `pbl_group_members` CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- 统一学习管理模块表
ALTER TABLE `pbl_course_enrollments` CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
ALTER TABLE `pbl_task_progress` CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
ALTER TABLE `pbl_learning_progress` CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
ALTER TABLE `pbl_learning_logs` CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- 统一视频管理模块表
ALTER TABLE `pbl_video_watch_records` CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
ALTER TABLE `pbl_video_user_permissions` CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
ALTER TABLE `pbl_video_play_progress` CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
ALTER TABLE `pbl_video_play_events` CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- 统一评价系统模块表
ALTER TABLE `pbl_assessments` CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
ALTER TABLE `pbl_assessment_templates` CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- 统一伦理教育模块表
ALTER TABLE `pbl_ethics_cases` CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
ALTER TABLE `pbl_ethics_activities` CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- 统一资源管理模块表
ALTER TABLE `pbl_datasets` CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- 统一家校社协同模块表
ALTER TABLE `pbl_student_portfolios` CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
ALTER TABLE `pbl_parent_relations` CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
ALTER TABLE `pbl_external_experts` CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
ALTER TABLE `pbl_social_activities` CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- 统一成就系统模块表
ALTER TABLE `pbl_achievements` CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
ALTER TABLE `pbl_user_achievements` CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- 统一AI对话模块表
ALTER TABLE `pbl_ai_conversations` CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- 统一学校管理模块表
ALTER TABLE `pbl_import_logs` CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- 统一课程模板相关表（如果存在）
-- 使用动态SQL检查表是否存在
SET @table_exists = 0;

-- 检查并转换 pbl_course_templates 表
SELECT COUNT(*) INTO @table_exists FROM information_schema.TABLES 
WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'pbl_course_templates';
SET @sql = IF(@table_exists > 0, 
    'ALTER TABLE `pbl_course_templates` CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci',
    'SELECT "表 pbl_course_templates 不存在，跳过" AS result');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 检查并转换 pbl_unit_templates 表
SELECT COUNT(*) INTO @table_exists FROM information_schema.TABLES 
WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'pbl_unit_templates';
SET @sql = IF(@table_exists > 0, 
    'ALTER TABLE `pbl_unit_templates` CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci',
    'SELECT "表 pbl_unit_templates 不存在，跳过" AS result');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 检查并转换 pbl_resource_templates 表
SELECT COUNT(*) INTO @table_exists FROM information_schema.TABLES 
WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'pbl_resource_templates';
SET @sql = IF(@table_exists > 0, 
    'ALTER TABLE `pbl_resource_templates` CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci',
    'SELECT "表 pbl_resource_templates 不存在，跳过" AS result');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 检查并转换 pbl_task_templates 表
SELECT COUNT(*) INTO @table_exists FROM information_schema.TABLES 
WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'pbl_task_templates';
SET @sql = IF(@table_exists > 0, 
    'ALTER TABLE `pbl_task_templates` CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci',
    'SELECT "表 pbl_task_templates 不存在，跳过" AS result');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SELECT '✓ 表级别排序规则统一完成' AS '执行状态';

-- ==========================================================================================================
-- 第二部分：验证排序规则统一结果
-- ==========================================================================================================

SELECT '' AS '';
SELECT '==========================================================================================================' AS '';
SELECT '排序规则验证报告' AS '';
SELECT '==========================================================================================================' AS '';
SELECT '' AS '';

-- 检查所有 PBL 表的排序规则
SELECT 
    '表级别排序规则统计' AS '检查类型',
    TABLE_NAME AS '表名',
    TABLE_COLLATION AS '当前排序规则',
    CASE 
        WHEN TABLE_COLLATION = 'utf8mb4_unicode_ci' THEN '✓ 正确'
        ELSE '✗ 需要修正'
    END AS '状态'
FROM information_schema.TABLES
WHERE TABLE_SCHEMA = DATABASE()
  AND TABLE_NAME LIKE 'pbl_%'
ORDER BY TABLE_NAME;

SELECT '' AS '';

-- 统计排序规则分布
SELECT 
    '排序规则分布统计' AS '检查类型',
    TABLE_COLLATION AS '排序规则',
    COUNT(*) AS '表数量'
FROM information_schema.TABLES
WHERE TABLE_SCHEMA = DATABASE()
  AND TABLE_NAME LIKE 'pbl_%'
GROUP BY TABLE_COLLATION
ORDER BY COUNT(*) DESC;

SELECT '' AS '';

-- 检查字段级别排序规则（查找可能的问题字段）
SELECT 
    '字段级别排序规则检查' AS '检查类型',
    TABLE_NAME AS '表名',
    COLUMN_NAME AS '字段名',
    COLUMN_TYPE AS '字段类型',
    COLLATION_NAME AS '当前排序规则',
    CASE 
        WHEN COLLATION_NAME = 'utf8mb4_unicode_ci' THEN '✓ 正确'
        WHEN COLLATION_NAME IS NULL THEN '- 无需设置'
        ELSE '✗ 需要修正'
    END AS '状态'
FROM information_schema.COLUMNS
WHERE TABLE_SCHEMA = DATABASE()
  AND TABLE_NAME LIKE 'pbl_%'
  AND COLLATION_NAME IS NOT NULL
  AND COLLATION_NAME != 'utf8mb4_unicode_ci'
ORDER BY TABLE_NAME, COLUMN_NAME;

-- ==========================================================================================================
-- 执行完成信息
-- ==========================================================================================================

SELECT '' AS '';
SELECT '==========================================================================================================' AS '';
SELECT 
    '排序规则统一完成！' AS '执行状态',
    DATABASE() AS '数据库',
    VERSION() AS 'MySQL版本',
    NOW() AS '完成时间';
SELECT '==========================================================================================================' AS '';
SELECT '' AS '';

SELECT '重要提示:' AS '信息';
SELECT '1. 所有 PBL 相关表已统一为 utf8mb4_unicode_ci 排序规则' AS '说明1';
SELECT '2. 此排序规则兼容 MySQL 5.7 和 8.0 版本' AS '说明2';
SELECT '3. 如有字段级别排序规则不一致，请检查上方的验证报告' AS '说明3';
SELECT '4. 建议重启应用服务以确保新的排序规则生效' AS '说明4';
SELECT '5. 如需验证修复结果，可以重新执行之前报错的查询语句' AS '说明5';

SELECT '' AS '';
SELECT '==========================================================================================================' AS '';

-- 恢复外键检查
SET FOREIGN_KEY_CHECKS = 1;

-- ==========================================================================================================
-- 脚本结束
-- ==========================================================================================================
