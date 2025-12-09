-- ==========================================================================================================
-- 为 pbl_tasks 表添加 order 字段，实现课程单元内容的统一顺序管理
-- ==========================================================================================================
-- 
-- 脚本名称: 01_add_order_to_pbl_tasks.sql
-- 创建日期: 2025-12-09
-- 用途说明: 为任务表添加顺序字段，配合资源表的 order 字段实现视频、文档、任务的交替排列和顺序解锁
-- 兼容版本: MySQL 5.7.x, 8.0.x
--
-- ==========================================================================================================

USE aiot_admin;

-- 设置字符集
SET NAMES utf8mb4 COLLATE utf8mb4_unicode_ci;

-- 开始事务
START TRANSACTION;

-- ==========================================================================================================
-- 1. 为 pbl_tasks 表添加 order 字段
-- ==========================================================================================================

-- 检查字段是否已存在，如果不存在则添加
SET @column_exists = (
    SELECT COUNT(*) 
    FROM information_schema.COLUMNS 
    WHERE TABLE_SCHEMA = 'aiot_admin' 
    AND TABLE_NAME = 'pbl_tasks' 
    AND COLUMN_NAME = 'order'
);

-- 如果字段不存在，添加 order 字段
-- 默认值为 0，放在 estimated_time 字段之后
SET @sql_add_column = IF(@column_exists = 0,
    'ALTER TABLE `pbl_tasks` ADD COLUMN `order` INT(11) NOT NULL DEFAULT 0 COMMENT ''顺序（与资源统一排序）'' AFTER `estimated_time`',
    'SELECT ''字段 order 已存在，跳过添加'' AS message'
);

PREPARE stmt FROM @sql_add_column;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- ==========================================================================================================
-- 2. 为 order 字段添加索引
-- ==========================================================================================================

-- 检查索引是否已存在
SET @index_exists = (
    SELECT COUNT(*) 
    FROM information_schema.STATISTICS 
    WHERE TABLE_SCHEMA = 'aiot_admin' 
    AND TABLE_NAME = 'pbl_tasks' 
    AND INDEX_NAME = 'idx_unit_order'
);

-- 如果索引不存在，创建复合索引
-- 复合索引 (unit_id, order) 用于高效查询单元内的任务并按顺序排序
SET @sql_add_index = IF(@index_exists = 0,
    'CREATE INDEX `idx_unit_order` ON `pbl_tasks` (`unit_id`, `order`)',
    'SELECT ''索引 idx_unit_order 已存在，跳过创建'' AS message'
);

PREPARE stmt FROM @sql_add_index;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- ==========================================================================================================
-- 3. 初始化现有数据的 order 值（可选）
-- ==========================================================================================================

-- 说明：
--   如果数据库中已有任务数据，此脚本会为它们设置初始 order 值
--   初始化策略：按任务ID顺序，为每个单元的任务从 100 开始编号（步长10）
--   这样预留了空间，方便后续在任务之间插入资源或其他任务

-- 为每个单元的任务按 id 顺序设置 order 值
-- 使用用户变量来生成序号
SET @current_unit_id = 0;
SET @current_order = 0;

UPDATE pbl_tasks t
JOIN (
    SELECT 
        id,
        unit_id,
        @current_order := IF(@current_unit_id = unit_id, @current_order + 10, 100) AS new_order,
        @current_unit_id := unit_id AS unit_check
    FROM pbl_tasks
    ORDER BY unit_id, id
) sub ON t.id = sub.id
SET t.`order` = sub.new_order
WHERE t.`order` = 0;

-- ==========================================================================================================
-- 4. 验证更新结果
-- ==========================================================================================================

-- 统计更新的任务数量
SELECT 
    '任务 order 字段更新完成' AS status,
    COUNT(*) AS total_tasks,
    COUNT(CASE WHEN `order` > 0 THEN 1 END) AS tasks_with_order
FROM pbl_tasks;

-- 按单元显示任务的 order 分布
SELECT 
    unit_id,
    COUNT(*) AS task_count,
    MIN(`order`) AS min_order,
    MAX(`order`) AS max_order
FROM pbl_tasks
GROUP BY unit_id
ORDER BY unit_id;

-- 提交事务
COMMIT;

-- ==========================================================================================================
-- 执行完成信息
-- ==========================================================================================================

SELECT '==========================================================================================================' AS ' ';
SELECT 'pbl_tasks 表 order 字段添加成功！' AS 'Status';
SELECT '==========================================================================================================' AS ' ';

SELECT '使用说明：' AS 'Information';
SELECT '1. 资源和任务现在可以通过 order 字段统一排序' AS 'Step 1';
SELECT '2. 建议资源和任务的 order 值范围：0-10000，步长为 10' AS 'Step 2';
SELECT '3. 示例：资源1(order=10), 任务1(order=20), 资源2(order=30), 任务2(order=40)' AS 'Step 3';
SELECT '4. 步长为10可以方便后续在两个项目之间插入新内容' AS 'Step 4';

SELECT '==========================================================================================================' AS ' ';

-- ==========================================================================================================
-- 脚本结束
-- ==========================================================================================================
