-- ==========================================================================================================
-- 重构选课表为学习记录表
-- 说明：将 pbl_course_enrollments 从"选课表"重构为"学习记录表"
-- 
-- 原有逻辑：学生需要"选课"才能访问课程
-- 新的逻辑：班级成员自动可以访问班级课程，enrollments 表仅记录学习数据
-- 
-- 执行策略：
-- 1. 保留现有数据和表结构（不删除数据）
-- 2. 确保班级课程的成员都有学习记录
-- 3. 删除不属于班级的选课记录（数据清理）
-- 4. 修改字段注释，明确新的表用途
-- ==========================================================================================================

-- ==========================================================================================================
-- 第一步：数据清理和迁移
-- ==========================================================================================================

-- 1.1 为班级课程的所有成员创建学习记录（如果不存在）
-- 说明：确保每个班级成员都有班级课程的学习记录
DROP PROCEDURE IF EXISTS create_learning_records_for_class_members;

DELIMITER $$

CREATE PROCEDURE create_learning_records_for_class_members()
BEGIN
    DECLARE done INT DEFAULT FALSE;
    DECLARE v_class_id INT;
    DECLARE v_course_id INT;
    DECLARE v_student_id INT;
    
    -- 游标：遍历所有班级课程和成员的组合
    DECLARE cur CURSOR FOR
        SELECT 
            c.class_id,
            c.id as course_id,
            cm.student_id
        FROM pbl_courses c
        INNER JOIN pbl_class_members cm ON c.class_id = cm.class_id
        WHERE c.class_id IS NOT NULL
          AND cm.is_active = 1
          AND NOT EXISTS (
              SELECT 1 
              FROM pbl_course_enrollments e 
              WHERE e.course_id = c.id 
                AND e.user_id = cm.student_id
          );
    
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;
    
    OPEN cur;
    
    read_loop: LOOP
        FETCH cur INTO v_class_id, v_course_id, v_student_id;
        
        IF done THEN
            LEAVE read_loop;
        END IF;
        
        -- 为该学生创建学习记录
        INSERT INTO pbl_course_enrollments (
            course_id,
            user_id,
            class_id,
            enrollment_status,
            enrolled_at,
            progress,
            created_at
        ) VALUES (
            v_course_id,
            v_student_id,
            v_class_id,
            'enrolled',
            NOW(),
            0,
            NOW()
        );
        
    END LOOP;
    
    CLOSE cur;
    
    -- 显示创建的记录数
    SELECT ROW_COUNT() as '新创建的学习记录数';
END$$

DELIMITER ;

-- 执行数据迁移
CALL create_learning_records_for_class_members();

-- 清理存储过程
DROP PROCEDURE IF EXISTS create_learning_records_for_class_members;


-- 1.2 标记不属于班级的选课记录（非班级课程的选课）
-- 说明：对于不通过班级的课程，保留其选课记录，但标记为"独立选课"
UPDATE pbl_course_enrollments e
INNER JOIN pbl_courses c ON e.course_id = c.id
SET e.class_id = NULL
WHERE c.class_id IS NULL;


-- 1.3 清理无效的选课记录
-- 说明：删除学生不是班级成员但有班级课程选课记录的情况（脏数据）
DELETE e 
FROM pbl_course_enrollments e
INNER JOIN pbl_courses c ON e.course_id = c.id
WHERE c.class_id IS NOT NULL
  AND NOT EXISTS (
      SELECT 1 
      FROM pbl_class_members cm 
      WHERE cm.class_id = c.class_id 
        AND cm.student_id = e.user_id 
        AND cm.is_active = 1
  );

-- 显示清理结果
SELECT '清理了无效的选课记录（学生不在班级中但有选课记录）' as '清理说明', ROW_COUNT() as '清理记录数';


-- ==========================================================================================================
-- 第二步：修改表结构和注释（明确新的表用途）
-- ==========================================================================================================

-- 2.1 修改表注释
ALTER TABLE pbl_course_enrollments 
COMMENT = '学习记录表：记录学生的课程学习进度、成绩等数据（不再作为选课权限控制）';

-- 2.2 修改字段注释，明确字段用途
ALTER TABLE pbl_course_enrollments 
MODIFY COLUMN enrollment_status ENUM('enrolled', 'dropped', 'completed') DEFAULT 'enrolled' 
COMMENT '学习状态：enrolled-学习中, dropped-已退出, completed-已完成';

ALTER TABLE pbl_course_enrollments 
MODIFY COLUMN class_id INT 
COMMENT '通过哪个班级获得此课程（NULL表示非班级课程）';

ALTER TABLE pbl_course_enrollments 
MODIFY COLUMN progress INT DEFAULT 0 
COMMENT '学习进度(0-100)';

ALTER TABLE pbl_course_enrollments 
MODIFY COLUMN final_score INT 
COMMENT '最终成绩';

ALTER TABLE pbl_course_enrollments 
MODIFY COLUMN enrolled_at TIMESTAMP 
COMMENT '开始学习时间';

ALTER TABLE pbl_course_enrollments 
MODIFY COLUMN dropped_at TIMESTAMP 
COMMENT '退出学习时间';

ALTER TABLE pbl_course_enrollments 
MODIFY COLUMN completed_at TIMESTAMP 
COMMENT '完成学习时间';


-- ==========================================================================================================
-- 第三步：创建视图，方便查询班级成员的课程访问权限
-- ==========================================================================================================

-- 3.1 创建视图：学生可访问的课程列表（基于班级成员关系）
-- 说明：该视图展示学生通过班级成员关系可以访问的所有课程，自动关联学习记录
DROP VIEW IF EXISTS view_student_accessible_courses;

CREATE VIEW view_student_accessible_courses AS
SELECT 
    cm.student_id,
    c.id AS course_id,
    c.uuid AS course_uuid,
    c.title AS course_title,
    c.class_id,
    cls.name AS class_name,
    c.difficulty,
    c.status AS course_status,
    COALESCE(e.progress, 0) AS progress,
    e.final_score,
    e.enrollment_status AS learning_status,
    e.enrolled_at AS start_learning_at,
    e.completed_at
FROM pbl_class_members cm
INNER JOIN pbl_classes cls ON cm.class_id = cls.id
INNER JOIN pbl_courses c ON c.class_id = cls.id
LEFT JOIN pbl_course_enrollments e ON e.course_id = c.id AND e.user_id = cm.student_id
WHERE cm.is_active = 1
  AND cls.is_active = 1
  AND c.status = 'published'
ORDER BY cm.student_id, c.id;


-- 3.2 创建视图：班级课程的学习统计
-- 说明：该视图统计每个班级课程的学习情况，包括成员数、学习人数、完成人数、平均进度和成绩
DROP VIEW IF EXISTS view_class_course_learning_stats;

CREATE VIEW view_class_course_learning_stats AS
SELECT 
    c.id AS course_id,
    c.uuid AS course_uuid,
    c.title AS course_title,
    c.class_id,
    cls.name AS class_name,
    COUNT(DISTINCT cm.student_id) AS total_members,
    COUNT(DISTINCT CASE WHEN e.id IS NOT NULL THEN e.user_id END) AS learning_count,
    COUNT(DISTINCT CASE WHEN e.enrollment_status = 'completed' THEN e.user_id END) AS completed_count,
    ROUND(AVG(CASE WHEN e.progress IS NOT NULL THEN e.progress ELSE 0 END), 2) AS avg_progress,
    ROUND(AVG(e.final_score), 2) AS avg_score
FROM pbl_courses c
INNER JOIN pbl_classes cls ON c.class_id = cls.id
INNER JOIN pbl_class_members cm ON cm.class_id = cls.id AND cm.is_active = 1
LEFT JOIN pbl_course_enrollments e ON e.course_id = c.id AND e.user_id = cm.student_id
WHERE c.class_id IS NOT NULL
  AND cls.is_active = 1
GROUP BY c.id, c.uuid, c.title, c.class_id, cls.name
ORDER BY c.class_id, c.id;


-- ==========================================================================================================
-- 第四步：创建触发器，自动为新加入的班级成员创建学习记录
-- ==========================================================================================================

-- 4.1 班级成员加入时，自动创建该班级所有课程的学习记录
DROP TRIGGER IF EXISTS trg_after_class_member_insert;

DELIMITER $$

CREATE TRIGGER trg_after_class_member_insert
AFTER INSERT ON pbl_class_members
FOR EACH ROW
BEGIN
    -- 为新成员创建该班级所有已发布课程的学习记录
    INSERT INTO pbl_course_enrollments (course_id, user_id, class_id, enrollment_status, enrolled_at, progress)
    SELECT 
        c.id,
        NEW.student_id,
        NEW.class_id,
        'enrolled',
        NOW(),
        0
    FROM pbl_courses c
    WHERE c.class_id = NEW.class_id
      AND c.status = 'published'
      AND NOT EXISTS (
          SELECT 1 
          FROM pbl_course_enrollments e 
          WHERE e.course_id = c.id 
            AND e.user_id = NEW.student_id
      );
END$$

DELIMITER ;


-- 4.2 班级创建新课程时，自动为所有班级成员创建学习记录
DROP TRIGGER IF EXISTS trg_after_course_publish;

DELIMITER $$

CREATE TRIGGER trg_after_course_publish
AFTER UPDATE ON pbl_courses
FOR EACH ROW
BEGIN
    -- 当课程状态变为 published 且课程属于某个班级时
    IF NEW.status = 'published' AND OLD.status != 'published' AND NEW.class_id IS NOT NULL THEN
        -- 为该班级的所有成员创建学习记录
        INSERT INTO pbl_course_enrollments (course_id, user_id, class_id, enrollment_status, enrolled_at, progress)
        SELECT 
            NEW.id,
            cm.student_id,
            NEW.class_id,
            'enrolled',
            NOW(),
            0
        FROM pbl_class_members cm
        WHERE cm.class_id = NEW.class_id
          AND cm.is_active = 1
          AND NOT EXISTS (
              SELECT 1 
              FROM pbl_course_enrollments e 
              WHERE e.course_id = NEW.id 
                AND e.user_id = cm.student_id
          );
    END IF;
END$$

DELIMITER ;


-- ==========================================================================================================
-- 第五步：数据验证和统计
-- ==========================================================================================================

-- 5.1 检查数据一致性
SELECT '=== 数据一致性检查 ===' AS '';

-- 检查：是否有班级成员没有对应的学习记录
SELECT 
    '班级成员缺少学习记录' AS check_item,
    COUNT(*) AS count
FROM pbl_class_members cm
INNER JOIN pbl_courses c ON c.class_id = cm.class_id
WHERE cm.is_active = 1
  AND c.status = 'published'
  AND NOT EXISTS (
      SELECT 1 
      FROM pbl_course_enrollments e 
      WHERE e.course_id = c.id 
        AND e.user_id = cm.student_id
  );

-- 检查：是否有学习记录但学生不是班级成员（脏数据）
SELECT 
    '存在无效学习记录（学生不在班级中）' AS check_item,
    COUNT(*) AS count
FROM pbl_course_enrollments e
INNER JOIN pbl_courses c ON e.course_id = c.id
WHERE c.class_id IS NOT NULL
  AND NOT EXISTS (
      SELECT 1 
      FROM pbl_class_members cm 
      WHERE cm.class_id = c.class_id 
        AND cm.student_id = e.user_id 
        AND cm.is_active = 1
  );


-- 5.2 统计信息
SELECT '=== 数据统计 ===' AS '';

-- 总体统计
SELECT 
    '班级总数' AS item,
    COUNT(*) AS count
FROM pbl_classes
WHERE is_active = 1

UNION ALL

SELECT 
    '班级课程总数' AS item,
    COUNT(*) AS count
FROM pbl_courses
WHERE class_id IS NOT NULL
  AND status = 'published'

UNION ALL

SELECT 
    '班级成员总数' AS item,
    COUNT(*) AS count
FROM pbl_class_members
WHERE is_active = 1

UNION ALL

SELECT 
    '学习记录总数' AS item,
    COUNT(*) AS count
FROM pbl_course_enrollments;


-- 5.3 按班级统计
SELECT '=== 各班级数据统计 ===' AS '';

SELECT 
    cls.id AS class_id,
    cls.name AS class_name,
    COUNT(DISTINCT c.id) AS course_count,
    COUNT(DISTINCT cm.student_id) AS member_count,
    COUNT(DISTINCT e.id) AS learning_record_count
FROM pbl_classes cls
LEFT JOIN pbl_courses c ON c.class_id = cls.id AND c.status = 'published'
LEFT JOIN pbl_class_members cm ON cm.class_id = cls.id AND cm.is_active = 1
LEFT JOIN pbl_course_enrollments e ON e.course_id = c.id AND e.user_id = cm.student_id
WHERE cls.is_active = 1
GROUP BY cls.id, cls.name
ORDER BY cls.id;


-- ==========================================================================================================
-- 执行完成提示
-- ==========================================================================================================

SELECT '
========================================
数据迁移完成！

表用途说明：
- pbl_class_members: 班级成员关系（权限控制）
- pbl_courses.class_id: 课程归属班级
- pbl_course_enrollments: 学习记录（进度、成绩）

访问规则：
- 班级成员自动可以访问班级的所有课程
- 不再需要"选课"操作
- enrollments 表仅记录学习数据

触发器：
- 新成员加入班级 → 自动创建学习记录
- 课程发布到班级 → 自动为班级成员创建学习记录

查询视图：
- view_student_accessible_courses: 学生可访问的课程
- view_class_course_learning_stats: 班级课程学习统计

建议：
1. 更新后端代码，使用班级成员关系判断访问权限
2. 删除"选课"相关的前端界面和API
3. 保留学习记录的读写API（进度、成绩）
========================================
' AS '迁移完成';
