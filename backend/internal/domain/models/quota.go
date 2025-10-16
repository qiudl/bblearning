package models

import (
	"time"

	"gorm.io/gorm"
)

// QuotaType 配额类型
type QuotaType string

const (
	QuotaTypeDaily     QuotaType = "daily"     // 日配额
	QuotaTypeMonthly   QuotaType = "monthly"   // 月配额
	QuotaTypePermanent QuotaType = "permanent" // 永久配额
)

// ServiceType AI服务类型
type ServiceType string

const (
	ServiceTypeChat     ServiceType = "chat"     // AI对话
	ServiceTypeGenerate ServiceType = "generate" // 生成题目
	ServiceTypeGrade    ServiceType = "grade"    // 批改答案
	ServiceTypeDiagnose ServiceType = "diagnose" // 学习诊断
	ServiceTypeOCR      ServiceType = "ocr"      // OCR识别
)

// RechargeMethod 充值方式
type RechargeMethod string

const (
	RechargeMethodManual   RechargeMethod = "manual"   // 手动充值
	RechargeMethodPurchase RechargeMethod = "purchase" // 购买充值
	RechargeMethodReward   RechargeMethod = "reward"   // 奖励
	RechargeMethodVIP      RechargeMethod = "vip"      // VIP赠送
)

// UserAIQuota 用户AI配额模型
type UserAIQuota struct {
	ID     uint `gorm:"primarykey" json:"id"`
	UserID uint `gorm:"not null;uniqueIndex" json:"user_id"`

	// 日配额
	DailyQuota   int       `gorm:"not null;default:10;check:daily_quota >= 0" json:"daily_quota"`
	DailyUsed    int       `gorm:"not null;default:0;check:daily_used >= 0" json:"daily_used"`
	DailyResetAt time.Time `gorm:"not null" json:"daily_reset_at"`

	// 月配额
	MonthlyQuota   int       `gorm:"not null;default:300;check:monthly_quota >= 0" json:"monthly_quota"`
	MonthlyUsed    int       `gorm:"not null;default:0;check:monthly_used >= 0" json:"monthly_used"`
	MonthlyResetAt time.Time `gorm:"not null" json:"monthly_reset_at"`

	// 永久配额（不重置）
	PermanentQuota int `gorm:"not null;default:0;check:permanent_quota >= 0" json:"permanent_quota"`

	// VIP相关
	IsVIP        bool       `gorm:"default:false" json:"is_vip"`
	VIPExpireAt  *time.Time `json:"vip_expire_at,omitempty"`

	// 统计字段
	TotalConsumed  int64      `gorm:"not null;default:0" json:"total_consumed"`
	LastConsumeAt  *time.Time `json:"last_consume_at,omitempty"`

	// 审计字段
	CreatedAt time.Time      `json:"created_at"`
	UpdatedAt time.Time      `json:"updated_at"`
	DeletedAt gorm.DeletedAt `gorm:"index" json:"-"`

	// 关联
	User *User `gorm:"foreignKey:UserID" json:"user,omitempty"`
}

// TableName 指定表名
func (UserAIQuota) TableName() string {
	return "user_ai_quotas"
}

// GetAvailableQuota 获取可用配额
func (q *UserAIQuota) GetAvailableQuota() int {
	dailyAvailable := q.DailyQuota - q.DailyUsed
	monthlyAvailable := q.MonthlyQuota - q.MonthlyUsed
	return q.PermanentQuota + monthlyAvailable + dailyAvailable
}

// GetDailyRemaining 获取今日剩余配额
func (q *UserAIQuota) GetDailyRemaining() int {
	remaining := q.DailyQuota - q.DailyUsed
	if remaining < 0 {
		return 0
	}
	return remaining
}

// GetMonthlyRemaining 获取本月剩余配额
func (q *UserAIQuota) GetMonthlyRemaining() int {
	remaining := q.MonthlyQuota - q.MonthlyUsed
	if remaining < 0 {
		return 0
	}
	return remaining
}

// NeedsDailyReset 检查是否需要重置日配额
func (q *UserAIQuota) NeedsDailyReset() bool {
	return time.Now().After(q.DailyResetAt)
}

// NeedsMonthlyReset 检查是否需要重置月配额
func (q *UserAIQuota) NeedsMonthlyReset() bool {
	return time.Now().After(q.MonthlyResetAt)
}

// AIQuotaLog AI配额使用日志
type AIQuotaLog struct {
	ID     uint `gorm:"primarykey" json:"id"`
	UserID uint `gorm:"not null;index:idx_ai_quota_logs_user_created" json:"user_id"`

	// 配额类型
	QuotaType QuotaType `gorm:"type:varchar(20);not null;index" json:"quota_type"`

	// 消耗数量
	Amount int `gorm:"not null;check:amount > 0" json:"amount"`

	// 服务类型
	ServiceType ServiceType `gorm:"type:varchar(50);not null;index" json:"service_type"`

	// 描述信息
	Description string `gorm:"type:text" json:"description,omitempty"`

	// 请求元数据
	RequestID string `gorm:"type:varchar(100)" json:"request_id,omitempty"`
	IPAddress string `gorm:"type:inet" json:"ip_address,omitempty"`
	UserAgent string `gorm:"type:text" json:"user_agent,omitempty"`

	// 审计字段
	CreatedAt time.Time      `gorm:"index:idx_ai_quota_logs_user_created" json:"created_at"`
	DeletedAt gorm.DeletedAt `gorm:"index" json:"-"`

	// 关联
	User *User `gorm:"foreignKey:UserID" json:"user,omitempty"`
}

// TableName 指定表名
func (AIQuotaLog) TableName() string {
	return "ai_quota_logs"
}

// QuotaRechargeLog 配额充值记录
type QuotaRechargeLog struct {
	ID     uint `gorm:"primarykey" json:"id"`
	UserID uint `gorm:"not null;index" json:"user_id"`

	// 充值配额类型
	QuotaType QuotaType `gorm:"type:varchar(20);not null" json:"quota_type"`

	// 充值数量
	Amount int `gorm:"not null;check:amount > 0" json:"amount"`

	// 充值原因
	Reason string `gorm:"type:varchar(100)" json:"reason,omitempty"`

	// 操作者ID
	OperatorID *uint `json:"operator_id,omitempty"`

	// 充值方式
	RechargeMethod RechargeMethod `gorm:"type:varchar(20);not null;default:'manual'" json:"recharge_method"`

	// 订单号
	OrderID string `gorm:"type:varchar(100);index" json:"order_id,omitempty"`

	// 审计字段
	CreatedAt time.Time      `gorm:"index" json:"created_at"`
	DeletedAt gorm.DeletedAt `gorm:"index" json:"-"`

	// 关联
	User     *User `gorm:"foreignKey:UserID" json:"user,omitempty"`
	Operator *User `gorm:"foreignKey:OperatorID" json:"operator,omitempty"`
}

// TableName 指定表名
func (QuotaRechargeLog) TableName() string {
	return "quota_recharge_logs"
}

// QuotaInfo 配额信息（用于API响应）
type QuotaInfo struct {
	// 配额统计
	DailyQuota     int `json:"daily_quota"`
	DailyUsed      int `json:"daily_used"`
	DailyRemaining int `json:"daily_remaining"`

	MonthlyQuota     int `json:"monthly_quota"`
	MonthlyUsed      int `json:"monthly_used"`
	MonthlyRemaining int `json:"monthly_remaining"`

	PermanentQuota int `json:"permanent_quota"`
	TotalAvailable int `json:"total_available"`

	// VIP信息
	IsVIP       bool       `json:"is_vip"`
	VIPExpireAt *time.Time `json:"vip_expire_at,omitempty"`

	// 重置时间
	DailyResetAt   time.Time `json:"daily_reset_at"`
	MonthlyResetAt time.Time `json:"monthly_reset_at"`

	// 统计
	TotalConsumed int64      `json:"total_consumed"`
	LastConsumeAt *time.Time `json:"last_consume_at,omitempty"`
}

// ToQuotaInfo 转换为QuotaInfo
func (q *UserAIQuota) ToQuotaInfo() *QuotaInfo {
	return &QuotaInfo{
		DailyQuota:       q.DailyQuota,
		DailyUsed:        q.DailyUsed,
		DailyRemaining:   q.GetDailyRemaining(),
		MonthlyQuota:     q.MonthlyQuota,
		MonthlyUsed:      q.MonthlyUsed,
		MonthlyRemaining: q.GetMonthlyRemaining(),
		PermanentQuota:   q.PermanentQuota,
		TotalAvailable:   q.GetAvailableQuota(),
		IsVIP:            q.IsVIP,
		VIPExpireAt:      q.VIPExpireAt,
		DailyResetAt:     q.DailyResetAt,
		MonthlyResetAt:   q.MonthlyResetAt,
		TotalConsumed:    q.TotalConsumed,
		LastConsumeAt:    q.LastConsumeAt,
	}
}
