-- ==========================================================================================================
-- 为单元表添加开放时间字段
-- ==========================================================================================================
-- 脚本名称: 25_add_unit_open_from.sql
-- 创建日期: 2025-12-14
-- 功能说明: 
--   1. 为 pbl_units 表添加 open_from 字段，用于控制单元对学生的开放时间
--   2. 只有当前时间 >= open_from 时，学生才能访问该单元
--   3. 如果 open_from 为 NULL，表示单元立即开放（取决于 status 字段）
--
-- 兼容版本: MySQL 5.7.x, 8.0.x
-- 
-- ⚠️ 注意：此脚本只能执行一次，重复执行会报错（字段已存在）
-- ==========================================================================================================

-- ==========================================================================================================
-- 1. 为 pbl_units 表添加 open_from 字段
-- ==========================================================================================================

-- 添加开放时间字段
ALTER TABLE `pbl_units`
ADD COLUMN `open_from` DATETIME DEFAULT NULL COMMENT '单元开放时间（NULL表示立即开放）' AFTER `status`;

-- ==========================================================================================================
-- 验证更新
-- ==========================================================================================================

-- 验证字段是否添加成功
SELECT 
    '验证结果' AS '',
    COUNT(*) AS '字段数量',
    GROUP_CONCAT(COLUMN_NAME) AS '字段列表'
FROM information_schema.COLUMNS
WHERE TABLE_SCHEMA = DATABASE()
  AND TABLE_NAME = 'pbl_units'
  AND COLUMN_NAME = 'open_from';

-- 显示 pbl_units 表结构
SELECT 
    COLUMN_NAME AS '字段名',
    COLUMN_TYPE AS '类型',
    IS_NULLABLE AS '可空',
    COLUMN_DEFAULT AS '默认值',
    COLUMN_COMMENT AS '注释'
FROM information_schema.COLUMNS
WHERE TABLE_SCHEMA = DATABASE()
  AND TABLE_NAME = 'pbl_units'
ORDER BY ORDINAL_POSITION;

-- ==========================================================================================================
-- 使用说明
-- ==========================================================================================================
/*
字段说明：
- open_from: 单元开放时间
  - NULL: 单元立即开放（具体是否可访问还取决于 status 字段）
  - 具体时间: 只有当前时间 >= open_from 时，学生才能访问该单元
  
使用示例：
1. 设置单元在 2025-12-20 00:00:00 开放：
   UPDATE pbl_units SET open_from = '2025-12-20 00:00:00' WHERE uuid = 'xxx';
   
2. 设置单元立即开放：
   UPDATE pbl_units SET open_from = NULL WHERE uuid = 'xxx';
   
3. 查询已开放的单元（当前时间已过开放时间）：
   SELECT * FROM pbl_units 
   WHERE status = 'available' 
     AND (open_from IS NULL OR open_from <= NOW());
     
4. 查询未开放的单元（当前时间未到开放时间）：
   SELECT * FROM pbl_units 
   WHERE open_from IS NOT NULL AND open_from > NOW();
*/
