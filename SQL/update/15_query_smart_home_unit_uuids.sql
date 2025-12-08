-- 查询智能家居课程的所有单元UUID
-- 使用此脚本获取可以访问的单元UUID

SELECT 
    u.uuid as unit_uuid,
    u.id as unit_id,
    u.title as unit_title,
    u.`order` as unit_order,
    u.status as unit_status,
    c.uuid as course_uuid,
    c.title as course_title
FROM pbl_units u
JOIN pbl_courses c ON u.course_id = c.id
WHERE c.uuid = 'b2c3d4e5-f6a7-8901-bcde-f12345678901'
ORDER BY u.`order`;

-- 查询所有已发布课程的第一个可用单元
SELECT 
    c.uuid as course_uuid,
    c.title as course_title,
    u.uuid as first_unit_uuid,
    u.title as first_unit_title,
    CONCAT('http://localhost:8082/unit/', u.uuid) as access_url
FROM pbl_courses c
LEFT JOIN pbl_units u ON c.id = u.course_id AND u.`order` = 1
WHERE c.status = 'published'
ORDER BY c.id;
