-- 初始化数据库表结构
-- 注意: 此文件作为备份和参考,实际表结构由 GORM AutoMigrate 创建

-- 用户表
CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    grade VARCHAR(20),
    avatar VARCHAR(500),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP WITH TIME ZONE
);

CREATE INDEX idx_users_deleted_at ON users(deleted_at);
CREATE INDEX idx_users_username ON users(username) WHERE deleted_at IS NULL;

-- 章节表
CREATE TABLE IF NOT EXISTS chapters (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    grade VARCHAR(20) NOT NULL,
    semester VARCHAR(20) NOT NULL,
    description TEXT,
    sequence INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP WITH TIME ZONE
);

CREATE INDEX idx_chapters_deleted_at ON chapters(deleted_at);
CREATE INDEX idx_chapters_grade_semester ON chapters(grade, semester) WHERE deleted_at IS NULL;

-- 知识点表
CREATE TABLE IF NOT EXISTS knowledge_points (
    id SERIAL PRIMARY KEY,
    chapter_id INTEGER NOT NULL REFERENCES chapters(id) ON DELETE CASCADE,
    name VARCHAR(200) NOT NULL,
    content TEXT,
    difficulty VARCHAR(20) DEFAULT 'medium',
    sequence INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP WITH TIME ZONE
);

CREATE INDEX idx_knowledge_points_deleted_at ON knowledge_points(deleted_at);
CREATE INDEX idx_knowledge_points_chapter_id ON knowledge_points(chapter_id) WHERE deleted_at IS NULL;

-- 题目表
CREATE TABLE IF NOT EXISTS questions (
    id SERIAL PRIMARY KEY,
    knowledge_point_id INTEGER NOT NULL REFERENCES knowledge_points(id) ON DELETE CASCADE,
    type VARCHAR(20) NOT NULL,
    content TEXT NOT NULL,
    options JSONB,
    answer TEXT NOT NULL,
    analysis TEXT,
    difficulty VARCHAR(20) DEFAULT 'medium',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP WITH TIME ZONE
);

CREATE INDEX idx_questions_deleted_at ON questions(deleted_at);
CREATE INDEX idx_questions_knowledge_point_id ON questions(knowledge_point_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_questions_type ON questions(type) WHERE deleted_at IS NULL;
CREATE INDEX idx_questions_difficulty ON questions(difficulty) WHERE deleted_at IS NULL;

-- 练习记录表
CREATE TABLE IF NOT EXISTS practice_records (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    question_id INTEGER NOT NULL REFERENCES questions(id) ON DELETE CASCADE,
    user_answer TEXT NOT NULL,
    is_correct BOOLEAN DEFAULT FALSE,
    time_spent INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP WITH TIME ZONE
);

CREATE INDEX idx_practice_records_deleted_at ON practice_records(deleted_at);
CREATE INDEX idx_practice_records_user_id ON practice_records(user_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_practice_records_question_id ON practice_records(question_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_practice_records_created_at ON practice_records(created_at DESC) WHERE deleted_at IS NULL;

-- 错题表
CREATE TABLE IF NOT EXISTS wrong_questions (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    question_id INTEGER NOT NULL REFERENCES questions(id) ON DELETE CASCADE,
    wrong_count INTEGER DEFAULT 1,
    last_wrong_answer TEXT,
    review_count INTEGER DEFAULT 0,
    last_review_at TIMESTAMP WITH TIME ZONE,
    is_mastered BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP WITH TIME ZONE,
    UNIQUE(user_id, question_id)
);

CREATE INDEX idx_wrong_questions_deleted_at ON wrong_questions(deleted_at);
CREATE INDEX idx_wrong_questions_user_id ON wrong_questions(user_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_wrong_questions_is_mastered ON wrong_questions(is_mastered) WHERE deleted_at IS NULL;

-- 学习进度表
CREATE TABLE IF NOT EXISTS learning_progresses (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    knowledge_point_id INTEGER NOT NULL REFERENCES knowledge_points(id) ON DELETE CASCADE,
    mastery_level DECIMAL(5,2) DEFAULT 0.00,
    practice_count INTEGER DEFAULT 0,
    correct_count INTEGER DEFAULT 0,
    last_practice_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP WITH TIME ZONE,
    UNIQUE(user_id, knowledge_point_id)
);

CREATE INDEX idx_learning_progresses_deleted_at ON learning_progresses(deleted_at);
CREATE INDEX idx_learning_progresses_user_id ON learning_progresses(user_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_learning_progresses_knowledge_point_id ON learning_progresses(knowledge_point_id) WHERE deleted_at IS NULL;

-- 创建触发器自动更新 updated_at 字段
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_chapters_updated_at BEFORE UPDATE ON chapters FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_knowledge_points_updated_at BEFORE UPDATE ON knowledge_points FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_questions_updated_at BEFORE UPDATE ON questions FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_practice_records_updated_at BEFORE UPDATE ON practice_records FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_wrong_questions_updated_at BEFORE UPDATE ON wrong_questions FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_learning_progresses_updated_at BEFORE UPDATE ON learning_progresses FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
