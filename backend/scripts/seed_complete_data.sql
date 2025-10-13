-- ============================================
-- BBLearning 完整种子数据
-- 包含7-9年级完整知识点树和示例题目
-- ============================================

-- 清理现有数据
TRUNCATE TABLE practice_records, wrong_questions, learning_progress, questions, knowledge_points, chapters, users RESTART IDENTITY CASCADE;

-- ============================================
-- 1. 章节数据 (7-9年级)
-- ============================================

-- 七年级上学期
INSERT INTO chapters (name, grade, semester, description, sequence, subject) VALUES
('有理数', '7', '上学期', '学习有理数的概念、分类和运算', 1, '数学'),
('整式的加减', '7', '上学期', '学习单项式、多项式及其加减运算', 2, '数学'),
('一元一次方程', '7', '上学期', '学习一元一次方程的解法和应用', 3, '数学'),
('几何图形初步', '7', '上学期', '学习点、线、面、角等基本几何概念', 4, '数学');

-- 七年级下学期
INSERT INTO chapters (name, grade, semester, description, sequence, subject) VALUES
('相交线与平行线', '7', '下学期', '学习相交线、平行线的性质和判定', 5, '数学'),
('实数', '7', '下学期', '学习平方根、立方根和实数的概念', 6, '数学'),
('平面直角坐标系', '7', '下学期', '学习平面直角坐标系及坐标的应用', 7, '数学'),
('二元一次方程组', '7', '下学期', '学习二元一次方程组的解法', 8, '数学');

-- 八年级上学期
INSERT INTO chapters (name, grade, semester, description, sequence, subject) VALUES
('三角形', '8', '上学期', '学习三角形的性质、全等和相似', 9, '数学'),
('全等三角形', '8', '上学期', '学习全等三角形的判定和性质', 10, '数学'),
('轴对称', '8', '上学期', '学习轴对称图形和等腰三角形', 11, '数学'),
('整式的乘除与因式分解', '8', '上学期', '学习整式的乘除运算和因式分解', 12, '数学');

-- 八年级下学期
INSERT INTO chapters (name, grade, semester, description, sequence, subject) VALUES
('分式', '8', '下学期', '学习分式的概念、运算和方程', 13, '数学'),
('二次根式', '8', '下学期', '学习二次根式的概念和运算', 14, '数学'),
('勾股定理', '8', '下学期', '学习勾股定理及其应用', 15, '数学'),
('平行四边形', '8', '下学期', '学习平行四边形、矩形、菱形、正方形', 16, '数学');

-- 九年级上学期
INSERT INTO chapters (name, grade, semester, description, sequence, subject) VALUES
('一元二次方程', '9', '上学期', '学习一元二次方程的解法和应用', 17, '数学'),
('二次函数', '9', '上学期', '学习二次函数的图像和性质', 18, '数学'),
('旋转', '9', '上学期', '学习图形的旋转变换', 19, '数学'),
('圆', '9', '上学期', '学习圆的性质、切线和圆周角', 20, '数学');

-- 九年级下学期
INSERT INTO chapters (name, grade, semester, description, sequence, subject) VALUES
('反比例函数', '9', '下学期', '学习反比例函数的性质和应用', 21, '数学'),
('相似', '9', '下学期', '学习相似三角形的判定和性质', 22, '数学'),
('锐角三角函数', '9', '下学期', '学习正弦、余弦、正切函数', 23, '数学'),
('概率初步', '9', '下学期', '学习概率的基本概念和计算', 24, '数学');

-- ============================================
-- 2. 知识点数据 (详细展开)
-- ============================================

-- 第1章: 有理数
INSERT INTO knowledge_points (chapter_id, parent_id, name, content, type, difficulty, sequence) VALUES
(1, NULL, '有理数的概念', '有理数包括整数和分数，可以表示为两个整数的比。正数、负数和零都是有理数。', 'concept', 'basic', 1),
(1, NULL, '有理数的分类', '有理数分为整数（正整数、0、负整数）和分数（正分数、负分数）。', 'concept', 'basic', 2),
(1, NULL, '数轴', '数轴是规定了原点、正方向和单位长度的直线，用于直观表示有理数。', 'concept', 'basic', 3),
(1, NULL, '相反数', '只有符号不同的两个数互为相反数，0的相反数是0。', 'concept', 'basic', 4),
(1, NULL, '绝对值', '数轴上表示数a的点与原点的距离叫做a的绝对值，记作|a|。正数的绝对值是它本身，负数的绝对值是它的相反数，0的绝对值是0。', 'concept', 'medium', 5),
(1, NULL, '有理数的加法', '同号两数相加，取相同的符号，并把绝对值相加；异号两数相加，取绝对值较大的加数的符号，并用较大的绝对值减去较小的绝对值。', 'skill', 'medium', 6),
(1, NULL, '有理数的减法', '减去一个数等于加上这个数的相反数。', 'skill', 'medium', 7),
(1, NULL, '有理数的乘法', '两数相乘，同号得正，异号得负，并把绝对值相乘；任何数与0相乘都得0。', 'skill', 'medium', 8),
(1, NULL, '有理数的除法', '除以一个数等于乘以这个数的倒数（0除外）；两数相除，同号得正，异号得负。', 'skill', 'medium', 9),
(1, NULL, '有理数的乘方', 'n个相同因数a相乘，记作a^n，读作a的n次方。正数的任何次幂都是正数，负数的奇次幂是负数，负数的偶次幂是正数。', 'skill', 'advanced', 10);

-- 第2章: 整式的加减
INSERT INTO knowledge_points (chapter_id, parent_id, name, content, type, difficulty, sequence) VALUES
(2, NULL, '单项式', '由数字与字母的乘积组成的代数式叫做单项式。单独的一个数或字母也是单项式。', 'concept', 'basic', 1),
(2, NULL, '多项式', '几个单项式的和叫做多项式。多项式中每个单项式叫做多项式的项，不含字母的项叫做常数项。', 'concept', 'basic', 2),
(2, NULL, '同类项', '所含字母相同，并且相同字母的指数也相同的项叫做同类项。', 'concept', 'basic', 3),
(2, NULL, '合并同类项', '把同类项合并成一项叫做合并同类项。合并同类项时，把同类项的系数相加，字母和字母的指数不变。', 'skill', 'medium', 4),
(2, NULL, '去括号法则', '括号前是"+"号，把括号和它前面的"+"号去掉，括号里各项都不变号；括号前是"-"号，把括号和它前面的"-"号去掉，括号里各项都改变符号。', 'skill', 'medium', 5),
(2, NULL, '整式的加减', '整式加减的一般步骤：去括号、合并同类项。', 'skill', 'medium', 6);

-- 第3章: 一元一次方程
INSERT INTO knowledge_points (chapter_id, parent_id, name, content, type, difficulty, sequence) VALUES
(3, NULL, '方程的概念', '含有未知数的等式叫做方程。', 'concept', 'basic', 1),
(3, NULL, '一元一次方程', '只含有一个未知数，未知数的次数都是1，等号两边都是整式的方程叫做一元一次方程。', 'concept', 'basic', 2),
(3, NULL, '等式的性质', '等式两边加（或减）同一个数（或式子），结果仍相等；等式两边乘同一个数，或除以同一个不为0的数，结果仍相等。', 'theorem', 'basic', 3),
(3, NULL, '解一元一次方程', '解一元一次方程的一般步骤：去分母、去括号、移项、合并同类项、系数化为1。', 'skill', 'medium', 4),
(3, NULL, '一元一次方程的应用', '列方程解应用题的步骤：审题、设未知数、找等量关系、列方程、解方程、检验、作答。', 'skill', 'advanced', 5);

-- 第9章: 三角形
INSERT INTO knowledge_points (chapter_id, parent_id, name, content, type, difficulty, sequence) VALUES
(9, NULL, '三角形的定义', '由不在同一直线上的三条线段首尾顺次连接所组成的图形叫做三角形。', 'concept', 'basic', 1),
(9, NULL, '三角形的内角和', '三角形的内角和等于180°。', 'theorem', 'basic', 2),
(9, NULL, '三角形的三边关系', '三角形任意两边之和大于第三边，任意两边之差小于第三边。', 'theorem', 'basic', 3),
(9, NULL, '三角形的分类', '按边分：等边三角形、等腰三角形、不等边三角形。按角分：锐角三角形、直角三角形、钝角三角形。', 'concept', 'basic', 4),
(9, NULL, '三角形的高', '从三角形的一个顶点向它的对边所在直线作垂线，顶点和垂足之间的线段叫做三角形的高。', 'concept', 'basic', 5),
(9, NULL, '三角形的中线', '连接三角形的一个顶点与它对边中点的线段叫做三角形的中线。', 'concept', 'basic', 6),
(9, NULL, '三角形的角平分线', '三角形一个内角的平分线与它的对边相交，这个角的顶点与交点之间的线段叫做三角形的角平分线。', 'concept', 'medium', 7),
(9, NULL, '三角形的外角', '三角形的一边与另一边的延长线组成的角叫做三角形的外角。三角形的外角等于与它不相邻的两个内角的和。', 'theorem', 'medium', 8);

-- 第12章: 整式的乘除与因式分解
INSERT INTO knowledge_points (chapter_id, parent_id, name, content, type, difficulty, sequence) VALUES
(12, NULL, '同底数幂的乘法', '同底数幂相乘，底数不变，指数相加：a^m · a^n = a^(m+n)。', 'formula', 'basic', 1),
(12, NULL, '幂的乘方', '幂的乘方，底数不变，指数相乘：(a^m)^n = a^(mn)。', 'formula', 'basic', 2),
(12, NULL, '积的乘方', '积的乘方等于各因数乘方的积：(ab)^n = a^n · b^n。', 'formula', 'basic', 3),
(12, NULL, '同底数幂的除法', '同底数幂相除，底数不变，指数相减：a^m ÷ a^n = a^(m-n) (a≠0, m>n)。', 'formula', 'medium', 4),
(12, NULL, '整式的乘法', '单项式乘单项式、单项式乘多项式、多项式乘多项式的运算法则。', 'skill', 'medium', 5),
(12, NULL, '平方差公式', '(a+b)(a-b) = a² - b²。', 'formula', 'medium', 6),
(12, NULL, '完全平方公式', '(a±b)² = a² ± 2ab + b²。', 'formula', 'medium', 7),
(12, NULL, '因式分解', '把一个多项式化成几个整式的积的形式，叫做把这个多项式因式分解。', 'concept', 'medium', 8),
(12, NULL, '提公因式法', '如果多项式的各项有公因式，可以把这个公因式提出来，从而将多项式化成两个因式乘积的形式。', 'skill', 'medium', 9),
(12, NULL, '公式法因式分解', '利用平方差公式和完全平方公式进行因式分解。', 'skill', 'advanced', 10);

-- 第17章: 一元二次方程
INSERT INTO knowledge_points (chapter_id, parent_id, name, content, type, difficulty, sequence) VALUES
(17, NULL, '一元二次方程的概念', '只含有一个未知数，并且未知数的最高次数是2的整式方程叫做一元二次方程。一般形式：ax² + bx + c = 0 (a≠0)。', 'concept', 'basic', 1),
(17, NULL, '直接开平方法', '利用平方根的定义直接开平方求一元二次方程的解的方法。适用于 x² = p 或 (x+m)² = p 的形式。', 'skill', 'medium', 2),
(17, NULL, '配方法', '通过配方将一元二次方程化为 (x+m)² = n 的形式，再用直接开平方法求解。', 'skill', 'medium', 3),
(17, NULL, '公式法', '一元二次方程 ax² + bx + c = 0 (a≠0) 的求根公式：x = [-b ± √(b²-4ac)] / 2a。', 'formula', 'medium', 4),
(17, NULL, '因式分解法', '将方程左边因式分解，使方程化为两个一次因式的积等于0的形式，再使每个因式等于0求解。', 'skill', 'advanced', 5),
(17, NULL, '一元二次方程根的判别式', '对于一元二次方程 ax² + bx + c = 0 (a≠0)，判别式 Δ = b² - 4ac。当Δ>0时，方程有两个不相等的实数根；当Δ=0时，方程有两个相等的实数根；当Δ<0时，方程没有实数根。', 'theorem', 'advanced', 6);

-- ============================================
-- 3. 示例题目数据
-- ============================================

-- 有理数题目
INSERT INTO questions (knowledge_point_id, type, content, options, answer, analysis, difficulty, source) VALUES
(1, 'choice', '下列各数中，属于有理数的是（　）',
 '["A. √2", "B. π", "C. -3/4", "D. √5"]',
 'C',
 '有理数包括整数和分数。A、B、D选项都是无理数，只有C选项-3/4是分数，属于有理数。',
 'basic', '基础练习'),

(5, 'choice', '|-5|的值等于（　）',
 '["A. 5", "B. -5", "C. 1/5", "D. -1/5"]',
 'A',
 '负数的绝对值等于它的相反数，所以|-5| = 5。',
 'basic', '基础练习'),

(6, 'choice', '计算：(-8) + 13 =（　）',
 '["A. -21", "B. -5", "C. 5", "D. 21"]',
 'C',
 '异号两数相加，取绝对值较大的加数的符号，用较大的绝对值减去较小的绝对值：13 - 8 = 5。',
 'medium', '基础练习'),

(8, 'choice', '计算：(-3) × (-4) =（　）',
 '["A. -12", "B. 12", "C. -7", "D. 7"]',
 'B',
 '两个负数相乘，同号得正：(-3) × (-4) = 12。',
 'medium', '基础练习'),

(10, 'choice', '计算：(-2)³ =（　）',
 '["A. -8", "B. 8", "C. -6", "D. 6"]',
 'A',
 '负数的奇次幂是负数：(-2)³ = (-2) × (-2) × (-2) = -8。',
 'medium', '基础练习');

-- 整式的加减题目
INSERT INTO questions (knowledge_point_id, type, content, options, answer, analysis, difficulty, source) VALUES
(11, 'choice', '下列各式中，是单项式的是（　）',
 '["A. x + y", "B. 2xy", "C. x/y", "D. x² - 1"]',
 'B',
 '单项式是数字与字母的乘积。A是多项式，C是分式，D是多项式，只有B是单项式。',
 'basic', '基础练习'),

(13, 'choice', '下列各组中，是同类项的是（　）',
 '["A. 2x²y和2xy²", "B. 3ab和3abc", "C. -5x²y和2yx²", "D. 4和4x"]',
 'C',
 '同类项要求所含字母相同，并且相同字母的指数也相同。-5x²y和2yx²满足这个条件（字母顺序可以不同）。',
 'medium', '基础练习'),

(14, 'fill', '合并同类项：3x² - 5x² + 2x² = ______',
 NULL,
 '0',
 '把同类项的系数相加：3 - 5 + 2 = 0，所以结果是0。',
 'medium', '基础练习'),

(15, 'choice', '化简：-(2x - 3y) =（　）',
 '["A. -2x + 3y", "B. -2x - 3y", "C. 2x - 3y", "D. 2x + 3y"]',
 'A',
 '括号前是负号，去括号后各项都要变号：-(2x - 3y) = -2x + 3y。',
 'medium', '基础练习');

-- 一元一次方程题目
INSERT INTO questions (knowledge_point_id, type, content, options, answer, analysis, difficulty, source) VALUES
(18, 'choice', '下列方程中，是一元一次方程的是（　）',
 '["A. x² + 2x = 0", "B. 2x - y = 3", "C. 3x + 1 = 2x - 5", "D. 1/x = 2"]',
 'C',
 '一元一次方程要满足：只含一个未知数，未知数次数是1，等号两边都是整式。只有C满足所有条件。',
 'basic', '基础练习'),

(21, 'fill', '解方程：2x + 5 = 13，得 x = ______',
 NULL,
 '4',
 '移项得：2x = 13 - 5，即 2x = 8，系数化为1得：x = 4。',
 'medium', '基础练习'),

(22, 'answer', '某数的3倍加上5等于这个数的2倍减去1，求这个数。',
 NULL,
 '-6',
 '设这个数为x，根据题意列方程：3x + 5 = 2x - 1，解得：x = -6。',
 'advanced', '基础练习');

-- 三角形题目
INSERT INTO questions (knowledge_point_id, type, content, options, answer, analysis, difficulty, source) VALUES
(33, 'choice', '三角形的两个内角分别为50°和60°，则第三个内角为（　）',
 '["A. 60°", "B. 70°", "C. 80°", "D. 90°"]',
 'B',
 '根据三角形内角和定理：180° - 50° - 60° = 70°。',
 'basic', '基础练习'),

(35, 'choice', '已知三角形的两边长分别为3cm和8cm，则第三边长x的取值范围是（　）',
 '["A. 3 < x < 8", "B. 5 < x < 11", "C. x > 5", "D. x < 11"]',
 'B',
 '根据三角形三边关系：两边之差 < 第三边 < 两边之和，即 8-3 < x < 8+3，得 5 < x < 11。',
 'medium', '基础练习'),

(36, 'choice', '等腰三角形的定义是（　）',
 '["A. 三边相等的三角形", "B. 两边相等的三角形", "C. 三角相等的三角形", "D. 两角相等的三角形"]',
 'B',
 '等腰三角形是指有两条边相等的三角形。',
 'basic', '基础练习');

-- 整式的乘除与因式分解题目
INSERT INTO questions (knowledge_point_id, type, content, options, answer, analysis, difficulty, source) VALUES
(45, 'choice', '计算：a³ · a⁵ =（　）',
 '["A. a⁸", "B. a¹⁵", "C. a²", "D. 2a⁸"]',
 'A',
 '同底数幂相乘，底数不变，指数相加：a³ · a⁵ = a^(3+5) = a⁸。',
 'basic', '基础练习'),

(46, 'choice', '计算：(x²)⁴ =（　）',
 '["A. x⁶", "B. x⁸", "C. x²", "D. x¹⁶"]',
 'B',
 '幂的乘方，底数不变，指数相乘：(x²)⁴ = x^(2×4) = x⁸。',
 'basic', '基础练习'),

(50, 'choice', '计算：(x+3)(x-3) =（　）',
 '["A. x² - 9", "B. x² + 9", "C. x² - 6x + 9", "D. x² + 6x - 9"]',
 'A',
 '利用平方差公式：(a+b)(a-b) = a² - b²，所以 (x+3)(x-3) = x² - 9。',
 'medium', '基础练习'),

(51, 'choice', '计算：(x+2)² =（　）',
 '["A. x² + 4", "B. x² + 2x + 4", "C. x² + 4x + 4", "D. x² - 4x + 4"]',
 'C',
 '利用完全平方公式：(a+b)² = a² + 2ab + b²，所以 (x+2)² = x² + 4x + 4。',
 'medium', '基础练习'),

(53, 'fill', '提公因式分解：3x² - 6x = ______',
 NULL,
 '3x(x - 2)',
 '公因式是3x，提出公因式：3x² - 6x = 3x(x - 2)。',
 'medium', '基础练习');

-- 一元二次方程题目
INSERT INTO questions (knowledge_point_id, type, content, options, answer, analysis, difficulty, source) VALUES
(55, 'choice', '下列方程中，是一元二次方程的是（　）',
 '["A. x + 2y = 3", "B. x² = 0", "C. x³ - x = 0", "D. 1/x² + x = 1"]',
 'B',
 '一元二次方程的定义：只含一个未知数，未知数的最高次数是2，是整式方程。只有B满足条件。',
 'basic', '基础练习'),

(58, 'fill', '用公式法解方程：x² - 3x + 2 = 0，得 x₁ = ______, x₂ = ______',
 NULL,
 'x₁ = 1, x₂ = 2',
 '这里 a=1, b=-3, c=2。判别式 Δ = b² - 4ac = 9 - 8 = 1 > 0。\n用公式：x = [3 ± √1] / 2 = [3 ± 1] / 2，得 x₁ = 2, x₂ = 1。',
 'advanced', '基础练习'),

(60, 'choice', '方程 x² - 4x + 4 = 0 根的判别式 Δ =（　）',
 '["A. 0", "B. 4", "C. 8", "D. 16"]',
 'A',
 'Δ = b² - 4ac = (-4)² - 4×1×4 = 16 - 16 = 0，说明方程有两个相等的实数根。',
 'advanced', '基础练习');

-- ============================================
-- 4. 示例用户数据
-- ============================================

-- 创建测试用户 (密码都是 "123456")
-- 使用 bcrypt 生成的哈希值: $2a$10$qWHWs.Ftc7yL4tG6ByvXTODjdV5hQacN7SaxCIW8MQWKKfwtjW7m6
INSERT INTO users (username, password, nickname, email, phone, grade, avatar, role, created_at, updated_at) VALUES
('student01', '$2a$10$qWHWs.Ftc7yL4tG6ByvXTODjdV5hQacN7SaxCIW8MQWKKfwtjW7m6', '张三', 'zhangsan@example.com', '13800138001', '7', NULL, 'student', NOW(), NOW()),
('student02', '$2a$10$qWHWs.Ftc7yL4tG6ByvXTODjdV5hQacN7SaxCIW8MQWKKfwtjW7m6', '李四', 'lisi@example.com', '13800138002', '8', NULL, 'student', NOW(), NOW()),
('student03', '$2a$10$qWHWs.Ftc7yL4tG6ByvXTODjdV5hQacN7SaxCIW8MQWKKfwtjW7m6', '王五', 'wangwu@example.com', '13800138003', '9', NULL, 'student', NOW(), NOW()),
('teacher01', '$2a$10$qWHWs.Ftc7yL4tG6ByvXTODjdV5hQacN7SaxCIW8MQWKKfwtjW7m6', '陈老师', 'chen@example.com', '13900139001', NULL, NULL, 'teacher', NOW(), NOW());

-- ============================================
-- 5. 学习进度示例数据
-- ============================================

-- 为 student01 创建一些学习进度
INSERT INTO learning_progress (user_id, knowledge_point_id, mastery_level, practice_count, correct_count, last_practice_at, created_at, updated_at) VALUES
(1, 1, 0.85, 10, 9, NOW() - INTERVAL '1 day', NOW() - INTERVAL '7 days', NOW() - INTERVAL '1 day'),
(1, 2, 0.75, 8, 6, NOW() - INTERVAL '2 days', NOW() - INTERVAL '6 days', NOW() - INTERVAL '2 days'),
(1, 3, 0.90, 12, 11, NOW() - INTERVAL '1 day', NOW() - INTERVAL '5 days', NOW() - INTERVAL '1 day'),
(1, 5, 0.65, 6, 4, NOW() - INTERVAL '3 days', NOW() - INTERVAL '4 days', NOW() - INTERVAL '3 days'),
(1, 6, 0.80, 15, 12, NOW() - INTERVAL '1 day', NOW() - INTERVAL '8 days', NOW() - INTERVAL '1 day');

-- ============================================
-- 6. 练习记录示例数据
-- ============================================

-- 为 student01 创建一些练习记录
INSERT INTO practice_records (user_id, question_id, user_answer, is_correct, time_spent, created_at) VALUES
(1, 1, 'C', TRUE, 45, NOW() - INTERVAL '1 day'),
(1, 2, 'A', TRUE, 38, NOW() - INTERVAL '1 day'),
(1, 3, 'B', TRUE, 52, NOW() - INTERVAL '1 day'),
(1, 4, 'A', FALSE, 65, NOW() - INTERVAL '2 days'),
(1, 5, 'A', TRUE, 48, NOW() - INTERVAL '2 days'),
(1, 6, 'B', TRUE, 42, NOW() - INTERVAL '3 days'),
(1, 7, 'C', FALSE, 55, NOW() - INTERVAL '3 days');

-- ============================================
-- 7. 错题记录示例数据
-- ============================================

-- 基于练习记录创建错题
INSERT INTO wrong_questions (user_id, question_id, wrong_count, last_wrong_at, status, error_reason, created_at, updated_at) VALUES
(1, 4, 1, NOW() - INTERVAL '2 days', 'pending', '对绝对值的概念理解不够深刻', NOW() - INTERVAL '2 days', NOW() - INTERVAL '2 days'),
(1, 7, 1, NOW() - INTERVAL '3 days', 'pending', '去括号时符号变化规则掌握不牢', NOW() - INTERVAL '3 days', NOW() - INTERVAL '3 days');

-- ============================================
-- 完成
-- ============================================

-- 显示插入的数据统计
SELECT
    (SELECT COUNT(*) FROM chapters) as chapter_count,
    (SELECT COUNT(*) FROM knowledge_points) as knowledge_point_count,
    (SELECT COUNT(*) FROM questions) as question_count,
    (SELECT COUNT(*) FROM users) as user_count,
    (SELECT COUNT(*) FROM learning_progress) as learning_progress_count,
    (SELECT COUNT(*) FROM practice_records) as practice_record_count,
    (SELECT COUNT(*) FROM wrong_questions) as wrong_question_count;
