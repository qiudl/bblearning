-- API密钥加密存储表
CREATE TABLE api_keys (
    id BIGSERIAL PRIMARY KEY,

    -- 服务提供商信息
    provider VARCHAR(50) NOT NULL,              -- 服务提供商：deepseek, openai, anthropic等
    key_name VARCHAR(100) NOT NULL,             -- 密钥名称标识（如：default, backup, test）

    -- 加密信息
    encrypted_key TEXT NOT NULL,                -- AES-256-GCM加密后的API密钥（base64编码）
    encryption_salt VARCHAR(64) NOT NULL,       -- 加密盐值（hex编码，32字节）
    encryption_nonce VARCHAR(64) NOT NULL,      -- GCM模式的nonce（hex编码，12字节）

    -- 状态和配置
    is_active BOOLEAN DEFAULT true NOT NULL,    -- 是否启用
    priority INTEGER DEFAULT 0,                 -- 优先级（数字越大优先级越高，支持主备切换）

    -- 元数据
    description TEXT,                           -- 描述信息
    metadata JSONB,                             -- 额外元数据（如配额限制、使用统计等）

    -- 审计信息
    created_at TIMESTAMP DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMP DEFAULT NOW() NOT NULL,
    created_by BIGINT REFERENCES users(id),     -- 创建者
    updated_by BIGINT REFERENCES users(id),     -- 最后更新者

    -- 使用统计（可选）
    last_used_at TIMESTAMP,                     -- 最后使用时间
    usage_count BIGINT DEFAULT 0,               -- 使用次数

    -- 唯一约束：同一提供商的同名密钥只能有一个
    CONSTRAINT uk_api_keys_provider_name UNIQUE(provider, key_name)
);

-- 索引
CREATE INDEX idx_api_keys_provider ON api_keys(provider);
CREATE INDEX idx_api_keys_active ON api_keys(is_active);
CREATE INDEX idx_api_keys_priority ON api_keys(priority DESC);
CREATE INDEX idx_api_keys_provider_active ON api_keys(provider, is_active);

-- 审计日志表
CREATE TABLE api_key_audit_logs (
    id BIGSERIAL PRIMARY KEY,
    api_key_id BIGINT REFERENCES api_keys(id) ON DELETE SET NULL,

    -- 操作信息
    action VARCHAR(20) NOT NULL,                -- 操作类型：create, update, delete, activate, deactivate
    operator_id BIGINT REFERENCES users(id),    -- 操作者
    operator_ip VARCHAR(45),                    -- 操作者IP

    -- 变更内容
    old_value JSONB,                            -- 变更前的值（不包含密钥明文）
    new_value JSONB,                            -- 变更后的值（不包含密钥明文）

    -- 审计元数据
    created_at TIMESTAMP DEFAULT NOW() NOT NULL,
    user_agent TEXT,                            -- 用户代理
    request_id VARCHAR(100)                     -- 请求ID（用于追踪）
);

-- 审计日志索引
CREATE INDEX idx_api_key_audit_logs_key_id ON api_key_audit_logs(api_key_id);
CREATE INDEX idx_api_key_audit_logs_operator ON api_key_audit_logs(operator_id);
CREATE INDEX idx_api_key_audit_logs_created_at ON api_key_audit_logs(created_at DESC);
CREATE INDEX idx_api_key_audit_logs_action ON api_key_audit_logs(action);

-- 注释
COMMENT ON TABLE api_keys IS 'API密钥加密存储表';
COMMENT ON COLUMN api_keys.provider IS '服务提供商：deepseek, openai, anthropic等';
COMMENT ON COLUMN api_keys.key_name IS '密钥名称标识，如default, backup, test';
COMMENT ON COLUMN api_keys.encrypted_key IS 'AES-256-GCM加密后的API密钥';
COMMENT ON COLUMN api_keys.encryption_salt IS '加密盐值，每条记录独立';
COMMENT ON COLUMN api_keys.encryption_nonce IS 'GCM模式的随机数';
COMMENT ON COLUMN api_keys.is_active IS '是否启用，支持临时禁用密钥';
COMMENT ON COLUMN api_keys.priority IS '优先级，数字越大优先级越高，支持主备切换';
COMMENT ON COLUMN api_keys.metadata IS '扩展元数据，存储配额、限制等信息';

COMMENT ON TABLE api_key_audit_logs IS 'API密钥操作审计日志';
COMMENT ON COLUMN api_key_audit_logs.action IS '操作类型：create, update, delete, activate, deactivate';
COMMENT ON COLUMN api_key_audit_logs.old_value IS '变更前的值（脱敏）';
COMMENT ON COLUMN api_key_audit_logs.new_value IS '变更后的值（脱敏）';
