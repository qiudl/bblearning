#!/bin/bash

# BBLearning iOS应用安装脚本
# 用途: 安装iOS应用到模拟器和真实设备

set -e

echo "=========================================="
echo "BBLearning iOS 应用安装"
echo "=========================================="
echo ""

# 切换到项目目录
cd /Users/johnqiu/coding/www/projects/bblearning/ios/BBLearning

# 1. 检查fastlane是否已安装
echo "📦 步骤1: 检查fastlane..."
if command -v fastlane &> /dev/null; then
    echo "  ✅ fastlane已安装"
    fastlane --version
elif [ -f "Gemfile" ] && bundle exec fastlane --version &> /dev/null; then
    echo "  ✅ fastlane已安装 (via bundler)"
    FASTLANE_CMD="bundle exec fastlane"
else
    echo "  ❌ fastlane未安装，尝试使用bundler安装到用户目录..."
    bundle config set --local path 'vendor/bundle'
    bundle install
    FASTLANE_CMD="bundle exec fastlane"
fi

# 设置fastlane命令
FASTLANE_CMD=${FASTLANE_CMD:-"fastlane"}

echo ""

# 2. 检查可用的iOS模拟器
echo "📱 步骤2: 检查iOS模拟器..."
echo "  可用的iPhone模拟器:"
xcrun simctl list devices available | grep "iPhone" | head -5

echo ""

# 3. 启动iOS模拟器
echo "🚀 步骤3: 启动iOS模拟器..."
# 获取最新的iPhone模拟器
SIMULATOR_ID=$(xcrun simctl list devices available | grep "iPhone" | head -1 | grep -o '[0-9A-F-]\{36\}' | head -1)
if [ -n "$SIMULATOR_ID" ]; then
    echo "  启动模拟器: $SIMULATOR_ID"
    xcrun simctl boot "$SIMULATOR_ID" 2>/dev/null || echo "  模拟器可能已经在运行"
    open -a Simulator
    sleep 3
else
    echo "  ⚠️  未找到可用的模拟器"
fi

echo ""

# 4. 构建并安装到模拟器
echo "🔨 步骤4: 构建应用..."
echo "  这可能需要几分钟时间..."

# 使用xcodebuild直接构建
xcodebuild \
    -scheme BBLearning \
    -destination "platform=iOS Simulator,name=iPhone 15" \
    -configuration Debug \
    build

echo "  ✅ 构建完成"

echo ""

# 5. 安装到模拟器
echo "📲 步骤5: 安装到模拟器..."
# 查找构建产物
BUILD_DIR=$(find ~/Library/Developer/Xcode/DerivedData -name "BBLearning.app" -type d | head -1)
if [ -n "$BUILD_DIR" ]; then
    echo "  找到应用: $BUILD_DIR"
    xcrun simctl install booted "$BUILD_DIR"
    echo "  ✅ 已安装到模拟器"

    # 获取Bundle ID并启动应用
    BUNDLE_ID=$(defaults read "$BUILD_DIR/Info.plist" CFBundleIdentifier)
    xcrun simctl launch booted "$BUNDLE_ID"
    echo "  ✅ 应用已启动"
else
    echo "  ⚠️  未找到构建产物，使用Xcode打开项目"
    open BBLearning.xcodeproj
fi

echo ""

# 6. 检查物理设备
echo "📱 步骤6: 检查物理设备..."
DEVICES=$(instruments -s devices | grep -v "Simulator" | grep "iPhone")
if [ -n "$DEVICES" ]; then
    echo "  找到连接的设备:"
    echo "$DEVICES"
    echo ""
    echo "  ⚠️  安装到物理设备需要开发者证书"
    echo "  如需安装，请在Xcode中:"
    echo "  1. 打开项目: open BBLearning.xcodeproj"
    echo "  2. 选择您的设备"
    echo "  3. 点击运行按钮 (Cmd+R)"
else
    echo "  ⚠️  未检测到连接的物理设备"
    echo "  如需在真机测试，请:"
    echo "  1. 用USB连接iPhone到Mac"
    echo "  2. 在iPhone上信任此电脑"
    echo "  3. 重新运行此脚本"
fi

echo ""
echo "=========================================="
echo "✅ 模拟器安装完成！"
echo "=========================================="
echo ""
echo "测试账号:"
echo "  用户名: student2025"
echo "  密码: Test123456"
echo ""
echo "API地址: https://bblearning.joylodging.com/api/v1"
echo ""
