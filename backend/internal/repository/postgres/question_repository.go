package postgres

import (
	"context"

	"github.com/qiudl/bblearning-backend/internal/domain/models"
	"gorm.io/gorm"
)

// QuestionRepository 题目仓库
type QuestionRepository struct {
	db *gorm.DB
}

// NewQuestionRepository 创建题目仓库
func NewQuestionRepository(db *gorm.DB) *QuestionRepository {
	return &QuestionRepository{db: db}
}

// Create 创建题目
func (r *QuestionRepository) Create(ctx context.Context, question *models.Question) error {
	return r.db.WithContext(ctx).Create(question).Error
}

// FindByID 根据ID查询题目
func (r *QuestionRepository) FindByID(ctx context.Context, id uint) (*models.Question, error) {
	var question models.Question
	err := r.db.WithContext(ctx).First(&question, id).Error
	if err != nil {
		return nil, err
	}
	return &question, nil
}

// List 查询题目列表
func (r *QuestionRepository) List(ctx context.Context, filters map[string]interface{}, limit, offset int) ([]*models.Question, int64, error) {
	var questions []*models.Question
	var total int64

	query := r.db.WithContext(ctx).Model(&models.Question{})

	// 应用过滤条件
	if kpID, ok := filters["knowledge_point_id"]; ok {
		query = query.Where("knowledge_point_id = ?", kpID)
	}
	if qType, ok := filters["type"]; ok {
		query = query.Where("type = ?", qType)
	}
	if difficulty, ok := filters["difficulty"]; ok {
		query = query.Where("difficulty = ?", difficulty)
	}

	// 查询总数
	if err := query.Count(&total).Error; err != nil {
		return nil, 0, err
	}

	// 查询列表
	err := query.
		Order("id DESC").
		Limit(limit).
		Offset(offset).
		Find(&questions).Error

	return questions, total, err
}

// FindByKnowledgePointID 根据知识点ID查询题目
func (r *QuestionRepository) FindByKnowledgePointID(ctx context.Context, kpID uint) ([]*models.Question, error) {
	var questions []*models.Question
	err := r.db.WithContext(ctx).
		Where("knowledge_point_id = ?", kpID).
		Order("difficulty ASC, id DESC").
		Find(&questions).Error
	return questions, err
}

// FindRandomByKnowledgePoint 根据知识点随机查询题目
func (r *QuestionRepository) FindRandomByKnowledgePoint(ctx context.Context, kpID uint, count int, filters map[string]interface{}) ([]*models.Question, error) {
	var questions []*models.Question

	query := r.db.WithContext(ctx).
		Where("knowledge_point_id = ?", kpID)

	// 应用过滤条件
	if qType, ok := filters["type"]; ok {
		query = query.Where("type = ?", qType)
	}
	if difficulty, ok := filters["difficulty"]; ok {
		query = query.Where("difficulty = ?", difficulty)
	}

	err := query.
		Order("RANDOM()").
		Limit(count).
		Find(&questions).Error

	return questions, err
}

// Update 更新题目
func (r *QuestionRepository) Update(ctx context.Context, question *models.Question) error {
	return r.db.WithContext(ctx).Save(question).Error
}

// UpdateFields 更新指定字段
func (r *QuestionRepository) UpdateFields(ctx context.Context, id uint, fields map[string]interface{}) error {
	return r.db.WithContext(ctx).Model(&models.Question{}).Where("id = ?", id).Updates(fields).Error
}

// Delete 删除题目
func (r *QuestionRepository) Delete(ctx context.Context, id uint) error {
	return r.db.WithContext(ctx).Delete(&models.Question{}, id).Error
}

// CountByKnowledgePoint 统计知识点下的题目数量
func (r *QuestionRepository) CountByKnowledgePoint(ctx context.Context, kpID uint) (int64, error) {
	var count int64
	err := r.db.WithContext(ctx).
		Model(&models.Question{}).
		Where("knowledge_point_id = ?", kpID).
		Count(&count).Error
	return count, err
}

// FindByIDs 根据ID列表批量查询题目
func (r *QuestionRepository) FindByIDs(ctx context.Context, ids []uint) ([]*models.Question, error) {
	var questions []*models.Question
	err := r.db.WithContext(ctx).
		Where("id IN ?", ids).
		Find(&questions).Error
	return questions, err
}
