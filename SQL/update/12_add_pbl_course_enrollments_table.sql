-- 创建 PBL 课程选课表
-- 用于记录学生选课信息和学习进度

CREATE TABLE IF NOT EXISTS `pbl_course_enrollments` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `course_id` INT NOT NULL COMMENT '课程ID',
  `user_id` INT NOT NULL COMMENT '学生用户ID',
  `enrollment_status` ENUM('enrolled', 'dropped', 'completed') NOT NULL DEFAULT 'enrolled' COMMENT '选课状态: enrolled-已选课, dropped-已退课, completed-已完成',
  `enrolled_at` TIMESTAMP NULL COMMENT '选课时间',
  `dropped_at` TIMESTAMP NULL COMMENT '退课时间',
  `completed_at` TIMESTAMP NULL COMMENT '完成时间',
  `progress` INT NOT NULL DEFAULT 0 COMMENT '学习进度(0-100)',
  `final_score` INT NULL COMMENT '最终成绩',
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  INDEX `idx_course_id` (`course_id`),
  INDEX `idx_user_id` (`user_id`),
  INDEX `idx_enrollment_status` (`enrollment_status`),
  CONSTRAINT `fk_pbl_enrollments_course` FOREIGN KEY (`course_id`) REFERENCES `pbl_courses` (`id`) ON DELETE CASCADE,
  CONSTRAINT `uk_course_user` UNIQUE (`course_id`, `user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='PBL课程选课表';

