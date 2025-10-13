#!/bin/bash

# BBLearning - 生成API密钥加密主密钥
# 此脚本生成一个32字节（256位）的随机主密钥，用于AES-256-GCM加密

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}生成API密钥加密主密钥${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# 生成32字节的随机hex密钥
MASTER_KEY=$(openssl rand -hex 32)

if [ -z "$MASTER_KEY" ]; then
    echo -e "${YELLOW}错误: 生成密钥失败${NC}"
    exit 1
fi

echo -e "${GREEN}✓ 主密钥生成成功${NC}"
echo ""
echo "请将以下环境变量添加到您的 .env.production 文件中："
echo ""
echo -e "${YELLOW}ENCRYPTION_MASTER_KEY=${MASTER_KEY}${NC}"
echo ""
echo "注意事项："
echo "1. 这个密钥非常重要，丢失后将无法解密已存储的API密钥"
echo "2. 请妥善保管此密钥，不要提交到版本控制系统"
echo "3. 生产环境建议使用密钥管理服务（如AWS KMS、HashiCorp Vault）"
echo "4. 定期轮换主密钥以提高安全性"
echo ""
echo -e "${GREEN}========================================${NC}"
