-- 插入伦理案例和活动测试数据
-- 适用于MySQL 5.7-8.0

USE codehubot_pbl;

-- 插入伦理案例测试数据
INSERT INTO pbl_ethics_cases (
    uuid, title, description, content, grade_level, 
    ethics_topics, difficulty, discussion_questions, 
    reference_links, cover_image, author, source, 
    view_count, like_count, is_published, created_at, updated_at
) VALUES 
(
    UUID(),
    'AI智能助手的隐私保护',
    '探讨智能语音助手在收集用户数据时面临的隐私和伦理问题',
    '随着智能语音助手的普及，它们可以识别用户的声音、记录对话内容，甚至分析用户的行为习惯。某科技公司开发的智能助手被曝光在未经用户明确同意的情况下，将用户对话录音上传至服务器进行人工审核和分析。\n\n这引发了广泛的隐私担忧：\n1. 用户是否真正了解他们的数据被如何使用？\n2. 科技公司如何平衡产品改进和用户隐私保护？\n3. 在家庭环境中使用智能助手，如何保护儿童的隐私？',
    '初中',
    JSON_ARRAY('隐私保护', '数据安全', '人工智能伦理'),
    'basic',
    JSON_ARRAY(
        '你认为智能助手收集用户数据是否合理？为什么？',
        '如果你是产品设计师，你会如何在功能改进和隐私保护之间取得平衡？',
        '作为用户，你会如何保护自己的隐私？'
    ),
    JSON_ARRAY(
        '《中华人民共和国个人信息保护法》',
        'GDPR（欧盟通用数据保护条例）'
    ),
    'https://via.placeholder.com/400x300?text=AI+Privacy',
    '伦理教育委员会',
    '真实案例改编',
    0,
    0,
    1,
    NOW(),
    NOW()
),
(
    UUID(),
    '智能垃圾桶的环保责任',
    '讨论智能垃圾桶在垃圾分类中的作用以及可能带来的社会影响',
    '某社区引入了AI智能垃圾桶，能够自动识别和分类垃圾。然而，一些居民开始过度依赖这项技术，不再主动学习垃圾分类知识。同时，智能垃圾桶的制造和维护成本很高，产生的电子废弃物也带来新的环境问题。\n\n这个案例引发了以下思考：\n1. 技术是否让人们变得更懒惰？\n2. 高科技解决方案是否总是最好的选择？\n3. 我们应该如何平衡技术便利和个人责任？',
    '初中',
    JSON_ARRAY('环境保护', '技术依赖', '社会责任'),
    'intermediate',
    JSON_ARRAY(
        '你认为智能垃圾桶是环保问题的好解决方案吗？',
        '如果过度依赖技术，会带来什么问题？',
        '除了使用智能设备，还有哪些方法可以提高垃圾分类率？'
    ),
    JSON_ARRAY(
        '《中国垃圾分类政策》',
        '《循环经济促进法》'
    ),
    'https://via.placeholder.com/400x300?text=Smart+Trash',
    '环境教育小组',
    '社区实践案例',
    0,
    0,
    1,
    NOW(),
    NOW()
),
(
    UUID(),
    '算法推荐的信息茧房',
    '探讨社交媒体算法推荐机制可能导致的认知偏见和社会分化',
    '小明发现他的社交媒体推荐内容总是符合他的喜好，但渐渐地，他接触到的信息越来越单一。他的朋友小红则接收到完全不同的推荐内容，导致两人对同一事件产生了截然不同的看法。\n\n这种"信息茧房"现象引发了对算法伦理的讨论：\n1. 算法推荐是便利还是限制？\n2. 如何保持信息的多元性和客观性？\n3. 技术公司应该承担什么样的社会责任？',
    '初中',
    JSON_ARRAY('算法伦理', '信息茧房', '媒体素养'),
    'advanced',
    JSON_ARRAY(
        '你认为算法推荐系统有哪些优点和缺点？',
        '如何避免陷入"信息茧房"？',
        '社交媒体平台应该如何改进推荐算法？'
    ),
    JSON_ARRAY(
        '《网络信息内容生态治理规定》',
        '算法推荐伦理研究报告'
    ),
    'https://via.placeholder.com/400x300?text=Algorithm+Bias',
    '媒体素养教育团队',
    '理论研究与案例结合',
    0,
    0,
    1,
    NOW(),
    NOW()
);

-- 插入伦理活动测试数据
INSERT INTO pbl_ethics_activities (
    uuid, case_id, course_id, unit_id, activity_type, 
    title, description, participants, group_id, 
    facilitator_id, discussion_records, conclusions, 
    reflections, status, scheduled_at, completed_at, 
    created_at, updated_at
) VALUES 
(
    UUID(),
    (SELECT id FROM pbl_ethics_cases WHERE title = 'AI智能助手的隐私保护' LIMIT 1),
    NULL,
    NULL,
    'debate',
    'AI隐私保护主题辩论',
    '围绕"智能助手收集用户数据是利大于弊还是弊大于利"展开辩论',
    JSON_ARRAY(),
    NULL,
    (SELECT id FROM admin_users WHERE username = 'admin' LIMIT 1),
    JSON_ARRAY(),
    NULL,
    JSON_ARRAY(),
    'planned',
    DATE_ADD(NOW(), INTERVAL 3 DAY),
    NULL,
    NOW(),
    NOW()
),
(
    UUID(),
    (SELECT id FROM pbl_ethics_cases WHERE title = '智能垃圾桶的环保责任' LIMIT 1),
    NULL,
    NULL,
    'case_analysis',
    '智能垃圾桶案例分析',
    '分析智能垃圾桶项目的社会、环境和经济影响',
    JSON_ARRAY(),
    NULL,
    (SELECT id FROM admin_users WHERE username = 'admin' LIMIT 1),
    JSON_ARRAY(),
    NULL,
    JSON_ARRAY(),
    'ongoing',
    NOW(),
    NULL,
    NOW(),
    NOW()
),
(
    UUID(),
    (SELECT id FROM pbl_ethics_cases WHERE title = '算法推荐的信息茧房' LIMIT 1),
    NULL,
    NULL,
    'discussion',
    '算法伦理小组讨论',
    '讨论如何避免信息茧房，培养批判性思维',
    JSON_ARRAY(),
    NULL,
    (SELECT id FROM admin_users WHERE username = 'admin' LIMIT 1),
    JSON_ARRAY(),
    NULL,
    JSON_ARRAY(),
    'completed',
    DATE_SUB(NOW(), INTERVAL 2 DAY),
    DATE_SUB(NOW(), INTERVAL 1 DAY),
    DATE_SUB(NOW(), INTERVAL 3 DAY),
    DATE_SUB(NOW(), INTERVAL 1 DAY)
);

-- 验证插入结果
SELECT '插入伦理案例数量：' AS message, COUNT(*) AS count FROM pbl_ethics_cases;
SELECT '插入伦理活动数量：' AS message, COUNT(*) AS count FROM pbl_ethics_activities;

SELECT '伦理案例列表：' AS message;
SELECT uuid, title, difficulty, grade_level, is_published, created_at 
FROM pbl_ethics_cases 
ORDER BY created_at DESC;

SELECT '伦理活动列表：' AS message;
SELECT uuid, title, activity_type, status, scheduled_at 
FROM pbl_ethics_activities 
ORDER BY created_at DESC;
