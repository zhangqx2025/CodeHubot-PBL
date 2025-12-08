-- ==========================================
-- PBL 系统测试数据脚本
-- ==========================================
-- 说明：
--   本脚本用于向 PBL 系统添加完整的测试数据，覆盖六大管理模块：
--   1. 课程内容管理（课程、单元、资源、任务、数据集）
--   2. 教学组织管理（学校、班级、分组、选课）
--   3. 项目实践管理（项目、任务进度、成果提交）
--   4. 评价体系管理（多维评价、成长档案）
--   5. 伦理教育管理（案例库、思辨活动）
--   6. 家校社协同（专家、社会实践）
--
-- 使用方式：
--   mysql -u username -p database_name < 11_insert_test_data.sql
--
-- 版本：v1.0
-- 日期：2024-12-08
-- ==========================================

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- ==========================================
-- 0. 创建测试用户（如果不存在）
-- ==========================================

-- 0.1 创建测试学生用户 (user_id 2-30)
INSERT IGNORE INTO `aiot_core_users` (`id`, `username`, `password_hash`, `email`, `real_name`, `role`, `is_active`, `school_id`, `student_number`, `created_at`) VALUES
(2, 'student_zhangsan', '$2b$12$dummy_hash_value_for_testing_purposes_only', 'zhangsan@student.example.com', '张三', 'student', 1, 1, 'S2024001', NOW()),
(3, 'student_lisi', '$2b$12$dummy_hash_value_for_testing_purposes_only', 'lisi@student.example.com', '李四', 'student', 1, 1, 'S2024002', NOW()),
(4, 'student_wangwu', '$2b$12$dummy_hash_value_for_testing_purposes_only', 'wangwu@student.example.com', '王五', 'student', 1, 1, 'S2024003', NOW()),
(5, 'student_zhaoliu', '$2b$12$dummy_hash_value_for_testing_purposes_only', 'zhaoliu@student.example.com', '赵六', 'student', 1, 1, 'S2024004', NOW()),
(6, 'student_sunqi', '$2b$12$dummy_hash_value_for_testing_purposes_only', 'sunqi@student.example.com', '孙七', 'student', 1, 1, 'S2024005', NOW()),
(7, 'student_zhouba', '$2b$12$dummy_hash_value_for_testing_purposes_only', 'zhouba@student.example.com', '周八', 'student', 1, 1, 'S2024006', NOW()),
(8, 'student_wujiu', '$2b$12$dummy_hash_value_for_testing_purposes_only', 'wujiu@student.example.com', '吴九', 'student', 1, 1, 'S2024007', NOW()),
(9, 'student_zhengshi', '$2b$12$dummy_hash_value_for_testing_purposes_only', 'zhengshi@student.example.com', '郑十', 'student', 1, 1, 'S2024008', NOW()),
(10, 'student_chenyi', '$2b$12$dummy_hash_value_for_testing_purposes_only', 'chenyi@student.example.com', '陈一', 'student', 1, 1, 'S2024009', NOW()),
(11, 'student_huanger', '$2b$12$dummy_hash_value_for_testing_purposes_only', 'huanger@student.example.com', '黄二', 'student', 1, 1, 'S2024010', NOW()),
(12, 'student_xusan', '$2b$12$dummy_hash_value_for_testing_purposes_only', 'xusan@student.example.com', '许三', 'student', 1, 1, 'S2024011', NOW()),
(13, 'student_linsi', '$2b$12$dummy_hash_value_for_testing_purposes_only', 'linsi@student.example.com', '林四', 'student', 1, 1, 'S2024012', NOW()),
(14, 'student_huwu', '$2b$12$dummy_hash_value_for_testing_purposes_only', 'huwu@student.example.com', '胡五', 'student', 1, 1, 'S2024013', NOW()),
(15, 'student_guoliu', '$2b$12$dummy_hash_value_for_testing_purposes_only', 'guoliu@student.example.com', '郭六', 'student', 1, 1, 'S2024014', NOW()),
(16, 'student_heqi', '$2b$12$dummy_hash_value_for_testing_purposes_only', 'heqi@student.example.com', '何七', 'student', 1, 1, 'S2024015', NOW()),
(17, 'student_gaoba', '$2b$12$dummy_hash_value_for_testing_purposes_only', 'gaoba@student.example.com', '高八', 'student', 1, 1, 'S2024016', NOW()),
(18, 'student_luojiu', '$2b$12$dummy_hash_value_for_testing_purposes_only', 'luojiu@student.example.com', '罗九', 'student', 1, 1, 'S2024017', NOW()),
(19, 'student_liangshi', '$2b$12$dummy_hash_value_for_testing_purposes_only', 'liangshi@student.example.com', '梁十', 'student', 1, 1, 'S2024018', NOW()),
(20, 'student_songyi', '$2b$12$dummy_hash_value_for_testing_purposes_only', 'songyi@student.example.com', '宋一', 'student', 1, 1, 'S2024019', NOW()),
(21, 'student_tanger', '$2b$12$dummy_hash_value_for_testing_purposes_only', 'tanger@student.example.com', '唐二', 'student', 1, 1, 'S2024020', NOW()),
(22, 'student_fengsan', '$2b$12$dummy_hash_value_for_testing_purposes_only', 'fengsan@student.example.com', '冯三', 'student', 1, 1, 'S2024021', NOW()),
(23, 'student_hansi', '$2b$12$dummy_hash_value_for_testing_purposes_only', 'hansi@student.example.com', '韩四', 'student', 1, 1, 'S2024022', NOW()),
(24, 'student_caowu', '$2b$12$dummy_hash_value_for_testing_purposes_only', 'caowu@student.example.com', '曹五', 'student', 1, 1, 'S2024023', NOW()),
(25, 'student_zengliu', '$2b$12$dummy_hash_value_for_testing_purposes_only', 'zengliu@student.example.com', '曾六', 'student', 1, 1, 'S2024024', NOW()),
(26, 'student_pengqi', '$2b$12$dummy_hash_value_for_testing_purposes_only', 'pengqi@student.example.com', '彭七', 'student', 1, 1, 'S2024025', NOW()),
(27, 'student_xieba', '$2b$12$dummy_hash_value_for_testing_purposes_only', 'xieba@student.example.com', '谢八', 'student', 1, 1, 'S2024026', NOW()),
(28, 'student_panjiu', '$2b$12$dummy_hash_value_for_testing_purposes_only', 'panjiu@student.example.com', '潘九', 'student', 1, 1, 'S2024027', NOW()),
(29, 'student_yushi', '$2b$12$dummy_hash_value_for_testing_purposes_only', 'yushi@student.example.com', '于十', 'student', 1, 1, 'S2024028', NOW()),
(30, 'student_dongyi', '$2b$12$dummy_hash_value_for_testing_purposes_only', 'dongyi@student.example.com', '董一', 'student', 1, 1, 'S2024029', NOW());

-- 0.2 创建测试家长用户 (user_id 100-105)
-- 注意：家长角色在当前系统中使用 'individual' 角色，通过 pbl_parent_relations 表关联学生
INSERT IGNORE INTO `aiot_core_users` (`id`, `username`, `password_hash`, `email`, `real_name`, `role`, `is_active`, `created_at`) VALUES
(100, 'parent_zhang_father', '$2b$12$dummy_hash_value_for_testing_purposes_only', 'zhangfather@parent.example.com', '张三父亲', 'individual', 1, NOW()),
(101, 'parent_zhang_mother', '$2b$12$dummy_hash_value_for_testing_purposes_only', 'zhangmother@parent.example.com', '张三母亲', 'individual', 1, NOW()),
(102, 'parent_sun_mother', '$2b$12$dummy_hash_value_for_testing_purposes_only', 'sunmother@parent.example.com', '孙七母亲', 'individual', 1, NOW()),
(103, 'parent_he_father', '$2b$12$dummy_hash_value_for_testing_purposes_only', 'hefather@parent.example.com', '何七父亲', 'individual', 1, NOW()),
(104, 'parent_wang_guardian', '$2b$12$dummy_hash_value_for_testing_purposes_only', 'wangguardian@parent.example.com', '王五监护人', 'individual', 1, NOW()),
(105, 'parent_li_father', '$2b$12$dummy_hash_value_for_testing_purposes_only', 'lifather@parent.example.com', '李四父亲', 'individual', 1, NOW());

-- 0.3 创建专家用户（作为teacher角色或individual角色）
-- 注意：专家可以使用 teacher 角色，通过 pbl_external_experts 表管理专家信息
INSERT IGNORE INTO `aiot_core_users` (`id`, `username`, `password_hash`, `email`, `real_name`, `role`, `is_active`, `created_at`) VALUES
(20, 'expert_zhangwei', '$2b$12$dummy_hash_value_for_testing_purposes_only', 'zhangwei@tsinghua.edu.cn', '张伟', 'teacher', 1, NOW());

-- ==========================================
-- 1. 课程内容管理测试数据
-- ==========================================

-- 1.1 课程数据 (pbl_courses)
INSERT INTO `pbl_courses` (`uuid`, `title`, `description`, `cover_image`, `duration`, `difficulty`, `status`, `creator_id`, `school_id`) VALUES
(UUID(), 'AI智能垃圾分类系统', '通过机器学习技术实现智能垃圾分类，培养学生的环保意识和技术能力。学生将学习图像识别、数据采集、模型训练等核心技能。', '/images/courses/garbage-classification.jpg', '8周', 'intermediate', 'published', 1, 1),
(UUID(), '智慧校园AI助手开发', '开发一个基于自然语言处理的智能校园助手，帮助学生解答学习问题。学习对话系统、知识图谱等技术。', '/images/courses/campus-ai-assistant.jpg', '10周', 'advanced', 'published', 1, 1),
(UUID(), 'AI图像识别入门', '适合初学者的AI图像识别课程，通过趣味项目学习计算机视觉基础知识。', '/images/courses/image-recognition.jpg', '6周', 'beginner', 'published', 1, 1),
(UUID(), '智能家居控制系统', '设计并实现智能家居控制系统，学习物联网与人工智能的结合应用。', '/images/courses/smart-home.jpg', '12周', 'intermediate', 'published', 1, 1),
(UUID(), '情感识别AI应用', '基于面部表情和语音识别技术，开发情感识别应用，探索AI在心理健康领域的应用。', '/images/courses/emotion-recognition.jpg', '8周', 'intermediate', 'draft', 1, 1);

-- 获取课程ID用于后续插入
SET @course1_id = (SELECT id FROM pbl_courses WHERE title = 'AI智能垃圾分类系统' LIMIT 1);
SET @course2_id = (SELECT id FROM pbl_courses WHERE title = '智慧校园AI助手开发' LIMIT 1);
SET @course3_id = (SELECT id FROM pbl_courses WHERE title = 'AI图像识别入门' LIMIT 1);
SET @course4_id = (SELECT id FROM pbl_courses WHERE title = '智能家居控制系统' LIMIT 1);

-- 1.2 单元数据 (pbl_units)
INSERT INTO `pbl_units` (`uuid`, `course_id`, `title`, `description`, `order`, `status`, `learning_guide`) VALUES
(UUID(), @course1_id, '项目启动与需求分析', '了解垃圾分类的重要性，分析用户需求，制定项目计划。', 1, 'available', '{"objectives":["理解项目背景","掌握需求分析方法"],"duration":"1周","activities":["小组讨论","用户调研"]}'),
(UUID(), @course1_id, '数据采集与标注', '学习图像数据采集方法，进行垃圾图像数据标注。', 2, 'available', '{"objectives":["掌握数据采集技能","学习数据标注工具"],"duration":"2周","activities":["实地拍摄","数据清洗"]}'),
(UUID(), @course1_id, 'AI模型训练', '使用机器学习框架训练垃圾分类模型。', 3, 'locked', '{"objectives":["理解模型训练原理","掌握训练参数调优"],"duration":"2周","activities":["模型选择","参数调整"]}'),
(UUID(), @course1_id, '系统开发与部署', '开发用户界面，部署AI模型到实际应用中。', 4, 'locked', '{"objectives":["掌握系统集成","学习云端部署"],"duration":"2周","activities":["界面开发","性能测试"]}'),
(UUID(), @course1_id, '项目展示与反思', '展示项目成果，总结经验教训，讨论伦理问题。', 5, 'locked', '{"objectives":["提升表达能力","培养批判思维"],"duration":"1周","activities":["成果答辩","伦理讨论"]}'),

(UUID(), @course2_id, 'AI对话系统基础', '学习自然语言处理基础知识，了解对话系统架构。', 1, 'available', '{"objectives":["理解NLP基础","掌握对话流程"],"duration":"2周","activities":["理论学习","案例分析"]}'),
(UUID(), @course2_id, '知识库构建', '构建校园知识图谱，收集整理常见问答。', 2, 'available', '{"objectives":["学习知识表示","掌握知识抽取"],"duration":"2周","activities":["知识收集","图谱构建"]}'),
(UUID(), @course2_id, '对话模型训练', '训练基于深度学习的对话模型。', 3, 'locked', '{"objectives":["掌握模型训练","理解注意力机制"],"duration":"3周","activities":["数据准备","模型优化"]}'),
(UUID(), @course2_id, '系统集成与测试', '集成各个模块，进行系统测试和优化。', 4, 'locked', '{"objectives":["掌握系统集成","学习测试方法"],"duration":"2周","activities":["功能测试","用户体验优化"]}'),

(UUID(), @course3_id, 'AI与图像识别概述', '了解人工智能的发展历史，认识图像识别技术的应用。', 1, 'available', '{"objectives":["建立AI认知","激发学习兴趣"],"duration":"1周","activities":["观看视频","互动演示"]}'),
(UUID(), @course3_id, '图像数据的获取与处理', '学习如何获取和处理图像数据。', 2, 'available', '{"objectives":["掌握图像处理基础","学习数据增强"],"duration":"1周","activities":["实践操作","小组练习"]}'),
(UUID(), @course3_id, '简单模型搭建', '使用可视化工具搭建简单的图像识别模型。', 3, 'locked', '{"objectives":["体验模型训练","理解模型原理"],"duration":"2周","activities":["拖拽式建模","模型测试"]}');

-- 获取单元ID用于后续插入
SET @unit1_id = (SELECT id FROM pbl_units WHERE course_id = @course1_id AND `order` = 1 LIMIT 1);
SET @unit2_id = (SELECT id FROM pbl_units WHERE course_id = @course1_id AND `order` = 2 LIMIT 1);
SET @unit3_id = (SELECT id FROM pbl_units WHERE course_id = @course1_id AND `order` = 3 LIMIT 1);
SET @unit_course2_1 = (SELECT id FROM pbl_units WHERE course_id = @course2_id AND `order` = 1 LIMIT 1);
SET @unit_course3_1 = (SELECT id FROM pbl_units WHERE course_id = @course3_id AND `order` = 1 LIMIT 1);

-- 1.3 资源数据 (pbl_resources)
INSERT INTO `pbl_resources` (`uuid`, `unit_id`, `type`, `title`, `description`, `url`, `content`, `duration`, `order`, `video_id`, `video_cover_url`) VALUES
(UUID(), @unit1_id, 'video', '垃圾分类的重要性', '了解全球垃圾处理现状和垃圾分类的意义', 'https://video.example.com/garbage-intro', NULL, 15, 1, 'vid_garbage_intro_001', '/images/video-covers/garbage-intro.jpg'),
(UUID(), @unit1_id, 'document', '需求分析方法论', '学习如何进行用户需求调研和分析', NULL, '# 需求分析方法论\n\n## 1. 用户调研\n- 问卷调查\n- 用户访谈\n- 观察法\n\n## 2. 需求整理\n- 功能需求\n- 性能需求\n- 用户体验需求', NULL, 2, NULL, NULL),
(UUID(), @unit1_id, 'link', 'AI在环保领域的应用案例', '外部参考资料：AI技术在环保领域的成功案例', 'https://example.com/ai-environmental-cases', NULL, NULL, 3, NULL, NULL),

(UUID(), @unit2_id, 'video', '图像数据采集技巧', '学习如何拍摄高质量的训练图像', 'https://video.example.com/data-collection', NULL, 20, 1, 'vid_data_collection_001', '/images/video-covers/data-collection.jpg'),
(UUID(), @unit2_id, 'document', '数据标注工具使用指南', 'Labelme工具的详细使用教程', NULL, '# Labelme 数据标注工具\n\n## 安装\n```bash\npip install labelme\n```\n\n## 基本使用\n1. 打开图像\n2. 绘制标注框\n3. 添加类别标签\n4. 导出JSON格式', NULL, 2, NULL, NULL),
(UUID(), @unit2_id, 'video', '数据质量检查方法', '如何保证标注数据的质量', 'https://video.example.com/data-quality', NULL, 12, 3, 'vid_data_quality_001', '/images/video-covers/data-quality.jpg'),

(UUID(), @unit3_id, 'video', '机器学习模型基础', '了解神经网络和深度学习基础概念', 'https://video.example.com/ml-basics', NULL, 25, 1, 'vid_ml_basics_001', '/images/video-covers/ml-basics.jpg'),
(UUID(), @unit3_id, 'document', 'TensorFlow入门教程', '使用TensorFlow进行图像分类', NULL, '# TensorFlow 图像分类\n\n## 环境准备\n```python\nimport tensorflow as tf\nfrom tensorflow import keras\n```\n\n## 模型搭建\n```python\nmodel = keras.Sequential([\n    keras.layers.Conv2D(32, 3, activation="relu"),\n    keras.layers.MaxPooling2D(),\n    keras.layers.Flatten(),\n    keras.layers.Dense(128, activation="relu"),\n    keras.layers.Dense(4, activation="softmax")\n])\n```', NULL, 2, NULL, NULL),

(UUID(), @unit_course2_1, 'video', 'NLP技术概述', '自然语言处理技术在AI对话系统中的应用', 'https://video.example.com/nlp-intro', NULL, 18, 1, 'vid_nlp_intro_001', '/images/video-covers/nlp-intro.jpg'),
(UUID(), @unit_course2_1, 'document', '对话系统架构设计', '学习对话系统的整体架构和核心组件', NULL, '# 对话系统架构\n\n## 核心组件\n1. 意图识别\n2. 实体抽取\n3. 对话管理\n4. 自然语言生成\n\n## 技术选型\n- 框架：Rasa / DialoGPT\n- 模型：BERT / GPT', NULL, 2, NULL, NULL);

-- 1.4 任务数据 (pbl_tasks)
INSERT INTO `pbl_tasks` (`uuid`, `unit_id`, `title`, `description`, `type`, `difficulty`, `estimated_time`, `requirements`, `prerequisites`) VALUES
(UUID(), @unit1_id, '用户需求调研报告', '通过问卷或访谈形式，调研至少20名用户对垃圾分类的认知和需求，撰写调研报告。', 'analysis', 'easy', '3天', '["完成至少20份有效问卷或访谈","分析用户痛点和需求","撰写完整的调研报告(至少1500字)","包含数据图表分析"]', '[]'),
(UUID(), @unit1_id, '项目计划书', '制定详细的项目实施计划，包括任务分工、时间安排、技术选型等。', 'design', 'medium', '2天', '["明确项目目标和范围","制定详细的时间表","分配小组成员任务","列出所需资源和工具"]', '[]'),

(UUID(), @unit2_id, '垃圾图像数据集构建', '拍摄或收集至少200张垃圾图像，并完成分类标注。', 'coding', 'medium', '5天', '["收集4类垃圾各50张图像","使用Labelme完成标注","数据按7:2:1划分训练集、验证集和测试集","提交标注后的数据集"]', '[]'),
(UUID(), @unit2_id, '数据质量评估报告', '对构建的数据集进行质量评估，分析数据分布和潜在问题。', 'analysis', 'easy', '2天', '["分析各类别数据分布","检查标注准确性","识别数据质量问题","提出改进建议"]', '[]'),

(UUID(), @unit3_id, '垃圾分类模型训练', '使用TensorFlow或PyTorch训练垃圾分类模型，准确率达到85%以上。', 'coding', 'hard', '7天', '["选择合适的模型架构","完成模型训练","测试集准确率≥85%","保存训练好的模型文件","记录训练过程和参数"]', '[]'),
(UUID(), @unit3_id, '模型性能优化报告', '分析模型性能，尝试不同的优化方法，撰写优化报告。', 'analysis', 'hard', '3天', '["分析模型的混淆矩阵","尝试至少3种优化方法","对比优化前后的性能","撰写详细的优化报告"]', '[]'),

(UUID(), @unit_course2_1, 'NLP基础知识测试', '完成NLP基础知识在线测试，检验学习成果。', 'analysis', 'easy', '1小时', '["完成20道选择题","得分达到80分以上","总结错题知识点"]', '[]'),
(UUID(), @unit_course2_1, '对话系统需求分析', '分析校园AI助手的功能需求，设计对话流程。', 'design', 'medium', '3天', '["列出至少10个核心功能","设计3个典型对话场景","绘制对话流程图","考虑异常情况处理"]', '[]');

-- 1.5 数据集数据 (pbl_datasets)
INSERT INTO `pbl_datasets` (`uuid`, `name`, `description`, `data_type`, `category`, `file_url`, `file_size`, `sample_count`, `class_count`, `classes`, `is_labeled`, `label_format`, `split_ratio`, `grade_level`, `applicable_projects`, `source`, `license`, `preview_images`, `download_count`, `creator_id`, `school_id`, `is_public`, `quality_score`) VALUES
(UUID(), '校园垃圾分类数据集', '包含可回收物、有害垃圾、厨余垃圾、其他垃圾四类共1000张标注图像', 'image', '垃圾分类', '/datasets/garbage-classification-v1.zip', 156789012, 1000, 4, '["可回收物","有害垃圾","厨余垃圾","其他垃圾"]', 1, 'YOLO', '{"train":0.7,"val":0.2,"test":0.1}', '5-6年级', '["垃圾分类","环保教育"]', '某某中学AI实验室', 'CC BY-NC-SA 4.0', '["/previews/garbage1.jpg","/previews/garbage2.jpg","/previews/garbage3.jpg"]', 45, 1, 1, 1, 4.50),

(UUID(), '常见植物识别数据集', '包含50种常见植物的图像数据，每种植物50-100张图片', 'image', '植物识别', '/datasets/plant-recognition-v1.zip', 234567890, 3500, 50, '["玫瑰","月季","茉莉","向日葵","牡丹","..."]', 1, 'COCO', '{"train":0.7,"val":0.15,"test":0.15}', '3-4年级', '["植物识别","生态教育"]', '开源社区', 'CC BY 4.0', '["/previews/plant1.jpg","/previews/plant2.jpg"]', 128, 1, NULL, 1, 4.30),

(UUID(), '情绪识别人脸数据集', '包含7种情绪的面部表情图像数据', 'image', '情绪识别', '/datasets/emotion-recognition-v1.zip', 98765432, 5000, 7, '["开心","悲伤","愤怒","惊讶","恐惧","厌恶","中性"]', 1, 'CSV', '{"train":0.7,"val":0.15,"test":0.15}', '7-9年级', '["情绪识别","心理健康"]', 'FER2013数据集改编', 'MIT', '["/previews/emotion1.jpg","/previews/emotion2.jpg"]', 67, 1, NULL, 1, 4.70),

(UUID(), '校园问答语料库', '包含1000+条校园常见问答对，涵盖教学、生活、活动等多个方面', 'text', '问答系统', '/datasets/campus-qa-corpus-v1.json', 2345678, 1200, NULL, NULL, 1, 'JSON', '{"train":0.8,"val":0.1,"test":0.1}', '7-9年级', '["智能问答","校园助手"]', '某某中学', 'CC BY-NC 4.0', NULL, 34, 1, 1, 1, 4.20),

(UUID(), '智能家居语音指令数据集', '包含智能家居场景下的语音指令和文本转录', 'audio', '语音识别', '/datasets/smart-home-voice-v1.zip', 456789012, 2000, 20, '["打开灯","关闭窗帘","调节温度","播放音乐","..."]', 1, 'JSON', '{"train":0.7,"val":0.2,"test":0.1}', '10-12年级', '["智能家居","语音控制"]', '开源社区', 'Apache 2.0', NULL, 23, 1, NULL, 1, 4.10);

-- ==========================================
-- 2. 教学组织管理测试数据
-- ==========================================

-- 2.1 班级数据 (pbl_classes) - 假设school_id=1存在
INSERT INTO `pbl_classes` (`uuid`, `school_id`, `name`, `grade`, `academic_year`, `class_teacher_id`, `max_students`, `is_active`) VALUES
(UUID(), 1, '六年级(1)班', '六年级', '2024-2025', 1, 40, 1),
(UUID(), 1, '六年级(2)班', '六年级', '2024-2025', 1, 40, 1),
(UUID(), 1, '八年级(3)班', '八年级', '2024-2025', 1, 45, 1),
(UUID(), 1, '高一(5)班', '高一', '2024-2025', 1, 50, 1),
(UUID(), 1, '高二(2)班', '高二', '2024-2025', 1, 48, 1);

-- 获取班级ID
SET @class1_id = (SELECT id FROM pbl_classes WHERE name = '六年级(1)班' LIMIT 1);
SET @class2_id = (SELECT id FROM pbl_classes WHERE name = '八年级(3)班' LIMIT 1);
SET @class3_id = (SELECT id FROM pbl_classes WHERE name = '高一(5)班' LIMIT 1);

-- 2.2 学习小组数据 (pbl_groups)
INSERT INTO `pbl_groups` (`uuid`, `class_id`, `course_id`, `name`, `description`, `leader_id`, `max_members`, `is_active`) VALUES
(UUID(), @class1_id, @course1_id, '智能分类先锋队', '专注于垃圾分类AI项目开发', 2, 6, 1),
(UUID(), @class1_id, @course1_id, '环保科技小组', '致力于环保技术创新', 3, 6, 1),
(UUID(), @class2_id, @course2_id, '校园AI助手开发组', '开发智能校园问答系统', 4, 5, 1),
(UUID(), @class3_id, @course4_id, '智慧家居创新组', '探索智能家居应用', 5, 6, 1);

-- 获取小组ID
SET @group1_id = (SELECT id FROM pbl_groups WHERE name = '智能分类先锋队' LIMIT 1);
SET @group2_id = (SELECT id FROM pbl_groups WHERE name = '环保科技小组' LIMIT 1);
SET @group3_id = (SELECT id FROM pbl_groups WHERE name = '校园AI助手开发组' LIMIT 1);

-- 2.3 小组成员数据 (pbl_group_members) - 假设user_id 2-10存在
INSERT INTO `pbl_group_members` (`group_id`, `user_id`, `role`, `is_active`) VALUES
(@group1_id, 2, 'leader', 1),
(@group1_id, 6, 'member', 1),
(@group1_id, 7, 'member', 1),
(@group1_id, 8, 'member', 1),
(@group1_id, 9, 'deputy_leader', 1),

(@group2_id, 3, 'leader', 1),
(@group2_id, 10, 'member', 1),
(@group2_id, 11, 'member', 1),
(@group2_id, 12, 'member', 1),

(@group3_id, 4, 'leader', 1),
(@group3_id, 13, 'member', 1),
(@group3_id, 14, 'deputy_leader', 1),
(@group3_id, 15, 'member', 1);

-- 2.4 选课记录数据 (pbl_course_enrollments)
INSERT INTO `pbl_course_enrollments` (`course_id`, `user_id`, `enrollment_status`, `progress`, `final_score`) VALUES
(@course1_id, 2, 'enrolled', 35, NULL),
(@course1_id, 3, 'enrolled', 28, NULL),
(@course1_id, 6, 'enrolled', 40, NULL),
(@course1_id, 7, 'enrolled', 32, NULL),
(@course1_id, 8, 'enrolled', 38, NULL),
(@course1_id, 9, 'enrolled', 42, NULL),
(@course1_id, 10, 'enrolled', 25, NULL),

(@course2_id, 4, 'enrolled', 20, NULL),
(@course2_id, 13, 'enrolled', 22, NULL),
(@course2_id, 14, 'enrolled', 18, NULL),
(@course2_id, 15, 'enrolled', 25, NULL),

(@course3_id, 16, 'completed', 100, 88),
(@course3_id, 17, 'completed', 100, 92),
(@course3_id, 18, 'enrolled', 75, NULL),

(@course4_id, 5, 'enrolled', 15, NULL),
(@course4_id, 19, 'enrolled', 12, NULL);

-- ==========================================
-- 3. 项目实践管理测试数据
-- ==========================================

-- 3.1 项目数据 (pbl_projects)
INSERT INTO `pbl_projects` (`uuid`, `group_id`, `course_id`, `title`, `description`, `status`, `progress`, `repo_url`) VALUES
(UUID(), @group1_id, @course1_id, '智能垃圾分类APP', '基于图像识别的智能垃圾分类移动应用，帮助用户快速识别垃圾类型并给出分类建议。', 'in-progress', 35, 'https://github.com/school/garbage-classifier'),
(UUID(), @group2_id, @course1_id, '校园垃圾分类智能箱', '带有AI识别功能的智能垃圾箱，自动识别投放垃圾并正确分类。', 'in-progress', 28, 'https://github.com/school/smart-bin'),
(UUID(), @group3_id, @course2_id, '小智校园助手', '基于NLP的智能问答系统，帮助学生解答学习和生活问题。', 'in-progress', 20, 'https://github.com/school/campus-assistant'),
(UUID(), NULL, @course3_id, '植物识别小助手', '帮助识别校园常见植物的AI应用', 'completed', 100, 'https://github.com/school/plant-recognizer');

-- 获取项目ID
SET @project1_id = (SELECT id FROM pbl_projects WHERE title = '智能垃圾分类APP' LIMIT 1);
SET @project2_id = (SELECT id FROM pbl_projects WHERE title = '校园垃圾分类智能箱' LIMIT 1);
SET @project3_id = (SELECT id FROM pbl_projects WHERE title = '小智校园助手' LIMIT 1);
SET @project4_id = (SELECT id FROM pbl_projects WHERE title = '植物识别小助手' LIMIT 1);

-- 获取任务ID
SET @task1_id = (SELECT id FROM pbl_tasks WHERE title = '用户需求调研报告' LIMIT 1);
SET @task2_id = (SELECT id FROM pbl_tasks WHERE title = '项目计划书' LIMIT 1);
SET @task3_id = (SELECT id FROM pbl_tasks WHERE title = '垃圾图像数据集构建' LIMIT 1);
SET @task4_id = (SELECT id FROM pbl_tasks WHERE title = '垃圾分类模型训练' LIMIT 1);

-- 3.2 任务进度数据 (pbl_task_progress)
INSERT INTO `pbl_task_progress` (`task_id`, `user_id`, `status`, `progress`, `submission`, `score`, `feedback`, `graded_by`, `graded_at`) VALUES
(@task1_id, 2, 'completed', 100, '{"report_url":"/submissions/user2_research_report.pdf","summary":"完成了30份问卷调查和5次深度访谈","key_findings":["用户对垃圾分类认知度较低","希望有便捷的识别工具","关注环保教育"]}', 92, '调研工作扎实，数据分析深入，报告结构清晰。建议在用户画像部分增加更多细节。', 1, NOW() - INTERVAL 5 DAY),
(@task1_id, 3, 'completed', 100, '{"report_url":"/submissions/user3_research_report.pdf","summary":"完成了25份问卷和3次访谈"}', 85, '调研数据充分，但分析深度可以再加强。', 1, NOW() - INTERVAL 5 DAY),
(@task1_id, 6, 'review', 100, '{"report_url":"/submissions/user6_research_report.pdf","summary":"完成了20份问卷"}', NULL, NULL, NULL, NULL),

(@task2_id, 2, 'completed', 100, '{"plan_url":"/submissions/user2_project_plan.pdf","milestones":["需求分析","数据采集","模型训练","应用开发","测试部署"]}', 88, '计划详细，时间安排合理，但风险评估部分需要补充。', 1, NOW() - INTERVAL 3 DAY),
(@task2_id, 9, 'in-progress', 70, '{"draft_url":"/submissions/user9_plan_draft.pdf"}', NULL, NULL, NULL, NULL),

(@task3_id, 6, 'completed', 100, '{"dataset_url":"/datasets/user6_garbage_dataset.zip","sample_count":250,"classes":4}', 95, '数据集质量优秀，标注准确，超出基本要求。', 1, NOW() - INTERVAL 2 DAY),
(@task3_id, 7, 'in-progress', 80, '{"current_count":180,"target":200}', NULL, NULL, NULL, NULL),
(@task3_id, 8, 'in-progress', 75, '{"current_count":160,"target":200}', NULL, NULL, NULL, NULL),

(@task4_id, 2, 'in-progress', 60, '{"model_file":"/models/user2_model_v1.h5","accuracy":0.82,"training_log":"/logs/training.log"}', NULL, NULL, NULL, NULL);

-- 3.3 项目成果数据 (pbl_project_outputs)
INSERT INTO `pbl_project_outputs` (`uuid`, `project_id`, `task_id`, `user_id`, `group_id`, `output_type`, `title`, `description`, `file_url`, `file_size`, `file_type`, `repo_url`, `demo_url`, `thumbnail`, `meta_data`, `is_public`, `view_count`, `like_count`) VALUES
(UUID(), @project1_id, @task1_id, 2, @group1_id, 'report', '垃圾分类用户需求调研报告', '通过问卷和访谈深入了解用户对垃圾分类的认知和需求', '/outputs/garbage-app-research-report.pdf', 2345678, 'application/pdf', NULL, NULL, '/thumbnails/report1.jpg', '{"pages":15,"charts":8,"interviewees":5}', 1, 45, 12),

(UUID(), @project1_id, @task3_id, 6, @group1_id, 'dataset', '垃圾分类训练数据集v1.0', '包含250张高质量标注图像的垃圾分类数据集', '/outputs/garbage-dataset-v1.zip', 45678901, 'application/zip', NULL, NULL, '/thumbnails/dataset1.jpg', '{"format":"YOLO","classes":4,"train_samples":175,"val_samples":50,"test_samples":25}', 1, 67, 23),

(UUID(), @project1_id, NULL, 2, @group1_id, 'code', '垃圾分类模型代码', 'TensorFlow实现的垃圾分类CNN模型', NULL, NULL, NULL, 'https://github.com/school/garbage-classifier', 'https://demo.school.com/garbage-app', '/thumbnails/code1.jpg', '{"framework":"TensorFlow 2.10","model":"ResNet50","accuracy":0.87}', 1, 89, 34),

(UUID(), @project1_id, NULL, 2, @group1_id, 'presentation', '项目中期答辩PPT', '智能垃圾分类APP项目中期进展汇报', '/outputs/midterm-presentation.pptx', 8901234, 'application/vnd.ms-powerpoint', NULL, NULL, '/thumbnails/ppt1.jpg', '{"slides":25,"duration":"15分钟"}', 0, 12, 5),

(UUID(), @project2_id, NULL, 3, @group2_id, 'design', '智能垃圾箱外观设计方案', '包含3D建模和渲染图的设计方案', '/outputs/smart-bin-design.pdf', 12345678, 'application/pdf', NULL, NULL, '/thumbnails/design1.jpg', '{"software":"Fusion360","formats":["STL","OBJ"],"views":6}', 1, 34, 8),

(UUID(), @project3_id, NULL, 4, @group3_id, 'report', 'NLP技术调研报告', '对话系统中NLP技术的调研和选型报告', '/outputs/nlp-research.pdf', 3456789, 'application/pdf', NULL, NULL, '/thumbnails/report2.jpg', '{"references":20,"comparison_table":3}', 0, 23, 6),

(UUID(), @project4_id, NULL, 16, NULL, 'model', '植物识别训练模型', '基于MobileNet的轻量级植物识别模型', '/outputs/plant-model.tflite', 5678901, 'application/octet-stream', 'https://github.com/school/plant-recognizer', 'https://demo.school.com/plant-app', '/thumbnails/model1.jpg', '{"framework":"TensorFlow Lite","size":"5.4MB","classes":50,"accuracy":0.91}', 1, 156, 45);

-- ==========================================
-- 4. 评价体系管理测试数据
-- ==========================================

-- 4.1 评价记录 (pbl_assessments)
INSERT INTO `pbl_assessments` (`uuid`, `assessor_id`, `assessor_role`, `target_type`, `target_id`, `student_id`, `group_id`, `assessment_type`, `dimensions`, `total_score`, `max_score`, `comments`, `strengths`, `improvements`, `tags`, `is_public`) VALUES
-- 教师对任务的评价
(UUID(), 1, 'teacher', 'task', @task1_id, 2, @group1_id, 'formative', '[{"dimension":"调研方法","score":90,"weight":0.3,"comment":"问卷设计合理，访谈深入"},{"dimension":"数据分析","score":92,"weight":0.3,"comment":"数据整理清晰，分析有深度"},{"dimension":"报告撰写","score":93,"weight":0.25,"comment":"逻辑清晰，表达流畅"},{"dimension":"团队协作","score":90,"weight":0.15,"comment":"分工明确，配合良好"}]', 91.45, 100.00, '优秀的调研工作，展现了良好的分析能力和团队协作精神。', '问卷设计科学，数据收集充分，报告结构完整', '建议在用户画像部分增加更多可视化图表，使结论更直观', '["优秀","数据分析强","团队协作好"]', 1),

(UUID(), 1, 'teacher', 'task', @task3_id, 6, @group1_id, 'formative', '[{"dimension":"数据质量","score":95,"weight":0.4,"comment":"图像质量优秀，标注准确"},{"dimension":"数量完成度","score":100,"weight":0.3,"comment":"超出要求，达到250张"},{"dimension":"数据多样性","score":92,"weight":0.2,"comment":"覆盖多种场景"},{"dimension":"工作态度","score":93,"weight":0.1,"comment":"认真负责"}]', 95.40, 100.00, '数据集构建工作非常出色，为后续模型训练打下了坚实基础。', '数据质量高，标注准确，超额完成任务', '可以考虑增加一些极端光照条件下的样本', '["优秀","超额完成","质量高"]', 1),

-- 学生互评
(UUID(), 7, 'student', 'student', 2, 2, @group1_id, 'formative', '[{"dimension":"技术能力","score":85,"weight":0.3,"comment":"编程能力强"},{"dimension":"问题解决","score":88,"weight":0.3,"comment":"善于分析问题"},{"dimension":"沟通协作","score":90,"weight":0.2,"comment":"沟通顺畅"},{"dimension":"责任心","score":92,"weight":0.2,"comment":"认真负责"}]', 88.10, 100.00, '组长非常负责任，技术能力强，带领我们完成了很多任务。', '技术扎实，领导能力强，乐于助人', '有时候太追求完美，可以适当放松一些', '["技术强","负责任","好队友"]', 0),

(UUID(), 2, 'student', 'student', 6, 6, @group1_id, 'formative', '[{"dimension":"技术能力","score":90,"weight":0.3,"comment":"数据处理很专业"},{"dimension":"创新思维","score":85,"weight":0.25,"comment":"想法独特"},{"dimension":"执行力","score":92,"weight":0.25,"comment":"高效完成任务"},{"dimension":"团队贡献","score":88,"weight":0.2,"comment":"贡献突出"}]', 88.95, 100.00, '数据采集和标注工作非常出色，质量很高。', '专业能力强，做事认真细致', '可以多参与一些技术讨论', '["专业","高效","认真"]', 0),

-- 自我评价
(UUID(), 2, 'self', 'project', @project1_id, 2, @group1_id, 'formative', '[{"dimension":"技术掌握","score":80,"weight":0.3,"comment":"基本掌握了图像识别技术"},{"dimension":"项目管理","score":75,"weight":0.2,"comment":"项目管理经验有待提升"},{"dimension":"团队协作","score":85,"weight":0.25,"comment":"与队友配合愉快"},{"dimension":"创新能力","score":78,"weight":0.15,"comment":"还需要更多创新"},{"dimension":"伦理意识","score":82,"weight":0.1,"comment":"认识到AI应用的社会责任"}]', 79.65, 100.00, '通过这个项目学到了很多，但也发现了自己的不足之处。', '学会了完整的AI项目开发流程，团队协作能力得到提升', '需要加强项目管理能力，提高代码质量，培养创新思维', '["成长","反思","进步空间大"]', 0),

-- 专家评审（总结性评价）
(UUID(), 20, 'expert', 'output', 1, 2, @group1_id, 'summative', '[{"dimension":"技术实现","score":85,"weight":0.35,"comment":"技术方案合理，实现完整"},{"dimension":"创新性","score":80,"weight":0.25,"comment":"在应用场景上有创新"},{"dimension":"实用价值","score":88,"weight":0.25,"comment":"解决了实际问题"},{"dimension":"文档规范","score":82,"weight":0.15,"comment":"文档较完整"}]', 84.05, 100.00, '这是一个完整且实用的AI应用项目，技术实现扎实，具有很好的社会价值。', '问题分析清晰，技术选型合理，应用场景贴近生活，具有推广价值', '模型准确率还有提升空间，用户界面可以更加友好，建议增加更多功能', '["实用","完整","有价值"]', 1);

-- 4.2 学生成长档案 (pbl_student_portfolios)
INSERT INTO `pbl_student_portfolios` (`uuid`, `student_id`, `school_year`, `grade_level`, `completed_projects`, `achievements`, `skill_assessment`, `growth_trajectory`, `highlights`, `total_learning_hours`, `projects_count`, `avg_score`, `teacher_comments`, `self_reflection`) VALUES
(UUID(), 2, '2024-2025', '5-6年级', CONCAT('[{"project_id":', @project1_id, ',"title":"智能垃圾分类APP","score":87,"status":"in-progress","role":"组长"}]'), '[{"id":1,"name":"数据达人","unlocked_at":"2024-11-15"},{"id":2,"name":"团队领袖","unlocked_at":"2024-10-20"}]', '{"技术能力":85,"创新能力":80,"协作能力":90,"伦理意识":82,"问题解决":87}', '{"2024-09":{"技术":70,"创新":75,"协作":85},"2024-10":{"技术":78,"创新":78,"协作":88},"2024-11":{"技术":85,"创新":80,"协作":90}}', '[1,2,3]', 48, 1, 87.50, '该生学习积极主动，技术能力进步明显。在项目中担任组长，展现出良好的领导能力和团队协作精神。希望继续保持学习热情，不断挑战自我。', '通过垃圾分类项目，我深刻体会到AI技术可以为环保事业做出贡献。学会了完整的项目开发流程，也认识到自己在项目管理和创新思维方面还需要提升。下学期希望能参与更多挑战性的项目。'),

(UUID(), 6, '2024-2025', '5-6年级', CONCAT('[{"project_id":', @project1_id, ',"title":"智能垃圾分类APP","score":92,"status":"in-progress","role":"成员"}]'), '[{"id":3,"name":"数据标注专家","unlocked_at":"2024-11-20"}]', '{"技术能力":90,"创新能力":82,"协作能力":85,"伦理意识":88,"问题解决":86}', '{"2024-09":{"技术":75,"创新":78,"协作":82},"2024-10":{"技术":82,"创新":80,"协作":84},"2024-11":{"技术":90,"创新":82,"协作":85}}', '[2]', 52, 1, 92.00, '该生在数据采集和标注方面表现突出，工作认真细致，质量优秀。技术能力扎实，是团队的重要成员。建议多参与技术交流，提升综合能力。', '数据标注工作让我理解了数据质量对AI模型的重要性。每一张图片的认真标注都是对项目的贡献，这让我感到很有成就感。未来想学习更多AI技术。'),

(UUID(), 16, '2024-2025', '3-4年级', CONCAT('[{"project_id":', @project4_id, ',"title":"植物识别小助手","score":91,"status":"completed","role":"独立完成"}]'), '[{"id":4,"name":"初出茅庐","unlocked_at":"2024-09-10"},{"id":5,"name":"模型训练师","unlocked_at":"2024-10-15"}]', '{"技术能力":88,"创新能力":85,"协作能力":80,"伦理意识":86,"问题解决":89}', '{"2024-09":{"技术":65,"创新":70,"协作":75},"2024-10":{"技术":78,"创新":80,"协作":78},"2024-11":{"技术":88,"创新":85,"协作":80}}', '[7]', 42, 1, 91.00, '该生对AI技术充满热情，学习能力强。独立完成了植物识别项目，展现了良好的自学能力和问题解决能力。继续保持学习热情，期待更多优秀作品。', '植物识别项目是我的第一个AI项目，从零开始学习TensorFlow，遇到了很多困难，但最终完成了。这个过程让我认识到学习的重要性，也对AI技术产生了浓厚兴趣。');

-- ==========================================
-- 5. 伦理教育管理测试数据
-- ==========================================

-- 5.1 伦理案例库 (pbl_ethics_cases)
INSERT INTO `pbl_ethics_cases` (`uuid`, `title`, `description`, `content`, `grade_level`, `ethics_topics`, `difficulty`, `discussion_questions`, `reference_links`, `cover_image`, `author`, `source`, `is_published`, `view_count`, `like_count`) VALUES
(UUID(), 'AI人脸识别：便利与隐私的权衡', '学校安装了人脸识别门禁系统，提高了安全性和便利性，但也引发了关于隐私保护的讨论。', '# AI人脸识别：便利与隐私的权衡\n\n## 案例背景\n某中学为了提高校园安全管理水平，决定在校门口安装人脸识别系统。系统可以自动识别师生身份，记录进出时间，还能识别陌生人并及时报警。\n\n## 实施情况\n系统上线后，确实带来了很多便利：\n- 学生不需要刷卡，直接刷脸即可进出\n- 家长可以收到孩子到校、离校的通知\n- 陌生人进入校园会立即被识别\n- 学生考勤统计更加准确\n\n## 产生的问题\n但同时也出现了一些担忧：\n- 学生的面部信息被大量采集和存储\n- 系统会记录每个人的行踪轨迹\n- 有学生表示不喜欢被"监控"的感觉\n- 如果数据泄露会产生严重后果\n\n## 思考方向\n1. 技术的便利性和个人隐私如何平衡？\n2. 学校应该采取哪些措施保护数据安全？\n3. 学生是否应该有权选择退出？', '5-6年级', JSON_ARRAY('数据隐私','技术滥用','知情同意','数据安全'), 'intermediate', JSON_ARRAY('你觉得学校使用人脸识别系统合理吗？为什么？','如果你是学校管理者，会如何平衡安全管理和隐私保护？','学生的面部数据应该如何存储和使用？需要遵循什么原则？','除了人脸识别，还有哪些更友好的校园管理方式？'), JSON_ARRAY('《中华人民共和国个人信息保护法》','《儿童个人信息网络保护规定》'), '/images/ethics/face-recognition.jpg', '张老师', '某某中学案例库', 1, 234, 45),

(UUID(), 'AI作业批改助手：是帮手还是替代？', '一款AI作业批改软件能快速批改作业，但也引发了对教师角色和教育本质的思考。', '# AI作业批改助手：是帮手还是替代？\n\n## 案例介绍\n某教育科技公司开发了一款AI作业批改软件，可以自动批改数学、英语等科目的作业，并生成详细的错误分析报告。很多学校引进了这个系统。\n\n## 优势\n- 批改速度快，大大减轻教师负担\n- 评分标准统一、客观\n- 能生成详细的学情分析报告\n- 可以24小时提供反馈\n\n## 问题\n- 一些个性化的答案无法被AI理解\n- 缺少教师的鼓励和关怀\n- 学生可能过度依赖AI反馈\n- 教师的专业价值是否会被削弱？\n\n## 真实案例\n小明的一道数学题用了非常规方法解答，虽然答案正确，但AI系统因为不符合标准答案格式而判错。小明感到很沮丧。\n\n## 讨论要点\n技术应该如何辅助教育？教师的不可替代性体现在哪里？', '7-9年级', JSON_ARRAY('认知外包','技术依赖','教育本质','人机协作'), 'intermediate', JSON_ARRAY('AI批改作业有哪些优点和局限？','如果你是老师，会如何使用AI批改工具？','技术能完全替代教师吗？为什么？','如何避免学生对AI产生过度依赖？'), JSON_ARRAY('《人工智能教育应用伦理指南》'), '/images/ethics/ai-grading.jpg', '李老师', '教育伦理研究中心', 1, 187, 38),

(UUID(), '算法推荐的"信息茧房"', '短视频平台的推荐算法让人看到更多自己感兴趣的内容，但也可能限制视野。', '# 算法推荐的"信息茧房"\n\n## 现象描述\n小红非常喜欢看舞蹈视频，某短视频App的算法发现了她的喜好，不断推荐各类舞蹈内容。渐渐地，小红发现自己的推荐页面几乎都是舞蹈视频，其他类型的内容很少看到了。\n\n## 算法原理\n推荐算法通过分析用户行为（点赞、观看时长、评论等），预测用户喜好，推荐相似内容，提高用户粘性。\n\n## 带来的问题\n- 视野变窄，接触不到多元化信息\n- 可能强化原有观点，缺乏批判性思考\n- 不同用户看到的"世界"完全不同\n- 容易形成"回音壁"效应\n\n## 思考\n这种个性化推荐是技术进步还是信息囚笼？', '7-9年级', JSON_ARRAY('算法偏见','信息茧房','媒介素养','批判性思维'), 'advanced', JSON_ARRAY('算法推荐的优点和缺点是什么？','如何避免陷入信息茧房？','平台应该承担什么责任？','作为用户，我们应该如何主动选择信息？'), JSON_ARRAY('《算法推荐的社会影响研究》'), '/images/ethics/algorithm-bubble.jpg', '王老师', '媒介素养教育中心', 1, 312, 67),

(UUID(), 'AI生成的"假"作文', '有同学使用AI写作工具完成作文作业，引发了关于学习诚信和技术使用的讨论。', '# AI生成的"假"作文\n\n## 事件经过\n小华发现一个AI写作工具，只要输入主题和要求，就能生成一篇完整的作文。他用这个工具完成了一篇读后感作业，得到了老师的表扬。但他心里总觉得不踏实。\n\n## 同学反应\n- 有人觉得这是利用工具提高效率，没问题\n- 有人认为这是作弊行为，不诚实\n- 有人担心长期这样会影响写作能力\n\n## 深层问题\n- AI时代，原创性如何定义？\n- 学习的目的是完成作业还是提升能力？\n- 如何正确使用AI辅助学习？', '5-6年级', JSON_ARRAY('学术诚信','认知外包','技术依赖','学习本质'), 'basic', JSON_ARRAY('使用AI写作文算不算作弊？为什么？','如果你是小华，你会怎么做？','AI写作工具应该如何正确使用？','技术会让我们变得更聪明还是更懒惰？'), NULL, '/images/ethics/ai-writing.jpg', '陈老师', '教育伦理案例集', 1, 423, 89),

(UUID(), '自动驾驶的"电车难题"', '自动驾驶汽车遇到紧急情况时，如何做出决策？', '# 自动驾驶的"电车难题"\n\n## 场景设定\n一辆自动驾驶汽车在行驶中，前方突然出现两个孩子横穿马路。如果急刹车，可能撞到孩子；如果转向，会撞上路边的行人；如果保持直行，肯定会撞到孩子。系统只有0.5秒时间做决定。\n\n## 伦理困境\n- 应该优先保护谁？\n- 谁来决定这个优先级？\n- 这个决策标准能被编程吗？\n- 不同文化背景下的选择会一样吗？\n\n## 延伸思考\n这不仅是技术问题，更是伦理问题。AI做出的决策反映了什么价值观？', '10-12年级', JSON_ARRAY('算法伦理','生命价值','道德决策','技术责任'), 'advanced', JSON_ARRAY('如果你是AI工程师，会如何设计这个决策算法？','这个问题有标准答案吗？','AI的决策和人类的决策有什么不同？','如何在技术设计中体现伦理考量？'), JSON_ARRAY('《机器伦理学导论》'), '/images/ethics/trolley-problem.jpg', '赵老师', '科技伦理研究所', 1, 567, 123);

-- 获取伦理案例ID用于后续插入
SET @case1_id = (SELECT id FROM pbl_ethics_cases WHERE title = 'AI人脸识别：便利与隐私的权衡' LIMIT 1);
SET @case2_id = (SELECT id FROM pbl_ethics_cases WHERE title = 'AI作业批改助手：是帮手还是替代？' LIMIT 1);
SET @case3_id = (SELECT id FROM pbl_ethics_cases WHERE title = '算法推荐的"信息茧房"' LIMIT 1);
SET @case4_id = (SELECT id FROM pbl_ethics_cases WHERE title = 'AI生成的"假"作文' LIMIT 1);
SET @case5_id = (SELECT id FROM pbl_ethics_cases WHERE title = '自动驾驶的"电车难题"' LIMIT 1);

-- 5.2 伦理活动记录 (pbl_ethics_activities)
INSERT INTO `pbl_ethics_activities` (`uuid`, `case_id`, `course_id`, `unit_id`, `activity_type`, `title`, `description`, `participants`, `group_id`, `facilitator_id`, `status`, `discussion_records`, `conclusions`, `reflections`, `scheduled_at`, `completed_at`) VALUES
(UUID(), @case1_id, @course1_id, @unit1_id, 'debate', '人脸识别系统辩论赛', '就校园人脸识别系统的使用展开正反方辩论', '[2,3,6,7,8,9]', @group1_id, 1, 'completed', '[{"student_id":2,"viewpoint":"支持使用，但需要严格的数据保护措施","arguments":["提高安全性","方便管理","技术发展趋势"],"time":"2024-11-05 14:30:00"},{"student_id":7,"viewpoint":"反对过度使用，担心隐私问题","arguments":["侵犯隐私","心理压力","数据安全风险"],"time":"2024-11-05 14:35:00"}]', '通过激烈讨论，同学们认识到技术应用需要在便利性和隐私保护之间寻找平衡。学校应该制定严格的数据管理制度，并充分听取学生意见。技术不是目的，而是为人服务的工具。', '[{"student_id":2,"content":"这次辩论让我意识到技术应用不仅是技术问题，更是社会问题。我们在开发AI应用时，必须考虑伦理影响。","insights":["技术与伦理的关系","数据保护的重要性","多方利益的平衡"]},{"student_id":7,"content":"了解了不同观点后，我的看法更加全面了。技术可以用，但要用得恰当，要有底线。","insights":["批判性思维","换位思考","规则意识"]}]', '2024-11-05 14:00:00', '2024-11-05 16:00:00'),

(UUID(), @case2_id, @course2_id, @unit_course2_1, 'case_analysis', 'AI批改作业案例分析', '分析AI批改工具的利弊，探讨人机协作的教育模式', '[4,13,14,15]', @group3_id, 1, 'completed', '[{"student_id":4,"viewpoint":"AI可以作为辅助工具，但不能完全替代教师","time":"2024-11-10 15:00:00"},{"student_id":13,"viewpoint":"关键是如何合理使用，发挥各自优势","time":"2024-11-10 15:10:00"}]', 'AI批改工具在客观题上有优势，但主观题、开放性问题仍需教师参与。未来的教育应该是人机协作模式，AI处理重复性工作,教师专注于启发思考和情感关怀。', '[{"student_id":4,"content":"认识到教师的价值不仅在于传授知识，更在于启发思考、培养品格。","insights":["教育本质","人文关怀","技术边界"]},{"student_id":14,"content":"技术应该让教育更好,而不是取代教育的核心价值。","insights":["技术工具论","以人为本"]}]', '2024-11-10 14:30:00', '2024-11-10 16:30:00'),

(UUID(), @case4_id, @course1_id, @unit2_id, 'discussion', 'AI写作工具使用规范讨论', '小组讨论如何正确使用AI写作辅助工具', '[2,6,7,8,9]', @group1_id, 1, 'completed', '[{"student_id":6,"viewpoint":"可以用AI帮助构思和润色，但核心内容要自己写","time":"2024-11-12 10:00:00"},{"student_id":8,"viewpoint":"应该明确标注哪些部分使用了AI辅助","time":"2024-11-12 10:10:00"}]', '制定了小组AI工具使用公约：1)主要内容必须原创；2)AI仅用于辅助；3)明确标注AI使用情况；4)不能直接提交AI生成的内容。', '[{"student_id":8,"content":"诚信比成绩更重要，使用工具要遵守规则。","insights":["学术诚信","自律意识"]}]', '2024-11-12 09:30:00', '2024-11-12 11:00:00'),

(UUID(), @case3_id, NULL, NULL, 'reflection', '信息茧房反思活动', '让学生记录一周的内容消费，反思算法推荐的影响', '[2,3,4,5,6,16,17,18]', NULL, 1, 'ongoing', NULL, NULL, '[{"student_id":2,"content":"发现自己确实陷入了信息茧房，总是看相似的内容。决定主动寻找不同类型的信息源。","insights":["媒介觉察","主动选择","视野拓展"]},{"student_id":16,"content":"算法推荐让我错过了很多有趣的内容，我要学会主动探索。","insights":["算法影响","主动性"]}]', '2024-11-15 00:00:00', NULL);

-- ==========================================
-- 6. 家校社协同测试数据
-- ==========================================

-- 6.1 外部专家 (pbl_external_experts)
INSERT INTO `pbl_external_experts` (`uuid`, `name`, `organization`, `title`, `expertise_areas`, `bio`, `email`, `phone`, `avatar`, `is_active`, `participated_projects`, `avg_rating`) VALUES
(UUID(), '张伟', '清华大学计算机系', '副教授', '["人工智能","机器学习","计算机视觉"]', '张伟博士，清华大学计算机系副教授，主要研究方向为计算机视觉和深度学习。发表论文50余篇，主持国家自然科学基金项目3项。热心科普教育，多次为中小学生做AI科普讲座。', 'zhangwei@tsinghua.edu.cn', '13800138001', '/avatars/expert1.jpg', 1, 5, 4.80),

(UUID(), '李梅', '百度AI实验室', '高级工程师', '["自然语言处理","对话系统","知识图谱"]', '李梅，百度AI实验室高级工程师，具有10年NLP研发经验。参与开发了百度多款AI产品，在对话系统领域有深入研究。愿意为青少年AI教育贡献力量。', 'limei@baidu.com', '13900139001', '/avatars/expert2.jpg', 1, 3, 4.70),

(UUID(), '王强', '北京市环境保护科学研究院', '高级工程师', '["环境保护","智慧城市","物联网"]', '王强，环保领域专家，长期从事智慧环保系统研发。对垃圾分类、环境监测等领域有丰富经验。支持青少年环保教育和科技创新。', 'wangqiang@bjee.org.cn', '13700137001', '/avatars/expert3.jpg', 1, 2, 4.90),

(UUID(), '刘芳', '微软亚洲研究院', '研究员', '["深度学习","语音识别","多模态学习"]', '刘芳博士，微软亚洲研究院研究员，ACM杰出会员。在深度学习领域有突出贡献，多次获得国际学术奖项。热衷于科技教育公益活动。', 'liufang@microsoft.com', '13600136001', '/avatars/expert4.jpg', 1, 1, 5.00),

(UUID(), '陈建国', '中国科学院自动化研究所', '研究员', '["机器人","智能控制","人机交互"]', '陈建国研究员，中科院自动化所智能系统实验室主任。在智能机器人和人机交互领域有20年研究经验。多次指导青少年机器人竞赛。', 'chenjianguo@ia.ac.cn', '13500135001', '/avatars/expert5.jpg', 1, 4, 4.75);

-- 6.2 家长关系 (pbl_parent_relations) - 假设有家长用户
-- 注意：这里假设user_id 100-105 是家长账号
INSERT INTO `pbl_parent_relations` (`parent_user_id`, `student_id`, `relationship`, `can_view_progress`, `can_view_scores`, `can_view_projects`, `notification_enabled`, `verified`, `verified_at`) VALUES
(100, 2, 'father', 1, 1, 1, 1, 1, '2024-09-01 10:00:00'),
(101, 2, 'mother', 1, 1, 1, 1, 1, '2024-09-01 10:05:00'),
(102, 6, 'mother', 1, 1, 1, 1, 1, '2024-09-01 11:00:00'),
(103, 16, 'father', 1, 1, 1, 1, 1, '2024-09-02 09:00:00'),
(104, 4, 'guardian', 1, 1, 1, 1, 1, '2024-09-02 14:00:00');

-- 6.3 社会实践活动 (pbl_social_activities)
INSERT INTO `pbl_social_activities` (`uuid`, `title`, `description`, `activity_type`, `organizer`, `partner_organization`, `location`, `scheduled_at`, `duration`, `max_participants`, `current_participants`, `participants`, `facilitators`, `status`, `photos`, `summary`, `feedback`) VALUES
(UUID(), '参观百度AI展厅', '组织学生参观百度AI展厅，了解人工智能技术的最新发展和实际应用', 'company_visit', '某某中学', '百度公司', '北京市海淀区百度科技园', '2024-10-20 09:00:00', 180, 30, 25, '[2,3,6,7,8,9,10,16,17,18,19,4,13,14,15,20,21,22,23,24,25,26,27,28,29,30]', '[1]', 'completed', '["/photos/baidu-visit-1.jpg","/photos/baidu-visit-2.jpg","/photos/baidu-visit-3.jpg"]', '本次活动圆满成功。学生们参观了百度AI展厅，体验了智能语音助手、自动驾驶模拟器等前沿AI产品。百度工程师进行了深入讲解，学生们积极提问互动。活动后，学生们对AI技术的应用场景有了更直观的认识，激发了学习热情。', '[{"student_id":2,"rating":5,"comment":"非常震撼！看到了很多只在书上学过的技术的实际应用。"},{"student_id":6,"rating":5,"comment":"工程师讲解很专业，收获很大。"},{"student_id":16,"rating":4,"comment":"展厅很酷，希望以后能有更多这样的活动。"}]'),

(UUID(), '清华大学AI实验室开放日', '走进清华大学人工智能实验室，与教授面对面交流', 'lab_tour', '某某中学', '清华大学计算机系', '清华大学FIT楼', '2024-11-15 14:00:00', 120, 20, 18, '[2,3,4,5,6,7,8,9,13,14,15,16,17,18,19,20,21,22]', '[1]', 'completed', '["/photos/tsinghua-lab-1.jpg","/photos/tsinghua-lab-2.jpg"]', '张伟教授热情接待了学生们，详细介绍了实验室的研究方向和最新成果。学生们参观了GPU集群、机器人实验室，观摩了研究生的项目演示。张教授还为大家做了一场生动的AI科普讲座，并耐心解答问题。许多学生表示对AI研究产生了浓厚兴趣。', '[{"student_id":4,"rating":5,"comment":"张教授讲得太好了，激发了我对科研的向往。"},{"student_id":2,"rating":5,"comment":"看到了真正的AI研究是什么样子，和我想象的不一样，更有挑战性。"}]'),

(UUID(), '青少年AI创新大赛', '市级青少年人工智能创新应用大赛', 'competition', '北京市教委', '北京市科协', '北京市青少年活动中心', '2024-12-01 08:00:00', 480, 200, 156, '[2,6,9,3,10,11,4,13,14,16,17]', '[1]', 'completed', '["/photos/ai-competition-1.jpg","/photos/ai-competition-2.jpg"]', '本次大赛共有50支队伍参赛，展示了各类优秀的AI应用项目。我校有3支队伍参赛，"智能分类先锋队"的垃圾分类项目获得二等奖，"植物识别小助手"获得三等奖。评委专家给予了高度评价，认为项目有创新性和实用价值。学生们在比赛中学到了很多，也看到了其他优秀作品，开阔了视野。', '[{"student_id":2,"rating":5,"comment":"比赛紧张但很充实，看到了很多优秀的项目，学到了很多。"},{"student_id":6,"rating":4,"comment":"虽然没有获得一等奖，但我们尽力了，这个过程本身就很有价值。"},{"student_id":16,"rating":5,"comment":"第一次参加这么大的比赛，虽然紧张但很兴奋，期待下次再参加。"}]'),

(UUID(), 'AI伦理与社会责任研讨会', '邀请专家学者与学生共同探讨AI伦理问题', 'lecture', '某某中学', '中国科学院自动化研究所', '某某中学学术报告厅', '2024-11-25 15:00:00', 120, 100, 87, '[2,3,4,5,6,7,8,9,10,13,14,15,16,17,18,19,20]', '[1]', 'completed', '["/photos/ethics-seminar.jpg"]', '陈建国研究员做了题为《人工智能的伦理挑战与社会责任》的主题报告，深入浅出地讲解了AI发展中的伦理问题。随后进行了互动讨论环节，学生们就数据隐私、算法偏见、技术滥用等话题与专家交流。会议加深了学生们对AI伦理的理解，培养了批判性思维和社会责任感。', '[{"student_id":2,"rating":5,"comment":"这种讨论很有意义，让我认识到AI开发者的社会责任。"},{"student_id":7,"rating":5,"comment":"陈研究员的讲座让我对AI有了更深层次的思考。"}]'),

(UUID(), '智慧城市创新工作坊', '与企业工程师合作，设计智慧城市解决方案', 'workshop', '某某中学', '华为技术有限公司', '某某中学创客空间', '2024-12-10 09:00:00', 360, 40, 32, '[2,3,4,5,6,7,8,9,13,14,15,19,20,21,22,23]', '[1]', 'registration', NULL, NULL, NULL);

-- ==========================================
-- 完成提示
-- ==========================================

SET FOREIGN_KEY_CHECKS = 1;

SELECT '✅ 测试数据插入完成！' AS status;
SELECT '📊 数据统计：' AS info;
SELECT 
    (SELECT COUNT(*) FROM pbl_courses) AS '课程数',
    (SELECT COUNT(*) FROM pbl_units) AS '单元数',
    (SELECT COUNT(*) FROM pbl_resources) AS '资源数',
    (SELECT COUNT(*) FROM pbl_tasks) AS '任务数',
    (SELECT COUNT(*) FROM pbl_datasets) AS '数据集数',
    (SELECT COUNT(*) FROM pbl_classes) AS '班级数',
    (SELECT COUNT(*) FROM pbl_groups) AS '小组数',
    (SELECT COUNT(*) FROM pbl_projects) AS '项目数',
    (SELECT COUNT(*) FROM pbl_project_outputs) AS '项目成果数',
    (SELECT COUNT(*) FROM pbl_assessments) AS '评价记录数',
    (SELECT COUNT(*) FROM pbl_ethics_cases) AS '伦理案例数',
    (SELECT COUNT(*) FROM pbl_ethics_activities) AS '伦理活动数',
    (SELECT COUNT(*) FROM pbl_external_experts) AS '外部专家数',
    (SELECT COUNT(*) FROM pbl_social_activities) AS '社会实践活动数';
