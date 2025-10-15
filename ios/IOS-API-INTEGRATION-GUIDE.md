# iOS API集成指南

## ✅ 配置已完成

### 1. API端点配置

**Environment.swift** 已更新为正确的端口：
- ✅ Development API: `http://localhost:9090/api/v1`
- ✅ Development WebSocket: `ws://localhost:9090/ws`

### 2. 后端服务状态

**当前运行的服务：**
```
✅ Backend API  - http://localhost:9090
✅ PostgreSQL   - localhost:5433
✅ Redis        - localhost:6380
✅ MinIO        - localhost:9000
```

### 3. 测试账号

**可用的测试账号（密码均为 123456）：**

| 用户名 | 密码 | 角色 | 年级 | 昵称 |
|--------|------|------|------|------|
| student01 | 123456 | 学生 | 7年级 | 张三 |
| student02 | 123456 | 学生 | 8年级 | 李四 |
| student03 | 123456 | 学生 | 9年级 | 王五 |
| teacher01 | 123456 | 老师 | - | 陈老师 |

## 📋 iOS集成步骤

### Step 1: 确保后端服务运行

```bash
# 检查服务状态
cd /Users/johnqiu/coding/www/projects/bblearning
docker-compose ps

# 如果服务未运行，启动服务
docker-compose up -d

# 验证API可用
curl http://localhost:9090/api/v1/health
```

### Step 2: 在iOS模拟器中测试

1. **打开Xcode项目**
   ```bash
   cd /Users/johnqiu/coding/www/projects/bblearning/ios/BBLearning
   open BBLearning.xcodeproj
   ```

2. **选择模拟器** - 选择任意iPhone模拟器（推荐iPhone 15 Pro）

3. **运行应用** - 点击运行按钮或按 `Cmd+R`

4. **测试登录**
   - 用户名: `student01`
   - 密码: `123456`
   - 点击登录按钮

### Step 3: 验证网络连接

#### 检查点1: 健康检查
iOS应用启动时会自动调用健康检查接口：
```
GET http://localhost:9090/api/v1/health
```

**预期响应：**
```json
{
  "code": 0,
  "message": "success",
  "data": {
    "service": "bblearning-backend",
    "status": "ok"
  }
}
```

#### 检查点2: 用户登录
输入测试账号后点击登录：
```
POST http://localhost:9090/api/v1/auth/login
Body: {"username":"student01","password":"123456"}
```

**预期响应：**
```json
{
  "code": 0,
  "message": "success",
  "data": {
    "user": {
      "id": 1,
      "username": "student01",
      "nickname": "张三",
      "grade": "7",
      "role": "student"
    },
    "access_token": "eyJhbGci...",
    "refresh_token": "eyJhbGci..."
  }
}
```

#### 检查点3: 获取章节列表
登录成功后，应用会加载7年级的章节：
```
GET http://localhost:9090/api/v1/chapters?grade=7&page=1&page_size=10
Headers: Authorization: Bearer {access_token}
```

**预期响应：**
```json
{
  "code": 0,
  "message": "success",
  "data": {
    "items": [
      {"id": 1, "name": "有理数", "grade": "7", "semester": "上学期"},
      {"id": 2, "name": "整式的加减", "grade": "7", "semester": "上学期"},
      {"id": 3, "name": "一元一次方程", "grade": "7", "semester": "上学期"},
      {"id": 4, "name": "几何图形初步", "grade": "7", "semester": "上学期"}
    ],
    "total": 4,
    "page": 1,
    "page_size": 10
  }
}
```

## 🔍 调试技巧

### 查看网络请求日志

在Xcode中打开Console（`Cmd+Shift+Y`），应该能看到：
```
[Network] GET http://localhost:9090/api/v1/health
[Network] Response: 200 OK
[Network] POST http://localhost:9090/api/v1/auth/login
[Network] Response: 200 OK
```

### 使用Charles/Proxyman抓包

1. 安装Charles或Proxyman
2. 配置iOS模拟器代理
3. 查看所有HTTP请求和响应

### 检查后端日志

```bash
# 实时查看后端日志
docker logs bblearning-backend -f

# 应该能看到类似的日志：
# [GIN] 2025/10/13 - 13:32:17 | 200 | 2.5ms | 127.0.0.1 | GET "/api/v1/health"
# [GIN] 2025/10/13 - 13:32:20 | 200 | 15ms | 127.0.0.1 | POST "/api/v1/auth/login"
```

## 🚨 常见问题

### 问题1: 无法连接到localhost

**症状：** iOS模拟器无法访问 `http://localhost:9090`

**解决方案：**
- ✅ iOS模拟器可以直接访问Mac的localhost，无需特殊配置
- ❌ 如果使用真机测试，需要：
  1. 确保Mac和iPhone在同一WiFi网络
  2. 将localhost改为Mac的IP地址（如 `http://192.168.1.100:9090`）
  3. 在Info.plist中添加App Transport Security例外

### 问题2: 登录失败 - 401 Unauthorized

**症状：** API返回401错误

**可能原因：**
1. 用户名或密码错误
2. 后端数据库未正确初始化

**解决方案：**
```bash
# 验证用户数据是否存在
docker exec -i bblearning-postgres psql -U bblearning -d bblearning_dev \
  -c "SELECT username, nickname, grade FROM users;"

# 如果没有数据，重新导入种子数据
docker exec -i bblearning-postgres psql -U bblearning -d bblearning_dev \
  < /Users/johnqiu/coding/www/projects/bblearning/backend/scripts/seed_complete_data.sql
```

### 问题3: Token过期

**症状：** 登录后一段时间API返回token expired错误

**解决方案：**
- Access Token默认1小时有效期
- 使用Refresh Token刷新：
  ```swift
  POST /api/v1/auth/refresh
  Headers: Authorization: Bearer {refresh_token}
  ```

### 问题4: 网络请求超时

**症状：** 请求长时间没有响应

**检查清单：**
1. ✅ 后端服务是否运行：`docker-compose ps`
2. ✅ 端口是否正确：9090（不是8080）
3. ✅ 防火墙是否阻止连接
4. ✅ 后端日志是否有错误：`docker logs bblearning-backend`

## 📝 API响应格式说明

### 成功响应
```json
{
  "code": 0,
  "message": "success",
  "data": { /* 实际数据 */ },
  "request_id": "uuid"
}
```

### 错误响应
```json
{
  "code": 1000,  // 错误码
  "message": "参数错误",  // 错误信息
  "request_id": "uuid"
}
```

### 错误码对照表

| 错误码 | 说明 |
|--------|------|
| 0 | 成功 |
| 1000 | 参数错误 |
| 1001 | 未授权 |
| 1002 | Token过期 |
| 2000 | 资源不存在 |
| 3000 | 服务器错误 |
| 4000 | 外部服务错误 |

## 🧪 完整测试流程

### 测试脚本（可以在终端运行）

```bash
#!/bin/bash
# iOS API集成测试脚本

echo "=== 测试1: 健康检查 ==="
curl -s http://localhost:9090/api/v1/health | python3 -m json.tool
echo ""

echo "=== 测试2: 用户登录 ==="
LOGIN_RESPONSE=$(curl -s -X POST http://localhost:9090/api/v1/auth/login \
  -H 'Content-Type: application/json' \
  -d '{"username":"student01","password":"123456"}')
echo $LOGIN_RESPONSE | python3 -m json.tool
echo ""

# 提取token
TOKEN=$(echo $LOGIN_RESPONSE | python3 -c "import sys, json; print(json.load(sys.stdin)['data']['access_token'])")

echo "=== 测试3: 获取章节列表 ==="
curl -s "http://localhost:9090/api/v1/chapters?grade=7&page=1&page_size=10" \
  -H "Authorization: Bearer $TOKEN" | python3 -m json.tool
echo ""

echo "=== 测试4: 获取知识点 ==="
curl -s "http://localhost:9090/api/v1/knowledge-points?chapter_id=1&page=1&page_size=5" \
  -H "Authorization: Bearer $TOKEN" | python3 -m json.tool
echo ""

echo "✅ 所有测试完成！"
```

保存为 `test_ios_integration.sh` 并运行：
```bash
chmod +x test_ios_integration.sh
./test_ios_integration.sh
```

## 📚 相关文档

- **后端API文档**: `/backend/docs/architecture/api-specification.md`
- **后端启动状态**: `/backend/STARTUP_STATUS.md`
- **iOS架构文档**: `/ios/BBLearning/ARCHITECTURE.md`
- **测试脚本**: `/backend/scripts/test_api.sh`

## ✅ 集成完成检查清单

完成以下检查项，确认iOS集成成功：

- [ ] 后端服务正常运行（docker-compose ps显示healthy）
- [ ] Environment.swift端口已更新为9090
- [ ] iOS应用可以成功启动
- [ ] 登录页面可以正常显示
- [ ] 使用student01/123456可以成功登录
- [ ] 登录后可以看到用户信息（张三，7年级）
- [ ] 主页可以加载章节列表（有理数、整式的加减等）
- [ ] 点击章节可以查看知识点
- [ ] 网络请求在Xcode Console中有日志输出
- [ ] 后端日志中可以看到来自iOS的请求

## 🎉 下一步

完成集成后，可以继续开发：

1. **完善登录流程** - 添加错误处理、加载动画
2. **实现Token刷新** - 在Token快过期时自动刷新
3. **添加网络缓存** - 提升用户体验
4. **实现离线功能** - 使用Core Data缓存数据
5. **测试其他API** - 练习、错题、AI诊断等功能

---

**更新时间**: 2025-10-13 15:00
**状态**: iOS API端点配置已完成，可以开始测试集成
