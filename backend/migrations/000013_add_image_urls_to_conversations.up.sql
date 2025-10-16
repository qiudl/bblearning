-- 为ai_conversations表添加image_urls字段，用于存储MinIO上传的图片URL列表
ALTER TABLE ai_conversations
ADD COLUMN IF NOT EXISTS image_urls TEXT[] DEFAULT ARRAY[]::TEXT[];

-- 添加索引以加速查询包含图片的对话
CREATE INDEX IF NOT EXISTS idx_ai_conversations_has_images
ON ai_conversations ((CASE WHEN array_length(image_urls, 1) > 0 THEN 1 ELSE 0 END));

-- 添加注释
COMMENT ON COLUMN ai_conversations.image_urls IS '图片MinIO存储URL列表';
