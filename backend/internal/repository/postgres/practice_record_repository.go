package postgres

import (
	"context"
	"time"

	"github.com/qiudl/bblearning-backend/internal/domain/models"
	"gorm.io/gorm"
)

// PracticeRecordRepository 练习记录仓库
type PracticeRecordRepository struct {
	db *gorm.DB
}

// NewPracticeRecordRepository 创建练习记录仓库
func NewPracticeRecordRepository(db *gorm.DB) *PracticeRecordRepository {
	return &PracticeRecordRepository{db: db}
}

// Create 创建练习记录
func (r *PracticeRecordRepository) Create(ctx context.Context, record *models.PracticeRecord) error {
	return r.db.WithContext(ctx).Create(record).Error
}

// FindByID 根据ID查询练习记录
func (r *PracticeRecordRepository) FindByID(ctx context.Context, id uint) (*models.PracticeRecord, error) {
	var record models.PracticeRecord
	err := r.db.WithContext(ctx).Preload("Question").First(&record, id).Error
	if err != nil {
		return nil, err
	}
	return &record, nil
}

// List 查询练习记录列表
func (r *PracticeRecordRepository) List(ctx context.Context, filters map[string]interface{}, limit, offset int) ([]*models.PracticeRecord, int64, error) {
	var records []*models.PracticeRecord
	var total int64

	query := r.db.WithContext(ctx).Model(&models.PracticeRecord{})

	// 应用过滤条件
	if userID, ok := filters["user_id"]; ok {
		query = query.Where("user_id = ?", userID)
	}
	if questionID, ok := filters["question_id"]; ok {
		query = query.Where("question_id = ?", questionID)
	}
	if isCorrect, ok := filters["is_correct"]; ok {
		query = query.Where("is_correct = ?", isCorrect)
	}
	if startDate, ok := filters["start_date"]; ok {
		query = query.Where("created_at >= ?", startDate)
	}
	if endDate, ok := filters["end_date"]; ok {
		query = query.Where("created_at <= ?", endDate)
	}
	if kpID, ok := filters["knowledge_point_id"]; ok {
		query = query.Joins("JOIN questions ON questions.id = practice_records.question_id").
			Where("questions.knowledge_point_id = ?", kpID)
	}

	// 查询总数
	if err := query.Count(&total).Error; err != nil {
		return nil, 0, err
	}

	// 查询列表(预加载Question)
	err := query.
		Preload("Question").
		Order("created_at DESC").
		Limit(limit).
		Offset(offset).
		Find(&records).Error

	return records, total, err
}

// FindByUserID 根据用户ID查询练习记录
func (r *PracticeRecordRepository) FindByUserID(ctx context.Context, userID uint, limit, offset int) ([]*models.PracticeRecord, int64, error) {
	filters := map[string]interface{}{"user_id": userID}
	return r.List(ctx, filters, limit, offset)
}

// FindByUserAndQuestion 根据用户和题目查询练习记录
func (r *PracticeRecordRepository) FindByUserAndQuestion(ctx context.Context, userID, questionID uint) ([]*models.PracticeRecord, error) {
	var records []*models.PracticeRecord
	err := r.db.WithContext(ctx).
		Where("user_id = ? AND question_id = ?", userID, questionID).
		Order("created_at DESC").
		Find(&records).Error
	return records, err
}

// GetStatistics 获取用户练习统计
func (r *PracticeRecordRepository) GetStatistics(ctx context.Context, userID uint) (map[string]interface{}, error) {
	var result struct {
		TotalPractice int64
		TotalCorrect  int64
		TotalWrong    int64
	}

	err := r.db.WithContext(ctx).
		Model(&models.PracticeRecord{}).
		Select(`
			COUNT(*) as total_practice,
			SUM(CASE WHEN is_correct THEN 1 ELSE 0 END) as total_correct,
			SUM(CASE WHEN NOT is_correct THEN 1 ELSE 0 END) as total_wrong
		`).
		Where("user_id = ?", userID).
		Scan(&result).Error

	if err != nil {
		return nil, err
	}

	accuracy := 0.0
	if result.TotalPractice > 0 {
		accuracy = float64(result.TotalCorrect) / float64(result.TotalPractice) * 100
	}

	return map[string]interface{}{
		"total_practice": result.TotalPractice,
		"total_correct":  result.TotalCorrect,
		"total_wrong":    result.TotalWrong,
		"accuracy":       accuracy,
	}, nil
}

// GetTodayStatistics 获取今日练习统计
func (r *PracticeRecordRepository) GetTodayStatistics(ctx context.Context, userID uint) (int64, error) {
	var count int64
	today := time.Now().Format("2006-01-02")
	err := r.db.WithContext(ctx).
		Model(&models.PracticeRecord{}).
		Where("user_id = ? AND DATE(created_at) = ?", userID, today).
		Count(&count).Error
	return count, err
}

// GetWeekStatistics 获取本周练习统计
func (r *PracticeRecordRepository) GetWeekStatistics(ctx context.Context, userID uint) (int64, error) {
	var count int64
	weekStart := time.Now().AddDate(0, 0, -int(time.Now().Weekday()))
	err := r.db.WithContext(ctx).
		Model(&models.PracticeRecord{}).
		Where("user_id = ? AND created_at >= ?", userID, weekStart).
		Count(&count).Error
	return count, err
}

// GetLastPracticeTime 获取最后练习时间
func (r *PracticeRecordRepository) GetLastPracticeTime(ctx context.Context, userID uint) (*time.Time, error) {
	var record models.PracticeRecord
	err := r.db.WithContext(ctx).
		Where("user_id = ?", userID).
		Order("created_at DESC").
		First(&record).Error

	if err != nil {
		if err == gorm.ErrRecordNotFound {
			return nil, nil
		}
		return nil, err
	}

	return &record.CreatedAt, nil
}

// GetKnowledgePointAccuracy 获取各知识点正确率
func (r *PracticeRecordRepository) GetKnowledgePointAccuracy(ctx context.Context, userID uint) ([]map[string]interface{}, error) {
	var results []struct {
		KnowledgePointID uint
		TotalCount       int64
		CorrectCount     int64
		Accuracy         float64
	}

	err := r.db.WithContext(ctx).
		Model(&models.PracticeRecord{}).
		Select(`
			questions.knowledge_point_id,
			COUNT(*) as total_count,
			SUM(CASE WHEN practice_records.is_correct THEN 1 ELSE 0 END) as correct_count,
			CASE
				WHEN COUNT(*) > 0 THEN (SUM(CASE WHEN practice_records.is_correct THEN 1 ELSE 0 END)::float / COUNT(*) * 100)
				ELSE 0
			END as accuracy
		`).
		Joins("JOIN questions ON questions.id = practice_records.question_id").
		Where("practice_records.user_id = ?", userID).
		Group("questions.knowledge_point_id").
		Scan(&results).Error

	if err != nil {
		return nil, err
	}

	// 转换为map格式
	data := make([]map[string]interface{}, len(results))
	for i, r := range results {
		data[i] = map[string]interface{}{
			"knowledge_point_id": r.KnowledgePointID,
			"total_count":        r.TotalCount,
			"correct_count":      r.CorrectCount,
			"accuracy":           r.Accuracy,
		}
	}

	return data, nil
}

// BatchCreate 批量创建练习记录
func (r *PracticeRecordRepository) BatchCreate(ctx context.Context, records []*models.PracticeRecord) error {
	return r.db.WithContext(ctx).Create(&records).Error
}

// FindByDateRange 根据日期范围查询练习记录
func (r *PracticeRecordRepository) FindByDateRange(ctx context.Context, userID uint, startDate, endDate time.Time) ([]*models.PracticeRecord, error) {
	var records []*models.PracticeRecord
	err := r.db.WithContext(ctx).
		Where("user_id = ? AND created_at >= ? AND created_at <= ?", userID, startDate, endDate).
		Order("created_at ASC").
		Find(&records).Error
	return records, err
}
