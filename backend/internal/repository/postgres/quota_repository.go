package postgres

import (
	"context"
	"fmt"
	"time"

	"github.com/qiudl/bblearning-backend/internal/domain/models"
	"gorm.io/gorm"
	"gorm.io/gorm/clause"
)

// QuotaRepository 配额仓库
type QuotaRepository struct {
	db *gorm.DB
}

// NewQuotaRepository 创建配额仓库
func NewQuotaRepository(db *gorm.DB) *QuotaRepository {
	return &QuotaRepository{db: db}
}

// GetUserQuota 获取用户配额
func (r *QuotaRepository) GetUserQuota(ctx context.Context, userID uint) (*models.UserAIQuota, error) {
	var quota models.UserAIQuota
	err := r.db.WithContext(ctx).Where("user_id = ?", userID).First(&quota).Error
	if err != nil {
		if err == gorm.ErrRecordNotFound {
			// 如果不存在，自动创建
			return r.CreateUserQuota(ctx, userID)
		}
		return nil, fmt.Errorf("failed to get user quota: %w", err)
	}

	// 检查是否需要重置配额
	if quota.NeedsDailyReset() || quota.NeedsMonthlyReset() {
		quota, err = r.resetQuotaIfNeeded(ctx, &quota)
		if err != nil {
			return nil, err
		}
	}

	return &quota, nil
}

// CreateUserQuota 创建用户配额
func (r *QuotaRepository) CreateUserQuota(ctx context.Context, userID uint) (*models.UserAIQuota, error) {
	now := time.Now()
	tomorrow := time.Date(now.Year(), now.Month(), now.Day()+1, 0, 0, 0, 0, now.Location())
	nextMonth := time.Date(now.Year(), now.Month()+1, 1, 0, 0, 0, 0, now.Location())

	quota := &models.UserAIQuota{
		UserID:         userID,
		DailyQuota:     10,
		DailyUsed:      0,
		DailyResetAt:   tomorrow,
		MonthlyQuota:   300,
		MonthlyUsed:    0,
		MonthlyResetAt: nextMonth,
		PermanentQuota: 0,
		IsVIP:          false,
		TotalConsumed:  0,
	}

	err := r.db.WithContext(ctx).Create(quota).Error
	if err != nil {
		return nil, fmt.Errorf("failed to create user quota: %w", err)
	}

	return quota, nil
}

// ConsumeQuota 扣减配额
func (r *QuotaRepository) ConsumeQuota(ctx context.Context, userID uint, amount int, quotaType models.QuotaType) error {
	return r.db.WithContext(ctx).Transaction(func(tx *gorm.DB) error {
		// 获取并锁定用户配额记录
		var quota models.UserAIQuota
		err := tx.Clauses(clause.Locking{Strength: "UPDATE"}).
			Where("user_id = ?", userID).
			First(&quota).Error
		if err != nil {
			return fmt.Errorf("failed to lock user quota: %w", err)
		}

		// 根据配额类型扣减
		switch quotaType {
		case models.QuotaTypeDaily:
			if quota.DailyUsed+amount > quota.DailyQuota {
				return fmt.Errorf("insufficient daily quota")
			}
			quota.DailyUsed += amount
		case models.QuotaTypeMonthly:
			if quota.MonthlyUsed+amount > quota.MonthlyQuota {
				return fmt.Errorf("insufficient monthly quota")
			}
			quota.MonthlyUsed += amount
		case models.QuotaTypePermanent:
			if quota.PermanentQuota < amount {
				return fmt.Errorf("insufficient permanent quota")
			}
			quota.PermanentQuota -= amount
		default:
			return fmt.Errorf("invalid quota type: %s", quotaType)
		}

		// 更新统计
		quota.TotalConsumed += int64(amount)
		now := time.Now()
		quota.LastConsumeAt = &now

		// 保存更新
		err = tx.Save(&quota).Error
		if err != nil {
			return fmt.Errorf("failed to update quota: %w", err)
		}

		return nil
	})
}

// RechargeQuota 充值配额
func (r *QuotaRepository) RechargeQuota(ctx context.Context, userID uint, quotaType models.QuotaType, amount int) error {
	return r.db.WithContext(ctx).Transaction(func(tx *gorm.DB) error {
		var quota models.UserAIQuota
		err := tx.Clauses(clause.Locking{Strength: "UPDATE"}).
			Where("user_id = ?", userID).
			First(&quota).Error
		if err != nil {
			return fmt.Errorf("failed to lock user quota: %w", err)
		}

		// 根据配额类型充值
		switch quotaType {
		case models.QuotaTypeDaily:
			quota.DailyQuota += amount
		case models.QuotaTypeMonthly:
			quota.MonthlyQuota += amount
		case models.QuotaTypePermanent:
			quota.PermanentQuota += amount
		default:
			return fmt.Errorf("invalid quota type: %s", quotaType)
		}

		err = tx.Save(&quota).Error
		if err != nil {
			return fmt.Errorf("failed to update quota: %w", err)
		}

		return nil
	})
}

// CreateQuotaLog 创建配额使用日志
func (r *QuotaRepository) CreateQuotaLog(ctx context.Context, log *models.AIQuotaLog) error {
	err := r.db.WithContext(ctx).Create(log).Error
	if err != nil {
		return fmt.Errorf("failed to create quota log: %w", err)
	}
	return nil
}

// CreateRechargeLog 创建充值记录
func (r *QuotaRepository) CreateRechargeLog(ctx context.Context, log *models.QuotaRechargeLog) error {
	err := r.db.WithContext(ctx).Create(log).Error
	if err != nil {
		return fmt.Errorf("failed to create recharge log: %w", err)
	}
	return nil
}

// GetQuotaLogs 获取配额使用日志
func (r *QuotaRepository) GetQuotaLogs(ctx context.Context, userID uint, limit, offset int) ([]*models.AIQuotaLog, int64, error) {
	var logs []*models.AIQuotaLog
	var total int64

	// 计数
	err := r.db.WithContext(ctx).Model(&models.AIQuotaLog{}).
		Where("user_id = ?", userID).
		Count(&total).Error
	if err != nil {
		return nil, 0, fmt.Errorf("failed to count quota logs: %w", err)
	}

	// 查询
	err = r.db.WithContext(ctx).
		Where("user_id = ?", userID).
		Order("created_at DESC").
		Limit(limit).
		Offset(offset).
		Find(&logs).Error
	if err != nil {
		return nil, 0, fmt.Errorf("failed to get quota logs: %w", err)
	}

	return logs, total, nil
}

// GetRechargeLogs 获取充值记录
func (r *QuotaRepository) GetRechargeLogs(ctx context.Context, userID uint, limit, offset int) ([]*models.QuotaRechargeLog, int64, error) {
	var logs []*models.QuotaRechargeLog
	var total int64

	// 计数
	err := r.db.WithContext(ctx).Model(&models.QuotaRechargeLog{}).
		Where("user_id = ?", userID).
		Count(&total).Error
	if err != nil {
		return nil, 0, fmt.Errorf("failed to count recharge logs: %w", err)
	}

	// 查询
	err = r.db.WithContext(ctx).
		Where("user_id = ?", userID).
		Order("created_at DESC").
		Limit(limit).
		Offset(offset).
		Find(&logs).Error
	if err != nil {
		return nil, 0, fmt.Errorf("failed to get recharge logs: %w", err)
	}

	return logs, total, nil
}

// ResetDailyQuota 重置日配额
func (r *QuotaRepository) ResetDailyQuota(ctx context.Context) error {
	now := time.Now()
	tomorrow := time.Date(now.Year(), now.Month(), now.Day()+1, 0, 0, 0, 0, now.Location())

	return r.db.WithContext(ctx).
		Model(&models.UserAIQuota{}).
		Where("daily_reset_at <= ?", now).
		Updates(map[string]interface{}{
			"daily_used":     0,
			"daily_reset_at": tomorrow,
		}).Error
}

// ResetMonthlyQuota 重置月配额
func (r *QuotaRepository) ResetMonthlyQuota(ctx context.Context) error {
	now := time.Now()
	nextMonth := time.Date(now.Year(), now.Month()+1, 1, 0, 0, 0, 0, now.Location())

	return r.db.WithContext(ctx).
		Model(&models.UserAIQuota{}).
		Where("monthly_reset_at <= ?", now).
		Updates(map[string]interface{}{
			"monthly_used":     0,
			"monthly_reset_at": nextMonth,
		}).Error
}

// resetQuotaIfNeeded 重置配额（如果需要）
func (r *QuotaRepository) resetQuotaIfNeeded(ctx context.Context, quota *models.UserAIQuota) (*models.UserAIQuota, error) {
	now := time.Now()
	needsUpdate := false

	if quota.NeedsDailyReset() {
		tomorrow := time.Date(now.Year(), now.Month(), now.Day()+1, 0, 0, 0, 0, now.Location())
		quota.DailyUsed = 0
		quota.DailyResetAt = tomorrow
		needsUpdate = true
	}

	if quota.NeedsMonthlyReset() {
		nextMonth := time.Date(now.Year(), now.Month()+1, 1, 0, 0, 0, 0, now.Location())
		quota.MonthlyUsed = 0
		quota.MonthlyResetAt = nextMonth
		needsUpdate = true
	}

	if needsUpdate {
		err := r.db.WithContext(ctx).Save(quota).Error
		if err != nil {
			return nil, fmt.Errorf("failed to reset quota: %w", err)
		}
	}

	return quota, nil
}

// SetVIP 设置VIP
func (r *QuotaRepository) SetVIP(ctx context.Context, userID uint, expireAt time.Time) error {
	return r.db.WithContext(ctx).
		Model(&models.UserAIQuota{}).
		Where("user_id = ?", userID).
		Updates(map[string]interface{}{
			"is_vip":        true,
			"vip_expire_at": expireAt,
		}).Error
}

// CancelVIP 取消VIP
func (r *QuotaRepository) CancelVIP(ctx context.Context, userID uint) error {
	return r.db.WithContext(ctx).
		Model(&models.UserAIQuota{}).
		Where("user_id = ?", userID).
		Updates(map[string]interface{}{
			"is_vip":        false,
			"vip_expire_at": nil,
		}).Error
}

// GetExpiredVIPUsers 获取VIP已过期的用户
func (r *QuotaRepository) GetExpiredVIPUsers(ctx context.Context) ([]*models.UserAIQuota, error) {
	var quotas []*models.UserAIQuota
	now := time.Now()

	err := r.db.WithContext(ctx).
		Where("is_vip = ? AND vip_expire_at < ?", true, now).
		Find(&quotas).Error
	if err != nil {
		return nil, fmt.Errorf("failed to get expired VIP users: %w", err)
	}

	return quotas, nil
}
