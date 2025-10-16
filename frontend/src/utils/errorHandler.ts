import { message } from 'antd';

// 错误码定义（与后端保持一致）
export enum ErrorCode {
  // 成功
  SUCCESS = 0,

  // 客户端错误 1xxx
  INVALID_REQUEST = 1000,
  UNAUTHORIZED = 1001,
  TOKEN_EXPIRED = 1002,
  INSUFFICIENT_QUOTA = 1003,
  FORBIDDEN = 1004,
  RATE_LIMIT_EXCEEDED = 1005,

  // 资源错误 2xxx
  NOT_FOUND = 2000,
  ALREADY_EXISTS = 2001,
  CONFLICT = 2002,
  RESOURCE_DELETED = 2003,

  // 服务器错误 3xxx
  INTERNAL_ERROR = 3000,
  DATABASE_ERROR = 3001,
  CACHE_ERROR = 3002,
  STORAGE_ERROR = 3003,
  SERVICE_TIMEOUT = 3004,

  // 外部服务错误 4xxx
  EXTERNAL_SERVICE_ERROR = 4000,
  AI_SERVICE_ERROR = 4001,
  AI_SERVICE_TIMEOUT = 4002,
  AI_RATE_LIMIT_EXCEEDED = 4003,
  OCR_SERVICE_ERROR = 4004,
  OCR_SERVICE_TIMEOUT = 4005,
}

// 错误类型
export enum ErrorType {
  VALIDATION = 'validation',
  AUTH = 'auth',
  BUSINESS = 'business',
  SYSTEM = 'system',
  EXTERNAL = 'external',
  RATE_LIMIT = 'rate_limit',
}

// API错误响应接口
export interface ErrorResponse {
  code: ErrorCode;
  message: string;
  type?: ErrorType;
  retryable?: boolean;
  data?: Record<string, any>;
}

// 错误处理选项
export interface ErrorHandlerOptions {
  showMessage?: boolean;        // 是否显示错误提示
  duration?: number;             // 提示显示时长
  onRetry?: () => void;         // 重试回调
  onQuotaInsufficient?: () => void; // 配额不足回调
  onUnauthorized?: () => void;  // 未授权回调
}

/**
 * 错误处理器类
 */
export class ErrorHandler {
  /**
   * 处理API错误
   */
  static handle(error: any, options: ErrorHandlerOptions = {}): ErrorResponse | null {
    const {
      showMessage: shouldShowMessage = true,
      duration = 3,
      onRetry,
      onQuotaInsufficient,
      onUnauthorized,
    } = options;

    // 解析错误响应
    const errorResponse = this.parseError(error);

    if (!errorResponse) {
      if (shouldShowMessage) {
        message.error('网络请求失败，请检查网络连接');
      }
      return null;
    }

    // 显示用户友好的错误提示
    if (shouldShowMessage) {
      this.showErrorMessage(errorResponse, duration);
    }

    // 处理特定错误
    this.handleSpecificErrors(errorResponse, {
      onRetry,
      onQuotaInsufficient,
      onUnauthorized,
    });

    return errorResponse;
  }

  /**
   * 解析错误对象
   */
  private static parseError(error: any): ErrorResponse | null {
    // Axios错误
    if (error?.response?.data) {
      return error.response.data as ErrorResponse;
    }

    // 网络错误
    if (error?.message === 'Network Error') {
      return {
        code: ErrorCode.INTERNAL_ERROR,
        message: '网络连接失败，请检查网络设置',
        type: ErrorType.SYSTEM,
      };
    }

    // 超时错误
    if (error?.code === 'ECONNABORTED') {
      return {
        code: ErrorCode.SERVICE_TIMEOUT,
        message: '请求超时，请稍后重试',
        type: ErrorType.SYSTEM,
        retryable: true,
      };
    }

    return null;
  }

  /**
   * 显示错误提示
   */
  private static showErrorMessage(errorResponse: ErrorResponse, duration: number) {
    const { code, message: msg, retryable } = errorResponse;

    // 根据错误类型选择不同的提示方式
    switch (code) {
      case ErrorCode.INSUFFICIENT_QUOTA:
        message.warning({
          content: msg,
          duration,
          key: 'quota-error',
        });
        break;

      case ErrorCode.AI_RATE_LIMIT_EXCEEDED:
      case ErrorCode.RATE_LIMIT_EXCEEDED:
        message.warning({
          content: `${msg}${retryable ? '，系统将自动重试' : ''}`,
          duration,
        });
        break;

      case ErrorCode.AI_SERVICE_TIMEOUT:
      case ErrorCode.SERVICE_TIMEOUT:
        message.error({
          content: `${msg}${retryable ? '，可以尝试重新提交' : ''}`,
          duration,
        });
        break;

      case ErrorCode.UNAUTHORIZED:
      case ErrorCode.TOKEN_EXPIRED:
        message.error({
          content: msg || '登录已过期，请重新登录',
          duration,
          key: 'auth-error',
        });
        break;

      case ErrorCode.AI_SERVICE_ERROR:
      case ErrorCode.EXTERNAL_SERVICE_ERROR:
        message.error({
          content: msg,
          duration,
        });
        break;

      default:
        message.error({
          content: msg || '操作失败，请稍后重试',
          duration,
        });
    }
  }

  /**
   * 处理特定错误的额外逻辑
   */
  private static handleSpecificErrors(
    errorResponse: ErrorResponse,
    callbacks: Pick<ErrorHandlerOptions, 'onRetry' | 'onQuotaInsufficient' | 'onUnauthorized'>
  ) {
    const { code } = errorResponse;

    // 配额不足
    if (code === ErrorCode.INSUFFICIENT_QUOTA && callbacks.onQuotaInsufficient) {
      callbacks.onQuotaInsufficient();
    }

    // 未授权
    if ((code === ErrorCode.UNAUTHORIZED || code === ErrorCode.TOKEN_EXPIRED) && callbacks.onUnauthorized) {
      // 延迟执行，确保错误提示先显示
      setTimeout(() => {
        callbacks.onUnauthorized!();
      }, 1000);
    }

    // 可重试错误
    if (errorResponse.retryable && callbacks.onRetry) {
      const retryAfter = errorResponse.data?.retry_after || 3;
      setTimeout(() => {
        callbacks.onRetry!();
      }, retryAfter * 1000);
    }
  }

  /**
   * 获取用户友好的错误消息
   */
  static getUserFriendlyMessage(code: ErrorCode, defaultMessage?: string): string {
    const messages: Record<ErrorCode, string> = {
      [ErrorCode.SUCCESS]: '操作成功',
      [ErrorCode.INVALID_REQUEST]: '请求参数错误，请检查输入',
      [ErrorCode.UNAUTHORIZED]: '您还未登录，请先登录',
      [ErrorCode.TOKEN_EXPIRED]: '登录已过期，请重新登录',
      [ErrorCode.INSUFFICIENT_QUOTA]: '您的配额不足，请充值或等待重置',
      [ErrorCode.FORBIDDEN]: '您没有权限执行此操作',
      [ErrorCode.RATE_LIMIT_EXCEEDED]: '操作过于频繁，请稍后再试',
      [ErrorCode.NOT_FOUND]: '请求的资源不存在',
      [ErrorCode.ALREADY_EXISTS]: '资源已存在',
      [ErrorCode.CONFLICT]: '操作冲突，请刷新后重试',
      [ErrorCode.RESOURCE_DELETED]: '资源已被删除',
      [ErrorCode.INTERNAL_ERROR]: '服务器内部错误，请稍后重试',
      [ErrorCode.DATABASE_ERROR]: '数据库操作失败，请稍后重试',
      [ErrorCode.CACHE_ERROR]: '缓存服务异常，请稍后重试',
      [ErrorCode.STORAGE_ERROR]: '存储服务异常，请稍后重试',
      [ErrorCode.SERVICE_TIMEOUT]: '请求超时，请稍后重试',
      [ErrorCode.EXTERNAL_SERVICE_ERROR]: '外部服务异常，请稍后重试',
      [ErrorCode.AI_SERVICE_ERROR]: 'AI服务暂时不可用，请稍后再试',
      [ErrorCode.AI_SERVICE_TIMEOUT]: 'AI服务响应超时，请稍后重试',
      [ErrorCode.AI_RATE_LIMIT_EXCEEDED]: 'AI请求过于频繁，请稍后再试',
      [ErrorCode.OCR_SERVICE_ERROR]: '图片识别服务暂时不可用，请稍后再试',
      [ErrorCode.OCR_SERVICE_TIMEOUT]: '图片识别超时，请稍后重试',
    };

    return messages[code] || defaultMessage || '操作失败';
  }

  /**
   * 判断错误是否可重试
   */
  static isRetryable(errorResponse: ErrorResponse): boolean {
    return errorResponse.retryable === true;
  }

  /**
   * 获取重试延迟时间（秒）
   */
  static getRetryDelay(errorResponse: ErrorResponse): number {
    return errorResponse.data?.retry_after || 3;
  }
}

/**
 * 简化的错误处理函数
 */
export function handleApiError(error: any, options?: ErrorHandlerOptions): ErrorResponse | null {
  return ErrorHandler.handle(error, options);
}

/**
 * 用于async/await的错误处理包装器
 */
export async function withErrorHandling<T>(
  promise: Promise<T>,
  options?: ErrorHandlerOptions
): Promise<[T | null, ErrorResponse | null]> {
  try {
    const data = await promise;
    return [data, null];
  } catch (error) {
    const errorResponse = ErrorHandler.handle(error, options);
    return [null, errorResponse];
  }
}
