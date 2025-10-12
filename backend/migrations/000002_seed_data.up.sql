-- 插入种子数据

-- 插入章节数据(七年级上学期)
INSERT INTO chapters (name, grade, semester, description, sequence) VALUES
('三角形', '七年级', '上学期', '学习三角形的基本性质、分类和相关定理', 1),
('整式的乘除', '七年级', '上学期', '学习单项式、多项式的乘除运算', 2),
('因式分解', '七年级', '上学期', '学习提取公因式、公式法等因式分解方法', 3),
('分式', '七年级', '上学期', '学习分式的概念、运算和应用', 4),
('二元一次方程组', '七年级', '上学期', '学习二元一次方程组的解法和应用', 5);

-- 插入知识点数据(三角形章节)
INSERT INTO knowledge_points (chapter_id, name, content, difficulty, sequence) VALUES
(1, '三角形的定义与性质', '三角形是由三条线段首尾相连组成的封闭图形。三角形的内角和为180度。', 'easy', 1),
(1, '三角形的分类', '按边分类:等边三角形、等腰三角形、不等边三角形。按角分类:锐角三角形、直角三角形、钝角三角形。', 'easy', 2),
(1, '三角形的三边关系', '三角形任意两边之和大于第三边,任意两边之差小于第三边。', 'medium', 3),
(1, '三角形的高、中线和角平分线', '了解三角形的高、中线和角平分线的概念及性质。', 'medium', 4),
(1, '等腰三角形的性质', '等腰三角形的两底角相等,顶角的平分线、底边的中线、底边的高互相重合。', 'medium', 5);

-- 插入知识点数据(整式的乘除章节)
INSERT INTO knowledge_points (chapter_id, name, content, difficulty, sequence) VALUES
(2, '同底数幂的乘法', 'a^m × a^n = a^(m+n),即同底数幂相乘,底数不变,指数相加。', 'easy', 1),
(2, '幂的乘方', '(a^m)^n = a^(mn),即幂的乘方,底数不变,指数相乘。', 'easy', 2),
(2, '积的乘方', '(ab)^n = a^n × b^n,即积的乘方等于各因数乘方的积。', 'medium', 3),
(2, '同底数幂的除法', 'a^m ÷ a^n = a^(m-n) (a≠0),即同底数幂相除,底数不变,指数相减。', 'medium', 4),
(2, '单项式乘单项式', '系数相乘,相同字母的幂相加,其余字母及其指数不变。', 'medium', 5);

-- 插入示例题目(三角形章节)
INSERT INTO questions (knowledge_point_id, type, content, options, answer, analysis, difficulty) VALUES
(1, 'choice', '一个三角形的三个内角分别为60°、70°和x°,则x的值为( )',
 '["A. 40°", "B. 50°", "C. 60°", "D. 70°"]',
 'B',
 '根据三角形内角和为180°,可得 60° + 70° + x° = 180°,解得 x = 50°。',
 'easy'),

(2, 'choice', '下列三角形分类中,正确的是( )',
 '["A. 按边分类:锐角三角形、直角三角形、钝角三角形", "B. 按角分类:等边三角形、等腰三角形、不等边三角形", "C. 按边分类:等边三角形、等腰三角形、不等边三角形", "D. 以上都不对"]',
 'C',
 '按边分类应该是:等边三角形、等腰三角形、不等边三角形。按角分类应该是:锐角三角形、直角三角形、钝角三角形。',
 'easy'),

(3, 'choice', '已知三角形的两边长分别为3和7,则第三边长x的取值范围是( )',
 '["A. 3 < x < 7", "B. 4 < x < 10", "C. x > 4", "D. x < 10"]',
 'B',
 '根据三角形两边之和大于第三边,两边之差小于第三边,可得: 7-3 < x < 7+3,即 4 < x < 10。',
 'medium'),

(5, 'choice', '等腰三角形的顶角为40°,则它的底角为( )',
 '["A. 40°", "B. 70°", "C. 80°", "D. 100°"]',
 'B',
 '设底角为x°,根据等腰三角形两底角相等和三角形内角和为180°,可得: 40° + x° + x° = 180°,解得 x = 70°。',
 'medium');

-- 插入示例题目(整式的乘除章节)
INSERT INTO questions (knowledge_point_id, type, content, options, answer, analysis, difficulty) VALUES
(6, 'choice', '计算 a³ × a⁵ 的结果是( )',
 '["A. a⁸", "B. a¹⁵", "C. a²", "D. 2a⁸"]',
 'A',
 '根据同底数幂的乘法法则: a^m × a^n = a^(m+n),所以 a³ × a⁵ = a^(3+5) = a⁸。',
 'easy'),

(7, 'choice', '计算 (x²)³ 的结果是( )',
 '["A. x⁵", "B. x⁶", "C. x⁸", "D. x⁹"]',
 'B',
 '根据幂的乘方法则: (a^m)^n = a^(mn),所以 (x²)³ = x^(2×3) = x⁶。',
 'easy'),

(8, 'choice', '计算 (2a)³ 的结果是( )',
 '["A. 2a³", "B. 6a³", "C. 8a³", "D. a⁶"]',
 'C',
 '根据积的乘方法则: (ab)^n = a^n × b^n,所以 (2a)³ = 2³ × a³ = 8a³。',
 'medium'),

(9, 'fill', '计算: a⁷ ÷ a² = ___',
 NULL,
 'a⁵',
 '根据同底数幂的除法法则: a^m ÷ a^n = a^(m-n),所以 a⁷ ÷ a² = a^(7-2) = a⁵。',
 'medium');

-- 创建示例用户(密码为 bcrypt 加密的 "123456")
INSERT INTO users (username, password, grade, avatar) VALUES
('demo_student', '$2a$10$YourBcryptHashHere', '七年级', 'https://example.com/avatar.jpg'),
('test_user', '$2a$10$YourBcryptHashHere', '八年级', 'https://example.com/avatar2.jpg');

-- 注意: 实际密码哈希需要在应用层使用 bcrypt 生成
