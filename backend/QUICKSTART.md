# BBLearning 后端快速启动指南

## 5分钟快速启动

### 前置条件

- Go 1.21+
- Docker Desktop 或 OrbStack
- (可选) PostgreSQL 客户端工具

### 一键启动

```bash
# 1. 进入后端目录
cd backend

# 2. 启动所有服务（Docker + 后端）
./scripts/start_dev.sh
```

脚本会自动：
- ✅ 检查Docker和Go环境
- ✅ 启动PostgreSQL、Redis、MinIO
- ✅ 初始化数据库和种子数据
- ✅ 安装Go依赖
- ✅ 启动后端服务

### 验证服务

在另一个终端运行：

```bash
cd backend

# 快速测试
./scripts/quick_test.sh

# 完整测试
./scripts/test_api.sh
```

## 手动启动步骤

如果自动脚本出错，可以手动启动：

### 1. 启动Docker服务

```bash
cd /path/to/bblearning

# 启动PostgreSQL, Redis, MinIO
docker-compose up -d postgres redis minio

# 检查服务状态
docker-compose ps
```

### 2. 初始化数据库

```bash
cd backend

# 创建数据库
psql -h localhost -p 5432 -U postgres -c "CREATE DATABASE bblearning_dev;"

# 运行迁移 (需要安装 golang-migrate)
make migrate-up

# 导入种子数据
./scripts/run_seed.sh
```

### 3. 配置环境变量

```bash
cd backend

# 复制环境配置
cp .env.example .env

# 编辑配置（可选）
vim .env
```

### 4. 启动后端服务

```bash
cd backend

# 方式1: 使用go run
go run cmd/server/main.go

# 方式2: 使用make
make run

# 方式3: 编译后运行
make build
./bin/server
```

## 访问服务

### API端点

- **健康检查**: http://localhost:8080/api/v1/health
- **API文档**: http://localhost:8080/swagger/index.html (待实现)
- **基础URL**: http://localhost:8080/api/v1

### 测试账号

| 用户名 | 密码 | 角色 | 年级 |
|--------|------|------|------|
| student01 | 123456 | 学生 | 7 |
| student02 | 123456 | 学生 | 8 |
| student03 | 123456 | 学生 | 9 |
| teacher01 | 123456 | 教师 | - |

### 快速测试API

```bash
# 登录
curl -X POST http://localhost:8080/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"student01","password":"123456"}' | jq '.'

# 保存返回的access_token
TOKEN="your_access_token_here"

# 获取当前用户
curl -X GET http://localhost:8080/api/v1/users/me \
  -H "Authorization: Bearer $TOKEN" | jq '.'

# 获取知识树
curl -X GET "http://localhost:8080/api/v1/knowledge/tree?grade=7" \
  -H "Authorization: Bearer $TOKEN" | jq '.'
```

## 常见问题

### Docker连接失败

```bash
# 错误: Cannot connect to the Docker daemon
# 解决: 启动Docker Desktop或OrbStack

# Mac
open -a Docker

# 或使用OrbStack
open -a OrbStack
```

### 端口已被占用

```bash
# 错误: bind: address already in use
# 解决: 查找并杀死占用端口的进程

# 查找占用8080端口的进程
lsof -i :8080

# 杀死进程
kill -9 <PID>

# 或修改.env中的SERVER_PORT
```

### 数据库连接失败

```bash
# 错误: connection refused
# 解决: 检查PostgreSQL是否运行

docker-compose ps postgres

# 重启PostgreSQL
docker-compose restart postgres

# 查看日志
docker-compose logs postgres
```

### Go模块下载慢

```bash
# 设置GOPROXY代理
export GOPROXY=https://goproxy.cn,direct

# 或
export GOPROXY=https://goproxy.io,direct

# 添加到~/.zshrc或~/.bashrc永久生效
```

### 迁移工具未安装

```bash
# Mac
brew install golang-migrate

# Linux
curl -L https://github.com/golang-migrate/migrate/releases/download/v4.16.2/migrate.linux-amd64.tar.gz | tar xvz
sudo mv migrate /usr/local/bin/

# 验证安装
migrate -version
```

## 停止服务

### 停止后端

```
按 Ctrl+C 停止后端服务
```

### 停止Docker服务

```bash
cd /path/to/bblearning

# 停止所有服务
docker-compose stop

# 停止并删除容器
docker-compose down

# 停止并删除容器和数据卷
docker-compose down -v
```

## 开发工作流

### 1. 日常开发

```bash
# 启动服务
cd backend && ./scripts/start_dev.sh

# 修改代码...

# 自动重启（使用air工具）
air

# 或手动重启（Ctrl+C后重新运行）
go run cmd/server/main.go
```

### 2. 测试

```bash
# 单元测试
make test

# 集成测试
./scripts/test_api.sh

# 快速测试
./scripts/quick_test.sh
```

### 3. 代码格式化

```bash
# 格式化代码
make fmt

# 检查代码
make lint
```

### 4. 重置数据库

```bash
# 重新导入种子数据
./scripts/run_seed.sh

# 完全重置
make migrate-down
make migrate-up
./scripts/run_seed.sh
```

## 生产部署

参考 [DOCKER.md](DOCKER.md) 和 [部署文档](docs/deployment/)

## 下一步

- ✅ 后端服务已运行
- ✅ 数据库已初始化
- ✅ 测试账号可用
- 📱 可以开始iOS端集成
- 🌐 可以开始前端开发

## 相关文档

- [CLAUDE.md](CLAUDE.md) - 项目架构和开发指南
- [TESTING.md](TESTING.md) - 测试指南
- [DOCKER.md](DOCKER.md) - Docker部署指南
- [API文档](docs/architecture/api-specification.md)

## 需要帮助？

- 查看日志: `docker-compose logs -f`
- 查看后端日志: 终端输出
- 提交Issue: https://github.com/qiudl/bblearning/issues
