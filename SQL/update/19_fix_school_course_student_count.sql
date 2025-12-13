-- ================================================================
-- 修复学校课程选课人数统计
-- 文件: 19_fix_school_course_student_count.sql
-- 说明: 重新计算 pbl_school_courses 表中的 current_students 字段
--       确保与实际选课记录一致
-- ================================================================

-- 1. 创建临时存储过程来更新选课人数
DROP PROCEDURE IF EXISTS fix_school_course_student_count;

DELIMITER $$

CREATE PROCEDURE fix_school_course_student_count()
BEGIN
    DECLARE done INT DEFAULT 0;
    DECLARE v_course_id BIGINT;
    DECLARE v_enrolled_count INT;
    
    -- 游标：遍历所有学校课程
    DECLARE course_cursor CURSOR FOR 
        SELECT course_id FROM pbl_school_courses;
    
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;
    
    -- 开始事务
    START TRANSACTION;
    
    OPEN course_cursor;
    
    read_loop: LOOP
        FETCH course_cursor INTO v_course_id;
        
        IF done THEN
            LEAVE read_loop;
        END IF;
        
        -- 统计该课程的实际选课人数（只统计 enrolled 状态）
        SELECT COUNT(*) INTO v_enrolled_count
        FROM pbl_course_enrollments
        WHERE course_id = v_course_id
          AND enrollment_status = 'enrolled';
        
        -- 更新 pbl_school_courses 表
        UPDATE pbl_school_courses
        SET current_students = v_enrolled_count
        WHERE course_id = v_course_id;
        
    END LOOP;
    
    CLOSE course_cursor;
    
    -- 提交事务
    COMMIT;
    
    -- 输出统计信息
    SELECT 
        '修复完成' as message,
        COUNT(*) as total_courses,
        SUM(current_students) as total_students
    FROM pbl_school_courses;
    
END$$

DELIMITER ;

-- 2. 执行修复
CALL fix_school_course_student_count();

-- 3. 清理存储过程
DROP PROCEDURE IF EXISTS fix_school_course_student_count;

-- 4. 验证结果（可选）
-- 显示修复后的数据，对比实际选课记录
SELECT 
    sc.id as school_course_id,
    sc.course_id,
    c.title as course_title,
    sc.current_students as stored_count,
    (
        SELECT COUNT(*) 
        FROM pbl_course_enrollments e 
        WHERE e.course_id = sc.course_id 
          AND e.enrollment_status = 'enrolled'
    ) as actual_count,
    (
        sc.current_students - (
            SELECT COUNT(*) 
            FROM pbl_course_enrollments e 
            WHERE e.course_id = sc.course_id 
              AND e.enrollment_status = 'enrolled'
        )
    ) as difference
FROM pbl_school_courses sc
LEFT JOIN pbl_courses c ON sc.course_id = c.id
HAVING difference != 0
ORDER BY sc.id;

-- ================================================================
-- 说明
-- ================================================================
-- 1. 本脚本会重新计算所有学校课程的 current_students 字段
-- 2. 只统计 enrollment_status = 'enrolled' 的学生
-- 3. 可以重复执行，不会产生副作用
-- 4. 执行后，最后一个查询会显示不一致的记录（如果有）
-- ================================================================
