# BBLearning 生产环境部署准备指南

**状态**: 🟡 等待配置环境变量
**预计时间**: 15分钟配置 + 10分钟部署

---

## ✅ 已完成的准备工作

- ✅ 部署脚本已创建 (`scripts/deploy-production.sh`)
- ✅ Docker配置已创建 (`docker-compose.prod.yml`)
- ✅ Nginx配置已创建 (`nginx/nginx.conf`)
- ✅ 环境变量模板已创建 (`.env.production.example`)
- ✅ 前端代码已构建 (`frontend/build/`)
- ✅ 后端代码已就绪 (`backend/`)
- ✅ 完整文档已创建

---

## 🔧 需要立即执行的操作

### 步骤1: 创建生产环境配置文件

```bash
# 复制环境变量模板
cp .env.production.example .env.production

# 编辑配置文件
vim .env.production  # 或使用其他编辑器
```

### 步骤2: 填写必需的配置项

打开 `.env.production` 文件，填入以下真实值：

#### 🔐 数据库配置
```bash
POSTGRES_PASSWORD=你的强密码          # 至少16字符
```
**建议密码**: 包含大小写字母、数字、特殊字符
**示例生成**: `openssl rand -base64 24`

#### 🔐 Redis配置
```bash
REDIS_PASSWORD=你的Redis强密码        # 至少16字符
```

#### 🔐 MinIO配置
```bash
MINIO_ROOT_PASSWORD=你的MinIO强密码   # 至少16字符
```

#### 🔐 JWT密钥
```bash
JWT_SECRET=你的32字符以上随机字符串
```
**生成方法**: `openssl rand -hex 32`

#### 🔐 OpenAI API密钥
```bash
OPENAI_API_KEY=sk-your-real-api-key-here
```
从 https://platform.openai.com/api-keys 获取

#### 🌐 域名配置（已预配置）
```bash
REACT_APP_API_URL=https://api.bblearning.joylodging.com
REACT_APP_WS_URL=wss://api.bblearning.joylodging.com/ws
```

---

## 🔍 部署前检查清单

### 服务器准备
- [ ] 服务器可通过SSH访问 (`ssh ubuntu@192.144.174.87`)
- [ ] DNS已正确解析:
  - [ ] `bblearning.joylodging.com` → `192.144.174.87`
  - [ ] `api.bblearning.joylodging.com` → `192.144.174.87`

### 本地准备
- [ ] `.env.production` 文件已创建并填写完整
- [ ] 所有密码至少16字符
- [ ] JWT_SECRET至少32字符
- [ ] OpenAI API密钥有效且有余额

### 网络准备
- [ ] 本地可访问服务器22端口（SSH）
- [ ] 服务器可访问Docker Hub（下载镜像）
- [ ] 服务器可访问Let's Encrypt（申请SSL证书）

---

## 🚀 开始部署

一旦完成上述配置，执行以下命令开始部署：

```bash
# 方式1: 一键部署（推荐）
./scripts/deploy-production.sh

# 方式2: 查看部署日志详情
./scripts/deploy-production.sh 2>&1 | tee deployment.log
```

部署过程大约需要10-15分钟，脚本会自动完成以下步骤：
1. ✅ SSH连接检查
2. ✅ 服务器环境准备（Docker, Nginx, Certbot）
3. ✅ 部署目录创建
4. ✅ 项目文件上传
5. ✅ 前端构建与上传
6. ✅ Docker容器启动
7. ✅ 数据库迁移
8. ✅ Nginx配置
9. ✅ SSL证书申请
10. ✅ 健康检查验证

---

## 📋 部署后验证清单

部署完成后，验证以下项目：

### 基础访问
- [ ] 前端可访问: https://bblearning.joylodging.com
- [ ] API健康检查: https://api.bblearning.joylodging.com/health
- [ ] SSL证书有效（浏览器无警告）

### 功能验证
- [ ] 用户注册功能正常
- [ ] 用户登录功能正常
- [ ] 数据持久化正常（刷新页面数据不丢失）

### 服务状态
```bash
# SSH到服务器
ssh ubuntu@192.144.174.87

# 查看所有服务状态
cd /opt/bblearning
docker-compose -f docker-compose.prod.yml ps

# 预期所有服务状态为 Up
```

### 日志检查
```bash
# 查看后端日志
docker-compose -f docker-compose.prod.yml logs -f backend

# 查看Nginx日志
docker-compose -f docker-compose.prod.yml logs -f nginx

# 确认没有ERROR级别的日志
```

---

## 🛠️ 密码生成参考

### 快速生成强密码

```bash
# PostgreSQL密码（24字符）
openssl rand -base64 24

# Redis密码（24字符）
openssl rand -base64 24

# MinIO密码（24字符）
openssl rand -base64 24

# JWT Secret（64字符十六进制）
openssl rand -hex 32
```

### 示例 `.env.production` 配置

```bash
# ========== 部署配置 ==========
DEPLOY_USER=ubuntu
DEPLOY_HOST=192.144.174.87
DEPLOY_PORT=22
REMOTE_APP_DIR=/var/www/bblearning

# ========== 数据库配置 ==========
POSTGRES_DB=bblearning
POSTGRES_USER=bblearning
POSTGRES_PASSWORD=Ab12Cd34Ef56Gh78!@#$%^&*()

# ========== Redis配置 ==========
REDIS_PASSWORD=Xy98Zw76Vu54Ts32!@#$%^&*()

# ========== MinIO配置 ==========
MINIO_ROOT_USER=minioadmin
MINIO_ROOT_PASSWORD=Mn87Op65Qr43St21!@#$%^&*()

# ========== 后端配置 ==========
BACKEND_PORT=8080
JWT_SECRET=a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6q7r8s9t0u1v2w3x4y5z6

# ========== OpenAI配置 ==========
OPENAI_API_KEY=sk-proj-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

# ========== 前端配置 ==========
REACT_APP_API_URL=https://api.bblearning.joylodging.com
REACT_APP_WS_URL=wss://api.bblearning.joylodging.com/ws
```

⚠️ **注意**: 上述密码仅为示例，请生成真实的随机密码！

---

## 🆘 遇到问题？

### 常见问题

**Q: SSH连接失败？**
A: 检查服务器IP、SSH密钥配置、防火墙规则

**Q: DNS解析失败？**
A: 使用 `nslookup bblearning.joylodging.com` 检查DNS记录

**Q: Docker镜像下载慢？**
A: 可能需要配置Docker镜像加速器

**Q: SSL证书申请失败？**
A: 确认域名DNS已正确解析，80端口可访问

详细故障排查请参考: `DEPLOYMENT_GUIDE.md`

---

## 📞 下一步

1. ✅ 完成 `.env.production` 配置
2. ✅ 执行部署脚本
3. ✅ 验证部署结果
4. ✅ 开始使用系统！

---

**创建时间**: 2025-10-15
**准备时间**: 约15分钟
**部署时间**: 约10-15分钟
**总耗时**: 约25-30分钟
