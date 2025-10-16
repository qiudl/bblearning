package handlers

import (
	"net/http"
	"strconv"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/qiudl/bblearning-backend/internal/domain/models"
	"github.com/qiudl/bblearning-backend/internal/service/quota"
)

// QuotaHandler 配额处理器
type QuotaHandler struct {
	quotaService *quota.QuotaService
}

// NewQuotaHandler 创建配额处理器
func NewQuotaHandler(quotaService *quota.QuotaService) *QuotaHandler {
	return &QuotaHandler{
		quotaService: quotaService,
	}
}

// GetMyQuota 获取我的配额
// @Summary 获取我的配额
// @Tags Quota
// @Accept json
// @Produce json
// @Success 200 {object} map[string]interface{}
// @Router /api/v1/quota/my [get]
func (h *QuotaHandler) GetMyQuota(c *gin.Context) {
	userID := c.GetUint("user_id")

	quotaInfo, err := h.quotaService.GetUserQuota(c.Request.Context(), userID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"code":    3000,
			"message": "获取配额失败",
			"error":   err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"code":    0,
		"message": "success",
		"data":    quotaInfo,
	})
}

// GetQuotaLogs 获取配额使用日志
// @Summary 获取配额使用日志
// @Tags Quota
// @Accept json
// @Produce json
// @Param page query int false "页码" default(1)
// @Param page_size query int false "每页数量" default(20)
// @Success 200 {object} map[string]interface{}
// @Router /api/v1/quota/logs [get]
func (h *QuotaHandler) GetQuotaLogs(c *gin.Context) {
	userID := c.GetUint("user_id")

	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	pageSize, _ := strconv.Atoi(c.DefaultQuery("page_size", "20"))

	logs, total, err := h.quotaService.GetQuotaLogs(c.Request.Context(), userID, page, pageSize)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"code":    3000,
			"message": "获取日志失败",
			"error":   err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"code":    0,
		"message": "success",
		"data": gin.H{
			"list":  logs,
			"total": total,
			"page":  page,
			"size":  pageSize,
		},
	})
}

// GetRechargeLogs 获取充值记录
// @Summary 获取充值记录
// @Tags Quota
// @Accept json
// @Produce json
// @Param page query int false "页码" default(1)
// @Param page_size query int false "每页数量" default(20)
// @Success 200 {object} map[string]interface{}
// @Router /api/v1/quota/recharge-logs [get]
func (h *QuotaHandler) GetRechargeLogs(c *gin.Context) {
	userID := c.GetUint("user_id")

	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	pageSize, _ := strconv.Atoi(c.DefaultQuery("page_size", "20"))

	logs, total, err := h.quotaService.GetRechargeLogs(c.Request.Context(), userID, page, pageSize)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"code":    3000,
			"message": "获取充值记录失败",
			"error":   err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"code":    0,
		"message": "success",
		"data": gin.H{
			"list":  logs,
			"total": total,
			"page":  page,
			"size":  pageSize,
		},
	})
}

// RechargeQuotaRequest 充值请求
type RechargeQuotaRequest struct {
	UserID     uint              `json:"user_id" binding:"required"`
	QuotaType  models.QuotaType  `json:"quota_type" binding:"required,oneof=daily monthly permanent"`
	Amount     int               `json:"amount" binding:"required,min=1"`
	Reason     string            `json:"reason"`
	Method     models.RechargeMethod `json:"method" binding:"omitempty,oneof=manual purchase reward vip"`
}

// RechargeQuota 充值配额（管理员）
// @Summary 充值配额
// @Tags Quota
// @Accept json
// @Produce json
// @Param request body RechargeQuotaRequest true "充值请求"
// @Success 200 {object} map[string]interface{}
// @Router /api/v1/quota/recharge [post]
func (h *QuotaHandler) RechargeQuota(c *gin.Context) {
	operatorID := c.GetUint("user_id")

	var req RechargeQuotaRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"code":    1000,
			"message": "参数错误",
			"error":   err.Error(),
		})
		return
	}

	// 默认充值方式
	method := req.Method
	if method == "" {
		method = models.RechargeMethodManual
	}

	err := h.quotaService.RechargeQuota(
		c.Request.Context(),
		req.UserID,
		req.QuotaType,
		req.Amount,
		req.Reason,
		&operatorID,
		method,
	)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"code":    3000,
			"message": "充值失败",
			"error":   err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"code":    0,
		"message": "充值成功",
	})
}

// SetVIPRequest 设置VIP请求
type SetVIPRequest struct {
	UserID     uint   `json:"user_id" binding:"required"`
	Days       int    `json:"days" binding:"required,min=1"`
	ExtraQuota int    `json:"extra_quota" binding:"min=0"`
}

// SetVIP 设置VIP（管理员）
// @Summary 设置VIP
// @Tags Quota
// @Accept json
// @Produce json
// @Param request body SetVIPRequest true "VIP请求"
// @Success 200 {object} map[string]interface{}
// @Router /api/v1/quota/vip [post]
func (h *QuotaHandler) SetVIP(c *gin.Context) {
	operatorID := c.GetUint("user_id")

	var req SetVIPRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"code":    1000,
			"message": "参数错误",
			"error":   err.Error(),
		})
		return
	}

	expireAt := time.Now().AddDate(0, 0, req.Days)

	err := h.quotaService.SetVIP(
		c.Request.Context(),
		req.UserID,
		expireAt,
		req.ExtraQuota,
		&operatorID,
	)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"code":    3000,
			"message": "设置VIP失败",
			"error":   err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"code":    0,
		"message": "设置VIP成功",
	})
}

// CancelVIP 取消VIP（管理员）
// @Summary 取消VIP
// @Tags Quota
// @Accept json
// @Produce json
// @Param user_id path int true "用户ID"
// @Success 200 {object} map[string]interface{}
// @Router /api/v1/quota/vip/:user_id [delete]
func (h *QuotaHandler) CancelVIP(c *gin.Context) {
	userIDStr := c.Param("user_id")
	userID, err := strconv.ParseUint(userIDStr, 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"code":    1000,
			"message": "用户ID格式错误",
		})
		return
	}

	err = h.quotaService.CancelVIP(c.Request.Context(), uint(userID))
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"code":    3000,
			"message": "取消VIP失败",
			"error":   err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"code":    0,
		"message": "取消VIP成功",
	})
}

// CheckQuota 检查配额（不扣减）
// @Summary 检查配额
// @Tags Quota
// @Accept json
// @Produce json
// @Param amount query int true "需要的配额数量"
// @Success 200 {object} map[string]interface{}
// @Router /api/v1/quota/check [get]
func (h *QuotaHandler) CheckQuota(c *gin.Context) {
	userID := c.GetUint("user_id")

	amountStr := c.Query("amount")
	amount, err := strconv.Atoi(amountStr)
	if err != nil || amount <= 0 {
		c.JSON(http.StatusBadRequest, gin.H{
			"code":    1000,
			"message": "amount参数错误",
		})
		return
	}

	sufficient, err := h.quotaService.CheckQuota(c.Request.Context(), userID, amount)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"code":    3000,
			"message": "检查配额失败",
			"error":   err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"code":    0,
		"message": "success",
		"data": gin.H{
			"sufficient": sufficient,
			"amount":     amount,
		},
	})
}
