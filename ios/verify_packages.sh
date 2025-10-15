#!/bin/bash

echo "======================================"
echo "Swift Package 安装验证脚本"
echo "======================================"
echo ""

# 颜色定义
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 检查计数器
SUCCESS_COUNT=0
FAIL_COUNT=0

# 函数：检查文件是否存在
check_file() {
    if [ -f "$1" ]; then
        echo -e "${GREEN}✅ $2${NC}"
        ((SUCCESS_COUNT++))
    else
        echo -e "${RED}❌ $2 - 文件不存在: $1${NC}"
        ((FAIL_COUNT++))
    fi
}

# 函数：检查目录是否存在
check_dir() {
    if [ -d "$1" ]; then
        echo -e "${GREEN}✅ $2${NC}"
        ((SUCCESS_COUNT++))
    else
        echo -e "${RED}❌ $2 - 目录不存在: $1${NC}"
        ((FAIL_COUNT++))
    fi
}

echo "1. 检查Swift Package下载..."
echo "-----------------------------------"
check_dir "/Users/johnqiu/coding/www/projects/bblearning/ios/SwiftPackages/Alamofire" "Alamofire 包"
check_dir "/Users/johnqiu/coding/www/projects/bblearning/ios/SwiftPackages/realm-swift" "realm-swift 包"
check_dir "/Users/johnqiu/coding/www/projects/bblearning/ios/SwiftPackages/Swinject" "Swinject 包"
check_dir "/Users/johnqiu/coding/www/projects/bblearning/ios/SwiftPackages/KeychainAccess" "KeychainAccess 包"
check_dir "/Users/johnqiu/coding/www/projects/bblearning/ios/SwiftPackages/Nuke" "Nuke 包"
check_dir "/Users/johnqiu/coding/www/projects/bblearning/ios/SwiftPackages/swift-log" "swift-log 包"

echo ""
echo "2. 检查Package.swift文件..."
echo "-----------------------------------"
check_file "/Users/johnqiu/coding/www/projects/bblearning/ios/SwiftPackages/Alamofire/Package.swift" "Alamofire/Package.swift"
check_file "/Users/johnqiu/coding/www/projects/bblearning/ios/SwiftPackages/realm-swift/Package.swift" "realm-swift/Package.swift"
check_file "/Users/johnqiu/coding/www/projects/bblearning/ios/SwiftPackages/Swinject/Package.swift" "Swinject/Package.swift"
check_file "/Users/johnqiu/coding/www/projects/bblearning/ios/SwiftPackages/KeychainAccess/Package.swift" "KeychainAccess/Package.swift"
check_file "/Users/johnqiu/coding/www/projects/bblearning/ios/SwiftPackages/Nuke/Package.swift" "Nuke/Package.swift"
check_file "/Users/johnqiu/coding/www/projects/bblearning/ios/SwiftPackages/swift-log/Package.swift" "swift-log/Package.swift"

echo ""
echo "3. 检查项目文件..."
echo "-----------------------------------"
check_file "/Users/johnqiu/coding/www/projects/bblearning/ios/BBLearningApp/BBLearningApp.xcodeproj/project.pbxproj" "project.pbxproj"
check_file "/Users/johnqiu/coding/www/projects/bblearning/ios/BBLearningApp/BBLearningApp.xcodeproj/project.pbxproj.backup" "project.pbxproj.backup (备份)"

echo ""
echo "4. 检查项目文件中的包引用..."
echo "-----------------------------------"

PROJECT_FILE="/Users/johnqiu/coding/www/projects/bblearning/ios/BBLearningApp/BBLearningApp.xcodeproj/project.pbxproj"

if grep -q "XCLocalSwiftPackageReference" "$PROJECT_FILE"; then
    echo -e "${GREEN}✅ 找到本地包引用 (XCLocalSwiftPackageReference)${NC}"
    ((SUCCESS_COUNT++))
else
    echo -e "${RED}❌ 未找到本地包引用${NC}"
    ((FAIL_COUNT++))
fi

if grep -q "XCSwiftPackageProductDependency" "$PROJECT_FILE"; then
    echo -e "${GREEN}✅ 找到产品依赖 (XCSwiftPackageProductDependency)${NC}"
    ((SUCCESS_COUNT++))
else
    echo -e "${RED}❌ 未找到产品依赖${NC}"
    ((FAIL_COUNT++))
fi

if grep -q "packageReferences" "$PROJECT_FILE"; then
    echo -e "${GREEN}✅ 找到包引用配置 (packageReferences)${NC}"
    ((SUCCESS_COUNT++))
else
    echo -e "${RED}❌ 未找到包引用配置${NC}"
    ((FAIL_COUNT++))
fi

if grep -q "packageProductDependencies" "$PROJECT_FILE"; then
    echo -e "${GREEN}✅ 找到产品依赖配置 (packageProductDependencies)${NC}"
    ((SUCCESS_COUNT++))
else
    echo -e "${RED}❌ 未找到产品依赖配置${NC}"
    ((FAIL_COUNT++))
fi

# 检查特定包的引用
echo ""
echo "5. 检查各个包的引用..."
echo "-----------------------------------"

for pkg in "Alamofire" "realm-swift" "Swinject" "KeychainAccess" "Nuke" "swift-log"; do
    if grep -q "$pkg" "$PROJECT_FILE"; then
        echo -e "${GREEN}✅ $pkg 已引用${NC}"
        ((SUCCESS_COUNT++))
    else
        echo -e "${RED}❌ $pkg 未引用${NC}"
        ((FAIL_COUNT++))
    fi
done

echo ""
echo "======================================"
echo "验证总结"
echo "======================================"
echo -e "成功: ${GREEN}${SUCCESS_COUNT}${NC}"
echo -e "失败: ${RED}${FAIL_COUNT}${NC}"
echo ""

if [ $FAIL_COUNT -eq 0 ]; then
    echo -e "${GREEN}🎉 所有检查通过！可以在Xcode中打开项目并编译了。${NC}"
    echo ""
    echo "下一步:"
    echo "  1. 打开项目: open ~/coding/www/projects/bblearning/ios/BBLearningApp/BBLearningApp.xcodeproj"
    echo "  2. 清理构建: Shift + Cmd + K"
    echo "  3. 构建项目: Cmd + B"
    exit 0
else
    echo -e "${RED}⚠️  发现 ${FAIL_COUNT} 个问题，请检查并修复。${NC}"
    echo ""
    echo "故障排除:"
    echo "  - 查看上面的错误信息"
    echo "  - 参考 PACKAGE_INSTALLATION_COMPLETE.md 文档"
    echo "  - 如需帮助，请联系开发者"
    exit 1
fi
