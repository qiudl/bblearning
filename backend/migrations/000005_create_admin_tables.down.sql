-- 000005_create_admin_tables.down.sql
-- 回滚管理员系统相关表

-- 删除用户状态变更历史表
DROP TABLE IF EXISTS user_status_history;

-- 移除users表扩展字段
ALTER TABLE users
DROP COLUMN IF EXISTS last_login_ip,
DROP COLUMN IF EXISTS last_login_at;

-- 移除questions表扩展字段
DROP INDEX IF EXISTS idx_questions_review_status;
DROP INDEX IF EXISTS idx_questions_generation;
DROP INDEX IF EXISTS idx_questions_source;

ALTER TABLE questions
DROP COLUMN IF EXISTS reviewed_at,
DROP COLUMN IF EXISTS reviewer_id,
DROP COLUMN IF EXISTS review_status,
DROP COLUMN IF EXISTS generation_id,
DROP COLUMN IF EXISTS source;

-- 删除管理员操作日志表
DROP TABLE IF EXISTS admin_operation_logs;

-- 删除AI题目生成记录表
DROP TABLE IF EXISTS ai_generation_records;
