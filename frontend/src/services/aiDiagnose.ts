import api from './api';

// 薄弱点分析
export interface WeakPointAnalysis {
  knowledge_point_id: number;
  knowledge_point: string;
  mastery_level: number;      // 掌握度 0-1
  error_rate: number;          // 错误率 0-1
  common_mistakes: string[];   // 常见错误
}

// AI诊断请求
export interface AIDiagnoseRequest {
  knowledge_point_id?: number; // 可选，诊断特定知识点
}

// AI诊断响应
export interface AIDiagnoseResponse {
  overall_level: string;           // 整体水平: beginner/intermediate/advanced
  weak_points: WeakPointAnalysis[]; // 薄弱知识点
  recommendations: string[];        // 学习建议
  next_steps: string[];             // 下一步行动
}

// AI诊断服务
class AIDiagnoseService {
  /**
   * 获取学习诊断报告
   */
  async diagnose(data?: AIDiagnoseRequest): Promise<AIDiagnoseResponse> {
    const response = await api.post('/api/v1/ai/diagnose', data || {});
    return response.data;
  }

  /**
   * 格式化整体水平
   */
  formatOverallLevel(level: string): { text: string; color: string } {
    const levelMap: { [key: string]: { text: string; color: string } } = {
      beginner: { text: '初学者', color: 'default' },
      intermediate: { text: '中级水平', color: 'processing' },
      advanced: { text: '高级水平', color: 'success' },
    };
    return levelMap[level] || { text: level, color: 'default' };
  }

  /**
   * 获取掌握度颜色
   */
  getMasteryColor(masteryLevel: number): string {
    if (masteryLevel >= 0.8) return '#52c41a'; // 绿色
    if (masteryLevel >= 0.6) return '#faad14'; // 橙色
    return '#ff4d4f'; // 红色
  }

  /**
   * 获取掌握度等级
   */
  getMasteryGrade(masteryLevel: number): string {
    if (masteryLevel >= 0.8) return '掌握良好';
    if (masteryLevel >= 0.6) return '基本掌握';
    if (masteryLevel >= 0.4) return '部分掌握';
    return '需要加强';
  }

  /**
   * 格式化百分比
   */
  formatPercentage(value: number): string {
    return `${(value * 100).toFixed(1)}%`;
  }

  /**
   * 获取错误率标签颜色
   */
  getErrorRateColor(errorRate: number): string {
    if (errorRate >= 0.5) return 'error';
    if (errorRate >= 0.3) return 'warning';
    return 'success';
  }

  /**
   * 排序薄弱点（按错误率降序）
   */
  sortWeakPoints(weakPoints: WeakPointAnalysis[]): WeakPointAnalysis[] {
    return [...weakPoints].sort((a, b) => b.error_rate - a.error_rate);
  }
}

export default new AIDiagnoseService();
