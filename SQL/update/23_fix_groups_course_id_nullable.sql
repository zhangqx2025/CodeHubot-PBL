-- ==========================================================================================================
-- 23. 修复小组表 course_id 字段允许为 NULL
-- ==========================================================================================================
-- 说明：
-- 1. 小组可以是班级级别的（course_id 为 NULL）
-- 2. 小组也可以是课程级别的（course_id 有值）
-- 3. 前端在班级管理页面创建小组时，不传递 course_id
-- 4. 因此需要将 course_id 字段改回允许 NULL
-- ==========================================================================================================


-- 删除现有的外键约束
SET @fk_exists = (
    SELECT COUNT(*) 
    FROM information_schema.TABLE_CONSTRAINTS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = 'pbl_groups'
      AND CONSTRAINT_NAME = 'fk_groups_course'
      AND CONSTRAINT_TYPE = 'FOREIGN KEY'
);

SET @sql = IF(@fk_exists > 0,
    'ALTER TABLE `pbl_groups` DROP FOREIGN KEY `fk_groups_course`',
    'SELECT "Foreign key fk_groups_course does not exist" AS result');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 修改 course_id 字段为允许 NULL
ALTER TABLE `pbl_groups`
  MODIFY COLUMN `course_id` BIGINT(20) DEFAULT NULL COMMENT '所属课程ID（可选，班级级别的小组可为空）';

-- 重新创建外键约束（保留 ON DELETE SET NULL）
SET @sql = IF(@fk_exists > 0,
    'ALTER TABLE `pbl_groups` ADD CONSTRAINT `fk_groups_course` FOREIGN KEY (`course_id`) REFERENCES `pbl_courses` (`id`) ON DELETE SET NULL',
    'SELECT "Skip adding foreign key fk_groups_course" AS result');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 验证修改结果
SELECT 
    COLUMN_NAME,
    COLUMN_TYPE,
    IS_NULLABLE,
    COLUMN_DEFAULT,
    COLUMN_COMMENT
FROM information_schema.COLUMNS
WHERE TABLE_SCHEMA = DATABASE()
  AND TABLE_NAME = 'pbl_groups'
  AND COLUMN_NAME = 'course_id';

SELECT '✅ pbl_groups.course_id 字段已修改为允许 NULL' AS status;
