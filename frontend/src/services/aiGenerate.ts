import api from './api';

// AI生成题目请求
export interface AIGenerateQuestionRequest {
  knowledge_point_id: number;
  difficulty: 'basic' | 'medium' | 'advanced';
  type: 'choice' | 'fill' | 'answer';
  count: number;
}

// 题目信息
export interface QuestionInfo {
  id?: number;
  knowledge_point_id: number;
  type: string;
  content: string;
  options?: string[];
  answer: string;
  explanation: string;
  difficulty?: string;
}

// AI生成题目响应
export interface AIGenerateQuestionResponse {
  questions: QuestionInfo[];
  count: number;
}

// AI生成题目服务
class AIGenerateService {
  /**
   * 生成题目
   */
  async generateQuestions(data: AIGenerateQuestionRequest): Promise<AIGenerateQuestionResponse> {
    const response = await api.post('/api/v1/ai/generate', data);
    return response.data;
  }

  /**
   * 保存题目到题库
   */
  async saveQuestion(question: QuestionInfo): Promise<{ id: number }> {
    const response = await api.post('/api/v1/questions', question);
    return response.data;
  }

  /**
   * 批量保存题目
   */
  async batchSaveQuestions(questions: QuestionInfo[]): Promise<{ saved: number; failed: number }> {
    const response = await api.post('/api/v1/questions/batch', { questions });
    return response.data;
  }

  /**
   * 格式化难度标签
   */
  formatDifficulty(difficulty: string): string {
    const map: { [key: string]: string } = {
      'basic': '基础',
      'medium': '中等',
      'advanced': '困难'
    };
    return map[difficulty] || difficulty;
  }

  /**
   * 格式化题型标签
   */
  formatType(type: string): string {
    const map: { [key: string]: string } = {
      'choice': '选择题',
      'fill': '填空题',
      'answer': '解答题'
    };
    return map[type] || type;
  }

  /**
   * 获取难度颜色
   */
  getDifficultyColor(difficulty: string): string {
    const colorMap: { [key: string]: string } = {
      'basic': 'success',
      'medium': 'warning',
      'advanced': 'error'
    };
    return colorMap[difficulty] || 'default';
  }

  /**
   * 获取题型图标
   */
  getTypeIcon(type: string): string {
    const iconMap: { [key: string]: string } = {
      'choice': '📝',
      'fill': '✏️',
      'answer': '📋'
    };
    return iconMap[type] || '❓';
  }
}

export default new AIGenerateService();
