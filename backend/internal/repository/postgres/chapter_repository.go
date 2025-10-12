package postgres

import (
	"context"

	"github.com/qiudl/bblearning-backend/internal/domain/models"
	"gorm.io/gorm"
)

// ChapterRepository 章节仓库
type ChapterRepository struct {
	db *gorm.DB
}

// NewChapterRepository 创建章节仓库
func NewChapterRepository(db *gorm.DB) *ChapterRepository {
	return &ChapterRepository{db: db}
}

// Create 创建章节
func (r *ChapterRepository) Create(ctx context.Context, chapter *models.Chapter) error {
	return r.db.WithContext(ctx).Create(chapter).Error
}

// FindByID 根据ID查询章节
func (r *ChapterRepository) FindByID(ctx context.Context, id uint) (*models.Chapter, error) {
	var chapter models.Chapter
	err := r.db.WithContext(ctx).First(&chapter, id).Error
	if err != nil {
		return nil, err
	}
	return &chapter, nil
}

// FindByIDWithKnowledgePoints 根据ID查询章节(包含知识点)
func (r *ChapterRepository) FindByIDWithKnowledgePoints(ctx context.Context, id uint) (*models.Chapter, error) {
	var chapter models.Chapter
	err := r.db.WithContext(ctx).
		Preload("KnowledgePoints", func(db *gorm.DB) *gorm.DB {
			return db.Order("display_order ASC, id ASC")
		}).
		First(&chapter, id).Error
	if err != nil {
		return nil, err
	}
	return &chapter, nil
}

// List 查询章节列表
func (r *ChapterRepository) List(ctx context.Context, filters map[string]interface{}, limit, offset int) ([]*models.Chapter, int64, error) {
	var chapters []*models.Chapter
	var total int64

	query := r.db.WithContext(ctx).Model(&models.Chapter{})

	// 应用过滤条件
	if grade, ok := filters["grade"]; ok {
		query = query.Where("grade = ?", grade)
	}
	if subject, ok := filters["subject"]; ok {
		query = query.Where("subject = ?", subject)
	}
	if semester, ok := filters["semester"]; ok {
		query = query.Where("semester = ?", semester)
	}

	// 查询总数
	if err := query.Count(&total).Error; err != nil {
		return nil, 0, err
	}

	// 查询列表
	err := query.
		Order("display_order ASC, chapter_number ASC, id ASC").
		Limit(limit).
		Offset(offset).
		Find(&chapters).Error

	return chapters, total, err
}

// Update 更新章节
func (r *ChapterRepository) Update(ctx context.Context, chapter *models.Chapter) error {
	return r.db.WithContext(ctx).Save(chapter).Error
}

// UpdateFields 更新指定字段
func (r *ChapterRepository) UpdateFields(ctx context.Context, id uint, fields map[string]interface{}) error {
	return r.db.WithContext(ctx).Model(&models.Chapter{}).Where("id = ?", id).Updates(fields).Error
}

// Delete 删除章节(软删除)
func (r *ChapterRepository) Delete(ctx context.Context, id uint) error {
	return r.db.WithContext(ctx).Delete(&models.Chapter{}, id).Error
}

// FindByGrade 根据年级查询所有章节
func (r *ChapterRepository) FindByGrade(ctx context.Context, grade string) ([]*models.Chapter, error) {
	var chapters []*models.Chapter
	err := r.db.WithContext(ctx).
		Where("grade = ?", grade).
		Order("display_order ASC, chapter_number ASC").
		Find(&chapters).Error
	return chapters, err
}

// FindByGradeWithKnowledgePoints 根据年级查询所有章节(包含知识点)
func (r *ChapterRepository) FindByGradeWithKnowledgePoints(ctx context.Context, grade string) ([]*models.Chapter, error) {
	var chapters []*models.Chapter
	err := r.db.WithContext(ctx).
		Where("grade = ?", grade).
		Preload("KnowledgePoints", func(db *gorm.DB) *gorm.DB {
			return db.Order("display_order ASC, id ASC")
		}).
		Order("display_order ASC, chapter_number ASC").
		Find(&chapters).Error
	return chapters, err
}
