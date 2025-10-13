# iOS项目开发设置指南

本文档说明如何在macOS上设置和开发BBLearning iOS应用。

## 系统要求

- **macOS**: 14.0 (Sonoma) 或更高版本
- **Xcode**: 15.2 或更高版本
- **iOS SDK**: iOS 15.0+
- **Ruby**: 3.2+ (用于Fastlane)
- **Git**: 2.30+

## 初次设置

### 1. 安装Xcode

```bash
# 从Mac App Store安装Xcode
# 或使用命令行工具
xcode-select --install
```

### 2. 安装Homebrew（如果尚未安装）

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

### 3. 安装必要工具

```bash
# 安装SwiftLint
brew install swiftlint

# 安装Ruby（如果系统版本过低）
brew install ruby

# 安装Fastlane
gem install fastlane

# 安装Bundler
gem install bundler
```

### 4. 克隆项目

```bash
cd ~/coding/www/projects/bblearning
cd ios/BBLearning
```

### 5. 安装项目依赖

```bash
# 安装Ruby依赖
bundle install

# 解析Swift Package Manager依赖
# 这将在第一次打开Xcode时自动完成
# 或手动运行：
xcodebuild -resolvePackageDependencies
```

## 项目配置

### 1. 配置Apple Developer账号

1. 打开Xcode
2. 进入 **Xcode > Preferences > Accounts**
3. 点击 **+** 添加Apple ID
4. 登录你的开发者账号

### 2. 配置Signing

目前项目采用手动签名方式（用于个人开发）：

1. 在Xcode中打开 `BBLearning.xcodeproj`
2. 选择BBLearning target
3. 进入 **Signing & Capabilities** 标签
4. 取消勾选 **Automatically manage signing**
5. 选择你的开发Team
6. 选择对应的Provisioning Profile

### 3. 配置环境变量

创建本地配置文件（不要提交到Git）：

```bash
# 在项目根目录创建 .env 文件
cat > .env << EOF
FASTLANE_USER=your-apple-id@example.com
FASTLANE_TEAM_ID=YOUR_TEAM_ID
MATCH_PASSWORD=your-match-password
EOF
```

## 开发流程

### 运行项目

**方式1: 使用Xcode**
1. 打开 `BBLearning.xcodeproj`
2. 选择模拟器设备（推荐：iPhone 15 Pro）
3. 点击运行按钮 (⌘+R)

**方式2: 使用命令行**
```bash
xcodebuild -scheme BBLearning \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
  -configuration Debug \
  build
```

### 运行测试

```bash
# 使用Fastlane
fastlane test

# 或使用xcodebuild
xcodebuild test \
  -scheme BBLearning \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro'
```

### 代码格式化

项目使用SwiftLint进行代码检查：

```bash
# 检查代码
swiftlint

# 自动修复
swiftlint --fix
```

### Git工作流

```bash
# 创建功能分支
git checkout -b feature/your-feature

# 提交代码
git add .
git commit -m "feat: add your feature"

# 推送到远程
git push origin feature/your-feature
```

## 真机调试

### 准备工作

1. **注册设备UDID**
   - 连接iPhone到Mac
   - 打开Xcode > Window > Devices and Simulators
   - 复制设备的Identifier
   - 在Apple Developer网站添加设备

2. **创建Development Provisioning Profile**
   - 访问 [Apple Developer](https://developer.apple.com/account/resources/profiles/list)
   - 创建iOS App Development类型的Profile
   - 选择App ID、证书和设备
   - 下载并双击安装

3. **配置Xcode**
   - 选择真机设备
   - 确认Signing配置正确
   - 运行项目 (⌘+R)

### 信任开发者证书

首次运行时，需要在设备上信任开发者：
1. 打开 **设置 > 通用 > VPN与设备管理**
2. 点击你的开发者账号
3. 点击 **信任**

## TestFlight测试

### 上传构建版本

```bash
# 确保在main分支
git checkout main

# 运行Fastlane命令
fastlane beta
```

这将：
1. 增加build number
2. 构建应用
3. 上传到App Store Connect
4. 创建Git tag
5. 提交版本号变更

### 添加测试用户

1. 访问 [App Store Connect](https://appstoreconnect.apple.com)
2. 进入 **TestFlight** 标签
3. 添加内部测试员（家庭成员）
4. 等待构建版本通过审核
5. 测试员将收到邮件邀请

## 故障排查

### 问题1: 依赖解析失败

```bash
# 清理并重新解析
rm -rf .build
rm -rf DerivedData
xcodebuild -resolvePackageDependencies
```

### 问题2: 模拟器启动失败

```bash
# 重置模拟器
xcrun simctl shutdown all
xcrun simctl erase all
```

### 问题3: 证书或签名问题

```bash
# 清理钥匙串中的旧证书
# 打开钥匙串访问 > 登录 > 我的证书
# 删除过期的证书

# 重新设置签名
fastlane setup_signing
```

### 问题4: Xcode构建缓存问题

```bash
# 清理构建缓存
fastlane clean

# 或手动清理
rm -rf ~/Library/Developer/Xcode/DerivedData
rm -rf ~/Library/Caches/org.swift.swiftpm
```

### 问题5: SwiftLint警告过多

临时禁用某些规则：
```swift
// swiftlint:disable rule_name
// your code
// swiftlint:enable rule_name
```

## 性能分析

### Instruments工具

1. Product > Profile (⌘+I)
2. 选择分析模板：
   - **Time Profiler**: CPU使用分析
   - **Allocations**: 内存分配分析
   - **Leaks**: 内存泄漏检测
   - **Network**: 网络请求分析

### SwiftUI预览

使用SwiftUI的实时预览功能：
```swift
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .previewDevice("iPhone 15 Pro")
            .preferredColorScheme(.light)
    }
}
```

## 最佳实践

### 1. 代码组织

- 遵循Clean Architecture分层
- 每个文件只包含一个主要类型
- 使用MARK注释分隔代码区域

### 2. SwiftUI开发

- 保持View body简洁
- 将复杂逻辑移到ViewModel
- 使用@StateObject和@ObservedObject正确管理状态
- 使用LazyVStack优化列表性能

### 3. 网络请求

- 始终使用Combine进行异步处理
- 在ViewModel中处理网络错误
- 实现请求取消机制
- 使用Repository模式隔离网络层

### 4. 数据持久化

- 使用Realm进行本地存储
- 实现离线模式
- 定期清理过期缓存
- 敏感数据使用Keychain

### 5. 测试

- 单元测试覆盖率 > 80%
- 为每个ViewModel编写测试
- 使用Mock对象隔离依赖
- UI测试覆盖关键用户流程

## 有用的资源

### 官方文档

- [Swift官方文档](https://swift.org/documentation/)
- [SwiftUI教程](https://developer.apple.com/tutorials/swiftui)
- [Xcode文档](https://developer.apple.com/documentation/xcode)

### 第三方库文档

- [Alamofire](https://github.com/Alamofire/Alamofire)
- [Realm Swift](https://realm.io/docs/swift/latest/)
- [Swinject](https://github.com/Swinject/Swinject)
- [Fastlane](https://docs.fastlane.tools/)

### 学习资源

- [Hacking with Swift](https://www.hackingwithswift.com/)
- [Ray Wenderlich](https://www.raywenderlich.com/)
- [Apple Developer Forums](https://developer.apple.com/forums/)

## 获取帮助

如果遇到问题：

1. 查看本文档的故障排查部分
2. 搜索项目的Issue列表
3. 查阅相关库的官方文档
4. 在项目中创建新Issue

---

**最后更新**: 2025-10-13
**维护者**: Claude Code AI Assistant
