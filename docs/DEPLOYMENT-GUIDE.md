# BBLearning 生产环境部署指南

## 部署信息

- **域名**: bblearning.joylodging.com
- **API域名**: api.bblearning.joylodging.com
- **服务器**: ubuntu@192.144.174.87
- **部署目录**: /opt/bblearning

## 前置要求

### 本地环境
- [x] Git 仓库包含所有最新代码
- [x] 已配置SSH密钥访问服务器
- [x] 已安装rsync用于文件同步
- [x] 已安装Node.js用于前端构建

### 服务器环境
部署脚本会自动安装以下组件（如未安装）：
- Docker Engine
- Docker Compose
- Nginx
- Certbot (Let's Encrypt SSL)

### DNS配置
确保以下DNS记录已正确配置：
```
bblearning.joylodging.com     A    192.144.174.87
api.bblearning.joylodging.com A    192.144.174.87
```

## 部署步骤

### 1. 验证配置文件

确认以下配置文件已正确配置：

#### backend/.env.production
```env
# 应用配置
APP_ENV=production
APP_DEBUG=false
SERVER_PORT=8080
SERVER_HOST=0.0.0.0

# 数据库配置
DB_HOST=postgres
DB_PORT=5432
DB_USER=bblearning_prod
DB_PASSWORD=BBLearning2025Prod!SecureDB#
DB_NAME=bblearning_production
DB_SSLMODE=disable

# Redis配置
REDIS_HOST=redis
REDIS_PORT=6379
REDIS_PASSWORD=BBLearning2025Redis!Secure#
REDIS_DB=0

# JWT配置
JWT_SECRET=7f8a9b2c4d6e1f3a5b7c9d2e4f6a8b1c3d5e7f9a2b4c6d8e1f3a5b7c9d2e4f6a8b
JWT_ACCESS_EXPIRE=3600
JWT_REFRESH_EXPIRE=604800

# AI服务配置（DeepSeek）
DEEPSEEK_API_KEY=sk-your-deepseek-api-key-here
DEEPSEEK_BASE_URL=https://api.deepseek.com/v1
DEEPSEEK_MODEL=deepseek-chat

# MinIO配置
MINIO_ENDPOINT=minio:9000
MINIO_ACCESS_KEY=bblearning_minio_admin
MINIO_SECRET_KEY=BBLearning2025MinIO!SecureKey#

# CORS配置
CORS_ALLOWED_ORIGINS=https://bblearning.joylodging.com,https://api.bblearning.joylodging.com
```

**注意**: 在实际部署前，请确保更新以下敏感信息：
- `DEEPSEEK_API_KEY`: 替换为真实的DeepSeek API密钥
- `JWT_SECRET`: 可以保持当前值或生成新的64字符随机字符串
- 所有密码可根据需要修改（确保足够复杂）

#### frontend/.env.production
```env
REACT_APP_API_URL=https://api.bblearning.joylodging.com/api/v1
```

### 2. 执行部署脚本

从项目根目录运行部署脚本：

```bash
cd /Users/johnqiu/coding/www/projects/bblearning
./scripts/deploy-production.sh
```

脚本会自动执行以下步骤：

#### [1/10] 检查SSH连接
- 验证与服务器的连接
- 超时时间：5秒

#### [2/10] 准备服务器环境
- 更新系统包
- 安装Docker（如未安装）
- 安装Docker Compose（如未安装）
- 安装Nginx（如未安装）
- 安装Certbot（如未安装）

#### [3/10] 创建部署目录
- 创建 `/opt/bblearning` 目录
- 设置正确的所有权（ubuntu用户）

#### [4/10] 上传项目文件
- 使用rsync同步项目文件
- 排除：node_modules, .git, build, bin

#### [5/10] 构建前端
- 执行 `npm run build`
- 上传构建产物到服务器

#### [6/10] 启动Docker容器
- 停止现有容器（如有）
- 构建新镜像
- 启动所有服务：
  - PostgreSQL (端口5432)
  - Redis (端口6379)
  - MinIO (端口9000/9001)
  - Backend (端口8080)

#### [7/10] 运行数据库迁移
- 自动执行数据库迁移脚本
- 创建所有必要的表结构

#### [8/10] 配置Nginx
- 创建Nginx配置文件
- 配置双域名：
  - bblearning.joylodging.com → 前端静态文件
  - api.bblearning.joylodging.com → 后端API反向代理
- 启用HTTP到HTTPS重定向
- 配置Gzip压缩和缓存策略

#### [9/10] 申请SSL证书
- 使用Let's Encrypt申请免费SSL证书
- 为两个域名分别申请证书
- 自动配置Nginx使用证书
- 证书自动续期（90天有效期）

#### [10/10] 验证部署
- 检查后端健康端点：https://api.bblearning.joylodging.com/health
- 检查前端页面：https://bblearning.joylodging.com

### 3. 部署后验证

部署完成后，执行以下验证步骤：

#### 3.1 访问前端页面
```bash
curl -I https://bblearning.joylodging.com
```
预期：返回200状态码

#### 3.2 检查API健康状态
```bash
curl https://api.bblearning.joylodging.com/health
```
预期：返回JSON健康状态响应

#### 3.3 测试用户注册
通过浏览器访问 https://bblearning.joylodging.com 并尝试注册新用户

#### 3.4 检查Docker服务状态
```bash
ssh ubuntu@192.144.174.87 'cd /opt/bblearning && docker-compose -f docker-compose.prod.yml ps'
```
预期：所有服务状态为 "Up" 或 "Up (healthy)"

#### 3.5 查看日志
```bash
ssh ubuntu@192.144.174.87 'cd /opt/bblearning && docker-compose -f docker-compose.prod.yml logs -f backend'
```

## 生产环境架构

### 网络拓扑
```
Internet
    |
    v
[bblearning.joylodging.com] ---> Nginx (443) ---> Frontend Static Files
[api.bblearning.joylodging.com] ---> Nginx (443) ---> Backend (8080)
                                                         |
                                                         +---> PostgreSQL (5432)
                                                         +---> Redis (6379)
                                                         +---> MinIO (9000)
```

### Docker容器
```
bblearning-postgres-prod   - PostgreSQL 15
bblearning-redis-prod      - Redis 7
bblearning-minio-prod      - MinIO (对象存储)
bblearning-backend-prod    - Go Backend
```

### 资源限制
- **PostgreSQL**: CPU 1.0核, 内存 1GB
- **Redis**: CPU 0.5核, 内存 512MB
- **MinIO**: CPU 0.5核, 内存 512MB
- **Backend**: CPU 2.0核, 内存 2GB

## 常见运维操作

### 查看服务状态
```bash
ssh ubuntu@192.144.174.87 'cd /opt/bblearning && docker-compose -f docker-compose.prod.yml ps'
```

### 查看实时日志
```bash
# 所有服务
ssh ubuntu@192.144.174.87 'cd /opt/bblearning && docker-compose -f docker-compose.prod.yml logs -f'

# 仅后端
ssh ubuntu@192.144.174.87 'cd /opt/bblearning && docker-compose -f docker-compose.prod.yml logs -f backend'

# 仅数据库
ssh ubuntu@192.144.174.87 'cd /opt/bblearning && docker-compose -f docker-compose.prod.yml logs -f postgres'
```

### 重启服务
```bash
# 重启所有服务
ssh ubuntu@192.144.174.87 'cd /opt/bblearning && docker-compose -f docker-compose.prod.yml restart'

# 仅重启后端
ssh ubuntu@192.144.174.87 'cd /opt/bblearning && docker-compose -f docker-compose.prod.yml restart backend'
```

### 停止服务
```bash
ssh ubuntu@192.144.174.87 'cd /opt/bblearning && docker-compose -f docker-compose.prod.yml down'
```

### 启动服务
```bash
ssh ubuntu@192.144.174.87 'cd /opt/bblearning && docker-compose -f docker-compose.prod.yml up -d'
```

### 更新代码并重新部署
```bash
# 方法1: 重新运行完整部署脚本
./scripts/deploy-production.sh

# 方法2: 仅更新后端代码
rsync -avz ./backend/ ubuntu@192.144.174.87:/opt/bblearning/backend/
ssh ubuntu@192.144.174.87 'cd /opt/bblearning && docker-compose -f docker-compose.prod.yml build backend && docker-compose -f docker-compose.prod.yml up -d backend'

# 方法3: 仅更新前端代码
cd frontend && npm run build
rsync -avz build/ ubuntu@192.144.174.87:/opt/bblearning/frontend/build/
```

### 数据库备份
```bash
# 创建备份
ssh ubuntu@192.144.174.87 'docker exec bblearning-postgres-prod pg_dump -U bblearning_prod bblearning_production > /backup/bblearning_$(date +%Y%m%d_%H%M%S).sql'

# 下载备份到本地
scp ubuntu@192.144.174.87:/backup/bblearning_*.sql ./backups/
```

### 数据库恢复
```bash
# 上传备份文件
scp ./backups/bblearning_20250113.sql ubuntu@192.144.174.87:/opt/bblearning/backup/

# 恢复数据库
ssh ubuntu@192.144.174.87 'docker exec -i bblearning-postgres-prod psql -U bblearning_prod bblearning_production < /backup/bblearning_20250113.sql'
```

### SSL证书续期
```bash
# Let's Encrypt证书会自动续期，也可以手动触发
ssh ubuntu@192.144.174.87 'sudo certbot renew'
ssh ubuntu@192.144.174.87 'sudo systemctl reload nginx'
```

### Nginx配置测试
```bash
ssh ubuntu@192.144.174.87 'sudo nginx -t'
```

### Nginx重新加载配置
```bash
ssh ubuntu@192.144.174.87 'sudo systemctl reload nginx'
```

## 监控和告警

### 健康检查端点
- **后端健康**: https://api.bblearning.joylodging.com/health
- **数据库健康**: 通过Docker健康检查
- **Redis健康**: 通过Docker健康检查

### 日志位置
- **后端日志**: Docker容器日志 + /var/log/bblearning/
- **Nginx日志**: /var/log/nginx/access.log 和 /var/log/nginx/error.log
- **PostgreSQL日志**: Docker容器日志

### 性能监控
建议配置以下监控工具：
- **Prometheus**: 收集应用指标
- **Grafana**: 可视化监控面板
- **Alertmanager**: 告警通知

## 安全配置

### 防火墙规则
确保服务器防火墙允许以下端口：
- 22 (SSH)
- 80 (HTTP - 重定向到HTTPS)
- 443 (HTTPS)

### SSL/TLS配置
- 使用TLSv1.2和TLSv1.3协议
- 强加密套件
- HSTS启用（可选）

### 数据库安全
- 数据库仅监听内部网络（Docker网络）
- 使用强密码
- 定期备份

### API安全
- CORS配置仅允许指定域名
- JWT令牌过期时间：1小时
- 刷新令牌过期时间：7天
- 限流保护（100请求/分钟）

## 故障排除

### 问题1: 无法访问网站
```bash
# 检查Nginx状态
ssh ubuntu@192.144.174.87 'sudo systemctl status nginx'

# 检查DNS解析
nslookup bblearning.joylodging.com

# 检查SSL证书
curl -vI https://bblearning.joylodging.com
```

### 问题2: API返回502错误
```bash
# 检查后端服务状态
ssh ubuntu@192.144.174.87 'cd /opt/bblearning && docker-compose -f docker-compose.prod.yml ps backend'

# 查看后端日志
ssh ubuntu@192.144.174.87 'cd /opt/bblearning && docker-compose -f docker-compose.prod.yml logs backend'

# 检查端口监听
ssh ubuntu@192.144.174.87 'netstat -tlnp | grep 8080'
```

### 问题3: 数据库连接失败
```bash
# 检查PostgreSQL状态
ssh ubuntu@192.144.174.87 'cd /opt/bblearning && docker-compose -f docker-compose.prod.yml ps postgres'

# 测试数据库连接
ssh ubuntu@192.144.174.87 'docker exec bblearning-postgres-prod psql -U bblearning_prod -d bblearning_production -c "SELECT 1;"'
```

### 问题4: SSL证书问题
```bash
# 检查证书有效期
ssh ubuntu@192.144.174.87 'sudo certbot certificates'

# 手动续期
ssh ubuntu@192.144.174.87 'sudo certbot renew --force-renewal'
```

## 回滚策略

### 快速回滚
如果部署后发现问题，可以快速回滚到之前的版本：

```bash
# 1. SSH到服务器
ssh ubuntu@192.144.174.87

# 2. 切换到部署目录
cd /opt/bblearning

# 3. 使用Git回滚代码
git log --oneline -5  # 查看最近的提交
git checkout <previous-commit-hash>

# 4. 重新构建和启动服务
docker-compose -f docker-compose.prod.yml down
docker-compose -f docker-compose.prod.yml build
docker-compose -f docker-compose.prod.yml up -d
```

## 性能优化建议

### 数据库优化
- 启用PostgreSQL连接池
- 配置适当的shared_buffers和effective_cache_size
- 定期执行VACUUM和ANALYZE

### 缓存策略
- 使用Redis缓存频繁查询的数据
- 设置合理的TTL
- 实现缓存预热

### CDN集成
- 将静态资源托管到CDN
- 配置适当的缓存头

### 负载均衡
- 当流量增长时，考虑配置多个后端实例
- 使用Nginx作为负载均衡器

## 扩展性考虑

### 水平扩展
- 后端服务无状态设计，易于水平扩展
- 可以增加多个后端实例
- 使用共享的PostgreSQL和Redis

### 垂直扩展
- 根据负载增加服务器资源
- 调整Docker容器资源限制

### 数据库扩展
- 考虑读写分离
- 实施数据库分片（如需要）

## 联系和支持

- **项目仓库**: [项目Git仓库地址]
- **问题反馈**: [GitHub Issues]
- **紧急联系**: [管理员联系方式]

## 附录

### 附录A: 环境变量完整列表

见 `backend/.env.production` 文件

### 附录B: Docker Compose配置

见 `docker-compose.prod.yml` 文件

### 附录C: Nginx配置

见部署脚本中的Nginx配置部分

### 附录D: 数据库表结构

见 `backend/migrations/` 目录中的迁移文件
