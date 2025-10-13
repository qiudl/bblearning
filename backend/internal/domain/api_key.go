package domain

import (
	"database/sql"
	"time"
)

// APIKey API密钥模型（加密存储）
type APIKey struct {
	ID               int64          `json:"id" gorm:"primaryKey"`
	Provider         string         `json:"provider" gorm:"type:varchar(50);not null;index:idx_api_keys_provider_active"`
	KeyName          string         `json:"key_name" gorm:"type:varchar(100);not null;uniqueIndex:uk_api_keys_provider_name"`
	EncryptedKey     string         `json:"-" gorm:"type:text;not null"` // 加密后的密钥，不返回给前端
	EncryptionSalt   string         `json:"-" gorm:"type:varchar(64);not null"` // 加密盐值，不返回给前端
	EncryptionNonce  string         `json:"-" gorm:"type:varchar(64);not null"` // GCM nonce，不返回给前端
	IsActive         bool           `json:"is_active" gorm:"default:true;not null;index:idx_api_keys_active"`
	Priority         int            `json:"priority" gorm:"default:0;index:idx_api_keys_priority"`
	Description      string         `json:"description" gorm:"type:text"`
	Metadata         sql.NullString `json:"metadata" gorm:"type:jsonb"` // JSONB存储额外元数据
	CreatedAt        time.Time      `json:"created_at" gorm:"not null"`
	UpdatedAt        time.Time      `json:"updated_at" gorm:"not null"`
	CreatedBy        sql.NullInt64  `json:"created_by"`
	UpdatedBy        sql.NullInt64  `json:"updated_by"`
	LastUsedAt       sql.NullTime   `json:"last_used_at"`
	UsageCount       int64          `json:"usage_count" gorm:"default:0"`
}

// TableName 指定表名
func (APIKey) TableName() string {
	return "api_keys"
}

// APIKeyAuditLog API密钥操作审计日志
type APIKeyAuditLog struct {
	ID         int64          `json:"id" gorm:"primaryKey"`
	APIKeyID   sql.NullInt64  `json:"api_key_id" gorm:"index:idx_api_key_audit_logs_key_id"`
	Action     string         `json:"action" gorm:"type:varchar(20);not null;index:idx_api_key_audit_logs_action"`
	OperatorID sql.NullInt64  `json:"operator_id" gorm:"index:idx_api_key_audit_logs_operator"`
	OperatorIP string         `json:"operator_ip" gorm:"type:varchar(45)"`
	OldValue   sql.NullString `json:"old_value" gorm:"type:jsonb"` // 脱敏后的旧值
	NewValue   sql.NullString `json:"new_value" gorm:"type:jsonb"` // 脱敏后的新值
	CreatedAt  time.Time      `json:"created_at" gorm:"not null;index:idx_api_key_audit_logs_created_at"`
	UserAgent  string         `json:"user_agent" gorm:"type:text"`
	RequestID  string         `json:"request_id" gorm:"type:varchar(100)"`
}

// TableName 指定表名
func (APIKeyAuditLog) TableName() string {
	return "api_key_audit_logs"
}

// APIKeyDTO 用于API响应的DTO（不包含敏感信息）
type APIKeyDTO struct {
	ID          int64      `json:"id"`
	Provider    string     `json:"provider"`
	KeyName     string     `json:"key_name"`
	IsActive    bool       `json:"is_active"`
	Priority    int        `json:"priority"`
	Description string     `json:"description"`
	CreatedAt   time.Time  `json:"created_at"`
	UpdatedAt   time.Time  `json:"updated_at"`
	LastUsedAt  *time.Time `json:"last_used_at,omitempty"`
	UsageCount  int64      `json:"usage_count"`
}

// ToDTO 转换为DTO（隐藏敏感信息）
func (a *APIKey) ToDTO() *APIKeyDTO {
	dto := &APIKeyDTO{
		ID:          a.ID,
		Provider:    a.Provider,
		KeyName:     a.KeyName,
		IsActive:    a.IsActive,
		Priority:    a.Priority,
		Description: a.Description,
		CreatedAt:   a.CreatedAt,
		UpdatedAt:   a.UpdatedAt,
		UsageCount:  a.UsageCount,
	}

	if a.LastUsedAt.Valid {
		dto.LastUsedAt = &a.LastUsedAt.Time
	}

	return dto
}

// CreateAPIKeyRequest 创建/更新API密钥请求
type CreateAPIKeyRequest struct {
	Provider    string `json:"provider" binding:"required,oneof=deepseek openai anthropic gemini"`
	KeyName     string `json:"key_name" binding:"required,min=1,max=100"`
	APIKey      string `json:"api_key" binding:"required,min=10"`
	Description string `json:"description" binding:"max=500"`
	Priority    int    `json:"priority" binding:"min=0,max=100"`
}

// UpdateAPIKeyStatusRequest 更新API密钥状态请求
type UpdateAPIKeyStatusRequest struct {
	IsActive bool `json:"is_active"`
}

// AuditAction 审计操作类型
type AuditAction string

const (
	AuditActionCreate     AuditAction = "create"
	AuditActionUpdate     AuditAction = "update"
	AuditActionDelete     AuditAction = "delete"
	AuditActionActivate   AuditAction = "activate"
	AuditActionDeactivate AuditAction = "deactivate"
	AuditActionUse        AuditAction = "use" // 使用密钥
)

// Provider 支持的AI服务提供商
type Provider string

const (
	ProviderDeepSeek   Provider = "deepseek"
	ProviderOpenAI     Provider = "openai"
	ProviderAnthropic  Provider = "anthropic"
	ProviderGemini     Provider = "gemini"
)

// IsValidProvider 检查是否是有效的提供商
func IsValidProvider(provider string) bool {
	switch Provider(provider) {
	case ProviderDeepSeek, ProviderOpenAI, ProviderAnthropic, ProviderGemini:
		return true
	default:
		return false
	}
}
