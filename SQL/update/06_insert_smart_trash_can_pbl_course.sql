-- ========================================
-- 智能垃圾桶 PBL 课程样例数据
-- ========================================
-- 此脚本为"智能垃圾桶"PBL课程创建完整的样例数据
-- 包括：课程、单元、学习资源、学习任务
-- 主题：硬件设计 + 智能体开发
-- ========================================

-- 课程UUID使用固定值，方便后续引用
SET @course_uuid = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890';

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
    '智能垃圾桶 - 硬件与AI的完美结合',
    '本课程将引导学生设计并实现一个智能垃圾桶系统。学生将学习如何进行硬件选型、电路设计、传感器集成，并开发一个智能体来实现垃圾分类识别、满溢检测等功能。通过这个项目，学生将掌握物联网硬件开发和AI智能体开发的核心技能。',
    'intermediate',
    '40小时',
    'published',
    '/assets/courses/smart-trash-can/cover.jpg'
);

-- 获取插入的课程ID
SET @course_id = LAST_INSERT_ID();

-- ========================================
-- 2. 插入课程单元
-- ========================================

-- 单元1: 项目需求分析与硬件选型
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
    '项目需求分析与硬件选型',
    '了解智能垃圾桶的功能需求，学习如何进行硬件需求分析和选型，为后续开发打下基础。',
    1,
    'available',
    JSON_OBJECT(
        'guide', '在这个单元中，你将：\n1. 分析智能垃圾桶的核心功能需求\n2. 学习常见传感器和开发板的特性\n3. 完成硬件选型方案设计',
        'estimatedTime', '4-6小时'
    )
);
SET @unit1_id = LAST_INSERT_ID();

-- 单元2: 硬件电路设计与组装
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
    '硬件电路设计与组装',
    '学习电路设计基础知识，设计智能垃圾桶的电路图，并完成硬件组装。',
    2,
    'available',
    JSON_OBJECT(
        'guide', '在这个单元中，你将：\n1. 学习基础电路设计原理\n2. 使用电路设计工具绘制原理图\n3. 完成硬件的物理组装和接线',
        'estimatedTime', '6-8小时'
    )
);
SET @unit2_id = LAST_INSERT_ID();

-- 单元3: 传感器集成与测试
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
    '传感器集成与测试',
    '集成各类传感器（超声波、重量、红外等），编写驱动程序，进行功能测试。',
    3,
    'available',
    JSON_OBJECT(
        'guide', '在这个单元中，你将：\n1. 学习传感器工作原理\n2. 编写传感器驱动程序\n3. 测试传感器功能并优化代码',
        'estimatedTime', '6-8小时'
    )
);
SET @unit3_id = LAST_INSERT_ID();

-- 单元4: 智能体开发基础
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
    '智能体开发基础',
    '学习智能体的基本概念、架构设计，掌握AI模型调用和决策逻辑开发。',
    4,
    'available',
    JSON_OBJECT(
        'guide', '在这个单元中，你将：\n1. 理解智能体的基本概念和架构\n2. 学习如何调用AI模型API\n3. 设计智能体的决策流程',
        'estimatedTime', '6-8小时'
    )
);
SET @unit4_id = LAST_INSERT_ID();

-- 单元5: 智能垃圾桶智能体实现
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
    '智能垃圾桶智能体实现',
    '开发智能垃圾桶的智能体，实现垃圾分类识别、满溢检测、语音提示等功能。',
    5,
    'available',
    JSON_OBJECT(
        'guide', '在这个单元中，你将：\n1. 实现图像识别功能进行垃圾分类\n2. 开发满溢检测和预警功能\n3. 集成语音交互功能',
        'estimatedTime', '8-10小时'
    )
);
SET @unit5_id = LAST_INSERT_ID();

-- 单元6: 系统集成与调试
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
    '系统集成与调试',
    '将硬件和智能体进行集成，完成系统级测试和性能优化。',
    6,
    'available',
    JSON_OBJECT(
        'guide', '在这个单元中，你将：\n1. 完成硬件和软件的集成\n2. 进行系统级功能测试\n3. 优化系统性能和用户体验',
        'estimatedTime', '6-8小时'
    )
);
SET @unit6_id = LAST_INSERT_ID();

-- 单元7: 项目展示与总结
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
    '项目展示与总结',
    '准备项目展示材料，进行成果汇报，总结项目经验和收获。',
    7,
    'available',
    JSON_OBJECT(
        'guide', '在这个单元中，你将：\n1. 制作项目展示PPT和演示视频\n2. 准备技术文档和用户手册\n3. 进行项目汇报和经验总结',
        'estimatedTime', '4-6小时'
    )
);
SET @unit7_id = LAST_INSERT_ID();

-- ========================================
-- 3. 插入学习资源
-- ========================================

-- 单元1的资源
INSERT INTO pbl_resources (uuid, unit_id, type, title, url, content, duration, `order`) VALUES
(UUID(), @unit1_id, 'video', '智能垃圾桶功能需求分析', '/resources/unit1/requirement-analysis.mp4', '介绍智能垃圾桶的核心功能、用户需求和技术要求', 15, 1),
(UUID(), @unit1_id, 'document', '常见传感器选型指南', '/resources/unit1/sensor-selection-guide.pdf', '详细介绍常见传感器的类型、特性、应用场景和选型要点', NULL, 2),
(UUID(), @unit1_id, 'document', '开发板选型对比', '/resources/unit1/dev-board-comparison.pdf', '对比Arduino、ESP32、树莓派等常见开发板的性能和适用场景', NULL, 3),
(UUID(), @unit1_id, 'link', '智能硬件设计案例库', 'https://example.com/hardware-cases', '提供多个智能硬件项目的设计案例和参考资料', NULL, 4);

-- 单元2的资源
INSERT INTO pbl_resources (uuid, unit_id, type, title, url, content, duration, `order`) VALUES
(UUID(), @unit2_id, 'video', '电路设计基础教程', '/resources/unit2/circuit-design-basics.mp4', '讲解电路设计的基本原理、常用元器件和设计方法', 25, 1),
(UUID(), @unit2_id, 'video', 'Fritzing电路设计工具使用', '/resources/unit2/fritzing-tutorial.mp4', '详细演示如何使用Fritzing进行电路原理图和PCB设计', 20, 2),
(UUID(), @unit2_id, 'document', '硬件组装指导手册', '/resources/unit2/assembly-guide.pdf', '提供详细的硬件组装步骤、注意事项和常见问题解决方案', NULL, 3),
(UUID(), @unit2_id, 'link', '元器件采购参考', 'https://example.com/components-shop', '推荐的元器件采购渠道和价格参考', NULL, 4);

-- 单元3的资源
INSERT INTO pbl_resources (uuid, unit_id, type, title, url, content, duration, `order`) VALUES
(UUID(), @unit3_id, 'video', '超声波传感器原理与应用', '/resources/unit3/ultrasonic-sensor.mp4', '介绍超声波传感器的工作原理、接线方法和编程实现', 18, 1),
(UUID(), @unit3_id, 'video', '重量传感器与HX711模块', '/resources/unit3/weight-sensor.mp4', '讲解重量传感器的使用和HX711放大模块的配置', 15, 2),
(UUID(), @unit3_id, 'document', 'Arduino编程基础', '/resources/unit3/arduino-programming.pdf', 'Arduino编程语言基础、常用库函数和调试技巧', NULL, 3),
(UUID(), @unit3_id, 'document', '传感器驱动代码示例', '/resources/unit3/sensor-drivers.zip', '提供完整的传感器驱动代码示例和测试程序（注：实际应为link或document类型）', NULL, 4);

-- 单元4的资源
INSERT INTO pbl_resources (uuid, unit_id, type, title, url, content, duration, `order`) VALUES
(UUID(), @unit4_id, 'video', '智能体架构设计入门', '/resources/unit4/agent-architecture.mp4', '介绍智能体的基本概念、设计模式和架构原则', 22, 1),
(UUID(), @unit4_id, 'video', 'AI模型API调用实战', '/resources/unit4/ai-api-tutorial.mp4', '演示如何调用常见AI模型API（GPT、视觉识别等）', 20, 2),
(UUID(), @unit4_id, 'document', 'Python智能体开发指南', '/resources/unit4/python-agent-dev.pdf', '详细介绍使用Python开发智能体的方法和最佳实践', NULL, 3),
(UUID(), @unit4_id, 'document', '简单智能体示例代码', '/resources/unit4/simple-agent-demo.zip', '提供一个简单的智能体示例项目，包含完整代码和文档', NULL, 4);

-- 单元5的资源
INSERT INTO pbl_resources (uuid, unit_id, type, title, url, content, duration, `order`) VALUES
(UUID(), @unit5_id, 'video', '图像识别实现垃圾分类', '/resources/unit5/image-classification.mp4', '讲解如何使用图像识别技术实现垃圾自动分类', 25, 1),
(UUID(), @unit5_id, 'video', '满溢检测算法设计', '/resources/unit5/overflow-detection.mp4', '介绍垃圾桶满溢检测的多种实现方案和算法优化', 18, 2),
(UUID(), @unit5_id, 'document', '语音交互集成方案', '/resources/unit5/voice-interaction.pdf', '详细介绍如何集成语音合成和语音识别功能', NULL, 3),
(UUID(), @unit5_id, 'document', '智能垃圾桶智能体完整代码', '/resources/unit5/smart-trash-agent.zip', '提供智能垃圾桶智能体的参考实现代码', NULL, 4);

-- 单元6的资源
INSERT INTO pbl_resources (uuid, unit_id, type, title, url, content, duration, `order`) VALUES
(UUID(), @unit6_id, 'video', '硬件与软件集成方法', '/resources/unit6/hw-sw-integration.mp4', '讲解如何将硬件设备与智能体软件进行集成', 20, 1),
(UUID(), @unit6_id, 'document', '系统测试与调试指南', '/resources/unit6/testing-debugging.pdf', '提供系统测试方法、调试技巧和常见问题解决方案', NULL, 2),
(UUID(), @unit6_id, 'document', '性能优化最佳实践', '/resources/unit6/performance-optimization.pdf', '介绍系统性能优化的方法和技巧', NULL, 3);

-- 单元7的资源
INSERT INTO pbl_resources (uuid, unit_id, type, title, url, content, duration, `order`) VALUES
(UUID(), @unit7_id, 'video', '项目展示PPT制作技巧', '/resources/unit7/ppt-tips.mp4', '分享如何制作高质量的项目展示PPT', 12, 1),
(UUID(), @unit7_id, 'document', '技术文档编写规范', '/resources/unit7/tech-doc-standard.pdf', '介绍技术文档的结构、内容要求和编写规范', NULL, 2),
(UUID(), @unit7_id, 'document', '项目汇报评分标准', '/resources/unit7/presentation-rubric.pdf', '说明项目汇报的评分标准和评价维度', NULL, 3);

-- ========================================
-- 4. 插入学习任务
-- ========================================

-- 单元1的任务
INSERT INTO pbl_tasks (uuid, unit_id, title, description, type, difficulty, estimated_time, requirements, prerequisites) VALUES
(UUID(), @unit1_id, '智能垃圾桶需求分析报告', 
'分析智能垃圾桶的用户需求、功能需求和技术需求，撰写详细的需求分析报告。报告应包括：目标用户分析、核心功能列表、技术可行性分析、成本预算等内容。',
'analysis', 'easy', '3小时', 
JSON_ARRAY(
    '需求分析报告文档（PDF或Word格式）',
    '至少包含5个核心功能需求',
    '包含用户画像和使用场景描述',
    '提供初步的成本预算'
),
NULL),

(UUID(), @unit1_id, '硬件选型方案设计',
'根据需求分析结果，选择合适的传感器、开发板、执行器等硬件组件，设计完整的硬件选型方案。',
'design', 'easy', '4小时',
JSON_ARRAY(
    '硬件选型方案文档',
    '列出所有需要的硬件组件清单',
    '说明每个组件的选型理由',
    '提供采购链接和价格信息',
    '绘制硬件连接框图'
),
JSON_ARRAY('完成需求分析报告'));

-- 单元2的任务
INSERT INTO pbl_tasks (uuid, unit_id, title, description, type, difficulty, estimated_time, requirements, prerequisites) VALUES
(UUID(), @unit2_id, '电路原理图设计',
'使用Fritzing或其他电路设计工具，设计智能垃圾桶的完整电路原理图。电路应包括电源模块、传感器接口、执行器控制等部分。',
'design', 'medium', '5小时',
JSON_ARRAY(
    '提交电路原理图文件（.fzz或.pdf格式）',
    '标注所有元器件型号和参数',
    '包含完整的接线说明',
    '通过电路设计评审'
),
JSON_ARRAY('完成硬件选型方案')),

(UUID(), @unit2_id, '硬件组装与接线',
'按照电路原理图，完成智能垃圾桶硬件的物理组装和接线。要求接线规范、固定牢固、易于调试维护。',
'deployment', 'medium', '6小时',
JSON_ARRAY(
    '提交硬件组装完成的照片（多角度）',
    '拍摄接线细节照片并标注',
    '记录组装过程中遇到的问题和解决方法',
    '通过硬件检查，无短路或接线错误'
),
JSON_ARRAY('完成电路原理图设计'));

-- 单元3的任务
INSERT INTO pbl_tasks (uuid, unit_id, title, description, type, difficulty, estimated_time, requirements, prerequisites) VALUES
(UUID(), @unit3_id, '超声波传感器驱动开发',
'编写超声波传感器的驱动程序，实现距离测量功能。要求代码结构清晰、注释完整、测试充分。',
'coding', 'medium', '4小时',
JSON_ARRAY(
    '提交Arduino代码文件',
    '代码包含完整的注释',
    '实现准确的距离测量功能（误差<5%）',
    '提供测试数据和测试报告'
),
JSON_ARRAY('完成硬件组装')),

(UUID(), @unit3_id, '重量传感器驱动开发',
'编写重量传感器和HX711模块的驱动程序，实现重量测量和校准功能。',
'coding', 'medium', '4小时',
JSON_ARRAY(
    '提交Arduino代码文件',
    '实现重量测量和校准功能',
    '测量精度达到10g以内',
    '包含自动去皮功能',
    '提供测试数据'
),
JSON_ARRAY('完成硬件组装')),

(UUID(), @unit3_id, '多传感器集成测试',
'将所有传感器集成到一个程序中，实现数据采集、处理和显示功能。进行综合功能测试。',
'coding', 'hard', '5小时',
JSON_ARRAY(
    '提交完整的集成代码',
    '所有传感器能够同时正常工作',
    '数据采集频率达到设计要求',
    '提供完整的测试报告和数据',
    '制作演示视频'
),
JSON_ARRAY('完成所有传感器驱动开发'));

-- 单元4的任务
INSERT INTO pbl_tasks (uuid, unit_id, title, description, type, difficulty, estimated_time, requirements, prerequisites) VALUES
(UUID(), @unit4_id, '智能体架构设计',
'设计智能垃圾桶智能体的整体架构，包括感知模块、决策模块、执行模块等。绘制架构图并说明各模块功能。',
'design', 'medium', '4小时',
JSON_ARRAY(
    '提交智能体架构设计文档',
    '包含清晰的架构图',
    '详细说明各模块功能和接口',
    '设计合理的数据流和控制流'
),
NULL),

(UUID(), @unit4_id, '调用AI模型API实现图像识别',
'学习如何调用图像识别API（如百度AI、阿里云等），实现垃圾图片的分类识别功能。',
'coding', 'medium', '5小时',
JSON_ARRAY(
    '提交Python代码',
    '成功调用AI模型API',
    '实现至少4类垃圾的识别',
    '识别准确率达到80%以上',
    '包含错误处理机制'
),
JSON_ARRAY('完成智能体架构设计'));

-- 单元5的任务
INSERT INTO pbl_tasks (uuid, unit_id, title, description, type, difficulty, estimated_time, requirements, prerequisites) VALUES
(UUID(), @unit5_id, '实现垃圾分类智能体',
'开发完整的垃圾分类智能体，集成摄像头、图像识别API，实现实时垃圾分类功能。',
'coding', 'hard', '8小时',
JSON_ARRAY(
    '提交完整的智能体代码',
    '支持实时图像采集和识别',
    '识别结果能够触发相应动作',
    '包含用户交互界面',
    '提供使用说明文档'
),
JSON_ARRAY('完成AI模型API调用任务')),

(UUID(), @unit5_id, '开发满溢检测与预警功能',
'利用超声波传感器和重量传感器数据，开发垃圾桶满溢检测和预警功能。当垃圾桶即将满时，发出警报并通知管理员。',
'coding', 'medium', '5小时',
JSON_ARRAY(
    '提交满溢检测代码',
    '实现多级预警机制（如50%、80%、100%）',
    '支持本地警报（蜂鸣器、LED等）',
    '支持远程通知（邮件或推送）',
    '提供测试数据和测试报告'
),
JSON_ARRAY('完成多传感器集成测试')),

(UUID(), @unit5_id, '集成语音交互功能',
'为智能垃圾桶添加语音交互功能，能够语音提示垃圾分类结果、播报当前状态等。',
'coding', 'medium', '5小时',
JSON_ARRAY(
    '提交语音交互代码',
    '支持至少5种语音提示',
    '语音清晰、音量适中',
    '支持语音内容自定义',
    '制作功能演示视频'
),
JSON_ARRAY('完成垃圾分类智能体'));

-- 单元6的任务
INSERT INTO pbl_tasks (uuid, unit_id, title, description, type, difficulty, estimated_time, requirements, prerequisites) VALUES
(UUID(), @unit6_id, '硬件与智能体系统集成',
'将硬件系统和智能体软件进行完整集成，实现从传感器数据采集到智能决策再到执行器控制的完整流程。',
'deployment', 'hard', '6小时',
JSON_ARRAY(
    '完成硬件和软件的完整集成',
    '所有功能模块正常协作',
    '系统响应时间符合要求',
    '提供系统集成测试报告'
),
JSON_ARRAY('完成所有前置任务')),

(UUID(), @unit6_id, '系统功能测试与优化',
'对集成后的系统进行全面的功能测试，发现并修复问题，优化系统性能和用户体验。',
'analysis', 'hard', '7小时',
JSON_ARRAY(
    '提交完整的测试报告',
    '测试所有功能点并记录结果',
    '修复发现的所有严重问题',
    '优化至少3个性能指标',
    '提供优化前后对比数据'
),
JSON_ARRAY('完成系统集成'));

-- 单元7的任务
INSERT INTO pbl_tasks (uuid, unit_id, title, description, type, difficulty, estimated_time, requirements, prerequisites) VALUES
(UUID(), @unit7_id, '制作项目展示材料',
'制作项目展示PPT、演示视频、技术文档等材料，准备项目汇报。',
'design', 'medium', '5小时',
JSON_ARRAY(
    '提交项目展示PPT（至少15页）',
    '提交演示视频（3-5分钟）',
    '提交技术文档（包括设计方案、代码说明、使用手册）',
    '材料内容完整、制作精美'
),
JSON_ARRAY('完成系统测试')),

(UUID(), @unit7_id, '项目成果汇报与答辩',
'进行项目成果汇报，展示项目成果，回答评委和同学的提问。',
'analysis', 'medium', '2小时',
JSON_ARRAY(
    '完成现场汇报（15-20分钟）',
    '进行功能演示',
    '回答提问',
    '获得评委认可'
),
JSON_ARRAY('完成展示材料制作')),

(UUID(), @unit7_id, '撰写项目总结报告',
'总结项目开发过程中的经验教训、技术难点、创新点等，撰写详细的项目总结报告。',
'analysis', 'easy', '3小时',
JSON_ARRAY(
    '提交项目总结报告（至少3000字）',
    '包含项目背景、实现过程、技术难点、解决方案',
    '总结经验教训和收获',
    '提出改进建议和未来展望'
),
JSON_ARRAY('完成项目汇报'));

-- ========================================
-- 完成
-- ========================================
-- 样例数据插入完成
-- 课程UUID: a1b2c3d4-e5f6-7890-abcd-ef1234567890
-- 包含7个单元、28个学习资源、18个学习任务
