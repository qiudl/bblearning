# BBLearning 快速部署指南

## 一键部署

```bash
# 从项目根目录执行
./scripts/deploy-production.sh
```

## 部署信息

| 项目 | 值 |
|------|-----|
| 前端域名 | https://bblearning.joylodging.com |
| API域名 | https://api.bblearning.joylodging.com |
| 服务器 | ubuntu@192.144.174.87 |
| 部署目录 | /opt/bblearning |

## 前置检查

- [ ] SSH密钥已配置（能访问ubuntu@192.144.174.87）
- [ ] DNS已配置（两个域名都指向192.144.174.87）
- [ ] 已生成主加密密钥（运行`cd backend && ./scripts/generate-master-key.sh`）
- [ ] 已将`ENCRYPTION_MASTER_KEY`添加到`backend/.env.production`
- [ ] 准备好DeepSeek API密钥（部署后通过CLI或API添加）
- [ ] 本地已安装Node.js和rsync

## 部署脚本会做什么

1. ✓ 检查SSH连接
2. ✓ 安装Docker、Nginx、Certbot
3. ✓ 创建部署目录
4. ✓ 上传项目文件
5. ✓ 构建前端
6. ✓ 启动Docker服务（PostgreSQL、Redis、MinIO、Backend）
7. ✓ 运行数据库迁移
8. ✓ 配置Nginx（双域名）
9. ✓ 申请SSL证书（Let's Encrypt）
10. ✓ 验证部署

## 部署后验证

```bash
# 1. 检查前端
curl -I https://bblearning.joylodging.com

# 2. 检查API
curl https://api.bblearning.joylodging.com/health

# 3. 查看服务状态
ssh ubuntu@192.144.174.87 'cd /opt/bblearning && docker-compose -f docker-compose.prod.yml ps'

# 4. 添加DeepSeek API密钥
ssh ubuntu@192.144.174.87
cd /opt/bblearning/backend
./bin/apikey -action=add \
  -provider=deepseek \
  -name=default \
  -key="sk-your-deepseek-api-key" \
  -desc="DeepSeek生产环境密钥"

# 5. 验证密钥解密
./bin/apikey -action=test -provider=deepseek -name=default
```

## 常用命令

### 查看日志
```bash
ssh ubuntu@192.144.174.87 'cd /opt/bblearning && docker-compose -f docker-compose.prod.yml logs -f'
```

### 重启服务
```bash
ssh ubuntu@192.144.174.87 'cd /opt/bblearning && docker-compose -f docker-compose.prod.yml restart'
```

### 更新部署
```bash
# 重新运行部署脚本
./scripts/deploy-production.sh
```

## 需要帮助？

查看完整文档：`docs/DEPLOYMENT-GUIDE.md`

## 服务架构

```
Internet
    |
    v
Nginx (443)
    |
    +---> bblearning.joylodging.com     ---> Frontend (静态文件)
    |
    +---> api.bblearning.joylodging.com ---> Backend (8080)
                                                |
                                                +---> PostgreSQL (5432)
                                                +---> Redis (6379)
                                                +---> MinIO (9000)
```

## 重要文件

- `scripts/deploy-production.sh` - 部署脚本
- `backend/.env.production` - 后端生产配置
- `frontend/.env.production` - 前端生产配置
- `docker-compose.prod.yml` - Docker生产配置
- `docs/DEPLOYMENT-GUIDE.md` - 完整部署文档

## 故障排除

### 无法访问网站
```bash
ssh ubuntu@192.144.174.87 'sudo systemctl status nginx'
```

### API 502错误
```bash
ssh ubuntu@192.144.174.87 'cd /opt/bblearning && docker-compose -f docker-compose.prod.yml logs backend'
```

### SSL证书问题
```bash
ssh ubuntu@192.144.174.87 'sudo certbot certificates'
```
