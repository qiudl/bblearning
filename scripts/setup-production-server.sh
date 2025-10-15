#!/bin/bash

###############################################################################
# BBLearning 生产服务器初始化脚本
# 用途：在全新的服务器上安装必要的软件和配置
# 运行方式：在服务器上执行此脚本
###############################################################################

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查是否为root用户
check_root() {
    if [ "$EUID" -ne 0 ]; then
        log_error "请使用root用户或sudo执行此脚本"
        exit 1
    fi
}

# 更新系统
update_system() {
    log_info "更新系统包..."
    apt-get update -y
    apt-get upgrade -y
    log_success "系统更新完成"
}

# 安装基础工具
install_basic_tools() {
    log_info "安装基础工具..."
    apt-get install -y \
        curl \
        wget \
        git \
        vim \
        htop \
        net-tools \
        unzip \
        build-essential \
        software-properties-common \
        apt-transport-https \
        ca-certificates \
        gnupg \
        lsb-release
    log_success "基础工具安装完成"
}

# 安装Docker
install_docker() {
    log_info "安装Docker..."

    # 添加Docker官方GPG密钥
    mkdir -p /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg

    # 添加Docker仓库
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
      $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

    # 安装Docker
    apt-get update -y
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

    # 启动Docker
    systemctl start docker
    systemctl enable docker

    # 验证安装
    docker --version
    docker compose version

    log_success "Docker安装完成"
}

# 配置防火墙
configure_firewall() {
    log_info "配置防火墙..."

    # 安装ufw
    apt-get install -y ufw

    # 允许SSH
    ufw allow 22/tcp

    # 允许HTTP和HTTPS
    ufw allow 80/tcp
    ufw allow 443/tcp

    # 启用防火墙
    ufw --force enable

    log_success "防火墙配置完成"
}

# 创建应用目录
create_app_directory() {
    log_info "创建应用目录..."

    APP_DIR="/var/www/bblearning"
    mkdir -p ${APP_DIR}/{releases,backups,logs}

    log_success "应用目录创建完成: ${APP_DIR}"
}

# 配置Swap（可选，用于低内存服务器）
configure_swap() {
    log_info "配置Swap..."

    if [ -f /swapfile ]; then
        log_info "Swap已存在，跳过"
        return
    fi

    # 创建2GB Swap文件
    fallocate -l 2G /swapfile
    chmod 600 /swapfile
    mkswap /swapfile
    swapon /swapfile

    # 永久启用
    echo '/swapfile none swap sw 0 0' >> /etc/fstab

    log_success "Swap配置完成"
}

# 安装监控工具（可选）
install_monitoring() {
    log_info "安装监控工具..."

    # 安装Node Exporter（用于Prometheus监控）
    wget https://github.com/prometheus/node_exporter/releases/download/v1.6.1/node_exporter-1.6.1.linux-amd64.tar.gz
    tar xvfz node_exporter-1.6.1.linux-amd64.tar.gz
    cp node_exporter-1.6.1.linux-amd64/node_exporter /usr/local/bin/
    rm -rf node_exporter-1.6.1.linux-amd64*

    # 创建systemd服务
    cat > /etc/systemd/system/node_exporter.service << 'EOF'
[Unit]
Description=Node Exporter
After=network.target

[Service]
Type=simple
User=nobody
ExecStart=/usr/local/bin/node_exporter

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl start node_exporter
    systemctl enable node_exporter

    log_success "监控工具安装完成"
}

# 配置自动备份
configure_backup() {
    log_info "配置自动备份..."

    # 创建备份脚本
    cat > /usr/local/bin/bblearning-backup.sh << 'EOF'
#!/bin/bash
BACKUP_DIR="/var/www/bblearning/backups"
DATE=$(date +%Y%m%d-%H%M%S)

# 备份数据库
docker exec bblearning-postgres-prod pg_dump -U bblearning bblearning | gzip > ${BACKUP_DIR}/db-${DATE}.sql.gz

# 清理7天前的备份
find ${BACKUP_DIR} -name "db-*.sql.gz" -mtime +7 -delete

echo "备份完成: ${DATE}"
EOF

    chmod +x /usr/local/bin/bblearning-backup.sh

    # 添加到crontab（每天凌晨2点执行）
    (crontab -l 2>/dev/null; echo "0 2 * * * /usr/local/bin/bblearning-backup.sh >> /var/log/bblearning-backup.log 2>&1") | crontab -

    log_success "自动备份配置完成"
}

# 主函数
main() {
    log_info "=========================================="
    log_info "BBLearning 生产服务器初始化"
    log_info "=========================================="
    echo ""

    check_root
    update_system
    install_basic_tools
    install_docker
    configure_firewall
    create_app_directory
    configure_swap
    install_monitoring
    configure_backup

    echo ""
    log_success "=========================================="
    log_success "服务器初始化完成！"
    log_success "=========================================="
    echo ""
    echo "下一步："
    echo "1. 配置SSH密钥认证"
    echo "2. 创建 .env.production 文件"
    echo "3. 运行部署脚本: ./scripts/deploy-production.sh"
    echo ""
}

main
