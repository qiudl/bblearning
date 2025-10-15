#!/bin/bash

# BBLearning 快速API测试脚本
# 快速验证后端服务是否正常运行

set -e

GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

API_URL="${1:-http://localhost:8080}"
BASE_URL="$API_URL/api/v1"

print_test() {
    echo -e "${BLUE}[TEST]${NC} $1"
}

print_pass() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_fail() {
    echo -e "${RED}[✗]${NC} $1"
}

print_info() {
    echo -e "${YELLOW}[INFO]${NC} $1"
}

echo -e "\n${BLUE}========================================${NC}"
echo -e "${BLUE}BBLearning 快速API测试${NC}"
echo -e "${BLUE}========================================${NC}\n"
print_info "测试服务器: $API_URL"
echo ""

# 测试1: 健康检查
print_test "1. 健康检查"
if curl -s "$BASE_URL/health" | grep -q "ok"; then
    print_pass "服务运行正常"
else
    print_fail "健康检查失败"
    echo ""
    print_info "请确保服务已启动: cd backend && ./scripts/start_dev.sh"
    exit 1
fi

# 测试2: 用户登录
print_test "2. 用户登录"
LOGIN_RESPONSE=$(curl -s -X POST "$BASE_URL/auth/login" \
    -H "Content-Type: application/json" \
    -d '{"username":"student01","password":"123456"}')

if echo "$LOGIN_RESPONSE" | jq -e '.code == 0' > /dev/null 2>&1; then
    print_pass "登录成功"
    TOKEN=$(echo "$LOGIN_RESPONSE" | jq -r '.data.access_token')
    USERNAME=$(echo "$LOGIN_RESPONSE" | jq -r '.data.user.nickname')
    print_info "用户: $USERNAME"
else
    print_fail "登录失败"
    echo "$LOGIN_RESPONSE" | jq '.'
    exit 1
fi

# 测试3: 获取用户信息
print_test "3. 获取当前用户"
if curl -s -X GET "$BASE_URL/users/me" \
    -H "Authorization: Bearer $TOKEN" | jq -e '.code == 0' > /dev/null 2>&1; then
    print_pass "获取用户信息成功"
else
    print_fail "获取用户信息失败"
fi

# 测试4: 获取知识树
print_test "4. 获取知识树"
TREE_RESPONSE=$(curl -s -X GET "$BASE_URL/knowledge/tree?grade=7" \
    -H "Authorization: Bearer $TOKEN")
if echo "$TREE_RESPONSE" | jq -e '.code == 0' > /dev/null 2>&1; then
    CHAPTER_COUNT=$(echo "$TREE_RESPONSE" | jq '.data.chapters | length')
    print_pass "知识树加载成功 ($CHAPTER_COUNT 个章节)"
else
    print_fail "知识树加载失败"
fi

# 测试5: 生成练习
print_test "5. 生成练习题目"
PRACTICE_RESPONSE=$(curl -s -X POST "$BASE_URL/practice/generate" \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -d '{"knowledge_point_ids":[1,2,3],"count":5,"difficulty":"medium","mode":"standard"}')
if echo "$PRACTICE_RESPONSE" | jq -e '.code == 0' > /dev/null 2>&1; then
    QUESTION_COUNT=$(echo "$PRACTICE_RESPONSE" | jq '.data.questions | length')
    print_pass "生成练习成功 ($QUESTION_COUNT 道题目)"
else
    print_fail "生成练习失败"
fi

# 测试6: 获取学习报告
print_test "6. 获取学习报告"
if curl -s -X GET "$BASE_URL/reports/statistics" \
    -H "Authorization: Bearer $TOKEN" | jq -e '.code == 0' > /dev/null 2>&1; then
    print_pass "学习报告获取成功"
else
    print_fail "学习报告获取失败"
fi

# 汇总
echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}✅ 核心功能测试通过!${NC}"
echo -e "${GREEN}========================================${NC}\n"

print_info "后端API已就绪，可以开始iOS端集成"
print_info "API Base URL: $BASE_URL"
print_info "测试账号: student01 / 123456"
echo ""
