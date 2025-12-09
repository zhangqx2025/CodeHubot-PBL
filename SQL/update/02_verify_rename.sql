-- ========================================
-- 数据库表重命名验证脚本
-- ========================================
-- 说明：验证表重命名是否成功
-- 执行时间：在 01_rename_tables_core_users_schools.sql 执行后
-- ========================================

SET NAMES utf8mb4;

-- ========================================
-- 1. 检查新表是否存在
-- ========================================
SELECT 
    'core_users' as table_name,
    COUNT(*) as record_count
FROM core_users
UNION ALL
SELECT 
    'core_schools' as table_name,
    COUNT(*) as record_count
FROM core_schools;

-- ========================================
-- 2. 检查表结构
-- ========================================
SHOW CREATE TABLE core_users;
SHOW CREATE TABLE core_schools;

-- ========================================
-- 3. 验证索引
-- ========================================
SHOW INDEX FROM core_users;
SHOW INDEX FROM core_schools;

-- ========================================
-- 4. 验证数据完整性
-- ========================================
-- 检查用户表
SELECT 
    role,
    COUNT(*) as user_count
FROM core_users
WHERE deleted_at IS NULL
GROUP BY role;

-- 检查学校表
SELECT 
    is_active,
    COUNT(*) as school_count
FROM core_schools
GROUP BY is_active;

-- ========================================
-- 5. 检查外键关联（如果有的话）
-- ========================================
-- 注意：PBL系统的外键是通过应用层维护的，没有数据库级外键约束
-- 验证数据关联是否正常
SELECT 
    cs.school_name,
    COUNT(cu.id) as user_count
FROM core_schools cs
LEFT JOIN core_users cu ON cu.school_id = cs.id
WHERE cs.is_active = 1
GROUP BY cs.id, cs.school_name
ORDER BY school_name;

-- ========================================
-- 验证完成
-- ========================================
-- 如果所有查询都成功执行且返回预期结果，说明表重命名成功
-- ========================================
