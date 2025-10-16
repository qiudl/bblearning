/**
 * 前端性能优化工具
 */

// 防抖函数
export function debounce<T extends (...args: any[]) => any>(
  func: T,
  wait: number
): (...args: Parameters<T>) => void {
  let timeout: NodeJS.Timeout | null = null;

  return function executedFunction(...args: Parameters<T>) {
    const later = () => {
      timeout = null;
      func(...args);
    };

    if (timeout) {
      clearTimeout(timeout);
    }
    timeout = setTimeout(later, wait);
  };
}

// 节流函数
export function throttle<T extends (...args: any[]) => any>(
  func: T,
  limit: number
): (...args: Parameters<T>) => void {
  let inThrottle: boolean;

  return function executedFunction(...args: Parameters<T>) {
    if (!inThrottle) {
      func(...args);
      inThrottle = true;
      setTimeout(() => (inThrottle = false), limit);
    }
  };
}

// 本地存储缓存
class LocalCache {
  private prefix: string = 'bblearning_';

  /**
   * 设置缓存
   */
  set(key: string, value: any, ttl?: number): void {
    const item = {
      value,
      expiry: ttl ? Date.now() + ttl * 1000 : null,
    };
    localStorage.setItem(this.prefix + key, JSON.stringify(item));
  }

  /**
   * 获取缓存
   */
  get<T = any>(key: string): T | null {
    const itemStr = localStorage.getItem(this.prefix + key);
    if (!itemStr) {
      return null;
    }

    try {
      const item = JSON.parse(itemStr);

      // 检查是否过期
      if (item.expiry && Date.now() > item.expiry) {
        this.remove(key);
        return null;
      }

      return item.value as T;
    } catch (error) {
      console.error('Failed to parse cache:', error);
      return null;
    }
  }

  /**
   * 删除缓存
   */
  remove(key: string): void {
    localStorage.removeItem(this.prefix + key);
  }

  /**
   * 清除所有缓存
   */
  clear(): void {
    const keys = Object.keys(localStorage);
    keys.forEach((key) => {
      if (key.startsWith(this.prefix)) {
        localStorage.removeItem(key);
      }
    });
  }
}

export const localCache = new LocalCache();

// 内存缓存
class MemoryCache {
  private cache: Map<string, { value: any; expiry: number | null }> = new Map();

  set(key: string, value: any, ttl?: number): void {
    this.cache.set(key, {
      value,
      expiry: ttl ? Date.now() + ttl * 1000 : null,
    });
  }

  get<T = any>(key: string): T | null {
    const item = this.cache.get(key);
    if (!item) {
      return null;
    }

    if (item.expiry && Date.now() > item.expiry) {
      this.cache.delete(key);
      return null;
    }

    return item.value as T;
  }

  remove(key: string): void {
    this.cache.delete(key);
  }

  clear(): void {
    this.cache.clear();
  }

  size(): number {
    return this.cache.size;
  }
}

export const memoryCache = new MemoryCache();

// API请求缓存装饰器
export function cacheRequest(ttl: number = 60) {
  return function (
    target: any,
    propertyKey: string,
    descriptor: PropertyDescriptor
  ) {
    const originalMethod = descriptor.value;

    descriptor.value = async function (...args: any[]) {
      const cacheKey = `api_${propertyKey}_${JSON.stringify(args)}`;

      // 尝试从缓存获取
      const cachedResult = memoryCache.get(cacheKey);
      if (cachedResult !== null) {
        return cachedResult;
      }

      // 执行原方法
      const result = await originalMethod.apply(this, args);

      // 缓存结果
      memoryCache.set(cacheKey, result, ttl);

      return result;
    };

    return descriptor;
  };
}

// 图片懒加载
export function lazyLoadImage(
  element: HTMLImageElement,
  src: string,
  placeholder?: string
): void {
  if ('IntersectionObserver' in window) {
    const observer = new IntersectionObserver((entries) => {
      entries.forEach((entry) => {
        if (entry.isIntersecting) {
          const img = entry.target as HTMLImageElement;
          img.src = src;
          observer.unobserve(img);
        }
      });
    });

    if (placeholder) {
      element.src = placeholder;
    }
    observer.observe(element);
  } else {
    // Fallback for browsers that don't support IntersectionObserver
    element.src = src;
  }
}

// 性能监控
export class PerformanceMonitor {
  private static marks: Map<string, number> = new Map();

  /**
   * 开始计时
   */
  static start(label: string): void {
    this.marks.set(label, performance.now());
  }

  /**
   * 结束计时并打印结果
   */
  static end(label: string): number | null {
    const startTime = this.marks.get(label);
    if (!startTime) {
      console.warn(`No start mark found for: ${label}`);
      return null;
    }

    const duration = performance.now() - startTime;
    console.log(`[Performance] ${label}: ${duration.toFixed(2)}ms`);
    this.marks.delete(label);
    return duration;
  }

  /**
   * 测量函数执行时间
   */
  static async measure<T>(label: string, fn: () => Promise<T>): Promise<T> {
    this.start(label);
    try {
      const result = await fn();
      this.end(label);
      return result;
    } catch (error) {
      this.end(label);
      throw error;
    }
  }
}

// 批量请求优化
export class RequestBatcher {
  private queue: Array<{
    resolve: (value: any) => void;
    reject: (reason: any) => void;
    params: any;
  }> = [];
  private timer: NodeJS.Timeout | null = null;
  private batchFn: (params: any[]) => Promise<any[]>;
  private wait: number;

  constructor(batchFn: (params: any[]) => Promise<any[]>, wait: number = 50) {
    this.batchFn = batchFn;
    this.wait = wait;
  }

  request(params: any): Promise<any> {
    return new Promise((resolve, reject) => {
      this.queue.push({ resolve, reject, params });

      if (!this.timer) {
        this.timer = setTimeout(() => this.flush(), this.wait);
      }
    });
  }

  private async flush(): void {
    const batch = this.queue.splice(0);
    this.timer = null;

    if (batch.length === 0) return;

    try {
      const params = batch.map((item) => item.params);
      const results = await this.batchFn(params);

      batch.forEach((item, index) => {
        item.resolve(results[index]);
      });
    } catch (error) {
      batch.forEach((item) => {
        item.reject(error);
      });
    }
  }
}

// 前端资源预加载
export function preloadResource(url: string, as: string = 'fetch'): void {
  const link = document.createElement('link');
  link.rel = 'preload';
  link.href = url;
  link.as = as;
  document.head.appendChild(link);
}

// 清理过期缓存
export function cleanupExpiredCache(): void {
  // 清理localStorage中过期的缓存
  const keys = Object.keys(localStorage);
  keys.forEach((key) => {
    if (key.startsWith('bblearning_')) {
      try {
        const item = JSON.parse(localStorage.getItem(key) || '');
        if (item.expiry && Date.now() > item.expiry) {
          localStorage.removeItem(key);
        }
      } catch (error) {
        // 无效的缓存项，删除
        localStorage.removeItem(key);
      }
    }
  });
}

// 初始化性能优化
export function initPerformanceOptimization(): void {
  // 定期清理过期缓存（每小时）
  setInterval(cleanupExpiredCache, 60 * 60 * 1000);

  // 页面可见性变化时清理缓存
  document.addEventListener('visibilitychange', () => {
    if (document.hidden) {
      cleanupExpiredCache();
    }
  });
}
