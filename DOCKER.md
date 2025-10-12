# Docker 开发环境指南

本文档介绍如何使用 Docker 快速搭建 BBLearning 的开发环境。

## 前置条件

- Docker 20.10+
- Docker Compose 2.0+
- 至少 4GB 可用内存
- 至少 10GB 可用磁盘空间

## 快速开始

### 1. 一键启动所有服务

```bash
./scripts/dev-setup.sh
```

这个脚本会自动完成以下操作:
- 检查 Docker 环境
- 创建 .env 配置文件(如果不存在)
- 构建所有服务镜像
- 启动所有容器
- 验证服务状态

### 2. 手动启动

如果你更喜欢手动控制,可以使用以下命令:

```bash
# 1. 创建环境变量文件
cp backend/.env.example backend/.env

# 2. 启动所有服务
docker-compose up -d

# 3. 查看服务状态
docker-compose ps

# 4. 查看日志
docker-compose logs -f
```

## 服务访问

启动成功后,可以通过以下地址访问各个服务:

| 服务 | 地址 | 说明 |
|-----|------|-----|
| 前端应用 | http://localhost:3000 | React Web 应用 |
| 后端 API | http://localhost:8080 | RESTful API 服务 |
| 健康检查 | http://localhost:8080/health | API 健康状态 |
| MinIO 控制台 | http://localhost:9001 | 对象存储管理界面 |
| PostgreSQL | localhost:5432 | 数据库服务 |
| Redis | localhost:6379 | 缓存服务 |

### 默认凭证

**PostgreSQL:**
- 用户名: `bblearning`
- 密码: `bblearning_dev_password`
- 数据库: `bblearning_dev`

**MinIO:**
- 用户名: `minioadmin`
- 密码: `minioadmin123`

**Redis:**
- 无需密码(开发环境)

## 常用命令

### 查看服务状态

```bash
docker-compose ps
```

### 查看服务日志

```bash
# 查看所有服务日志
docker-compose logs -f

# 查看特定服务日志
docker-compose logs -f backend
docker-compose logs -f frontend
docker-compose logs -f postgres
```

### 重启服务

```bash
# 重启所有服务
docker-compose restart

# 重启特定服务
docker-compose restart backend
```

### 停止服务

```bash
# 停止所有服务(保留数据)
docker-compose stop

# 停止并删除所有容器(保留数据卷)
docker-compose down

# 停止并删除所有容器和数据卷
docker-compose down -v
```

### 重新构建镜像

```bash
# 重新构建所有镜像
docker-compose build --no-cache

# 重新构建特定服务
docker-compose build --no-cache backend
```

### 进入容器

```bash
# 进入后端容器
docker-compose exec backend sh

# 进入数据库容器
docker-compose exec postgres psql -U bblearning -d bblearning_dev

# 进入 Redis 容器
docker-compose exec redis redis-cli
```

## 数据库管理

### 访问数据库

```bash
# 使用 docker-compose
docker-compose exec postgres psql -U bblearning -d bblearning_dev

# 使用本地 psql
psql -h localhost -p 5432 -U bblearning -d bblearning_dev
```

### 数据库迁移

数据库表结构会在后端服务启动时自动创建(使用 GORM AutoMigrate)。

如果需要手动运行迁移:

```bash
# 进入后端容器
docker-compose exec backend sh

# 运行迁移(未来实现)
# make migrate-up
```

### 插入种子数据

```bash
# 进入后端容器
docker-compose exec backend sh

# 运行种子脚本(未来实现)
# make seed
```

### 备份和恢复

```bash
# 备份数据库
docker-compose exec -T postgres pg_dump -U bblearning bblearning_dev > backup.sql

# 恢复数据库
docker-compose exec -T postgres psql -U bblearning bblearning_dev < backup.sql
```

## 故障排除

### 端口冲突

如果遇到端口占用问题,检查并停止占用端口的进程:

```bash
# 检查端口占用
lsof -i :3000  # 前端
lsof -i :8080  # 后端
lsof -i :5432  # PostgreSQL
lsof -i :6379  # Redis
lsof -i :9000  # MinIO API
lsof -i :9001  # MinIO Console
```

或者修改 `docker-compose.yml` 中的端口映射。

### 服务无法启动

1. 检查 Docker 是否运行:
```bash
docker info
```

2. 查看服务日志:
```bash
docker-compose logs [service-name]
```

3. 检查磁盘空间:
```bash
docker system df
```

4. 清理 Docker 资源:
```bash
docker system prune -a --volumes
```

### 数据库连接失败

1. 确保 PostgreSQL 容器健康:
```bash
docker-compose ps postgres
```

2. 检查数据库日志:
```bash
docker-compose logs postgres
```

3. 测试数据库连接:
```bash
docker-compose exec postgres pg_isready -U bblearning
```

### 前端无法访问后端 API

1. 检查后端服务状态:
```bash
curl http://localhost:8080/health
```

2. 检查网络连接:
```bash
docker-compose exec frontend ping backend
```

3. 确认环境变量配置正确(frontend/.env)

## 开发工作流

### 代码热重载

- **前端**: Vite 开发服务器支持热重载,保存文件后自动刷新
- **后端**: 使用 Air 工具实现热重载(需要安装):

```bash
# 在后端目录安装 Air
cd backend
go install github.com/cosmtrek/air@latest

# 使用 Air 运行
make dev
```

### 数据库重置

如果需要重置数据库到初始状态:

```bash
# 停止服务并删除数据卷
docker-compose down -v

# 重新启动服务
docker-compose up -d
```

### 查看服务资源使用

```bash
docker stats
```

## 生产环境部署

Docker Compose 配置主要用于开发环境。生产环境部署请参考:
- [生产部署指南](./docs/deployment/production.md)(待完成)
- 使用独立的配置文件 `docker-compose.prod.yml`
- 使用环境变量管理敏感配置
- 配置反向代理(Nginx)
- 启用 HTTPS
- 配置日志收集和监控

## 更多资源

- [Docker 官方文档](https://docs.docker.com/)
- [Docker Compose 文档](https://docs.docker.com/compose/)
- [项目主文档](./README.md)
- [API 文档](./docs/api/api-specification.md)
