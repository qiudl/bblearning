#!/bin/bash

# BBLearning 本地停止脚本

set -e

echo "=========================================="
echo "  停止 BBLearning 本地服务"
echo "=========================================="
echo ""

GREEN='\033[0;32m'
NC='\033[0m'

# 停止后端
echo -n "停止后端服务... "
pkill -f 'go run cmd/server/main.go' 2>/dev/null || true
echo -e "${GREEN}✓${NC}"

# 停止前端
echo -n "停止前端服务... "
pkill -f 'npm start' 2>/dev/null || true
pkill -f 'react-scripts start' 2>/dev/null || true
echo -e "${GREEN}✓${NC}"

# 停止 Docker 服务
echo -n "停止 Docker 服务... "
cd /Users/johnqiu/coding/www/projects/bblearning
docker-compose down 2>/dev/null || true
echo -e "${GREEN}✓${NC}"

echo ""
echo "=========================================="
echo "  所有服务已停止"
echo "=========================================="
echo ""
