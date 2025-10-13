package service

import (
	"context"
	"database/sql"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"sync"
	"time"

	"github.com/qiudl/bblearning-backend/internal/domain"
	"github.com/qiudl/bblearning-backend/internal/pkg/crypto"
	"github.com/qiudl/bblearning-backend/internal/repository"
	"gorm.io/gorm"
)

// APIKeyService API密钥服务接口
type APIKeyService interface {
	Create(ctx context.Context, req *domain.CreateAPIKeyRequest, operatorID int64) (*domain.APIKeyDTO, error)
	GetDecrypted(ctx context.Context, provider, keyName string) (string, error)
	GetByID(ctx context.Context, id int64) (*domain.APIKeyDTO, error)
	List(ctx context.Context, provider string) ([]*domain.APIKeyDTO, error)
	UpdateStatus(ctx context.Context, id int64, isActive bool, operatorID int64) error
	Delete(ctx context.Context, id int64, operatorID int64) error
	GetAuditLogs(ctx context.Context, id int64, limit, offset int) ([]*domain.APIKeyAuditLog, error)
}

// DecryptedKeyCache 解密密钥缓存
type DecryptedKeyCache struct {
	plaintext string
	expiresAt time.Time
}

type apiKeyService struct {
	repo      repository.APIKeyRepository
	encryptor crypto.Encryptor
	keyCache  sync.Map // 缓存解密后的密钥
	cacheTTL  time.Duration
}

// NewAPIKeyService 创建API密钥服务
func NewAPIKeyService(repo repository.APIKeyRepository, encryptor crypto.Encryptor) APIKeyService {
	return &apiKeyService{
		repo:      repo,
		encryptor: encryptor,
		cacheTTL:  5 * time.Minute, // 缓存5分钟
	}
}

// Create 创建或更新API密钥
func (s *apiKeyService) Create(ctx context.Context, req *domain.CreateAPIKeyRequest, operatorID int64) (*domain.APIKeyDTO, error) {
	// 检查是否已存在
	existing, err := s.repo.GetByProviderAndName(ctx, req.Provider, req.KeyName)
	if err == nil && existing != nil {
		// 已存在，执行更新
		return s.update(ctx, existing, req, operatorID)
	}

	// 生成盐值
	salt, err := s.encryptor.GenerateSalt()
	if err != nil {
		return nil, fmt.Errorf("failed to generate salt: %w", err)
	}

	// 加密API密钥
	encryptedKey, nonce, err := s.encryptor.Encrypt(req.APIKey, salt)
	if err != nil {
		return nil, fmt.Errorf("failed to encrypt API key: %w", err)
	}

	// 创建记录
	now := time.Now()
	apiKey := &domain.APIKey{
		Provider:        req.Provider,
		KeyName:         req.KeyName,
		EncryptedKey:    encryptedKey,
		EncryptionSalt:  hex.EncodeToString(salt),
		EncryptionNonce: nonce,
		IsActive:        true,
		Priority:        req.Priority,
		Description:     req.Description,
		CreatedAt:       now,
		UpdatedAt:       now,
		CreatedBy:       sql.NullInt64{Int64: operatorID, Valid: true},
		UpdatedBy:       sql.NullInt64{Int64: operatorID, Valid: true},
	}

	if err := s.repo.Create(ctx, apiKey); err != nil {
		return nil, fmt.Errorf("failed to create API key: %w", err)
	}

	// 记录审计日志
	_ = s.createAuditLog(ctx, apiKey.ID, domain.AuditActionCreate, operatorID, nil, apiKey)

	return apiKey.ToDTO(), nil
}

// update 更新现有API密钥
func (s *apiKeyService) update(ctx context.Context, existing *domain.APIKey, req *domain.CreateAPIKeyRequest, operatorID int64) (*domain.APIKeyDTO, error) {
	oldKey := *existing

	// 生成新的盐值和nonce
	salt, _ := s.encryptor.GenerateSalt()
	encryptedKey, nonce, err := s.encryptor.Encrypt(req.APIKey, salt)
	if err != nil {
		return nil, fmt.Errorf("failed to encrypt API key: %w", err)
	}

	// 更新字段
	existing.EncryptedKey = encryptedKey
	existing.EncryptionSalt = hex.EncodeToString(salt)
	existing.EncryptionNonce = nonce
	existing.Description = req.Description
	existing.Priority = req.Priority
	existing.UpdatedAt = time.Now()
	existing.UpdatedBy = sql.NullInt64{Int64: operatorID, Valid: true}

	if err := s.repo.Update(ctx, existing); err != nil {
		return nil, fmt.Errorf("failed to update API key: %w", err)
	}

	// 清除缓存
	s.clearCache(existing.Provider, existing.KeyName)

	// 记录审计日志
	_ = s.createAuditLog(ctx, existing.ID, domain.AuditActionUpdate, operatorID, &oldKey, existing)

	return existing.ToDTO(), nil
}

// GetDecrypted 获取解密后的API密钥
func (s *apiKeyService) GetDecrypted(ctx context.Context, provider, keyName string) (string, error) {
	// 尝试从缓存获取
	cacheKey := fmt.Sprintf("%s:%s", provider, keyName)
	if cached, ok := s.keyCache.Load(cacheKey); ok {
		cachedData := cached.(*DecryptedKeyCache)
		if time.Now().Before(cachedData.expiresAt) {
			return cachedData.plaintext, nil
		}
		// 缓存过期，删除
		s.keyCache.Delete(cacheKey)
	}

	// 从数据库获取
	apiKey, err := s.repo.GetByProviderAndName(ctx, provider, keyName)
	if err != nil {
		if err == gorm.ErrRecordNotFound {
			return "", fmt.Errorf("API key not found for provider %s with name %s", provider, keyName)
		}
		return "", err
	}

	// 检查是否激活
	if !apiKey.IsActive {
		return "", fmt.Errorf("API key is inactive")
	}

	// 解密
	salt, err := hex.DecodeString(apiKey.EncryptionSalt)
	if err != nil {
		return "", fmt.Errorf("invalid encryption salt: %w", err)
	}

	plaintext, err := s.encryptor.Decrypt(apiKey.EncryptedKey, apiKey.EncryptionNonce, salt)
	if err != nil {
		return "", fmt.Errorf("failed to decrypt API key: %w", err)
	}

	// 更新使用统计（异步）
	go func() {
		_ = s.repo.IncrementUsageCount(context.Background(), apiKey.ID)
	}()

	// 缓存解密结果
	s.keyCache.Store(cacheKey, &DecryptedKeyCache{
		plaintext: plaintext,
		expiresAt: time.Now().Add(s.cacheTTL),
	})

	return plaintext, nil
}

// GetByID 根据ID获取（不包含明文密钥）
func (s *apiKeyService) GetByID(ctx context.Context, id int64) (*domain.APIKeyDTO, error) {
	apiKey, err := s.repo.GetByID(ctx, id)
	if err != nil {
		return nil, err
	}
	return apiKey.ToDTO(), nil
}

// List 列出API密钥
func (s *apiKeyService) List(ctx context.Context, provider string) ([]*domain.APIKeyDTO, error) {
	apiKeys, err := s.repo.ListByProvider(ctx, provider, true)
	if err != nil {
		return nil, err
	}

	dtos := make([]*domain.APIKeyDTO, len(apiKeys))
	for i, key := range apiKeys {
		dtos[i] = key.ToDTO()
	}
	return dtos, nil
}

// UpdateStatus 更新状态
func (s *apiKeyService) UpdateStatus(ctx context.Context, id int64, isActive bool, operatorID int64) error {
	apiKey, err := s.repo.GetByID(ctx, id)
	if err != nil {
		return err
	}

	oldKey := *apiKey
	apiKey.IsActive = isActive
	apiKey.UpdatedAt = time.Now()
	apiKey.UpdatedBy = sql.NullInt64{Int64: operatorID, Valid: true}

	if err := s.repo.Update(ctx, apiKey); err != nil {
		return err
	}

	// 清除缓存
	s.clearCache(apiKey.Provider, apiKey.KeyName)

	// 审计日志
	action := domain.AuditActionActivate
	if !isActive {
		action = domain.AuditActionDeactivate
	}
	_ = s.createAuditLog(ctx, apiKey.ID, action, operatorID, &oldKey, apiKey)

	return nil
}

// Delete 删除API密钥
func (s *apiKeyService) Delete(ctx context.Context, id int64, operatorID int64) error {
	apiKey, err := s.repo.GetByID(ctx, id)
	if err != nil {
		return err
	}

	// 审计日志
	_ = s.createAuditLog(ctx, apiKey.ID, domain.AuditActionDelete, operatorID, apiKey, nil)

	// 删除
	if err := s.repo.Delete(ctx, id); err != nil {
		return err
	}

	// 清除缓存
	s.clearCache(apiKey.Provider, apiKey.KeyName)

	return nil
}

// GetAuditLogs 获取审计日志
func (s *apiKeyService) GetAuditLogs(ctx context.Context, id int64, limit, offset int) ([]*domain.APIKeyAuditLog, error) {
	if limit <= 0 {
		limit = 20
	}
	if limit > 100 {
		limit = 100
	}
	return s.repo.ListAuditLogs(ctx, id, limit, offset)
}

// clearCache 清除缓存
func (s *apiKeyService) clearCache(provider, keyName string) {
	cacheKey := fmt.Sprintf("%s:%s", provider, keyName)
	s.keyCache.Delete(cacheKey)
}

// createAuditLog 创建审计日志
func (s *apiKeyService) createAuditLog(ctx context.Context, apiKeyID int64, action domain.AuditAction, operatorID int64, oldValue, newValue *domain.APIKey) error {
	log := &domain.APIKeyAuditLog{
		APIKeyID:   sql.NullInt64{Int64: apiKeyID, Valid: true},
		Action:     string(action),
		OperatorID: sql.NullInt64{Int64: operatorID, Valid: true},
		CreatedAt:  time.Now(),
	}

	// 存储脱敏后的旧值和新值（不包含密钥明文）
	if oldValue != nil {
		oldDTO := oldValue.ToDTO()
		oldJSON, _ := json.Marshal(oldDTO)
		log.OldValue = sql.NullString{String: string(oldJSON), Valid: true}
	}

	if newValue != nil {
		newDTO := newValue.ToDTO()
		newJSON, _ := json.Marshal(newDTO)
		log.NewValue = sql.NullString{String: string(newJSON), Valid: true}
	}

	return s.repo.CreateAuditLog(ctx, log)
}
