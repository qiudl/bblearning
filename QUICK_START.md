# BBLearning 快速启动指南

## 🚀 一键启动

### 前提条件

1. **启动 Docker**（必须）
   ```bash
   # OrbStack
   open -a OrbStack

   # 或 Docker Desktop
   open -a "Docker Desktop"
   ```

2. **等待 Docker 就绪**（约10-30秒）
   ```bash
   # 验证 Docker 是否运行
   docker info
   ```

### 启动系统

```bash
cd /Users/johnqiu/coding/www/projects/bblearning

# 一键启动所有服务
./start_local.sh
```

**启动过程**（约1-2分钟）:
1. ✅ 检查 Docker 状态
2. ✅ 启动 PostgreSQL (5433)、Redis (6380)、MinIO (9001)
3. ✅ 启动后端服务 (9090)
4. ✅ 启动前端服务 (3002)

### 访问应用

启动完成后，访问：

- **前端应用**: http://localhost:3002
- **后端API**: http://localhost:9090
- **健康检查**: http://localhost:9090/api/v1/health
- **Metrics**: http://localhost:9090/metrics

### 停止系统

```bash
# 一键停止所有服务
./stop_local.sh
```

## 🌐 远程数据库模式

如果你已有远程 PostgreSQL/Redis/MinIO 服务，可以使用远程模式启动，无需本地 Docker。

### 配置远程服务

1. **编辑远程配置文件**
   ```bash
   vi backend/config/config-remote.yaml
   ```

2. **替换占位符**
   ```yaml
   database:
     host: "your-remote-db-host.com"  # 替换为实际远程数据库地址
     password: "your-remote-db-password"  # 替换为实际密码

   redis:
     host: "your-remote-redis-host.com"  # 替换为实际Redis地址
     password: "your-redis-password"

   minio:
     endpoint: "your-remote-minio.com:9000"  # 替换为实际MinIO地址
     access_key: "your-access-key"
     secret_key: "your-secret-key"
   ```

### 启动系统（远程模式）

```bash
cd /Users/johnqiu/coding/www/projects/bblearning

# 一键启动（仅启动后端和前端，连接远程服务）
./start_remote.sh
```

**启动过程**（约30秒-1分钟）:
1. ✅ 检查远程配置文件
2. ✅ 验证配置是否完整
3. ✅ 启动后端服务 (9090) - 连接远程数据库
4. ✅ 启动前端服务 (3002)

### 停止系统（远程模式）

```bash
# 一键停止本地服务（远程服务不受影响）
./stop_remote.sh
```

### 远程模式日志

```bash
# 后端日志（远程模式）
tail -f /tmp/bblearning-backend-remote.log

# 前端日志（远程模式）
tail -f /tmp/bblearning-frontend-remote.log
```

### 注意事项

- 确保远程服务器防火墙允许你的 IP 访问
- 确保数据库用户有足够的权限（CREATE, ALTER, SELECT, INSERT, UPDATE, DELETE）
- 网络延迟可能影响性能
- 建议远程连接使用 SSL（配置文件中 `sslmode: require`）

## 📦 端口分配

| 服务 | 端口 | 说明 |
|------|------|------|
| 前端 | 3002 | React应用 (避开3000) |
| 后端 | 9090 | Gin API服务 (避开8080) |
| PostgreSQL | 5433 | 数据库 (避开5432) |
| Redis | 6380 | 缓存 (避开6379) |
| MinIO | 9001 | 对象存储控制台 |
| MinIO API | 9000 | 对象存储API |

## 🔧 常用命令

### 查看日志

```bash
# 后端日志
tail -f /tmp/bblearning-backend.log

# 前端日志
tail -f /tmp/bblearning-frontend.log

# Docker服务日志
docker-compose logs -f postgres
docker-compose logs -f redis
```

### 重启单个服务

```bash
# 重启后端
pkill -f 'go run cmd/server/main.go'
cd backend && nohup go run cmd/server/main.go > /tmp/bblearning-backend.log 2>&1 &

# 重启前端
pkill -f 'npm start'
cd frontend && PORT=3002 nohup npm start > /tmp/bblearning-frontend.log 2>&1 &
```

### Docker 服务管理

```bash
# 查看服务状态
docker-compose ps

# 重启数据库
docker-compose restart postgres

# 查看数据库日志
docker-compose logs -f postgres

# 进入数据库
docker-compose exec postgres psql -U bblearning -d bblearning_dev
```

## 🐛 故障排查

### 问题 1: Docker 未运行

**症状**:
```
Cannot connect to the Docker daemon
```

**解决**:
```bash
# 启动 Docker
open -a OrbStack  # 或 open -a "Docker Desktop"

# 等待30秒后重新运行
./start_local.sh
```

### 问题 2: 端口被占用

**症状**:
```
bind: address already in use
```

**解决**:
```bash
# 查找占用端口的进程
lsof -i :9090  # 后端
lsof -i :3002  # 前端
lsof -i :5433  # PostgreSQL

# 终止进程
kill -9 <PID>
```

### 问题 3: 后端无法连接数据库

**症状**:
```
failed to connect to database
```

**解决**:
```bash
# 检查数据库是否运行
docker-compose ps postgres

# 重启数据库
docker-compose restart postgres

# 等待10秒后重启后端
pkill -f 'go run cmd/server/main.go'
cd backend && nohup go run cmd/server/main.go > /tmp/bblearning-backend.log 2>&1 &
```

### 问题 4: 前端编译失败

**症状**:
```
Module not found
```

**解决**:
```bash
cd frontend

# 清理并重新安装依赖
rm -rf node_modules package-lock.json
npm install

# 重新启动
PORT=3002 npm start
```

### 问题 5: AI 功能不工作

**症状**: AI聊天无响应或报错

**解决**:
```bash
# 检查 OpenAI API Key 是否配置
echo $OPENAI_API_KEY

# 如果未设置，添加到环境变量
export OPENAI_API_KEY="sk-your-api-key"

# 或在 config.yaml 中配置
vi backend/config/config.yaml
# ai:
#   api_key: "sk-your-api-key"

# 重启后端
pkill -f 'go run cmd/server/main.go'
cd backend && nohup go run cmd/server/main.go > /tmp/bblearning-backend.log 2>&1 &
```

## 📊 监控服务（可选）

### 启动 Prometheus + Grafana

```bash
# 启动监控服务
docker-compose up -d prometheus grafana

# 访问
# Prometheus: http://localhost:9091
# Grafana: http://localhost:3003 (admin/admin)
```

**注意**: 需要先修改 `docker-compose.yml` 中 Prometheus 和 Grafana 的端口映射。

## 🔐 默认账号

### 应用

**测试账号**（需先注册）:
- 用户名: `test`
- 密码: `test123`

### MinIO

- 访问: http://localhost:9001
- 用户名: `minioadmin`
- 密码: `minioadmin123`

### Grafana

- 访问: http://localhost:3003
- 用户名: `admin`
- 密码: `admin`（首次登录需修改）

## 🗄️ 数据库管理

### 连接数据库

```bash
# 使用 Docker
docker-compose exec postgres psql -U bblearning -d bblearning_dev

# 使用本地 psql
psql -h localhost -p 5433 -U bblearning -d bblearning_dev
# 密码: bblearning_dev_password
```

### 常用 SQL

```sql
-- 查看所有表
\dt

-- 查看用户
SELECT id, username, email, created_at FROM users;

-- 查看知识点
SELECT id, name, description FROM knowledge_points LIMIT 10;

-- 查看练习记录
SELECT id, user_id, question_id, is_correct, created_at
FROM practice_records
ORDER BY created_at DESC
LIMIT 10;
```

## 📝 开发流程

### 修改后端代码

```bash
# 1. 修改代码
vim backend/internal/api/handlers/ai_handler.go

# 2. 重启后端（自动重新编译）
pkill -f 'go run cmd/server/main.go'
cd backend && nohup go run cmd/server/main.go > /tmp/bblearning-backend.log 2>&1 &

# 3. 查看日志确认启动成功
tail -f /tmp/bblearning-backend.log
```

### 修改前端代码

```bash
# 1. 修改代码
vim frontend/src/pages/AIChat/index.tsx

# 2. 保存后自动热重载（无需重启）
# 3. 查看浏览器控制台确认更新
```

## 🧪 测试

### API 测试

```bash
# 健康检查
curl http://localhost:9090/api/v1/health

# 注册
curl -X POST http://localhost:9090/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{"username":"test","email":"test@example.com","password":"test123","grade":7}'

# 登录
curl -X POST http://localhost:9090/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"test","password":"test123"}'

# 获取知识点列表（需要token）
TOKEN="your-token-here"
curl http://localhost:9090/api/v1/knowledge/tree \
  -H "Authorization: Bearer $TOKEN"
```

### 前端测试

1. 访问 http://localhost:3002
2. 点击"注册"创建账号
3. 登录后测试各项功能:
   - 知识点浏览
   - 练习题生成
   - AI 问答
   - 错题本

## 📚 相关文档

- **监控指南**: [MONITORING_GUIDE.md](./MONITORING_GUIDE.md)
- **SSE测试**: [SSE_STREAMING_TEST_PLAN.md](./SSE_STREAMING_TEST_PLAN.md)
- **API文档**: `backend/docs/api-specification.md`
- **架构文档**: `backend/docs/tech-architecture.md`

## 💡 提示

- 首次启动可能需要 2-3 分钟（依赖下载和编译）
- 数据库数据持久化在 Docker volumes 中
- 停止服务不会清除数据
- 如需清空数据: `docker-compose down -v`

---

## 🚀 快速命令

### 本地模式（使用 Docker）
- **启动**: `./start_local.sh`
- **停止**: `./stop_local.sh`
- **日志**: `tail -f /tmp/bblearning-backend.log`

### 远程数据库模式（不使用 Docker）
- **启动**: `./start_remote.sh`
- **停止**: `./stop_remote.sh`
- **日志**: `tail -f /tmp/bblearning-backend-remote.log`

### 共同特性
- **端口**: 前端 3002, 后端 9090
- **前端地址**: http://localhost:3002
- **后端地址**: http://localhost:9090
- **健康检查**: http://localhost:9090/api/v1/health
