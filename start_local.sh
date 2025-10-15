#!/bin/bash

# BBLearning 本地启动脚本
# 使用非标准端口避免冲突
#
# 端口分配：
# - 后端: 9090 (避开8080)
# - 前端: 3002 (避开3000)
# - PostgreSQL: 5433 (避开5432)
# - Redis: 6380 (避开6379)
# - MinIO: 9001/9002
# - Prometheus: 9091 (避开9090后端端口 - 需调整)
# - Grafana: 3003 (避开3000/3001)

set -e  # 遇到错误立即退出

echo "=========================================="
echo "  BBLearning 本地启动脚本"
echo "=========================================="
echo ""

# 颜色定义
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# 检查Docker是否运行
check_docker() {
    echo -n "检查 Docker 状态... "
    if ! docker info > /dev/null 2>&1; then
        echo -e "${RED}失败${NC}"
        echo ""
        echo "❌ Docker 未运行！"
        echo ""
        echo "请先启动 Docker："
        echo "  - OrbStack: open -a OrbStack"
        echo "  - Docker Desktop: open -a 'Docker Desktop'"
        echo ""
        exit 1
    fi
    echo -e "${GREEN}✓${NC}"
}

# 启动依赖服务 (PostgreSQL, Redis, MinIO)
start_services() {
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📦 步骤 1: 启动依赖服务 (Docker Compose)"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    echo ""
    echo "启动服务: PostgreSQL (5433), Redis (6380), MinIO (9001)"

    cd /Users/johnqiu/coding/www/projects/bblearning

    # 只启动必要的服务，不启动Prometheus和Grafana（避免端口冲突）
    docker-compose up -d postgres redis minio

    echo ""
    echo -n "等待服务就绪"
    for i in {1..10}; do
        echo -n "."
        sleep 1
    done
    echo -e " ${GREEN}完成${NC}"

    echo ""
    echo "服务状态："
    docker-compose ps postgres redis minio
}

# 启动后端服务
start_backend() {
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🔧 步骤 2: 启动后端服务 (端口: 9090)"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    cd /Users/johnqiu/coding/www/projects/bblearning/backend

    # 清理旧的日志
    > /tmp/bblearning-backend.log

    # 后台启动后端
    echo ""
    echo "启动后端服务..."
    nohup go run cmd/server/main.go > /tmp/bblearning-backend.log 2>&1 &
    BACKEND_PID=$!

    echo "后端 PID: $BACKEND_PID"
    echo "日志文件: /tmp/bblearning-backend.log"

    # 等待后端启动
    echo -n "等待后端启动"
    for i in {1..15}; do
        if grep -q "Server starting" /tmp/bblearning-backend.log 2>/dev/null; then
            echo -e " ${GREEN}✓${NC}"
            break
        fi
        if grep -q "FATAL\|fatal\|Failed" /tmp/bblearning-backend.log 2>/dev/null; then
            echo -e " ${RED}✗${NC}"
            echo ""
            echo "❌ 后端启动失败！查看日志："
            tail -20 /tmp/bblearning-backend.log
            exit 1
        fi
        echo -n "."
        sleep 1
    done

    echo ""
    echo "后端状态检查..."
    sleep 2

    if curl -s http://localhost:9090/api/v1/health > /dev/null 2>&1; then
        echo -e "${GREEN}✓ 后端健康检查通过${NC}"
    else
        echo -e "${YELLOW}⚠ 后端健康检查失败（可能还在初始化）${NC}"
    fi

    echo ""
    echo "查看后端日志:"
    tail -10 /tmp/bblearning-backend.log
}

# 启动前端服务
start_frontend() {
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🎨 步骤 3: 启动前端服务 (端口: 3002)"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    cd /Users/johnqiu/coding/www/projects/bblearning/frontend

    # 检查是否需要安装依赖
    if [ ! -d "node_modules" ]; then
        echo ""
        echo "检测到未安装依赖，正在安装..."
        npm install
    fi

    # 设置前端端口为3002
    export PORT=3002

    echo ""
    echo "启动前端开发服务器（端口: 3002）..."

    # 后台启动前端
    nohup npm start > /tmp/bblearning-frontend.log 2>&1 &
    FRONTEND_PID=$!

    echo "前端 PID: $FRONTEND_PID"
    echo "日志文件: /tmp/bblearning-frontend.log"

    echo -n "等待前端编译"
    for i in {1..30}; do
        if grep -q "Compiled successfully\|webpack compiled" /tmp/bblearning-frontend.log 2>/dev/null; then
            echo -e " ${GREEN}✓${NC}"
            break
        fi
        echo -n "."
        sleep 1
    done
}

# 显示访问信息
show_info() {
    echo ""
    echo "=========================================="
    echo "  ✨ BBLearning 启动成功！"
    echo "=========================================="
    echo ""
    echo "📍 访问地址："
    echo "  ├─ 前端应用:    http://localhost:3002"
    echo "  ├─ 后端API:     http://localhost:9090"
    echo "  ├─ API文档:     http://localhost:9090/swagger/index.html (如已配置)"
    echo "  ├─ Metrics:     http://localhost:9090/metrics"
    echo "  └─ Health:      http://localhost:9090/api/v1/health"
    echo ""
    echo "💾 数据库连接："
    echo "  ├─ PostgreSQL:  localhost:5433"
    echo "  ├─ Redis:       localhost:6380"
    echo "  └─ MinIO:       http://localhost:9001 (minioadmin/minioadmin123)"
    echo ""
    echo "📊 监控（可选，需手动启动）："
    echo "  ├─ Prometheus:  docker-compose up -d prometheus"
    echo "  └─ Grafana:     docker-compose up -d grafana"
    echo ""
    echo "📝 日志文件："
    echo "  ├─ 后端:        tail -f /tmp/bblearning-backend.log"
    echo "  └─ 前端:        tail -f /tmp/bblearning-frontend.log"
    echo ""
    echo "🛑 停止服务："
    echo "  ├─ 停止所有:    ./stop_local.sh"
    echo "  ├─ 后端进程:    pkill -f 'go run cmd/server/main.go'"
    echo "  ├─ 前端进程:    pkill -f 'npm start'"
    echo "  └─ Docker:      docker-compose down"
    echo ""
    echo "=========================================="
    echo ""
}

# 主流程
main() {
    check_docker
    start_services
    start_backend
    start_frontend
    show_info
}

# 执行主流程
main
