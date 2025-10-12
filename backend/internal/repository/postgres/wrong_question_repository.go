package postgres

import (
	"context"

	"github.com/qiudl/bblearning-backend/internal/domain/models"
	"gorm.io/gorm"
)

// WrongQuestionRepository 错题仓库
type WrongQuestionRepository struct {
	db *gorm.DB
}

// NewWrongQuestionRepository 创建错题仓库
func NewWrongQuestionRepository(db *gorm.DB) *WrongQuestionRepository {
	return &WrongQuestionRepository{db: db}
}

// Create 创建错题记录
func (r *WrongQuestionRepository) Create(ctx context.Context, wq *models.WrongQuestion) error {
	return r.db.WithContext(ctx).Create(wq).Error
}

// FindByID 根据ID查询错题
func (r *WrongQuestionRepository) FindByID(ctx context.Context, id uint) (*models.WrongQuestion, error) {
	var wq models.WrongQuestion
	err := r.db.WithContext(ctx).Preload("Question").First(&wq, id).Error
	if err != nil {
		return nil, err
	}
	return &wq, nil
}

// FindByUserAndQuestion 根据用户和题目查询错题
func (r *WrongQuestionRepository) FindByUserAndQuestion(ctx context.Context, userID, questionID uint) (*models.WrongQuestion, error) {
	var wq models.WrongQuestion
	err := r.db.WithContext(ctx).
		Where("user_id = ? AND question_id = ?", userID, questionID).
		First(&wq).Error
	if err != nil {
		return nil, err
	}
	return &wq, nil
}

// List 查询错题列表
func (r *WrongQuestionRepository) List(ctx context.Context, filters map[string]interface{}, limit, offset int) ([]*models.WrongQuestion, int64, error) {
	var wrongQuestions []*models.WrongQuestion
	var total int64

	query := r.db.WithContext(ctx).Model(&models.WrongQuestion{})

	// 应用过滤条件
	if userID, ok := filters["user_id"]; ok {
		query = query.Where("user_id = ?", userID)
	}
	if kpID, ok := filters["knowledge_point_id"]; ok {
		query = query.Joins("JOIN questions ON questions.id = wrong_questions.question_id").
			Where("questions.knowledge_point_id = ?", kpID)
	}
	if difficulty, ok := filters["difficulty"]; ok {
		query = query.Joins("JOIN questions ON questions.id = wrong_questions.question_id").
			Where("questions.difficulty = ?", difficulty)
	}

	// 查询总数
	if err := query.Count(&total).Error; err != nil {
		return nil, 0, err
	}

	// 查询列表(预加载Question)
	err := query.
		Preload("Question").
		Order("last_wrong_time DESC").
		Limit(limit).
		Offset(offset).
		Find(&wrongQuestions).Error

	return wrongQuestions, total, err
}

// FindByUserID 根据用户ID查询错题列表
func (r *WrongQuestionRepository) FindByUserID(ctx context.Context, userID uint, limit, offset int) ([]*models.WrongQuestion, int64, error) {
	filters := map[string]interface{}{"user_id": userID}
	return r.List(ctx, filters, limit, offset)
}

// Update 更新错题记录
func (r *WrongQuestionRepository) Update(ctx context.Context, wq *models.WrongQuestion) error {
	return r.db.WithContext(ctx).Save(wq).Error
}

// UpdateFields 更新指定字段
func (r *WrongQuestionRepository) UpdateFields(ctx context.Context, id uint, fields map[string]interface{}) error {
	return r.db.WithContext(ctx).Model(&models.WrongQuestion{}).Where("id = ?", id).Updates(fields).Error
}

// Delete 删除错题记录
func (r *WrongQuestionRepository) Delete(ctx context.Context, id uint) error {
	return r.db.WithContext(ctx).Delete(&models.WrongQuestion{}, id).Error
}

// DeleteByUserAndQuestion 删除用户的某个错题
func (r *WrongQuestionRepository) DeleteByUserAndQuestion(ctx context.Context, userID, questionID uint) error {
	return r.db.WithContext(ctx).
		Where("user_id = ? AND question_id = ?", userID, questionID).
		Delete(&models.WrongQuestion{}).Error
}

// Upsert 创建或更新错题(错误次数+1)
func (r *WrongQuestionRepository) Upsert(ctx context.Context, wq *models.WrongQuestion) error {
	var existing models.WrongQuestion
	err := r.db.WithContext(ctx).
		Where("user_id = ? AND question_id = ?", wq.UserID, wq.QuestionID).
		First(&existing).Error

	if err == gorm.ErrRecordNotFound {
		// 不存在,创建新记录
		return r.Create(ctx, wq)
	}

	if err != nil {
		return err
	}

	// 存在,更新错误次数和时间
	existing.WrongCount++
	existing.LastWrongTime = wq.LastWrongTime
	return r.Update(ctx, &existing)
}

// CountByUser 统计用户错题数量
func (r *WrongQuestionRepository) CountByUser(ctx context.Context, userID uint) (int64, error) {
	var count int64
	err := r.db.WithContext(ctx).
		Model(&models.WrongQuestion{}).
		Where("user_id = ?", userID).
		Count(&count).Error
	return count, err
}

// GetTopWrongQuestions 获取错误次数最多的题目
func (r *WrongQuestionRepository) GetTopWrongQuestions(ctx context.Context, userID uint, limit int) ([]*models.WrongQuestion, error) {
	var wrongQuestions []*models.WrongQuestion
	err := r.db.WithContext(ctx).
		Preload("Question").
		Where("user_id = ?", userID).
		Order("wrong_count DESC, last_wrong_time DESC").
		Limit(limit).
		Find(&wrongQuestions).Error
	return wrongQuestions, err
}
