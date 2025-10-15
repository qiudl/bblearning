# BBLearning iOS App - Xcode配置与运行指南

## 目录
1. [环境要求](#环境要求)
2. [打开项目](#打开项目)
3. [添加Swift Package依赖](#添加swift-package依赖)
4. [项目配置](#项目配置)
5. [编译项目](#编译项目)
6. [在模拟器上运行](#在模拟器上运行)
7. [常见问题](#常见问题)

---

## 环境要求

- **macOS**: 13.0 (Ventura) 或更高版本
- **Xcode**: 15.0 或更高版本
- **iOS 模拟器**: iOS 17.0 或更高版本
- **Swift**: 5.9+

---

## 打开项目

### 步骤 1: 定位项目文件

项目位置：
```
/Users/johnqiu/coding/www/projects/bblearning/ios/BBLearningApp/
```

### 步骤 2: 打开Xcode项目

**方法 1 - 使用Finder:**
1. 打开Finder
2. 导航到上述路径
3. 双击 `BBLearningApp.xcodeproj` 文件

**方法 2 - 使用终端:**
```bash
cd ~/coding/www/projects/bblearning/ios/BBLearningApp
open BBLearningApp.xcodeproj
```

---

## 添加Swift Package依赖

项目需要以下6个Swift Package依赖。请按照以下步骤添加：

### 添加步骤（通用）

1. 在Xcode中，选择菜单 **File → Add Package Dependencies...**
2. 在搜索框中粘贴Package URL
3. 设置版本要求（Dependency Rule）
4. 点击 **Add Package**
5. 选择要添加到的Target（选择 `BBLearningApp`）
6. 点击 **Add Package** 确认

### Package 1: Alamofire (网络请求)

- **URL**: `https://github.com/Alamofire/Alamofire.git`
- **版本**: `5.8.0` - `Next Major` (Up to Next Major Version)
- **用途**: HTTP网络请求库

### Package 2: Realm Swift (本地数据库)

- **URL**: `https://github.com/realm/realm-swift.git`
- **版本**: `10.45.0` - `Next Major`
- **用途**: 本地数据持久化
- **注意**: 需要同时添加 `RealmSwift` 和 `Realm` 两个product

### Package 3: Swinject (依赖注入)

- **URL**: `https://github.com/Swinject/Swinject.git`
- **版本**: `2.8.0` - `Next Major`
- **用途**: 依赖注入容器

### Package 4: KeychainAccess (安全存储)

- **URL**: `https://github.com/kishikawakatsumi/KeychainAccess.git`
- **版本**: `4.2.0` - `Next Major`
- **用途**: Keychain安全存储（存储Token等敏感数据）

### Package 5: Nuke (图片加载)

- **URL**: `https://github.com/kean/Nuke.git`
- **版本**: `12.1.0` - `Next Major`
- **用途**: 异步图片加载和缓存

### Package 6: swift-log (日志)

- **URL**: `https://github.com/apple/swift-log.git`
- **版本**: `1.5.0` - `Next Major`
- **用途**: 结构化日志记录

### 验证依赖添加

添加完所有Package后，在Xcode左侧导航栏中应该能看到：

```
BBLearningApp
├── BBLearningApp
├── Package Dependencies
    ├── Alamofire
    ├── KeychainAccess
    ├── Nuke
    ├── Realm
    ├── Swinject
    └── swift-log
```

---

## 项目配置

### 配置 1: 签名和证书

1. 选择项目根节点 `BBLearningApp`
2. 选择Target `BBLearningApp`
3. 选择 **Signing & Capabilities** 标签
4. 设置 **Team**: 选择你的开发者账号（或使用Personal Team）
5. 确认 **Bundle Identifier**: `com.bblearning.app` （或修改为你的唯一ID）
6. 勾选 **Automatically manage signing**

### 配置 2: 部署目标

在 **General** 标签中：
- **Minimum Deployments**: iOS 17.0
- **Supported Destinations**: iPhone

### 配置 3: Build Settings

检查以下设置（通常默认即可）：
- **Swift Language Version**: Swift 5
- **Build Configuration**: Debug（开发）/ Release（发布）

---

## 编译项目

### 步骤 1: 清理构建缓存

首次编译前，建议清理构建缓存：
- 菜单: **Product → Clean Build Folder** (快捷键: `Shift + Cmd + K`)

### 步骤 2: 选择模拟器

在Xcode顶部工具栏：
1. 点击设备选择器（scheme selector）
2. 选择一个iOS模拟器，例如:
   - **iPhone 15 Pro** (推荐)
   - **iPhone 15**
   - 或其他iOS 17+模拟器

### 步骤 3: 开始编译

- 菜单: **Product → Build** (快捷键: `Cmd + B`)
- 或直接点击 **Run** 按钮（会自动编译）

### 步骤 4: 查看编译输出

编译过程中：
- 查看Xcode底部的 **Build** 进度条
- 如有错误，会在 **Issue Navigator** (左侧栏第5个图标) 中显示

---

## 在模拟器上运行

### 启动应用

1. 确保已选择iOS模拟器（不是"Any iOS Device"）
2. 点击Xcode左上角的 **Run** 按钮（▶️）或按 `Cmd + R`
3. 等待模拟器启动和应用安装
4. 应用会自动启动并显示登录页面

### 验证功能

应用启动后，验证以下功能：

#### 1. 登录页面
- 显示"BBLearning"标题
- 用户名和密码输入框
- "登录"和"注册"按钮

#### 2. 测试账号登录

使用测试账号（确保后端服务运行）：
- **用户名**: `testuser`
- **密码**: `password123`

或者先注册新账号。

#### 3. 首页验证

登录成功后应看到：
- ✅ 欢迎卡片（显示用户昵称和问候语）
- ✅ 根据时间变化的图标（早晨太阳/晚上月亮）
- ✅ 今日学习数据（学习时长、完成题目、正确率）
- ✅ 快捷入口（开始练习、错题本、AI辅导、学习报告）
- ✅ 学习进度（知识点掌握、练习完成度、错题复习率）
- ✅ AI推荐练习（如有数据）

#### 4. 导航测试

点击底部Tab Bar切换：
- 首页 (Home)
- 知识 (Knowledge)
- 练习 (Practice)
- 错题 (Wrong Questions)
- 我的 (Profile)

---

## 常见问题

### 问题 1: 找不到Swift Package

**症状**:
```
No such module 'Alamofire'
```

**解决方案**:
1. 检查Package Dependencies是否正确添加
2. 尝试清理并重新解析包：
   - **File → Packages → Reset Package Caches**
   - **File → Packages → Update to Latest Package Versions**
3. 重新构建项目 (`Cmd + Shift + K` 然后 `Cmd + B`)

### 问题 2: 代码签名失败

**症状**:
```
Code signing is required for product type 'Application'
```

**解决方案**:
1. 在 **Signing & Capabilities** 中选择有效的Team
2. 如果没有付费开发者账号，选择 **Personal Team**（免费，但有限制）
3. 修改Bundle Identifier为唯一值

### 问题 3: 模拟器无法启动

**症状**:
模拟器一直显示黑屏或崩溃

**解决方案**:
1. 重启模拟器：
   - **Device → Erase All Content and Settings...**
2. 或选择不同的模拟器型号
3. 重启Xcode

### 问题 4: 网络请求失败

**症状**:
应用显示"加载失败"或网络错误

**解决方案**:
1. 确保后端服务正在运行：
   ```bash
   cd ~/coding/www/projects/bblearning/backend
   ./scripts/start_dev.sh
   ```
2. 检查 `Configuration.swift` 中的API Base URL：
   ```swift
   // 开发环境应该使用本地地址
   static let development = Configuration(
       apiBaseURL: "http://localhost:8080/api/v1",
       ...
   )
   ```
3. 在模拟器中，`localhost` 指向模拟器自身，需要使用：
   - Mac的实际IP地址（如 `http://192.168.1.100:8080/api/v1`）
   - 或使用 `http://127.0.0.1:8080/api/v1`（某些情况下有效）

### 问题 5: Realm数据库错误

**症状**:
```
Realm accessed from incorrect thread
```

**解决方案**:
- 这是代码问题，需要确保Realm操作在正确的线程上执行
- 查看相关Repository代码，确保使用了正确的线程处理

### 问题 6: 构建时间过长

**解决方案**:
1. 启用并行构建：
   - **Xcode → Settings → Locations → Derived Data**
   - 点击箭头打开文件夹，删除旧的构建数据
2. 在 **Build Settings** 中搜索 "Build Active Architecture Only"，设置为 `Yes`

### 问题 7: 无法连接到后端（localhost问题）

**重要**: iOS模拟器中的 `localhost` 指向模拟器自身，而不是Mac主机。

**解决方案**:

**方法 1: 使用Mac的IP地址**
1. 获取Mac的IP地址：
   ```bash
   ifconfig | grep "inet " | grep -v 127.0.0.1
   ```
   例如输出: `inet 192.168.1.100`

2. 修改 `BBLearning/BBLearning/Config/Configuration.swift`:
   ```swift
   static let development = Configuration(
       apiBaseURL: "http://192.168.1.100:8080/api/v1",  // 使用Mac的实际IP
       environment: .development
   )
   ```

**方法 2: 配置后端允许所有网络接口**

确保后端配置 `backend/config/config.yaml` 中：
```yaml
server:
  host: "0.0.0.0"  # 监听所有网络接口
  port: 8080
```

**方法 3: 使用环境变量动态配置**

创建可切换的配置：
```swift
static let development = Configuration(
    apiBaseURL: ProcessInfo.processInfo.environment["API_BASE_URL"]
        ?? "http://localhost:8080/api/v1",
    environment: .development
)
```

然后在Xcode中设置环境变量：
1. **Product → Scheme → Edit Scheme...**
2. 选择 **Run** → **Arguments** 标签
3. 在 **Environment Variables** 中添加：
   - Name: `API_BASE_URL`
   - Value: `http://192.168.1.100:8080/api/v1`

---

## 下一步

完成模拟器运行后，可以继续：

1. **测试完整用户流程**
   - 注册 → 登录 → 浏览知识点 → 开始练习 → 查看错题

2. **开发调试**
   - 使用断点调试
   - 查看Console日志输出
   - 使用Xcode的View Debugger

3. **继续开发任务**
   - Task #2534: 补充缺失功能（统计图表、AI语音等）
   - Task #2535: 测试与发布准备

4. **真机测试**
   - 连接iPhone设备
   - 选择设备而不是模拟器
   - 构建并运行

---

## 获取帮助

如果遇到其他问题：

1. 查看Xcode的 **Report Navigator**（左侧栏第9个图标）查看详细错误日志
2. 检查 **Issue Navigator**（左侧栏第5个图标）查看编译警告和错误
3. 使用Xcode菜单 **Help → Search** 搜索错误消息
4. 查看项目文档：
   - `/Users/johnqiu/coding/www/projects/bblearning/docs/`
   - `/Users/johnqiu/coding/www/projects/bblearning/CLAUDE.md`

---

**最后更新**: 2025-10-15
**版本**: 1.0
**作者**: Claude Code
