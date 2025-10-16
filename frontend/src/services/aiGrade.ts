import api from './api';

// AI批改答案请求
export interface AIGradeAnswerRequest {
  question_id: number;
  question_content: string;
  standard_answer: string;
  user_answer: string;
}

// AI批改答案响应
export interface AIGradeAnswerResponse {
  is_correct: boolean;
  score: number;          // 0-100分
  feedback: string;       // AI批改意见
  suggestion: string;     // 改进建议
  key_points: string[];   // 答题要点
}

// AI批改服务
class AIGradeService {
  /**
   * AI批改答案
   */
  async gradeAnswer(data: AIGradeAnswerRequest): Promise<AIGradeAnswerResponse> {
    const response = await api.post('/api/v1/ai/grade', data);
    return response.data;
  }

  /**
   * 获取分数颜色
   */
  getScoreColor(score: number): string {
    if (score >= 90) return 'success';
    if (score >= 70) return 'warning';
    return 'error';
  }

  /**
   * 获取分数等级
   */
  getScoreGrade(score: number): string {
    if (score >= 90) return '优秀';
    if (score >= 80) return '良好';
    if (score >= 70) return '中等';
    if (score >= 60) return '及格';
    return '不及格';
  }

  /**
   * 格式化分数显示
   */
  formatScore(score: number): string {
    return `${score.toFixed(1)}分`;
  }

  /**
   * 获取正确性标签
   */
  getCorrectnessTag(isCorrect: boolean): { text: string; color: string } {
    return isCorrect
      ? { text: '✓ 正确', color: 'success' }
      : { text: '✗ 错误', color: 'error' };
  }
}

export default new AIGradeService();
