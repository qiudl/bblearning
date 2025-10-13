# API密钥加密存储使用指南

## 概述

BBLearning使用AES-256-GCM加密算法安全地存储DeepSeek等AI服务的API密钥，确保密钥不以明文形式存储在配置文件或数据库中。

## 快速开始

### 1. 生成主加密密钥

```bash
cd backend
./scripts/generate-master-key.sh
```

这将生成一个64字符的hex编码密钥。将输出的`ENCRYPTION_MASTER_KEY`添加到`.env.production`文件中。

### 2. 运行数据库迁移

```bash
make migrate-up
```

这将创建`api_keys`和`api_key_audit_logs`表。

### 3. 添加DeepSeek API密钥

#### 方法1: 使用CLI工具

```bash
# 编译CLI工具
go build -o bin/apikey ./cmd/apikey

# 添加密钥
./bin/apikey -action=add \
  -provider=deepseek \
  -name=default \
  -key="sk-your-deepseek-api-key" \
  -desc="DeepSeek生产环境密钥" \
  -priority=100

# 列出所有密钥
./bin/apikey -action=list

# 测试解密
./bin/apikey -action=test -provider=deepseek -name=default
```

#### 方法2: 使用HTTP API

```bash
curl -X POST https://api.bblearning.joylodging.com/api/v1/admin/api-keys \
  -H "Authorization: Bearer YOUR_ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "provider": "deepseek",
    "key_name": "default",
    "api_key": "sk-your-deepseek-api-key",
    "description": "DeepSeek生产环境密钥",
    "priority": 100
  }'
```

## 配置说明

### 环境变量

在`.env.production`中添加：

```env
# API密钥加密主密钥（必需）
ENCRYPTION_MASTER_KEY=your-64-char-hex-master-key

# DeepSeek配置
DEEPSEEK_BASE_URL=https://api.deepseek.com/v1
DEEPSEEK_MODEL=deepseek-chat
DEEPSEEK_MAX_TOKENS=2000
DEEPSEEK_TIMEOUT=30
```

**重要提示**：
- `ENCRYPTION_MASTER_KEY`必须是64个hex字符（32字节）
- 不要将主密钥提交到Git
- 生产环境建议使用密钥管理服务（AWS KMS、HashiCorp Vault等）

## API接口

### 管理员接口

所有接口需要管理员权限。

#### 1. 创建/更新API密钥

```http
POST /api/v1/admin/api-keys
Content-Type: application/json
Authorization: Bearer {admin_token}

{
  "provider": "deepseek",
  "key_name": "default",
  "api_key": "sk-xxxxx",
  "description": "描述信息",
  "priority": 100
}
```

**响应**：
```json
{
  "code": 0,
  "message": "API密钥保存成功",
  "data": {
    "id": 1,
    "provider": "deepseek",
    "key_name": "default",
    "is_active": true,
    "priority": 100,
    "created_at": "2025-01-13T10:00:00Z"
  }
}
```

#### 2. 列出API密钥

```http
GET /api/v1/admin/api-keys?provider=deepseek
Authorization: Bearer {admin_token}
```

**响应**：
```json
{
  "code": 0,
  "data": [
    {
      "id": 1,
      "provider": "deepseek",
      "key_name": "default",
      "is_active": true,
      "priority": 100,
      "description": "DeepSeek生产环境密钥",
      "usage_count": 1523,
      "created_at": "2025-01-13T10:00:00Z",
      "last_used_at": "2025-01-14T15:30:00Z"
    }
  ]
}
```

#### 3. 更新密钥状态

```http
PUT /api/v1/admin/api-keys/{id}/status
Content-Type: application/json
Authorization: Bearer {admin_token}

{
  "is_active": false
}
```

#### 4. 删除API密钥

```http
DELETE /api/v1/admin/api-keys/{id}
Authorization: Bearer {admin_token}
```

#### 5. 查看审计日志

```http
GET /api/v1/admin/api-keys/{id}/audit-logs?limit=20&offset=0
Authorization: Bearer {admin_token}
```

## 在代码中使用

### 获取解密的API密钥

```go
import (
    "github.com/qiudl/bblearning-backend/internal/service"
    "github.com/qiudl/bblearning-backend/internal/pkg/crypto"
)

// 在AI服务中
func (s *AIService) callDeepSeek(ctx context.Context) error {
    // 从数据库获取解密的API密钥
    apiKey, err := s.apiKeyService.GetDecrypted(ctx, "deepseek", "default")
    if err != nil {
        return fmt.Errorf("failed to get API key: %w", err)
    }

    // 使用完毕后清除内存
    defer crypto.ClearString(&apiKey)

    // 使用API密钥调用DeepSeek
    client := openai.NewClientWithConfig(openai.ClientConfig{
        APIKey:  apiKey,
        BaseURL: os.Getenv("DEEPSEEK_BASE_URL"),
    })

    // ... 调用API

    return nil
}
```

### 密钥缓存

Service层自动实现了密钥缓存（TTL: 5分钟），避免频繁解密操作：
- 首次获取密钥时从数据库解密
- 后续5分钟内直接从内存缓存获取
- 更新或禁用密钥时自动清除缓存

## 安全特性

### 1. 加密算法
- **AES-256-GCM**: 认证加密（AEAD）
- **PBKDF2**: 密钥派生（100,000次迭代）
- **随机盐值**: 每条记录独立32字节盐值
- **随机Nonce**: 每次加密使用12字节随机nonce

### 2. 密钥管理
- 主密钥与加密数据分离存储
- 支持主备密钥切换（priority字段）
- 密钥状态管理（启用/禁用）

### 3. 审计追踪
- 完整的操作审计日志
- 记录创建/更新/删除操作
- 操作者和时间戳记录
- 密钥使用统计

### 4. 内存安全
- 明文密钥使用完毕立即清除
- 密钥不出现在日志中
- API响应不包含密钥明文

## 数据库表结构

### api_keys 表

| 字段 | 类型 | 说明 |
|------|------|------|
| id | BIGSERIAL | 主键 |
| provider | VARCHAR(50) | 服务提供商 |
| key_name | VARCHAR(100) | 密钥名称 |
| encrypted_key | TEXT | 加密后的密钥 |
| encryption_salt | VARCHAR(64) | 加密盐值(hex) |
| encryption_nonce | VARCHAR(64) | GCM nonce(hex) |
| is_active | BOOLEAN | 是否启用 |
| priority | INTEGER | 优先级 |
| description | TEXT | 描述 |
| usage_count | BIGINT | 使用次数 |
| last_used_at | TIMESTAMP | 最后使用时间 |
| created_at | TIMESTAMP | 创建时间 |
| updated_at | TIMESTAMP | 更新时间 |

### api_key_audit_logs 表

| 字段 | 类型 | 说明 |
|------|------|------|
| id | BIGSERIAL | 主键 |
| api_key_id | BIGINT | API密钥ID |
| action | VARCHAR(20) | 操作类型 |
| operator_id | BIGINT | 操作者ID |
| operator_ip | VARCHAR(45) | 操作者IP |
| old_value | JSONB | 变更前的值 |
| new_value | JSONB | 变更后的值 |
| created_at | TIMESTAMP | 创建时间 |

## 故障排除

### 问题1: 解密失败

```
Error: failed to decrypt API key: decryption failed
```

**原因**: 主密钥不正确或密钥数据损坏

**解决**:
1. 检查`ENCRYPTION_MASTER_KEY`是否正确
2. 如果更换了主密钥，需要重新添加所有API密钥

### 问题2: 密钥不存在

```
Error: API key not found for provider deepseek with name default
```

**解决**:
```bash
# 使用CLI工具添加密钥
./bin/apikey -action=add -provider=deepseek -name=default -key="sk-xxx"
```

### 问题3: 密钥被禁用

```
Error: API key is inactive
```

**解决**:
```bash
# 通过API启用密钥
curl -X PUT https://api.bblearning.joylodging.com/api/v1/admin/api-keys/{id}/status \
  -H "Authorization: Bearer {token}" \
  -d '{"is_active": true}'
```

## 最佳实践

### 1. 主密钥管理
- ✅ 使用密钥管理服务（KMS）
- ✅ 定期轮换主密钥
- ✅ 备份主密钥到安全位置
- ❌ 不要提交到Git
- ❌ 不要硬编码在代码中

### 2. API密钥管理
- ✅ 为不同环境使用不同的密钥
- ✅ 设置密钥描述和标签
- ✅ 定期检查使用统计
- ✅ 及时删除过期密钥

### 3. 安全配置
- ✅ 限制管理接口访问权限
- ✅ 启用操作审计日志
- ✅ 监控异常访问
- ✅ 配置告警通知

### 4. 性能优化
- ✅ 利用内置缓存减少解密次数
- ✅ 使用主备密钥实现高可用
- ✅ 监控解密性能

## 技术细节

### 加密流程

```
明文API密钥
    ↓
生成随机Salt(32字节)
    ↓
PBKDF2(主密钥, Salt, 100000次) → 派生密钥(32字节)
    ↓
生成随机Nonce(12字节)
    ↓
AES-256-GCM(派生密钥, Nonce, 明文) → 密文
    ↓
存储: (密文, Salt, Nonce) → 数据库
```

### 解密流程

```
数据库 → (密文, Salt, Nonce)
    ↓
PBKDF2(主密钥, Salt, 100000次) → 派生密钥
    ↓
AES-256-GCM解密(派生密钥, Nonce, 密文) → 明文
    ↓
缓存5分钟
    ↓
返回明文API密钥
```

## 性能基准

加密性能（M1 Pro）:
- 加密: ~26,000 ops/sec
- 解密: ~25,000 ops/sec
- 盐值生成: ~2,500,000 ops/sec

实际使用中由于缓存机制，解密操作很少触发。

## 相关文档

- [技术架构设计](../docs/architecture/tech-architecture.md)
- [API接口规范](../docs/architecture/api-specification.md)
- [部署指南](../docs/DEPLOYMENT-GUIDE.md)

## 联系支持

如有问题，请查看项目文档或提交Issue。
