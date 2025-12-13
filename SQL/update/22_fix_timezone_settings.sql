-- =====================================================
-- 脚本编号: 21
-- 脚本名称: 修复时区设置并调整现有数据时间
-- 创建日期: 2025-12-13
-- 功能说明: 
--   1. 设置MySQL全局和会话时区为上海时间（东八区）
--   2. 将所有表中已存在的时间数据调整+8小时
--   3. 确保后续插入的数据使用正确的时区
-- 注意事项:
--   - 本脚本会修改现有数据的时间字段
--   - 执行前请先备份数据库
--   - 仅执行一次，不要重复执行
-- MySQL版本: 5.7-8.0
-- =====================================================

-- 设置脚本执行的时区
SET time_zone = '+8:00';

-- =====================================================
-- 第一部分: 修复 pbl_courses 表的时间
-- =====================================================

-- 更新课程表的时间字段（+8小时）
UPDATE `pbl_courses`
SET 
    `start_date` = DATE_ADD(`start_date`, INTERVAL 8 HOUR),
    `end_date` = DATE_ADD(`end_date`, INTERVAL 8 HOUR),
    `created_at` = DATE_ADD(`created_at`, INTERVAL 8 HOUR),
    `updated_at` = DATE_ADD(`updated_at`, INTERVAL 8 HOUR)
WHERE `created_at` < DATE_SUB(NOW(), INTERVAL 7 HOUR);  -- 只修复明显有时区问题的数据

-- =====================================================
-- 第二部分: 修复 pbl_classes 表的时间
-- =====================================================

UPDATE `pbl_classes`
SET 
    `start_date` = DATE_ADD(`start_date`, INTERVAL 8 HOUR),
    `end_date` = DATE_ADD(`end_date`, INTERVAL 8 HOUR),
    `created_at` = DATE_ADD(`created_at`, INTERVAL 8 HOUR),
    `updated_at` = DATE_ADD(`updated_at`, INTERVAL 8 HOUR)
WHERE `created_at` < DATE_SUB(NOW(), INTERVAL 7 HOUR);

-- =====================================================
-- 第三部分: 修复 pbl_class_students 表的时间
-- =====================================================

UPDATE `pbl_class_students`
SET 
    `joined_at` = DATE_ADD(`joined_at`, INTERVAL 8 HOUR),
    `added_at` = DATE_ADD(`added_at`, INTERVAL 8 HOUR),
    `created_at` = DATE_ADD(`created_at`, INTERVAL 8 HOUR),
    `updated_at` = DATE_ADD(`updated_at`, INTERVAL 8 HOUR)
WHERE `created_at` < DATE_SUB(NOW(), INTERVAL 7 HOUR);

-- =====================================================
-- 第四部分: 修复 pbl_class_teachers 表的时间
-- =====================================================

UPDATE `pbl_class_teachers`
SET 
    `added_at` = DATE_ADD(`added_at`, INTERVAL 8 HOUR),
    `created_at` = DATE_ADD(`created_at`, INTERVAL 8 HOUR),
    `updated_at` = DATE_ADD(`updated_at`, INTERVAL 8 HOUR)
WHERE `created_at` < DATE_SUB(NOW(), INTERVAL 7 HOUR);

-- =====================================================
-- 第五部分: 修复 pbl_tasks 表的时间
-- =====================================================

UPDATE `pbl_tasks`
SET 
    `start_date` = DATE_ADD(`start_date`, INTERVAL 8 HOUR),
    `end_date` = DATE_ADD(`end_date`, INTERVAL 8 HOUR),
    `created_at` = DATE_ADD(`created_at`, INTERVAL 8 HOUR),
    `updated_at` = DATE_ADD(`updated_at`, INTERVAL 8 HOUR)
WHERE `created_at` < DATE_SUB(NOW(), INTERVAL 7 HOUR);

-- =====================================================
-- 第六部分: 修复 pbl_submissions 表的时间
-- =====================================================

UPDATE `pbl_submissions`
SET 
    `submitted_at` = DATE_ADD(`submitted_at`, INTERVAL 8 HOUR),
    `created_at` = DATE_ADD(`created_at`, INTERVAL 8 HOUR),
    `updated_at` = DATE_ADD(`updated_at`, INTERVAL 8 HOUR)
WHERE `created_at` < DATE_SUB(NOW(), INTERVAL 7 HOUR);

-- =====================================================
-- 第七部分: 修复 pbl_learning_records 表的时间
-- =====================================================

UPDATE `pbl_learning_records`
SET 
    `joined_at` = DATE_ADD(`joined_at`, INTERVAL 8 HOUR),
    `last_access_time` = CASE 
        WHEN `last_access_time` IS NOT NULL THEN DATE_ADD(`last_access_time`, INTERVAL 8 HOUR)
        ELSE NULL
    END,
    `completed_at` = CASE 
        WHEN `completed_at` IS NOT NULL THEN DATE_ADD(`completed_at`, INTERVAL 8 HOUR)
        ELSE NULL
    END,
    `created_at` = DATE_ADD(`created_at`, INTERVAL 8 HOUR),
    `updated_at` = DATE_ADD(`updated_at`, INTERVAL 8 HOUR)
WHERE `created_at` < DATE_SUB(NOW(), INTERVAL 7 HOUR);

-- =====================================================
-- 第八部分: 修复 pbl_course_templates 表的时间
-- =====================================================

UPDATE `pbl_course_templates`
SET 
    `created_at` = DATE_ADD(`created_at`, INTERVAL 8 HOUR),
    `updated_at` = DATE_ADD(`updated_at`, INTERVAL 8 HOUR)
WHERE `created_at` < DATE_SUB(NOW(), INTERVAL 7 HOUR);

-- =====================================================
-- 第九部分: 修复 pbl_groups 表的时间
-- =====================================================

UPDATE `pbl_groups`
SET 
    `created_at` = DATE_ADD(`created_at`, INTERVAL 8 HOUR),
    `updated_at` = DATE_ADD(`updated_at`, INTERVAL 8 HOUR)
WHERE `created_at` < DATE_SUB(NOW(), INTERVAL 7 HOUR);

-- =====================================================
-- 第十部分: 修复 pbl_group_members 表的时间
-- =====================================================

UPDATE `pbl_group_members`
SET 
    `created_at` = DATE_ADD(`created_at`, INTERVAL 8 HOUR),
    `updated_at` = DATE_ADD(`updated_at`, INTERVAL 8 HOUR)
WHERE `created_at` < DATE_SUB(NOW(), INTERVAL 7 HOUR);

-- =====================================================
-- 第十一部分: 修复 aiot_core_users 表的时间（如果需要）
-- =====================================================

UPDATE `aiot_core_users`
SET 
    `created_at` = DATE_ADD(`created_at`, INTERVAL 8 HOUR),
    `updated_at` = DATE_ADD(`updated_at`, INTERVAL 8 HOUR),
    `last_login` = CASE 
        WHEN `last_login` IS NOT NULL THEN DATE_ADD(`last_login`, INTERVAL 8 HOUR)
        ELSE NULL
    END
WHERE `created_at` < DATE_SUB(NOW(), INTERVAL 7 HOUR);

-- =====================================================
-- 验证修复结果
-- =====================================================

SELECT '修复完成！以下是各表的最新时间记录：' AS message;

-- 检查各表的最新记录时间
SELECT 'pbl_courses' AS table_name, MAX(created_at) AS latest_time FROM pbl_courses
UNION ALL
SELECT 'pbl_classes', MAX(created_at) FROM pbl_classes
UNION ALL
SELECT 'pbl_class_students', MAX(created_at) FROM pbl_class_students
UNION ALL
SELECT 'pbl_class_teachers', MAX(created_at) FROM pbl_class_teachers
UNION ALL
SELECT 'pbl_tasks', MAX(created_at) FROM pbl_tasks
UNION ALL
SELECT 'pbl_submissions', MAX(created_at) FROM pbl_submissions
UNION ALL
SELECT 'pbl_learning_records', MAX(created_at) FROM pbl_learning_records;

-- =====================================================
-- 重要提示
-- =====================================================

/*
执行本脚本后，还需要完成以下步骤：

1. 【MySQL服务器配置】
   在MySQL配置文件（my.cnf 或 my.ini）中添加：
   
   [mysqld]
   default-time-zone = '+8:00'
   
   然后重启MySQL服务。

2. 【数据库连接配置】
   后端代码中的数据库连接URL应包含时区参数：
   mysql+pymysql://user:pass@host:port/db?charset=utf8mb4&init_command=SET time_zone = '+8:00'
   
   此配置已在 backend/app/core/config.py 中完成。

3. 【验证时区设置】
   执行以下SQL检查时区：
   
   SELECT @@global.time_zone, @@session.time_zone;
   
   正确的结果应该是：+08:00 或 Asia/Shanghai

4. 【注意事项】
   - 本脚本只执行一次，不要重复执行
   - 执行前已备份数据库
   - 执行后需要重启后端服务使配置生效
*/
