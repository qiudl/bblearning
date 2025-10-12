-- 回滚种子数据

-- 删除示例用户
DELETE FROM users WHERE username IN ('demo_student', 'test_user');

-- 删除题目
DELETE FROM questions WHERE knowledge_point_id IN (
    SELECT id FROM knowledge_points WHERE chapter_id IN (
        SELECT id FROM chapters WHERE grade = '七年级' AND semester = '上学期'
    )
);

-- 删除知识点
DELETE FROM knowledge_points WHERE chapter_id IN (
    SELECT id FROM chapters WHERE grade = '七年级' AND semester = '上学期'
);

-- 删除章节
DELETE FROM chapters WHERE grade = '七年级' AND semester = '上学期';
