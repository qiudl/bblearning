# iOS端与后端API集成指南

## 概述

本文档说明如何将iOS应用连接到本地或远程后端API。

## 网络配置

iOS应用的网络配置位于：
```
ios/BBLearning/BBLearning/Config/Environment.swift
```

### 环境配置

目前支持三种环境：

| 环境 | BaseURL | 说明 |
|------|---------|------|
| Development | `http://localhost:8080/api/v1` | 本地开发（默认） |
| Staging | `https://staging-api.bblearning.com/api/v1` | 预发布环境 |
| Production | `https://api.bblearning.com/api/v1` | 生产环境 |

### 切换环境

#### Debug模式（开发环境）
默认情况下，Debug构建使用Development环境，自动连接到`localhost:8080`。

#### 修改本地IP地址
如果需要连接到其他设备上的后端（如真机测试）：

```swift
// 编辑 Environment.swift
case .development:
    return "http://192.168.1.100:8080/api/v1"  // 替换为Mac的IP地址
```

#### 获取Mac本机IP地址

```bash
# 查看IP地址
ifconfig | grep "inet " | grep -v 127.0.0.1

# 或
ipconfig getifaddr en0
```

## 集成步骤

### 1. 启动后端服务

```bash
cd backend

# 一键启动所有服务
./scripts/start_dev.sh

# 验证服务运行
./scripts/quick_test.sh
```

确保输出显示：
```
✅ 所有测试通过!
后端API已就绪，可以开始iOS端集成
```

### 2. 配置iOS项目

iOS项目已经配置好，无需额外设置。默认配置：

- ✅ BaseURL: `http://localhost:8080/api/v1`
- ✅ 超时时间: 30秒
- ✅ 自动Token刷新: 已启用
- ✅ 网络日志: Debug模式启用

### 3. 运行iOS应用

#### 使用Xcode

```bash
# 打开项目
cd ios/BBLearning
open BBLearning.xcodeproj

# 在Xcode中:
# 1. 选择模拟器: iPhone 15 Pro (iOS 17+)
# 2. 点击运行 (⌘R)
```

#### 使用命令行

```bash
cd ios/BBLearning

# 构建
xcodebuild -project BBLearning.xcodeproj \
  -scheme BBLearning \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
  build

# 运行
xcodebuild -project BBLearning.xcodeproj \
  -scheme BBLearning \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
  run
```

### 4. 测试连接

#### 登录测试

1. 启动iOS应用
2. 在登录界面输入：
   - 用户名: `student01`
   - 密码: `123456`
3. 点击登录

期望结果：
- ✅ 登录成功
- ✅ 跳转到主页
- ✅ 显示用户昵称 "张三"
- ✅ 加载知识点数据

#### API调用验证

在Xcode控制台查看网络日志：

```
🚀 [POST] http://localhost:8080/api/v1/auth/login
Headers: ["Content-Type": "application/json"]
Body: {"username":"student01","password":"123456"}

✅ [200] http://localhost:8080/api/v1/auth/login
Response: {"code":0,"message":"登录成功","data":{...}}
```

## 真机测试

### 方案1: 使用Mac IP（推荐）

1. 获取Mac IP地址:
   ```bash
   ipconfig getifaddr en0
   # 输出例如: 192.168.1.100
   ```

2. 修改Environment.swift:
   ```swift
   case .development:
       return "http://192.168.1.100:8080/api/v1"
   ```

3. 确保iPhone和Mac在同一WiFi网络

4. 重新构建并运行到真机

### 方案2: 使用Ngrok（远程测试）

1. 安装Ngrok:
   ```bash
   brew install ngrok
   ```

2. 启动Ngrok隧道:
   ```bash
   ngrok http 8080
   ```

3. 使用Ngrok提供的URL:
   ```
   Forwarding: https://xxxx-xx-xx-xx-xx.ngrok.io -> http://localhost:8080
   ```

4. 修改Environment.swift:
   ```swift
   case .development:
       return "https://xxxx-xx-xx-xx-xx.ngrok.io/api/v1"
   ```

### 方案3: 部署到云服务器

参考 `backend/DOCKER.md` 部署到云服务器后，修改：

```swift
case .staging:
    return "https://your-server.com/api/v1"
```

然后在Xcode中选择Staging Build Configuration。

## 网络安全设置

### iOS App Transport Security (ATS)

开发环境已配置允许HTTP请求（Info.plist）：

```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <true/>
    <key>NSAllowsLocalNetworking</key>
    <true/>
</dict>
```

⚠️ **生产环境务必使用HTTPS!**

## 故障排查

### 问题1: 无法连接到localhost

**现象**:
```
❌ No connection
```

**解决**:
1. 确认后端服务正在运行:
   ```bash
   curl http://localhost:8080/api/v1/health
   ```

2. 真机无法连接localhost，需使用Mac IP地址

3. 检查防火墙设置

### 问题2: Token过期

**现象**:
```
401 Unauthorized
```

**解决**:
- iOS已实现自动Token刷新
- 如仍失败，重新登录

### 问题3: 网络请求超时

**现象**:
```
❌ Request timeout
```

**解决**:
1. 检查网络连接
2. 增加超时时间（Configuration.swift）:
   ```swift
   static let apiTimeout: TimeInterval = 60
   ```

### 问题4: 数据解析失败

**现象**:
```
❌ Decoding error
```

**解决**:
1. 检查API响应格式是否正确
2. 查看网络日志的Response内容
3. 确认后端返回的字段与iOS模型一致

## 测试账号

| 用户名 | 密码 | 角色 | 年级 | 昵称 |
|--------|------|------|------|------|
| student01 | 123456 | 学生 | 7 | 张三 |
| student02 | 123456 | 学生 | 8 | 李四 |
| student03 | 123456 | 学生 | 9 | 王五 |

## 功能测试清单

完成后端集成后，测试以下功能：

### 1. 用户认证 ✅
- [x] 用户登录
- [x] Token自动刷新
- [x] 用户信息获取
- [x] 退出登录

### 2. 知识点学习 ✅
- [x] 获取章节列表
- [x] 获取知识点树
- [x] 知识点搜索
- [x] 学习进度追踪

### 3. 练习系统 ✅
- [x] 生成练习题目
- [x] 提交答案
- [x] 获取练习记录
- [x] 练习统计

### 4. AI辅导 ✅
- [x] AI对话
- [x] 拍照识题（需配置AI API）
- [x] 快捷提问

### 5. 错题本 ✅
- [x] 错题列表
- [x] 错题详情
- [x] 错题统计

### 6. 学习报告 ✅
- [x] 学习统计
- [x] 进度分析
- [x] 薄弱点识别

## 性能优化

### 1. 缓存策略

iOS已实现三级缓存：
- ✅ 内存缓存（快速访问）
- ✅ Realm本地数据库（离线支持）
- ✅ 网络请求（最新数据）

### 2. 图片加载优化

使用Kingfisher或Nuke进行图片缓存和懒加载。

### 3. 网络请求优化

- ✅ 请求合并
- ✅ 分页加载
- ✅ 防抖搜索（300ms）

## 监控和日志

### 网络日志

Debug模式下自动记录所有网络请求：

```swift
// 查看日志
Logger.shared.network("Request details...")
```

### Crashlytics集成（待实现）

```swift
// 记录错误
Crashlytics.crashlytics().record(error: error)
```

## 下一步

- [ ] 集成Firebase Analytics
- [ ] 添加推送通知
- [ ] 实现离线模式完整同步
- [ ] 优化图片加载性能
- [ ] 添加单元测试和UI测试

## 相关文档

- [后端API文档](backend/docs/architecture/api-specification.md)
- [后端快速启动](backend/QUICKSTART.md)
- [iOS开发进度](ios/PROGRESS.md)
- [项目状态](PROJECT-STATUS.md)

## 需要帮助？

- 查看后端日志: 后端终端输出
- 查看iOS日志: Xcode控制台
- 提交Issue: https://github.com/qiudl/bblearning/issues
