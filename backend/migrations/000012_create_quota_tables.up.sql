-- AI配额系统相关表
-- Task #2596: 实现用户AI配额管理系统

-- 1. 用户AI配额主表
CREATE TABLE IF NOT EXISTS user_ai_quotas (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,

    -- 日配额
    daily_quota INT NOT NULL DEFAULT 10 CHECK (daily_quota >= 0),
    daily_used INT NOT NULL DEFAULT 0 CHECK (daily_used >= 0),
    daily_reset_at TIMESTAMP NOT NULL DEFAULT (CURRENT_DATE + INTERVAL '1 day'),

    -- 月配额
    monthly_quota INT NOT NULL DEFAULT 300 CHECK (monthly_quota >= 0),
    monthly_used INT NOT NULL DEFAULT 0 CHECK (monthly_used >= 0),
    monthly_reset_at TIMESTAMP NOT NULL DEFAULT (DATE_TRUNC('month', CURRENT_DATE) + INTERVAL '1 month'),

    -- 永久配额（不重置）
    permanent_quota INT NOT NULL DEFAULT 0 CHECK (permanent_quota >= 0),

    -- VIP相关
    is_vip BOOLEAN DEFAULT FALSE,
    vip_expire_at TIMESTAMP,

    -- 统计字段
    total_consumed BIGINT NOT NULL DEFAULT 0,
    last_consume_at TIMESTAMP,

    -- 审计字段
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP
);

-- 索引
CREATE INDEX idx_user_ai_quotas_user_id ON user_ai_quotas(user_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_user_ai_quotas_is_vip ON user_ai_quotas(is_vip) WHERE deleted_at IS NULL;
CREATE INDEX idx_user_ai_quotas_daily_reset ON user_ai_quotas(daily_reset_at) WHERE deleted_at IS NULL;
CREATE INDEX idx_user_ai_quotas_monthly_reset ON user_ai_quotas(monthly_reset_at) WHERE deleted_at IS NULL;

COMMENT ON TABLE user_ai_quotas IS '用户AI配额表';
COMMENT ON COLUMN user_ai_quotas.daily_quota IS '日配额限制';
COMMENT ON COLUMN user_ai_quotas.daily_used IS '今日已使用配额';
COMMENT ON COLUMN user_ai_quotas.daily_reset_at IS '日配额重置时间';
COMMENT ON COLUMN user_ai_quotas.monthly_quota IS '月配额限制';
COMMENT ON COLUMN user_ai_quotas.monthly_used IS '本月已使用配额';
COMMENT ON COLUMN user_ai_quotas.monthly_reset_at IS '月配额重置时间';
COMMENT ON COLUMN user_ai_quotas.permanent_quota IS '永久配额（充值获得，不重置）';
COMMENT ON COLUMN user_ai_quotas.is_vip IS '是否VIP用户';
COMMENT ON COLUMN user_ai_quotas.total_consumed IS '累计总消耗配额';

-- 2. AI配额使用日志表
CREATE TABLE IF NOT EXISTS ai_quota_logs (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,

    -- 配额类型: daily, monthly, permanent
    quota_type VARCHAR(20) NOT NULL CHECK (quota_type IN ('daily', 'monthly', 'permanent')),

    -- 消耗数量
    amount INT NOT NULL CHECK (amount > 0),

    -- 服务类型: chat, generate, grade, diagnose, ocr
    service_type VARCHAR(50) NOT NULL,

    -- 描述信息
    description TEXT,

    -- 请求元数据
    request_id VARCHAR(100),
    ip_address INET,
    user_agent TEXT,

    -- 审计字段
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP
);

-- 索引
CREATE INDEX idx_ai_quota_logs_user_id ON ai_quota_logs(user_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_ai_quota_logs_created_at ON ai_quota_logs(created_at DESC) WHERE deleted_at IS NULL;
CREATE INDEX idx_ai_quota_logs_quota_type ON ai_quota_logs(quota_type) WHERE deleted_at IS NULL;
CREATE INDEX idx_ai_quota_logs_service_type ON ai_quota_logs(service_type) WHERE deleted_at IS NULL;
CREATE INDEX idx_ai_quota_logs_user_created ON ai_quota_logs(user_id, created_at DESC) WHERE deleted_at IS NULL;

COMMENT ON TABLE ai_quota_logs IS 'AI配额使用日志表';
COMMENT ON COLUMN ai_quota_logs.quota_type IS '配额类型: daily-日配额, monthly-月配额, permanent-永久配额';
COMMENT ON COLUMN ai_quota_logs.amount IS '本次消耗的配额数量';
COMMENT ON COLUMN ai_quota_logs.service_type IS '服务类型: chat-对话, generate-生成题目, grade-批改, diagnose-诊断, ocr-图片识别';

-- 3. 配额充值记录表
CREATE TABLE IF NOT EXISTS quota_recharge_logs (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,

    -- 充值配额类型: daily, monthly, permanent
    quota_type VARCHAR(20) NOT NULL CHECK (quota_type IN ('daily', 'monthly', 'permanent')),

    -- 充值数量
    amount INT NOT NULL CHECK (amount > 0),

    -- 充值原因
    reason VARCHAR(100),

    -- 操作者ID（管理员充值时记录）
    operator_id BIGINT REFERENCES users(id) ON DELETE SET NULL,

    -- 充值方式: manual-手动, purchase-购买, reward-奖励, vip-VIP赠送
    recharge_method VARCHAR(20) NOT NULL DEFAULT 'manual',

    -- 订单号（购买充值时）
    order_id VARCHAR(100),

    -- 审计字段
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP
);

-- 索引
CREATE INDEX idx_quota_recharge_logs_user_id ON quota_recharge_logs(user_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_quota_recharge_logs_created_at ON quota_recharge_logs(created_at DESC) WHERE deleted_at IS NULL;
CREATE INDEX idx_quota_recharge_logs_order_id ON quota_recharge_logs(order_id) WHERE deleted_at IS NULL AND order_id IS NOT NULL;

COMMENT ON TABLE quota_recharge_logs IS '配额充值记录表';
COMMENT ON COLUMN quota_recharge_logs.quota_type IS '充值的配额类型';
COMMENT ON COLUMN quota_recharge_logs.amount IS '充值数量';
COMMENT ON COLUMN quota_recharge_logs.recharge_method IS '充值方式: manual-手动, purchase-购买, reward-奖励, vip-VIP赠送';

-- 触发器：更新 updated_at 字段
CREATE OR REPLACE FUNCTION update_user_ai_quotas_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_user_ai_quotas_updated_at
    BEFORE UPDATE ON user_ai_quotas
    FOR EACH ROW
    EXECUTE FUNCTION update_user_ai_quotas_updated_at();

-- 初始化现有用户的配额（如果有）
INSERT INTO user_ai_quotas (user_id, daily_quota, monthly_quota, permanent_quota)
SELECT id, 10, 300, 0
FROM users
WHERE NOT EXISTS (
    SELECT 1 FROM user_ai_quotas WHERE user_ai_quotas.user_id = users.id
)
ON CONFLICT (user_id) DO NOTHING;
