# BBLearning 测试文档

本文档详细说明BBLearning项目的完整测试策略、测试用例和执行指南。

---

## 目录

1. [测试策略](#测试策略)
2. [环境准备](#环境准备)
3. [集成测试](#集成测试)
4. [API测试](#api测试)
5. [端到端测试](#端到端测试)
6. [性能测试](#性能测试)
7. [测试报告](#测试报告)

---

## 测试策略

### 测试金字塔

```
        ┌────────────┐
        │  E2E Tests │  端到端测试 (10%)
        └────────────┘
      ┌────────────────┐
      │ Integration Tests│ 集成测试 (30%)
      └────────────────┘
   ┌──────────────────────┐
   │    Unit Tests         │ 单元测试 (60%)
   └──────────────────────┘
```

### 测试覆盖目标

| 测试类型 | 覆盖率目标 | 优先级 |
|---------|-----------|--------|
| 单元测试 | 80%+ | 高 |
| 集成测试 | 关键流程100% | 高 |
| E2E测试 | 核心功能100% | 中 |
| 性能测试 | 主要API | 中 |

### 测试范围

#### MVP阶段（当前）
- ✅ 用户认证流程
- ✅ Token管理和刷新
- ✅ 基础API端点
- ⏳ 前端路由保护
- ⏳ 数据持久化

#### 完整功能
- 学习路径推荐
- AI对话功能
- 图片OCR识别
- 学习报告生成
- 错题本管理

---

## 环境准备

### 1. 安装测试工具

```bash
# 后端测试工具
cd backend/
go install github.com/golang/mock/mockgen@latest
go get -u github.com/stretchr/testify

# API测试工具
brew install curl jq  # macOS
# 或安装 Postman / Insomnia

# 性能测试工具
brew install apache-bench  # ab
brew install wrk           # wrk
```

### 2. 启动测试环境

```bash
# 方式1: Docker Compose（推荐）
docker-compose up -d

# 方式2: 本地服务
# 终端1: 启动后端
cd backend && make run

# 终端2: 启动前端
cd frontend && npm start
```

### 3. 验证环境

```bash
# 检查后端
curl http://localhost:8080/health

# 检查前端
curl http://localhost:3000

# 检查数据库
docker-compose exec postgres psql -U bblearning -d bblearning_dev -c "SELECT 1;"
```

---

## 集成测试

### 自动化集成测试

使用提供的自动化脚本进行完整集成测试：

```bash
# 运行集成测试脚本
./scripts/integration-test.sh

# 自定义API地址
API_BASE_URL=http://api.example.com/api/v1 ./scripts/integration-test.sh
```

### 测试覆盖范围

脚本自动测试以下场景：

1. **服务健康检查**
   - 后端API可用性
   - 前端页面可访问性

2. **用户认证流程**
   - 用户注册
   - 用户登录
   - Token获取

3. **受保护API访问**
   - 获取用户信息
   - 获取知识点列表
   - 获取章节信息

4. **Token刷新机制**
   - 使用refresh_token获取新access_token

5. **错误处理**
   - 无效登录凭据
   - 未授权访问
   - 404错误处理

### 预期输出

```
================================================
BBLearning 集成测试
================================================
API URL: http://localhost:8080/api/v1
Frontend URL: http://localhost:3000
================================================

======================================
1. 服务健康检查
======================================
Testing: 后端健康检查 ... PASSED (Status: 200)
Testing: 前端页面访问 ... PASSED (Status: 200)

======================================
2. 用户认证测试
======================================
测试用户: testuser_12345

Attempting registration...
PASSED 用户注册成功 (Status: 201)
  ✓ Access Token获取成功
  ✓ Refresh Token获取成功

Attempting login...
PASSED 用户登录成功 (Status: 200)

======================================
3. 受保护API测试
======================================
Testing: 获取当前用户信息 ... PASSED (Status: 200)
Testing: 获取知识点列表 ... PASSED (Status: 200)
Testing: 获取章节列表 ... PASSED (Status: 200)

======================================
4. Token刷新测试
======================================
Testing: 刷新Access Token ... PASSED (Status: 200)

======================================
5. 错误处理测试
======================================
Testing: 无效的登录凭据 ... PASSED (Status: 401)
Testing: 未授权的API访问 ... PASSED (Status: 401)
Testing: 不存在的端点 ... PASSED (Status: 404)

======================================
测试结果汇总
======================================
总测试数: 12
通过: 12
失败: 0

✓ 所有测试通过！
```

---

## API测试

### 使用Postman/Thunder Client

1. **导入测试集合**

```bash
# 导入文件
tests/api-tests.json
```

2. **配置环境变量**

```json
{
  "base_url": "http://localhost:8080/api/v1",
  "test_username": "testuser_{{$randomInt}}",
  "test_password": "TestPassword123!"
}
```

3. **运行测试套件**

按顺序执行以下测试组：

#### 1. Authentication Tests
- 1.1 Register User
- 1.2 Login User
- 1.3 Refresh Token
- 1.4 Logout

#### 2. User Management Tests
- 2.1 Get Current User
- 2.2 Update User Profile

#### 3. Knowledge & Chapters Tests
- 3.1 Get Chapters by Grade
- 3.2 Get Knowledge Points
- 3.3 Get Knowledge Point Detail

#### 4. Practice Tests
- 4.1 Generate Practice Questions
- 4.2 Submit Answer
- 4.3 Get Practice Records

#### 5. AI Chat Tests
- 5.1 Send Chat Message
- 5.2 OCR Math Problem

#### 6. Wrong Questions Tests
- 6.1 Get Wrong Questions
- 6.2 Mark Wrong Question Resolved

#### 7. Reports Tests
- 7.1 Get Learning Report
- 7.2 Get Weak Points
- 7.3 Get Progress

#### 8. Error Cases
- 8.1 Invalid Login (expect 401)
- 8.2 Unauthorized Access (expect 401)
- 8.3 Not Found (expect 404)

### 手动API测试

#### 示例1: 用户注册

```bash
curl -X POST http://localhost:8080/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "username": "testuser1",
    "password": "Pass123!",
    "grade": "7"
  }'
```

**预期响应** (201 Created):
```json
{
  "code": 0,
  "message": "注册成功",
  "data": {
    "user": {
      "id": 1,
      "username": "testuser1",
      "grade": "7",
      "created_at": "2025-10-13T08:00:00Z"
    },
    "access_token": "eyJhbGciOiJIUzI1NiIs...",
    "refresh_token": "eyJhbGciOiJIUzI1NiIs..."
  }
}
```

#### 示例2: 用户登录

```bash
curl -X POST http://localhost:8080/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "username": "testuser1",
    "password": "Pass123!"
  }'
```

#### 示例3: 访问受保护API

```bash
# 设置token变量
ACCESS_TOKEN="your_access_token_here"

curl -X GET http://localhost:8080/api/v1/users/me \
  -H "Authorization: Bearer $ACCESS_TOKEN"
```

#### 示例4: 刷新Token

```bash
REFRESH_TOKEN="your_refresh_token_here"

curl -X POST http://localhost:8080/api/v1/auth/refresh \
  -H "Content-Type: application/json" \
  -d "{\"refresh_token\": \"$REFRESH_TOKEN\"}"
```

---

## 端到端测试

### E2E测试场景

#### 场景1: 新用户完整学习流程

**步骤**:
1. 访问前端页面 `http://localhost:3000`
2. 点击"注册"标签
3. 填写注册信息（用户名、密码、年级）
4. 提交注册表单
5. 自动跳转到学习页面
6. 选择一个知识点，点击"开始练习"
7. 完成练习题目
8. 查看学习进度
9. 退出登录

**验证点**:
- [ ] 注册表单验证（用户名长度、密码强度）
- [ ] 注册成功后自动登录
- [ ] 自动跳转到学习页面
- [ ] Token存储在localStorage
- [ ] 知识点卡片正确显示
- [ ] 练习页面正确加载
- [ ] 答题后显示正确解析
- [ ] 退出登录后清除Token

#### 场景2: 已注册用户登录

**步骤**:
1. 访问登录页面
2. 输入用户名和密码
3. 点击"登录"
4. 验证跳转到学习页面
5. 验证持久化的学习进度

**验证点**:
- [ ] 登录表单验证
- [ ] 错误密码提示
- [ ] 登录成功跳转
- [ ] Token自动刷新
- [ ] 学习进度正确显示

#### 场景3: Token过期处理

**步骤**:
1. 登录系统
2. 等待token过期（或手动修改过期时间）
3. 执行需要认证的操作
4. 验证自动刷新token
5. 验证操作成功完成

**验证点**:
- [ ] Token过期检测
- [ ] 自动调用refresh接口
- [ ] 新token存储
- [ ] 原请求重试成功
- [ ] 用户无感知

#### 场景4: 路由保护

**步骤**:
1. 未登录状态直接访问 `/learn`
2. 验证重定向到 `/login`
3. 登录后自动返回原页面

**验证点**:
- [ ] 未登录访问受保护路由被拦截
- [ ] 重定向到登录页
- [ ] 登录后正确返回

### 手动E2E测试清单

使用此清单进行完整的手动端到端测试：

```markdown
## 前置条件
- [ ] 后端服务运行正常 (http://localhost:8080)
- [ ] 前端服务运行正常 (http://localhost:3000)
- [ ] 数据库已初始化
- [ ] 测试数据已准备

## 用户认证模块
- [ ] 注册新用户（正常流程）
- [ ] 注册验证（用户名重复、密码弱、必填项）
- [ ] 登录（正常流程）
- [ ] 登录失败（错误密码、不存在的用户）
- [ ] 退出登录
- [ ] Token自动刷新
- [ ] Token过期后重新登录

## 学习模块
- [ ] 查看章节列表
- [ ] 查看知识点详情
- [ ] 知识点掌握度显示
- [ ] 开始练习按钮

## 练习模块
- [ ] 生成练习题
- [ ] 答题（选择题）
- [ ] 答题（填空题）
- [ ] 答题（解答题）
- [ ] 提交答案
- [ ] 查看解析
- [ ] 答题统计更新

## AI对话模块
- [ ] 发送消息
- [ ] 接收回复
- [ ] 历史记录
- [ ] 图片上传（OCR）

## 错题本模块
- [ ] 查看错题列表
- [ ] 错题详情
- [ ] 标记已掌握
- [ ] 重新练习

## 学习报告模块
- [ ] 查看学习报告
- [ ] 进度曲线
- [ ] 薄弱点分析
- [ ] 知识点掌握度

## 用户界面
- [ ] 响应式布局（移动端/桌面端）
- [ ] 页面加载状态
- [ ] 错误提示
- [ ] 成功提示
- [ ] 导航菜单

## 性能
- [ ] 首屏加载时间 < 3s
- [ ] API响应时间 < 500ms
- [ ] 页面切换流畅
- [ ] 无内存泄漏
```

---

## 性能测试

### 使用Apache Bench进行负载测试

#### 测试登录接口

```bash
# 100并发，1000请求
ab -n 1000 -c 100 -p login-data.json -T application/json \
   http://localhost:8080/api/v1/auth/login

# login-data.json 内容
echo '{"username":"testuser","password":"pass123"}' > login-data.json
```

**预期结果**:
```
Requests per second:    500-1000 [#/sec]
Time per request:       1-2 ms
```

#### 测试受保护API

```bash
# 创建包含Authorization头的请求
ab -n 1000 -c 100 -H "Authorization: Bearer ${ACCESS_TOKEN}" \
   http://localhost:8080/api/v1/users/me
```

### 使用wrk进行压力测试

```bash
# 持续10秒，10个连接，2个线程
wrk -t2 -c10 -d10s http://localhost:8080/api/v1/health

# 使用Lua脚本测试登录
cat > post.lua << 'EOF'
wrk.method = "POST"
wrk.body   = '{"username":"testuser","password":"pass123"}'
wrk.headers["Content-Type"] = "application/json"
EOF

wrk -t2 -c10 -d10s -s post.lua http://localhost:8080/api/v1/auth/login
```

### 性能基准

| API端点 | 平均响应时间 | 95th百分位 | QPS目标 |
|---------|-------------|-----------|---------|
| /health | < 10ms | < 20ms | 1000+ |
| /auth/login | < 100ms | < 200ms | 500+ |
| /auth/register | < 150ms | < 300ms | 300+ |
| /users/me | < 50ms | < 100ms | 800+ |
| /knowledge | < 100ms | < 200ms | 500+ |
| /practice/generate | < 200ms | < 500ms | 200+ |
| /ai/chat | < 2000ms | < 5000ms | 50+ |

### 性能优化建议

1. **数据库优化**
   - 添加索引（username, email, grade等）
   - 使用连接池
   - 查询优化（避免N+1）

2. **缓存策略**
   - Redis缓存用户信息
   - 缓存知识点树
   - 缓存题目详情

3. **API优化**
   - 响应数据压缩（Gzip）
   - 分页查询
   - 字段过滤

4. **前端优化**
   - 代码分割
   - 图片懒加载
   - 虚拟滚动

---

## 测试报告

### 测试执行记录模板

```markdown
# BBLearning 测试执行报告

**测试日期**: 2025-10-13
**测试人员**: [姓名]
**测试环境**: Development
**版本号**: v1.0.0-mvp

## 测试概述

- **测试范围**: MVP核心功能
- **测试方法**: 自动化 + 手动
- **测试时长**: 2小时

## 测试结果汇总

| 模块 | 用例数 | 通过 | 失败 | 阻塞 | 通过率 |
|-----|--------|------|------|------|--------|
| 用户认证 | 8 | 8 | 0 | 0 | 100% |
| 用户管理 | 4 | 4 | 0 | 0 | 100% |
| 知识点 | 6 | 6 | 0 | 0 | 100% |
| 练习 | 8 | 8 | 0 | 0 | 100% |
| AI对话 | 3 | 2 | 1 | 0 | 67% |
| 错题本 | 4 | 4 | 0 | 0 | 100% |
| 报告 | 4 | 4 | 0 | 0 | 100% |
| **总计** | **37** | **36** | **1** | **0** | **97%** |

## 缺陷列表

### 高优先级
无

### 中优先级
1. **AI对话超时** (BUG-001)
   - 描述: AI对话API在30秒后超时
   - 复现步骤: 发送复杂问题到/ai/chat
   - 预期: 在10秒内返回响应
   - 实际: 30秒超时
   - 影响: 用户体验差
   - 建议: 增加超时时间或流式返回

### 低优先级
无

## 性能测试结果

- 登录接口QPS: 580/s ✓
- 平均响应时间: 120ms ✓
- 95th百分位: 280ms ✓

## 测试结论

✅ **通过** - MVP核心功能测试通过，可以进入部署阶段

## 后续建议

1. 修复AI对话超时问题
2. 增加单元测试覆盖率
3. 添加前端自动化测试
4. 完善错误处理和提示
```

---

## 持续集成

### GitHub Actions配置

创建 `.github/workflows/test.yml`:

```yaml
name: Tests

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

jobs:
  backend-test:
    runs-on: ubuntu-latest

    services:
      postgres:
        image: postgres:15
        env:
          POSTGRES_USER: bblearning
          POSTGRES_PASSWORD: testpass
          POSTGRES_DB: bblearning_test
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
        ports:
          - 5432:5432

    steps:
    - uses: actions/checkout@v3

    - name: Set up Go
      uses: actions/setup-go@v4
      with:
        go-version: '1.23'

    - name: Run backend tests
      working-directory: ./backend
      run: |
        go mod download
        go test -v -coverprofile=coverage.out ./...
        go tool cover -html=coverage.out -o coverage.html

    - name: Upload coverage
      uses: codecov/codecov-action@v3
      with:
        files: ./backend/coverage.out

  frontend-test:
    runs-on: ubuntu-latest

    steps:
    - uses: actions/checkout@v3

    - name: Set up Node
      uses: actions/setup-node@v3
      with:
        node-version: '18'

    - name: Install dependencies
      working-directory: ./frontend
      run: npm ci

    - name: Run frontend tests
      working-directory: ./frontend
      run: npm test -- --coverage

    - name: Build
      working-directory: ./frontend
      run: npm run build

  integration-test:
    runs-on: ubuntu-latest
    needs: [backend-test, frontend-test]

    steps:
    - uses: actions/checkout@v3

    - name: Start services
      run: docker-compose up -d

    - name: Wait for services
      run: |
        timeout 60 bash -c 'until curl -f http://localhost:8080/health; do sleep 2; done'

    - name: Run integration tests
      run: ./scripts/integration-test.sh

    - name: Stop services
      run: docker-compose down
```

---

## 附录

### 测试数据

#### 测试用户

| 用户名 | 密码 | 年级 | 用途 |
|-------|------|------|------|
| testuser1 | Pass123! | 7 | 基础功能测试 |
| testuser2 | Pass123! | 8 | 并发测试 |
| admin | AdminPass123! | - | 管理功能测试 |

#### 测试知识点

- 三角形的边（ID: 1, Grade: 7, Difficulty: basic）
- 三角形的角（ID: 2, Grade: 7, Difficulty: basic）
- 全等三角形（ID: 3, Grade: 7, Difficulty: medium）

### 常见问题

**Q: 集成测试脚本报错 "Connection refused"**

A: 确保后端服务已启动。检查 `docker-compose ps` 或 `lsof -i :8080`

**Q: API测试返回401**

A: Token可能已过期。重新执行登录获取新token。

**Q: 前端页面空白**

A: 检查浏览器控制台错误。通常是API地址配置错误或CORS问题。

---

**文档版本**: v1.0
**最后更新**: 2025-10-13
**维护者**: BBLearning团队
