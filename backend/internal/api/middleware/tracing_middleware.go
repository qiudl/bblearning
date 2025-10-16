package middleware

import (
	"time"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/qiudl/bblearning-backend/internal/pkg/logger"
	"github.com/qiudl/bblearning-backend/internal/pkg/metrics"
)

// TracingMiddleware 请求追踪中间件
// 为每个请求生成唯一的Request ID，记录请求日志和指标
func TracingMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		// 生成请求ID
		requestID := c.GetHeader("X-Request-ID")
		if requestID == "" {
			requestID = uuid.New().String()
		}

		// 设置到上下文
		c.Set("request_id", requestID)
		c.Header("X-Request-ID", requestID)

		// 记录开始时间
		startTime := time.Now()

		// 处理请求
		c.Next()

		// 计算耗时
		duration := time.Since(startTime)

		// 获取用户ID
		userID, exists := c.Get("user_id")
		var uid uint
		if exists {
			if id, ok := userID.(uint); ok {
				uid = id
			}
		}

		// 记录请求日志
		requestLog := &logger.RequestLogger{
			RequestID:  requestID,
			Method:     c.Request.Method,
			Path:       c.Request.URL.Path,
			UserID:     uid,
			IP:         c.ClientIP(),
			UserAgent:  c.Request.UserAgent(),
			StatusCode: c.Writer.Status(),
			Latency:    duration.Milliseconds(),
		}

		// 如果有错误，记录错误信息
		if len(c.Errors) > 0 {
			requestLog.Error = c.Errors.String()
		}

		requestLog.LogRequest()

		// 记录指标
		metrics.GetMetrics().RecordHTTPRequest(
			c.Request.Method,
			c.Request.URL.Path,
			c.Writer.Status(),
			duration,
		)
	}
}

// RequestIDMiddleware 简化版请求ID中间件（仅生成Request ID）
func RequestIDMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		requestID := c.GetHeader("X-Request-ID")
		if requestID == "" {
			requestID = uuid.New().String()
		}
		c.Set("request_id", requestID)
		c.Header("X-Request-ID", requestID)
		c.Next()
	}
}

// GetRequestID 从上下文获取Request ID
func GetRequestID(c *gin.Context) string {
	if requestID, exists := c.Get("request_id"); exists {
		if id, ok := requestID.(string); ok {
			return id
		}
	}
	return ""
}
