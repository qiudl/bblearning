package postgres

import (
	"context"

	"github.com/qiudl/bblearning-backend/internal/domain/models"
	"gorm.io/gorm"
)

// KnowledgePointRepository 知识点仓库
type KnowledgePointRepository struct {
	db *gorm.DB
}

// NewKnowledgePointRepository 创建知识点仓库
func NewKnowledgePointRepository(db *gorm.DB) *KnowledgePointRepository {
	return &KnowledgePointRepository{db: db}
}

// Create 创建知识点
func (r *KnowledgePointRepository) Create(ctx context.Context, kp *models.KnowledgePoint) error {
	return r.db.WithContext(ctx).Create(kp).Error
}

// FindByID 根据ID查询知识点
func (r *KnowledgePointRepository) FindByID(ctx context.Context, id uint) (*models.KnowledgePoint, error) {
	var kp models.KnowledgePoint
	err := r.db.WithContext(ctx).First(&kp, id).Error
	if err != nil {
		return nil, err
	}
	return &kp, nil
}

// List 查询知识点列表
func (r *KnowledgePointRepository) List(ctx context.Context, filters map[string]interface{}, limit, offset int) ([]*models.KnowledgePoint, int64, error) {
	var kps []*models.KnowledgePoint
	var total int64

	query := r.db.WithContext(ctx).Model(&models.KnowledgePoint{})

	// 应用过滤条件
	if chapterID, ok := filters["chapter_id"]; ok {
		query = query.Where("chapter_id = ?", chapterID)
	}
	if kpType, ok := filters["type"]; ok {
		query = query.Where("type = ?", kpType)
	}
	if difficulty, ok := filters["difficulty"]; ok {
		query = query.Where("difficulty = ?", difficulty)
	}
	if parentID, ok := filters["parent_id"]; ok {
		if parentID == nil {
			query = query.Where("parent_id IS NULL")
		} else {
			query = query.Where("parent_id = ?", parentID)
		}
	}

	// 查询总数
	if err := query.Count(&total).Error; err != nil {
		return nil, 0, err
	}

	// 查询列表
	err := query.
		Order("display_order ASC, id ASC").
		Limit(limit).
		Offset(offset).
		Find(&kps).Error

	return kps, total, err
}

// FindByChapterID 根据章节ID查询所有知识点
func (r *KnowledgePointRepository) FindByChapterID(ctx context.Context, chapterID uint) ([]*models.KnowledgePoint, error) {
	var kps []*models.KnowledgePoint
	err := r.db.WithContext(ctx).
		Where("chapter_id = ?", chapterID).
		Order("display_order ASC, id ASC").
		Find(&kps).Error
	return kps, err
}

// FindRootByChapterID 根据章节ID查询根知识点(parent_id为NULL)
func (r *KnowledgePointRepository) FindRootByChapterID(ctx context.Context, chapterID uint) ([]*models.KnowledgePoint, error) {
	var kps []*models.KnowledgePoint
	err := r.db.WithContext(ctx).
		Where("chapter_id = ? AND parent_id IS NULL", chapterID).
		Order("display_order ASC, id ASC").
		Find(&kps).Error
	return kps, err
}

// FindChildrenByParentID 根据父ID查询子知识点
func (r *KnowledgePointRepository) FindChildrenByParentID(ctx context.Context, parentID uint) ([]*models.KnowledgePoint, error) {
	var kps []*models.KnowledgePoint
	err := r.db.WithContext(ctx).
		Where("parent_id = ?", parentID).
		Order("display_order ASC, id ASC").
		Find(&kps).Error
	return kps, err
}

// Update 更新知识点
func (r *KnowledgePointRepository) Update(ctx context.Context, kp *models.KnowledgePoint) error {
	return r.db.WithContext(ctx).Save(kp).Error
}

// UpdateFields 更新指定字段
func (r *KnowledgePointRepository) UpdateFields(ctx context.Context, id uint, fields map[string]interface{}) error {
	return r.db.WithContext(ctx).Model(&models.KnowledgePoint{}).Where("id = ?", id).Updates(fields).Error
}

// Delete 删除知识点(软删除)
func (r *KnowledgePointRepository) Delete(ctx context.Context, id uint) error {
	return r.db.WithContext(ctx).Delete(&models.KnowledgePoint{}, id).Error
}

// CountByChapterID 统计章节下的知识点数量
func (r *KnowledgePointRepository) CountByChapterID(ctx context.Context, chapterID uint) (int64, error) {
	var count int64
	err := r.db.WithContext(ctx).
		Model(&models.KnowledgePoint{}).
		Where("chapter_id = ?", chapterID).
		Count(&count).Error
	return count, err
}
