# BBLearning 生产环境部署指南

## 📋 部署概览

本指南介绍如何将BBLearning应用部署到生产服务器。

**目标环境**:
- 服务器: Ubuntu 20.04+ (192.144.174.87)
- 域名: bblearning.joylodging.com
- API域名: api.bblearning.joylodging.com

## 🚀 快速开始

### 一键部署

```bash
# 在本地项目根目录执行
./scripts/deploy-production.sh
```

该脚本将自动完成:
1. SSH连接检查
2. 服务器环境准备 (Docker, Nginx, Certbot)
3. 部署目录创建
4. 项目文件上传
5. 前端构建与上传
6. Docker容器启动
7. 数据库迁移
8. Nginx配置
9. SSL证书申请
10. 部署验证

## 📁 部署文件清单

### 核心部署文件

```
bblearning/
├── scripts/
│   ├── deploy-production.sh              # 一键部署脚本
│   └── setup-production-server.sh        # 服务器初始化脚本
├── docker-compose.prod.yml               # 生产环境Docker配置
├── nginx/
│   └── nginx.conf                        # Nginx配置
├── .env.production.example               # 环境变量模板
└── DEPLOYMENT_GUIDE.md                   # 本文档
```

### 环境配置

复制并编辑环境变量文件:

```bash
cp .env.production.example .env.production
```

必须配置的变量:
- `POSTGRES_PASSWORD`: PostgreSQL密码
- `REDIS_PASSWORD`: Redis密码
- `MINIO_ROOT_PASSWORD`: MinIO密码
- `JWT_SECRET`: JWT密钥 (至少32字符)
- `OPENAI_API_KEY`: OpenAI API密钥

## 🔧 手动部署步骤

如果需要手动部署，请按以下步骤操作:

### 1. 服务器初始化

首次部署需要初始化服务器环境:

```bash
# SSH登录到服务器
ssh ubuntu@192.144.174.87

# 下载并执行初始化脚本
wget https://raw.githubusercontent.com/你的仓库/main/scripts/setup-production-server.sh
chmod +x setup-production-server.sh
sudo ./setup-production-server.sh
```

初始化脚本将安装:
- Docker & Docker Compose
- Nginx
- 基础工具 (curl, git, vim等)
- UFW防火墙配置
- 2GB Swap空间
- Node Exporter (监控)
- 自动备份任务 (每天凌晨2点)

### 2. 创建部署目录

```bash
sudo mkdir -p /opt/bblearning
sudo chown -R ubuntu:ubuntu /opt/bblearning
```

### 3. 上传项目文件

```bash
# 在本地执行
rsync -avz --exclude='node_modules' --exclude='.git' \
    ./ ubuntu@192.144.174.87:/opt/bblearning/
```

### 4. 构建前端

```bash
# 在本地构建
cd frontend
npm run build

# 上传构建结果
rsync -avz build/ ubuntu@192.144.174.87:/opt/bblearning/frontend/build/
```

### 5. 启动Docker容器

```bash
# SSH到服务器
ssh ubuntu@192.144.174.87

# 进入部署目录
cd /opt/bblearning

# 启动所有服务
docker-compose -f docker-compose.prod.yml up -d

# 查看服务状态
docker-compose -f docker-compose.prod.yml ps

# 查看日志
docker-compose -f docker-compose.prod.yml logs -f
```

### 6. 运行数据库迁移

```bash
# 在服务器上执行
cd /opt/bblearning
docker-compose -f docker-compose.prod.yml exec backend make migrate-up
```

### 7. 配置Nginx

创建Nginx配置文件 `/etc/nginx/sites-available/bblearning`:

```nginx
# HTTP - 重定向到HTTPS
server {
    listen 80;
    server_name bblearning.joylodging.com api.bblearning.joylodging.com;

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
    server_name bblearning.joylodging.com;

    ssl_certificate /etc/letsencrypt/live/bblearning.joylodging.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/bblearning.joylodging.com/privkey.pem;

    root /opt/bblearning/frontend/build;
    index index.html;

    location / {
        try_files $uri $uri/ /index.html;
    }
}

# HTTPS - API
server {
    listen 443 ssl http2;
    server_name api.bblearning.joylodging.com;

    ssl_certificate /etc/letsencrypt/live/api.bblearning.joylodging.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/api.bblearning.joylodging.com/privkey.pem;

    location / {
        proxy_pass http://localhost:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

启用配置:

```bash
sudo ln -s /etc/nginx/sites-available/bblearning /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default
sudo nginx -t
sudo systemctl reload nginx
```

### 8. 申请SSL证书

```bash
# 主域名
sudo certbot certonly --nginx \
    -d bblearning.joylodging.com \
    --email admin@joylodging.com \
    --agree-tos

# API域名
sudo certbot certonly --nginx \
    -d api.bblearning.joylodging.com \
    --email admin@joylodging.com \
    --agree-tos

# 重新加载Nginx
sudo systemctl reload nginx
```

## 🏗️ 架构说明

### Docker容器

生产环境包含以下容器:

1. **PostgreSQL** (postgres:15-alpine)
   - 端口: 5432
   - 数据卷: postgres_data
   - 资源限制: 1GB内存

2. **Redis** (redis:7-alpine)
   - 端口: 6379
   - 数据卷: redis_data
   - 持久化: AOF模式

3. **MinIO** (minio/minio:latest)
   - 端口: 9000 (API), 9001 (Console)
   - 数据卷: minio_data

4. **Backend** (自构建)
   - 端口: 8080
   - 依赖: postgres, redis, minio
   - 健康检查: /health端点

5. **Nginx** (nginx:alpine)
   - 端口: 80, 443
   - 作用: 反向代理、静态文件服务

### 网络架构

```
Internet
    ↓
[ Nginx :80/:443 ]
    ↓
    ├─→ Frontend (静态文件)
    └─→ Backend :8080
         ↓
         ├─→ PostgreSQL :5432
         ├─→ Redis :6379
         └─→ MinIO :9000
```

### 数据持久化

所有重要数据存储在Docker卷中:
- `postgres_data`: 数据库数据
- `redis_data`: Redis持久化数据
- `minio_data`: 文件存储
- `nginx_logs`: Nginx日志

## 🔍 监控与维护

### 查看服务状态

```bash
# 查看所有容器状态
docker-compose -f docker-compose.prod.yml ps

# 查看资源使用
docker stats

# 查看容器日志
docker-compose -f docker-compose.prod.yml logs -f [service_name]
```

### 数据库备份

自动备份 (每天凌晨2点):
```bash
# 查看备份任务
crontab -l

# 手动执行备份
/usr/local/bin/bblearning-backup.sh
```

备份文件位置: `/var/www/bblearning/backups/`

手动备份:
```bash
docker exec bblearning-postgres-prod pg_dump -U bblearning bblearning | gzip > backup-$(date +%Y%m%d).sql.gz
```

### 更新应用

```bash
# 拉取最新代码
cd /opt/bblearning
git pull

# 重新构建前端
cd frontend
npm run build

# 重启服务
cd ..
docker-compose -f docker-compose.prod.yml down
docker-compose -f docker-compose.prod.yml build
docker-compose -f docker-compose.prod.yml up -d
```

### 日志管理

Docker日志自动轮转:
- 最大文件大小: 10MB
- 保留文件数: 3个

查看日志:
```bash
# 后端日志
docker-compose -f docker-compose.prod.yml logs -f backend

# Nginx访问日志
docker-compose -f docker-compose.prod.yml exec nginx tail -f /var/log/nginx/access.log

# 数据库日志
docker-compose -f docker-compose.prod.yml logs -f postgres
```

## 🔒 安全配置

### 防火墙规则

UFW已配置允许以下端口:
- 22 (SSH)
- 80 (HTTP)
- 443 (HTTPS)

其他端口默认拒绝外部访问。

### SSL证书自动续期

Certbot已配置自动续期任务:
```bash
# 测试续期
sudo certbot renew --dry-run

# 手动续期
sudo certbot renew
```

### 密码要求

生产环境密码必须满足:
- 至少16个字符
- 包含大小写字母、数字、特殊字符
- 不使用默认密码

## 🐛 故障排查

### 服务无法启动

1. 检查Docker服务
```bash
sudo systemctl status docker
```

2. 查看容器日志
```bash
docker-compose -f docker-compose.prod.yml logs [service_name]
```

3. 检查端口占用
```bash
sudo netstat -tulpn | grep LISTEN
```

### 数据库连接失败

1. 检查PostgreSQL容器状态
```bash
docker-compose -f docker-compose.prod.yml ps postgres
```

2. 测试数据库连接
```bash
docker-compose -f docker-compose.prod.yml exec postgres \
    psql -U bblearning -d bblearning -c "SELECT version();"
```

### 前端无法访问

1. 检查Nginx配置
```bash
sudo nginx -t
```

2. 检查静态文件
```bash
ls -lh /opt/bblearning/frontend/build/
```

3. 查看Nginx错误日志
```bash
sudo tail -f /var/log/nginx/error.log
```

### SSL证书问题

1. 检查证书有效期
```bash
sudo certbot certificates
```

2. 手动续期
```bash
sudo certbot renew
sudo systemctl reload nginx
```

## 📞 运维联系

- 服务器IP: 192.144.174.87
- 前端URL: https://bblearning.joylodging.com
- API URL: https://api.bblearning.joylodging.com
- 部署目录: /opt/bblearning
- 备份目录: /var/www/bblearning/backups

## 📚 相关文档

- [技术架构文档](docs/architecture/tech-architecture.md)
- [API接口文档](docs/architecture/api-specification.md)
- [开发指南](CLAUDE.md)
- [环境配置示例](.env.production.example)

## ✅ 部署检查清单

部署前检查:
- [ ] 配置 `.env.production` 文件
- [ ] 确认服务器SSH连接正常
- [ ] 确认域名DNS已解析到服务器IP
- [ ] 准备好OpenAI API密钥
- [ ] 检查本地Docker和Docker Compose版本

部署后验证:
- [ ] 前端页面可正常访问
- [ ] API健康检查端点返回正常
- [ ] 用户注册登录功能正常
- [ ] 数据库连接正常
- [ ] Redis缓存正常
- [ ] MinIO文件上传正常
- [ ] SSL证书正常 (无浏览器警告)
- [ ] 自动备份任务已配置

---

**最后更新**: 2025-10-15
**维护者**: BBLearning Team
