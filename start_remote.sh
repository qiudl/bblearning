#!/bin/bash

# BBLearning 本地启动脚本（使用远程数据库）
# 此脚本不启动本地数据库，而是连接到远程数据库
#
# 端口分配：
# - 后端: 9090 (避开8080)
# - 前端: 3002 (避开3000)
#
# 远程服务：
# - PostgreSQL: 远程服务器
# - Redis: 远程服务器
# - MinIO: 远程服务器或云存储

set -e  # 遇到错误立即退出

echo "=========================================="
echo "  BBLearning 本地启动（远程数据库）"
echo "=========================================="
echo ""

# 颜色定义
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# 检查远程配置文件
check_remote_config() {
    echo -n "检查远程数据库配置文件... "

    if [ ! -f "/Users/johnqiu/coding/www/projects/bblearning/backend/config/config-remote.yaml" ]; then
        echo -e "${RED}失败${NC}"
        echo ""
        echo "❌ 远程配置文件不存在！"
        echo ""
        echo "请先配置 backend/config/config-remote.yaml"
        echo "需要设置："
        echo "  - 远程 PostgreSQL 连接信息"
        echo "  - 远程 Redis 连接信息"
        echo "  - 远程 MinIO/S3 连接信息"
        echo ""
        exit 1
    fi

    # 检查是否包含占位符
    if grep -q "your-remote-db-host.com" "/Users/johnqiu/coding/www/projects/bblearning/backend/config/config-remote.yaml"; then
        echo -e "${YELLOW}警告${NC}"
        echo ""
        echo "⚠️  检测到配置文件包含占位符！"
        echo ""
        echo "请编辑 backend/config/config-remote.yaml 并替换："
        echo "  - your-remote-db-host.com"
        echo "  - your-remote-db-password"
        echo "  - your-remote-redis-host.com"
        echo "  - your-remote-minio.com"
        echo ""
        read -p "是否继续？(y/N) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    else
        echo -e "${GREEN}✓${NC}"
    fi
}

# 测试远程数据库连接
test_remote_connection() {
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🔌 步骤 1: 测试远程服务连接"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    cd /Users/johnqiu/coding/www/projects/bblearning/backend

    # 读取配置
    DB_HOST=$(grep "host:" config/config-remote.yaml | head -1 | awk '{print $2}' | tr -d '"')
    DB_PORT=$(grep "port:" config/config-remote.yaml | head -1 | awk '{print $2}')

    echo ""
    echo "数据库地址: $DB_HOST:$DB_PORT"

    # 测试连接（可选）
    echo -n "跳过连接测试（启动后端时会自动验证）... "
    echo -e "${GREEN}✓${NC}"
}

# 启动后端服务
start_backend() {
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🔧 步骤 2: 启动后端服务 (端口: 9090)"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    cd /Users/johnqiu/coding/www/projects/bblearning/backend

    # 清理旧的日志
    > /tmp/bblearning-backend-remote.log

    # 复制远程配置为主配置（临时）
    echo "使用远程数据库配置..."
    cp config/config-remote.yaml config/config.yaml

    # 后台启动后端
    echo ""
    echo "启动后端服务..."
    nohup go run cmd/server/main.go > /tmp/bblearning-backend-remote.log 2>&1 &
    BACKEND_PID=$!

    echo "后端 PID: $BACKEND_PID"
    echo "日志文件: /tmp/bblearning-backend-remote.log"

    # 等待后端启动
    echo -n "等待后端启动"
    for i in {1..20}; do
        if grep -q "Server starting" /tmp/bblearning-backend-remote.log 2>/dev/null; then
            echo -e " ${GREEN}✓${NC}"
            break
        fi
        if grep -q "FATAL\|fatal\|Failed to initialize database" /tmp/bblearning-backend-remote.log 2>/dev/null; then
            echo -e " ${RED}✗${NC}"
            echo ""
            echo "❌ 后端启动失败！可能的原因："
            echo "  1. 远程数据库连接失败"
            echo "  2. 数据库凭证不正确"
            echo "  3. 网络无法访问远程服务器"
            echo ""
            echo "错误日志："
            tail -20 /tmp/bblearning-backend-remote.log
            echo ""
            echo "请检查 config/config-remote.yaml 中的配置"
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
        echo -e "${GREEN}✓ 远程数据库连接成功${NC}"
    else
        echo -e "${YELLOW}⚠ 后端健康检查失败（可能还在初始化）${NC}"
        echo "等待5秒后再次检查..."
        sleep 5
        if curl -s http://localhost:9090/api/v1/health > /dev/null 2>&1; then
            echo -e "${GREEN}✓ 后端健康检查通过${NC}"
        else
            echo -e "${RED}✗ 后端启动失败${NC}"
            echo "请查看日志: tail -f /tmp/bblearning-backend-remote.log"
        fi
    fi

    echo ""
    echo "查看后端日志（最后10行）:"
    tail -10 /tmp/bblearning-backend-remote.log
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
    nohup npm start > /tmp/bblearning-frontend-remote.log 2>&1 &
    FRONTEND_PID=$!

    echo "前端 PID: $FRONTEND_PID"
    echo "日志文件: /tmp/bblearning-frontend-remote.log"

    echo -n "等待前端编译"
    for i in {1..30}; do
        if grep -q "Compiled successfully\|webpack compiled" /tmp/bblearning-frontend-remote.log 2>/dev/null; then
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
    echo "  ✨ BBLearning 启动成功（远程数据库）"
    echo "=========================================="
    echo ""
    echo "📍 访问地址："
    echo "  ├─ 前端应用:    http://localhost:3002"
    echo "  ├─ 后端API:     http://localhost:9090"
    echo "  ├─ API文档:     http://localhost:9090/swagger/index.html"
    echo "  ├─ Metrics:     http://localhost:9090/metrics"
    echo "  └─ Health:      http://localhost:9090/api/v1/health"
    echo ""
    echo "🌐 远程服务："
    echo "  ├─ PostgreSQL:  远程数据库服务器"
    echo "  ├─ Redis:       远程缓存服务器"
    echo "  └─ MinIO/S3:    远程对象存储"
    echo ""
    echo "📝 日志文件："
    echo "  ├─ 后端:        tail -f /tmp/bblearning-backend-remote.log"
    echo "  └─ 前端:        tail -f /tmp/bblearning-frontend-remote.log"
    echo ""
    echo "🛑 停止服务："
    echo "  ├─ 停止所有:    ./stop_remote.sh"
    echo "  ├─ 后端进程:    pkill -f 'go run cmd/server/main.go'"
    echo "  └─ 前端进程:    pkill -f 'npm start'"
    echo ""
    echo "⚠️  注意事项："
    echo "  - 确保远程服务器防火墙允许你的IP访问"
    echo "  - 确保数据库用户有足够的权限"
    echo "  - 网络延迟可能影响性能"
    echo ""
    echo "=========================================="
    echo ""
}

# 主流程
main() {
    check_remote_config
    test_remote_connection
    start_backend
    start_frontend
    show_info
}

# 执行主流程
main
