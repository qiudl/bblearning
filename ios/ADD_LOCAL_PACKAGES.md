# 在Xcode中添加本地Swift Package依赖

## 包位置

所有依赖包已下载到：
```
/Users/johnqiu/coding/www/projects/bblearning/ios/SwiftPackages/
```

包含以下6个包：
- ✅ Alamofire (v5.9.1)
- ✅ KeychainAccess (v4.2.2)
- ✅ Nuke (v12.8.0)
- ✅ Swinject (v2.8.4)
- ✅ realm-swift (v10.53.1)
- ✅ swift-log (v1.6.1)

---

## 添加步骤

### 方法1: 通过Xcode界面添加（推荐）

#### 1. 打开项目
```bash
open ~/coding/www/projects/bblearning/ios/BBLearningApp/BBLearningApp.xcodeproj
```

#### 2. 添加第一个包：Alamofire

1. 在Xcode菜单栏，选择 **File → Add Package Dependencies...**
2. 在弹出的窗口左下角，点击 **Add Local...** 按钮
3. 导航到 `/Users/johnqiu/coding/www/projects/bblearning/ios/SwiftPackages/Alamofire`
4. 选择 `Alamofire` 文件夹，点击 **Add Package**
5. 在弹出的 "Choose Package Products" 窗口：
   - 确保 `Alamofire` 被勾选
   - Target选择 `BBLearningApp`
   - 点击 **Add Package**

#### 3. 添加第二个包：Realm Swift

1. 重复上述步骤，选择路径 `SwiftPackages/realm-swift`
2. **重要**: 在 "Choose Package Products" 窗口中，需要添加两个product：
   - ✅ 勾选 `Realm`
   - ✅ 勾选 `RealmSwift`
   - Target都选择 `BBLearningApp`
3. 点击 **Add Package**

#### 4. 添加第三个包：Swinject

1. 选择路径 `SwiftPackages/Swinject`
2. 确保勾选 `Swinject`
3. 点击 **Add Package**

#### 5. 添加第四个包：KeychainAccess

1. 选择路径 `SwiftPackages/KeychainAccess`
2. 确保勾选 `KeychainAccess`
3. 点击 **Add Package**

#### 6. 添加第五个包：Nuke

1. 选择路径 `SwiftPackages/Nuke`
2. 确保勾选 `Nuke`（可能还有NukeUI等，根据需要选择）
3. 点击 **Add Package**

#### 7. 添加第六个包：swift-log

1. 选择路径 `SwiftPackages/swift-log`
2. 确保勾选 `Logging`
3. 点击 **Add Package**

---

### 方法2: 手动修改项目文件（备选）

如果方法1遇到问题，可以手动编辑项目文件：

1. 关闭Xcode
2. 使用文本编辑器打开 `BBLearningApp.xcodeproj/project.pbxproj`
3. 在文件中添加本地包引用

**注意**: 这个方法比较复杂，建议优先使用方法1。

---

## 验证安装

### 1. 检查Package Dependencies

在Xcode左侧导航栏（Project Navigator），应该能看到：

```
BBLearningApp
├── BBLearningApp (项目文件)
├── Package Dependencies (新增)
    ├── alamofire (本地)
    ├── keychainaccess (本地)
    ├── nuke (本地)
    ├── realm (本地)
    ├── swinject (本地)
    └── swift-log (本地)
```

### 2. 检查Build Phases

1. 选择项目根节点 `BBLearningApp`
2. 选择Target `BBLearningApp`
3. 切换到 **Build Phases** 标签
4. 展开 **Link Binary With Libraries**
5. 应该能看到以下库：
   - Alamofire
   - Realm
   - RealmSwift
   - Swinject
   - KeychainAccess
   - Nuke
   - Logging

### 3. 测试导入

创建一个测试文件或在现有文件中尝试导入：

```swift
import Alamofire
import RealmSwift
import Swinject
import KeychainAccess
import Nuke
import Logging
```

如果没有错误提示，说明安装成功！

---

## 常见问题

### 问题1: 找不到Package.swift

**症状**:
```
The package at '/path/to/package' doesn't contain a Package.swift manifest
```

**解决方案**:
确保选择的是包含 `Package.swift` 文件的文件夹。检查：
```bash
ls ~/coding/www/projects/bblearning/ios/SwiftPackages/Alamofire/Package.swift
```

如果文件存在，尝试重新克隆包。

### 问题2: Xcode无法解析本地包

**解决方案**:
1. 在Xcode菜单，选择 **File → Packages → Reset Package Caches**
2. 清理构建文件夹：**Product → Clean Build Folder** (`Shift + Cmd + K`)
3. 重启Xcode

### 问题3: Build失败，提示找不到模块

**症状**:
```
No such module 'Alamofire'
```

**解决方案**:
1. 检查 **Build Phases → Link Binary With Libraries** 是否包含该库
2. 检查 **General → Frameworks, Libraries, and Embedded Content**
3. 尝试手动添加：
   - 点击 `+` 按钮
   - 选择对应的框架

### 问题4: Realm相关错误

**症状**:
```
Could not find module 'Realm' for target 'arm64-apple-ios'
```

**解决方案**:
Realm需要同时添加 `Realm` 和 `RealmSwift` 两个product。确保在添加realm-swift包时，两个都勾选了。

---

## 构建和运行

### 第1步: 清理和构建

```
1. Product → Clean Build Folder (Shift + Cmd + K)
2. Product → Build (Cmd + B)
```

### 第2步: 查看构建输出

- 如果构建成功，继续下一步
- 如果有错误，查看错误信息并解决

### 第3步: 运行项目

1. 选择模拟器（推荐 iPhone 15 Pro）
2. 点击 Run 按钮 或按 `Cmd + R`

---

## 依赖说明

### Alamofire
- **用途**: HTTP网络请求
- **使用位置**:
  - `Core/Network/APIClient.swift`
  - `Data/Repositories/*.swift`

### Realm Swift
- **用途**: 本地数据库
- **使用位置**:
  - `Core/Storage/RealmManager.swift`
  - 离线数据缓存

### Swinject
- **用途**: 依赖注入容器
- **使用位置**:
  - `Core/DI/DIContainer.swift`
  - 管理所有依赖关系

### KeychainAccess
- **用途**: 安全存储敏感数据
- **使用位置**:
  - `Core/Storage/KeychainManager.swift`
  - 存储JWT Token、用户凭证

### Nuke
- **用途**: 异步图片加载和缓存
- **使用位置**:
  - 题目图片加载
  - 用户头像显示

### swift-log
- **用途**: 结构化日志记录
- **使用位置**:
  - `Core/Utils/Logger.swift`
  - 应用各处的日志输出

---

## 下一步

完成包添加后：

1. ✅ 验证所有包都已正确添加
2. ✅ 清理并构建项目
3. ✅ 解决任何编译错误
4. ✅ 在模拟器上运行测试

如果遇到编译错误，请查看错误信息并参考：
- `PRE_COMPILATION_FIXES.md` - 已知问题和修复
- `XCODE_SETUP_GUIDE.md` - 完整设置指南

---

**创建时间**: 2025-10-15
**包下载位置**: `/Users/johnqiu/coding/www/projects/bblearning/ios/SwiftPackages/`
**项目位置**: `/Users/johnqiu/coding/www/projects/bblearning/ios/BBLearningApp/`
