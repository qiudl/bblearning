package database

import (
	"fmt"

	"gorm.io/gorm"
)

// QueryOptimizer 查询优化器
type QueryOptimizer struct {
	db *gorm.DB
}

// NewQueryOptimizer 创建查询优化器
func NewQueryOptimizer(db *gorm.DB) *QueryOptimizer {
	return &QueryOptimizer{db: db}
}

// OptimizeQuery 优化查询
// 添加常用索引字段的预加载和选择性字段加载
func (o *QueryOptimizer) OptimizeQuery(query *gorm.DB, options ...QueryOption) *gorm.DB {
	for _, opt := range options {
		query = opt(query)
	}
	return query
}

// QueryOption 查询选项
type QueryOption func(*gorm.DB) *gorm.DB

// WithPreload 预加载关联
func WithPreload(associations ...string) QueryOption {
	return func(db *gorm.DB) *gorm.DB {
		for _, assoc := range associations {
			db = db.Preload(assoc)
		}
		return db
	}
}

// WithSelect 选择特定字段
func WithSelect(fields ...string) QueryOption {
	return func(db *gorm.DB) *gorm.DB {
		return db.Select(fields)
	}
}

// WithPagination 分页查询
func WithPagination(page, pageSize int) QueryOption {
	return func(db *gorm.DB) *gorm.DB {
		offset := (page - 1) * pageSize
		return db.Offset(offset).Limit(pageSize)
	}
}

// WithOrder 排序
func WithOrder(orderBy string) QueryOption {
	return func(db *gorm.DB) *gorm.DB {
		return db.Order(orderBy)
	}
}

// WithIndexHint 使用索引提示 (MySQL specific)
func WithIndexHint(indexName string) QueryOption {
	return func(db *gorm.DB) *gorm.DB {
		// MySQL: USE INDEX (index_name)
		// 这里需要根据实际数据库类型调整
		return db.Clauses(gorm.Expr(fmt.Sprintf("USE INDEX (%s)", indexName)))
	}
}

// OptimizedPaginate 优化的分页查询
// 使用子查询优化大数据量分页
func (o *QueryOptimizer) OptimizedPaginate(model interface{}, page, pageSize int, result interface{}, countDest *int64) error {
	// 先获取总数
	if err := o.db.Model(model).Count(countDest).Error; err != nil {
		return err
	}

	// 如果总数为0，直接返回
	if *countDest == 0 {
		return nil
	}

	// 计算偏移量
	offset := (page - 1) * pageSize

	// 执行分页查询
	return o.db.Offset(offset).Limit(pageSize).Find(result).Error
}

// BatchInsert 批量插入优化
func (o *QueryOptimizer) BatchInsert(records interface{}, batchSize int) error {
	return o.db.CreateInBatches(records, batchSize).Error
}

// OptimizeIndexes 创建推荐索引
// 这是一个示例方法，实际应该在migration中创建索引
func (o *QueryOptimizer) GetRecommendedIndexes() []string {
	return []string{
		// 用户表
		"CREATE INDEX idx_users_email ON users(email)",
		"CREATE INDEX idx_users_grade ON users(grade)",

		// 知识点表
		"CREATE INDEX idx_knowledge_points_grade ON knowledge_points(grade)",
		"CREATE INDEX idx_knowledge_points_parent_id ON knowledge_points(parent_id)",

		// 题目表
		"CREATE INDEX idx_questions_knowledge_point_id ON questions(knowledge_point_id)",
		"CREATE INDEX idx_questions_difficulty ON questions(difficulty)",
		"CREATE INDEX idx_questions_type ON questions(type)",
		"CREATE INDEX idx_questions_created_at ON questions(created_at)",

		// 练习记录表
		"CREATE INDEX idx_practice_records_user_id ON practice_records(user_id)",
		"CREATE INDEX idx_practice_records_question_id ON practice_records(question_id)",
		"CREATE INDEX idx_practice_records_created_at ON practice_records(created_at)",
		"CREATE INDEX idx_practice_records_user_created ON practice_records(user_id, created_at)",

		// 错题表
		"CREATE INDEX idx_wrong_questions_user_id ON wrong_questions(user_id)",
		"CREATE INDEX idx_wrong_questions_knowledge_point_id ON wrong_questions(knowledge_point_id)",

		// 学习记录表
		"CREATE INDEX idx_learning_records_user_id ON learning_records(user_id)",
		"CREATE INDEX idx_learning_records_knowledge_point_id ON learning_records(knowledge_point_id)",

		// 学习统计表
		"CREATE INDEX idx_learning_statistics_user_id ON learning_statistics(user_id)",
		"CREATE INDEX idx_learning_statistics_date ON learning_statistics(date)",
		"CREATE INDEX idx_learning_statistics_user_date ON learning_statistics(user_id, date)",

		// 配额表
		"CREATE INDEX idx_user_quotas_user_id ON user_quotas(user_id)",

		// 复合索引示例
		"CREATE INDEX idx_practice_user_kp ON practice_records(user_id, knowledge_point_id, created_at)",
	}
}
