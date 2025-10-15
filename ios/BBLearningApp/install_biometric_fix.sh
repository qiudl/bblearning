#!/bin/bash

echo "==========================================
========== BBLearningApp 安装脚本 =========="
echo "=========================================="
echo ""

# App路径
APP_PATH="/Users/johnqiu/Library/Developer/Xcode/DerivedData/BBLearningApp-eialpytihrjtwgahcswjdvoymgdb/Build/Products/Debug-iphoneos/BBLearningApp.app"

echo "📱 检查设备连接..."
xcrun devicectl list devices

echo ""
echo "⚠️  如果设备显示为'unavailable'，请确保："
echo "   1. iPhone已解锁"
echo "   2. iPhone已点击'信任此电脑'"
echo "   3. USB连接正常"
echo ""

# 获取第一个可用设备
DEVICE_ID=$(xcrun devicectl list devices | grep "郭梅梅" | awk '{print $3}')

if [ -z "$DEVICE_ID" ]; then
    echo "❌ 未找到设备，请检查连接后重试"
    exit 1
fi

echo "✅ 找到设备: $DEVICE_ID"
echo ""
echo "📦 开始安装应用..."

# 安装应用
xcrun devicectl device install app --device "$DEVICE_ID" "$APP_PATH"

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ 应用安装成功！"
    echo ""
    echo "🔍 验证步骤："
    echo "   1. 在iPhone上打开BBLearningApp"
    echo "   2. 检查控制台输出，应该看到："
    echo "      🎬 [LoginView] onAppear - 检查生物识别状态"
    echo "      🔐 [LoginView] 生物识别检查完成"
    echo "      🖥️ [LoginView] Rendering with:"
    echo "   3. 登录页面应该显示 Face ID/Touch ID 提示框"
    echo ""
else
    echo "❌ 安装失败，错误代码: $?"
    echo "请尝试："
    echo "   1. 重新插拔USB线"
    echo "   2. 重启Xcode"
    echo "   3. 在iPhone设置中删除旧版本应用"
fi
