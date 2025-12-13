-- ==========================================================================================================
-- 删除所有触发器和视图
-- 
-- 说明：根据系统架构决策，所有业务逻辑应在应用层实现，数据库不使用触发器和视图
-- 
-- 执行策略：
-- 1. 删除所有已创建的触发器
-- 2. 删除所有已创建的视图
-- 3. 这些功能将在应用层代码中实现
-- ==========================================================================================================

SELECT '=== 开始删除触发器和视图 ===' AS '';

-- ==========================================================================================================
-- 第一步：删除触发器
-- ==========================================================================================================

SELECT '--- 删除班级成员相关触发器 ---' AS '';

-- 删除班级成员触发器（来自 08_add_club_class_system.sql）
DROP TRIGGER IF EXISTS `trg_class_members_after_insert`;
DROP TRIGGER IF EXISTS `trg_class_members_after_update`;
DROP TRIGGER IF EXISTS `trg_class_members_after_delete`;

SELECT '✓ 已删除班级成员相关触发器' AS '';


-- ==========================================================================================================
-- 第二步：删除视图
-- ==========================================================================================================

SELECT '--- 删除所有视图 ---' AS '';

-- 删除学习记录相关视图（如果存在）
DROP VIEW IF EXISTS `view_student_course_learning`;
DROP VIEW IF EXISTS `view_class_course_learning_stats`;

SELECT '✓ 已删除学习记录相关视图' AS '';


-- ==========================================================================================================
-- 第三步：验证清理结果
-- ==========================================================================================================

SELECT '=== 验证清理结果 ===' AS '';

-- 检查剩余的触发器
SELECT 
    '剩余触发器数量' AS check_item,
    COUNT(*) AS count,
    CASE 
        WHEN COUNT(*) = 0 THEN '✅ 所有触发器已删除'
        ELSE '⚠️  仍有触发器存在'
    END AS status
FROM information_schema.TRIGGERS
WHERE TRIGGER_SCHEMA = DATABASE();

-- 列出剩余的触发器（如果有）
SELECT 
    '--- 剩余的触发器列表 ---' AS '';

SELECT 
    TRIGGER_NAME,
    EVENT_MANIPULATION,
    EVENT_OBJECT_TABLE,
    ACTION_TIMING
FROM information_schema.TRIGGERS
WHERE TRIGGER_SCHEMA = DATABASE();

-- 检查剩余的视图
SELECT 
    '剩余视图数量' AS check_item,
    COUNT(*) AS count,
    CASE 
        WHEN COUNT(*) = 0 THEN '✅ 所有视图已删除'
        ELSE '⚠️  仍有视图存在'
    END AS status
FROM information_schema.VIEWS
WHERE TABLE_SCHEMA = DATABASE();

-- 列出剩余的视图（如果有）
SELECT 
    '--- 剩余的视图列表 ---' AS '';

SELECT 
    TABLE_NAME AS view_name
FROM information_schema.VIEWS
WHERE TABLE_SCHEMA = DATABASE();


-- ==========================================================================================================
-- 完成提示
-- ==========================================================================================================

SELECT '
========================================
✅ 触发器和视图清理完成！

已删除的触发器：
- trg_class_members_after_insert
- trg_class_members_after_update
- trg_class_members_after_delete

已删除的视图：
- view_student_course_learning
- view_class_course_learning_stats

重要说明：
- 所有触发器功能需在应用层实现
- 所有视图查询需在应用层通过JOIN实现
- 班级成员数更新需在添加/删除成员时手动执行UPDATE

应用层需要实现的功能：
1. 添加班级成员时 → 更新 pbl_classes.current_members
2. 删除班级成员时 → 更新 pbl_classes.current_members
3. 更新成员状态时 → 更新 pbl_classes.current_members
4. 学生选课时 → 创建学习记录
5. 学习数据查询 → 通过 JOIN 组合多表数据
6. 统计分析 → 在代码中实现聚合查询

建议：
- 在相关API接口中添加事务处理
- 确保数据一致性由应用层保证
- 添加适当的错误处理和回滚机制
========================================
' AS '清理完成';
