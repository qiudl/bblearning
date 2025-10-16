package errors

import (
	"fmt"
)

// ErrorCode 错误码类型
type ErrorCode int

// 错误码定义
const (
	// 成功
	CodeSuccess ErrorCode = 0

	// 客户端错误 1xxx
	CodeInvalidRequest   ErrorCode = 1000 // 请求参数错误
	CodeUnauthorized     ErrorCode = 1001 // 未授权
	CodeTokenExpired     ErrorCode = 1002 // Token过期
	CodeInsufficientQuota ErrorCode = 1003 // 配额不足
	CodeForbidden        ErrorCode = 1004 // 禁止访问
	CodeRateLimitExceeded ErrorCode = 1005 // 请求频率超限

	// 资源错误 2xxx
	CodeNotFound        ErrorCode = 2000 // 资源不存在
	CodeAlreadyExists   ErrorCode = 2001 // 资源已存在
	CodeConflict        ErrorCode = 2002 // 资源冲突
	CodeResourceDeleted ErrorCode = 2003 // 资源已删除

	// 服务器错误 3xxx
	CodeInternalError  ErrorCode = 3000 // 服务器内部错误
	CodeDatabaseError  ErrorCode = 3001 // 数据库错误
	CodeCacheError     ErrorCode = 3002 // 缓存错误
	CodeStorageError   ErrorCode = 3003 // 存储错误
	CodeServiceTimeout ErrorCode = 3004 // 服务超时

	// 外部服务错误 4xxx
	CodeExternalServiceError ErrorCode = 4000 // 外部服务错误
	CodeAIServiceError       ErrorCode = 4001 // AI服务错误
	CodeAIServiceTimeout     ErrorCode = 4002 // AI服务超时
	CodeAIRateLimitExceeded  ErrorCode = 4003 // AI API限流
	CodeOCRServiceError      ErrorCode = 4004 // OCR服务错误
	CodeOCRServiceTimeout    ErrorCode = 4005 // OCR服务超时
)

// ErrorType 错误类型
type ErrorType string

const (
	TypeValidation  ErrorType = "validation"   // 参数验证错误
	TypeAuth        ErrorType = "auth"         // 认证授权错误
	TypeBusiness    ErrorType = "business"     // 业务逻辑错误
	TypeSystem      ErrorType = "system"       // 系统错误
	TypeExternal    ErrorType = "external"     // 外部服务错误
	TypeRateLimit   ErrorType = "rate_limit"   // 限流错误
)

// AppError 应用错误结构
type AppError struct {
	Code      ErrorCode              // 错误码
	Type      ErrorType              // 错误类型
	Message   string                 // 错误消息（用户可见）
	Detail    string                 // 错误详情（开发调试用）
	Err       error                  // 原始错误
	Retryable bool                   // 是否可重试
	Meta      map[string]interface{} // 额外元数据
}

// Error 实现error接口
func (e *AppError) Error() string {
	if e.Detail != "" {
		return fmt.Sprintf("[%d] %s: %s", e.Code, e.Message, e.Detail)
	}
	return fmt.Sprintf("[%d] %s", e.Code, e.Message)
}

// Unwrap 支持errors.Unwrap
func (e *AppError) Unwrap() error {
	return e.Err
}

// New 创建新错误
func New(code ErrorCode, message string) *AppError {
	return &AppError{
		Code:      code,
		Type:      inferType(code),
		Message:   message,
		Retryable: isRetryable(code),
		Meta:      make(map[string]interface{}),
	}
}

// Wrap 包装已有错误
func Wrap(err error, code ErrorCode, message string) *AppError {
	if err == nil {
		return nil
	}

	// 如果已经是AppError，更新信息
	if appErr, ok := err.(*AppError); ok {
		appErr.Message = message
		return appErr
	}

	return &AppError{
		Code:      code,
		Type:      inferType(code),
		Message:   message,
		Detail:    err.Error(),
		Err:       err,
		Retryable: isRetryable(code),
		Meta:      make(map[string]interface{}),
	}
}

// WithDetail 添加错误详情
func (e *AppError) WithDetail(detail string) *AppError {
	e.Detail = detail
	return e
}

// WithMeta 添加元数据
func (e *AppError) WithMeta(key string, value interface{}) *AppError {
	if e.Meta == nil {
		e.Meta = make(map[string]interface{})
	}
	e.Meta[key] = value
	return e
}

// WithRetryable 设置是否可重试
func (e *AppError) WithRetryable(retryable bool) *AppError {
	e.Retryable = retryable
	return e
}

// inferType 根据错误码推断错误类型
func inferType(code ErrorCode) ErrorType {
	switch {
	case code >= 1000 && code < 1100:
		return TypeValidation
	case code >= 1100 && code < 1200:
		return TypeAuth
	case code >= 2000 && code < 3000:
		return TypeBusiness
	case code >= 3000 && code < 4000:
		return TypeSystem
	case code >= 4000 && code < 5000:
		return TypeExternal
	case code == CodeRateLimitExceeded || code == CodeAIRateLimitExceeded:
		return TypeRateLimit
	default:
		return TypeSystem
	}
}

// isRetryable 判断错误是否可重试
func isRetryable(code ErrorCode) bool {
	retryableCodes := map[ErrorCode]bool{
		CodeServiceTimeout:       true,
		CodeAIServiceTimeout:     true,
		CodeOCRServiceTimeout:    true,
		CodeAIRateLimitExceeded:  true,
		CodeRateLimitExceeded:    true,
		CodeExternalServiceError: true,
		CodeDatabaseError:        true,
		CodeCacheError:           true,
	}
	return retryableCodes[code]
}

// 常用错误构造函数

// NewValidationError 参数验证错误
func NewValidationError(message string) *AppError {
	return New(CodeInvalidRequest, message)
}

// NewUnauthorizedError 未授权错误
func NewUnauthorizedError(message string) *AppError {
	return New(CodeUnauthorized, message)
}

// NewInsufficientQuotaError 配额不足错误
func NewInsufficientQuotaError(required, available int) *AppError {
	return New(CodeInsufficientQuota, "配额不足，请充值或等待重置").
		WithMeta("required", required).
		WithMeta("available", available)
}

// NewNotFoundError 资源不存在错误
func NewNotFoundError(resource string) *AppError {
	return New(CodeNotFound, fmt.Sprintf("%s不存在", resource))
}

// NewAIServiceError AI服务错误
func NewAIServiceError(err error) *AppError {
	return Wrap(err, CodeAIServiceError, "AI服务暂时不可用，请稍后再试").
		WithRetryable(true)
}

// NewAITimeoutError AI服务超时
func NewAITimeoutError() *AppError {
	return New(CodeAIServiceTimeout, "AI服务响应超时，请稍后重试").
		WithRetryable(true)
}

// NewAIRateLimitError AI限流错误
func NewAIRateLimitError(retryAfter int) *AppError {
	return New(CodeAIRateLimitExceeded, fmt.Sprintf("请求过于频繁，请%d秒后重试", retryAfter)).
		WithMeta("retry_after", retryAfter).
		WithRetryable(true)
}

// NewOCRServiceError OCR服务错误
func NewOCRServiceError(err error) *AppError {
	return Wrap(err, CodeOCRServiceError, "图片识别服务暂时不可用，请稍后再试").
		WithRetryable(true)
}

// NewInternalError 内部错误
func NewInternalError(err error) *AppError {
	return Wrap(err, CodeInternalError, "服务器内部错误，请稍后再试")
}

// NewDatabaseError 数据库错误
func NewDatabaseError(err error) *AppError {
	return Wrap(err, CodeDatabaseError, "数据库操作失败，请稍后再试").
		WithRetryable(true)
}
