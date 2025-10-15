#!/bin/bash

# BBLearning iOS 应用安装脚本
# 用于将应用安装到连接的 iPhone 设备

set -e

echo "🚀 BBLearning iOS 安装脚本"
echo "================================"

# 项目路径
PROJECT_DIR="/Users/johnqiu/coding/www/projects/bblearning/ios/BBLearning"
PROJECT_NAME="BBLearning"
SCHEME="BBLearning"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 检查是否在正确的目录 (Swift Package Manager project)
if [ ! -f "$PROJECT_DIR/Package.swift" ]; then
    echo -e "${RED}❌ 错误: 找不到项目文件${NC}"
    echo "请确保项目路径正确: $PROJECT_DIR"
    echo "预期找到: $PROJECT_DIR/Package.swift"
    exit 1
fi

cd "$PROJECT_DIR"

# 检查设备连接
echo ""
echo "📱 检查连接的 iOS 设备..."
DEVICE_COUNT=$(xcrun xctrace list devices 2>&1 | grep -c "iPhone" || echo "0")

if [ "$DEVICE_COUNT" -eq "0" ]; then
    echo -e "${RED}❌ 未检测到连接的 iPhone 设备${NC}"
    echo "请确保："
    echo "  1. iPhone 已通过 USB 连接到 Mac"
    echo "  2. iPhone 已解锁"
    echo "  3. 已在 iPhone 上信任此电脑"
    exit 1
fi

echo -e "${GREEN}✅ 检测到 $DEVICE_COUNT 个 iOS 设备${NC}"

# 显示连接的设备
echo ""
echo "连接的设备列表："
xcrun xctrace list devices 2>&1 | grep "iPhone" | head -n 5

# 选择构建配置
echo ""
echo "请选择构建配置："
echo "  1) Debug（开发调试）"
echo "  2) Release（正式版本）"
read -p "请输入选项 (1 或 2, 默认 1): " config_choice
config_choice=${config_choice:-1}

if [ "$config_choice" == "2" ]; then
    CONFIGURATION="Release"
    echo -e "${YELLOW}📦 使用 Release 配置${NC}"
else
    CONFIGURATION="Debug"
    echo -e "${YELLOW}📦 使用 Debug 配置${NC}"
fi

# 清理之前的构建（可选）
read -p "是否清理之前的构建？(y/N): " clean_choice
if [ "$clean_choice" == "y" ] || [ "$clean_choice" == "Y" ]; then
    echo "🧹 清理构建缓存..."
    swift package clean
    rm -rf .build
fi

# 为 SPM 项目生成 Xcode project
echo ""
echo "📦 生成 Xcode 项目..."
swift package generate-xcodeproj 2>/dev/null || echo "已存在 Xcode 项目或使用 Xcode 打开"

# 构建并安装
echo ""
echo "🔨 开始构建和安装..."
echo "配置: $CONFIGURATION"
echo "设备: 连接的 iPhone"
echo ""

# 检查是否存在生成的 xcodeproj
if [ -d "$PROJECT_NAME.xcodeproj" ]; then
    echo "使用生成的 Xcode 项目构建..."
    xcodebuild -project "$PROJECT_NAME.xcodeproj" \
        -scheme "$SCHEME" \
        -configuration "$CONFIGURATION" \
        -destination 'generic/platform=iOS' \
        -allowProvisioningUpdates \
        CODE_SIGN_STYLE=Automatic \
        | xcpretty 2>/dev/null || xcodebuild -project "$PROJECT_NAME.xcodeproj" \
        -scheme "$SCHEME" \
        -configuration "$CONFIGURATION" \
        -destination 'generic/platform=iOS' \
        -allowProvisioningUpdates
else
    echo -e "${YELLOW}⚠️  需要在 Xcode 中打开项目${NC}"
    echo ""
    echo "请按照以下步骤操作："
    echo "  1. 打开 Xcode"
    echo "  2. 打开文件: $PROJECT_DIR/Package.swift"
    echo "  3. 选择你的 iPhone 设备作为目标"
    echo "  4. 点击 ▶️ 运行按钮 (Cmd+R)"
    echo ""
    exit 0
fi

echo ""
echo -e "${GREEN}✅ 构建成功！${NC}"

# 尝试直接运行到设备（需要 Xcode）
echo ""
read -p "是否立即安装到设备？(Y/n): " install_choice
install_choice=${install_choice:-Y}

if [ "$install_choice" == "y" ] || [ "$install_choice" == "Y" ]; then
    echo "📲 安装应用到设备..."

    # 方式1: 使用 ios-deploy（如果安装）
    if command -v ios-deploy &> /dev/null; then
        APP_PATH="build/Build/Products/$CONFIGURATION-iphoneos/$PROJECT_NAME.app"
        if [ -d "$APP_PATH" ]; then
            ios-deploy --bundle "$APP_PATH" --debug --no-wifi
        else
            echo -e "${YELLOW}⚠️  找不到 .app 文件，请使用 Xcode 手动安装${NC}"
        fi
    else
        # 方式2: 提示使用 Xcode
        echo -e "${YELLOW}ℹ️  未安装 ios-deploy${NC}"
        echo ""
        echo "请在 Xcode 中完成安装："
        echo "  1. 打开 Xcode"
        echo "  2. 选择你的 iPhone 设备"
        echo "  3. 点击 ▶️ 运行按钮 (Cmd+R)"
        echo ""
        echo "或安装 ios-deploy："
        echo "  brew install ios-deploy"
    fi
fi

echo ""
echo "📝 首次安装提醒："
echo "  如果这是首次在此设备上安装，需要在 iPhone 上信任开发者："
echo "  设置 → 通用 → VPN与设备管理 → 开发者应用 → 信任"
echo ""
echo -e "${GREEN}🎉 完成！${NC}"
