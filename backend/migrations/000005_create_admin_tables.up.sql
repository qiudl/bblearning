-- 000005_create_admin_tables.up.sql
-- 管理员系统相关表

-- AI题目生成记录表
CREATE TABLE IF NOT EXISTS ai_generation_records (
    id SERIAL PRIMARY KEY,
    generation_id VARCHAR(50) UNIQUE NOT NULL,
    admin_user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
    knowledge_point_id INTEGER NOT NULL REFERENCES knowledge_points(id) ON DELETE RESTRICT,
    question_type VARCHAR(20) NOT NULL CHECK (question_type IN ('choice', 'fill', 'answer')),
    difficulty VARCHAR(20) NOT NULL CHECK (difficulty IN ('basic', 'medium', 'advanced')),
    count INTEGER NOT NULL CHECK (count > 0 AND count <= 10),
    prompt TEXT,
    response TEXT,
    tokens_used INTEGER DEFAULT 0,
    cost DECIMAL(10,4) DEFAULT 0.00,
    status VARCHAR(20) DEFAULT 'success' CHECK (status IN ('pending', 'success', 'failed')),
    error_message TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_generation_admin_user (admin_user_id),
    INDEX idx_generation_kp (knowledge_point_id),
    INDEX idx_generation_status (status),
    INDEX idx_generation_created (created_at DESC)
);

COMMENT ON TABLE ai_generation_records IS 'AI题目生成历史记录';
COMMENT ON COLUMN ai_generation_records.generation_id IS '生成记录唯一标识';
COMMENT ON COLUMN ai_generation_records.admin_user_id IS '管理员用户ID';
COMMENT ON COLUMN ai_generation_records.knowledge_point_id IS '关联知识点ID';
COMMENT ON COLUMN ai_generation_records.question_type IS '题目类型: choice=选择题, fill=填空题, answer=解答题';
COMMENT ON COLUMN ai_generation_records.difficulty IS '难度等级: basic=基础, medium=中等, advanced=高级';
COMMENT ON COLUMN ai_generation_records.count IS '生成题目数量(1-10)';
COMMENT ON COLUMN ai_generation_records.prompt IS 'AI提示词';
COMMENT ON COLUMN ai_generation_records.response IS 'AI原始响应';
COMMENT ON COLUMN ai_generation_records.tokens_used IS 'Token消耗数';
COMMENT ON COLUMN ai_generation_records.cost IS 'API调用成本(美元)';
COMMENT ON COLUMN ai_generation_records.status IS '生成状态: pending=进行中, success=成功, failed=失败';

-- 管理员操作日志表
CREATE TABLE IF NOT EXISTS admin_operation_logs (
    id SERIAL PRIMARY KEY,
    admin_user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
    operation_type VARCHAR(50) NOT NULL,
    target_type VARCHAR(50),
    target_id INTEGER,
    description TEXT,
    request_data JSONB,
    response_status VARCHAR(20),
    ip_address VARCHAR(45),
    user_agent TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_op_log_admin_user (admin_user_id),
    INDEX idx_op_log_type (operation_type),
    INDEX idx_op_log_target (target_type, target_id),
    INDEX idx_op_log_created (created_at DESC)
);

COMMENT ON TABLE admin_operation_logs IS '管理员操作日志';
COMMENT ON COLUMN admin_operation_logs.admin_user_id IS '操作管理员ID';
COMMENT ON COLUMN admin_operation_logs.operation_type IS '操作类型: create_user, update_user_status, create_chapter, delete_question等';
COMMENT ON COLUMN admin_operation_logs.target_type IS '操作目标类型: user, chapter, knowledge_point, question等';
COMMENT ON COLUMN admin_operation_logs.target_id IS '操作目标ID';
COMMENT ON COLUMN admin_operation_logs.description IS '操作描述';
COMMENT ON COLUMN admin_operation_logs.request_data IS '请求数据(JSON格式)';
COMMENT ON COLUMN admin_operation_logs.response_status IS '响应状态: success, failed';

-- 扩展questions表：添加来源和审核状态字段
ALTER TABLE questions
ADD COLUMN IF NOT EXISTS source VARCHAR(20) DEFAULT 'manual'
    CHECK (source IN ('manual', 'ai_generated', 'imported')),
ADD COLUMN IF NOT EXISTS generation_id VARCHAR(50),
ADD COLUMN IF NOT EXISTS review_status VARCHAR(20) DEFAULT 'approved'
    CHECK (review_status IN ('pending', 'approved', 'rejected')),
ADD COLUMN IF NOT EXISTS reviewer_id INTEGER REFERENCES users(id) ON DELETE SET NULL,
ADD COLUMN IF NOT EXISTS reviewed_at TIMESTAMP;

CREATE INDEX IF NOT EXISTS idx_questions_source ON questions(source);
CREATE INDEX IF NOT EXISTS idx_questions_generation ON questions(generation_id);
CREATE INDEX IF NOT EXISTS idx_questions_review_status ON questions(review_status);

COMMENT ON COLUMN questions.source IS '题目来源: manual=手动创建, ai_generated=AI生成, imported=批量导入';
COMMENT ON COLUMN questions.generation_id IS '关联的AI生成记录ID';
COMMENT ON COLUMN questions.review_status IS '审核状态: pending=待审核, approved=已批准, rejected=已拒绝';
COMMENT ON COLUMN questions.reviewer_id IS '审核人ID';
COMMENT ON COLUMN questions.reviewed_at IS '审核时间';

-- 扩展users表：添加最后登录信息
ALTER TABLE users
ADD COLUMN IF NOT EXISTS last_login_at TIMESTAMP,
ADD COLUMN IF NOT EXISTS last_login_ip VARCHAR(45);

CREATE INDEX IF NOT EXISTS idx_users_last_login ON users(last_login_at DESC);

COMMENT ON COLUMN users.last_login_at IS '最后登录时间';
COMMENT ON COLUMN users.last_login_ip IS '最后登录IP地址';

-- 创建用户状态变更历史表(用于追踪封禁/解封记录)
CREATE TABLE IF NOT EXISTS user_status_history (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    old_status VARCHAR(20) NOT NULL,
    new_status VARCHAR(20) NOT NULL,
    reason TEXT,
    operator_id INTEGER NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_status_history_user (user_id),
    INDEX idx_status_history_operator (operator_id),
    INDEX idx_status_history_created (created_at DESC)
);

COMMENT ON TABLE user_status_history IS '用户状态变更历史';
COMMENT ON COLUMN user_status_history.user_id IS '用户ID';
COMMENT ON COLUMN user_status_history.old_status IS '原状态';
COMMENT ON COLUMN user_status_history.new_status IS '新状态';
COMMENT ON COLUMN user_status_history.reason IS '变更原因';
COMMENT ON COLUMN user_status_history.operator_id IS '操作人ID(管理员)';
