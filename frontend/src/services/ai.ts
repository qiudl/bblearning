import { request } from './api';
import { API_ENDPOINTS, API_CONFIG } from '../config/api';

// AI 请求/响应类型定义
export interface AIChatRequest {
  message: string;
  question_id?: number;
}

export interface AIChatResponse {
  code: number;
  message: string;
  data: {
    reply: string;
    conversation_id: number;
  };
}

export interface AIRecognizeQuestionRequest {
  image: string; // Base64编码的图片
}

export interface AIRecognizeQuestionResponse {
  code: number;
  message: string;
  data: {
    image_url: string;
    recognized_text: string;
    question?: any;
    ai_solution?: string;
    confidence: number;
  };
}

export interface AIGenerateQuestionRequest {
  knowledge_point_id: number;
  difficulty: 'basic' | 'medium' | 'advanced';
  type: 'choice' | 'fill' | 'answer';
  count: number;
}

export interface AIGradeAnswerRequest {
  question_id: number;
  question_content: string;
  standard_answer: string;
  user_answer: string;
}

export interface AIGradeAnswerResponse {
  code: number;
  message: string;
  data: {
    is_correct: boolean;
    score: number;
    feedback: string;
    suggestion: string;
    key_points: string[];
  };
}

export interface AIDiagnoseRequest {
  knowledge_point_id?: number;
}

export interface AIDiagnoseResponse {
  code: number;
  message: string;
  data: {
    overall_level: string;
    weak_points: Array<{
      knowledge_point_id: number;
      knowledge_point: string;
      mastery_level: number;
      error_rate: number;
      common_mistakes: string[];
      practice_suggestion: string;
    }>;
    recommendations: string[];
    next_steps: string[];
  };
}

export interface AIExplainRequest {
  question_id: number;
  user_answer?: string;
}

export interface AIExplainResponse {
  code: number;
  message: string;
  data: {
    explanation: string;
    steps: string[];
    key_concepts: string[];
    similar_questions?: number[];
  };
}

// AI 服务 API
class AIService {
  /**
   * AI 对话聊天
   * @param message 用户消息
   * @param questionId 可选的题目ID
   */
  async chat(message: string, questionId?: number): Promise<AIChatResponse> {
    return request.post<AIChatResponse>(API_ENDPOINTS.AI_CHAT, {
      message,
      question_id: questionId,
    });
  }

  /**
   * AI 对话聊天（流式输出）
   * @param message 用户消息
   * @param questionId 可选的题目ID
   * @param onChunk 接收到内容块时的回调
   * @param onDone 流式输出完成时的回调
   * @param onError 发生错误时的回调
   * @returns abort函数，用于取消请求
   */
  chatStream(
    message: string,
    questionId: number | undefined,
    onChunk: (content: string) => void,
    onDone: (conversationId: number) => void,
    onError: (error: string) => void
  ): () => void {
    const token = localStorage.getItem('access_token');
    if (!token) {
      onError('未登录，请先登录');
      return () => {};
    }

    // 使用 fetch 发起 POST 请求并接收 SSE 流
    const controller = new AbortController();

    fetch(`${API_CONFIG.BASE_URL}${API_ENDPOINTS.AI_CHAT_STREAM}`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${token}`,
      },
      body: JSON.stringify({
        message,
        question_id: questionId,
      }),
      signal: controller.signal,
    })
      .then(async (response) => {
        if (!response.ok) {
          throw new Error(`HTTP ${response.status}: ${response.statusText}`);
        }

        const reader = response.body?.getReader();
        if (!reader) {
          throw new Error('无法读取响应流');
        }

        const decoder = new TextDecoder();
        let buffer = '';

        while (true) {
          const { done, value } = await reader.read();

          if (done) {
            break;
          }

          // 解码数据块
          buffer += decoder.decode(value, { stream: true });

          // 处理 SSE 事件（可能包含多个事件）
          const lines = buffer.split('\n');
          buffer = lines.pop() || ''; // 保留最后一个未完成的行

          let currentEvent = '';
          let currentData = '';

          for (const line of lines) {
            if (line.startsWith('event:')) {
              currentEvent = line.substring(6).trim();
            } else if (line.startsWith('data:')) {
              currentData = line.substring(5).trim();
            } else if (line === '') {
              // 空行表示一个事件结束
              if (currentEvent && currentData) {
                try {
                  const data = JSON.parse(currentData);

                  if (currentEvent === 'message') {
                    onChunk(data.content);
                  } else if (currentEvent === 'done') {
                    onDone(data.conversation_id);
                  } else if (currentEvent === 'error') {
                    onError(data.error);
                  }
                } catch (e) {
                  console.error('解析 SSE 数据失败:', e);
                }

                currentEvent = '';
                currentData = '';
              }
            }
          }
        }
      })
      .catch((error) => {
        if (error.name === 'AbortError') {
          console.log('流式请求已取消');
        } else {
          onError(error.message || '流式请求失败');
        }
      });

    // 返回取消函数
    return () => {
      controller.abort();
    };
  }

  /**
   * 拍照识题（OCR识别）
   * @param imageBase64 Base64编码的图片
   */
  async recognizeQuestion(imageBase64: string): Promise<AIRecognizeQuestionResponse> {
    return request.post<AIRecognizeQuestionResponse>(API_ENDPOINTS.AI_OCR, {
      image: imageBase64,
    });
  }

  /**
   * AI生成题目
   * @param params 生成参数
   */
  async generateQuestion(params: AIGenerateQuestionRequest): Promise<any> {
    return request.post('/ai/generate-question', params);
  }

  /**
   * AI批改答案
   * @param params 批改参数
   */
  async gradeAnswer(params: AIGradeAnswerRequest): Promise<AIGradeAnswerResponse> {
    return request.post('/ai/grade', params);
  }

  /**
   * AI学习诊断
   * @param knowledgePointId 可选的知识点ID
   */
  async diagnose(knowledgePointId?: number): Promise<AIDiagnoseResponse> {
    return request.post('/ai/diagnose', {
      knowledge_point_id: knowledgePointId,
    });
  }

  /**
   * AI解题讲解
   * @param params 讲解参数
   */
  async explain(params: AIExplainRequest): Promise<AIExplainResponse> {
    return request.post('/ai/explain', params);
  }
}

// 导出单例
export const aiService = new AIService();
export default aiService;
