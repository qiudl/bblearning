# BBLearning 部署常用命令速查

## 🚀 部署命令

### 一键部署
```bash
./scripts/deploy-production.sh
```

### 回滚到上一版本
```bash
./scripts/deploy-production.sh rollback
```

### 查看部署日志
```bash
./scripts/deploy-production.sh logs
```

## 🔍 服务管理

### 启动所有服务
```bash
docker-compose -f docker-compose.prod.yml up -d
```

### 停止所有服务
```bash
docker-compose -f docker-compose.prod.yml down
```

### 重启特定服务
```bash
docker-compose -f docker-compose.prod.yml restart backend
docker-compose -f docker-compose.prod.yml restart postgres
docker-compose -f docker-compose.prod.yml restart redis
```

### 查看服务状态
```bash
docker-compose -f docker-compose.prod.yml ps
```

### 查看资源使用
```bash
docker stats
```

## 📋 日志查看

### 查看所有日志
```bash
docker-compose -f docker-compose.prod.yml logs -f
```

### 查看特定服务日志
```bash
# 后端日志
docker-compose -f docker-compose.prod.yml logs -f backend

# 数据库日志
docker-compose -f docker-compose.prod.yml logs -f postgres

# Redis日志
docker-compose -f docker-compose.prod.yml logs -f redis

# Nginx日志
docker-compose -f docker-compose.prod.yml logs -f nginx
```

### 查看最近100行日志
```bash
docker-compose -f docker-compose.prod.yml logs --tail=100 backend
```

## 🗄️ 数据库操作

### 连接数据库
```bash
docker-compose -f docker-compose.prod.yml exec postgres \
    psql -U bblearning -d bblearning
```

### 执行SQL查询
```bash
docker-compose -f docker-compose.prod.yml exec postgres \
    psql -U bblearning -d bblearning -c "SELECT COUNT(*) FROM users;"
```

### 数据库迁移
```bash
# 升级到最新版本
docker-compose -f docker-compose.prod.yml exec backend make migrate-up

# 回滚一个版本
docker-compose -f docker-compose.prod.yml exec backend make migrate-down

# 查看迁移状态
docker-compose -f docker-compose.prod.yml exec backend make migrate-status
```

### 数据库备份
```bash
# 手动备份
docker exec bblearning-postgres-prod \
    pg_dump -U bblearning bblearning | gzip > backup-$(date +%Y%m%d-%H%M%S).sql.gz

# 恢复备份
gunzip -c backup-20251015-120000.sql.gz | \
    docker exec -i bblearning-postgres-prod \
    psql -U bblearning -d bblearning
```

## 📦 Redis操作

### 连接Redis
```bash
docker-compose -f docker-compose.prod.yml exec redis redis-cli -a ${REDIS_PASSWORD}
```

### 清空缓存
```bash
docker-compose -f docker-compose.prod.yml exec redis redis-cli -a ${REDIS_PASSWORD} FLUSHALL
```

### 查看Redis信息
```bash
docker-compose -f docker-compose.prod.yml exec redis redis-cli -a ${REDIS_PASSWORD} INFO
```

## 🌐 Nginx操作

### 重新加载配置
```bash
sudo nginx -t && sudo systemctl reload nginx
```

### 查看访问日志
```bash
sudo tail -f /var/log/nginx/access.log
```

### 查看错误日志
```bash
sudo tail -f /var/log/nginx/error.log
```

## 🔒 SSL证书管理

### 查看证书状态
```bash
sudo certbot certificates
```

### 续期证书
```bash
# 测试续期（不实际续期）
sudo certbot renew --dry-run

# 实际续期
sudo certbot renew

# 续期后重新加载Nginx
sudo systemctl reload nginx
```

### 手动申请证书
```bash
sudo certbot certonly --nginx -d bblearning.joylodging.com
```

## 🔄 应用更新

### 完整更新流程
```bash
# 1. 拉取最新代码
cd /opt/bblearning
git pull

# 2. 构建前端
cd frontend
npm install
npm run build
cd ..

# 3. 重启服务
docker-compose -f docker-compose.prod.yml down
docker-compose -f docker-compose.prod.yml build
docker-compose -f docker-compose.prod.yml up -d

# 4. 运行数据库迁移
docker-compose -f docker-compose.prod.yml exec backend make migrate-up

# 5. 验证部署
curl -f https://api.bblearning.joylodging.com/health
```

### 仅更新后端
```bash
docker-compose -f docker-compose.prod.yml build backend
docker-compose -f docker-compose.prod.yml up -d backend
```

### 仅更新前端
```bash
cd /opt/bblearning/frontend
npm run build
sudo systemctl reload nginx
```

## 🐛 故障排查

### 检查容器健康状态
```bash
docker inspect bblearning-backend-prod | grep -A 10 "Health"
docker inspect bblearning-postgres-prod | grep -A 10 "Health"
```

### 查看容器详细信息
```bash
docker inspect bblearning-backend-prod
```

### 进入容器内部
```bash
# 进入后端容器
docker exec -it bblearning-backend-prod /bin/sh

# 进入数据库容器
docker exec -it bblearning-postgres-prod /bin/bash
```

### 检查端口占用
```bash
sudo netstat -tulpn | grep LISTEN
# 或
sudo ss -tulpn | grep LISTEN
```

### 检查磁盘空间
```bash
df -h
```

### 清理Docker资源
```bash
# 清理未使用的容器
docker container prune -f

# 清理未使用的镜像
docker image prune -a -f

# 清理未使用的卷
docker volume prune -f

# 一次性清理所有未使用资源
docker system prune -a -f --volumes
```

## 📊 监控命令

### 查看系统资源
```bash
# CPU和内存使用
htop

# 磁盘IO
iostat -x 1

# 网络流量
iftop
```

### 查看应用指标
```bash
# 后端健康检查
curl https://api.bblearning.joylodging.com/health

# 数据库连接数
docker-compose -f docker-compose.prod.yml exec postgres \
    psql -U bblearning -d bblearning -c "SELECT count(*) FROM pg_stat_activity;"

# Redis内存使用
docker-compose -f docker-compose.prod.yml exec redis \
    redis-cli -a ${REDIS_PASSWORD} INFO memory
```

## 🔐 安全操作

### 修改数据库密码
```bash
# 1. 进入数据库
docker-compose -f docker-compose.prod.yml exec postgres psql -U postgres

# 2. 修改密码
ALTER USER bblearning WITH PASSWORD '新密码';

# 3. 更新环境变量并重启
vim .env.production
docker-compose -f docker-compose.prod.yml restart backend
```

### 修改Redis密码
```bash
# 1. 更新环境变量
vim .env.production

# 2. 重启Redis
docker-compose -f docker-compose.prod.yml restart redis

# 3. 重启后端
docker-compose -f docker-compose.prod.yml restart backend
```

### 查看防火墙规则
```bash
sudo ufw status verbose
```

## 📈 性能优化

### 查看慢查询
```bash
docker-compose -f docker-compose.prod.yml exec postgres \
    psql -U bblearning -d bblearning -c "SELECT * FROM pg_stat_statements ORDER BY total_time DESC LIMIT 10;"
```

### 分析表大小
```bash
docker-compose -f docker-compose.prod.yml exec postgres \
    psql -U bblearning -d bblearning -c "
    SELECT
        schemaname,
        tablename,
        pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS size
    FROM pg_tables
    WHERE schemaname = 'public'
    ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;
    "
```

### 重建索引
```bash
docker-compose -f docker-compose.prod.yml exec postgres \
    psql -U bblearning -d bblearning -c "REINDEX DATABASE bblearning;"
```

## 🔄 定时任务

### 查看cron任务
```bash
crontab -l
```

### 编辑cron任务
```bash
crontab -e
```

### 查看备份日志
```bash
tail -f /var/log/bblearning-backup.log
```

## 🆘 紧急操作

### 紧急停止所有服务
```bash
docker-compose -f docker-compose.prod.yml down
```

### 快速回滚
```bash
# 1. 停止当前服务
docker-compose -f docker-compose.prod.yml down

# 2. 恢复备份
cd /var/www/bblearning/backups
ls -lt | head -5  # 查看最近的备份

# 3. 恢复数据库
gunzip -c db-20251015-020000.sql.gz | \
    docker exec -i bblearning-postgres-prod \
    psql -U bblearning -d bblearning

# 4. 重启服务
docker-compose -f docker-compose.prod.yml up -d
```

### 查看实时错误
```bash
# 后端错误
docker-compose -f docker-compose.prod.yml logs -f backend | grep ERROR

# Nginx错误
sudo tail -f /var/log/nginx/error.log

# 系统错误
sudo journalctl -f -u docker
```

## 📝 常用变量

```bash
# 服务器信息
SERVER_IP=192.144.174.87
DOMAIN=bblearning.joylodging.com
API_DOMAIN=api.bblearning.joylodging.com
DEPLOY_DIR=/opt/bblearning

# 容器名称
POSTGRES_CONTAINER=bblearning-postgres-prod
REDIS_CONTAINER=bblearning-redis-prod
BACKEND_CONTAINER=bblearning-backend-prod
NGINX_CONTAINER=bblearning-nginx-prod
MINIO_CONTAINER=bblearning-minio-prod

# 快捷访问
alias bb-logs='docker-compose -f docker-compose.prod.yml logs -f'
alias bb-ps='docker-compose -f docker-compose.prod.yml ps'
alias bb-restart='docker-compose -f docker-compose.prod.yml restart'
alias bb-exec='docker-compose -f docker-compose.prod.yml exec'
```

---

**提示**: 建议将这些命令添加到服务器的 `~/.bashrc` 或 `~/.zshrc` 中作为别名，方便日常使用。

**最后更新**: 2025-10-15
