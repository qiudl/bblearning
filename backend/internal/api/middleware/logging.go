package middleware

import (
	"bytes"
	"io"
	"time"

	"github.com/gin-gonic/gin"
	"go.uber.org/zap"
	"go.uber.org/zap/zapcore"
)

// responseWriter 包装gin.ResponseWriter以捕获响应体
type responseWriter struct {
	gin.ResponseWriter
	body *bytes.Buffer
}

func (w *responseWriter) Write(b []byte) (int, error) {
	w.body.Write(b)
	return w.ResponseWriter.Write(b)
}

// LoggingMiddleware 结构化日志中间件
func LoggingMiddleware(logger *zap.Logger) gin.HandlerFunc {
	return func(c *gin.Context) {
		// 记录请求开始时间
		start := time.Now()

		// 读取请求体（用于日志）
		var requestBody []byte
		if c.Request.Body != nil {
			requestBody, _ = io.ReadAll(c.Request.Body)
			// 恢复请求体，以便后续处理器可以读取
			c.Request.Body = io.NopCloser(bytes.NewBuffer(requestBody))
		}

		// 包装ResponseWriter以捕获响应
		blw := &responseWriter{
			ResponseWriter: c.Writer,
			body:           bytes.NewBufferString(""),
		}
		c.Writer = blw

		// 处理请求
		c.Next()

		// 计算请求持续时间
		duration := time.Since(start)

		// 构建日志字段
		fields := []zapcore.Field{
			zap.String("method", c.Request.Method),
			zap.String("path", c.Request.URL.Path),
			zap.String("query", c.Request.URL.RawQuery),
			zap.String("ip", c.ClientIP()),
			zap.String("user_agent", c.Request.UserAgent()),
			zap.Int("status", c.Writer.Status()),
			zap.Duration("latency", duration),
			zap.Int("response_size", c.Writer.Size()),
		}

		// 添加用户ID（如果已认证）
		if userID, exists := c.Get("user_id"); exists {
			fields = append(fields, zap.Any("user_id", userID))
		}

		// 添加请求ID（如果存在）
		if requestID := c.GetHeader("X-Request-ID"); requestID != "" {
			fields = append(fields, zap.String("request_id", requestID))
		}

		// 记录请求体（仅用于错误情况，且排除敏感路径）
		if c.Writer.Status() >= 400 && !isSensitivePath(c.Request.URL.Path) {
			if len(requestBody) > 0 && len(requestBody) < 1024 { // 限制大小
				fields = append(fields, zap.String("request_body", string(requestBody)))
			}
		}

		// 记录错误信息
		if len(c.Errors) > 0 {
			fields = append(fields, zap.String("error", c.Errors.String()))
		}

		// 根据状态码选择日志级别
		switch {
		case c.Writer.Status() >= 500:
			logger.Error("HTTP Request", fields...)
		case c.Writer.Status() >= 400:
			logger.Warn("HTTP Request", fields...)
		case duration > 5*time.Second:
			// 慢请求警告
			logger.Warn("Slow HTTP Request", fields...)
		default:
			logger.Info("HTTP Request", fields...)
		}
	}
}

// isSensitivePath 检查是否是敏感路径（不记录请求体）
func isSensitivePath(path string) bool {
	sensitivePaths := []string{
		"/api/v1/auth/login",
		"/api/v1/auth/register",
		"/api/v1/users/me/password",
	}

	for _, sp := range sensitivePaths {
		if path == sp {
			return true
		}
	}
	return false
}

// RequestIDMiddleware 添加请求ID
func RequestIDMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		requestID := c.GetHeader("X-Request-ID")
		if requestID == "" {
			// 生成请求ID
			requestID = generateRequestID()
		}
		c.Header("X-Request-ID", requestID)
		c.Set("request_id", requestID)
		c.Next()
	}
}

// generateRequestID 生成请求ID
func generateRequestID() string {
	return time.Now().Format("20060102150405") + "-" + randString(8)
}

// randString 生成随机字符串
func randString(n int) string {
	const letters = "abcdefghijklmnopqrstuvwxyz0123456789"
	b := make([]byte, n)
	for i := range b {
		b[i] = letters[time.Now().UnixNano()%int64(len(letters))]
	}
	return string(b)
}
