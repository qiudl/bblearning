import api from './api';

// 配额信息接口
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
  is_vip: boolean;
  vip_expire_at?: string;
  daily_reset_at: string;
  monthly_reset_at: string;
  total_consumed: number;
  last_consume_at?: string;
  last_reset_at: string;
  next_reset_at: string;
}

// 配额日志接口
export interface QuotaLog {
  id: number;
  user_id: number;
  quota_type: 'daily' | 'monthly' | 'permanent';
  amount: number;
  service_type: 'chat' | 'generate' | 'grade' | 'diagnose' | 'ocr';
  description?: string;
  created_at: string;
}

// 配额使用记录（别名，兼容性）
export interface QuotaUsageRecord extends QuotaLog {}

// 充值记录接口
export interface RechargeLog {
  id: number;
  user_id: number;
  quota_type: 'daily' | 'monthly' | 'permanent';
  amount: number;
  reason?: string;
  operator_id?: number;
  recharge_method: 'manual' | 'purchase' | 'reward' | 'vip';
  order_id?: string;
  created_at: string;
}

// 配额服务类
class QuotaService {
  /**
   * 获取我的配额信息
   */
  async getMyQuota(): Promise<QuotaInfo> {
    const response = await api.get('/api/v1/quota/my');
    return response.data;
  }

  /**
   * 获取配额使用日志
   */
  async getQuotaLogs(page: number = 1, pageSize: number = 20): Promise<{
    list: QuotaLog[];
    total: number;
    page: number;
    size: number;
  }> {
    const response = await api.get('/api/v1/quota/logs', {
      params: { page, page_size: pageSize }
    });
    return response.data;
  }

  /**
   * 获取配额使用历史（别名，兼容性）
   */
  async getUsageHistory(page: number = 1, pageSize: number = 20): Promise<{
    records: QuotaUsageRecord[];
    total: number;
    page: number;
    page_size: number;
  }> {
    const result = await this.getQuotaLogs(page, pageSize);
    return {
      records: result.list,
      total: result.total,
      page: result.page,
      page_size: result.size,
    };
  }

  /**
   * 获取充值记录
   */
  async getRechargeLogs(page: number = 1, pageSize: number = 20): Promise<{
    list: RechargeLog[];
    total: number;
    page: number;
    size: number;
  }> {
    const response = await api.get('/api/v1/quota/recharge-logs', {
      params: { page, page_size: pageSize }
    });
    return response.data;
  }

  /**
   * 检查配额是否足够
   */
  async checkQuota(amount: number): Promise<{
    sufficient: boolean;
    amount: number;
  }> {
    const response = await api.get('/api/v1/quota/check', {
      params: { amount }
    });
    return response.data;
  }

  /**
   * 充值配额（管理员）
   */
  async rechargeQuota(data: {
    user_id: number;
    quota_type: 'daily' | 'monthly' | 'permanent';
    amount: number;
    reason?: string;
    method?: 'manual' | 'purchase' | 'reward' | 'vip';
  }): Promise<void> {
    await api.post('/api/v1/quota/recharge', data);
  }

  /**
   * 设置VIP（管理员）
   */
  async setVIP(data: {
    user_id: number;
    days: number;
    extra_quota: number;
  }): Promise<void> {
    await api.post('/api/v1/quota/vip', data);
  }

  /**
   * 取消VIP（管理员）
   */
  async cancelVIP(userId: number): Promise<void> {
    await api.delete(`/api/v1/quota/vip/${userId}`);
  }

  /**
   * 格式化配额类型
   */
  formatQuotaType(type: string): string {
    const map: { [key: string]: string } = {
      'daily': '日配额',
      'monthly': '月配额',
      'permanent': '永久配额'
    };
    return map[type] || type;
  }

  /**
   * 格式化服务类型
   */
  formatServiceType(type: string): string {
    const map: { [key: string]: string } = {
      'chat': 'AI对话',
      'generate': '生成题目',
      'grade': '批改答案',
      'diagnose': '学习诊断',
      'ocr': 'OCR识别'
    };
    return map[type] || type;
  }

  /**
   * 格式化充值方式
   */
  formatRechargeMethod(method: string): string {
    const map: { [key: string]: string } = {
      'manual': '手动充值',
      'purchase': '购买充值',
      'reward': '奖励',
      'vip': 'VIP赠送'
    };
    return map[method] || method;
  }

  /**
   * 获取配额不足提示
   */
  getInsufficientQuotaMessage(quotaInfo: QuotaInfo): string {
    if (quotaInfo.permanent_quota > 0) {
      return `永久配额剩余: ${quotaInfo.permanent_quota}`;
    }

    if (quotaInfo.daily_remaining > 0) {
      return `今日剩余配额: ${quotaInfo.daily_remaining}/${quotaInfo.daily_quota}`;
    }

    if (quotaInfo.monthly_remaining > 0) {
      return `本月剩余配额: ${quotaInfo.monthly_remaining}/${quotaInfo.monthly_quota}`;
    }

    return '配额已用尽，请充值或等待重置';
  }

  /**
   * 计算下次重置时间
   */
  getNextResetTime(quotaInfo: QuotaInfo): string {
    const now = new Date();
    const nextReset = new Date(quotaInfo.next_reset_at || quotaInfo.daily_reset_at);
    const diff = nextReset.getTime() - now.getTime();

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
