package postgres

import (
	"context"

	"github.com/qiudl/bblearning-backend/internal/domain/models"
	"gorm.io/gorm"
)

// LearningProgressRepository 学习进度仓库
type LearningProgressRepository struct {
	db *gorm.DB
}

// NewLearningProgressRepository 创建学习进度仓库
func NewLearningProgressRepository(db *gorm.DB) *LearningProgressRepository {
	return &LearningProgressRepository{db: db}
}

// Create 创建学习进度
func (r *LearningProgressRepository) Create(ctx context.Context, progress *models.LearningProgress) error {
	return r.db.WithContext(ctx).Create(progress).Error
}

// FindByID 根据ID查询学习进度
func (r *LearningProgressRepository) FindByID(ctx context.Context, id uint) (*models.LearningProgress, error) {
	var progress models.LearningProgress
	err := r.db.WithContext(ctx).First(&progress, id).Error
	if err != nil {
		return nil, err
	}
	return &progress, nil
}

// FindByUserAndKnowledgePoint 根据用户和知识点查询学习进度
func (r *LearningProgressRepository) FindByUserAndKnowledgePoint(ctx context.Context, userID, knowledgePointID uint) (*models.LearningProgress, error) {
	var progress models.LearningProgress
	err := r.db.WithContext(ctx).
		Where("user_id = ? AND knowledge_point_id = ?", userID, knowledgePointID).
		First(&progress).Error
	if err != nil {
		return nil, err
	}
	return &progress, nil
}

// FindByUserID 根据用户ID查询所有学习进度
func (r *LearningProgressRepository) FindByUserID(ctx context.Context, userID uint, limit, offset int) ([]*models.LearningProgress, int64, error) {
	var progresses []*models.LearningProgress
	var total int64

	query := r.db.WithContext(ctx).
		Model(&models.LearningProgress{}).
		Where("user_id = ?", userID)

	// 查询总数
	if err := query.Count(&total).Error; err != nil {
		return nil, 0, err
	}

	// 查询列表
	err := query.
		Order("updated_at DESC").
		Limit(limit).
		Offset(offset).
		Find(&progresses).Error

	return progresses, total, err
}

// FindByUserIDAndChapter 根据用户ID和章节查询学习进度
func (r *LearningProgressRepository) FindByUserIDAndChapter(ctx context.Context, userID uint, chapterID uint) ([]*models.LearningProgress, error) {
	var progresses []*models.LearningProgress
	err := r.db.WithContext(ctx).
		Joins("JOIN knowledge_points ON knowledge_points.id = learning_progresses.knowledge_point_id").
		Where("learning_progresses.user_id = ? AND knowledge_points.chapter_id = ?", userID, chapterID).
		Order("learning_progresses.updated_at DESC").
		Find(&progresses).Error
	return progresses, err
}

// Update 更新学习进度
func (r *LearningProgressRepository) Update(ctx context.Context, progress *models.LearningProgress) error {
	return r.db.WithContext(ctx).Save(progress).Error
}

// UpdateFields 更新指定字段
func (r *LearningProgressRepository) UpdateFields(ctx context.Context, id uint, fields map[string]interface{}) error {
	return r.db.WithContext(ctx).Model(&models.LearningProgress{}).Where("id = ?", id).Updates(fields).Error
}

// Upsert 创建或更新学习进度
func (r *LearningProgressRepository) Upsert(ctx context.Context, progress *models.LearningProgress) error {
	return r.db.WithContext(ctx).
		Where("user_id = ? AND knowledge_point_id = ?", progress.UserID, progress.KnowledgePointID).
		Assign(progress).
		FirstOrCreate(progress).Error
}

// Delete 删除学习进度(软删除)
func (r *LearningProgressRepository) Delete(ctx context.Context, id uint) error {
	return r.db.WithContext(ctx).Delete(&models.LearningProgress{}, id).Error
}

// GetAverageMasteryByUser 获取用户平均掌握度
func (r *LearningProgressRepository) GetAverageMasteryByUser(ctx context.Context, userID uint) (float64, error) {
	var avg float64
	err := r.db.WithContext(ctx).
		Model(&models.LearningProgress{}).
		Where("user_id = ?", userID).
		Select("COALESCE(AVG(mastery_level), 0)").
		Scan(&avg).Error
	return avg, err
}

// GetMasteryStatsByChapter 获取用户在某章节的掌握度统计
func (r *LearningProgressRepository) GetMasteryStatsByChapter(ctx context.Context, userID, chapterID uint) (map[string]interface{}, error) {
	var result struct {
		AvgMastery   float64
		TotalKPs     int64
		MasteredKPs  int64 // mastery_level >= 80
		LearningKPs  int64 // 50 <= mastery_level < 80
		BeginnerKPs  int64 // mastery_level < 50
	}

	err := r.db.WithContext(ctx).
		Model(&models.LearningProgress{}).
		Select(`
			COALESCE(AVG(learning_progresses.mastery_level), 0) as avg_mastery,
			COUNT(*) as total_kps,
			SUM(CASE WHEN learning_progresses.mastery_level >= 80 THEN 1 ELSE 0 END) as mastered_kps,
			SUM(CASE WHEN learning_progresses.mastery_level >= 50 AND learning_progresses.mastery_level < 80 THEN 1 ELSE 0 END) as learning_kps,
			SUM(CASE WHEN learning_progresses.mastery_level < 50 THEN 1 ELSE 0 END) as beginner_kps
		`).
		Joins("JOIN knowledge_points ON knowledge_points.id = learning_progresses.knowledge_point_id").
		Where("learning_progresses.user_id = ? AND knowledge_points.chapter_id = ?", userID, chapterID).
		Scan(&result).Error

	if err != nil {
		return nil, err
	}

	return map[string]interface{}{
		"avg_mastery":   result.AvgMastery,
		"total_kps":     result.TotalKPs,
		"mastered_kps":  result.MasteredKPs,
		"learning_kps":  result.LearningKPs,
		"beginner_kps":  result.BeginnerKPs,
	}, nil
}
