package quota

import (
	"context"
	"fmt"
	"time"

	"github.com/qiudl/bblearning-backend/internal/domain/models"
	"github.com/qiudl/bblearning-backend/internal/repository/postgres"
)

// QuotaService 配额服务
type QuotaService struct {
	quotaRepo *postgres.QuotaRepository
}

// NewQuotaService 创建配额服务
func NewQuotaService(quotaRepo *postgres.QuotaRepository) *QuotaService {
	return &QuotaService{
		quotaRepo: quotaRepo,
	}
}

// GetUserQuota 获取用户配额信息
func (s *QuotaService) GetUserQuota(ctx context.Context, userID uint) (*models.QuotaInfo, error) {
	quota, err := s.quotaRepo.GetUserQuota(ctx, userID)
	if err != nil {
		return nil, err
	}

	return quota.ToQuotaInfo(), nil
}

// CheckAndConsumeQuota 检查并扣减配额
// 优先级: 永久配额 > 月配额 > 日配额
func (s *QuotaService) CheckAndConsumeQuota(ctx context.Context, userID uint, amount int, serviceType models.ServiceType) error {
	if amount <= 0 {
		return fmt.Errorf("invalid amount: %d", amount)
	}

	// 获取用户配额
	quota, err := s.quotaRepo.GetUserQuota(ctx, userID)
	if err != nil {
		return err
	}

	// 检查总配额是否足够
	totalAvailable := quota.GetAvailableQuota()
	if totalAvailable < amount {
		return fmt.Errorf("配额不足: 需要%d，可用%d", amount, totalAvailable)
	}

	// 决定使用哪种配额类型
	var quotaType models.QuotaType
	var description string

	if quota.PermanentQuota >= amount {
		// 优先使用永久配额
		quotaType = models.QuotaTypePermanent
		description = fmt.Sprintf("使用永久配额 %d", amount)
	} else if quota.GetMonthlyRemaining() >= amount {
		// 其次使用月配额
		quotaType = models.QuotaTypeMonthly
		description = fmt.Sprintf("使用月配额 %d", amount)
	} else if quota.GetDailyRemaining() >= amount {
		// 最后使用日配额
		quotaType = models.QuotaTypeDaily
		description = fmt.Errorf("使用日配额 %d", amount)
	} else {
		// 需要组合使用多种配额
		return s.consumeMultipleQuotas(ctx, userID, amount, serviceType, quota)
	}

	// 扣减配额
	err = s.quotaRepo.ConsumeQuota(ctx, userID, amount, quotaType)
	if err != nil {
		return err
	}

	// 记录日志
	log := &models.AIQuotaLog{
		UserID:      userID,
		QuotaType:   quotaType,
		Amount:      amount,
		ServiceType: serviceType,
		Description: description,
	}
	_ = s.quotaRepo.CreateQuotaLog(ctx, log) // 忽略日志错误

	return nil
}

// consumeMultipleQuotas 组合使用多种配额
func (s *QuotaService) consumeMultipleQuotas(ctx context.Context, userID uint, amount int, serviceType models.ServiceType, quota *models.UserAIQuota) error {
	remaining := amount

	// 1. 先用永久配额
	if quota.PermanentQuota > 0 {
		use := min(quota.PermanentQuota, remaining)
		err := s.quotaRepo.ConsumeQuota(ctx, userID, use, models.QuotaTypePermanent)
		if err != nil {
			return err
		}
		remaining -= use

		// 记录日志
		log := &models.AIQuotaLog{
			UserID:      userID,
			QuotaType:   models.QuotaTypePermanent,
			Amount:      use,
			ServiceType: serviceType,
			Description: fmt.Sprintf("组合使用永久配额 %d", use),
		}
		_ = s.quotaRepo.CreateQuotaLog(ctx, log)
	}

	// 2. 再用月配额
	if remaining > 0 && quota.GetMonthlyRemaining() > 0 {
		use := min(quota.GetMonthlyRemaining(), remaining)
		err := s.quotaRepo.ConsumeQuota(ctx, userID, use, models.QuotaTypeMonthly)
		if err != nil {
			return err
		}
		remaining -= use

		// 记录日志
		log := &models.AIQuotaLog{
			UserID:      userID,
			QuotaType:   models.QuotaTypeMonthly,
			Amount:      use,
			ServiceType: serviceType,
			Description: fmt.Sprintf("组合使用月配额 %d", use),
		}
		_ = s.quotaRepo.CreateQuotaLog(ctx, log)
	}

	// 3. 最后用日配额
	if remaining > 0 && quota.GetDailyRemaining() > 0 {
		use := min(quota.GetDailyRemaining(), remaining)
		err := s.quotaRepo.ConsumeQuota(ctx, userID, use, models.QuotaTypeDaily)
		if err != nil {
			return err
		}
		remaining -= use

		// 记录日志
		log := &models.AIQuotaLog{
			UserID:      userID,
			QuotaType:   models.QuotaTypeDaily,
			Amount:      use,
			ServiceType: serviceType,
			Description: fmt.Sprintf("组合使用日配额 %d", use),
		}
		_ = s.quotaRepo.CreateQuotaLog(ctx, log)
	}

	if remaining > 0 {
		return fmt.Errorf("配额不足: 还差 %d", remaining)
	}

	return nil
}

// RechargeQuota 充值配额
func (s *QuotaService) RechargeQuota(ctx context.Context, userID uint, quotaType models.QuotaType, amount int, reason string, operatorID *uint, method models.RechargeMethod) error {
	if amount <= 0 {
		return fmt.Errorf("invalid amount: %d", amount)
	}

	// 充值
	err := s.quotaRepo.RechargeQuota(ctx, userID, quotaType, amount)
	if err != nil {
		return err
	}

	// 记录充值日志
	log := &models.QuotaRechargeLog{
		UserID:         userID,
		QuotaType:      quotaType,
		Amount:         amount,
		Reason:         reason,
		OperatorID:     operatorID,
		RechargeMethod: method,
	}
	err = s.quotaRepo.CreateRechargeLog(ctx, log)
	if err != nil {
		// 日志记录失败不影响主流程
		return fmt.Errorf("recharge success but failed to log: %w", err)
	}

	return nil
}

// GetQuotaLogs 获取配额使用日志
func (s *QuotaService) GetQuotaLogs(ctx context.Context, userID uint, page, pageSize int) ([]*models.AIQuotaLog, int64, error) {
	if page < 1 {
		page = 1
	}
	if pageSize < 1 || pageSize > 100 {
		pageSize = 20
	}

	offset := (page - 1) * pageSize
	return s.quotaRepo.GetQuotaLogs(ctx, userID, pageSize, offset)
}

// GetRechargeLogs 获取充值记录
func (s *QuotaService) GetRechargeLogs(ctx context.Context, userID uint, page, pageSize int) ([]*models.QuotaRechargeLog, int64, error) {
	if page < 1 {
		page = 1
	}
	if pageSize < 1 || pageSize > 100 {
		pageSize = 20
	}

	offset := (page - 1) * pageSize
	return s.quotaRepo.GetRechargeLogs(ctx, userID, pageSize, offset)
}

// ResetDailyQuotas 重置所有用户的日配额（定时任务）
func (s *QuotaService) ResetDailyQuotas(ctx context.Context) error {
	return s.quotaRepo.ResetDailyQuota(ctx)
}

// ResetMonthlyQuotas 重置所有用户的月配额（定时任务）
func (s *QuotaService) ResetMonthlyQuotas(ctx context.Context) error {
	return s.quotaRepo.ResetMonthlyQuota(ctx)
}

// SetVIP 设置用户为VIP
func (s *QuotaService) SetVIP(ctx context.Context, userID uint, expireAt time.Time, extraQuota int, operatorID *uint) error {
	// 设置VIP状态
	err := s.quotaRepo.SetVIP(ctx, userID, expireAt)
	if err != nil {
		return err
	}

	// 赠送永久配额
	if extraQuota > 0 {
		err = s.RechargeQuota(ctx, userID, models.QuotaTypePermanent, extraQuota, "VIP赠送", operatorID, models.RechargeMethodVIP)
		if err != nil {
			return err
		}
	}

	return nil
}

// CancelVIP 取消VIP
func (s *QuotaService) CancelVIP(ctx context.Context, userID uint) error {
	return s.quotaRepo.CancelVIP(ctx, userID)
}

// ProcessExpiredVIPs 处理过期的VIP用户（定时任务）
func (s *QuotaService) ProcessExpiredVIPs(ctx context.Context) error {
	quotas, err := s.quotaRepo.GetExpiredVIPUsers(ctx)
	if err != nil {
		return err
	}

	for _, quota := range quotas {
		err = s.quotaRepo.CancelVIP(ctx, quota.UserID)
		if err != nil {
			// 记录错误但继续处理其他用户
			fmt.Printf("failed to cancel VIP for user %d: %v\n", quota.UserID, err)
		}
	}

	return nil
}

// CheckQuota 仅检查配额是否足够（不扣减）
func (s *QuotaService) CheckQuota(ctx context.Context, userID uint, amount int) (bool, error) {
	quota, err := s.quotaRepo.GetUserQuota(ctx, userID)
	if err != nil {
		return false, err
	}

	return quota.GetAvailableQuota() >= amount, nil
}

// min 返回两个整数中的较小值
func min(a, b int) int {
	if a < b {
		return a
	}
	return b
}
