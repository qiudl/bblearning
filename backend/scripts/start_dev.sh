#!/bin/bash

# BBLearning 开发环境启动脚本

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
BACKEND_DIR="$PROJECT_ROOT/backend"

print_header() {
    echo -e "\n${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}\n"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

# 检查Docker是否运行
check_docker() {
    if ! docker info > /dev/null 2>&1; then
        print_error "Docker未运行"
        print_info "请先启动Docker Desktop或OrbStack"
        exit 1
    fi
    print_success "Docker已运行"
}

# 检查Go环境
check_go() {
    if ! command -v go &> /dev/null; then
        print_error "未找到Go环境"
        print_info "请安装Go 1.21或更高版本"
        exit 1
    fi
    GO_VERSION=$(go version | awk '{print $3}')
    print_success "Go环境已就绪 ($GO_VERSION)"
}

# 检查PostgreSQL客户端
check_psql() {
    if ! command -v psql &> /dev/null; then
        print_warning "未找到psql命令，将跳过数据库初始化"
        print_info "安装方法: brew install libpq"
        print_info "然后添加到PATH: export PATH=\"/usr/local/opt/libpq/bin:\$PATH\""
        return 1
    fi
    print_success "PostgreSQL客户端已就绪"
    return 0
}

# 启动Docker服务
start_docker_services() {
    print_header "启动Docker服务"

    cd "$PROJECT_ROOT"

    # 检查docker-compose文件
    if [ ! -f "docker-compose.yml" ]; then
        print_error "未找到docker-compose.yml"
        exit 1
    fi

    # 启动服务
    print_info "启动PostgreSQL, Redis, MinIO..."
    docker-compose up -d postgres redis minio

    # 等待服务就绪
    print_info "等待服务启动..."
    sleep 5

    # 检查服务状态
    if docker-compose ps | grep -E "postgres|redis|minio" | grep -q "Up"; then
        print_success "Docker服务已启动"
        docker-compose ps
    else
        print_error "Docker服务启动失败"
        docker-compose ps
        exit 1
    fi
}

# 初始化数据库
init_database() {
    print_header "初始化数据库"

    if ! check_psql; then
        print_warning "跳过数据库初始化，请手动运行:"
        print_info "  cd backend && make migrate-up"
        print_info "  cd backend && ./scripts/run_seed.sh"
        return
    fi

    cd "$BACKEND_DIR"

    # 检查数据库连接
    export PGPASSWORD="postgres"
    if ! psql -h localhost -p 5432 -U postgres -d postgres -c "SELECT 1" > /dev/null 2>&1; then
        print_warning "无法连接到PostgreSQL，跳过数据库初始化"
        return
    fi

    # 创建数据库（如果不存在）
    print_info "创建数据库..."
    psql -h localhost -p 5432 -U postgres -d postgres -c "
        SELECT 'CREATE DATABASE bblearning_dev'
        WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'bblearning_dev')\gexec
    " > /dev/null 2>&1 || true

    # 检查是否需要运行迁移
    if psql -h localhost -p 5432 -U postgres -d bblearning_dev -c "SELECT 1 FROM users LIMIT 1" > /dev/null 2>&1; then
        print_info "数据库已存在数据，跳过初始化"
    else
        print_info "运行数据库迁移..."
        # 这里需要migrate工具，如果没有安装会跳过
        if command -v migrate &> /dev/null; then
            make migrate-up || print_warning "迁移失败，请手动运行: make migrate-up"
        else
            print_warning "未找到migrate工具"
            print_info "安装方法: brew install golang-migrate"
            print_info "手动运行: cd backend && make migrate-up"
        fi

        print_info "导入种子数据..."
        if [ -f "scripts/run_seed.sh" ]; then
            ./scripts/run_seed.sh || print_warning "种子数据导入失败"
        fi
    fi

    unset PGPASSWORD
    print_success "数据库初始化完成"
}

# 安装Go依赖
install_dependencies() {
    print_header "安装Go依赖"

    cd "$BACKEND_DIR"

    if [ ! -f "go.mod" ]; then
        print_error "未找到go.mod"
        exit 1
    fi

    print_info "下载Go模块..."
    go mod download

    print_success "依赖安装完成"
}

# 生成加密密钥
generate_encryption_key() {
    if [ ! -f "$BACKEND_DIR/scripts/generate-master-key.sh" ]; then
        return
    fi

    if grep -q "ENCRYPTION_MASTER_KEY=0123456789abcdef" "$BACKEND_DIR/.env" 2>/dev/null; then
        print_warning "使用默认加密密钥（仅用于开发）"
        print_info "生产环境请运行: ./scripts/generate-master-key.sh"
    fi
}

# 启动后端服务
start_backend() {
    print_header "启动后端服务"

    cd "$BACKEND_DIR"

    # 检查.env文件
    if [ ! -f ".env" ]; then
        print_warning "未找到.env文件，使用.env.example"
        if [ -f ".env.example" ]; then
            cp .env.example .env
        else
            print_error "未找到.env.example"
            exit 1
        fi
    fi

    print_info "后端服务配置:"
    print_info "  - API地址: http://localhost:8080"
    print_info "  - API文档: http://localhost:8080/swagger/index.html"
    print_info "  - 健康检查: http://localhost:8080/api/v1/health"
    echo ""

    print_info "启动后端服务 (按Ctrl+C停止)..."
    print_info "日志将显示在下方..."
    echo ""

    # 启动服务
    go run cmd/server/main.go
}

# 主流程
main() {
    print_header "BBLearning 开发环境启动"

    # 检查环境
    check_go
    check_docker

    # 启动服务
    start_docker_services
    init_database
    install_dependencies
    generate_encryption_key

    # 启动后端
    start_backend
}

# 运行
main
