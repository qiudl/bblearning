# BBLearning 部署文档

本文档详细说明BBLearning项目的完整部署流程，包括开发环境、测试环境和生产环境的配置。

---

## 目录

1. [系统要求](#系统要求)
2. [开发环境部署](#开发环境部署)
3. [生产环境部署](#生产环境部署)
4. [Docker部署（推荐）](#docker部署推荐)
5. [监控和运维](#监控和运维)
6. [常见问题](#常见问题)

---

## 系统要求

### 最低配置
- **CPU**: 2核
- **内存**: 4GB RAM
- **存储**: 20GB 可用空间
- **操作系统**: Linux (Ubuntu 20.04+), macOS 12+
- **网络**: 稳定的互联网连接

### 推荐配置（生产环境）
- **CPU**: 4核+
- **内存**: 8GB+ RAM
- **存储**: 50GB+ SSD
- **操作系统**: Ubuntu 22.04 LTS
- **网络**: 100Mbps+ 带宽

### 软件依赖

#### 后端
- Go 1.23+
- PostgreSQL 15+
- Redis 7+
- MinIO (可选，用于文件存储)

#### 前端
- Node.js 18+ (推荐 v18.17.0)
- npm 9+ 或 yarn 1.22+

#### 通用工具
- Docker 24+ 和 Docker Compose 2.20+ (推荐使用Docker部署)
- Git 2.30+
- Make (可选，用于快捷命令)

---

## 开发环境部署

### 方式1: Docker Compose（推荐）

#### 1. 克隆项目

```bash
git clone <repository-url>
cd bblearning
```

#### 2. 配置环境变量

```bash
# 后端配置
cp backend/.env.example backend/.env

# 编辑配置
vim backend/.env
```

**关键配置项**:
```env
# 数据库配置
DB_HOST=postgres
DB_PORT=5432
DB_USER=bblearning
DB_PASSWORD=your_strong_password
DB_NAME=bblearning_dev

# Redis配置
REDIS_HOST=redis
REDIS_PORT=6379
REDIS_PASSWORD=

# JWT配置
JWT_SECRET=your_jwt_secret_here
JWT_ACCESS_EXPIRE=3600
JWT_REFRESH_EXPIRE=604800

# AI服务配置
OPENAI_API_KEY=your_openai_api_key
OPENAI_MODEL=gpt-4o-mini

# 服务端口
SERVER_PORT=8080
```

#### 3. 启动所有服务

```bash
# 启动所有服务（后台运行）
docker-compose up -d

# 查看服务状态
docker-compose ps

# 查看日志
docker-compose logs -f
```

#### 4. 初始化数据库

```bash
# 运行数据库迁移
docker-compose exec backend make migrate-up

# 插入种子数据（可选）
docker-compose exec backend make seed
```

#### 5. 访问应用

- **前端**: http://localhost:3000
- **后端API**: http://localhost:8080
- **API文档**: http://localhost:8080/swagger/index.html
- **PostgreSQL**: localhost:5432
- **Redis**: localhost:6379
- **MinIO控制台**: http://localhost:9001

#### 6. 停止服务

```bash
# 停止所有服务
docker-compose down

# 停止并删除数据卷（⚠️ 会清除所有数据）
docker-compose down -v
```

---

### 方式2: 本地开发（无Docker）

#### 1. 启动PostgreSQL

```bash
# macOS (Homebrew)
brew install postgresql@15
brew services start postgresql@15

# Ubuntu
sudo apt install postgresql-15
sudo systemctl start postgresql

# 创建数据库
createdb bblearning_dev
```

#### 2. 启动Redis

```bash
# macOS
brew install redis
brew services start redis

# Ubuntu
sudo apt install redis-server
sudo systemctl start redis
```

#### 3. 启动后端

```bash
cd backend/

# 安装依赖
go mod download

# 运行迁移
make migrate-up

# 启动服务
make run

# 或直接运行
go run cmd/server/main.go
```

#### 4. 启动前端

```bash
cd frontend/

# 安装依赖
npm install

# 启动开发服务器
npm start
```

---

## 生产环境部署

### 架构图

```
                    ┌─────────────┐
                    │   用户      │
                    └──────┬──────┘
                           │ HTTPS
                    ┌──────▼──────┐
                    │   Nginx     │ (反向代理 + SSL)
                    │  (443/80)   │
                    └──────┬──────┘
                           │
          ┌────────────────┼────────────────┐
          │                │                │
   ┌──────▼──────┐  ┌─────▼─────┐   ┌─────▼─────┐
   │  Frontend   │  │  Backend  │   │   MinIO   │
   │  (Static)   │  │  (Go API) │   │  (Files)  │
   └─────────────┘  └─────┬─────┘   └───────────┘
                          │
          ┌───────────────┼───────────────┐
          │               │               │
   ┌──────▼──────┐ ┌─────▼─────┐  ┌─────▼─────┐
   │ PostgreSQL  │ │   Redis   │  │  OpenAI   │
   │ (Database)  │ │  (Cache)  │  │   API     │
   └─────────────┘ └───────────┘  └───────────┘
```

### 步骤1: 准备服务器

#### 1.1 更新系统

```bash
sudo apt update
sudo apt upgrade -y
```

#### 1.2 安装必要工具

```bash
# 安装Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
sudo usermod -aG docker $USER

# 安装Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# 安装Nginx
sudo apt install nginx -y
```

#### 1.3 配置防火墙

```bash
sudo ufw allow 22/tcp    # SSH
sudo ufw allow 80/tcp    # HTTP
sudo ufw allow 443/tcp   # HTTPS
sudo ufw enable
```

---

### 步骤2: 部署后端

#### 2.1 配置生产环境变量

```bash
# 创建生产配置
cp backend/.env.example backend/.env.production

# 编辑配置（⚠️ 使用强密码）
vim backend/.env.production
```

**生产环境配置示例**:
```env
# 应用模式
APP_ENV=production
APP_DEBUG=false

# 数据库配置（使用强密码）
DB_HOST=postgres
DB_PORT=5432
DB_USER=bblearning_prod
DB_PASSWORD=<strong_password>
DB_NAME=bblearning_production
DB_SSLMODE=require

# Redis配置
REDIS_HOST=redis
REDIS_PORT=6379
REDIS_PASSWORD=<redis_password>

# JWT配置（⚠️ 使用64字符随机字符串）
JWT_SECRET=<64_random_characters>
JWT_ACCESS_EXPIRE=3600
JWT_REFRESH_EXPIRE=604800

# AI服务
OPENAI_API_KEY=<your_production_api_key>
OPENAI_MODEL=gpt-4o-mini
OPENAI_MAX_TOKENS=2000

# 服务配置
SERVER_HOST=0.0.0.0
SERVER_PORT=8080
CORS_ALLOWED_ORIGINS=https://yourdomain.com
```

#### 2.2 构建后端Docker镜像

```bash
cd backend/

# 构建生产镜像
docker build -t bblearning-backend:latest -f Dockerfile .

# 或使用docker-compose
docker-compose -f docker-compose.prod.yml build backend
```

#### 2.3 运行数据库迁移

```bash
# 运行迁移
docker-compose -f docker-compose.prod.yml run --rm backend make migrate-up
```

---

### 步骤3: 部署前端

#### 3.1 配置生产环境变量

```bash
# 创建生产配置
cat > frontend/.env.production << EOF
REACT_APP_API_URL=https://api.yourdomain.com
REACT_APP_WS_URL=wss://api.yourdomain.com
EOF
```

#### 3.2 构建生产版本

```bash
cd frontend/

# 安装依赖
npm ci --production=false

# 构建生产版本
npm run build

# 输出目录: build/
```

#### 3.3 部署到Nginx

```bash
# 复制构建文件到Nginx目录
sudo mkdir -p /var/www/bblearning
sudo cp -r build/* /var/www/bblearning/

# 设置权限
sudo chown -R www-data:www-data /var/www/bblearning
```

---

### 步骤4: 配置Nginx

#### 4.1 创建Nginx配置文件

```bash
sudo vim /etc/nginx/sites-available/bblearning
```

**配置内容**:
```nginx
# 前端服务器配置
server {
    listen 80;
    server_name yourdomain.com www.yourdomain.com;

    # 重定向到HTTPS
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name yourdomain.com www.yourdomain.com;

    # SSL证书配置
    ssl_certificate /etc/letsencrypt/live/yourdomain.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/yourdomain.com/privkey.pem;

    # SSL安全配置
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;

    # 根目录
    root /var/www/bblearning;
    index index.html;

    # Gzip压缩
    gzip on;
    gzip_types text/plain text/css application/json application/javascript text/xml application/xml+rss text/javascript;
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

# 后端API服务器配置
server {
    listen 443 ssl http2;
    server_name api.yourdomain.com;

    # SSL证书配置
    ssl_certificate /etc/letsencrypt/live/api.yourdomain.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/api.yourdomain.com/privkey.pem;

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

    # API速率限制
    limit_req_zone $binary_remote_addr zone=api_limit:10m rate=100r/m;
    limit_req zone=api_limit burst=20 nodelay;
}
```

#### 4.2 启用配置

```bash
# 创建软链接
sudo ln -s /etc/nginx/sites-available/bblearning /etc/nginx/sites-enabled/

# 测试配置
sudo nginx -t

# 重新加载Nginx
sudo systemctl reload nginx
```

---

### 步骤5: 配置SSL证书（Let's Encrypt）

#### 5.1 安装Certbot

```bash
sudo apt install certbot python3-certbot-nginx -y
```

#### 5.2 获取证书

```bash
# 为前端域名获取证书
sudo certbot --nginx -d yourdomain.com -d www.yourdomain.com

# 为API域名获取证书
sudo certbot --nginx -d api.yourdomain.com

# 测试自动续期
sudo certbot renew --dry-run
```

---

### 步骤6: 启动生产环境

#### 6.1 使用Docker Compose启动

```bash
# 创建生产环境docker-compose文件
cat > docker-compose.prod.yml << 'EOF'
version: '3.8'

services:
  postgres:
    image: postgres:15-alpine
    container_name: bblearning-postgres-prod
    environment:
      POSTGRES_USER: bblearning_prod
      POSTGRES_PASSWORD: ${DB_PASSWORD}
      POSTGRES_DB: bblearning_production
    volumes:
      - postgres_data:/var/lib/postgresql/data
    restart: always
    networks:
      - bblearning-network

  redis:
    image: redis:7-alpine
    container_name: bblearning-redis-prod
    command: redis-server --requirepass ${REDIS_PASSWORD}
    volumes:
      - redis_data:/data
    restart: always
    networks:
      - bblearning-network

  backend:
    build:
      context: ./backend
      dockerfile: Dockerfile
    container_name: bblearning-backend-prod
    env_file:
      - ./backend/.env.production
    ports:
      - "8080:8080"
    depends_on:
      - postgres
      - redis
    restart: always
    networks:
      - bblearning-network

  minio:
    image: minio/minio:latest
    container_name: bblearning-minio-prod
    command: server /data --console-address ":9001"
    environment:
      MINIO_ROOT_USER: ${MINIO_ROOT_USER}
      MINIO_ROOT_PASSWORD: ${MINIO_ROOT_PASSWORD}
    volumes:
      - minio_data:/data
    ports:
      - "9000:9000"
      - "9001:9001"
    restart: always
    networks:
      - bblearning-network

volumes:
  postgres_data:
  redis_data:
  minio_data:

networks:
  bblearning-network:
    driver: bridge
EOF

# 启动生产环境
docker-compose -f docker-compose.prod.yml up -d

# 查看日志
docker-compose -f docker-compose.prod.yml logs -f
```

---

## Docker部署（推荐）

### 完整Docker部署流程

#### 1. 准备部署脚本

```bash
# 创建部署脚本
cat > deploy.sh << 'EOF'
#!/bin/bash

set -e

echo "🚀 开始部署BBLearning..."

# 1. 拉取最新代码
echo "📥 拉取最新代码..."
git pull origin main

# 2. 备份数据库
echo "💾 备份数据库..."
docker-compose exec -T postgres pg_dump -U bblearning_prod bblearning_production > backup_$(date +%Y%m%d_%H%M%S).sql

# 3. 停止服务
echo "⏸️ 停止当前服务..."
docker-compose -f docker-compose.prod.yml down

# 4. 构建新镜像
echo "🔨 构建新镜像..."
docker-compose -f docker-compose.prod.yml build --no-cache

# 5. 启动服务
echo "▶️ 启动服务..."
docker-compose -f docker-compose.prod.yml up -d

# 6. 运行迁移
echo "🗄️ 运行数据库迁移..."
docker-compose -f docker-compose.prod.yml exec -T backend make migrate-up

# 7. 健康检查
echo "🏥 健康检查..."
sleep 5
curl -f http://localhost:8080/health || exit 1

echo "✅ 部署完成！"
EOF

chmod +x deploy.sh
```

#### 2. 执行部署

```bash
./deploy.sh
```

---

## 监控和运维

### 日志管理

#### 查看日志

```bash
# 查看所有服务日志
docker-compose logs -f

# 查看特定服务日志
docker-compose logs -f backend
docker-compose logs -f postgres

# 查看最近100行日志
docker-compose logs --tail=100 backend

# 查看Nginx日志
sudo tail -f /var/log/nginx/access.log
sudo tail -f /var/log/nginx/error.log
```

#### 日志轮转配置

```bash
# 创建Nginx日志轮转配置
sudo vim /etc/logrotate.d/nginx
```

```
/var/log/nginx/*.log {
    daily
    rotate 14
    compress
    delaycompress
    notifempty
    create 0640 www-data adm
    sharedscripts
    postrotate
        if [ -f /var/run/nginx.pid ]; then
            kill -USR1 `cat /var/run/nginx.pid`
        fi
    endscript
}
```

---

### 数据库备份

#### 自动备份脚本

```bash
# 创建备份脚本
cat > backup.sh << 'EOF'
#!/bin/bash

BACKUP_DIR="/var/backups/bblearning"
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="$BACKUP_DIR/bblearning_$DATE.sql"

mkdir -p $BACKUP_DIR

# 备份数据库
docker-compose exec -T postgres pg_dump -U bblearning_prod bblearning_production > $BACKUP_FILE

# 压缩备份
gzip $BACKUP_FILE

# 删除7天前的备份
find $BACKUP_DIR -name "*.sql.gz" -mtime +7 -delete

echo "备份完成: $BACKUP_FILE.gz"
EOF

chmod +x backup.sh
```

#### 设置定时备份

```bash
# 添加到crontab
crontab -e

# 每天凌晨2点备份
0 2 * * * /path/to/backup.sh >> /var/log/bblearning-backup.log 2>&1
```

---

### 性能监控

#### 安装监控工具

```bash
# 安装Docker监控工具
docker run -d \
  --name=cadvisor \
  --volume=/:/rootfs:ro \
  --volume=/var/run:/var/run:ro \
  --volume=/sys:/sys:ro \
  --volume=/var/lib/docker/:/var/lib/docker:ro \
  --publish=8081:8080 \
  --restart=always \
  gcr.io/cadvisor/cadvisor:latest

# 访问 http://your-server:8081 查看监控
```

#### 健康检查

```bash
# 后端健康检查
curl http://localhost:8080/health

# 数据库连接检查
docker-compose exec postgres pg_isready -U bblearning_prod

# Redis连接检查
docker-compose exec redis redis-cli ping
```

---

## 常见问题

### 1. 端口冲突

**问题**: 启动服务时提示端口已被占用

**解决方案**:
```bash
# 查看占用端口的进程
sudo lsof -i :8080
sudo lsof -i :3000

# 停止占用端口的进程
sudo kill -9 <PID>

# 或修改docker-compose.yml中的端口映射
```

---

### 2. 数据库连接失败

**问题**: 后端无法连接数据库

**排查步骤**:
```bash
# 1. 检查PostgreSQL是否运行
docker-compose ps postgres

# 2. 检查数据库日志
docker-compose logs postgres

# 3. 测试连接
docker-compose exec postgres psql -U bblearning_prod -d bblearning_production -c "SELECT 1;"

# 4. 检查网络
docker network ls
docker network inspect bblearning_bblearning-network
```

---

### 3. 前端无法访问API

**问题**: 前端请求后端API时出现CORS错误

**解决方案**:
```go
// backend/internal/api/middleware/cors.go
func CORS() gin.HandlerFunc {
    return func(c *gin.Context) {
        c.Writer.Header().Set("Access-Control-Allow-Origin", "https://yourdomain.com")
        c.Writer.Header().Set("Access-Control-Allow-Credentials", "true")
        c.Writer.Header().Set("Access-Control-Allow-Headers", "Content-Type, Authorization")
        c.Writer.Header().Set("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS")

        if c.Request.Method == "OPTIONS" {
            c.AbortWithStatus(204)
            return
        }

        c.Next()
    }
}
```

---

### 4. SSL证书问题

**问题**: SSL证书过期或配置错误

**解决方案**:
```bash
# 检查证书有效期
sudo certbot certificates

# 手动续期
sudo certbot renew

# 测试续期（不实际执行）
sudo certbot renew --dry-run

# 如果续期失败，重新获取证书
sudo certbot --nginx -d yourdomain.com --force-renewal
```

---

### 5. 内存不足

**问题**: 服务器内存不足导致服务崩溃

**解决方案**:
```bash
# 1. 增加Swap空间
sudo fallocate -l 2G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab

# 2. 限制Docker容器内存
# docker-compose.yml
services:
  backend:
    mem_limit: 512m
    mem_reservation: 256m

# 3. 清理Docker资源
docker system prune -a --volumes
```

---

### 6. 迁移失败

**问题**: 数据库迁移执行失败

**解决方案**:
```bash
# 1. 检查迁移状态
docker-compose exec backend make migrate-version

# 2. 回滚迁移
docker-compose exec backend make migrate-down

# 3. 强制修复迁移表
docker-compose exec backend make migrate-force 1

# 4. 重新执行迁移
docker-compose exec backend make migrate-up
```

---

## 安全加固

### 1. 防火墙配置

```bash
# 仅允许必要端口
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow 22/tcp   # SSH
sudo ufw allow 80/tcp   # HTTP
sudo ufw allow 443/tcp  # HTTPS
sudo ufw enable
```

### 2. SSH安全

```bash
# 禁用密码登录，仅允许密钥认证
sudo vim /etc/ssh/sshd_config

# 修改以下配置
PasswordAuthentication no
PubkeyAuthentication yes
PermitRootLogin no

# 重启SSH服务
sudo systemctl restart sshd
```

### 3. 定期更新

```bash
# 创建自动更新脚本
sudo vim /etc/cron.weekly/system-update

#!/bin/bash
apt update
apt upgrade -y
apt autoremove -y

# 设置可执行权限
sudo chmod +x /etc/cron.weekly/system-update
```

---

## 扩展阅读

- [Docker最佳实践](https://docs.docker.com/develop/dev-best-practices/)
- [Nginx性能优化](https://www.nginx.com/blog/tuning-nginx/)
- [PostgreSQL备份与恢复](https://www.postgresql.org/docs/current/backup.html)
- [Let's Encrypt证书管理](https://letsencrypt.org/docs/)

---

## 联系支持

如有部署问题，请参考：
- 项目文档: `docs/`
- 问题追踪: GitHub Issues
- 技术支持: 参考CLAUDE.md中的联系方式

---

**最后更新**: 2025-10-13
**文档版本**: v1.0
