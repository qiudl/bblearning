package repository

import (
	"context"

	"github.com/qiudl/bblearning-backend/internal/domain"
	"gorm.io/gorm"
)

// APIKeyRepository API密钥仓储接口
type APIKeyRepository interface {
	Create(ctx context.Context, apiKey *domain.APIKey) error
	GetByID(ctx context.Context, id int64) (*domain.APIKey, error)
	GetByProviderAndName(ctx context.Context, provider, keyName string) (*domain.APIKey, error)
	GetActiveByProvider(ctx context.Context, provider string) ([]*domain.APIKey, error)
	Update(ctx context.Context, apiKey *domain.APIKey) error
	Delete(ctx context.Context, id int64) error
	ListByProvider(ctx context.Context, provider string, includeInactive bool) ([]*domain.APIKey, error)
	IncrementUsageCount(ctx context.Context, id int64) error

	// 审计日志
	CreateAuditLog(ctx context.Context, log *domain.APIKeyAuditLog) error
	ListAuditLogs(ctx context.Context, apiKeyID int64, limit, offset int) ([]*domain.APIKeyAuditLog, error)
}

type apiKeyRepository struct {
	db *gorm.DB
}

// NewAPIKeyRepository 创建API密钥仓储
func NewAPIKeyRepository(db *gorm.DB) APIKeyRepository {
	return &apiKeyRepository{db: db}
}

// Create 创建API密钥
func (r *apiKeyRepository) Create(ctx context.Context, apiKey *domain.APIKey) error {
	return r.db.WithContext(ctx).Create(apiKey).Error
}

// GetByID 根据ID获取
func (r *apiKeyRepository) GetByID(ctx context.Context, id int64) (*domain.APIKey, error) {
	var apiKey domain.APIKey
	err := r.db.WithContext(ctx).First(&apiKey, id).Error
	if err != nil {
		return nil, err
	}
	return &apiKey, nil
}

// GetByProviderAndName 根据提供商和名称获取
func (r *apiKeyRepository) GetByProviderAndName(ctx context.Context, provider, keyName string) (*domain.APIKey, error) {
	var apiKey domain.APIKey
	err := r.db.WithContext(ctx).
		Where("provider = ? AND key_name = ?", provider, keyName).
		First(&apiKey).Error
	if err != nil {
		return nil, err
	}
	return &apiKey, nil
}

// GetActiveByProvider 获取指定提供商的所有活跃密钥（按优先级排序）
func (r *apiKeyRepository) GetActiveByProvider(ctx context.Context, provider string) ([]*domain.APIKey, error) {
	var apiKeys []*domain.APIKey
	err := r.db.WithContext(ctx).
		Where("provider = ? AND is_active = ?", provider, true).
		Order("priority DESC, created_at ASC").
		Find(&apiKeys).Error
	return apiKeys, err
}

// Update 更新API密钥
func (r *apiKeyRepository) Update(ctx context.Context, apiKey *domain.APIKey) error {
	return r.db.WithContext(ctx).Save(apiKey).Error
}

// Delete 删除API密钥
func (r *apiKeyRepository) Delete(ctx context.Context, id int64) error {
	return r.db.WithContext(ctx).Delete(&domain.APIKey{}, id).Error
}

// ListByProvider 列出指定提供商的所有密钥
func (r *apiKeyRepository) ListByProvider(ctx context.Context, provider string, includeInactive bool) ([]*domain.APIKey, error) {
	query := r.db.WithContext(ctx)

	if provider != "" {
		query = query.Where("provider = ?", provider)
	}

	if !includeInactive {
		query = query.Where("is_active = ?", true)
	}

	var apiKeys []*domain.APIKey
	err := query.Order("priority DESC, created_at DESC").Find(&apiKeys).Error
	return apiKeys, err
}

// IncrementUsageCount 增加使用次数
func (r *apiKeyRepository) IncrementUsageCount(ctx context.Context, id int64) error {
	return r.db.WithContext(ctx).
		Model(&domain.APIKey{}).
		Where("id = ?", id).
		Updates(map[string]interface{}{
			"usage_count":  gorm.Expr("usage_count + 1"),
			"last_used_at": gorm.Expr("NOW()"),
		}).Error
}

// CreateAuditLog 创建审计日志
func (r *apiKeyRepository) CreateAuditLog(ctx context.Context, log *domain.APIKeyAuditLog) error {
	return r.db.WithContext(ctx).Create(log).Error
}

// ListAuditLogs 列出审计日志
func (r *apiKeyRepository) ListAuditLogs(ctx context.Context, apiKeyID int64, limit, offset int) ([]*domain.APIKeyAuditLog, error) {
	var logs []*domain.APIKeyAuditLog

	query := r.db.WithContext(ctx).Order("created_at DESC")

	if apiKeyID > 0 {
		query = query.Where("api_key_id = ?", apiKeyID)
	}

	if limit > 0 {
		query = query.Limit(limit)
	}

	if offset > 0 {
		query = query.Offset(offset)
	}

	err := query.Find(&logs).Error
	return logs, err
}
