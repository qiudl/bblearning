#!/bin/bash

# BBLearning 远程数据库模式停止脚本

set -e

echo "=========================================="
echo "  停止 BBLearning (远程数据库模式)"
echo "=========================================="
echo ""

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
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

# 恢复原始配置文件（如果需要）
echo -n "清理配置... "
cd /Users/johnqiu/coding/www/projects/bblearning/backend
if [ -f "config/config.yaml.backup" ]; then
    mv config/config.yaml.backup config/config.yaml
fi
echo -e "${GREEN}✓${NC}"

echo ""
echo "=========================================="
echo "  所有本地服务已停止"
echo "=========================================="
echo ""
echo -e "${YELLOW}注意: 远程数据库服务仍在运行（未被停止）${NC}"
echo ""
