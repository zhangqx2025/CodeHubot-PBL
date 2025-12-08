-- ==========================================
-- 确保所有课程都有UUID
-- ==========================================
-- 
-- 说明：
--   本脚本用于确保pbl_courses表中的所有记录都有uuid值
--   如果某些课程记录的uuid为空，则自动生成并填充
--
-- 使用方式：
--   mysql -u username -p database_name < 13_ensure_course_uuid.sql
--
-- 注意事项：
--   - 支持 MySQL 5.7-8.0 版本
--   - 此脚本是幂等的，可以多次执行
--
-- ==========================================

-- 为没有uuid的课程记录生成uuid
UPDATE pbl_courses 
SET uuid = UUID() 
WHERE uuid IS NULL OR uuid = '';

-- 验证结果
SELECT 
    COUNT(*) as total_courses,
    COUNT(uuid) as courses_with_uuid,
    COUNT(*) - COUNT(uuid) as courses_without_uuid
FROM pbl_courses;

-- 显示所有课程的id和uuid对应关系
SELECT id, uuid, title 
FROM pbl_courses 
ORDER BY id;
