package postgres

import (
	"context"

	"github.com/qiudl/bblearning-backend/internal/domain/models"
	"gorm.io/gorm"
)

// AIConversationRepository AI对话记录仓库
type AIConversationRepository struct {
	db *gorm.DB
}

// NewAIConversationRepository 创建AI对话记录仓库
func NewAIConversationRepository(db *gorm.DB) *AIConversationRepository {
	return &AIConversationRepository{db: db}
}

// Create 创建对话记录
func (r *AIConversationRepository) Create(ctx context.Context, conversation *models.AIConversation) error {
	return r.db.WithContext(ctx).Create(conversation).Error
}

// FindByID 根据ID查询对话记录
func (r *AIConversationRepository) FindByID(ctx context.Context, id uint) (*models.AIConversation, error) {
	var conversation models.AIConversation
	err := r.db.WithContext(ctx).First(&conversation, id).Error
	if err != nil {
		return nil, err
	}
	return &conversation, nil
}

// FindRecentByUserID 获取用户最近的对话记录
func (r *AIConversationRepository) FindRecentByUserID(ctx context.Context, userID uint, limit int) ([]*models.AIConversation, error) {
	var conversations []*models.AIConversation
	err := r.db.WithContext(ctx).
		Where("user_id = ?", userID).
		Order("created_at DESC").
		Limit(limit).
		Find(&conversations).Error
	if err != nil {
		return nil, err
	}

	// Reverse to get chronological order (oldest first)
	for i, j := 0, len(conversations)-1; i < j; i, j = i+1, j-1 {
		conversations[i], conversations[j] = conversations[j], conversations[i]
	}

	return conversations, nil
}

// FindByUserIDAndQuestionID 查询特定题目的对话记录
func (r *AIConversationRepository) FindByUserIDAndQuestionID(ctx context.Context, userID uint, questionID uint, limit int) ([]*models.AIConversation, error) {
	var conversations []*models.AIConversation
	err := r.db.WithContext(ctx).
		Where("user_id = ? AND question_id = ?", userID, questionID).
		Order("created_at ASC").
		Limit(limit).
		Find(&conversations).Error
	if err != nil {
		return nil, err
	}
	return conversations, nil
}

// CountByUserID 统计用户对话数量
func (r *AIConversationRepository) CountByUserID(ctx context.Context, userID uint) (int64, error) {
	var count int64
	err := r.db.WithContext(ctx).
		Model(&models.AIConversation{}).
		Where("user_id = ?", userID).
		Count(&count).Error
	return count, err
}

// DeleteByUserID 删除用户的对话记录
func (r *AIConversationRepository) DeleteByUserID(ctx context.Context, userID uint) error {
	return r.db.WithContext(ctx).
		Where("user_id = ?", userID).
		Delete(&models.AIConversation{}).Error
}

// DeleteOldConversations 删除超过指定天数的对话记录
func (r *AIConversationRepository) DeleteOldConversations(ctx context.Context, days int) error {
	return r.db.WithContext(ctx).
		Where("created_at < NOW() - INTERVAL '? days'", days).
		Delete(&models.AIConversation{}).Error
}

// List 分页查询对话记录
func (r *AIConversationRepository) List(ctx context.Context, userID uint, limit, offset int) ([]*models.AIConversation, int64, error) {
	var conversations []*models.AIConversation
	var total int64

	query := r.db.WithContext(ctx).Model(&models.AIConversation{}).Where("user_id = ?", userID)

	if err := query.Count(&total).Error; err != nil {
		return nil, 0, err
	}

	err := query.Order("created_at DESC").
		Limit(limit).
		Offset(offset).
		Find(&conversations).Error

	return conversations, total, err
}

// Update 更新对话记录
func (r *AIConversationRepository) Update(ctx context.Context, conversation *models.AIConversation) error {
	return r.db.WithContext(ctx).Save(conversation).Error
}

// Delete 删除对话记录
func (r *AIConversationRepository) Delete(ctx context.Context, id uint) error {
	return r.db.WithContext(ctx).Delete(&models.AIConversation{}, id).Error
}
