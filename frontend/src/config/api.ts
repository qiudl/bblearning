// API 配置
export const API_CONFIG = {
  BASE_URL: process.env.REACT_APP_API_URL || 'http://localhost:8080/api/v1',
  TIMEOUT: 30000,
};

// API 端点
export const API_ENDPOINTS = {
  // 用户相关
  LOGIN: '/auth/login',
  REGISTER: '/auth/register',
  LOGOUT: '/auth/logout',
  USER_INFO: '/users/me',

  // 知识点相关
  KNOWLEDGE_POINTS: '/knowledge-points',
  KNOWLEDGE_POINT_DETAIL: (id: number) => `/knowledge-points/${id}`,
  CHAPTERS: '/chapters',

  // 练习相关
  QUESTIONS: '/questions',
  SUBMIT_ANSWER: '/practice/submit',
  PRACTICE_RECORDS: '/practice/records',
  GENERATE_PRACTICE: '/practice/generate',

  // AI 问答
  AI_CHAT: '/ai/chat',
  AI_CHAT_STREAM: '/ai/chat/stream',
  AI_OCR: '/ai/ocr',

  // 错题本
  WRONG_QUESTIONS: '/wrong-questions',
  WRONG_QUESTION_DETAIL: (id: number) => `/wrong-questions/${id}`,

  // 学习报告
  LEARNING_REPORT: '/reports/learning',
  WEAK_POINTS: '/reports/weak-points',
  PROGRESS: '/reports/progress',
};
