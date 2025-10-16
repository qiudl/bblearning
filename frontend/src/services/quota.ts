import api from './api';

// 配额信息
export interface QuotaInfo {
  user_id: number;
  daily_quota: number;
  daily_used: number;
  daily_remaining: number;
  monthly_quota: number;
  monthly_used: number;
  monthly_remaining: number;
  permanent_quota: number;
  total_available: number;
  last_reset_at: string;
  next_reset_at: string;
}

// 配额使用记录
export interface QuotaUsageRecord {
  id: number;
  user_id: number;
  amount: number;
  reason: string;
  created_at: string;
}

// 配额服务
class QuotaService {
  /**
   * 获取当前用户配额信息
   */
  async getMyQuota(): Promise<QuotaInfo> {
    const response = await api.get('/api/v1/quota/my');
    return response.data;
  }

  /**
   * 获取配额使用历史
   */
  async getUsageHistory(page: number = 1, pageSize: number = 20): Promise<{
    records: QuotaUsageRecord[];
    total: number;
    page: number;
    page_size: number;
  }> {
    const response = await api.get('/api/v1/quota/usage', {
      params: { page, page_size: pageSize },
    });
    return response.data;
  }

  /**
   * 格式化下次重置时间
   */
  getNextResetTime(quota: QuotaInfo): string {
    const resetDate = new Date(quota.next_reset_at);
    const now = new Date();
    const diff = resetDate.getTime() - now.getTime();

    if (diff < 0) {
      return '即将重置';
    }

    const hours = Math.floor(diff / (1000 * 60 * 60));
    const minutes = Math.floor((diff % (1000 * 60 * 60)) / (1000 * 60));

    if (hours > 24) {
      const days = Math.floor(hours / 24);
      return `${days}天后重置`;
    }

    if (hours > 0) {
      return `${hours}小时${minutes}分钟后重置`;
    }

    return `${minutes}分钟后重置`;
  }

  /**
   * 格式化配额显示
   */
  formatQuota(quota: QuotaInfo): string {
    return `日配额: ${quota.daily_remaining}/${quota.daily_quota} | 月配额: ${quota.monthly_remaining}/${quota.monthly_quota}${
      quota.permanent_quota > 0 ? ` | 永久: ${quota.permanent_quota}` : ''
    }`;
  }

  /**
   * 获取配额状态
   */
  getQuotaStatus(quota: QuotaInfo): 'sufficient' | 'low' | 'depleted' {
    if (quota.total_available === 0) {
      return 'depleted';
    }
    if (quota.total_available <= 10) {
      return 'low';
    }
    return 'sufficient';
  }
}

export default new QuotaService();
