#!/bin/bash

# BBLearning 数据库种子数据导入脚本
# 用法: ./scripts/run_seed.sh [environment]
# environment: dev (默认) | prod

set -e

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# 默认环境为开发环境
ENV="${1:-dev}"

echo "======================================"
echo "BBLearning 数据库种子数据导入"
echo "环境: $ENV"
echo "======================================"

# 根据环境加载不同的数据库配置
if [ "$ENV" = "prod" ]; then
    # 生产环境配置
    DB_HOST="${DB_HOST:-localhost}"
    DB_PORT="${DB_PORT:-5432}"
    DB_NAME="${DB_NAME:-bblearning}"
    DB_USER="${DB_USER:-postgres}"
    DB_PASSWORD="${DB_PASSWORD}"
else
    # 开发环境配置
    DB_HOST="${DB_HOST:-localhost}"
    DB_PORT="${DB_PORT:-5432}"
    DB_NAME="${DB_NAME:-bblearning_dev}"
    DB_USER="${DB_USER:-postgres}"
    DB_PASSWORD="${DB_PASSWORD:-postgres}"
fi

echo ""
echo "数据库连接信息:"
echo "  主机: $DB_HOST"
echo "  端口: $DB_PORT"
echo "  数据库: $DB_NAME"
echo "  用户: $DB_USER"
echo ""

# 检查 PostgreSQL 客户端是否安装
if ! command -v psql &> /dev/null; then
    echo "❌ 错误: 未找到 psql 命令"
    echo "请安装 PostgreSQL 客户端工具"
    exit 1
fi

# 检查数据库是否可连接
echo "检查数据库连接..."
export PGPASSWORD="$DB_PASSWORD"
if ! psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c "SELECT 1" > /dev/null 2>&1; then
    echo "❌ 错误: 无法连接到数据库"
    echo "请检查数据库是否运行，以及连接参数是否正确"
    exit 1
fi
echo "✅ 数据库连接成功"

# 询问是否继续（生产环境需要确认）
if [ "$ENV" = "prod" ]; then
    echo ""
    echo "⚠️  警告: 即将在生产环境导入种子数据!"
    echo "这将清空现有数据并重新导入。"
    read -p "确定要继续吗? (输入 YES 继续): " confirm
    if [ "$confirm" != "YES" ]; then
        echo "操作已取消"
        exit 0
    fi
fi

# 执行种子数据脚本
echo ""
echo "开始导入种子数据..."
if psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -f "$SCRIPT_DIR/seed_complete_data.sql"; then
    echo ""
    echo "======================================"
    echo "✅ 种子数据导入成功!"
    echo "======================================"
    echo ""
    echo "测试用户账号:"
    echo "  学生账号: student01 / 123456 (七年级)"
    echo "  学生账号: student02 / 123456 (八年级)"
    echo "  学生账号: student03 / 123456 (九年级)"
    echo "  教师账号: teacher01 / 123456"
    echo ""
    echo "数据统计:"
    psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c "
        SELECT
            '章节' as 类型, COUNT(*)::text as 数量 FROM chapters
        UNION ALL
        SELECT '知识点', COUNT(*)::text FROM knowledge_points
        UNION ALL
        SELECT '题目', COUNT(*)::text FROM questions
        UNION ALL
        SELECT '用户', COUNT(*)::text FROM users
        UNION ALL
        SELECT '学习进度', COUNT(*)::text FROM learning_progress
        UNION ALL
        SELECT '练习记录', COUNT(*)::text FROM practice_records
        UNION ALL
        SELECT '错题记录', COUNT(*)::text FROM wrong_questions;
    "
else
    echo ""
    echo "======================================"
    echo "❌ 种子数据导入失败"
    echo "======================================"
    exit 1
fi

# 清理环境变量
unset PGPASSWORD
