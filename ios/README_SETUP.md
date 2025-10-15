# BBLearning iOS 开发环境配置指南

## 当前状态

✅ **已完成**:
- Xcode已安装 (`/Applications/Xcode.app`)
- Swift 6.1已可用
- iOS项目结构完整
- Fastlane配置已就绪

❌ **待完成**:
- Xcode命令行工具需要配置
- fastlane需要安装
- Swift Package依赖需要解析

---

## 快速开始

### 方式1: 使用自动化脚本 (推荐)

```bash
cd /Users/johnqiu/coding/www/projects/bblearning/ios
./setup_ios_env.sh
```

**这个脚本会:**
1. 配置Xcode命令行工具路径 (需要输入系统密码)
2. 使用bundler安装fastlane和依赖
3. 解析Swift Package依赖
4. 列出可用的模拟器和物理设备

---

### 方式2: 手动执行 (分步骤)

#### 步骤1: 配置Xcode命令行工具

```bash
# 设置Xcode路径 (需要输入密码)
sudo xcode-select -s /Applications/Xcode.app

# 验证配置
xcodebuild -version
# 应该显示: Xcode 版本号
```

#### 步骤2: 安装fastlane

```bash
cd /Users/johnqiu/coding/www/projects/bblearning/ios/BBLearning

# 使用bundler安装 (推荐)
sudo bundle install

# 验证安装
bundle exec fastlane --version
```

#### 步骤3: 解析Swift Package依赖

```bash
cd /Users/johnqiu/coding/www/projects/bblearning/ios/BBLearning

# 解析并下载Swift Package依赖
xcodebuild -resolvePackageDependencies -scheme BBLearning
```

#### 步骤4: 检查可用设备

```bash
# 查看iOS模拟器
xcrun simctl list devices available | grep iPhone

# 查看已连接的物理设备
instruments -s devices | grep -v "Simulator"
```

---

## 构建和安装

### 选项A: 安装到iOS模拟器 (无需证书)

```bash
cd /Users/johnqiu/coding/www/projects/bblearning/ios/BBLearning

# 构建开发版本
bundle exec fastlane build_dev

# 启动模拟器
open -a Simulator

# 在Xcode中运行
open BBLearning.xcodeproj
# 然后按 Cmd+R 运行
```

### 选项B: 安装到物理iPhone (需要证书)

**前提条件:**
- Apple Developer账号 (个人或企业)
- 已配置开发证书和Provisioning Profile
- iPhone已连接到Mac并信任此电脑

```bash
cd /Users/johnqiu/coding/www/projects/bblearning/ios/BBLearning

# 配置证书 (首次运行)
bundle exec fastlane match development

# 构建并安装到连接的设备
bundle exec fastlane beta
```

---

## 测试登录功能

安装完成后，使用以下测试账号登录:

**测试账号:**
- 用户名: `student2025`
- 密码: `Test123456`

**API地址:**
- 生产环境: `https://bblearning.joylodging.com/api/v1`

---

## 故障排除

### 问题1: `xcodebuild: error: tool requires Xcode`

**解决方案:**
```bash
sudo xcode-select -s /Applications/Xcode.app
```

### 问题2: `fastlane not found`

**解决方案:**
```bash
cd /Users/johnqiu/coding/www/projects/bblearning/ios/BBLearning
sudo bundle install
bundle exec fastlane --version
```

### 问题3: Swift Package依赖解析失败

**解决方案:**
```bash
# 清除缓存
rm -rf .swiftpm
rm Package.resolved

# 重新解析
xcodebuild -resolvePackageDependencies -scheme BBLearning
```

### 问题4: 证书问题 (物理设备安装)

**解决方案:**
1. 在Xcode中打开项目: `open BBLearning.xcodeproj`
2. 选择项目 → Signing & Capabilities
3. 取消勾选 "Automatically manage signing"
4. 选择正确的Team和Provisioning Profile
5. 重新构建

---

## 项目信息

- **项目路径**: `/Users/johnqiu/coding/www/projects/bblearning/ios/BBLearning`
- **Bundle ID**: `com.bblearning.app`
- **最低iOS版本**: iOS 15.0
- **Swift版本**: 5.9+
- **架构**: Clean Architecture + MVVM
- **UI框架**: SwiftUI

---

## 相关命令

```bash
# 查看fastlane可用命令
bundle exec fastlane lanes

# 运行单元测试
bundle exec fastlane test

# 构建开发版本
bundle exec fastlane build_dev

# 构建生产版本
bundle exec fastlane build_production

# 上传到TestFlight
bundle exec fastlane beta

# 查看项目设置
xcodebuild -project BBLearning.xcodeproj -showBuildSettings
```

---

## 下一步

完成环境配置后，请选择:

1. **模拟器测试** (推荐，快速测试):
   - 运行 `bundle exec fastlane build_dev`
   - 在Xcode中选择模拟器并运行

2. **物理设备测试** (真机体验):
   - 配置开发证书
   - 连接iPhone
   - 运行 `bundle exec fastlane beta`

---

**创建时间**: 2025-10-13
**相关任务**: ai-proj #2455
