-- 回滚AI对话记录表和统计表

-- 删除触发器
DROP TRIGGER IF EXISTS update_ai_conversations_updated_at ON ai_conversations;
DROP TRIGGER IF EXISTS update_daily_goals_updated_at ON daily_goals;
DROP TRIGGER IF EXISTS update_learning_statistics_updated_at ON learning_statistics;

-- 删除表
DROP TABLE IF EXISTS learning_statistics;
DROP TABLE IF EXISTS daily_goals;
DROP TABLE IF EXISTS ai_conversations;

-- 移除新增的User表字段
ALTER TABLE users DROP COLUMN IF EXISTS nickname;
ALTER TABLE users DROP COLUMN IF EXISTS phone_number;
ALTER TABLE users DROP COLUMN IF EXISTS email;
ALTER TABLE users DROP COLUMN IF EXISTS role;
ALTER TABLE users DROP COLUMN IF EXISTS status;
ALTER TABLE users DROP COLUMN IF EXISTS last_login_at;

-- 移除新增的Chapter表字段
ALTER TABLE chapters DROP COLUMN IF EXISTS chapter_number;
ALTER TABLE chapters DROP COLUMN IF EXISTS subject;
ALTER TABLE chapters DROP COLUMN IF EXISTS display_order;

-- 移除新增的KnowledgePoint表字段
DROP INDEX IF EXISTS idx_knowledge_points_parent_id;
ALTER TABLE knowledge_points DROP COLUMN IF EXISTS parent_id;
ALTER TABLE knowledge_points DROP COLUMN IF EXISTS type;
ALTER TABLE knowledge_points DROP COLUMN IF EXISTS description;
ALTER TABLE knowledge_points DROP COLUMN IF EXISTS video_url;
ALTER TABLE knowledge_points DROP COLUMN IF EXISTS prerequisites;
ALTER TABLE knowledge_points DROP COLUMN IF EXISTS tags;
ALTER TABLE knowledge_points DROP COLUMN IF EXISTS estimated_hours;
ALTER TABLE knowledge_points DROP COLUMN IF EXISTS display_order;
