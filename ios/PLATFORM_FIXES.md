# iOS 平台特定修复记录

## 修复日期
2025-10-13

## 问题概述

在构建 iOS 项目时遇到了跨平台编译问题，主要是由于 SPM (Swift Package Manager) 尝试同时为 iOS 和 macOS 构建，但代码中使用了 UIKit 等 iOS 特定的 API。

## 根本原因

1. **Package.swift 配置问题**: 初始配置包含了 macOS 平台支持
2. **UIKit 依赖**: 多个文件使用 UIKit API 但没有条件编译保护
3. **API 错误类型错误**: 使用了不存在的 `APIError.parameterError`

## 已修复的文件

### 1. Package.swift
**问题**: 包含 macOS 平台导致 Nuke 等依赖要求 macOS 10.15+
**修复**: 移除 macOS 平台支持，只保留 iOS
```swift
// Before
platforms: [
    .iOS(.v15),
    .macOS(.v10_15)
]

// After
platforms: [
    .iOS(.v15)
]
```

### 2. ImagePicker.swift
**问题**: 整个文件使用 UIKit，在 macOS 上无法编译
**修复**: 使用条件编译包装整个文件
```swift
#if canImport(UIKit)
import SwiftUI
import UIKit

// ... 所有内容 ...

#endif
```

### 3. AITutorViewModel.swift
**问题**: 使用 UIImage 类型
**修复**: 使用条件编译包装 UIKit 相关代码
```swift
#if canImport(UIKit)
import UIKit
#endif

#if canImport(UIKit)
@Published var selectedImage: UIImage?
#endif

#if canImport(UIKit)
func processSelectedImage(_ image: UIImage) { ... }
#endif
```

### 4. BBLearningApp.swift
**问题**: 使用 UINavigationBarAppearance, UITabBarAppearance 等 UIKit API
**修复**: 添加条件编译
```swift
#if canImport(UIKit)
import UIKit
#endif

private func setupAppearance() {
    #if canImport(UIKit)
    // UIKit appearance configuration
    #endif
}
```

### 5. View+Extension.swift
**问题**: 使用 UIApplication, UIResponder, UIRectCorner, UIBezierPath
**修复**: 添加 UIKit 导入和条件编译
```swift
#if canImport(UIKit)
import UIKit
#endif

#if canImport(UIKit)
func dismissKeyboardOnTap() -> some View { ... }
func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View { ... }
#endif

#if canImport(UIKit)
struct RoundedCorner: Shape { ... }
#endif
```

### 6. GetKnowledgeTreeUseCase.swift
**问题**: 使用了不存在的 `APIError.parameterError`
**修复**: 替换为 `APIError.badRequest(message:)`
```swift
// Before
return Fail(error: APIError.parameterError("年级设置错误"))

// After
return Fail(error: APIError.badRequest(message: "年级设置错误"))
```

### 7. 批量修复 UseCases (15处)
**问题**: 多个 UseCase 文件使用 `APIError.parameterError`
**修复**: 批量替换为 `APIError.badRequest(message:)`

**受影响的文件**:
- RegisterUseCase.swift (6处)
- LoginUseCase.swift (2处)
- SubmitAnswerUseCase.swift (2处)
- GenerateQuestionsUseCase.swift (3处)
- ChatWithAIUseCase.swift (2处)
- GetKnowledgeTreeUseCase.swift (2处)

**批量修复命令**:
```bash
find BBLearning/Domain/UseCases -name "*.swift" -type f \
  -exec sed -i '' 's/APIError\.parameterError(/APIError.badRequest(message: /g' {} \;
```

## 修复策略

### 条件编译模式
使用 `#if canImport(UIKit)` 而不是 `#if os(iOS)` 的原因：
- 更灵活，可以处理 Mac Catalyst 等特殊情况
- 基于能力检测而不是平台检测
- 更符合 Swift 的最佳实践

### UIKit 相关代码的处理原则
1. **完全 UIKit 依赖的文件**: 整个文件包装在 `#if canImport(UIKit)` 中
2. **部分 UIKit 依赖**: 只包装使用 UIKit 的部分
3. **类型引用**: 使用条件编译的属性和方法

## 清理步骤

为确保修复生效，执行了以下清理：

```bash
# 1. 删除 SPM 生成的 Xcode 项目
rm -rf .swiftpm/xcode

# 2. 删除构建产物
rm -rf .build

# 3. 清理 Xcode DerivedData
rm -rf ~/Library/Developer/Xcode/DerivedData/BBLearning-*
```

## 构建验证步骤

1. **关闭 Xcode**
2. **重新打开项目**:
   ```bash
   open Package.swift
   ```
3. **等待依赖解析完成**
4. **选择正确的构建目标**: "BBLearning > iPhone 16 Plus"
5. **清理构建文件夹**: Shift+Cmd+K
6. **重新构建**: Cmd+B

## APIError 标准化

### 正确的错误类型
```swift
enum APIError: Error {
    case networkError(Error)
    case decodingError(Error)
    case encodingError(Error)
    case unauthorized
    case forbidden
    case notFound
    case serverError(Int, String)
    case badRequest(String)      // ✅ 正确：用于参数错误
    case timeout
    case noConnection
    case unknown
}
```

### 使用规范
```swift
// ✅ 正确
APIError.badRequest(message: "参数错误")

// ❌ 错误（不存在）
APIError.parameterError("参数错误")
```

## 验证清单

- [x] Package.swift 只包含 iOS 平台
- [x] 所有 UIKit 使用都有条件编译保护
- [x] 不存在 `APIError.parameterError` 引用
- [x] 清理了所有构建缓存
- [x] Xcode 选择 iOS 构建目标
- [ ] 项目成功编译（等待用户验证）
- [ ] 在模拟器上运行测试
- [ ] 在真机上运行测试

## 后续建议

1. **持续集成**: 添加 CI 配置确保只为 iOS 构建
2. **代码规范**: 建立 UIKit 使用的代码审查清单
3. **错误处理**: 统一使用 APIError 的标准错误类型
4. **测试覆盖**: 为 UseCases 添加单元测试，验证错误处理逻辑

## 潜在风险

1. **Mac Catalyst**: 如果将来需要支持 Mac Catalyst，需要重新评估条件编译策略
2. **第三方库**: 某些依赖可能仍然要求 macOS 平台，需要逐案处理
3. **SwiftUI 跨平台**: 某些 SwiftUI API 在不同平台上行为可能不同

## 技术债务

1. **过度使用条件编译**: 当前方案使用了大量 `#if canImport(UIKit)`，可以考虑创建平台抽象层
2. **错误类型迁移**: 已有代码可能还在使用旧的错误处理模式，需要逐步迁移
3. **测试覆盖不足**: 修复后的代码缺少自动化测试验证

## 参考资料

- [Swift Evolution - Conditional Compilation](https://github.com/apple/swift-evolution/blob/main/proposals/0075-import-test.md)
- [Apple Documentation - Conditional Compilation](https://docs.swift.org/swift-book/ReferenceManual/Statements.html#ID538)
- [Swift Package Manager - Platform Deployment](https://docs.swift.org/package-manager/PackageDescription/PackageDescription.html#platform)

---

**修复完成时间**: 2025-10-13
**修复人**: Claude Code
**项目**: BBLearning iOS
