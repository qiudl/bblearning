#!/bin/bash
# iOS API集成测试脚本
# 用于验证iOS应用能否正确连接到后端API

set -e

echo "🚀 iOS API集成测试开始"
echo "======================================"
echo ""

# 颜色定义
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 测试计数器
PASSED=0
FAILED=0

# 测试函数
test_api() {
    local test_name=$1
    local method=$2
    local url=$3
    local headers=$4
    local data=$5

    echo -e "${YELLOW}测试: $test_name${NC}"

    if [ -n "$data" ]; then
        response=$(curl -s -X $method "$url" $headers -d "$data")
    else
        response=$(curl -s -X $method "$url" $headers)
    fi

    # 检查是否包含 "code": 0
    if echo "$response" | grep -q '"code":0' || echo "$response" | grep -q '"code": 0'; then
        echo -e "${GREEN}✅ 通过${NC}"
        echo "$response" | python3 -m json.tool 2>/dev/null || echo "$response"
        PASSED=$((PASSED + 1))
    else
        echo -e "${RED}❌ 失败${NC}"
        echo "$response" | python3 -m json.tool 2>/dev/null || echo "$response"
        FAILED=$((FAILED + 1))
    fi
    echo ""
}

# 测试1: 健康检查
echo "=== 测试1: 健康检查 ==="
test_api "健康检查" "GET" "http://localhost:9090/api/v1/health" "" ""

# 测试2: 用户登录
echo "=== 测试2: 用户登录 (student01) ==="
LOGIN_RESPONSE=$(curl -s -X POST http://localhost:9090/api/v1/auth/login \
  -H 'Content-Type: application/json' \
  -d '{"username":"student01","password":"123456"}')

echo "$LOGIN_RESPONSE" | python3 -m json.tool 2>/dev/null || echo "$LOGIN_RESPONSE"

# 检查登录是否成功
if echo "$LOGIN_RESPONSE" | grep -q '"code":0' || echo "$LOGIN_RESPONSE" | grep -q '"code": 0'; then
    echo -e "${GREEN}✅ 登录成功${NC}"
    PASSED=$((PASSED + 1))

    # 提取token
    TOKEN=$(echo $LOGIN_RESPONSE | python3 -c "import sys, json; print(json.load(sys.stdin)['data']['access_token'])" 2>/dev/null)

    if [ -n "$TOKEN" ]; then
        echo "Token获取成功: ${TOKEN:0:20}..."
        echo ""

        # 测试3: 获取章节列表
        echo "=== 测试3: 获取7年级章节列表 ==="
        test_api "获取章节列表" "GET" "http://localhost:9090/api/v1/chapters?grade=7&page=1&page_size=10" \
          "-H 'Authorization: Bearer $TOKEN'" ""

        # 测试4: 获取知识点
        echo "=== 测试4: 获取第一章的知识点 ==="
        test_api "获取知识点" "GET" "http://localhost:9090/api/v1/knowledge-points?chapter_id=1&page=1&page_size=5" \
          "-H 'Authorization: Bearer $TOKEN'" ""

        # 测试5: 获取用户信息
        echo "=== 测试5: 获取用户信息 ==="
        test_api "获取用户信息" "GET" "http://localhost:9090/api/v1/users/profile" \
          "-H 'Authorization: Bearer $TOKEN'" ""
    else
        echo -e "${RED}❌ 无法提取Token${NC}"
        FAILED=$((FAILED + 1))
    fi
else
    echo -e "${RED}❌ 登录失败${NC}"
    FAILED=$((FAILED + 1))
fi

# 测试其他测试账号
echo "=== 测试6: 其他测试账号登录 ==="
for username in "student02" "student03" "teacher01"; do
    echo "测试账号: $username"
    response=$(curl -s -X POST http://localhost:9090/api/v1/auth/login \
      -H 'Content-Type: application/json' \
      -d "{\"username\":\"$username\",\"password\":\"123456\"}")

    if echo "$response" | grep -q '"code":0' || echo "$response" | grep -q '"code": 0'; then
        echo -e "${GREEN}✅ $username 登录成功${NC}"
        PASSED=$((PASSED + 1))
    else
        echo -e "${RED}❌ $username 登录失败${NC}"
        FAILED=$((FAILED + 1))
    fi
done
echo ""

# 汇总结果
echo "======================================"
echo "📊 测试结果汇总"
echo "======================================"
echo -e "${GREEN}通过: $PASSED${NC}"
echo -e "${RED}失败: $FAILED${NC}"
echo "总计: $((PASSED + FAILED))"
echo ""

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}🎉 所有测试通过！iOS应用可以开始使用后端API了。${NC}"
    echo ""
    echo "下一步："
    echo "1. 打开Xcode项目: /Users/johnqiu/coding/www/projects/bblearning/ios/BBLearning"
    echo "2. 选择iOS模拟器（推荐iPhone 15 Pro）"
    echo "3. 运行应用（Cmd+R）"
    echo "4. 使用测试账号登录："
    echo "   - 用户名: student01"
    echo "   - 密码: 123456"
    exit 0
else
    echo -e "${RED}⚠️ 有 $FAILED 个测试失败，请检查后端服务。${NC}"
    echo ""
    echo "故障排查："
    echo "1. 检查Docker服务: docker-compose ps"
    echo "2. 查看后端日志: docker logs bblearning-backend"
    echo "3. 重启后端服务: docker-compose restart backend"
    exit 1
fi
