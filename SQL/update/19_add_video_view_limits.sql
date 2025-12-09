-- ==========================================
-- 19. 添加视频观看次数限制功能
-- ==========================================
-- 说明：
--   为 pbl_resources 表添加观看次数限制字段
--   创建视频观看记录表，用于详细追踪每次观看行为
--   支持为每个视频资源设置观看次数上限
--
-- 业务逻辑：
--   1. 管理员可以为每个视频资源设置 max_views（最大观看次数）
--   2. max_views = NULL 表示不限制观看次数
--   3. max_views > 0 表示每个学生最多可以观看该视频的次数
--   4. 每次学生请求视频播放凭证时，系统会检查观看次数
--   5. 如果超过限制，拒绝提供播放凭证
--
-- 使用方式：
--   1. 选择数据库：USE aiot_admin;
--   2. 执行本脚本：source /path/to/19_add_video_view_limits.sql;
--
-- ==========================================

SET NAMES utf8mb4;

-- ----------------------------
-- 1. 为 pbl_resources 表添加 max_views 字段
-- ----------------------------
-- 检查字段是否存在
SET @column_exists = (
    SELECT COUNT(*) 
    FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'pbl_resources'
    AND COLUMN_NAME = 'max_views'
);

SET @sql = IF(
    @column_exists = 0,
    'ALTER TABLE `pbl_resources` 
     ADD COLUMN `max_views` INT DEFAULT NULL COMMENT ''最大观看次数（NULL表示不限制，0表示禁止观看，大于0表示限制次数）'' AFTER `video_cover_url`',
    'SELECT ''Column max_views already exists'' AS message'
);

PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- ----------------------------
-- 2. 创建视频观看记录表
-- ----------------------------
-- 用于详细追踪每次视频观看行为
CREATE TABLE IF NOT EXISTS `pbl_video_watch_records` (
  `id` BIGINT(20) NOT NULL AUTO_INCREMENT COMMENT '记录ID',
  `resource_id` BIGINT(20) NOT NULL COMMENT '视频资源ID',
  `user_id` INT(11) NOT NULL COMMENT '用户ID（学生）',
  `watch_time` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '观看时间',
  `duration` INT DEFAULT 0 COMMENT '观看时长（秒）',
  `completed` TINYINT(1) DEFAULT 0 COMMENT '是否观看完成',
  `ip_address` VARCHAR(45) DEFAULT NULL COMMENT '观看IP地址',
  `user_agent` VARCHAR(500) DEFAULT NULL COMMENT '用户代理',
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  PRIMARY KEY (`id`),
  KEY `idx_resource_id` (`resource_id`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_watch_time` (`watch_time`),
  KEY `idx_resource_user` (`resource_id`, `user_id`),
  CONSTRAINT `fk_vwr_resource` FOREIGN KEY (`resource_id`) REFERENCES `pbl_resources` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='视频观看记录表';

-- ----------------------------
-- 3. 创建索引以优化查询性能
-- ----------------------------
-- 为 pbl_learning_logs 表添加组合索引（如果不存在）
SET @index_exists = (
    SELECT COUNT(*)
    FROM INFORMATION_SCHEMA.STATISTICS
    WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'pbl_learning_logs'
    AND INDEX_NAME = 'idx_user_resource_action'
);

SET @sql = IF(
    @index_exists = 0,
    'ALTER TABLE `pbl_learning_logs` ADD KEY `idx_user_resource_action` (`user_id`, `resource_id`, `action_type`)',
    'SELECT ''Index idx_user_resource_action already exists'' AS message'
);

PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- ----------------------------
-- 4. 为现有视频资源设置默认观看次数限制（可选）
-- ----------------------------
-- 默认不限制观看次数，如果需要全局限制，可以取消注释以下SQL
-- UPDATE `pbl_resources` SET `max_views` = 5 WHERE `type` = 'video' AND `max_views` IS NULL;

-- ----------------------------
-- 5. 显示统计信息
-- ----------------------------
SELECT '视频观看次数限制功能添加完成' AS status;

SELECT 
    COUNT(*) AS total_videos,
    SUM(CASE WHEN max_views IS NULL THEN 1 ELSE 0 END) AS unlimited_videos,
    SUM(CASE WHEN max_views > 0 THEN 1 ELSE 0 END) AS limited_videos,
    SUM(CASE WHEN max_views = 0 THEN 1 ELSE 0 END) AS disabled_videos
FROM `pbl_resources`
WHERE `type` = 'video';

-- ----------------------------
-- 7. 使用示例说明
-- ----------------------------
/*
=== 使用示例 ===

1. 设置某个视频的观看次数限制为5次：
   UPDATE `pbl_resources` SET `max_views` = 5 WHERE `uuid` = '视频UUID';

2. 取消某个视频的观看次数限制：
   UPDATE `pbl_resources` SET `max_views` = NULL WHERE `uuid` = '视频UUID';

3. 禁止观看某个视频：
   UPDATE `pbl_resources` SET `max_views` = 0 WHERE `uuid` = '视频UUID';

4. 查询某个学生对某个视频的观看次数：
   SELECT 
       COUNT(vwr.id) AS watch_count,
       r.max_views,
       CASE 
           WHEN r.max_views IS NULL THEN 1
           WHEN r.max_views = 0 THEN 0
           WHEN COUNT(vwr.id) >= r.max_views THEN 0
           ELSE 1
       END AS can_watch
   FROM `pbl_resources` r
   LEFT JOIN `pbl_video_watch_records` vwr ON r.id = vwr.resource_id AND vwr.user_id = 学生ID
   WHERE r.uuid = '视频UUID'
   GROUP BY r.id, r.max_views;

5. 查询某个学生所有视频的观看情况：
   SELECT 
       r.uuid AS resource_uuid,
       r.title AS resource_title,
       COUNT(vwr.id) AS watch_count,
       r.max_views,
       MAX(vwr.watch_time) AS last_watch_time
   FROM `pbl_resources` r
   LEFT JOIN `pbl_video_watch_records` vwr ON r.id = vwr.resource_id AND vwr.user_id = 学生ID
   WHERE r.type = 'video'
   GROUP BY r.id, r.uuid, r.title, r.max_views;

6. 查询已达到观看次数限制的学生（针对某个视频）：
   SELECT 
       u.id AS user_id,
       u.username,
       u.real_name,
       COUNT(vwr.id) AS watch_count,
       r.max_views
   FROM `aiot_core_users` u
   JOIN `pbl_video_watch_records` vwr ON u.id = vwr.user_id
   JOIN `pbl_resources` r ON vwr.resource_id = r.id
   WHERE r.id = 资源ID AND r.max_views IS NOT NULL AND r.max_views > 0
   GROUP BY u.id, u.username, u.real_name, r.max_views
   HAVING COUNT(vwr.id) >= r.max_views;

7. 记录一次视频观看行为：
   INSERT INTO `pbl_video_watch_records` 
   (`resource_id`, `user_id`, `duration`, `completed`) 
   VALUES (资源ID, 用户ID, 观看时长, 是否完成);

8. 统计某个视频的总观看次数：
   SELECT COUNT(*) AS total_views 
   FROM `pbl_video_watch_records` 
   WHERE `resource_id` = 资源ID;

9. 查询观看次数最多的视频TOP 10：
   SELECT r.title, COUNT(vwr.id) AS view_count
   FROM `pbl_resources` r
   LEFT JOIN `pbl_video_watch_records` vwr ON r.id = vwr.resource_id
   WHERE r.type = 'video'
   GROUP BY r.id, r.title
   ORDER BY view_count DESC
   LIMIT 10;
*/

-- 完成第一部分：视频观看次数限制
-- ==========================================

-- ==========================================
-- 20. 添加视频用户权限表 - 个性化观看次数和有效期设置
-- ==========================================
-- 说明：
--   为每个学生-视频组合设置个性化的观看权限
--   支持设置特定学生对特定视频的观看次数和有效期
--   优先级：个性化配置 > 全局配置
--
-- 业务逻辑：
--   1. 管理员可以为指定学生设置特定视频的观看次数
--   2. 可以设置观看有效期（开始时间和结束时间）
--   3. 个性化配置优先于全局配置（pbl_resources.max_views）
--   4. 如果设置了有效期，只能在有效期内观看
--
-- 使用场景：
--   - 补课学生需要额外的观看次数
--   - 为优秀学生提供更多学习资源
--   - 限时开放某些视频资源
--   - 考试期间临时限制某些视频
--
-- ==========================================

-- ----------------------------
-- 8. 创建视频用户权限表
-- ----------------------------
CREATE TABLE IF NOT EXISTS `pbl_video_user_permissions` (
  `id` BIGINT(20) NOT NULL AUTO_INCREMENT COMMENT '权限ID',
  `uuid` VARCHAR(36) NOT NULL COMMENT 'UUID',
  `resource_id` BIGINT(20) NOT NULL COMMENT '视频资源ID',
  `user_id` INT(11) NOT NULL COMMENT '用户ID（学生）',
  `max_views` INT DEFAULT NULL COMMENT '该学生对该视频的最大观看次数（NULL表示使用全局设置，0表示禁止，>0表示限制次数）',
  `valid_from` TIMESTAMP NULL DEFAULT NULL COMMENT '有效开始时间（NULL表示立即生效）',
  `valid_until` TIMESTAMP NULL DEFAULT NULL COMMENT '有效结束时间（NULL表示永久有效）',
  `reason` VARCHAR(500) DEFAULT NULL COMMENT '设置原因（如：补课、奖励、考试限制等）',
  `created_by` INT(11) NOT NULL COMMENT '创建者ID（管理员/教师）',
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `is_active` TINYINT(1) DEFAULT 1 COMMENT '是否启用',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_uuid` (`uuid`),
  UNIQUE KEY `uk_resource_user` (`resource_id`, `user_id`),
  KEY `idx_resource_id` (`resource_id`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_valid_period` (`valid_from`, `valid_until`),
  KEY `idx_created_by` (`created_by`),
  CONSTRAINT `fk_vup_resource` FOREIGN KEY (`resource_id`) REFERENCES `pbl_resources` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='视频用户权限表（个性化观看次数和有效期设置）';

-- ----------------------------
-- 9. 为 pbl_resources 表添加全局有效期字段
-- ----------------------------
-- 为所有学生设置统一的观看有效期
SET @column_exists = (
    SELECT COUNT(*) 
    FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'pbl_resources'
    AND COLUMN_NAME = 'valid_from'
);

SET @sql = IF(
    @column_exists = 0,
    'ALTER TABLE `pbl_resources` 
     ADD COLUMN `valid_from` TIMESTAMP NULL DEFAULT NULL COMMENT ''全局有效开始时间（NULL表示立即生效）'' AFTER `max_views`,
     ADD COLUMN `valid_until` TIMESTAMP NULL DEFAULT NULL COMMENT ''全局有效结束时间（NULL表示永久有效）'' AFTER `valid_from`',
    'SELECT ''Columns valid_from and valid_until already exist'' AS message'
);

PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- ----------------------------
-- 10. 添加索引以优化查询
-- ----------------------------
SET @index_exists = (
    SELECT COUNT(*)
    FROM INFORMATION_SCHEMA.STATISTICS
    WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'pbl_resources'
    AND INDEX_NAME = 'idx_valid_period'
);

SET @sql = IF(
    @index_exists = 0,
    'ALTER TABLE `pbl_resources` ADD KEY `idx_valid_period` (`valid_from`, `valid_until`)',
    'SELECT ''Index idx_valid_period already exists'' AS message'
);

PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- ----------------------------
-- 11. 显示统计信息
-- ----------------------------
SELECT '视频用户权限表创建完成' AS status;

SELECT 
    COUNT(*) AS total_videos,
    SUM(CASE WHEN max_views IS NULL AND valid_from IS NULL AND valid_until IS NULL THEN 1 ELSE 0 END) AS unlimited_videos,
    SUM(CASE WHEN max_views > 0 THEN 1 ELSE 0 END) AS limited_by_count,
    SUM(CASE WHEN valid_from IS NOT NULL OR valid_until IS NOT NULL THEN 1 ELSE 0 END) AS limited_by_time
FROM `pbl_resources`
WHERE `type` = 'video';

-- ----------------------------
-- 12. 扩展使用示例说明
-- ----------------------------
/*
=== 基础使用示例（第19部分） ===

1. 设置某个视频的观看次数限制为5次：
   UPDATE `pbl_resources` SET `max_views` = 5 WHERE `uuid` = '视频UUID';

2. 取消某个视频的观看次数限制：
   UPDATE `pbl_resources` SET `max_views` = NULL WHERE `uuid` = '视频UUID';

3. 禁止观看某个视频：
   UPDATE `pbl_resources` SET `max_views` = 0 WHERE `uuid` = '视频UUID';

4. 查询某个学生对某个视频的观看次数：
   SELECT 
       COUNT(vwr.id) AS watch_count,
       r.max_views,
       CASE 
           WHEN r.max_views IS NULL THEN 1
           WHEN r.max_views = 0 THEN 0
           WHEN COUNT(vwr.id) >= r.max_views THEN 0
           ELSE 1
       END AS can_watch
   FROM `pbl_resources` r
   LEFT JOIN `pbl_video_watch_records` vwr ON r.id = vwr.resource_id AND vwr.user_id = 学生ID
   WHERE r.uuid = '视频UUID'
   GROUP BY r.id, r.max_views;

5. 查询某个学生所有视频的观看情况：
   SELECT 
       r.uuid AS resource_uuid,
       r.title AS resource_title,
       COUNT(vwr.id) AS watch_count,
       r.max_views,
       MAX(vwr.watch_time) AS last_watch_time
   FROM `pbl_resources` r
   LEFT JOIN `pbl_video_watch_records` vwr ON r.id = vwr.resource_id AND vwr.user_id = 学生ID
   WHERE r.type = 'video'
   GROUP BY r.id, r.uuid, r.title, r.max_views;

6. 查询已达到观看次数限制的学生（针对某个视频）：
   SELECT 
       u.id AS user_id,
       u.username,
       u.real_name,
       COUNT(vwr.id) AS watch_count,
       r.max_views
   FROM `aiot_core_users` u
   JOIN `pbl_video_watch_records` vwr ON u.id = vwr.user_id
   JOIN `pbl_resources` r ON vwr.resource_id = r.id
   WHERE r.id = 资源ID AND r.max_views IS NOT NULL AND r.max_views > 0
   GROUP BY u.id, u.username, u.real_name, r.max_views
   HAVING COUNT(vwr.id) >= r.max_views;

7. 记录一次视频观看行为：
   INSERT INTO `pbl_video_watch_records` 
   (`resource_id`, `user_id`, `duration`, `completed`) 
   VALUES (资源ID, 用户ID, 观看时长, 是否完成);

8. 统计某个视频的总观看次数：
   SELECT COUNT(*) AS total_views 
   FROM `pbl_video_watch_records` 
   WHERE `resource_id` = 资源ID;

9. 查询观看次数最多的视频TOP 10：
   SELECT r.title, COUNT(vwr.id) AS view_count
   FROM `pbl_resources` r
   LEFT JOIN `pbl_video_watch_records` vwr ON r.id = vwr.resource_id
   WHERE r.type = 'video'
   GROUP BY r.id, r.title
   ORDER BY view_count DESC
   LIMIT 10;

=== 个性化权限使用示例（第20部分） ===

-- 1. 为指定学生设置特定视频的观看次数（个性化配置）
INSERT INTO `pbl_video_user_permissions` 
(`uuid`, `resource_id`, `user_id`, `max_views`, `reason`, `created_by`)
VALUES 
(UUID(), 视频资源ID, 学生ID, 10, '补课学生额外观看次数', 管理员ID);

-- 2. 为指定学生设置视频观看有效期
INSERT INTO `pbl_video_user_permissions` 
(`uuid`, `resource_id`, `user_id`, `valid_from`, `valid_until`, `reason`, `created_by`)
VALUES 
(UUID(), 视频资源ID, 学生ID, 
 '2025-12-10 00:00:00', '2025-12-20 23:59:59', 
 '期末复习专用', 管理员ID);

-- 3. 同时设置观看次数和有效期
INSERT INTO `pbl_video_user_permissions` 
(`uuid`, `resource_id`, `user_id`, `max_views`, `valid_from`, `valid_until`, `reason`, `created_by`)
VALUES 
(UUID(), 视频资源ID, 学生ID, 5, 
 '2025-12-08 00:00:00', '2025-12-15 23:59:59', 
 '考试前限时观看', 管理员ID);

-- 4. 为所有学生设置全局有效期（在 pbl_resources 表中）
UPDATE `pbl_resources` 
SET `valid_from` = '2025-12-08 00:00:00',
    `valid_until` = '2026-01-31 23:59:59'
WHERE `uuid` = '视频UUID';

-- 5. 查询某个学生对某个视频的权限
SELECT 
    r.id AS resource_id,
    r.uuid AS resource_uuid,
    r.title AS resource_title,
    r.max_views AS global_max_views,
    r.valid_from AS global_valid_from,
    r.valid_until AS global_valid_until,
    vup.id AS permission_id,
    vup.max_views AS user_max_views,
    vup.valid_from AS user_valid_from,
    vup.valid_until AS user_valid_until,
    COALESCE(vup.max_views, r.max_views) AS effective_max_views,
    COALESCE(vup.valid_from, r.valid_from) AS effective_valid_from,
    COALESCE(vup.valid_until, r.valid_until) AS effective_valid_until,
    COUNT(vwr.id) AS watch_count,
    MAX(vwr.watch_time) AS last_watch_time,
    CASE 
        WHEN vup.id IS NOT NULL AND vup.is_active = 0 THEN 0
        WHEN COALESCE(vup.max_views, r.max_views) = 0 THEN 0
        WHEN COALESCE(vup.max_views, r.max_views) IS NOT NULL 
             AND COUNT(vwr.id) >= COALESCE(vup.max_views, r.max_views) THEN 0
        WHEN COALESCE(vup.valid_from, r.valid_from) IS NOT NULL 
             AND NOW() < COALESCE(vup.valid_from, r.valid_from) THEN 0
        WHEN COALESCE(vup.valid_until, r.valid_until) IS NOT NULL 
             AND NOW() > COALESCE(vup.valid_until, r.valid_until) THEN 0
        ELSE 1
    END AS can_watch
FROM `pbl_resources` r
LEFT JOIN `pbl_video_user_permissions` vup ON r.id = vup.resource_id AND vup.user_id = 学生ID
LEFT JOIN `pbl_video_watch_records` vwr ON r.id = vwr.resource_id AND vwr.user_id = 学生ID
WHERE r.id = 视频资源ID
GROUP BY r.id, r.uuid, r.title, r.max_views, r.valid_from, r.valid_until,
         vup.id, vup.max_views, vup.valid_from, vup.valid_until, vup.is_active;

-- 6. 查询某个学生所有不能观看的视频及原因
SELECT 
    r.title AS 视频标题,
    0 AS 是否可观看,
    CASE 
        WHEN vup.id IS NOT NULL AND vup.is_active = 0 THEN '个性化权限已禁用'
        WHEN COALESCE(vup.max_views, r.max_views) = 0 THEN '该视频已被禁止观看'
        WHEN COALESCE(vup.max_views, r.max_views) IS NOT NULL 
             AND COUNT(vwr.id) >= COALESCE(vup.max_views, r.max_views) THEN 
             CONCAT('已达到观看次数上限（', COALESCE(vup.max_views, r.max_views), '次）')
        WHEN COALESCE(vup.valid_from, r.valid_from) IS NOT NULL 
             AND NOW() < COALESCE(vup.valid_from, r.valid_from) THEN 
             CONCAT('视频将于 ', DATE_FORMAT(COALESCE(vup.valid_from, r.valid_from), '%Y-%m-%d %H:%i'), ' 开放')
        WHEN COALESCE(vup.valid_until, r.valid_until) IS NOT NULL 
             AND NOW() > COALESCE(vup.valid_until, r.valid_until) THEN 
             CONCAT('视频观看期限已于 ', DATE_FORMAT(COALESCE(vup.valid_until, r.valid_until), '%Y-%m-%d %H:%i'), ' 结束')
        ELSE ''
    END AS 原因,
    COALESCE(vup.max_views, r.max_views) AS 观看次数限制,
    COUNT(vwr.id) AS 已观看次数,
    COALESCE(vup.valid_from, r.valid_from) AS 开始时间,
    COALESCE(vup.valid_until, r.valid_until) AS 结束时间
FROM `pbl_resources` r
LEFT JOIN `pbl_video_user_permissions` vup ON r.id = vup.resource_id AND vup.user_id = 学生ID
LEFT JOIN `pbl_video_watch_records` vwr ON r.id = vwr.resource_id AND vwr.user_id = 学生ID
WHERE r.type = 'video'
GROUP BY r.id, r.title, r.max_views, r.valid_from, r.valid_until,
         vup.id, vup.max_views, vup.valid_from, vup.valid_until, vup.is_active
HAVING (vup.id IS NOT NULL AND vup.is_active = 0)
    OR (COALESCE(vup.max_views, r.max_views) = 0)
    OR (COALESCE(vup.max_views, r.max_views) IS NOT NULL AND COUNT(vwr.id) >= COALESCE(vup.max_views, r.max_views))
    OR (COALESCE(vup.valid_from, r.valid_from) IS NOT NULL AND NOW() < COALESCE(vup.valid_from, r.valid_from))
    OR (COALESCE(vup.valid_until, r.valid_until) IS NOT NULL AND NOW() > COALESCE(vup.valid_until, r.valid_until));

-- 7. 批量为多个学生设置相同的权限
INSERT INTO `pbl_video_user_permissions` 
(`uuid`, `resource_id`, `user_id`, `max_views`, `valid_from`, `valid_until`, `reason`, `created_by`)
SELECT 
    UUID(),
    视频资源ID,
    u.id,
    5,
    '2025-12-08 00:00:00',
    '2025-12-31 23:59:59',
    '批量设置',
    管理员ID
FROM `aiot_core_users` u
WHERE u.role = 'student' AND u.class_id = 班级ID;

-- 8. 更新某个学生的权限
UPDATE `pbl_video_user_permissions`
SET `max_views` = 10,
    `valid_until` = '2026-01-31 23:59:59'
WHERE `resource_id` = 视频资源ID AND `user_id` = 学生ID;

-- 9. 禁用某个学生的个性化权限（恢复使用全局设置）
UPDATE `pbl_video_user_permissions`
SET `is_active` = 0
WHERE `resource_id` = 视频资源ID AND `user_id` = 学生ID;

-- 10. 删除某个学生的个性化权限
DELETE FROM `pbl_video_user_permissions`
WHERE `resource_id` = 视频资源ID AND `user_id` = 学生ID;

-- 11. 查询即将过期的视频（7天内）
SELECT 
    r.title AS 视频标题,
    u.id AS 学生ID,
    u.real_name AS 学生姓名,
    COALESCE(vup.valid_until, r.valid_until) AS 过期时间,
    DATEDIFF(COALESCE(vup.valid_until, r.valid_until), NOW()) AS 剩余天数
FROM `pbl_resources` r
CROSS JOIN `aiot_core_users` u
LEFT JOIN `pbl_video_user_permissions` vup ON r.id = vup.resource_id AND u.id = vup.user_id
WHERE r.type = 'video' 
  AND u.role = 'student'
  AND COALESCE(vup.valid_until, r.valid_until) IS NOT NULL
  AND COALESCE(vup.valid_until, r.valid_until) > NOW()
  AND DATEDIFF(COALESCE(vup.valid_until, r.valid_until), NOW()) <= 7
ORDER BY COALESCE(vup.valid_until, r.valid_until);

-- 12. 统计个性化权限使用情况
SELECT 
    COUNT(DISTINCT user_id) AS 设置学生数,
    COUNT(DISTINCT resource_id) AS 涉及视频数,
    SUM(CASE WHEN max_views IS NOT NULL THEN 1 ELSE 0 END) AS 设置观看次数的数量,
    SUM(CASE WHEN valid_from IS NOT NULL OR valid_until IS NOT NULL THEN 1 ELSE 0 END) AS 设置有效期的数量
FROM `pbl_video_user_permissions`
WHERE is_active = 1;
*/

-- 完成
COMMIT;
