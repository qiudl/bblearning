# BBLearning iOS

BBLearning iOS原生应用 - AI驱动的初中数学智能学习平台

## 项目概述

BBLearning是一个专为初中生（7-9年级）设计的数学学习应用，提供个性化学习路径、智能练习推荐和AI辅导功能。

### 主要功能

- 📚 **知识点学习**: 按年级和章节组织的知识树
- ✍️ **智能练习**: AI生成个性化题目，支持LaTeX数学公式
- 🤖 **AI辅导**: 智能对话辅导，拍照识题
- 📖 **错题本**: 自动收集错题，智能复习
- 📊 **学习报告**: 详细的学习数据分析和进度追踪
- 🔄 **离线支持**: 离线练习，自动同步

## 技术栈

- **UI框架**: SwiftUI (iOS 15+)
- **语言**: Swift 5.9+
- **架构**: Clean Architecture + MVVM
- **依赖管理**: Swift Package Manager
- **网络**: Alamofire + Combine
- **数据库**: Realm
- **依赖注入**: Swinject
- **安全存储**: KeychainAccess
- **图片缓存**: Nuke

## 项目结构

```
BBLearning/
├── BBLearning/              # 主应用
│   ├── App/                # 应用入口
│   ├── Core/               # 核心层（网络、存储、DI、工具）
│   ├── Domain/             # 领域层（实体、用例、仓储接口）
│   ├── Data/               # 数据层（仓储实现、API、本地存储）
│   ├── Presentation/       # 表示层（ViewModels、Views）
│   ├── Resources/          # 资源文件
│   └── Config/             # 配置文件
├── BBLearningTests/        # 单元测试
├── BBLearningUITests/      # UI测试
└── fastlane/               # 自动化脚本
```

## 开始使用

### 环境要求

- macOS 14.0+
- Xcode 15.2+
- iOS 15.0+
- Ruby 3.2+ (用于Fastlane)

### 安装依赖

```bash
# 1. 克隆项目
git clone https://github.com/yourusername/bblearning.git
cd bblearning/ios/BBLearning

# 2. 安装Ruby依赖
gem install bundler
bundle install

# 3. 解析Swift Package依赖
xcodebuild -resolvePackageDependencies

# 4. 打开Xcode项目
open BBLearning.xcodeproj
```

### 配置环境

1. 复制配置模板：
```bash
cp BBLearning/Config/Configuration.example.swift BBLearning/Config/Configuration.swift
```

2. 修改 `Configuration.swift` 中的API地址等配置

3. 配置开发者证书（Xcode > Signing & Capabilities）

### 运行项目

```bash
# 使用Xcode运行
# 或使用命令行：
xcodebuild -scheme BBLearning \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
  build
```

## 开发指南

### 代码规范

- 遵循[Swift官方代码风格指南](https://swift.org/documentation/api-design-guidelines/)
- 使用SwiftLint进行代码检查
- 所有公开API必须添加文档注释

### Git工作流

```bash
# 创建特性分支
git checkout -b feature/your-feature-name

# 提交代码
git add .
git commit -m "feat: your feature description"

# 推送并创建PR
git push origin feature/your-feature-name
```

### 测试

```bash
# 运行所有测试
fastlane test

# 运行单元测试
fastlane unit_test

# 运行UI测试
fastlane ui_test
```

### 构建

```bash
# 开发环境构建
fastlane build_dev

# Staging环境构建
fastlane build_staging

# 生产环境构建
fastlane build_production
```

## 发布流程

### TestFlight内测

```bash
# 上传到TestFlight
fastlane beta
```

### App Store发布

```bash
# 发布到App Store
fastlane release
```

## 架构设计

### Clean Architecture 分层

1. **Presentation Layer**:
   - SwiftUI Views
   - ViewModels (ObservableObject)
   - Navigation

2. **Domain Layer**:
   - Entities (业务实体)
   - Use Cases (业务逻辑)
   - Repository Protocols (仓储接口)

3. **Data Layer**:
   - Repository Implementations
   - API Services
   - Local Storage (Realm)

4. **Core Layer**:
   - Network Client
   - Storage Managers
   - Dependency Injection
   - Utilities

### 数据流

```
View → ViewModel → UseCase → Repository → API/Local Storage
         ↓
    @Published State
```

## API文档

API基础地址:
- 开发环境: `http://localhost:8080/api/v1`
- 生产环境: `https://api.bblearning.com/api/v1`

详细API文档请参考: [API Specification](../../docs/architecture/api-specification.md)

## 性能优化

- 使用LazyVStack进行列表优化
- 图片使用Nuke进行缓存
- 网络请求使用Combine进行响应式处理
- Realm数据库使用异步操作

## 安全措施

- JWT Token认证
- Keychain存储敏感信息
- SSL Pinning（生产环境）
- 数据加密（AES-256）

## 故障排查

### 常见问题

1. **构建失败**
   - 检查Xcode版本
   - 清理DerivedData: `fastlane clean`
   - 重新解析依赖

2. **证书问题**
   - 运行 `fastlane setup_signing`
   - 检查开发者账号状态

3. **测试失败**
   - 检查模拟器状态
   - 重启Xcode

## 贡献指南

1. Fork项目
2. 创建特性分支
3. 提交代码
4. 推送到分支
5. 创建Pull Request

## 许可证

本项目仅供个人学习使用。

## 联系方式

- 项目地址: https://github.com/yourusername/bblearning
- 问题反馈: https://github.com/yourusername/bblearning/issues

---

**版本**: 1.0.0
**最后更新**: 2025-10-13
**维护者**: Claude Code AI Assistant
