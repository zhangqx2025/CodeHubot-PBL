-- ==========================================================================================================
-- 智能家居控制智能体课程 - 初始化数据脚本
-- ==========================================================================================================
-- 
-- 脚本名称: 01_init_smart_home_course.sql
-- 脚本版本: 1.0.0
-- 创建日期: 2025-12-09
-- 兼容版本: MySQL 5.7.x, 8.0.x
-- 字符集: utf8mb4
-- 排序规则: utf8mb4_unicode_ci
--
-- ==========================================================================================================
-- 脚本说明
-- ==========================================================================================================
--
-- 1. 用途说明:
--    本脚本用于初始化"智能家居控制智能体"PBL课程的完整数据，包含：
--    - 1个课程：智能家居控制智能体
--    - 8个单元：智能体入门、插件、AIOT配置流程、知识库、工作流、对话流、调试与优化、综合
--    - 视频资源：每个单元的教学视频
--    - 实践任务：每个单元的实践任务清单
--
-- 2. 课程结构:
--    单元1: 智能体入门 - 创建能够理解自然语言的智能家居助手
--    单元2: 插件应用 - 学习使用各种插件扩展智能体能力(精简为3个任务)
--    单元3: 连接物理世界 - AIoT设备接入,实现软硬件连接
--    单元4: 知识库 - 让智能助手成为设备专家
--    单元5: 工作流 - 实现智能场景自动化(精简为3个任务)
--    单元6: 对话流 - 实现意图识别,从明确指令升级到自然对话
--    单元7: 调试与优化 - 根据不同情况智能控制设备
--    单元8: 综合 - 整合所有功能,实现智能意图路由
--
-- 3. 执行方式:
--    mysql -h hostname -u username -p --default-character-set=utf8mb4 aiot_admin < 01_init_smart_home_course.sql
--
-- 4. 注意事项:
--    - 请确保已执行 init_database.sql 和 pbl_schema.sql
--    - 脚本使用UUID函数生成唯一标识
--    - 课程创建者ID默认为1，请根据实际情况修改
--
-- ==========================================================================================================

-- 设置执行环境
SET NAMES utf8mb4 COLLATE utf8mb4_unicode_ci;
SET FOREIGN_KEY_CHECKS = 0;

-- 开始事务
START TRANSACTION;

-- ==========================================================================================================
-- 1. 创建课程
-- ==========================================================================================================

INSERT INTO `pbl_courses` (
    `uuid`,
    `title`,
    `description`,
    `cover_image`,
    `duration`,
    `difficulty`,
    `status`,
    `creator_id`,
    `school_id`,
    `created_at`,
    `updated_at`
) VALUES (
    UUID(),
    '智能家居控制智能体',
    '本课程采用项目制学习(PBL)的方式,通过"构建智能家居控制系统"这个实际项目,让学生边做边学,逐步掌握AI智能体开发技能。课程将学习人工智能、物联网等知识,培养动手能力和解决问题的能力。最终做出一个能够控制家居设备、听懂你说话、自动执行任务的智能助手,具备自然对话、设备控制、专业知识、场景自动化、意图理解和智能决策等能力。',
    NULL,
    '8周',
    'intermediate',
    'published',
    1,
    NULL,
    CURRENT_TIMESTAMP,
    CURRENT_TIMESTAMP
);

-- 获取刚插入的课程ID
SET @course_id = LAST_INSERT_ID();

-- ==========================================================================================================
-- 2. 创建单元
-- ==========================================================================================================

-- 单元1: 智能体入门
INSERT INTO `pbl_units` (
    `uuid`,
    `course_id`,
    `title`,
    `description`,
    `order`,
    `status`,
    `learning_guide`,
    `created_at`,
    `updated_at`
) VALUES (
    UUID(),
    @course_id,
    '智能体入门',
    '创建你的第一个智能助手：能够理解自然语言的智能家居助手。学习如何让计算机理解我们说的话，当你说"打开客厅的灯"、"把温度调到25度"时，计算机如何理解这些话。',
    1,
    'available',
    JSON_OBJECT(
        'objectives', JSON_ARRAY(
            '了解什么是智能体,它能做什么',
            '学会使用Coze平台创建智能体',
            '学会编写提示词,让AI理解你的需求',
            '完成一个能对话的智能家居助手'
        ),
        'duration', '2小时(1次课)',
        'time_allocation', JSON_OBJECT(
            'video', '38分钟',
            'reading', '20分钟',
            'practice', '62分钟'
        ),
        'prerequisites', JSON_ARRAY('会基本的电脑操作', '知道什么是智能家居')
    ),
    CURRENT_TIMESTAMP,
    CURRENT_TIMESTAMP
);
SET @unit1_id = LAST_INSERT_ID();

-- 单元2: 插件应用
INSERT INTO `pbl_units` (
    `uuid`,
    `course_id`,
    `title`,
    `description`,
    `order`,
    `status`,
    `learning_guide`,
    `created_at`,
    `updated_at`
) VALUES (
    UUID(),
    @course_id,
    '插件应用',
    '让智能助手更强大：学会使用各种插件来扩展智能体的能力。学习如何让助手能获取实时信息(天气、新闻)、读取网页内容、识别图片中的文字等。',
    2,
    'locked',
    JSON_OBJECT(
        'objectives', JSON_ARRAY(
            '理解什么是插件,插件有什么用',
            '学会给智能体添加插件',
            '学会使用新闻插件获取实时信息',
            '学会使用链接读取插件读取网页',
            '学会使用OCR插件识别图片中的文字'
        ),
        'duration', '2小时(1次课)',
        'time_allocation', JSON_OBJECT(
            'video', '40分钟',
            'reading', '20分钟',
            'practice', '60分钟'
        ),
        'prerequisites', JSON_ARRAY('完成单元1:智能体入门', '有可用的智能家居助手')
    ),
    CURRENT_TIMESTAMP,
    CURRENT_TIMESTAMP
);
SET @unit2_id = LAST_INSERT_ID();

-- 单元3: 连接物理世界 - AIoT设备接入
INSERT INTO `pbl_units` (
    `uuid`,
    `course_id`,
    `title`,
    `description`,
    `order`,
    `status`,
    `learning_guide`,
    `created_at`,
    `updated_at`
) VALUES (
    UUID(),
    @course_id,
    '连接物理世界 - AIoT设备接入',
    '实现软件与硬件的连接：做出能够控制真实物理设备的智能家居控制系统。这是智能家居系统最关键的一步:用户说"开灯",如何让实际的灯泡真的亮起来。',
    3,
    'locked',
    JSON_OBJECT(
        'objectives', JSON_ARRAY(
            '了解什么是AIoT',
            '学会配置AIoT设备',
            '学会创建能控制设备的智能体',
            '实现对话控制设备'
        ),
        'duration', '2小时(1次课)',
        'time_allocation', JSON_OBJECT(
            'video', '35分钟',
            'reading', '20分钟',
            'practice', '65分钟'
        ),
        'prerequisites', JSON_ARRAY('完成单元2:插件应用', '准备AIoT设备(智能灯、温湿度传感器等)')
    ),
    CURRENT_TIMESTAMP,
    CURRENT_TIMESTAMP
);
SET @unit3_id = LAST_INSERT_ID();

-- 单元4: 知识库
INSERT INTO `pbl_units` (
    `uuid`,
    `course_id`,
    `title`,
    `description`,
    `order`,
    `status`,
    `learning_guide`,
    `created_at`,
    `updated_at`
) VALUES (
    UUID(),
    @course_id,
    '知识库',
    '让智能助手成为设备专家：建立包含设备知识、使用技巧的智能家居知识库系统。让助手不仅能控制设备,还能回答"这个智能灯如何重置"、"加湿器能整晚开着吗"、"如何节省电费"等专业问题。',
    4,
    'locked',
    JSON_OBJECT(
        'objectives', JSON_ARRAY(
            '了解知识库在智能系统中的作用',
            '学会收集和整理设备知识',
            '学会创建和管理知识库',
            '实现基于知识的问答功能'
        ),
        'duration', '2小时(1次课)',
        'time_allocation', JSON_OBJECT(
            'video', '35分钟',
            'reading', '20分钟',
            'practice', '65分钟'
        ),
        'prerequisites', JSON_ARRAY('完成单元3:AIoT设备接入', '收集家中设备的说明书')
    ),
    CURRENT_TIMESTAMP,
    CURRENT_TIMESTAMP
);
SET @unit4_id = LAST_INSERT_ID();

-- 单元5: 工作流
INSERT INTO `pbl_units` (
    `uuid`,
    `course_id`,
    `title`,
    `description`,
    `order`,
    `status`,
    `learning_guide`,
    `created_at`,
    `updated_at`
) VALUES (
    UUID(),
    @course_id,
    '工作流',
    '实现智能场景自动化：做出"回家模式"、"离家模式"、"睡眠模式"等智能场景。让多个设备协同工作,用户说"我到家了",系统自动完成:开玄关灯→开客厅灯→调节温度→拉开窗帘。',
    5,
    'locked',
    JSON_OBJECT(
        'objectives', JSON_ARRAY(
            '了解工作流在智能家居中的作用',
            '学会设计场景自动化流程',
            '学会使用工作流节点',
            '实现多设备协同'
        ),
        'duration', '2小时(1次课)',
        'time_allocation', JSON_OBJECT(
            'video', '40分钟',
            'reading', '20分钟',
            'practice', '60分钟'
        ),
        'prerequisites', JSON_ARRAY('完成单元4:知识库', '至少有2个以上设备')
    ),
    CURRENT_TIMESTAMP,
    CURRENT_TIMESTAMP
);
SET @unit5_id = LAST_INSERT_ID();

-- 单元6: 对话流
INSERT INTO `pbl_units` (
    `uuid`,
    `course_id`,
    `title`,
    `description`,
    `order`,
    `status`,
    `learning_guide`,
    `created_at`,
    `updated_at`
) VALUES (
    UUID(),
    @course_id,
    '对话流',
    '让智能助手真正"听懂"用户：实现意图识别,从明确指令升级到自然对话。理解用户话语背后的真实意图:"我冷了"→提高温度,"太暗了"→开灯或调亮,"准备睡觉了"→启动睡眠模式。',
    6,
    'locked',
    JSON_OBJECT(
        'objectives', JSON_ARRAY(
            '了解意图识别的原理',
            '学会创建AIoT对话流',
            '学会配置意图识别',
            '实现自然对话控制'
        ),
        'duration', '2小时(1次课)',
        'time_allocation', JSON_OBJECT(
            'video', '34分钟',
            'reading', '20分钟',
            'practice', '66分钟'
        ),
        'prerequisites', JSON_ARRAY('完成单元5:工作流', '已有3个以上场景工作流')
    ),
    CURRENT_TIMESTAMP,
    CURRENT_TIMESTAMP
);
SET @unit6_id = LAST_INSERT_ID();

-- 单元7: 调试与优化
INSERT INTO `pbl_units` (
    `uuid`,
    `course_id`,
    `title`,
    `description`,
    `order`,
    `status`,
    `learning_guide`,
    `created_at`,
    `updated_at`
) VALUES (
    UUID(),
    @course_id,
    '调试与优化',
    '让系统更智能：学会根据不同情况组合控制设备。同样是"我到家了",在不同情况下应该有不同响应:白天回家→开灯(低亮度),晚上回家→开灯(全亮),夏天回家→优先开空调制冷,冬天回家→优先开暖气。',
    7,
    'locked',
    JSON_OBJECT(
        'objectives', JSON_ARRAY(
            '学会识别不同情况',
            '学会组合控制设备',
            '学会优化系统'
        ),
        'duration', '2小时(1次课)',
        'time_allocation', JSON_OBJECT(
            'video', '25分钟',
            'reading', '20分钟',
            'practice', '75分钟'
        ),
        'prerequisites', JSON_ARRAY('完成单元6:对话流')
    ),
    CURRENT_TIMESTAMP,
    CURRENT_TIMESTAMP
);
SET @unit7_id = LAST_INSERT_ID();

-- 单元8: 综合
INSERT INTO `pbl_units` (
    `uuid`,
    `course_id`,
    `title`,
    `description`,
    `order`,
    `status`,
    `learning_guide`,
    `created_at`,
    `updated_at`
) VALUES (
    UUID(),
    @course_id,
    '综合',
    '完成项目：整合所有功能,做出完整的智能家居控制系统。到现在为止,你已经做出了能对话的智能助手、各种插件能力、设备控制、专业知识库、场景自动化、意图识别和情况判断。本单元任务:系统整合、全面测试、优化体验、项目文档、项目展示。',
    8,
    'locked',
    JSON_OBJECT(
        'objectives', JSON_ARRAY(
            '学会整合系统',
            '学会测试系统',
            '学会编写文档',
            '学会展示项目'
        ),
        'duration', '2小时(1次课)',
        'time_allocation', JSON_OBJECT(
            'video', '30分钟',
            'reading', '15分钟',
            'practice', '75分钟'
        ),
        'prerequisites', JSON_ARRAY('完成单元7:调试与优化')
    ),
    CURRENT_TIMESTAMP,
    CURRENT_TIMESTAMP
);
SET @unit8_id = LAST_INSERT_ID();

-- ==========================================================================================================
-- 3. 创建资源（视频）
-- ==========================================================================================================

-- 单元1: 智能体入门 - 视频资源
INSERT INTO `pbl_resources` (`uuid`, `unit_id`, `type`, `title`, `description`, `url`, `duration`, `order`, `created_at`, `updated_at`)
VALUES
(UUID(), @unit1_id, 'video', '智能体和coze平台介绍', '介绍智能体的基本概念、应用场景以及Coze平台的功能特点和使用方法', NULL, 8, 1, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(UUID(), @unit1_id, 'video', '创建智能体', '详细演示如何在Coze平台上创建一个新的智能体，包括基本配置和初始化设置', NULL, 10, 2, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(UUID(), @unit1_id, 'video', '编写提示词与优化', '学习如何编写高质量的提示词，掌握提示词优化的技巧和最佳实践', NULL, 12, 3, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(UUID(), @unit1_id, 'video', '智能体的发布', '学习智能体的发布流程，包括测试、部署和版本管理', NULL, 8, 4, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

-- 单元2: 插件 - 视频资源
INSERT INTO `pbl_resources` (`uuid`, `unit_id`, `type`, `title`, `description`, `url`, `duration`, `order`, `created_at`, `updated_at`)
VALUES
(UUID(), @unit2_id, 'video', '插件的使用', '介绍插件的概念、作用以及在智能体中如何添加和使用插件', NULL, 8, 1, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(UUID(), @unit2_id, 'video', '获取新闻信息', '学习使用头条新闻插件获取实时新闻资讯，并在对话中调用', NULL, 8, 2, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(UUID(), @unit2_id, 'video', '链接读取', '掌握链接读取插件的使用方法，实现网页内容的提取和分析', NULL, 8, 3, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(UUID(), @unit2_id, 'video', '图像识别文字', '学习使用OCR技术进行图像文字识别，提取图片中的文本信息', NULL, 8, 4, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(UUID(), @unit2_id, 'video', '图像生成', '掌握使用图像生成插件创建各种风格的图片', NULL, 8, 5, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

-- 单元3: AIOT配置流程与创建AIoT智能体 - 视频资源
INSERT INTO `pbl_resources` (`uuid`, `unit_id`, `type`, `title`, `description`, `url`, `duration`, `order`, `created_at`, `updated_at`)
VALUES
(UUID(), @unit3_id, 'video', 'AIOT设备配置流程', '详细介绍AIoT设备的配置步骤，包括设备注册、连接和初始化', NULL, 15, 1, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(UUID(), @unit3_id, 'video', '创建AIoT智能体', '学习创建能够与物理设备交互的AIoT智能体，实现设备控制和数据读取', NULL, 20, 2, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

-- 单元4: 知识库 - 视频资源
INSERT INTO `pbl_resources` (`uuid`, `unit_id`, `type`, `title`, `description`, `url`, `duration`, `order`, `created_at`, `updated_at`)
VALUES
(UUID(), @unit4_id, 'video', '创建知识库', '学习如何创建和配置知识库，包括文本格式知识的导入和组织', NULL, 10, 1, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(UUID(), @unit4_id, 'video', '查询历史知识库', '掌握知识库的查询方法，了解如何高效检索历史知识', NULL, 10, 2, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(UUID(), @unit4_id, 'video', '智能家居aiot智能体', '学习为智能家居AIoT智能体添加专业知识库，增强问答能力', NULL, 15, 3, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

-- 单元5: 工作流 - 视频资源
INSERT INTO `pbl_resources` (`uuid`, `unit_id`, `type`, `title`, `description`, `url`, `duration`, `order`, `created_at`, `updated_at`)
VALUES
(UUID(), @unit5_id, 'video', '创建工作流', '学习工作流的基本概念和创建方法，了解工作流的设计原则', NULL, 8, 1, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(UUID(), @unit5_id, 'video', '配置与调试工作流', '掌握工作流的配置方法和调试技巧，确保流程正确运行', NULL, 10, 2, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(UUID(), @unit5_id, 'video', '开始、结束节点', '学习工作流的开始节点和结束节点的配置和使用', NULL, 6, 3, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(UUID(), @unit5_id, 'video', '大模型节点', '掌握在工作流中配置和使用大模型节点，实现AI能力的调用', NULL, 8, 4, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(UUID(), @unit5_id, 'video', '文本处理节点', '学习使用文本处理节点进行字符串操作，如拼接、分割、替换等', NULL, 8, 5, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

-- 单元6: 对话流 - 视频资源
INSERT INTO `pbl_resources` (`uuid`, `unit_id`, `type`, `title`, `description`, `url`, `duration`, `order`, `created_at`, `updated_at`)
VALUES
(UUID(), @unit6_id, 'video', '创建aiot对话流', '学习创建AIoT对话流，实现智能对话和设备控制的结合', NULL, 12, 1, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(UUID(), @unit6_id, 'video', '意图识别节点', '掌握意图识别节点的配置，让智能体理解用户的真实意图', NULL, 10, 2, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(UUID(), @unit6_id, 'video', 'aiot意图识别', '学习在AIoT场景下进行意图识别，区分设备控制和普通对话', NULL, 12, 3, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

-- 单元7: 调试与优化 - 视频资源
INSERT INTO `pbl_resources` (`uuid`, `unit_id`, `type`, `title`, `description`, `url`, `duration`, `order`, `created_at`, `updated_at`)
VALUES
(UUID(), @unit7_id, 'video', '知识库节点', '学习优化知识库节点,实现情况组合控制', NULL, 25, 1, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

-- 单元8: 综合 - 视频资源
INSERT INTO `pbl_resources` (`uuid`, `unit_id`, `type`, `title`, `description`, `url`, `duration`, `order`, `created_at`, `updated_at`)
VALUES
(UUID(), @unit8_id, 'video', '智能家居系统综合实现', '综合运用所有功能,完成最终系统', NULL, 30, 1, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

-- ==========================================================================================================
-- 4. 创建任务
-- ==========================================================================================================

-- 单元1: 智能体入门 - 任务
INSERT INTO `pbl_tasks` (`uuid`, `unit_id`, `title`, `description`, `type`, `difficulty`, `estimated_time`, `requirements`, `prerequisites`, `created_at`, `updated_at`)
VALUES
(UUID(), @unit1_id, '任务1:创建"ai伙伴"智能体', '在Coze平台创建第一个智能体"ai伙伴",熟悉基本操作', 'coding', 'easy', '15分钟', 
    JSON_ARRAY(
        '注册登录Coze平台',
        '创建新智能体,命名为"ai伙伴"',
        '编写简单的提示词,让它能聊天',
        '测试对话功能',
        '体会智能体是如何工作的'
    ), 
    NULL, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),

(UUID(), @unit1_id, '任务2:创建"写作助手"智能体', '创建一个专门帮助写作的智能体', 'coding', 'easy', '15分钟',
    JSON_ARRAY(
        '创建新智能体,命名为"写作助手"',
        '编写提示词,让它专注于写作帮助',
        '测试不同类型的写作需求',
        '对比"ai伙伴"和"写作助手"的区别'
    ),
    NULL, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),

(UUID(), @unit1_id, '任务3:创建"智能家居助手"', '创建专门用于智能家居控制的助手', 'coding', 'medium', '20分钟',
    JSON_ARRAY(
        '创建新智能体,命名为"智能家居助手"',
        '编写提示词,定义它的角色:专注于智能家居控制、能识别设备类型(灯、空调、窗帘等)、友好简洁的对话风格',
        '测试基本对话:"打开灯"、"调节温度"、"关闭窗帘"',
        '记录:哪些指令能理解?哪些还不行?'
    ),
    NULL, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),

(UUID(), @unit1_id, '任务4:优化智能家居助手', '让助手能理解更多种说法', 'coding', 'medium', '12分钟',
    JSON_ARRAY(
        '测试多种表达方式:直接指令("开灯"、"关灯")、完整句子("请把客厅的灯打开")、隐含需求("太暗了"、"我冷")',
        '根据测试结果优化提示词',
        '添加场景识别(客厅、卧室、厨房)',
        '再次测试,看有没有改进'
    ),
    NULL, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

-- 单元2: 插件应用 - 任务(精简为3个)
INSERT INTO `pbl_tasks` (`uuid`, `unit_id`, `title`, `description`, `type`, `difficulty`, `estimated_time`, `requirements`, `prerequisites`, `created_at`, `updated_at`)
VALUES
(UUID(), @unit2_id, '任务1:添加和使用新闻插件', '学会为智能助手添加插件,并让它能获取实时信息', 'coding', 'medium', '20分钟',
    JSON_ARRAY(
        '了解插件的作用',
        '为智能助手添加头条新闻插件',
        '测试不同的问题:"今天有什么新闻?"、"今天天气怎么样?"、"播报最新消息"',
        '观察助手是如何自动使用插件的'
    ),
    NULL, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),

(UUID(), @unit2_id, '任务2:添加链接读取插件', '让助手能够读取网页内容,学习设备使用方法', 'coding', 'medium', '20分钟',
    JSON_ARRAY(
        '为助手添加链接读取插件',
        '找一个设备说明书的网页链接',
        '测试对话:"这是设备说明书[链接],帮我看看如何使用",观察助手能否读取并总结内容',
        '试试其他类型的网页链接'
    ),
    NULL, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),

(UUID(), @unit2_id, '任务3:添加图像识别插件', '让助手能够识别图片中的文字,比如设备标签、说明书等', 'coding', 'medium', '20分钟',
    JSON_ARRAY(
        '为助手添加OCR图像识别插件',
        '准备测试图片(可以拍摄):产品标签照片、说明书页面照片',
        '上传图片,让助手识别并解释内容',
        '测试不同的图片,总结识别效果'
    ),
    NULL, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

-- 单元3: 连接物理世界 - AIoT设备接入 - 任务
INSERT INTO `pbl_tasks` (`uuid`, `unit_id`, `title`, `description`, `type`, `difficulty`, `estimated_time`, `requirements`, `prerequisites`, `created_at`, `updated_at`)
VALUES
(UUID(), @unit3_id, '任务1:完成AIOT设备配置流程', '把第一个物理设备接入系统。建议从智能灯开始', 'coding', 'hard', '30分钟',
    JSON_ARRAY(
        '设备准备:确认设备型号、准备设备说明文档',
        '设备注册:在Coze平台注册AIoT设备、配置设备参数',
        '连接测试:完成设备初始化、测试设备连接状态',
        '记录:记录设备信息(ID、类型等)、记录遇到的问题'
    ),
    NULL, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),

(UUID(), @unit3_id, '任务2:创建一个能够远程控制设备端口、读取传感器数据的AIoT智能体', '让用户的语音指令能够真正控制灯光', 'coding', 'hard', '35分钟',
    JSON_ARRAY(
        '第一步:创建AIoT智能体,关联已配置的设备',
        '第二步:实现基础控制-用户:"开灯"→灯亮、用户:"关灯"→灯灭,测试不同说法,验证设备真实响应',
        '第三步:添加状态读取-读取设备当前状态(开/关),让助手能回答"现在灯是开着的还是关着的?"',
        '第四步:测试-完整场景测试,处理异常(设备离线怎么办)'
    ),
    NULL, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

-- 单元4: 知识库 - 任务
INSERT INTO `pbl_tasks` (`uuid`, `unit_id`, `title`, `description`, `type`, `difficulty`, `estimated_time`, `requirements`, `prerequisites`, `created_at`, `updated_at`)
VALUES
(UUID(), @unit4_id, '任务1:创建文本格式的知识库', '整理设备知识并创建知识库', 'coding', 'medium', '25分钟',
    JSON_ARRAY(
        '第一步:收集知识-收集设备资料(产品说明书、使用手册、常见问题)',
        '第二步:整理知识-按照结构组织(设备信息、使用说明、使用技巧)',
        '第三步:编写知识文档-以智能灯为例编写基本信息、使用方法、常见问题'
    ),
    NULL, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),

(UUID(), @unit4_id, '任务2:创建一个学科类知识库', '在平台上创建知识库', 'coding', 'medium', '20分钟',
    JSON_ARRAY(
        '在Coze平台创建知识库',
        '命名为"智能家居设备知识库"',
        '导入整理好的知识文档',
        '测试知识检索:搜索"智能灯如何重置"、搜索"节能技巧"'
    ),
    NULL, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),

(UUID(), @unit4_id, '任务3:为AIoT智能体添加知识库内容', '让智能助手能使用知识库回答问题', 'coding', 'medium', '20分钟',
    JSON_ARRAY(
        '第一步:关联知识库-在智能助手配置中关联知识库,设置如何调用知识库',
        '第二步:测试知识问答-设备使用问题("智能灯如何配对?")、故障排查("设备离线了怎么办?")、建议咨询("如何节省电费?")',
        '第三步:优化-让助手能结合知识和控制'
    ),
    NULL, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

-- 单元5: 工作流 - 任务(精简为3个)
INSERT INTO `pbl_tasks` (`uuid`, `unit_id`, `title`, `description`, `type`, `difficulty`, `estimated_time`, `requirements`, `prerequisites`, `created_at`, `updated_at`)
VALUES
(UUID(), @unit5_id, '任务1:创建"回家模式"工作流', '创建第一个场景自动化工作流,实现一句话触发多个设备控制', 'coding', 'medium', '25分钟',
    JSON_ARRAY(
        '第一步:场景分析-分析"回家"场景需要哪些操作(开玄关灯、开客厅主灯、根据温度决定是否开空调、播放欢迎消息)',
        '第二步:创建工作流-创建名为"回家模式"的工作流,添加开始节点设置触发词,添加设备控制节点,添加结束节点返回消息',
        '第三步:测试-测试触发效果,观察各个设备的响应,优化执行顺序'
    ),
    NULL, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),

(UUID(), @unit5_id, '任务2:创建"睡眠模式"工作流', '创建睡眠场景,实现一句话完成睡前准备', 'coding', 'medium', '20分钟',
    JSON_ARRAY(
        '第一步:场景设计-睡眠场景流程(关闭所有主灯、调低空调温度、拉上窗帘、开启夜灯)',
        '第二步:实现工作流-创建"睡眠模式"工作流,配置触发词("晚安"、"睡觉了"),添加控制节点,测试完整流程'
    ),
    NULL, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),

(UUID(), @unit5_id, '任务3:创建智能决策工作流', '使用大模型节点实现智能决策,让场景根据情况自动调整', 'coding', 'hard', '15分钟',
    JSON_ARRAY(
        '在"回家模式"工作流中添加大模型节点',
        '配置决策逻辑:获取当前温度、判断是否需要开空调、决定空调温度',
        '测试不同温度下的响应'
    ),
    NULL, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

-- 单元6: 对话流 - 任务
INSERT INTO `pbl_tasks` (`uuid`, `unit_id`, `title`, `description`, `type`, `difficulty`, `estimated_time`, `requirements`, `prerequisites`, `created_at`, `updated_at`)
VALUES
(UUID(), @unit6_id, '任务1:搭建一个AIoT对话流来控制设备', '创建能识别用户意图的对话流', 'coding', 'hard', '25分钟',
    JSON_ARRAY(
        '第一步:定义常见意图-场景触发(回家意图、睡眠意图)、环境调节(温度调节、光线调节)、设备控制(开关类)',
        '第二步:创建对话流-创建AIoT对话流,添加意图识别节点,配置意图和动作的对应关系',
        '第三步:测试-测试各种表达("我到家了"→触发回家场景,"我冷了"→提高温度,"太暗了"→开灯)'
    ),
    NULL, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),

(UUID(), @unit6_id, '任务2:为智能体添加两个不同的意图', '实现意图到动作的智能映射', 'coding', 'hard', '23分钟',
    JSON_ARRAY(
        '意图1:温度调节-用户说"我冷了",系统识别意图、获取当前温度、决策并执行、反馈',
        '意图2:光线调节-用户说"太暗了",系统识别意图、获取当前灯光状态、决策并执行、反馈',
        '实现步骤:为每个意图添加识别规则,配置动作执行,测试各种情况'
    ),
    NULL, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),

(UUID(), @unit6_id, '任务3:实现智能意图路由', '让智能体能根据不同意图自动选择合适的响应方式', 'coding', 'hard', '18分钟',
    JSON_ARRAY(
        '第一步:分析意图类型-控制类意图(场景触发、设备控制、环境调节)和查询类意图(信息查询、知识问答、日常闲聊)',
        '第二步:实现智能路由-添加意图识别节点,配置不同意图的处理方式,设置合适的反馈信息',
        '第三步:测试混合场景-测试场景触发、信息查询、环境调节等不同类型的用户请求'
    ),
    NULL, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

-- 单元7: 调试与优化 - 任务
INSERT INTO `pbl_tasks` (`uuid`, `unit_id`, `title`, `description`, `type`, `difficulty`, `estimated_time`, `requirements`, `prerequisites`, `created_at`, `updated_at`)
VALUES
(UUID(), @unit7_id, '任务1:aiot智能体根据不同情境组合控制设备', '让系统能根据不同情况做出不同响应', 'coding', 'hard', '75分钟',
    JSON_ARRAY(
        '第一步:定义情况-时间(早上、中午、晚上、深夜)、季节(春夏秋冬)、天气(晴天、雨天)',
        '第二步:设计策略-场景"回家模式"的自适应(夏天炎热天、冬天寒冷天、春天舒适天)',
        '第三步:实现-获取当前情况信息,根据情况选择策略,执行控制,测试不同情况',
        '第四步:优化知识库-补充情况相关知识,优化知识检索,测试优化效果'
    ),
    NULL, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

-- 单元8: 综合 - 任务
INSERT INTO `pbl_tasks` (`uuid`, `unit_id`, `title`, `description`, `type`, `difficulty`, `estimated_time`, `requirements`, `prerequisites`, `created_at`, `updated_at`)
VALUES
(UUID(), @unit8_id, '任务1:系统功能整合与测试', '整合所有功能,确保协同工作', 'coding', 'hard', '30分钟',
    JSON_ARRAY(
        '第一步:功能检查-确认核心功能都能工作(自然语言对话、插件能力、设备控制、知识库问答、场景工作流、意图识别、情况判断)',
        '第二步:综合场景测试-设计完整的使用场景测试(下班回家场景)',
        '第三步:问题修复-记录测试中发现的问题,分析问题原因,修复并重新测试'
    ),
    NULL, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),

(UUID(), @unit8_id, '任务2:系统优化', '优化系统,让它更好用', 'coding', 'medium', '20分钟',
    JSON_ARRAY(
        '响应速度:确保快速响应',
        '反馈信息:给出清晰的反馈',
        '错误处理:处理异常情况',
        '用户体验:优化对话体验'
    ),
    NULL, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),

(UUID(), @unit8_id, '任务3:项目文档', '整理项目文档', 'design', 'medium', '25分钟',
    JSON_ARRAY(
        '系统介绍:系统能做什么',
        '使用说明:如何使用',
        '功能列表:有哪些功能',
        '常见问题:遇到问题怎么办'
    ),
    NULL, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

-- ==========================================================================================================
-- 5. 提交事务
-- ==========================================================================================================

-- 恢复外键检查
SET FOREIGN_KEY_CHECKS = 1;

-- 提交事务
COMMIT;

-- ==========================================================================================================
-- 6. 验证数据
-- ==========================================================================================================

-- 查询创建的课程
SELECT 
    '课程创建验证' AS info_type,
    id,
    title,
    difficulty,
    duration,
    status
FROM pbl_courses
WHERE title = '智能家居控制智能体';

-- 查询创建的单元数量
SELECT 
    '单元创建验证' AS info_type,
    COUNT(*) AS unit_count,
    @course_id AS course_id
FROM pbl_units
WHERE course_id = @course_id;

-- 查询创建的资源数量
SELECT 
    '资源创建验证' AS info_type,
    u.title AS unit_title,
    COUNT(r.id) AS resource_count
FROM pbl_units u
LEFT JOIN pbl_resources r ON u.id = r.unit_id
WHERE u.course_id = @course_id
GROUP BY u.id, u.title
ORDER BY u.order;

-- 查询创建的任务数量
SELECT 
    '任务创建验证' AS info_type,
    u.title AS unit_title,
    COUNT(t.id) AS task_count
FROM pbl_units u
LEFT JOIN pbl_tasks t ON u.id = t.unit_id
WHERE u.course_id = @course_id
GROUP BY u.id, u.title
ORDER BY u.order;

-- 统计总数
SELECT 
    '数据统计汇总' AS info_type,
    (SELECT COUNT(*) FROM pbl_courses WHERE id = @course_id) AS course_count,
    (SELECT COUNT(*) FROM pbl_units WHERE course_id = @course_id) AS unit_count,
    (SELECT COUNT(*) FROM pbl_resources r JOIN pbl_units u ON r.unit_id = u.id WHERE u.course_id = @course_id) AS resource_count,
    (SELECT COUNT(*) FROM pbl_tasks t JOIN pbl_units u ON t.unit_id = u.id WHERE u.course_id = @course_id) AS task_count;

-- ==========================================================================================================
-- 执行完成信息
-- ==========================================================================================================

SELECT '==========================================================================================================' AS ' ';
SELECT '智能家居控制智能体课程数据初始化完成！' AS '状态';
SELECT '课程包含 8 个单元，涵盖从智能体基础到综合应用的完整学习路径' AS '说明';
SELECT '==========================================================================================================' AS ' ';

-- ==========================================================================================================
-- 脚本结束
-- ==========================================================================================================
