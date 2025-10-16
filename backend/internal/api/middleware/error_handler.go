package middleware

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/qiudl/bblearning-backend/internal/pkg/errors"
	"github.com/qiudl/bblearning-backend/internal/pkg/logger"
)

// ErrorHandler 错误处理中间件
func ErrorHandler() gin.HandlerFunc {
	return func(c *gin.Context) {
		c.Next()

		// 检查是否有错误
		if len(c.Errors) == 0 {
			return
		}

		// 获取最后一个错误
		err := c.Errors.Last().Err

		// 转换为AppError
		var appErr *errors.AppError
		if e, ok := err.(*errors.AppError); ok {
			appErr = e
		} else {
			// 未知错误，包装为内部错误
			appErr = errors.NewInternalError(err)
		}

		// 记录错误日志
		logError(c, appErr)

		// 构建响应
		response := buildErrorResponse(appErr)

		// 确定HTTP状态码
		statusCode := getHTTPStatus(appErr.Code)

		// 返回JSON响应
		c.JSON(statusCode, response)
	}
}

// logError 记录错误日志
func logError(c *gin.Context, err *errors.AppError) {
	fields := map[string]interface{}{
		"error_code": err.Code,
		"error_type": err.Type,
		"path":       c.Request.URL.Path,
		"method":     c.Request.Method,
		"user_agent": c.Request.UserAgent(),
	}

	if userID, exists := c.Get("user_id"); exists {
		fields["user_id"] = userID
	}

	if err.Meta != nil {
		for k, v := range err.Meta {
			fields[k] = v
		}
	}

	// 根据错误类型选择日志级别
	switch err.Type {
	case errors.TypeValidation, errors.TypeAuth:
		logger.WarnWithFields("Request error", fields)
	case errors.TypeExternal, errors.TypeRateLimit:
		logger.WarnWithFields("External service error", fields)
	case errors.TypeSystem:
		logger.ErrorWithFields("System error", fields)
	default:
		logger.InfoWithFields("Business error", fields)
	}

	// 如果有原始错误，记录详细信息
	if err.Err != nil {
		logger.Error("Original error: " + err.Err.Error())
	}
}

// buildErrorResponse 构建错误响应
func buildErrorResponse(err *errors.AppError) gin.H {
	response := gin.H{
		"code":    err.Code,
		"message": err.Message,
	}

	// 添加错误类型
	response["type"] = err.Type

	// 可重试标记
	if err.Retryable {
		response["retryable"] = true
	}

	// 添加元数据（仅返回安全的元数据）
	if err.Meta != nil && len(err.Meta) > 0 {
		safeMeta := make(map[string]interface{})
		for k, v := range err.Meta {
			// 只返回特定的安全字段
			switch k {
			case "required", "available", "retry_after", "field", "limit", "remaining":
				safeMeta[k] = v
			}
		}
		if len(safeMeta) > 0 {
			response["data"] = safeMeta
		}
	}

	return response
}

// getHTTPStatus 根据错误码获取HTTP状态码
func getHTTPStatus(code errors.ErrorCode) int {
	switch code {
	// 客户端错误
	case errors.CodeInvalidRequest:
		return http.StatusBadRequest
	case errors.CodeUnauthorized, errors.CodeTokenExpired:
		return http.StatusUnauthorized
	case errors.CodeInsufficientQuota, errors.CodeForbidden:
		return http.StatusForbidden
	case errors.CodeRateLimitExceeded, errors.CodeAIRateLimitExceeded:
		return http.StatusTooManyRequests

	// 资源错误
	case errors.CodeNotFound:
		return http.StatusNotFound
	case errors.CodeAlreadyExists:
		return http.StatusConflict
	case errors.CodeConflict:
		return http.StatusConflict

	// 服务器错误
	case errors.CodeServiceTimeout, errors.CodeAIServiceTimeout, errors.CodeOCRServiceTimeout:
		return http.StatusGatewayTimeout
	case errors.CodeInternalError, errors.CodeDatabaseError, errors.CodeCacheError, errors.CodeStorageError:
		return http.StatusInternalServerError

	// 外部服务错误
	case errors.CodeExternalServiceError, errors.CodeAIServiceError, errors.CodeOCRServiceError:
		return http.StatusBadGateway

	default:
		return http.StatusInternalServerError
	}
}

// AbortWithError 中止请求并设置错误
func AbortWithError(c *gin.Context, err *errors.AppError) {
	c.Error(err)
	c.Abort()
}

// RespondWithError 直接响应错误（不经过错误处理中间件）
func RespondWithError(c *gin.Context, err *errors.AppError) {
	logError(c, err)
	response := buildErrorResponse(err)
	statusCode := getHTTPStatus(err.Code)
	c.JSON(statusCode, response)
}
