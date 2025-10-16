-- 回滚：删除image_urls字段和相关索引
DROP INDEX IF EXISTS idx_ai_conversations_has_images;

ALTER TABLE ai_conversations
DROP COLUMN IF EXISTS image_urls;
