-- ==========================================================================================================
-- 课程模板学校开放权限管理
-- ==========================================================================================================
-- 
-- 脚本名称: 09_add_template_school_permissions.sql
-- 脚本版本: 1.0.1
-- 创建日期: 2025-12-11
-- 更新日期: 2025-12-11
-- 兼容版本: MySQL 5.7.x, 8.0.x
-- 字符集: utf8mb4
-- 排序规则: utf8mb4_unicode_ci
--
-- 功能说明:
-- 1. 创建课程模板学校开放权限表 (pbl_template_school_permissions)
--    - 平台管理员可以将模板库中的课程开放给指定的学校
--    - 学校管理员可以查看开放给本校的模板课程
--    - 学校管理员可以基于开放的模板创建实际课程
--
-- 使用场景:
-- 1. 平台管理员在模板库中管理课程模板
-- 2. 平台管理员选择模板，开放给指定的学校
-- 3. 学校管理员查看开放给本校的模板列表
-- 4. 学校管理员基于模板创建课程实例
--
-- ==========================================================================================================
-- 【重要】执行前置条件:
-- ==========================================================================================================
-- 
-- 本脚本依赖以下表，执行前请确保这些表已存在：
-- 1. pbl_course_templates  - 课程模板表（通过 04_add_course_templates.sql 创建）
-- 2. core_schools          - 学校表（系统初始化时创建）
-- 3. core_users            - 用户表（系统初始化时创建）
-- 4. pbl_courses           - 课程表（系统初始化时创建）
--
-- 如果依赖表不存在，脚本会：
-- - 成功创建 pbl_template_school_permissions 表（不含外键约束）
-- - 跳过外键约束的创建
-- - 在验证部分显示警告信息
--
-- 建议执行顺序：
-- 1. 确保数据库已正确初始化（init_database.sql）
-- 2. 执行 04_add_course_templates.sql
-- 3. 执行本脚本（09_add_template_school_permissions.sql）
--
-- ==========================================================================================================

SET SQL_MODE = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION';
SET NAMES utf8mb4 COLLATE utf8mb4_unicode_ci;
SET FOREIGN_KEY_CHECKS = 0;

-- ==========================================================================================================
-- 0. 前置检查：验证依赖表是否存在
-- ==========================================================================================================

-- 检查 pbl_course_templates 表
SELECT CASE 
    WHEN EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_schema = DATABASE() 
          AND table_name = 'pbl_course_templates'
    )
    THEN '✓ pbl_course_templates 表存在'
    ELSE '✗ ERROR: pbl_course_templates 表不存在，请先执行 04_add_course_templates.sql'
END AS '依赖检查1';

-- 检查 core_schools 表
SELECT CASE 
    WHEN EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_schema = DATABASE() 
          AND table_name = 'core_schools'
    )
    THEN '✓ core_schools 表存在'
    ELSE '✗ ERROR: core_schools 表不存在，请检查数据库初始化脚本'
END AS '依赖检查2';

-- 检查 core_users 表
SELECT CASE 
    WHEN EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_schema = DATABASE() 
          AND table_name = 'core_users'
    )
    THEN '✓ core_users 表存在'
    ELSE '✗ ERROR: core_users 表不存在，请检查数据库初始化脚本'
END AS '依赖检查3';

-- ==========================================================================================================
-- 1. 创建课程模板学校开放权限表
-- ==========================================================================================================

DROP TABLE IF EXISTS `pbl_template_school_permissions`;

CREATE TABLE `pbl_template_school_permissions` (
  `id` BIGINT(20) NOT NULL AUTO_INCREMENT PRIMARY KEY COMMENT '主键ID',
  `uuid` CHAR(36) NOT NULL COMMENT 'UUID，用于外部API访问',
  
  -- 关联信息
  `template_id` BIGINT(20) NOT NULL COMMENT '课程模板ID',
  `school_id` INT(11) NOT NULL COMMENT '学校ID',
  
  -- 权限设置
  `is_active` TINYINT(1) NOT NULL DEFAULT 1 COMMENT '是否激活（0-禁用，1-启用）',
  `can_customize` TINYINT(1) NOT NULL DEFAULT 1 COMMENT '是否允许自定义修改（0-不允许，1-允许）',
  
  -- 使用限制
  `max_instances` INT(11) DEFAULT NULL COMMENT '最大创建实例数（NULL表示不限制）',
  `current_instances` INT(11) NOT NULL DEFAULT 0 COMMENT '当前已创建实例数',
  
  -- 有效期设置
  `valid_from` TIMESTAMP NULL DEFAULT NULL COMMENT '有效开始时间（NULL表示立即生效）',
  `valid_until` TIMESTAMP NULL DEFAULT NULL COMMENT '有效结束时间（NULL表示永久有效）',
  
  -- 管理信息
  `granted_by` INT(11) NOT NULL COMMENT '授权人ID（平台管理员）',
  `granted_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '授权时间',
  `remarks` TEXT COMMENT '备注说明',
  
  -- 时间戳
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  
  -- 唯一约束：一个模板对一个学校只能有一条有效记录
  UNIQUE KEY `uk_template_school` (`template_id`, `school_id`),
  
  -- 索引
  KEY `idx_uuid` (`uuid`),
  KEY `idx_template_id` (`template_id`),
  KEY `idx_school_id` (`school_id`),
  KEY `idx_is_active` (`is_active`),
  KEY `idx_granted_by` (`granted_by`),
  KEY `idx_valid_from` (`valid_from`),
  KEY `idx_valid_until` (`valid_until`)
  
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci 
COMMENT='课程模板学校开放权限表 - 管理平台向学校开放的课程模板';

-- ==========================================================================================================
-- 1.1 添加外键约束（条件执行，如果依赖表存在）
-- ==========================================================================================================

-- 添加到 pbl_course_templates 的外键
SET @fk_table_exists = (
    SELECT COUNT(*) FROM information_schema.tables 
    WHERE table_schema = DATABASE() 
      AND table_name = 'pbl_course_templates'
);

SET @sql = IF(@fk_table_exists > 0,
    'ALTER TABLE `pbl_template_school_permissions` 
     ADD CONSTRAINT `fk_tsp_template` 
     FOREIGN KEY (`template_id`) REFERENCES `pbl_course_templates` (`id`) 
     ON DELETE CASCADE',
    'SELECT "跳过外键 fk_tsp_template: pbl_course_templates 表不存在" AS warning'
);

PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 添加到 core_schools 的外键
SET @fk_table_exists = (
    SELECT COUNT(*) FROM information_schema.tables 
    WHERE table_schema = DATABASE() 
      AND table_name = 'core_schools'
);

SET @sql = IF(@fk_table_exists > 0,
    'ALTER TABLE `pbl_template_school_permissions` 
     ADD CONSTRAINT `fk_tsp_school` 
     FOREIGN KEY (`school_id`) REFERENCES `core_schools` (`id`) 
     ON DELETE CASCADE',
    'SELECT "跳过外键 fk_tsp_school: core_schools 表不存在" AS warning'
);

PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 添加到 core_users 的外键
SET @fk_table_exists = (
    SELECT COUNT(*) FROM information_schema.tables 
    WHERE table_schema = DATABASE() 
      AND table_name = 'core_users'
);

SET @sql = IF(@fk_table_exists > 0,
    'ALTER TABLE `pbl_template_school_permissions` 
     ADD CONSTRAINT `fk_tsp_granter` 
     FOREIGN KEY (`granted_by`) REFERENCES `core_users` (`id`) 
     ON DELETE RESTRICT',
    'SELECT "跳过外键 fk_tsp_granter: core_users 表不存在" AS warning'
);

PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- ==========================================================================================================
-- 2. 触发器：自动生成 UUID
-- ==========================================================================================================
-- 注意：根据系统规范，不使用触发器，UUID在应用层生成
-- （此部分保留为空，仅作为说明）

-- ==========================================================================================================
-- 3. 更新 pbl_courses 表，添加权限记录ID
-- ==========================================================================================================
-- 当学校基于模板创建课程时，记录使用的是哪个权限记录

-- 创建临时存储过程检查列是否存在
DROP PROCEDURE IF EXISTS add_column_if_not_exists;

DELIMITER $$
CREATE PROCEDURE add_column_if_not_exists(
    IN tableName VARCHAR(128),
    IN columnName VARCHAR(128),
    IN columnDefinition TEXT
)
BEGIN
    DECLARE column_count INT;
    SELECT COUNT(*) INTO column_count
    FROM information_schema.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = tableName
      AND COLUMN_NAME = columnName;
    
    IF column_count = 0 THEN
        SET @sql = CONCAT('ALTER TABLE `', tableName, '` ADD COLUMN `', columnName, '` ', columnDefinition);
        PREPARE stmt FROM @sql;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;
    END IF;
END$$
DELIMITER ;

-- 添加列
CALL add_column_if_not_exists(
    'pbl_courses', 
    'permission_id', 
    'BIGINT(20) DEFAULT NULL COMMENT \'关联的模板开放权限ID\' AFTER `template_version`'
);

-- 清理存储过程
DROP PROCEDURE IF EXISTS add_column_if_not_exists;

-- 添加外键约束（如果不存在）
SET @fk_exists = (
    SELECT COUNT(*) FROM information_schema.TABLE_CONSTRAINTS 
    WHERE CONSTRAINT_SCHEMA = DATABASE() 
      AND TABLE_NAME = 'pbl_courses' 
      AND CONSTRAINT_NAME = 'fk_course_permission'
);

SET @sql = IF(@fk_exists = 0,
    'ALTER TABLE `pbl_courses` ADD CONSTRAINT `fk_course_permission` FOREIGN KEY (`permission_id`) REFERENCES `pbl_template_school_permissions` (`id`) ON DELETE SET NULL',
    'SELECT "外键 fk_course_permission 已存在" AS result'
);

PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- ==========================================================================================================
-- 4. 创建视图：学校可用的课程模板
-- ==========================================================================================================
-- 注意：根据系统规范，不使用视图，改为在应用层实现查询逻辑

-- ==========================================================================================================
-- 5. 插入测试数据（可选）
-- ==========================================================================================================

-- 示例：为学校开放一些课程模板
-- INSERT INTO `pbl_template_school_permissions` 
-- (`uuid`, `template_id`, `school_id`, `is_active`, `can_customize`, `granted_by`, `remarks`)
-- VALUES
-- (UUID(), 1, 1, 1, 1, 1, '测试开放AI基础课程'),
-- (UUID(), 2, 1, 1, 0, 1, '测试开放Python编程，不允许自定义');

-- ==========================================================================================================
-- 6. 验证
-- ==========================================================================================================

-- 检查表是否创建成功
SELECT 
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM information_schema.tables 
            WHERE table_schema = DATABASE() 
              AND table_name = 'pbl_template_school_permissions'
        )
        THEN '✓ pbl_template_school_permissions 表创建成功'
        ELSE '✗ ERROR: pbl_template_school_permissions 表创建失败'
    END AS '表创建状态';

-- 检查 pbl_courses.permission_id 列是否添加
SELECT 
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM information_schema.COLUMNS 
            WHERE TABLE_SCHEMA = DATABASE() 
              AND TABLE_NAME = 'pbl_courses' 
              AND COLUMN_NAME = 'permission_id'
        )
        THEN '✓ pbl_courses.permission_id 列添加成功'
        ELSE '✗ ERROR: pbl_courses.permission_id 列添加失败'
    END AS 'Courses表列添加状态';

-- 检查外键约束
SELECT 
    CASE 
        WHEN COUNT(*) > 0 
        THEN CONCAT('✓ 创建了 ', COUNT(*), ' 个外键约束')
        ELSE '⚠ 警告: 未创建外键约束（可能依赖表不存在）'
    END AS '外键状态',
    IFNULL(GROUP_CONCAT(CONSTRAINT_NAME SEPARATOR ', '), '无') AS '外键名称'
FROM information_schema.TABLE_CONSTRAINTS 
WHERE CONSTRAINT_SCHEMA = DATABASE() 
  AND TABLE_NAME = 'pbl_template_school_permissions' 
  AND CONSTRAINT_TYPE = 'FOREIGN KEY';

-- 查看表结构（仅在表存在时执行）
SET @table_exists = (
    SELECT COUNT(*) FROM information_schema.tables 
    WHERE table_schema = DATABASE() 
      AND table_name = 'pbl_template_school_permissions'
);

-- 如果表存在，显示表结构
SELECT CASE 
    WHEN @table_exists > 0 
    THEN '表已创建，可以使用 SHOW CREATE TABLE pbl_template_school_permissions 查看详细结构'
    ELSE '✗ ERROR: 表创建失败'
END AS '表结构查询提示';

-- ==========================================================================================================
-- 7. 使用说明
-- ==========================================================================================================

SELECT '==========================================================================================================' AS ' ';
SELECT '使用说明' AS ' ';
SELECT '==========================================================================================================' AS ' ';

SELECT '1. 平台管理员开放模板给学校：' AS '步骤 1';
SELECT '   INSERT INTO pbl_template_school_permissions (uuid, template_id, school_id, granted_by, remarks)' AS ' ';
SELECT '   VALUES (UUID(), <模板ID>, <学校ID>, <管理员ID>, <备注>);' AS ' ';

SELECT '2. 查询学校可用的模板：' AS '步骤 2';
SELECT '   SELECT t.*, p.can_customize, p.valid_from, p.valid_until' AS ' ';
SELECT '   FROM pbl_course_templates t' AS ' ';
SELECT '   INNER JOIN pbl_template_school_permissions p ON t.id = p.template_id' AS ' ';
SELECT '   WHERE p.school_id = <学校ID> AND p.is_active = 1;' AS ' ';

SELECT '3. 学校基于模板创建课程：' AS '步骤 3';
SELECT '   INSERT INTO pbl_courses (uuid, template_id, permission_id, school_id, ...)' AS ' ';
SELECT '   VALUES (UUID(), <模板ID>, <权限ID>, <学校ID>, ...);' AS ' ';

SELECT '4. 更新权限实例计数：' AS '步骤 4';
SELECT '   UPDATE pbl_template_school_permissions' AS ' ';
SELECT '   SET current_instances = current_instances + 1' AS ' ';
SELECT '   WHERE id = <权限ID>;' AS ' ';

SELECT '==========================================================================================================' AS ' ';

-- 恢复外键检查
SET FOREIGN_KEY_CHECKS = 1;

-- ==========================================================================================================
-- 脚本结束
-- ==========================================================================================================
