-- 添加AI对话记录表和统计表

-- AI对话记录表
CREATE TABLE IF NOT EXISTS ai_conversations (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    question_id INTEGER REFERENCES questions(id) ON DELETE SET NULL,
    role VARCHAR(20) NOT NULL,
    content TEXT NOT NULL,
    metadata JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP WITH TIME ZONE
);

CREATE INDEX idx_ai_conversations_deleted_at ON ai_conversations(deleted_at);
CREATE INDEX idx_ai_conversations_user_id ON ai_conversations(user_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_ai_conversations_question_id ON ai_conversations(question_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_ai_conversations_created_at ON ai_conversations(created_at DESC) WHERE deleted_at IS NULL;

-- 每日学习目标表
CREATE TABLE IF NOT EXISTS daily_goals (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    date DATE NOT NULL,
    target_minutes INTEGER DEFAULT 30,
    actual_minutes INTEGER DEFAULT 0,
    target_questions INTEGER DEFAULT 10,
    completed_questions INTEGER DEFAULT 0,
    target_knowledge_points INTEGER DEFAULT 2,
    completed_knowledge_points INTEGER DEFAULT 0,
    is_completed BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP WITH TIME ZONE,
    UNIQUE(user_id, date)
);

CREATE INDEX idx_daily_goals_deleted_at ON daily_goals(deleted_at);
CREATE INDEX idx_daily_goals_user_id ON daily_goals(user_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_daily_goals_date ON daily_goals(date DESC) WHERE deleted_at IS NULL;
CREATE INDEX idx_daily_goals_is_completed ON daily_goals(is_completed) WHERE deleted_at IS NULL;

-- 学习统计表(按日聚合)
CREATE TABLE IF NOT EXISTS learning_statistics (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    date DATE NOT NULL,
    study_minutes INTEGER DEFAULT 0,
    practice_count INTEGER DEFAULT 0,
    correct_count INTEGER DEFAULT 0,
    wrong_count INTEGER DEFAULT 0,
    new_knowledge_points INTEGER DEFAULT 0,
    review_knowledge_points INTEGER DEFAULT 0,
    accuracy_rate DECIMAL(5,2) DEFAULT 0.00,
    average_time_per_question DECIMAL(8,2) DEFAULT 0.00,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP WITH TIME ZONE,
    UNIQUE(user_id, date)
);

CREATE INDEX idx_learning_statistics_deleted_at ON learning_statistics(deleted_at);
CREATE INDEX idx_learning_statistics_user_id ON learning_statistics(user_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_learning_statistics_date ON learning_statistics(date DESC) WHERE deleted_at IS NULL;

-- 添加触发器自动更新 updated_at 字段
CREATE TRIGGER update_ai_conversations_updated_at
    BEFORE UPDATE ON ai_conversations
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_daily_goals_updated_at
    BEFORE UPDATE ON daily_goals
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_learning_statistics_updated_at
    BEFORE UPDATE ON learning_statistics
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- 添加User表缺失的字段(如果不存在)
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                   WHERE table_name='users' AND column_name='nickname') THEN
        ALTER TABLE users ADD COLUMN nickname VARCHAR(50);
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                   WHERE table_name='users' AND column_name='phone_number') THEN
        ALTER TABLE users ADD COLUMN phone_number VARCHAR(20);
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                   WHERE table_name='users' AND column_name='email') THEN
        ALTER TABLE users ADD COLUMN email VARCHAR(100);
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                   WHERE table_name='users' AND column_name='role') THEN
        ALTER TABLE users ADD COLUMN role VARCHAR(20) DEFAULT 'student';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                   WHERE table_name='users' AND column_name='status') THEN
        ALTER TABLE users ADD COLUMN status VARCHAR(20) DEFAULT 'active';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                   WHERE table_name='users' AND column_name='last_login_at') THEN
        ALTER TABLE users ADD COLUMN last_login_at TIMESTAMP WITH TIME ZONE;
    END IF;
END $$;

-- 添加Chapter表缺失的字段
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                   WHERE table_name='chapters' AND column_name='chapter_number') THEN
        ALTER TABLE chapters ADD COLUMN chapter_number INTEGER;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                   WHERE table_name='chapters' AND column_name='subject') THEN
        ALTER TABLE chapters ADD COLUMN subject VARCHAR(20) DEFAULT 'math';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                   WHERE table_name='chapters' AND column_name='display_order') THEN
        ALTER TABLE chapters ADD COLUMN display_order INTEGER DEFAULT 0;
    END IF;
END $$;

-- 添加KnowledgePoint表缺失的字段
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                   WHERE table_name='knowledge_points' AND column_name='parent_id') THEN
        ALTER TABLE knowledge_points ADD COLUMN parent_id INTEGER REFERENCES knowledge_points(id) ON DELETE SET NULL;
        CREATE INDEX idx_knowledge_points_parent_id ON knowledge_points(parent_id);
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                   WHERE table_name='knowledge_points' AND column_name='type') THEN
        ALTER TABLE knowledge_points ADD COLUMN type VARCHAR(20);
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                   WHERE table_name='knowledge_points' AND column_name='description') THEN
        ALTER TABLE knowledge_points ADD COLUMN description TEXT;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                   WHERE table_name='knowledge_points' AND column_name='video_url') THEN
        ALTER TABLE knowledge_points ADD COLUMN video_url VARCHAR(500);
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                   WHERE table_name='knowledge_points' AND column_name='prerequisites') THEN
        ALTER TABLE knowledge_points ADD COLUMN prerequisites TEXT;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                   WHERE table_name='knowledge_points' AND column_name='tags') THEN
        ALTER TABLE knowledge_points ADD COLUMN tags TEXT;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                   WHERE table_name='knowledge_points' AND column_name='estimated_hours') THEN
        ALTER TABLE knowledge_points ADD COLUMN estimated_hours DECIMAL(5,2);
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                   WHERE table_name='knowledge_points' AND column_name='display_order') THEN
        ALTER TABLE knowledge_points ADD COLUMN display_order INTEGER DEFAULT 0;
    END IF;
END $$;
