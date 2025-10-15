#!/usr/bin/env bash
# BBLearning 简化版启动脚本（兼容性更好）

set -e

echo "======================================"
echo "BBLearning 快速启动"
echo "======================================"

# 检查Docker
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker未运行，请先启动Docker Desktop或OrbStack"
    exit 1
fi
echo "✅ Docker已运行"

# 启动Docker服务
cd /Users/johnqiu/coding/www/projects/bblearning
echo ""
echo "📦 启动Docker服务..."
docker-compose up -d postgres redis minio
sleep 3

# 检查服务状态
echo ""
echo "📊 服务状态:"
docker-compose ps

# 进入后端目录
cd backend

# 检查.env
if [ ! -f ".env" ]; then
    echo ""
    echo "⚠️  创建.env文件..."
    cp .env.example .env 2>/dev/null || cat > .env << 'ENVEOF'
DB_HOST=localhost
DB_PORT=5432
DB_USER=postgres
DB_PASSWORD=postgres
DB_NAME=bblearning_dev
REDIS_HOST=localhost
REDIS_PORT=6379
JWT_SECRET=bblearning_dev_secret_key
ENCRYPTION_MASTER_KEY=0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef
SERVER_PORT=8080
GIN_MODE=debug
ENVEOF
fi

# 启动后端
echo ""
echo "🚀 启动后端服务..."
echo "API地址: http://localhost:8080"
echo "按 Ctrl+C 停止服务"
echo ""

go run cmd/server/main.go
