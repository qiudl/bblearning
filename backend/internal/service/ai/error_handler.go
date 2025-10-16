package ai

import (
	"context"
	"encoding/json"
	"fmt"
	"io"
	"strings"
	"time"

	appErrors "github.com/qiudl/bblearning-backend/internal/pkg/errors"
	"github.com/qiudl/bblearning-backend/internal/pkg/logger"
	"github.com/qiudl/bblearning-backend/internal/pkg/retry"
	openai "github.com/sashabaranov/go-openai"
)

// AI服务超时配置
const (
	DefaultAITimeout  = 30 * time.Second // 默认超时时间
	StreamAITimeout   = 60 * time.Second // 流式响应超时时间
	DiagnoseTimeout   = 45 * time.Second // 诊断超时时间
	GenerateTimeout   = 40 * time.Second // 生成题目超时时间
)

// callAIWithRetry AI调用带重试
func (s *AIService) callAIWithRetry(ctx context.Context, timeout time.Duration, fn func(ctx context.Context) error) error {
	return retry.WithTimeout(ctx, timeout, retry.AIServiceConfig, func(ctx context.Context) error {
		err := fn(ctx)
		if err != nil {
			return wrapAIError(err)
		}
		return nil
	})
}

// callAIWithRetryAndResult AI调用带重试（返回结果）
func (s *AIService) callAIWithRetryAndResult[T any](ctx context.Context, timeout time.Duration, fn func(ctx context.Context) (T, error)) (T, error) {
	return retry.WithTimeoutAndResult(ctx, timeout, retry.AIServiceConfig, func(ctx context.Context) (T, error) {
		result, err := fn(ctx)
		if err != nil {
			return result, wrapAIError(err)
		}
		return result, nil
	})
}

// wrapAIError 包装AI错误
func wrapAIError(err error) error {
	if err == nil {
		return nil
	}

	// 已经是AppError，直接返回
	if _, ok := err.(*appErrors.AppError); ok {
		return err
	}

	// Context错误
	if err == context.Canceled {
		return appErrors.New(appErrors.CodeInternalError, "请求已取消")
	}
	if err == context.DeadlineExceeded {
		return appErrors.NewAITimeoutError()
	}

	// OpenAI SDK错误
	errMsg := err.Error()
	errMsgLower := strings.ToLower(errMsg)

	// 限流错误
	if strings.Contains(errMsgLower, "rate limit") || strings.Contains(errMsgLower, "too many requests") {
		return appErrors.NewAIRateLimitError(60)
	}

	// 超时错误
	if strings.Contains(errMsgLower, "timeout") || strings.Contains(errMsgLower, "deadline") {
		return appErrors.NewAITimeoutError()
	}

	// API密钥错误
	if strings.Contains(errMsgLower, "api key") || strings.Contains(errMsgLower, "unauthorized") {
		return appErrors.New(appErrors.CodeAIServiceError, "AI服务认证失败，请检查配置").
			WithRetryable(false)
	}

	// 配额不足
	if strings.Contains(errMsgLower, "quota") || strings.Contains(errMsgLower, "insufficient") {
		return appErrors.New(appErrors.CodeAIServiceError, "AI服务配额不足，请联系管理员").
			WithRetryable(false)
	}

	// 模型不存在
	if strings.Contains(errMsgLower, "model not found") || strings.Contains(errMsgLower, "invalid model") {
		return appErrors.New(appErrors.CodeAIServiceError, "AI模型配置错误").
			WithRetryable(false)
	}

	// 内容过滤
	if strings.Contains(errMsgLower, "content filter") || strings.Contains(errMsgLower, "content policy") {
		return appErrors.New(appErrors.CodeAIServiceError, "内容不符合AI服务政策，请修改后重试").
			WithRetryable(false)
	}

	// 网络连接错误
	if strings.Contains(errMsgLower, "connection") || strings.Contains(errMsgLower, "network") {
		return appErrors.NewAIServiceError(err).
			WithDetail("网络连接失败")
	}

	// 其他AI服务错误
	return appErrors.NewAIServiceError(err)
}

// safeParseJSON 安全的JSON解析
func safeParseJSON(content string, v interface{}) error {
	// 清理可能的markdown代码块标记
	content = strings.TrimSpace(content)
	content = strings.TrimPrefix(content, "```json")
	content = strings.TrimPrefix(content, "```")
	content = strings.TrimSuffix(content, "```")
	content = strings.TrimSpace(content)

	err := json.Unmarshal([]byte(content), v)
	if err != nil {
		logger.Error(fmt.Sprintf("Failed to parse AI response: %s", content))
		return appErrors.New(appErrors.CodeAIServiceError, "AI返回格式错误，请重试").
			WithDetail(err.Error()).
			WithRetryable(true)
	}
	return nil
}

// validateAIResponse 验证AI响应
func validateAIResponse(resp openai.ChatCompletionResponse) error {
	if len(resp.Choices) == 0 {
		return appErrors.New(appErrors.CodeAIServiceError, "AI服务返回为空，请重试").
			WithRetryable(true)
	}

	content := resp.Choices[0].Message.Content
	if strings.TrimSpace(content) == "" {
		return appErrors.New(appErrors.CodeAIServiceError, "AI服务返回为空，请重试").
			WithRetryable(true)
	}

	return nil
}

// handleStreamError 处理流式响应错误
func handleStreamError(err error) error {
	if err == nil {
		return nil
	}

	if err == io.EOF {
		return nil // 正常结束
	}

	return wrapAIError(err)
}

// logAIRequest 记录AI请求（用于监控和调试）
func logAIRequest(provider, model, operation string, startTime time.Time) {
	duration := time.Since(startTime)
	logger.InfoWithFields("AI request completed", map[string]interface{}{
		"provider":  provider,
		"model":     model,
		"operation": operation,
		"duration":  duration.Milliseconds(),
	})
}

// logAIError 记录AI错误
func logAIError(provider, model, operation string, err error, startTime time.Time) {
	duration := time.Since(startTime)
	logger.ErrorWithFields("AI request failed", map[string]interface{}{
		"provider":  provider,
		"model":     model,
		"operation": operation,
		"duration":  duration.Milliseconds(),
		"error":     err.Error(),
	})
}
