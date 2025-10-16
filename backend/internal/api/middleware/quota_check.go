package middleware

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/qiudl/bblearning-backend/internal/domain/models"
	"github.com/qiudl/bblearning-backend/internal/service/quota"
)

// QuotaCheckMiddleware 配额检查中间件
func QuotaCheckMiddleware(quotaService *quota.QuotaService, serviceType models.ServiceType, amount int) gin.HandlerFunc {
	return func(c *gin.Context) {
		// 获取用户ID
		userIDInterface, exists := c.Get("user_id")
		if !exists {
			c.JSON(http.StatusUnauthorized, gin.H{
				"code":    1001,
				"message": "未登录",
			})
			c.Abort()
			return
		}

		userID, ok := userIDInterface.(uint)
		if !ok {
			c.JSON(http.StatusInternalServerError, gin.H{
				"code":    3000,
				"message": "用户ID格式错误",
			})
			c.Abort()
			return
		}

		// 检查并扣减配额
		err := quotaService.CheckAndConsumeQuota(c.Request.Context(), userID, amount, serviceType)
		if err != nil {
			c.JSON(http.StatusForbidden, gin.H{
				"code":    1003,
				"message": err.Error(),
				"data": gin.H{
					"required": amount,
					"service":  serviceType,
				},
			})
			c.Abort()
			return
		}

		// 配额检查通过，继续处理请求
		c.Next()
	}
}

// QuotaCheckWithDynamicAmount 动态配额检查中间件（从请求中获取amount）
func QuotaCheckWithDynamicAmount(quotaService *quota.QuotaService, serviceType models.ServiceType, amountKey string) gin.HandlerFunc {
	return func(c *gin.Context) {
		// 获取用户ID
		userIDInterface, exists := c.Get("user_id")
		if !exists {
			c.JSON(http.StatusUnauthorized, gin.H{
				"code":    1001,
				"message": "未登录",
			})
			c.Abort()
			return
		}

		userID := userIDInterface.(uint)

		// 从请求参数中获取amount
		var amount int
		if amountValue, exists := c.Get(amountKey); exists {
			if amountInt, ok := amountValue.(int); ok {
				amount = amountInt
			} else {
				amount = 1 // 默认值
			}
		} else {
			amount = 1 // 默认值
		}

		// 检查并扣减配额
		err := quotaService.CheckAndConsumeQuota(c.Request.Context(), userID, amount, serviceType)
		if err != nil {
			c.JSON(http.StatusForbidden, gin.H{
				"code":    1003,
				"message": err.Error(),
			})
			c.Abort()
			return
		}

		c.Next()
	}
}
