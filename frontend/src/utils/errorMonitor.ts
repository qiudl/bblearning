/**
 * 前端错误监控工具
 */

export interface ErrorInfo {
  type: 'js' | 'promise' | 'resource' | 'api' | 'custom';
  message: string;
  stack?: string;
  filename?: string;
  lineno?: number;
  colno?: number;
  url?: string;
  timestamp: number;
  userAgent: string;
  href: string;
}

export interface APIErrorInfo extends ErrorInfo {
  type: 'api';
  method: string;
  url: string;
  status: number;
  statusText: string;
  response?: any;
}

class ErrorMonitor {
  private errors: ErrorInfo[] = [];
  private maxErrors: number = 100;
  private reportUrl: string = '/api/v1/errors/report';
  private autoReport: boolean = true;

  constructor() {
    this.init();
  }

  /**
   * 初始化错误监控
   */
  private init(): void {
    // 监听JavaScript运行时错误
    window.addEventListener('error', (event) => {
      this.handleJSError(event);
    });

    // 监听Promise未捕获错误
    window.addEventListener('unhandledrejection', (event) => {
      this.handlePromiseError(event);
    });

    // 监听资源加载错误
    window.addEventListener(
      'error',
      (event) => {
        this.handleResourceError(event);
      },
      true
    );
  }

  /**
   * 处理JavaScript错误
   */
  private handleJSError(event: ErrorEvent): void {
    const error: ErrorInfo = {
      type: 'js',
      message: event.message,
      stack: event.error?.stack,
      filename: event.filename,
      lineno: event.lineno,
      colno: event.colno,
      timestamp: Date.now(),
      userAgent: navigator.userAgent,
      href: window.location.href,
    };

    this.recordError(error);
  }

  /**
   * 处理Promise错误
   */
  private handlePromiseError(event: PromiseRejectionEvent): void {
    const error: ErrorInfo = {
      type: 'promise',
      message: event.reason?.message || String(event.reason),
      stack: event.reason?.stack,
      timestamp: Date.now(),
      userAgent: navigator.userAgent,
      href: window.location.href,
    };

    this.recordError(error);
  }

  /**
   * 处理资源加载错误
   */
  private handleResourceError(event: Event): void {
    const target = event.target as HTMLElement;

    // 只处理资源加载错误，忽略JS错误
    if (
      target instanceof HTMLScriptElement ||
      target instanceof HTMLLinkElement ||
      target instanceof HTMLImageElement
    ) {
      const error: ErrorInfo = {
        type: 'resource',
        message: `Failed to load resource: ${target.tagName}`,
        url:
          (target as HTMLScriptElement).src ||
          (target as HTMLLinkElement).href ||
          (target as HTMLImageElement).src,
        timestamp: Date.now(),
        userAgent: navigator.userAgent,
        href: window.location.href,
      };

      this.recordError(error);
    }
  }

  /**
   * 记录API错误
   */
  recordAPIError(
    method: string,
    url: string,
    status: number,
    statusText: string,
    response?: any
  ): void {
    const error: APIErrorInfo = {
      type: 'api',
      message: `API Error: ${method} ${url} - ${status} ${statusText}`,
      method,
      url,
      status,
      statusText,
      response,
      timestamp: Date.now(),
      userAgent: navigator.userAgent,
      href: window.location.href,
    };

    this.recordError(error);
  }

  /**
   * 记录自定义错误
   */
  recordCustomError(message: string, extra?: Record<string, any>): void {
    const error: ErrorInfo = {
      type: 'custom',
      message,
      timestamp: Date.now(),
      userAgent: navigator.userAgent,
      href: window.location.href,
      ...extra,
    };

    this.recordError(error);
  }

  /**
   * 记录错误
   */
  private recordError(error: ErrorInfo): void {
    // 添加到错误列表
    this.errors.push(error);

    // 限制错误数量
    if (this.errors.length > this.maxErrors) {
      this.errors.shift();
    }

    // 打印到控制台
    console.error('[ErrorMonitor]', error);

    // 自动上报
    if (this.autoReport) {
      this.reportError(error);
    }
  }

  /**
   * 上报错误到服务器
   */
  private async reportError(error: ErrorInfo): Promise<void> {
    try {
      // 使用sendBeacon API确保在页面卸载时也能发送
      if (navigator.sendBeacon) {
        const blob = new Blob([JSON.stringify(error)], {
          type: 'application/json',
        });
        navigator.sendBeacon(this.reportUrl, blob);
      } else {
        // 降级使用fetch
        await fetch(this.reportUrl, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
          },
          body: JSON.stringify(error),
          // 不等待响应
          keepalive: true,
        }).catch(() => {
          // 忽略上报失败
        });
      }
    } catch (err) {
      // 上报失败不影响业务
      console.warn('[ErrorMonitor] Failed to report error:', err);
    }
  }

  /**
   * 批量上报错误
   */
  async reportAllErrors(): Promise<void> {
    if (this.errors.length === 0) {
      return;
    }

    try {
      await fetch(this.reportUrl + '/batch', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          errors: this.errors,
        }),
      });

      // 上报成功后清空
      this.errors = [];
    } catch (err) {
      console.warn('[ErrorMonitor] Failed to report errors:', err);
    }
  }

  /**
   * 获取所有错误
   */
  getErrors(): ErrorInfo[] {
    return [...this.errors];
  }

  /**
   * 清空错误记录
   */
  clearErrors(): void {
    this.errors = [];
  }

  /**
   * 设置自动上报
   */
  setAutoReport(enabled: boolean): void {
    this.autoReport = enabled;
  }

  /**
   * 设置上报URL
   */
  setReportUrl(url: string): void {
    this.reportUrl = url;
  }

  /**
   * 获取错误统计
   */
  getErrorStats(): {
    total: number;
    byType: Record<string, number>;
    recent: ErrorInfo[];
  } {
    const byType: Record<string, number> = {};

    this.errors.forEach((error) => {
      byType[error.type] = (byType[error.type] || 0) + 1;
    });

    return {
      total: this.errors.length,
      byType,
      recent: this.errors.slice(-10),
    };
  }
}

// 全局单例
export const errorMonitor = new ErrorMonitor();

// React错误边界组件辅助函数
export function logReactError(error: Error, errorInfo: React.ErrorInfo): void {
  errorMonitor.recordCustomError(error.message, {
    componentStack: errorInfo.componentStack,
    stack: error.stack,
  });
}

// 性能监控
export class PerformanceMonitor {
  /**
   * 监控页面加载性能
   */
  static monitorPageLoad(): void {
    if (typeof window === 'undefined' || !window.performance) {
      return;
    }

    window.addEventListener('load', () => {
      setTimeout(() => {
        const timing = window.performance.timing;
        const metrics = {
          // DNS查询耗时
          dns: timing.domainLookupEnd - timing.domainLookupStart,
          // TCP连接耗时
          tcp: timing.connectEnd - timing.connectStart,
          // 请求耗时
          request: timing.responseEnd - timing.requestStart,
          // DOM解析耗时
          domParse: timing.domInteractive - timing.responseEnd,
          // 资源加载耗时
          resourceLoad:
            timing.loadEventStart - timing.domContentLoadedEventEnd,
          // 首屏时间
          firstPaint: timing.responseEnd - timing.fetchStart,
          // 总耗时
          total: timing.loadEventEnd - timing.navigationStart,
        };

        console.log('[PerformanceMonitor] Page Load Metrics:', metrics);

        // 可以上报到服务器
        if (metrics.total > 5000) {
          errorMonitor.recordCustomError('Slow page load', {
            metrics,
            type: 'performance',
          });
        }
      }, 0);
    });
  }

  /**
   * 监控长任务
   */
  static monitorLongTasks(): void {
    if (typeof PerformanceObserver === 'undefined') {
      return;
    }

    try {
      const observer = new PerformanceObserver((list) => {
        for (const entry of list.getEntries()) {
          if (entry.duration > 50) {
            console.warn('[PerformanceMonitor] Long task detected:', entry);
            errorMonitor.recordCustomError('Long task detected', {
              duration: entry.duration,
              startTime: entry.startTime,
              type: 'performance',
            });
          }
        }
      });

      observer.observe({ entryTypes: ['longtask'] });
    } catch (err) {
      // PerformanceObserver不支持
    }
  }

  /**
   * 监控内存使用
   */
  static monitorMemory(): void {
    if (
      typeof window === 'undefined' ||
      !(performance as any).memory
    ) {
      return;
    }

    setInterval(() => {
      const memory = (performance as any).memory;
      const usedPercent =
        (memory.usedJSHeapSize / memory.jsHeapSizeLimit) * 100;

      if (usedPercent > 90) {
        console.warn('[PerformanceMonitor] High memory usage:', {
          used: memory.usedJSHeapSize,
          total: memory.jsHeapSizeLimit,
          percent: usedPercent.toFixed(2) + '%',
        });

        errorMonitor.recordCustomError('High memory usage', {
          usedJSHeapSize: memory.usedJSHeapSize,
          jsHeapSizeLimit: memory.jsHeapSizeLimit,
          percent: usedPercent,
          type: 'performance',
        });
      }
    }, 30000); // 每30秒检查一次
  }
}

// 初始化性能监控
export function initErrorAndPerformanceMonitoring(): void {
  PerformanceMonitor.monitorPageLoad();
  PerformanceMonitor.monitorLongTasks();
  PerformanceMonitor.monitorMemory();
}
