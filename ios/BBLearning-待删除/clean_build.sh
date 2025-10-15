#!/bin/bash

echo "🧹 清理 BBLearning iOS 项目构建缓存..."

# 1. 关闭 Xcode
echo "正在关闭 Xcode..."
killall Xcode 2>/dev/null && sleep 2

# 2. 清理 DerivedData
echo "清理 DerivedData..."
rm -rf ~/Library/Developer/Xcode/DerivedData/BBLearning-*

# 3. 清理 Swift PM 缓存
echo "清理 Swift Package Manager 缓存..."
cd "$(dirname "$0")"
rm -rf .build .swiftpm

# 4. 清理 Package.resolved
echo "清理 Package.resolved..."
rm -f Package.resolved

# 5. 重新打开项目
echo "✅ 清理完成！正在重新打开项目..."
open Package.swift

echo ""
echo "📱 请在 Xcode 中执行以下步骤："
echo "   1. 等待依赖包下载完成"
echo "   2. 在顶部选择 iOS Simulator (如 iPhone 15 Pro)"
echo "   3. Product → Clean Build Folder (⇧⌘K)"
echo "   4. Product → Build (⌘B)"
echo ""
