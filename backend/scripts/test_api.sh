#!/bin/bash

# BBLearning API集成测试脚本
# 测试所有核心API端点

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# API基础URL
API_BASE_URL="${API_BASE_URL:-http://localhost:8080/api/v1}"

# 测试结果统计
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# 全局变量
ACCESS_TOKEN=""
REFRESH_TOKEN=""
USER_ID=""

# 打印函数
print_header() {
    echo -e "\n${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}\n"
}

print_test() {
    echo -e "${YELLOW}[TEST]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[✓ PASS]${NC} $1"
    ((PASSED_TESTS++))
}

print_fail() {
    echo -e "${RED}[✗ FAIL]${NC} $1"
    ((FAILED_TESTS++))
}

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

# HTTP请求函数
make_request() {
    local method=$1
    local endpoint=$2
    local data=$3
    local auth_required=$4

    local url="${API_BASE_URL}${endpoint}"
    local headers="Content-Type: application/json"

    if [ "$auth_required" = "true" ] && [ -n "$ACCESS_TOKEN" ]; then
        headers="${headers} -H Authorization: Bearer ${ACCESS_TOKEN}"
    fi

    if [ "$method" = "GET" ]; then
        curl -s -X GET "$url" -H "$headers"
    elif [ "$method" = "POST" ]; then
        curl -s -X POST "$url" -H "$headers" -d "$data"
    elif [ "$method" = "PUT" ]; then
        curl -s -X PUT "$url" -H "$headers" -d "$data"
    elif [ "$method" = "DELETE" ]; then
        curl -s -X DELETE "$url" -H "$headers"
    fi
}

# 检查API响应
check_response() {
    local response=$1
    local expected_code=$2
    local test_name=$3

    ((TOTAL_TESTS++))

    # 提取code字段
    local code=$(echo "$response" | jq -r '.code // empty')

    if [ "$code" = "$expected_code" ]; then
        print_success "$test_name"
        return 0
    else
        print_fail "$test_name (期望code=$expected_code, 实际code=$code)"
        echo "响应: $response" | jq '.' 2>/dev/null || echo "$response"
        return 1
    fi
}

# 检查curl是否安装
if ! command -v curl &> /dev/null; then
    echo -e "${RED}错误: 未找到 curl 命令${NC}"
    exit 1
fi

# 检查jq是否安装
if ! command -v jq &> /dev/null; then
    echo -e "${RED}错误: 未找到 jq 命令，请安装 jq 工具${NC}"
    echo "Mac: brew install jq"
    echo "Ubuntu: sudo apt-get install jq"
    exit 1
fi

print_header "BBLearning API 集成测试"
print_info "API Base URL: $API_BASE_URL"
print_info "开始时间: $(date '+%Y-%m-%d %H:%M:%S')"

# ====================================
# 1. 健康检查
# ====================================
print_header "1. 健康检查"

print_test "GET /health"
response=$(make_request GET "/health" "" "false")
if echo "$response" | jq -e '.status == "ok"' > /dev/null 2>&1; then
    print_success "健康检查通过"
    ((TOTAL_TESTS++))
    ((PASSED_TESTS++))
else
    print_fail "健康检查失败"
    ((TOTAL_TESTS++))
    ((FAILED_TESTS++))
fi

# ====================================
# 2. 用户认证API测试
# ====================================
print_header "2. 用户认证API测试"

# 2.1 用户注册
print_test "POST /auth/register - 用户注册"
register_data='{
  "username": "test_'$(date +%s)'",
  "password": "Test123456",
  "nickname": "测试用户",
  "email": "test'$(date +%s)'@example.com",
  "grade": "7"
}'
response=$(make_request POST "/auth/register" "$register_data" "false")
check_response "$response" "0" "用户注册"

# 2.2 用户登录
print_test "POST /auth/login - 用户登录"
login_data='{
  "username": "student01",
  "password": "123456"
}'
response=$(make_request POST "/auth/login" "$login_data" "false")
check_response "$response" "0" "用户登录"

# 提取token
ACCESS_TOKEN=$(echo "$response" | jq -r '.data.access_token // empty')
REFRESH_TOKEN=$(echo "$response" | jq -r '.data.refresh_token // empty')
USER_ID=$(echo "$response" | jq -r '.data.user.id // empty')

if [ -n "$ACCESS_TOKEN" ]; then
    print_info "获取到访问令牌: ${ACCESS_TOKEN:0:20}..."
else
    print_fail "未能获取访问令牌"
fi

# 2.3 获取当前用户信息
print_test "GET /users/me - 获取当前用户"
response=$(make_request GET "/users/me" "" "true")
check_response "$response" "0" "获取当前用户信息"

# 2.4 验证Token
print_test "GET /auth/verify - 验证Token"
response=$(make_request GET "/auth/verify" "" "true")
check_response "$response" "0" "验证Token"

# ====================================
# 3. 知识点API测试
# ====================================
print_header "3. 知识点API测试"

# 3.1 获取章节列表
print_test "GET /chapters?grade=7 - 获取章节列表"
response=$(make_request GET "/chapters?grade=7" "" "false")
check_response "$response" "0" "获取章节列表"

# 3.2 获取章节详情
print_test "GET /chapters/1 - 获取章节详情"
response=$(make_request GET "/chapters/1" "" "false")
check_response "$response" "0" "获取章节详情"

# 3.3 获取知识点列表
print_test "GET /knowledge-points?chapter_id=1 - 获取知识点列表"
response=$(make_request GET "/knowledge-points?chapter_id=1" "" "false")
check_response "$response" "0" "获取知识点列表"

# 3.4 获取知识点详情
print_test "GET /knowledge-points/1 - 获取知识点详情"
response=$(make_request GET "/knowledge-points/1" "" "true")
check_response "$response" "0" "获取知识点详情"

# 3.5 获取知识树
print_test "GET /knowledge/tree?grade=7 - 获取知识树"
response=$(make_request GET "/knowledge/tree?grade=7" "" "true")
check_response "$response" "0" "获取知识树"

# 3.6 获取用户学习进度
print_test "GET /learning/progress - 获取学习进度"
response=$(make_request GET "/learning/progress" "" "true")
check_response "$response" "0" "获取用户学习进度"

# ====================================
# 4. 练习API测试
# ====================================
print_header "4. 练习API测试"

# 4.1 获取题目列表
print_test "GET /questions?knowledge_point_id=1 - 获取题目列表"
response=$(make_request GET "/questions?knowledge_point_id=1" "" "true")
check_response "$response" "0" "获取题目列表"

# 4.2 生成练习题目
print_test "POST /practice/generate - 生成练习"
generate_data='{
  "knowledge_point_ids": [1, 2, 3],
  "count": 5,
  "difficulty": "medium",
  "mode": "standard"
}'
response=$(make_request POST "/practice/generate" "$generate_data" "true")
check_response "$response" "0" "生成练习题目"

# 提取第一道题目ID
QUESTION_ID=$(echo "$response" | jq -r '.data.questions[0].id // empty')

# 4.3 提交单个答案
if [ -n "$QUESTION_ID" ]; then
    print_test "POST /practice/submit - 提交答案"
    submit_data='{
      "question_id": '"$QUESTION_ID"',
      "user_answer": "A",
      "time_spent": 30
    }'
    response=$(make_request POST "/practice/submit" "$submit_data" "true")
    check_response "$response" "0" "提交单个答案"
fi

# 4.4 获取练习记录
print_test "GET /practice/records - 获取练习记录"
response=$(make_request GET "/practice/records" "" "true")
check_response "$response" "0" "获取练习记录"

# 4.5 获取练习统计
print_test "GET /practice/statistics - 获取练习统计"
response=$(make_request GET "/practice/statistics" "" "true")
check_response "$response" "0" "获取练习统计"

# ====================================
# 5. 错题本API测试
# ====================================
print_header "5. 错题本API测试"

# 5.1 获取错题列表
print_test "GET /wrong-questions - 获取错题列表"
response=$(make_request GET "/wrong-questions" "" "true")
check_response "$response" "0" "获取错题列表"

# 5.2 获取错误最多的题目
print_test "GET /wrong-questions/top?limit=5 - 获取Top错题"
response=$(make_request GET "/wrong-questions/top?limit=5" "" "true")
check_response "$response" "0" "获取错误最多的题目"

# ====================================
# 6. AI服务API测试
# ====================================
print_header "6. AI服务API测试"

# 6.1 AI生成题目
print_test "POST /ai/generate-question - AI生成题目"
ai_gen_data='{
  "knowledge_point_ids": [1],
  "grade": "7",
  "difficulty": "medium",
  "count": 1
}'
response=$(make_request POST "/ai/generate-question" "$ai_gen_data" "true")
# AI服务可能未配置，允许失败
if echo "$response" | jq -e '.code == 0' > /dev/null 2>&1; then
    print_success "AI生成题目"
    ((TOTAL_TESTS++))
    ((PASSED_TESTS++))
else
    print_info "AI生成题目跳过 (可能未配置AI服务)"
    ((TOTAL_TESTS++))
fi

# 6.2 AI对话
print_test "POST /ai/chat - AI对话"
chat_data='{
  "message": "什么是三角形?",
  "conversation_id": null
}'
response=$(make_request POST "/ai/chat" "$chat_data" "true")
if echo "$response" | jq -e '.code == 0' > /dev/null 2>&1; then
    print_success "AI对话"
    ((TOTAL_TESTS++))
    ((PASSED_TESTS++))
else
    print_info "AI对话跳过 (可能未配置AI服务)"
    ((TOTAL_TESTS++))
fi

# ====================================
# 7. 学习报告API测试
# ====================================
print_header "7. 学习报告API测试"

# 7.1 获取学习报告
print_test "GET /reports/learning?period=week - 获取学习报告"
response=$(make_request GET "/reports/learning?period=week" "" "true")
check_response "$response" "0" "获取学习报告"

# 7.2 获取薄弱点分析
print_test "GET /reports/weak-points - 获取薄弱点"
response=$(make_request GET "/reports/weak-points" "" "true")
check_response "$response" "0" "获取薄弱点分析"

# 7.3 获取进度总览
print_test "GET /reports/progress - 获取进度总览"
response=$(make_request GET "/reports/progress" "" "true")
check_response "$response" "0" "获取进度总览"

# 7.4 获取学习统计
print_test "GET /reports/statistics - 获取学习统计"
response=$(make_request GET "/reports/statistics" "" "true")
check_response "$response" "0" "获取学习统计"

# ====================================
# 8. Token刷新测试
# ====================================
print_header "8. Token刷新测试"

if [ -n "$REFRESH_TOKEN" ]; then
    print_test "POST /auth/refresh - 刷新Token"
    refresh_data='{
      "refresh_token": "'"$REFRESH_TOKEN"'"
    }'
    response=$(make_request POST "/auth/refresh" "$refresh_data" "false")
    check_response "$response" "0" "刷新Token"
fi

# ====================================
# 9. 登出测试
# ====================================
print_header "9. 登出测试"

print_test "POST /auth/logout - 用户登出"
response=$(make_request POST "/auth/logout" "{}" "true")
check_response "$response" "0" "用户登出"

# ====================================
# 测试结果汇总
# ====================================
print_header "测试结果汇总"

echo -e "总测试数: ${BLUE}$TOTAL_TESTS${NC}"
echo -e "通过测试: ${GREEN}$PASSED_TESTS${NC}"
echo -e "失败测试: ${RED}$FAILED_TESTS${NC}"

PASS_RATE=0
if [ "$TOTAL_TESTS" -gt 0 ]; then
    PASS_RATE=$(awk "BEGIN {printf \"%.2f\", ($PASSED_TESTS/$TOTAL_TESTS)*100}")
fi

echo -e "通过率: ${BLUE}${PASS_RATE}%${NC}"
echo ""
print_info "结束时间: $(date '+%Y-%m-%d %H:%M:%S')"

# 返回退出码
if [ "$FAILED_TESTS" -eq 0 ]; then
    echo -e "\n${GREEN}✅ 所有测试通过!${NC}\n"
    exit 0
else
    echo -e "\n${RED}❌ 有测试失败${NC}\n"
    exit 1
fi
