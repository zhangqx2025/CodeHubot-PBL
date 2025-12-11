-- 修复课程进度计算问题
-- 问题描述：课程进度使用了单元表本身的status字段，而不是学生的实际完成状态
-- 解决方案：根据学生实际完成的单元数重新计算课程进度

-- 更新所有选课记录的进度
-- 对每个选课记录，计算该学生已完成的单元数占总单元数的百分比

UPDATE pbl_course_enrollments e
SET progress = (
    SELECT IFNULL(
        FLOOR(
            (
                -- 计算该学生在该课程中已完成的单元数
                SELECT COUNT(DISTINCT lp.unit_id)
                FROM pbl_learning_progress lp
                WHERE lp.user_id = e.user_id
                  AND lp.course_id = e.course_id
                  AND lp.unit_id IS NOT NULL
                  AND lp.progress_type = 'unit_complete'
                  AND lp.status = 'completed'
            ) * 100.0 / (
                -- 计算该课程的总单元数
                SELECT COUNT(*)
                FROM pbl_units u
                WHERE u.course_id = e.course_id
            )
        ), 
        0
    )
)
WHERE e.enrollment_status = 'enrolled'
  AND (
    SELECT COUNT(*)
    FROM pbl_units u
    WHERE u.course_id = e.course_id
  ) > 0;

-- 对于完成了所有单元的学生，将选课状态标记为已完成
UPDATE pbl_course_enrollments e
SET enrollment_status = 'completed',
    completed_at = NOW()
WHERE e.enrollment_status = 'enrolled'
  AND e.progress >= 100;
