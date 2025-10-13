# BBLearning 后端测试指南

本文档介绍如何运行BBLearning后端的各种测试。

## 目录

- [测试类型](#测试类型)
- [前置准备](#前置准备)
- [单元测试](#单元测试)
- [集成测试](#集成测试)
- [API手动测试](#api手动测试)
- [性能测试](#性能测试)

## 测试类型

### 1. 单元测试 (Unit Tests)
- 测试单个函数和方法
- 使用Mock对象隔离依赖
- 快速执行，无需数据库

### 2. 集成测试 (Integration Tests)
- 测试完整的API流程
- 需要运行的数据库
- 测试真实的HTTP请求/响应

### 3. 端到端测试 (E2E Tests)
- 测试从前端到后端的完整流程
- 包含iOS/Web客户端 + 后端API

## 前置准备

### 安装依赖

```bash
# 安装Go测试工具
go get -u github.com/stretchr/testify
go get -u github.com/stretchr/testify/mock
go get -u github.com/stretchr/testify/assert

# 安装API测试工具
brew install jq curl  # Mac
# sudo apt-get install jq curl  # Ubuntu
```

### 启动测试环境

```bash
# 启动Docker服务
docker-compose up -d postgres redis minio

# 等待服务就绪
sleep 5

# 运行数据库迁移
make migrate-up

# 导入种子数据
./scripts/run_seed.sh
```

## 单元测试

### 运行所有单元测试

```bash
# 在项目根目录
make test

# 或直接使用go test
go test ./... -v

# 运行特定包的测试
go test ./internal/api/handlers -v

# 运行特定测试函数
go test ./internal/api/handlers -run TestRegister -v
```

### 测试覆盖率

```bash
# 生成覆盖率报告
make test-coverage

# 或
go test ./... -coverprofile=coverage.out
go tool cover -html=coverage.out

# 查看覆盖率统计
go test ./... -cover
```

### 单元测试示例

```go
// internal/api/handlers/auth_handler_test.go
func TestRegister(t *testing.T) {
    // Arrange
    mockService := new(MockAuthService)
    handler := NewAuthHandler(mockService)

    // Act
    response := handler.Register(request)

    // Assert
    assert.Equal(t, 200, response.Code)
}
```

## 集成测试

### 完整API集成测试

```bash
# 1. 确保后端服务运行
make run
# 或在另一个终端: go run cmd/server/main.go

# 2. 运行集成测试脚本
./scripts/test_api.sh

# 3. 指定不同的API地址
API_BASE_URL=http://192.168.1.100:8080/api/v1 ./scripts/test_api.sh
```

### 测试输出

```
========================================
BBLearning API 集成测试
========================================

[INFO] API Base URL: http://localhost:8080/api/v1
[INFO] 开始时间: 2025-10-13 10:30:45

========================================
1. 健康检查
========================================

[TEST] GET /health
[✓ PASS] 健康检查通过

========================================
2. 用户认证API测试
========================================

[TEST] POST /auth/register - 用户注册
[✓ PASS] 用户注册
...

========================================
测试结果汇总
========================================

总测试数: 25
通过测试: 25
失败测试: 0
通过率: 100.00%

✅ 所有测试通过!
```

### 集成测试覆盖的API端点

| 模块 | 端点数 | 说明 |
|------|--------|------|
| 健康检查 | 1 | GET /health |
| 用户认证 | 4 | 注册、登录、刷新Token、登出 |
| 知识点 | 6 | 章节、知识点、知识树、学习进度 |
| 练习 | 5 | 题目列表、生成练习、提交答案、记录、统计 |
| 错题本 | 2 | 错题列表、Top错题 |
| AI服务 | 2 | 生成题目、AI对话 |
| 学习报告 | 4 | 学习报告、薄弱点、进度总览、统计 |
| **总计** | **24** | **所有核心API** |

## API手动测试

### 使用curl

```bash
# 1. 用户登录
curl -X POST http://localhost:8080/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "username": "student01",
    "password": "123456"
  }' | jq '.'

# 保存access_token
TOKEN="your_access_token_here"

# 2. 获取当前用户信息
curl -X GET http://localhost:8080/api/v1/users/me \
  -H "Authorization: Bearer $TOKEN" | jq '.'

# 3. 获取知识树
curl -X GET "http://localhost:8080/api/v1/knowledge/tree?grade=7" \
  -H "Authorization: Bearer $TOKEN" | jq '.'

# 4. 生成练习
curl -X POST http://localhost:8080/api/v1/practice/generate \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "knowledge_point_ids": [1, 2, 3],
    "count": 5,
    "difficulty": "medium",
    "mode": "standard"
  }' | jq '.'
```

### 使用Postman

1. 导入Postman Collection（待创建）
2. 设置环境变量：
   - `base_url`: http://localhost:8080
   - `access_token`: (通过登录获取)
3. 运行Collection Runner进行批量测试

### 使用HTTPie (更友好的curl)

```bash
# 安装: brew install httpie

# 登录
http POST :8080/api/v1/auth/login \
  username=student01 password=123456

# 带Token的请求
http GET :8080/api/v1/users/me \
  Authorization:"Bearer $TOKEN"
```

## 性能测试

### 使用ab (Apache Bench)

```bash
# 安装: brew install httpd (Mac)

# 测试登录API
ab -n 1000 -c 10 \
  -p login.json \
  -T application/json \
  http://localhost:8080/api/v1/auth/login

# login.json 内容:
# {"username":"student01","password":"123456"}
```

### 使用wrk

```bash
# 安装: brew install wrk

# 基本负载测试
wrk -t10 -c100 -d30s http://localhost:8080/api/v1/health

# 带请求体的测试
wrk -t10 -c100 -d30s -s post.lua http://localhost:8080/api/v1/auth/login

# post.lua 内容:
# wrk.method = "POST"
# wrk.body = '{"username":"student01","password":"123456"}'
# wrk.headers["Content-Type"] = "application/json"
```

### 使用k6

```bash
# 安装: brew install k6

# 运行负载测试
k6 run scripts/k6_load_test.js
```

## 测试数据

### 测试用户

| 用户名 | 密码 | 角色 | 年级 |
|--------|------|------|------|
| student01 | 123456 | student | 7 |
| student02 | 123456 | student | 8 |
| student03 | 123456 | student | 9 |
| teacher01 | 123456 | teacher | - |

### 测试知识点

- 章节: 24个 (7-9年级，覆盖主要数学章节)
- 知识点: 60+ 个 (各章节详细知识点)
- 题目: 30+ 道 (涵盖各难度等级)

### 重置测试数据

```bash
# 重新导入种子数据
./scripts/run_seed.sh

# 清空并重建数据库
make migrate-down
make migrate-up
./scripts/run_seed.sh
```

## 持续集成 (CI)

### GitHub Actions

```yaml
# .github/workflows/test.yml
name: Test

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    services:
      postgres:
        image: postgres:15
        env:
          POSTGRES_PASSWORD: postgres
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5

    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-go@v4
        with:
          go-version: '1.21'

      - name: Run tests
        run: make test

      - name: Upload coverage
        uses: codecov/codecov-action@v3
```

## 故障排查

### 测试失败常见原因

1. **数据库连接失败**
   ```bash
   # 检查Docker服务
   docker-compose ps
   # 重启服务
   docker-compose restart postgres
   ```

2. **端口已被占用**
   ```bash
   # 查找占用端口的进程
   lsof -i :8080
   # 杀死进程
   kill -9 <PID>
   ```

3. **Token过期**
   ```bash
   # 重新登录获取新Token
   ./scripts/test_api.sh
   ```

4. **数据不一致**
   ```bash
   # 重置数据库
   ./scripts/run_seed.sh
   ```

## 最佳实践

1. **测试隔离**: 每个测试应该独立，不依赖其他测试的状态
2. **使用Mock**: 单元测试中使用Mock对象隔离外部依赖
3. **清理资源**: 测试后清理创建的资源（数据库记录、文件等）
4. **测试边界条件**: 测试正常情况和异常情况
5. **命名规范**: 测试函数命名清晰，描述测试目的
6. **覆盖率目标**: 保持80%以上的代码覆盖率

## 相关文档

- [API文档](docs/architecture/api-specification.md)
- [开发指南](CLAUDE.md)
- [部署文档](DOCKER.md)

## 问题反馈

如发现测试相关问题，请提交Issue到：
https://github.com/qiudl/bblearning/issues
