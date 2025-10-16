package retry

import (
	"context"
	"fmt"
	"math"
	"time"

	"github.com/qiudl/bblearning-backend/internal/pkg/errors"
	"github.com/qiudl/bblearning-backend/internal/pkg/logger"
)

// Strategy 重试策略
type Strategy string

const (
	StrategyFixed       Strategy = "fixed"       // 固定间隔
	StrategyExponential Strategy = "exponential" // 指数退避
	StrategyLinear      Strategy = "linear"      // 线性增长
)

// Config 重试配置
type Config struct {
	MaxAttempts  int           // 最大重试次数
	InitialDelay time.Duration // 初始延迟
	MaxDelay     time.Duration // 最大延迟
	Strategy     Strategy      // 重试策略
	Multiplier   float64       // 倍数（用于指数退避）
}

// DefaultConfig 默认配置
var DefaultConfig = Config{
	MaxAttempts:  3,
	InitialDelay: 1 * time.Second,
	MaxDelay:     30 * time.Second,
	Strategy:     StrategyExponential,
	Multiplier:   2.0,
}

// AIServiceConfig AI服务重试配置
var AIServiceConfig = Config{
	MaxAttempts:  3,
	InitialDelay: 2 * time.Second,
	MaxDelay:     15 * time.Second,
	Strategy:     StrategyExponential,
	Multiplier:   2.0,
}

// OCRServiceConfig OCR服务重试配置
var OCRServiceConfig = Config{
	MaxAttempts:  2,
	InitialDelay: 1 * time.Second,
	MaxDelay:     10 * time.Second,
	Strategy:     StrategyFixed,
	Multiplier:   1.0,
}

// Func 可重试的函数类型
type Func func(ctx context.Context) error

// Do 执行重试逻辑
func Do(ctx context.Context, config Config, fn Func) error {
	var lastErr error

	for attempt := 0; attempt < config.MaxAttempts; attempt++ {
		// 执行函数
		err := fn(ctx)

		// 成功则返回
		if err == nil {
			if attempt > 0 {
				logger.Info(fmt.Sprintf("Retry successful after %d attempts", attempt))
			}
			return nil
		}

		lastErr = err

		// 检查是否可重试
		if !isRetryable(err) {
			logger.Warn(fmt.Sprintf("Error is not retryable: %v", err))
			return err
		}

		// 检查是否还有重试机会
		if attempt < config.MaxAttempts-1 {
			delay := calculateDelay(config, attempt)
			logger.Warn(fmt.Sprintf("Attempt %d failed, retrying in %v: %v", attempt+1, delay, err))

			// 等待
			select {
			case <-time.After(delay):
				// 继续重试
			case <-ctx.Done():
				return fmt.Errorf("retry cancelled: %w", ctx.Err())
			}
		}
	}

	logger.Error(fmt.Sprintf("All %d retry attempts failed: %v", config.MaxAttempts, lastErr))
	return fmt.Errorf("max retry attempts (%d) exceeded: %w", config.MaxAttempts, lastErr)
}

// DoWithResult 执行重试逻辑并返回结果
func DoWithResult[T any](ctx context.Context, config Config, fn func(ctx context.Context) (T, error)) (T, error) {
	var result T
	var lastErr error

	for attempt := 0; attempt < config.MaxAttempts; attempt++ {
		var err error
		result, err = fn(ctx)

		if err == nil {
			if attempt > 0 {
				logger.Info(fmt.Sprintf("Retry successful after %d attempts", attempt))
			}
			return result, nil
		}

		lastErr = err

		if !isRetryable(err) {
			logger.Warn(fmt.Sprintf("Error is not retryable: %v", err))
			return result, err
		}

		if attempt < config.MaxAttempts-1 {
			delay := calculateDelay(config, attempt)
			logger.Warn(fmt.Sprintf("Attempt %d failed, retrying in %v: %v", attempt+1, delay, err))

			select {
			case <-time.After(delay):
			case <-ctx.Done():
				return result, fmt.Errorf("retry cancelled: %w", ctx.Err())
			}
		}
	}

	logger.Error(fmt.Sprintf("All %d retry attempts failed: %v", config.MaxAttempts, lastErr))
	return result, fmt.Errorf("max retry attempts (%d) exceeded: %w", config.MaxAttempts, lastErr)
}

// calculateDelay 计算延迟时间
func calculateDelay(config Config, attempt int) time.Duration {
	var delay time.Duration

	switch config.Strategy {
	case StrategyFixed:
		delay = config.InitialDelay

	case StrategyLinear:
		delay = config.InitialDelay * time.Duration(attempt+1)

	case StrategyExponential:
		// 指数退避: initialDelay * multiplier^attempt
		delay = time.Duration(float64(config.InitialDelay) * math.Pow(config.Multiplier, float64(attempt)))

	default:
		delay = config.InitialDelay
	}

	// 限制最大延迟
	if delay > config.MaxDelay {
		delay = config.MaxDelay
	}

	return delay
}

// isRetryable 判断错误是否可重试
func isRetryable(err error) bool {
	if err == nil {
		return false
	}

	// 检查是否是AppError
	if appErr, ok := err.(*errors.AppError); ok {
		return appErr.Retryable
	}

	// 检查context错误
	if err == context.Canceled || err == context.DeadlineExceeded {
		return false
	}

	// 默认不重试
	return false
}

// WithTimeout 带超时的重试
func WithTimeout(ctx context.Context, timeout time.Duration, config Config, fn Func) error {
	ctx, cancel := context.WithTimeout(ctx, timeout)
	defer cancel()

	return Do(ctx, config, fn)
}

// WithTimeoutAndResult 带超时的重试（返回结果）
func WithTimeoutAndResult[T any](ctx context.Context, timeout time.Duration, config Config, fn func(ctx context.Context) (T, error)) (T, error) {
	ctx, cancel := context.WithTimeout(ctx, timeout)
	defer cancel()

	return DoWithResult(ctx, config, fn)
}
