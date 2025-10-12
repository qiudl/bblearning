#!/bin/bash

# BBLearning 开发环境一键启动脚本

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}================================${NC}"
echo -e "${GREEN}BBLearning 开发环境启动脚本${NC}"
echo -e "${GREEN}================================${NC}"
echo ""

# 检查 Docker 是否安装
if ! command -v docker &> /dev/null; then
    echo -e "${RED}错误: Docker 未安装!${NC}"
    echo "请先安装 Docker: https://docs.docker.com/get-docker/"
    exit 1
fi

# 检查 Docker Compose 是否安装
if ! command -v docker-compose &> /dev/null; then
    echo -e "${RED}错误: Docker Compose 未安装!${NC}"
    echo "请先安装 Docker Compose: https://docs.docker.com/compose/install/"
    exit 1
fi

# 检查 Docker 是否运行
if ! docker info &> /dev/null; then
    echo -e "${RED}错误: Docker daemon 未运行!${NC}"
    echo "请先启动 Docker"
    exit 1
fi

echo -e "${YELLOW}步骤 1/5: 检查环境变量...${NC}"
if [ ! -f "./backend/.env" ]; then
    echo -e "${YELLOW}未找到 .env 文件,从 .env.example 创建...${NC}"
    cp ./backend/.env.example ./backend/.env
    echo -e "${GREEN}✓ .env 文件已创建${NC}"
else
    echo -e "${GREEN}✓ .env 文件已存在${NC}"
fi
echo ""

echo -e "${YELLOW}步骤 2/5: 停止现有容器...${NC}"
docker-compose down
echo -e "${GREEN}✓ 现有容器已停止${NC}"
echo ""

echo -e "${YELLOW}步骤 3/5: 构建镜像...${NC}"
docker-compose build --no-cache
echo -e "${GREEN}✓ 镜像构建完成${NC}"
echo ""

echo -e "${YELLOW}步骤 4/5: 启动服务...${NC}"
docker-compose up -d postgres redis minio
echo "等待数据库服务就绪..."
sleep 10

# 检查服务健康状态
echo "检查服务健康状态..."
for i in {1..30}; do
    if docker-compose ps | grep -q "healthy"; then
        echo -e "${GREEN}✓ 基础服务已就绪${NC}"
        break
    fi
    if [ $i -eq 30 ]; then
        echo -e "${RED}错误: 服务启动超时${NC}"
        docker-compose logs
        exit 1
    fi
    sleep 2
done

# 启动后端和前端
docker-compose up -d backend frontend
echo -e "${GREEN}✓ 所有服务已启动${NC}"
echo ""

echo -e "${YELLOW}步骤 5/5: 验证服务...${NC}"
sleep 5

# 检查各服务状态
services=("postgres" "redis" "minio" "backend" "frontend")
for service in "${services[@]}"; do
    if docker-compose ps | grep -q "$service.*Up"; then
        echo -e "${GREEN}✓ $service 运行中${NC}"
    else
        echo -e "${RED}✗ $service 未运行${NC}"
    fi
done
echo ""

echo -e "${GREEN}================================${NC}"
echo -e "${GREEN}启动完成!${NC}"
echo -e "${GREEN}================================${NC}"
echo ""
echo -e "${YELLOW}服务访问地址:${NC}"
echo -e "  前端:          http://localhost:3000"
echo -e "  后端API:       http://localhost:8080"
echo -e "  健康检查:      http://localhost:8080/health"
echo -e "  MinIO控制台:   http://localhost:9001 (minioadmin/minioadmin123)"
echo -e "  PostgreSQL:    localhost:5432 (bblearning/bblearning_dev_password)"
echo -e "  Redis:         localhost:6379"
echo ""
echo -e "${YELLOW}常用命令:${NC}"
echo -e "  查看日志:      docker-compose logs -f [service]"
echo -e "  停止服务:      docker-compose down"
echo -e "  重启服务:      docker-compose restart [service]"
echo -e "  查看状态:      docker-compose ps"
echo ""
echo -e "${GREEN}Happy Coding! 🚀${NC}"
