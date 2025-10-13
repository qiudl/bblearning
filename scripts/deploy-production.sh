#!/bin/bash

# BBLearning 生产环境一键部署脚本
# 域名: bblearning.joylodging.com
# 服务器: ubuntu@192.144.174.87

set -e

# 颜色输出
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

SERVER="ubuntu@192.144.174.87"
DEPLOY_DIR="/opt/bblearning"
DOMAIN="bblearning.joylodging.com"
API_DOMAIN="api.bblearning.joylodging.com"

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}BBLearning 生产环境部署${NC}"
echo -e "${GREEN}========================================${NC}"
echo "域名: $DOMAIN"
echo "API域名: $API_DOMAIN"
echo "服务器: $SERVER"
echo ""

# 1. 检查SSH连接
echo -e "${YELLOW}[1/10] 检查SSH连接...${NC}"
if ssh -o ConnectTimeout=5 $SERVER "echo 'SSH连接成功'" > /dev/null 2>&1; then
    echo -e "${GREEN}✓ SSH连接正常${NC}"
else
    echo -e "${RED}✗ SSH连接失败，请检查网络或密钥配置${NC}"
    exit 1
fi

# 2. 准备服务器环境
echo -e "${YELLOW}[2/10] 准备服务器环境...${NC}"
ssh $SERVER << 'ENDSSH'
    # 更新系统
    sudo apt update

    # 安装Docker（如果未安装）
    if ! command -v docker &> /dev/null; then
        echo "安装Docker..."
        curl -fsSL https://get.docker.com | sudo sh
        sudo usermod -aG docker $USER
    fi

    # 安装Docker Compose（如果未安装）
    if ! command -v docker-compose &> /dev/null; then
        echo "安装Docker Compose..."
        sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        sudo chmod +x /usr/local/bin/docker-compose
    fi

    # 安装Nginx（如果未安装）
    if ! command -v nginx &> /dev/null; then
        echo "安装Nginx..."
        sudo apt install -y nginx
    fi

    # 安装Certbot（如果未安装）
    if ! command -v certbot &> /dev/null; then
        echo "安装Certbot..."
        sudo apt install -y certbot python3-certbot-nginx
    fi

    echo "✓ 服务器环境准备完成"
ENDSSH

# 3. 创建部署目录
echo -e "${YELLOW}[3/10] 创建部署目录...${NC}"
ssh $SERVER "sudo mkdir -p $DEPLOY_DIR && sudo chown -R ubuntu:ubuntu $DEPLOY_DIR"
echo -e "${GREEN}✓ 部署目录创建完成${NC}"

# 4. 上传项目文件
echo -e "${YELLOW}[4/10] 上传项目文件...${NC}"
rsync -avz --exclude='node_modules' --exclude='.git' --exclude='build' --exclude='bin' \
    ./ $SERVER:$DEPLOY_DIR/
echo -e "${GREEN}✓ 项目文件上传完成${NC}"

# 5. 构建前端
echo -e "${YELLOW}[5/10] 构建前端...${NC}"
cd frontend
npm run build
rsync -avz build/ $SERVER:$DEPLOY_DIR/frontend/build/
cd ..
echo -e "${GREEN}✓ 前端构建完成${NC}"

# 6. 启动Docker容器
echo -e "${YELLOW}[6/10] 启动Docker容器...${NC}"
ssh $SERVER << ENDSSH
    cd $DEPLOY_DIR
    docker-compose -f docker-compose.prod.yml down
    docker-compose -f docker-compose.prod.yml build
    docker-compose -f docker-compose.prod.yml up -d

    # 等待服务启动
    echo "等待服务启动..."
    sleep 10

    # 检查服务状态
    docker-compose -f docker-compose.prod.yml ps
ENDSSH
echo -e "${GREEN}✓ Docker容器启动完成${NC}"

# 7. 运行数据库迁移
echo -e "${YELLOW}[7/10] 运行数据库迁移...${NC}"
ssh $SERVER << ENDSSH
    cd $DEPLOY_DIR
    docker-compose -f docker-compose.prod.yml exec -T backend make migrate-up
ENDSSH
echo -e "${GREEN}✓ 数据库迁移完成${NC}"

# 8. 配置Nginx
echo -e "${YELLOW}[8/10] 配置Nginx...${NC}"
ssh $SERVER << 'ENDSSH'
    # 创建Nginx配置
    sudo tee /etc/nginx/sites-available/bblearning > /dev/null << 'EOF'
# HTTP - 重定向到HTTPS
server {
    listen 80;
    listen [::]:80;
    server_name bblearning.joylodging.com;

    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
    }

    location / {
        return 301 https://$server_name$request_uri;
    }
}

# API HTTP - 重定向到HTTPS
server {
    listen 80;
    listen [::]:80;
    server_name api.bblearning.joylodging.com;

    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
    }

    location / {
        return 301 https://$server_name$request_uri;
    }
}

# HTTPS - 前端
server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name bblearning.joylodging.com;

    # SSL证书路径（稍后由certbot自动配置）
    ssl_certificate /etc/letsencrypt/live/bblearning.joylodging.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/bblearning.joylodging.com/privkey.pem;

    # SSL配置
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;

    # 根目录
    root /opt/bblearning/frontend/build;
    index index.html;

    # Gzip压缩
    gzip on;
    gzip_types text/plain text/css application/json application/javascript text/xml application/xml application/xml+rss text/javascript;
    gzip_comp_level 6;
    gzip_min_length 1000;

    # 前端路由
    location / {
        try_files $uri $uri/ /index.html;
    }

    # 静态资源缓存
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }

    # 安全头
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
}

# HTTPS - API
server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name api.bblearning.joylodging.com;

    # SSL证书路径
    ssl_certificate /etc/letsencrypt/live/api.bblearning.joylodging.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/api.bblearning.joylodging.com/privkey.pem;

    # SSL配置
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;

    # 反向代理到后端
    location / {
        proxy_pass http://localhost:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        # 超时配置
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;

        # WebSocket支持
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }
}
EOF

    # 启用配置
    sudo ln -sf /etc/nginx/sites-available/bblearning /etc/nginx/sites-enabled/

    # 删除默认配置
    sudo rm -f /etc/nginx/sites-enabled/default

    # 测试配置（暂时注释SSL行）
    sudo sed -i 's/ssl_certificate/#ssl_certificate/g' /etc/nginx/sites-available/bblearning
    sudo nginx -t && sudo systemctl reload nginx

    echo "✓ Nginx配置完成"
ENDSSH
echo -e "${GREEN}✓ Nginx配置完成${NC}"

# 9. 申请SSL证书
echo -e "${YELLOW}[9/10] 申请SSL证书...${NC}"
ssh $SERVER << ENDSSH
    # 创建certbot目录
    sudo mkdir -p /var/www/certbot

    # 申请主域名证书
    sudo certbot certonly --nginx \
        -d bblearning.joylodging.com \
        --non-interactive \
        --agree-tos \
        --email admin@joylodging.com \
        || true

    # 申请API域名证书
    sudo certbot certonly --nginx \
        -d api.bblearning.joylodging.com \
        --non-interactive \
        --agree-tos \
        --email admin@joylodging.com \
        || true

    # 恢复SSL配置
    sudo sed -i 's/#ssl_certificate/ssl_certificate/g' /etc/nginx/sites-available/bblearning

    # 重新加载Nginx
    sudo nginx -t && sudo systemctl reload nginx

    echo "✓ SSL证书申请完成"
ENDSSH
echo -e "${GREEN}✓ SSL证书配置完成${NC}"

# 10. 验证部署
echo -e "${YELLOW}[10/10] 验证部署...${NC}"
echo "检查后端健康状态..."
if curl -f https://api.bblearning.joylodging.com/health > /dev/null 2>&1; then
    echo -e "${GREEN}✓ 后端API正常${NC}"
else
    echo -e "${YELLOW}⚠ 后端API可能还在启动中${NC}"
fi

echo "检查前端访问..."
if curl -f https://bblearning.joylodging.com > /dev/null 2>&1; then
    echo -e "${GREEN}✓ 前端页面正常${NC}"
else
    echo -e "${YELLOW}⚠ 前端页面可能还在配置中${NC}"
fi

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}部署完成！${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "访问地址:"
echo "  前端: https://bblearning.joylodging.com"
echo "  API:  https://api.bblearning.joylodging.com"
echo ""
echo "后续操作:"
echo "  1. 访问前端页面测试注册登录"
echo "  2. 查看日志: ssh $SERVER 'cd $DEPLOY_DIR && docker-compose -f docker-compose.prod.yml logs -f'"
echo "  3. 查看服务状态: ssh $SERVER 'cd $DEPLOY_DIR && docker-compose -f docker-compose.prod.yml ps'"
echo ""
