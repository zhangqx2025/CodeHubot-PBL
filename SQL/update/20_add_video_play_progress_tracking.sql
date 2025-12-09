-- ==========================================
-- 20. 添加视频播放进度追踪功能
-- ==========================================
-- 说明：
--   创建视频播放进度追踪表，用于详细记录学生观看视频的真实情况
--   支持记录播放进度、拖动行为、暂停时长等详细数据
--   便于统计真实的观看时长和学习效果
--
-- 业务逻辑：
--   1. 前端播放器定期上报播放进度（每10-30秒一次）
--   2. 记录播放位置、播放时长、拖动行为等
--   3. 统计真实观看时长（排除暂停和拖动跳过的部分）
--   4. 支持断点续看功能
--
-- 使用方式：
--   1. 选择数据库：USE aiot_admin;
--   2. 执行本脚本：source /path/to/20_add_video_play_progress_tracking.sql;
--
-- ==========================================

SET NAMES utf8mb4;

-- ----------------------------
-- 1. 创建视频播放进度表
-- ----------------------------
CREATE TABLE IF NOT EXISTS `pbl_video_play_progress` (
  `id` BIGINT(20) NOT NULL AUTO_INCREMENT COMMENT '记录ID',
  `uuid` VARCHAR(36) NOT NULL COMMENT 'UUID',
  `resource_id` BIGINT(20) NOT NULL COMMENT '视频资源ID',
  `user_id` INT(11) NOT NULL COMMENT '用户ID（学生）',
  `session_id` VARCHAR(64) NOT NULL COMMENT '播放会话ID（同一次播放使用相同的session_id）',
  
  -- 播放进度信息
  `current_position` INT DEFAULT 0 COMMENT '当前播放位置（秒）',
  `duration` INT DEFAULT 0 COMMENT '视频总时长（秒）',
  `play_duration` INT DEFAULT 0 COMMENT '本次会话累计播放时长（秒）',
  `real_watch_duration` INT DEFAULT 0 COMMENT '真实观看时长（秒，排除暂停和重复观看）',
  
  -- 播放状态
  `status` VARCHAR(20) DEFAULT 'playing' COMMENT '播放状态: playing, paused, seeking, ended',
  `last_event` VARCHAR(50) DEFAULT NULL COMMENT '最后一次事件: play, pause, seek, ended, progress',
  `last_event_time` TIMESTAMP NULL DEFAULT NULL COMMENT '最后一次事件时间',
  
  -- 播放行为统计
  `seek_count` INT DEFAULT 0 COMMENT '拖动次数',
  `pause_count` INT DEFAULT 0 COMMENT '暂停次数',
  `pause_duration` INT DEFAULT 0 COMMENT '累计暂停时长（秒）',
  `replay_count` INT DEFAULT 0 COMMENT '重播次数',
  
  -- 播放范围（JSON格式，记录观看过的时间段）
  `watched_ranges` TEXT DEFAULT NULL COMMENT '已观看的时间段（JSON数组）: [[start1,end1],[start2,end2],...]',
  
  -- 完成度
  `completion_rate` DECIMAL(5,2) DEFAULT 0.00 COMMENT '完成度（百分比）',
  `is_completed` TINYINT(1) DEFAULT 0 COMMENT '是否观看完成（观看90%以上视为完成）',
  
  -- 客户端信息
  `ip_address` VARCHAR(45) DEFAULT NULL COMMENT '客户端IP地址',
  `user_agent` VARCHAR(500) DEFAULT NULL COMMENT '用户代理',
  `device_type` VARCHAR(50) DEFAULT NULL COMMENT '设备类型: PC, Mobile, Tablet',
  
  -- 时间信息
  `start_time` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '开始播放时间',
  `end_time` TIMESTAMP NULL DEFAULT NULL COMMENT '结束播放时间',
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_uuid` (`uuid`),
  KEY `idx_resource_id` (`resource_id`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_session_id` (`session_id`),
  KEY `idx_resource_user` (`resource_id`, `user_id`),
  KEY `idx_start_time` (`start_time`),
  KEY `idx_status` (`status`),
  CONSTRAINT `fk_vpp_resource` FOREIGN KEY (`resource_id`) REFERENCES `pbl_resources` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='视频播放进度追踪表';

-- ----------------------------
-- 2. 创建视频播放事件表（可选，用于更详细的日志）
-- ----------------------------
CREATE TABLE IF NOT EXISTS `pbl_video_play_events` (
  `id` BIGINT(20) NOT NULL AUTO_INCREMENT COMMENT '事件ID',
  `session_id` VARCHAR(64) NOT NULL COMMENT '播放会话ID',
  `resource_id` BIGINT(20) NOT NULL COMMENT '视频资源ID',
  `user_id` INT(11) NOT NULL COMMENT '用户ID',
  `event_type` VARCHAR(50) NOT NULL COMMENT '事件类型: play, pause, seek, ended, progress, error',
  `event_data` TEXT DEFAULT NULL COMMENT '事件数据（JSON格式）',
  `position` INT DEFAULT 0 COMMENT '事件发生时的播放位置（秒）',
  `timestamp` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '事件时间',
  
  PRIMARY KEY (`id`),
  KEY `idx_session_id` (`session_id`),
  KEY `idx_resource_id` (`resource_id`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_event_type` (`event_type`),
  KEY `idx_timestamp` (`timestamp`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='视频播放事件表（详细日志）';

-- ----------------------------
-- 3. 创建索引以优化查询性能
-- ----------------------------
-- 为 pbl_video_watch_records 表添加 session_id 字段（如果需要关联）
SET @column_exists = (
    SELECT COUNT(*) 
    FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'pbl_video_watch_records'
    AND COLUMN_NAME = 'session_id'
);

SET @sql = IF(
    @column_exists = 0,
    'ALTER TABLE `pbl_video_watch_records` 
     ADD COLUMN `session_id` VARCHAR(64) DEFAULT NULL COMMENT ''播放会话ID'' AFTER `user_id`,
     ADD KEY `idx_session_id` (`session_id`)',
    'SELECT ''Column session_id already exists'' AS message'
);

PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;


-- ----------------------------
-- 4. 显示统计信息
-- ----------------------------
SELECT '视频播放进度追踪功能添加完成' AS status;

SELECT 
    COUNT(*) AS total_videos,
    COUNT(DISTINCT uuid) AS unique_videos
FROM `pbl_resources`
WHERE `type` = 'video';

-- ----------------------------
-- 5. 使用示例说明
-- ----------------------------
/*
=== 使用示例 ===

1. 创建新的播放会话：
   INSERT INTO `pbl_video_play_progress`
   (`uuid`, `resource_id`, `user_id`, `session_id`, `duration`, `ip_address`, `user_agent`)
   VALUES
   (UUID(), 资源ID, 用户ID, '会话ID', 视频时长, IP地址, UA);

2. 更新播放进度：
   UPDATE `pbl_video_play_progress`
   SET `current_position` = 当前位置,
       `play_duration` = 播放时长,
       `status` = '状态',
       `last_event` = '事件',
       `last_event_time` = NOW(),
       `completion_rate` = (当前位置 / duration) * 100
   WHERE `session_id` = '会话ID';

3. 记录拖动事件：
   UPDATE `pbl_video_play_progress`
   SET `seek_count` = `seek_count` + 1,
       `current_position` = 新位置,
       `last_event` = 'seek',
       `last_event_time` = NOW()
   WHERE `session_id` = '会话ID';

4. 查询学生的观看统计：
   SELECT 
       vpp.resource_id,
       COUNT(DISTINCT vpp.session_id) AS session_count,
       SUM(vpp.play_duration) AS total_play_duration,
       SUM(vpp.real_watch_duration) AS total_real_watch_duration,
       AVG(vpp.completion_rate) AS avg_completion_rate,
       MAX(vpp.completion_rate) AS max_completion_rate
   FROM `pbl_video_play_progress` vpp
   WHERE vpp.user_id = 学生ID AND vpp.resource_id = 资源ID
   GROUP BY vpp.resource_id;

5. 查询所有活跃的播放会话：
   SELECT 
       vpp.session_id,
       r.title AS resource_title,
       u.username,
       vpp.current_position,
       vpp.completion_rate,
       vpp.status,
       vpp.last_event_time
   FROM `pbl_video_play_progress` vpp
   JOIN `pbl_resources` r ON vpp.resource_id = r.id
   JOIN `aiot_core_users` u ON vpp.user_id = u.id
   WHERE vpp.end_time IS NULL
     AND vpp.status != 'ended'
     AND TIMESTAMPDIFF(MINUTE, vpp.last_event_time, NOW()) < 30
   ORDER BY vpp.last_event_time DESC;

6. 查询某个学生的最后播放位置（断点续看）：
   SELECT current_position, completion_rate
   FROM `pbl_video_play_progress`
   WHERE resource_id = 资源ID AND user_id = 用户ID
   ORDER BY updated_at DESC
   LIMIT 1;

7. 查询观看完成率高的学生TOP 10：
   SELECT 
       u.real_name,
       AVG(vpp.completion_rate) AS avg_completion,
       COUNT(DISTINCT vpp.session_id) AS total_sessions
   FROM `pbl_video_play_progress` vpp
   JOIN `aiot_core_users` u ON vpp.user_id = u.id
   WHERE vpp.resource_id = 资源ID
   GROUP BY vpp.user_id, u.real_name
   HAVING AVG(vpp.completion_rate) > 80
   ORDER BY avg_completion DESC
   LIMIT 10;

8. 统计某个视频的平均观看情况：
   SELECT 
       r.title AS resource_title,
       COUNT(DISTINCT vpp.user_id) AS total_students,
       AVG(vpp.completion_rate) AS avg_completion,
       AVG(vpp.real_watch_duration) AS avg_watch_duration,
       AVG(vpp.seek_count) AS avg_seek_count
   FROM `pbl_video_play_progress` vpp
   JOIN `pbl_resources` r ON vpp.resource_id = r.id
   WHERE vpp.resource_id = 资源ID
   GROUP BY r.id, r.title;

9. 记录播放事件（详细日志）：
   INSERT INTO `pbl_video_play_events`
   (`session_id`, `resource_id`, `user_id`, `event_type`, `event_data`, `position`)
   VALUES
   ('会话ID', 资源ID, 用户ID, 'seek', '{"from":120,"to":300}', 300);

10. 查询学习最努力的学生（真实观看时长最长）：
    SELECT 
        u.real_name,
        SUM(vpp.real_watch_duration) / 3600 AS total_hours,
        COUNT(DISTINCT vpp.resource_id) AS videos_watched,
        AVG(vpp.completion_rate) AS avg_completion
    FROM `pbl_video_play_progress` vpp
    JOIN `aiot_core_users` u ON vpp.user_id = u.id
    GROUP BY vpp.user_id, u.real_name
    ORDER BY total_hours DESC
    LIMIT 20;
*/

-- 完成
COMMIT;
