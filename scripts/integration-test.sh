#!/bin/bash

# BBLearning 集成测试脚本
# 用途：自动化测试前后端集成功能

set -e

# 颜色输出
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 配置
API_BASE_URL="${API_BASE_URL:-http://localhost:8080/api/v1}"
FRONTEND_URL="${FRONTEND_URL:-http://localhost:3000}"

# 测试结果统计
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

echo "================================================"
echo "BBLearning 集成测试"
echo "================================================"
echo "API URL: $API_BASE_URL"
echo "Frontend URL: $FRONTEND_URL"
echo "================================================"
echo ""

# 辅助函数
function test_api() {
    local test_name="$1"
    local method="$2"
    local endpoint="$3"
    local data="$4"
    local expected_status="$5"
    local headers="$6"

    TOTAL_TESTS=$((TOTAL_TESTS + 1))

    echo -n "Testing: $test_name ... "

    if [ -z "$data" ]; then
        if [ -z "$headers" ]; then
            response=$(curl -s -w "\n%{http_code}" -X "$method" "$API_BASE_URL$endpoint" 2>&1)
        else
            response=$(curl -s -w "\n%{http_code}" -X "$method" "$API_BASE_URL$endpoint" -H "$headers" 2>&1)
        fi
    else
        if [ -z "$headers" ]; then
            response=$(curl -s -w "\n%{http_code}" -X "$method" "$API_BASE_URL$endpoint" \
                -H "Content-Type: application/json" \
                -d "$data" 2>&1)
        else
            response=$(curl -s -w "\n%{http_code}" -X "$method" "$API_BASE_URL$endpoint" \
                -H "Content-Type: application/json" \
                -H "$headers" \
                -d "$data" 2>&1)
        fi
    fi

    status_code=$(echo "$response" | tail -n 1)
    body=$(echo "$response" | sed '$d')

    if [ "$status_code" -eq "$expected_status" ]; then
        echo -e "${GREEN}PASSED${NC} (Status: $status_code)"
        PASSED_TESTS=$((PASSED_TESTS + 1))
        return 0
    else
        echo -e "${RED}FAILED${NC} (Expected: $expected_status, Got: $status_code)"
        echo "Response: $body"
        FAILED_TESTS=$((FAILED_TESTS + 1))
        return 1
    fi
}

function test_endpoint() {
    local test_name="$1"
    local url="$2"
    local expected_status="$3"

    TOTAL_TESTS=$((TOTAL_TESTS + 1))

    echo -n "Testing: $test_name ... "

    status_code=$(curl -s -o /dev/null -w "%{http_code}" "$url")

    if [ "$status_code" -eq "$expected_status" ]; then
        echo -e "${GREEN}PASSED${NC} (Status: $status_code)"
        PASSED_TESTS=$((PASSED_TESTS + 1))
        return 0
    else
        echo -e "${RED}FAILED${NC} (Expected: $expected_status, Got: $status_code)"
        FAILED_TESTS=$((FAILED_TESTS + 1))
        return 1
    fi
}

# 1. 测试服务健康检查
echo "======================================"
echo "1. 服务健康检查"
echo "======================================"

test_endpoint "后端健康检查" "$API_BASE_URL/../health" 200 || true
test_endpoint "前端页面访问" "$FRONTEND_URL" 200 || true

echo ""

# 2. 测试用户认证流程
echo "======================================"
echo "2. 用户认证测试"
echo "======================================"

# 生成随机测试用户
RANDOM_ID=$RANDOM
TEST_USERNAME="testuser_${RANDOM_ID}"
TEST_PASSWORD="TestPass123!"
TEST_GRADE="7"

echo "测试用户: $TEST_USERNAME"
echo ""

# 2.1 用户注册
register_data="{\"username\":\"$TEST_USERNAME\",\"password\":\"$TEST_PASSWORD\",\"grade\":\"$TEST_GRADE\"}"
echo "Attempting registration..."
response=$(curl -s -w "\n%{http_code}" -X POST "$API_BASE_URL/auth/register" \
    -H "Content-Type: application/json" \
    -d "$register_data" 2>&1)

status_code=$(echo "$response" | tail -n 1)
body=$(echo "$response" | sed '$d')

TOTAL_TESTS=$((TOTAL_TESTS + 1))
if [ "$status_code" -eq 200 ] || [ "$status_code" -eq 201 ]; then
    echo -e "${GREEN}PASSED${NC} 用户注册成功 (Status: $status_code)"
    PASSED_TESTS=$((PASSED_TESTS + 1))

    # 提取token
    ACCESS_TOKEN=$(echo "$body" | grep -o '"access_token":"[^"]*"' | sed 's/"access_token":"//;s/"//')
    REFRESH_TOKEN=$(echo "$body" | grep -o '"refresh_token":"[^"]*"' | sed 's/"refresh_token":"//;s/"//')

    if [ -n "$ACCESS_TOKEN" ]; then
        echo "  ✓ Access Token获取成功"
    fi
    if [ -n "$REFRESH_TOKEN" ]; then
        echo "  ✓ Refresh Token获取成功"
    fi
else
    echo -e "${RED}FAILED${NC} 用户注册失败 (Status: $status_code)"
    echo "Response: $body"
    FAILED_TESTS=$((FAILED_TESTS + 1))
fi

echo ""

# 2.2 用户登录
login_data="{\"username\":\"$TEST_USERNAME\",\"password\":\"$TEST_PASSWORD\"}"
echo "Attempting login..."
response=$(curl -s -w "\n%{http_code}" -X POST "$API_BASE_URL/auth/login" \
    -H "Content-Type: application/json" \
    -d "$login_data" 2>&1)

status_code=$(echo "$response" | tail -n 1)
body=$(echo "$response" | sed '$d')

TOTAL_TESTS=$((TOTAL_TESTS + 1))
if [ "$status_code" -eq 200 ]; then
    echo -e "${GREEN}PASSED${NC} 用户登录成功 (Status: $status_code)"
    PASSED_TESTS=$((PASSED_TESTS + 1))

    # 更新token
    ACCESS_TOKEN=$(echo "$body" | grep -o '"access_token":"[^"]*"' | sed 's/"access_token":"//;s/"//')
    REFRESH_TOKEN=$(echo "$body" | grep -o '"refresh_token":"[^"]*"' | sed 's/"refresh_token":"//;s/"//')
else
    echo -e "${RED}FAILED${NC} 用户登录失败 (Status: $status_code)"
    echo "Response: $body"
    FAILED_TESTS=$((FAILED_TESTS + 1))
fi

echo ""

# 3. 测试受保护的API端点
if [ -n "$ACCESS_TOKEN" ]; then
    echo "======================================"
    echo "3. 受保护API测试"
    echo "======================================"

    # 3.1 获取用户信息
    test_api "获取当前用户信息" "GET" "/users/me" "" 200 "Authorization: Bearer $ACCESS_TOKEN" || true

    # 3.2 获取知识点列表
    test_api "获取知识点列表" "GET" "/knowledge?grade=7" "" 200 "Authorization: Bearer $ACCESS_TOKEN" || true

    # 3.3 获取章节列表
    test_api "获取章节列表" "GET" "/chapters?grade=7" "" 200 "Authorization: Bearer $ACCESS_TOKEN" || true

    echo ""
fi

# 4. 测试Token刷新
if [ -n "$REFRESH_TOKEN" ]; then
    echo "======================================"
    echo "4. Token刷新测试"
    echo "======================================"

    refresh_data="{\"refresh_token\":\"$REFRESH_TOKEN\"}"
    test_api "刷新Access Token" "POST" "/auth/refresh" "$refresh_data" 200 || true

    echo ""
fi

# 5. 测试无效请求
echo "======================================"
echo "5. 错误处理测试"
echo "======================================"

test_api "无效的登录凭据" "POST" "/auth/login" '{"username":"invalid","password":"wrong"}' 401 || true
test_api "未授权的API访问" "GET" "/users/me" "" 401 || true
test_api "不存在的端点" "GET" "/nonexistent" "" 404 || true

echo ""

# 6. 测试结果汇总
echo "======================================"
echo "测试结果汇总"
echo "======================================"
echo "总测试数: $TOTAL_TESTS"
echo -e "通过: ${GREEN}$PASSED_TESTS${NC}"
echo -e "失败: ${RED}$FAILED_TESTS${NC}"

if [ $FAILED_TESTS -eq 0 ]; then
    echo -e "\n${GREEN}✓ 所有测试通过！${NC}"
    exit 0
else
    echo -e "\n${YELLOW}⚠ 部分测试失败${NC}"
    exit 1
fi
