-- ==========================================================================================================
-- 统一人数统计逻辑
-- ==========================================================================================================
-- 文件: 20_unify_student_count_logic.sql
-- 版本: 1.0.0
-- 创建日期: 2025-12-13
-- 兼容版本: MySQL 5.7-8.0
-- 说明: 
--   1. 统一所有人数统计逻辑，都基于 pbl_class_members 表
--   2. 更新 pbl_classes 表的 current_members 字段，确保与 pbl_class_members 表数据一致
--   3. 影响页面：
--      - 班级详情页 (/admin/classes/{uuid})
--      - 班级列表页 (/admin/classes)
--      - 课程库页面 (/admin/school-course-library)
--   4. 本脚本支持重复执行
-- ==========================================================================================================

SET NAMES utf8mb4 COLLATE utf8mb4_unicode_ci;

-- ==========================================================================================================
-- 1. 更新所有班级的 current_members 字段，基于 pbl_class_members 表实时统计
-- ==========================================================================================================

SELECT '开始更新班级成员数统计...' AS status;

-- 更新所有班级的 current_members 字段
UPDATE `pbl_classes` cls
SET `current_members` = (
    SELECT COUNT(*)
    FROM `pbl_class_members` cm
    WHERE cm.class_id = cls.id
    AND cm.is_active = 1
)
WHERE cls.is_active = 1;

SELECT '班级成员数统计更新完成' AS status;

-- ==========================================================================================================
-- 2. 验证数据一致性
-- ==========================================================================================================

SELECT '验证数据一致性...' AS status;

-- 显示每个班级的成员数统计
SELECT 
    cls.id AS class_id,
    cls.uuid AS class_uuid,
    cls.name AS class_name,
    cls.current_members AS stored_count,
    (
        SELECT COUNT(*)
        FROM `pbl_class_members` cm
        WHERE cm.class_id = cls.id
        AND cm.is_active = 1
    ) AS actual_count,
    CASE 
        WHEN cls.current_members = (
            SELECT COUNT(*)
            FROM `pbl_class_members` cm
            WHERE cm.class_id = cls.id
            AND cm.is_active = 1
        ) THEN '✓ 一致'
        ELSE '✗ 不一致'
    END AS status
FROM `pbl_classes` cls
WHERE cls.is_active = 1
ORDER BY cls.id;

-- ==========================================================================================================
-- 3. 显示统计摘要
-- ==========================================================================================================

SELECT '统计摘要：' AS summary;

SELECT 
    COUNT(*) AS total_classes,
    SUM(cls.current_members) AS total_members,
    ROUND(AVG(cls.current_members), 2) AS avg_members_per_class,
    MAX(cls.current_members) AS max_members,
    MIN(cls.current_members) AS min_members
FROM `pbl_classes` cls
WHERE cls.is_active = 1;

-- ==========================================================================================================
-- 说明
-- ==========================================================================================================

SELECT '
【重要说明 - 数据一致性保障机制】

1. 人数统计逻辑（双重保障）：
   ✅ 主数据源：pbl_classes.current_members 字段（冗余存储，性能优）
   ✅ 真实数据源：pbl_class_members 表（is_active = 1 的记录数）
   ✅ 更新时机：添加/删除班级成员时自动更新 current_members 字段
   ✅ 校验机制：定期执行本脚本验证和修正数据

2. 后端API修改（性能优化）：
   - club_classes.py - add_members_to_class(): 添加成员时 current_members += 1
   - club_classes.py - remove_member_from_class(): 删除成员时 current_members -= 1
   - club_classes.py - get_classes(): 直接使用 current_members 字段
   - club_classes.py - get_class_detail(): 直接使用 current_members 字段
   - school_courses.py - get_available_courses(): 累加各班级的 current_members

3. 前端修改：
   - ClubClasses.vue: 将"选课人数"改为"班级人数"，显示 current_members

4. 数据一致性保障（三重机制）：
   ① 实时更新：添加/删除成员时同步更新 current_members
   ② 字段约束：使用数据库默认值 DEFAULT 0
   ③ 定期校验：建议每周/每月执行本脚本验证数据

5. 性能优势：
   ✅ 班级列表页：无需100次COUNT查询，直接读取字段
   ✅ 班级详情页：无需JOIN统计，直接使用字段
   ✅ 课程库页面：简单累加各班级的 current_members
   
6. 何时执行本脚本：
   - 首次部署：必须执行，初始化所有班级的 current_members
   - 数据迁移后：建议执行，确保数据一致性
   - 发现异常时：立即执行，修正不一致的数据
   - 定期维护：每周/每月执行一次（可选）
' AS notes;

-- ==========================================================================================================
-- 完成
-- ==========================================================================================================

SELECT '✓ 脚本执行完成！' AS result;
