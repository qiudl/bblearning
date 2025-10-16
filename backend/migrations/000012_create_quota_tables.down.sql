-- 回滚AI配额系统相关表
-- Task #2596: 实现用户AI配额管理系统

-- 删除触发器
DROP TRIGGER IF EXISTS trigger_update_user_ai_quotas_updated_at ON user_ai_quotas;
DROP FUNCTION IF EXISTS update_user_ai_quotas_updated_at();

-- 删除表（按依赖关系倒序删除）
DROP TABLE IF EXISTS quota_recharge_logs;
DROP TABLE IF EXISTS ai_quota_logs;
DROP TABLE IF EXISTS user_ai_quotas;
