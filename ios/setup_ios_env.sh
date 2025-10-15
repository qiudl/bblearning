#!/bin/bash

# BBLearning iOS开发环境配置脚本
# 用途: 配置Xcode、安装fastlane、准备iOS开发环境

set -e

echo "=========================================="
echo "BBLearning iOS 环境配置"
echo "=========================================="
echo ""

# 1. 配置Xcode命令行工具
echo "📱 步骤1: 配置Xcode命令行工具..."
if [ -d "/Applications/Xcode.app" ]; then
    echo "  ✅ Xcode已安装"
    sudo xcode-select -s /Applications/Xcode.app
    echo "  ✅ Xcode路径已设置"

    # 验证Xcode版本
    xcodebuild -version
else
    echo "  ❌ 错误: 未找到Xcode，请从App Store安装"
    exit 1
fi

echo ""

# 2. 安装fastlane
echo "🚀 步骤2: 安装fastlane..."
cd /Users/johnqiu/coding/www/projects/bblearning/ios/BBLearning

if [ -f "Gemfile" ]; then
    echo "  📦 使用Bundler安装fastlane..."
    bundle install
    echo "  ✅ fastlane安装完成"
else
    echo "  📦 使用gem安装fastlane..."
    gem install fastlane
    echo "  ✅ fastlane安装完成"
fi

echo ""

# 3. 解析Swift Package依赖
echo "📦 步骤3: 解析Swift Package依赖..."
xcodebuild -resolvePackageDependencies -scheme BBLearning
echo "  ✅ Swift Package依赖解析完成"

echo ""

# 4. 检查可用设备
echo "📱 步骤4: 检查可用设备..."
echo "  模拟器列表:"
xcrun simctl list devices available | grep "iPhone"
echo ""
echo "  物理设备列表:"
instruments -s devices | grep -v "Simulator" | grep "iPhone"

echo ""
echo "=========================================="
echo "✅ iOS开发环境配置完成！"
echo "=========================================="
echo ""
echo "下一步操作:"
echo "  1. 如果要使用模拟器测试:"
echo "     cd /Users/johnqiu/coding/www/projects/bblearning/ios/BBLearning"
echo "     fastlane build_dev"
echo "     open -a Simulator"
echo ""
echo "  2. 如果要安装到物理设备:"
echo "     - 连接iPhone到Mac"
echo "     - 运行: fastlane beta (需要配置证书)"
echo ""
