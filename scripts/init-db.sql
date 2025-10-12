-- 初始化数据库脚本
-- 此脚本在 PostgreSQL 容器首次启动时自动执行

-- 设置时区
SET timezone = 'Asia/Shanghai';

-- 创建扩展
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 创建初始索引（表将由 GORM 自动创建）
-- 但我们可以在这里创建一些额外的索引来优化性能

-- 注意: 表会由 GORM AutoMigrate 创建,这里只做一些初始化工作

-- 创建一个函数来更新 updated_at 字段
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- 授予权限
GRANT ALL PRIVILEGES ON DATABASE bblearning_dev TO bblearning;

-- 打印初始化完成信息
DO $$
BEGIN
    RAISE NOTICE '数据库初始化完成! 时间: %', NOW();
END $$;
