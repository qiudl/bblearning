package postgres

import (
	"context"

	"github.com/qiudl/bblearning-backend/internal/domain/models"
	"gorm.io/gorm"
)

// UserRepository 用户仓库
type UserRepository struct {
	db *gorm.DB
}

// NewUserRepository 创建用户仓库
func NewUserRepository(db *gorm.DB) *UserRepository {
	return &UserRepository{db: db}
}

// Create 创建用户
func (r *UserRepository) Create(ctx context.Context, user *models.User) error {
	return r.db.WithContext(ctx).Create(user).Error
}

// FindByID 根据ID查询用户
func (r *UserRepository) FindByID(ctx context.Context, id uint) (*models.User, error) {
	var user models.User
	err := r.db.WithContext(ctx).First(&user, id).Error
	if err != nil {
		return nil, err
	}
	return &user, nil
}

// FindByUsername 根据用户名查询用户
func (r *UserRepository) FindByUsername(ctx context.Context, username string) (*models.User, error) {
	var user models.User
	err := r.db.WithContext(ctx).Where("username = ?", username).First(&user).Error
	if err != nil {
		return nil, err
	}
	return &user, nil
}

// ExistsByUsername 检查用户名是否存在
func (r *UserRepository) ExistsByUsername(ctx context.Context, username string) (bool, error) {
	var count int64
	err := r.db.WithContext(ctx).Model(&models.User{}).Where("username = ?", username).Count(&count).Error
	return count > 0, err
}

// Update 更新用户信息
func (r *UserRepository) Update(ctx context.Context, user *models.User) error {
	return r.db.WithContext(ctx).Save(user).Error
}

// UpdateFields 更新指定字段
func (r *UserRepository) UpdateFields(ctx context.Context, id uint, fields map[string]interface{}) error {
	return r.db.WithContext(ctx).Model(&models.User{}).Where("id = ?", id).Updates(fields).Error
}

// Delete 删除用户(软删除)
func (r *UserRepository) Delete(ctx context.Context, id uint) error {
	return r.db.WithContext(ctx).Delete(&models.User{}, id).Error
}

// List 查询用户列表
func (r *UserRepository) List(ctx context.Context, limit, offset int) ([]*models.User, int64, error) {
	var users []*models.User
	var total int64

	// 查询总数
	if err := r.db.WithContext(ctx).Model(&models.User{}).Count(&total).Error; err != nil {
		return nil, 0, err
	}

	// 查询列表
	err := r.db.WithContext(ctx).Limit(limit).Offset(offset).Find(&users).Error
	return users, total, err
}
