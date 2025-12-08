-- ========================================
-- 智能家居 AI Agent PBL 课程样例数据
-- ========================================
-- 此脚本为"EcoHome - AI Agent 驱动的智能家居中控"PBL课程创建完整的样例数据
-- 包括：课程、单元、学习资源、学习任务
-- 主题：AI Agent 开发 + 物联网 + 智能家居
-- ========================================

-- 课程UUID使用固定值，方便后续引用
SET @course_uuid = 'b2c3d4e5-f6a7-8901-bcde-f12345678901';

-- ========================================
-- 1. 插入课程基本信息
-- ========================================
INSERT INTO pbl_courses (
    uuid, 
    title, 
    description, 
    difficulty, 
    duration, 
    status,
    cover_image
) VALUES (
    @course_uuid,
    'EcoHome - AI Agent 驱动的智能家居中控实战',
    '利用 Coze 平台搭建一个具备自然语言理解能力的"管家智能体" Jarvis-Lite，它可以理解复杂的模糊指令，并自主决策调用 API 控制家里的设备，甚至根据环境自动执行任务。学生将掌握 AI Agent 核心概念、物联网设备接入、自然语言处理、系统集成等全链路技能。',
    'intermediate',
    '64小时',
    'published',
    '/assets/courses/smart-home/cover.jpg'
);

-- 获取插入的课程ID
SET @course_id = LAST_INSERT_ID();

-- ========================================
-- 2. 插入课程单元
-- ========================================

-- 单元1: 智能体基础与扣子平台入门
SET @unit1_uuid = UUID();
INSERT INTO pbl_units (
    uuid,
    course_id,
    title,
    description,
    `order`,
    status,
    learning_guide
) VALUES (
    @unit1_uuid,
    @course_id,
    '智能体基础与扣子平台入门',
    '了解 AI Agent 的核心概念，学习 Coze 平台的使用，掌握提示词工程基础，创建你的第一个智能体。',
    1,
    'available',
    JSON_OBJECT(
        'guide', '在这个单元中，你将：\n1. 理解 AI Agent 的基本概念和架构（LLM + Memory + Tools + Planning）\n2. 学习 Coze 平台的基本操作\n3. 掌握 RTF 提示词框架\n4. 创建并配置你的第一个智能管家 Bot',
        'estimatedTime', '8小时'
    )
);
SET @unit1_id = LAST_INSERT_ID();

-- 单元2: 硬件设备接入与通信协议
SET @unit2_uuid = UUID();
INSERT INTO pbl_units (
    uuid,
    course_id,
    title,
    description,
    `order`,
    status,
    learning_guide
) VALUES (
    @unit2_uuid,
    @course_id,
    '硬件设备接入与通信协议',
    '学习物联网设备接入方法，掌握 HTTP 和 MQTT 通信协议，实现智能家居设备的远程控制。',
    2,
    'available',
    JSON_OBJECT(
        'guide', '在这个单元中，你将：\n1. 了解智能家居设备的接入标准和协议\n2. 学习 HTTP API 和 MQTT 协议的使用\n3. 实现设备状态查询和控制功能\n4. 搭建简单的设备模拟器进行测试',
        'estimatedTime', '8小时'
    )
);
SET @unit2_id = LAST_INSERT_ID();

-- 单元3: 智能体框架与决策引擎
SET @unit3_uuid = UUID();
INSERT INTO pbl_units (
    uuid,
    course_id,
    title,
    description,
    `order`,
    status,
    learning_guide
) VALUES (
    @unit3_uuid,
    @course_id,
    '智能体框架与决策引擎',
    '深入学习智能体的架构设计，开发意图识别和决策引擎，让 Agent 能够理解用户指令并自主决策。',
    3,
    'available',
    JSON_OBJECT(
        'guide', '在这个单元中，你将：\n1. 设计智能体的整体架构和数据流\n2. 实现意图识别和实体抽取功能\n3. 开发决策引擎和工作流编排\n4. 集成工具和插件到智能体中',
        'estimatedTime', '12小时'
    )
);
SET @unit3_id = LAST_INSERT_ID();

-- 单元4: 自然语言处理与语音交互
SET @unit4_uuid = UUID();
INSERT INTO pbl_units (
    uuid,
    course_id,
    title,
    description,
    `order`,
    status,
    learning_guide
) VALUES (
    @unit4_uuid,
    @course_id,
    '自然语言处理与语音交互',
    '提升智能体的自然语言理解能力，集成语音识别和语音合成，实现多模态交互。',
    4,
    'available',
    JSON_OBJECT(
        'guide', '在这个单元中，你将：\n1. 优化 NLU（自然语言理解）能力\n2. 集成语音识别（ASR）服务\n3. 集成语音合成（TTS）服务\n4. 实现语音交互完整流程',
        'estimatedTime', '12小时'
    )
);
SET @unit4_id = LAST_INSERT_ID();

-- 单元5: 用户界面与交互设计
SET @unit5_uuid = UUID();
INSERT INTO pbl_units (
    uuid,
    course_id,
    title,
    description,
    `order`,
    status,
    learning_guide
) VALUES (
    @unit5_uuid,
    @course_id,
    '用户界面与交互设计',
    '设计并开发智能家居控制的可视化界面，对接 AI Agent API，提升用户体验。',
    5,
    'available',
    JSON_OBJECT(
        'guide', '在这个单元中，你将：\n1. 设计智能家居控制界面原型\n2. 使用 Vue.js 开发前端应用\n3. 对接 Coze Bot API\n4. 实现设备状态可视化和交互控制',
        'estimatedTime', '8小时'
    )
);
SET @unit5_id = LAST_INSERT_ID();

-- 单元6: 场景联动与自动化
SET @unit6_uuid = UUID();
INSERT INTO pbl_units (
    uuid,
    course_id,
    title,
    description,
    `order`,
    status,
    learning_guide
) VALUES (
    @unit6_uuid,
    @course_id,
    '场景联动与自动化',
    '设计和实现智能场景联动，让智能体根据环境自动执行任务，提升智能化水平。',
    6,
    'available',
    JSON_OBJECT(
        'guide', '在这个单元中，你将：\n1. 设计常见的智能场景（回家模式、离家模式、睡眠模式等）\n2. 实现基于时间和条件的自动化规则\n3. 开发场景编辑器\n4. 实现智能推荐场景',
        'estimatedTime', '8小时'
    )
);
SET @unit6_id = LAST_INSERT_ID();

-- 单元7: 安全与隐私保护
SET @unit7_uuid = UUID();
INSERT INTO pbl_units (
    uuid,
    course_id,
    title,
    description,
    `order`,
    status,
    learning_guide
) VALUES (
    @unit7_uuid,
    @course_id,
    '安全与隐私保护',
    '学习智能家居系统的安全威胁和防护措施，实现身份认证、权限控制和数据加密。',
    7,
    'available',
    JSON_OBJECT(
        'guide', '在这个单元中，你将：\n1. 了解智能家居系统的安全威胁\n2. 实现用户身份认证和授权\n3. 配置设备访问权限控制\n4. 实现敏感数据加密存储',
        'estimatedTime', '8小时'
    )
);
SET @unit7_id = LAST_INSERT_ID();

-- 单元8: 系统集成与项目部署
SET @unit8_uuid = UUID();
INSERT INTO pbl_units (
    uuid,
    course_id,
    title,
    description,
    `order`,
    status,
    learning_guide
) VALUES (
    @unit8_uuid,
    @course_id,
    '系统集成与项目部署',
    '完成系统的全链路集成，进行测试和优化，最终部署上线并进行项目展示。',
    8,
    'available',
    JSON_OBJECT(
        'guide', '在这个单元中，你将：\n1. 完成所有模块的集成测试\n2. 进行系统性能优化\n3. 部署到生产环境\n4. 准备项目展示和答辩',
        'estimatedTime', '8小时'
    )
);
SET @unit8_id = LAST_INSERT_ID();

-- ========================================
-- 3. 插入学习资源
-- ========================================

-- 单元1的资源
INSERT INTO pbl_resources (uuid, unit_id, type, title, url, content, duration, `order`) VALUES
(UUID(), @unit1_id, 'video', 'Agent 101：从 ChatGPT 到智能体', '/resources/unit1/agent-introduction.mp4', '了解什么是 AI Agent（智能体），它与普通聊天机器人的区别，以及 LLM + Memory + Tools + Planning 的核心架构', 10, 1),
(UUID(), @unit1_id, 'video', 'Coze 平台保姆级教程', '/resources/unit1/coze-tutorial.mp4', '详细演示 Coze 平台的注册、Bot 创建、配置等基本操作', 20, 2),
(UUID(), @unit1_id, 'document', 'RTF 提示词框架详解', '/resources/unit1/rtf-framework.pdf', '介绍高效 Prompt 编写的 RTF 框架：Role（角色）、Task（任务）、Format（格式）', NULL, 3),
(UUID(), @unit1_id, 'document', '智能体开发最佳实践', '/resources/unit1/agent-best-practices.pdf', '总结智能体开发的常见模式、最佳实践和常见陷阱', NULL, 4),
(UUID(), @unit1_id, 'link', 'Coze 官方文档', 'https://www.coze.com/docs', 'Coze 平台的官方文档和 API 参考', NULL, 5);

-- 单元2的资源
INSERT INTO pbl_resources (uuid, unit_id, type, title, url, content, duration, `order`) VALUES
(UUID(), @unit2_id, 'video', '物联网设备接入协议详解', '/resources/unit2/iot-protocols.mp4', '介绍智能家居常用的通信协议：HTTP、MQTT、CoAP、Zigbee 等', 18, 1),
(UUID(), @unit2_id, 'video', 'HTTP API 设计与实现', '/resources/unit2/http-api-tutorial.mp4', '讲解如何设计和实现 RESTful API 来控制智能设备', 22, 2),
(UUID(), @unit2_id, 'video', 'MQTT 协议实战', '/resources/unit2/mqtt-tutorial.mp4', '演示如何使用 MQTT 协议实现设备的发布订阅通信', 20, 3),
(UUID(), @unit2_id, 'document', '智能家居设备接入规范', '/resources/unit2/device-integration-standard.pdf', '智能家居设备接入的标准和规范', NULL, 4),
(UUID(), @unit2_id, 'document', '设备模拟器代码示例', '/resources/unit2/device-simulator.zip', '提供智能灯、空调、窗帘等设备的模拟器代码', NULL, 5);

-- 单元3的资源
INSERT INTO pbl_resources (uuid, unit_id, type, title, url, content, duration, `order`) VALUES
(UUID(), @unit3_id, 'video', '智能体架构设计', '/resources/unit3/agent-architecture.mp4', '深入讲解智能体的模块划分、数据流设计和组件交互', 25, 1),
(UUID(), @unit3_id, 'video', '意图识别与实体抽取', '/resources/unit3/nlu-tutorial.mp4', '介绍如何实现用户意图识别和关键信息提取', 20, 2),
(UUID(), @unit3_id, 'video', '决策引擎开发', '/resources/unit3/decision-engine.mp4', '讲解如何开发决策引擎，让智能体根据意图选择合适的工具和动作', 22, 3),
(UUID(), @unit3_id, 'document', '工作流编排指南', '/resources/unit3/workflow-orchestration.pdf', '介绍如何设计和编排复杂的工作流', NULL, 4),
(UUID(), @unit3_id, 'document', 'Coze 插件开发文档', '/resources/unit3/coze-plugin-dev.pdf', '详细说明如何开发自定义插件并集成到 Coze', NULL, 5);

-- 单元4的资源
INSERT INTO pbl_resources (uuid, unit_id, type, title, url, content, duration, `order`) VALUES
(UUID(), @unit4_id, 'video', '自然语言理解进阶', '/resources/unit4/advanced-nlu.mp4', '介绍上下文理解、多轮对话、歧义消解等高级 NLU 技术', 23, 1),
(UUID(), @unit4_id, 'video', '语音识别服务集成', '/resources/unit4/asr-integration.mp4', '演示如何集成阿里云、百度等语音识别服务', 18, 2),
(UUID(), @unit4_id, 'video', '语音合成服务集成', '/resources/unit4/tts-integration.mp4', '讲解如何集成语音合成服务，让智能体会说话', 16, 3),
(UUID(), @unit4_id, 'document', '多模态交互设计', '/resources/unit4/multimodal-interaction.pdf', '介绍如何设计文字、语音、图像等多模态交互体验', NULL, 4),
(UUID(), @unit4_id, 'document', '对话管理最佳实践', '/resources/unit4/dialogue-management.pdf', '分享对话状态管理和上下文维护的最佳实践', NULL, 5);

-- 单元5的资源
INSERT INTO pbl_resources (uuid, unit_id, type, title, url, content, duration, `order`) VALUES
(UUID(), @unit5_id, 'video', 'Vue.js 快速入门', '/resources/unit5/vue-quickstart.mp4', '快速上手 Vue.js 3.x 的核心概念和基本用法', 25, 1),
(UUID(), @unit5_id, 'video', '智能家居界面设计', '/resources/unit5/ui-design.mp4', '分享智能家居控制界面的设计原则和常见模式', 20, 2),
(UUID(), @unit5_id, 'video', 'Coze API 对接实战', '/resources/unit5/coze-api-tutorial.mp4', '演示如何在前端调用 Coze Bot API 实现对话功能', 22, 3),
(UUID(), @unit5_id, 'document', 'Element Plus 组件库文档', '/resources/unit5/element-plus.pdf', '常用 UI 组件的使用说明和示例代码', NULL, 4),
(UUID(), @unit5_id, 'document', '前端项目脚手架', '/resources/unit5/frontend-template.zip', '提供预配置的 Vue 3 + Vite + Element Plus 项目模板', NULL, 5);

-- 单元6的资源
INSERT INTO pbl_resources (uuid, unit_id, type, title, url, content, duration, `order`) VALUES
(UUID(), @unit6_id, 'video', '智能场景设计思路', '/resources/unit6/scene-design.mp4', '介绍如何设计实用的智能场景：回家模式、离家模式、睡眠模式等', 18, 1),
(UUID(), @unit6_id, 'video', '自动化规则引擎', '/resources/unit6/automation-engine.mp4', '讲解如何实现基于时间、条件、事件的自动化规则引擎', 24, 2),
(UUID(), @unit6_id, 'video', '场景编辑器开发', '/resources/unit6/scene-editor.mp4', '演示如何开发可视化的场景编辑器，让用户自定义场景', 20, 3),
(UUID(), @unit6_id, 'document', '智能推荐算法', '/resources/unit6/recommendation-algorithm.pdf', '介绍如何根据用户行为推荐合适的场景', NULL, 4);

-- 单元7的资源
INSERT INTO pbl_resources (uuid, unit_id, type, title, url, content, duration, `order`) VALUES
(UUID(), @unit7_id, 'video', '智能家居安全威胁分析', '/resources/unit7/security-threats.mp4', '分析智能家居系统面临的常见安全威胁和攻击手段', 20, 1),
(UUID(), @unit7_id, 'video', 'JWT 身份认证实现', '/resources/unit7/jwt-authentication.mp4', '演示如何使用 JWT 实现用户身份认证和授权', 22, 2),
(UUID(), @unit7_id, 'video', '数据加密与安全存储', '/resources/unit7/data-encryption.mp4', '讲解如何对敏感数据进行加密存储和传输', 18, 3),
(UUID(), @unit7_id, 'document', '权限控制模型', '/resources/unit7/access-control.pdf', '介绍 RBAC、ABAC 等权限控制模型及其实现', NULL, 4),
(UUID(), @unit7_id, 'document', '安全测试清单', '/resources/unit7/security-checklist.pdf', '提供完整的安全测试检查清单', NULL, 5);

-- 单元8的资源
INSERT INTO pbl_resources (uuid, unit_id, type, title, url, content, duration, `order`) VALUES
(UUID(), @unit8_id, 'video', '系统集成测试策略', '/resources/unit8/integration-testing.mp4', '介绍如何进行端到端的集成测试，确保各模块协同工作', 20, 1),
(UUID(), @unit8_id, 'video', '性能优化技巧', '/resources/unit8/performance-optimization.mp4', '分享前端和后端的性能优化方法和工具', 22, 2),
(UUID(), @unit8_id, 'video', 'Docker 容器化部署', '/resources/unit8/docker-deployment.mp4', '演示如何使用 Docker 进行容器化部署', 25, 3),
(UUID(), @unit8_id, 'document', '项目展示 PPT 模板', '/resources/unit8/presentation-template.pptx', '提供专业的项目展示 PPT 模板', NULL, 4),
(UUID(), @unit8_id, 'document', '技术文档编写规范', '/resources/unit8/documentation-standard.pdf', '介绍如何编写高质量的技术文档', NULL, 5);

-- ========================================
-- 4. 插入学习任务
-- ========================================

-- 单元1的任务
INSERT INTO pbl_tasks (uuid, unit_id, title, description, type, difficulty, estimated_time, requirements, prerequisites) VALUES
(UUID(), @unit1_id, 'Hello World：创建你的 Agent',
'访问 Coze 官网，注册账号并创建一个全新的 Bot，命名为 Jarvis-Lite（或你喜欢的名字）。',
'coding', 'easy', '30分钟',
JSON_ARRAY(
    '完成 Coze 账号注册',
    '创建 Bot，填写名称和简介',
    '生成并设置 Bot 头像',
    '提交 Bot ID 或创建截图'
),
NULL),

(UUID(), @unit1_id, '注入灵魂：编写人设 Prompt',
'使用 RTF 框架编写 Prompt，并填入"人设与回复逻辑"区域。让你的 Agent 知道自己是管家，而不是百科全书。',
'design', 'medium', '45分钟',
JSON_ARRAY(
    '编写包含 Role, Task, Format 的 Prompt',
    '设定"意图识别"技能',
    '在右侧预览窗口进行不少于 3 轮的对话测试',
    '提交 Prompt 内容和对话截图'
),
JSON_ARRAY('完成 Hello World 任务')),

(UUID(), @unit1_id, '初次调试',
'在预览窗口验证人设是否生效。尝试输入"你是谁？"、"把灯打开"等指令，观察它的反应。',
'analysis', 'easy', '20分钟',
JSON_ARRAY(
    '测试自我介绍功能',
    '测试设备控制指令（模拟）',
    '测试闲聊话题（验证约束条件）',
    '提交测试报告和对话记录'
),
JSON_ARRAY('完成人设 Prompt 编写')),

(UUID(), @unit1_id, '外挂大脑：知识库配置',
'创建"家庭设备说明书"知识库并上传文档，增强 Agent 的回答能力。',
'coding', 'medium', '40分钟',
JSON_ARRAY(
    '创建知识库并命名',
    '准备至少 3 个设备的说明文档',
    '上传文档到知识库',
    '测试知识库问答功能',
    '提交知识库配置截图和测试结果'
),
JSON_ARRAY('完成初次调试')),

(UUID(), @unit1_id, '初识插件',
'添加天气或时间插件，让 Agent 具备查询实时信息的能力。',
'coding', 'easy', '30分钟',
JSON_ARRAY(
    '浏览 Coze 插件市场',
    '添加天气插件或时间插件',
    '配置插件参数',
    '测试插件调用功能',
    '提交插件使用截图'
),
JSON_ARRAY('完成知识库配置')),

(UUID(), @unit1_id, '记忆管理与发布',
'设置数据库变量记住用户偏好，并将 Agent 发布到豆包或微信客服。',
'deployment', 'medium', '45分钟',
JSON_ARRAY(
    '创建数据库变量存储用户偏好',
    '实现用户偏好的读写逻辑',
    '测试记忆功能',
    '发布 Bot 到至少一个渠道',
    '提交发布链接或二维码'
),
JSON_ARRAY('完成插件配置'));

-- 单元2的任务
INSERT INTO pbl_tasks (uuid, unit_id, title, description, type, difficulty, estimated_time, requirements, prerequisites) VALUES
(UUID(), @unit2_id, '设计设备控制 API',
'设计智能灯、空调、窗帘等设备的 HTTP API 接口规范，包括状态查询和控制命令。',
'design', 'medium', '3小时',
JSON_ARRAY(
    '设计至少 3 种设备的 API 接口',
    '使用 RESTful 风格设计',
    '编写 API 文档（包含请求/响应示例）',
    '定义统一的错误码和响应格式',
    '提交 API 设计文档'
),
JSON_ARRAY('完成单元1所有任务')),

(UUID(), @unit2_id, '实现设备模拟器',
'使用 Python 或 Node.js 实现智能设备模拟器，模拟真实设备的行为和响应。',
'coding', 'hard', '5小时',
JSON_ARRAY(
    '实现至少 3 种设备的模拟器',
    '支持 HTTP API 接口',
    '模拟设备状态变化',
    '提供设备状态查询接口',
    '编写使用说明文档',
    '提交源代码和演示视频'
),
JSON_ARRAY('完成 API 设计')),

(UUID(), @unit2_id, '创建设备控制插件',
'在 Coze 平台创建自定义插件，让 Agent 能够调用设备控制 API。',
'coding', 'hard', '4小时',
JSON_ARRAY(
    '在 Coze 创建自定义插件',
    '配置插件 API 端点',
    '编写插件描述和参数说明',
    '测试插件功能',
    '将插件集成到 Agent',
    '提交插件配置和测试结果'
),
JSON_ARRAY('完成设备模拟器'));

-- 单元3的任务
INSERT INTO pbl_tasks (uuid, unit_id, title, description, type, difficulty, estimated_time, requirements, prerequisites) VALUES
(UUID(), @unit3_id, '设计智能体架构',
'设计智能家居管家的整体架构，包括感知层、认知层、决策层、执行层。绘制架构图并说明各层职责。',
'design', 'medium', '4小时',
JSON_ARRAY(
    '绘制完整的系统架构图',
    '定义各层的职责和接口',
    '设计数据流和控制流',
    '说明关键组件的实现方案',
    '提交架构设计文档'
),
JSON_ARRAY('完成单元2所有任务')),

(UUID(), @unit3_id, '实现意图识别引擎',
'开发意图识别模块，能够识别用户的控制指令、查询请求、场景切换等意图。',
'coding', 'hard', '6小时',
JSON_ARRAY(
    '定义至少 10 种用户意图',
    '实现意图识别算法',
    '实现实体抽取功能',
    '准备测试数据集并测试准确率',
    '准确率达到 85% 以上',
    '提交代码和测试报告'
),
JSON_ARRAY('完成架构设计')),

(UUID(), @unit3_id, '开发决策引擎',
'开发决策引擎，根据识别的意图选择合适的工具、生成执行计划。',
'coding', 'hard', '6小时',
JSON_ARRAY(
    '实现决策逻辑',
    '支持多步骤任务规划',
    '实现错误处理和重试机制',
    '集成到 Coze Bot 工作流',
    '测试复杂指令的处理',
    '提交代码和演示视频'
),
JSON_ARRAY('完成意图识别引擎'));

-- 单元4的任务
INSERT INTO pbl_tasks (uuid, unit_id, title, description, type, difficulty, estimated_time, requirements, prerequisites) VALUES
(UUID(), @unit4_id, '优化对话理解能力',
'优化 Agent 的 NLU 能力，支持上下文理解、多轮对话、模糊指令理解。',
'coding', 'hard', '5小时',
JSON_ARRAY(
    '实现上下文管理',
    '支持指代消解（"它"、"那个"等）',
    '处理模糊指令（"有点热" → 调低温度）',
    '测试多轮对话场景',
    '提交代码和测试案例'
),
JSON_ARRAY('完成单元3所有任务')),

(UUID(), @unit4_id, '集成语音识别',
'集成第三方语音识别服务（如阿里云、百度等），实现语音输入功能。',
'coding', 'medium', '4小时',
JSON_ARRAY(
    '选择并注册语音识别服务',
    '实现语音上传和识别',
    '处理识别结果并转发给 Agent',
    '测试识别准确率',
    '提交代码和演示视频'
),
JSON_ARRAY('完成对话理解优化')),

(UUID(), @unit4_id, '集成语音合成',
'集成语音合成服务，让 Agent 能够用语音回复用户。',
'coding', 'medium', '4小时',
JSON_ARRAY(
    '选择并注册语音合成服务',
    '实现文本到语音转换',
    '支持语音播放',
    '优化语音播放体验',
    '提交代码和演示视频'
),
JSON_ARRAY('完成语音识别集成'));

-- 单元5的任务
INSERT INTO pbl_tasks (uuid, unit_id, title, description, type, difficulty, estimated_time, requirements, prerequisites) VALUES
(UUID(), @unit5_id, '设计界面原型',
'使用 Figma 或 Sketch 设计智能家居控制界面的原型，包括设备控制、场景管理、对话交互等页面。',
'design', 'medium', '3小时',
JSON_ARRAY(
    '设计至少 5 个主要页面',
    '包含设备控制、场景管理、对话界面',
    '遵循良好的 UI/UX 设计原则',
    '考虑移动端适配',
    '提交设计稿或原型链接'
),
JSON_ARRAY('完成单元4所有任务')),

(UUID(), @unit5_id, '开发前端应用',
'使用 Vue.js + Element Plus 开发智能家居控制的前端应用。',
'coding', 'hard', '8小时',
JSON_ARRAY(
    '搭建 Vue 3 项目框架',
    '实现设备列表和控制界面',
    '实现场景管理界面',
    '实现对话交互界面',
    '响应式设计，支持移动端',
    '提交源代码和部署链接'
),
JSON_ARRAY('完成界面原型设计')),

(UUID(), @unit5_id, '对接 Coze Bot API',
'在前端应用中对接 Coze Bot API，实现与智能体的实时对话。',
'coding', 'medium', '3小时',
JSON_ARRAY(
    '实现 Coze API 调用',
    '处理流式响应',
    '实现消息历史记录',
    '处理错误和超时',
    '优化交互体验',
    '提交代码和测试报告'
),
JSON_ARRAY('完成前端应用开发'));

-- 单元6的任务
INSERT INTO pbl_tasks (uuid, unit_id, title, description, type, difficulty, estimated_time, requirements, prerequisites) VALUES
(UUID(), @unit6_id, '设计智能场景',
'设计至少 5 个实用的智能场景（如回家模式、离家模式、睡眠模式等），定义每个场景的触发条件和执行动作。',
'design', 'medium', '3小时',
JSON_ARRAY(
    '设计至少 5 个智能场景',
    '定义场景的触发条件',
    '定义场景的执行动作序列',
    '考虑场景之间的联动',
    '提交场景设计文档'
),
JSON_ARRAY('完成单元5所有任务')),

(UUID(), @unit6_id, '实现自动化规则引擎',
'开发自动化规则引擎，支持基于时间、条件、事件的自动化规则执行。',
'coding', 'hard', '6小时',
JSON_ARRAY(
    '实现规则定义和存储',
    '实现规则匹配和触发',
    '支持时间、条件、事件触发',
    '实现规则的启用/禁用',
    '测试规则引擎功能',
    '提交代码和测试报告'
),
JSON_ARRAY('完成场景设计')),

(UUID(), @unit6_id, '开发场景编辑器',
'开发可视化的场景编辑器，让用户可以自定义和编辑智能场景。',
'coding', 'hard', '5小时',
JSON_ARRAY(
    '实现场景的创建、编辑、删除',
    '实现触发条件的可视化配置',
    '实现执行动作的可视化配置',
    '实现场景的保存和加载',
    '提供场景模板',
    '提交代码和演示视频'
),
JSON_ARRAY('完成自动化规则引擎'));

-- 单元7的任务
INSERT INTO pbl_tasks (uuid, unit_id, title, description, type, difficulty, estimated_time, requirements, prerequisites) VALUES
(UUID(), @unit7_id, '安全威胁分析',
'分析智能家居系统可能面临的安全威胁，制定安全防护方案。',
'analysis', 'medium', '3小时',
JSON_ARRAY(
    '列出至少 10 种潜在安全威胁',
    '分析每种威胁的危害程度',
    '制定相应的防护措施',
    '绘制安全架构图',
    '提交安全分析报告'
),
JSON_ARRAY('完成单元6所有任务')),

(UUID(), @unit7_id, '实现身份认证',
'实现基于 JWT 的用户身份认证和授权机制。',
'coding', 'medium', '4小时',
JSON_ARRAY(
    '实现用户注册和登录',
    '实现 JWT token 生成和验证',
    '实现 token 刷新机制',
    '实现登出功能',
    '测试认证流程',
    '提交代码和测试报告'
),
JSON_ARRAY('完成安全威胁分析')),

(UUID(), @unit7_id, '实现权限控制',
'实现基于角色的权限控制（RBAC），区分管理员、家庭成员、访客等不同角色。',
'coding', 'hard', '5小时',
JSON_ARRAY(
    '定义用户角色和权限',
    '实现权限检查中间件',
    '实现设备访问权限控制',
    '实现场景操作权限控制',
    '测试权限控制功能',
    '提交代码和权限矩阵文档'
),
JSON_ARRAY('完成身份认证'));

-- 单元8的任务
INSERT INTO pbl_tasks (uuid, unit_id, title, description, type, difficulty, estimated_time, requirements, prerequisites) VALUES
(UUID(), @unit8_id, '系统集成测试',
'进行端到端的系统集成测试，确保所有模块协同工作正常。',
'analysis', 'hard', '5小时',
JSON_ARRAY(
    '编写集成测试用例',
    '测试所有核心功能',
    '测试异常场景和边界情况',
    '记录测试结果和发现的问题',
    '修复关键问题',
    '提交测试报告'
),
JSON_ARRAY('完成单元7所有任务')),

(UUID(), @unit8_id, '性能优化',
'对系统进行性能测试和优化，提升响应速度和用户体验。',
'coding', 'medium', '4小时',
JSON_ARRAY(
    '使用工具进行性能测试',
    '识别性能瓶颈',
    '优化至少 3 个性能指标',
    '提供优化前后对比数据',
    '提交优化报告'
),
JSON_ARRAY('完成系统集成测试')),

(UUID(), @unit8_id, '容器化部署',
'使用 Docker 对系统进行容器化，编写 docker-compose 配置文件，实现一键部署。',
'deployment', 'hard', '5小时',
JSON_ARRAY(
    '编写 Dockerfile',
    '编写 docker-compose.yml',
    '配置环境变量',
    '测试容器化部署',
    '编写部署文档',
    '提交配置文件和部署文档'
),
JSON_ARRAY('完成性能优化')),

(UUID(), @unit8_id, '项目展示与答辩',
'准备项目展示材料，进行成果汇报和答辩。',
'analysis', 'medium', '4小时',
JSON_ARRAY(
    '制作项目展示 PPT（至少 20 页）',
    '录制演示视频（5-8 分钟）',
    '准备技术文档',
    '进行现场演示',
    '回答提问',
    '获得评审认可'
),
JSON_ARRAY('完成容器化部署'));

-- ========================================
-- 完成
-- ========================================
-- 样例数据插入完成
-- 课程UUID: b2c3d4e5-f6a7-8901-bcde-f12345678901
-- 包含8个单元、39个学习资源、30个学习任务
