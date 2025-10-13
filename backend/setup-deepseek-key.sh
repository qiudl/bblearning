#!/bin/bash

# DeepSeek API密钥设置脚本
# 此脚本将DeepSeek API密钥加密存储到数据库中

set -e

echo "========================================"
echo "DeepSeek API密钥配置"
echo "========================================"
echo ""

# 检查ENCRYPTION_MASTER_KEY环境变量
if [ -z "$ENCRYPTION_MASTER_KEY" ]; then
    echo "错误: ENCRYPTION_MASTER_KEY 环境变量未设置"
    echo "请先设置环境变量或在 .env.production 中配置"
    exit 1
fi

# 检查数据库连接
echo "检查数据库连接..."
if ! psql -h localhost -p 5432 -U bblearning_prod -d bblearning_production -c "SELECT 1" > /dev/null 2>&1; then
    echo "错误: 无法连接到数据库"
    echo "请确保 PostgreSQL 服务正在运行"
    echo "运行: docker-compose up -d postgres"
    exit 1
fi

echo "✓ 数据库连接正常"
echo ""

# 运行数据库迁移
echo "运行数据库迁移..."
cd "$(dirname "$0")"
if [ ! -f "bin/server" ]; then
    echo "错误: 未找到服务器二进制文件"
    echo "请先编译: go build -o bin/server ./cmd/server"
    exit 1
fi

# 使用migrate工具运行迁移
if command -v migrate &> /dev/null; then
    migrate -path migrations -database "postgresql://bblearning_prod:BBLearning2025Prod!SecureDB#@localhost:5432/bblearning_production?sslmode=disable" up
    echo "✓ 数据库迁移完成"
else
    echo "警告: migrate工具未安装，跳过迁移"
    echo "请手动运行: make migrate-up"
fi

echo ""

# 添加DeepSeek API密钥
echo "添加DeepSeek API密钥到数据库..."
./bin/apikey -action=add \
  -provider=deepseek \
  -name=default \
  -key="sk-b6c8b9260bdb4cd4bb7252e010540277" \
  -desc="DeepSeek生产环境密钥" \
  -priority=100

echo ""
echo "========================================"
echo "✓ DeepSeek API密钥配置完成"
echo "========================================"
echo ""

# 测试密钥解密
echo "测试密钥解密功能..."
./bin/apikey -action=test -provider=deepseek -name=default

echo ""
echo "配置成功！现在可以使用AI服务了。"
echo ""
