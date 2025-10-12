-- 回滚初始化数据库表结构

-- 删除触发器
DROP TRIGGER IF EXISTS update_users_updated_at ON users;
DROP TRIGGER IF EXISTS update_chapters_updated_at ON chapters;
DROP TRIGGER IF EXISTS update_knowledge_points_updated_at ON knowledge_points;
DROP TRIGGER IF EXISTS update_questions_updated_at ON questions;
DROP TRIGGER IF EXISTS update_practice_records_updated_at ON practice_records;
DROP TRIGGER IF EXISTS update_wrong_questions_updated_at ON wrong_questions;
DROP TRIGGER IF EXISTS update_learning_progresses_updated_at ON learning_progresses;

-- 删除函数
DROP FUNCTION IF EXISTS update_updated_at_column();

-- 删除表(按照依赖关系的反向顺序)
DROP TABLE IF EXISTS learning_progresses;
DROP TABLE IF EXISTS wrong_questions;
DROP TABLE IF EXISTS practice_records;
DROP TABLE IF EXISTS questions;
DROP TABLE IF EXISTS knowledge_points;
DROP TABLE IF EXISTS chapters;
DROP TABLE IF EXISTS users;
