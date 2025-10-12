// 用户相关类型
export interface User {
  id: number;
  username: string;
  grade: string;
  avatar?: string;
  createdAt: string;
}

// 知识点相关类型
export interface Chapter {
  id: number;
  name: string;
  description?: string;
  order: number;
  knowledgePoints?: KnowledgePoint[];
}

export interface KnowledgePoint {
  id: number;
  chapterId: number;
  name: string;
  content: string;
  videoUrl?: string;
  difficulty: 'basic' | 'medium' | 'advanced';
  masteryLevel?: number; // 0-100 掌握度
}

// 题目相关类型
export type QuestionType = 'choice' | 'fill' | 'answer';
export type QuestionDifficulty = 'basic' | 'medium' | 'advanced';

export interface Question {
  id: number;
  knowledgePointId: number;
  type: QuestionType;
  content: string;
  options?: string[]; // 选择题选项
  answer: string;
  explanation: string;
  difficulty: QuestionDifficulty;
}

// 练习记录
export interface PracticeRecord {
  id: number;
  userId: number;
  questionId: number;
  userAnswer: string;
  isCorrect: boolean;
  timestamp: string;
  question?: Question;
}

// 错题
export interface WrongQuestion {
  id: number;
  userId: number;
  questionId: number;
  wrongCount: number;
  lastWrongTime: string;
  question?: Question;
}

// AI 聊天消息
export interface ChatMessage {
  id: string;
  role: 'user' | 'assistant';
  content: string;
  timestamp: string;
  images?: string[]; // 用户上传的图片
}

// 学习报告
export interface LearningReport {
  studyDays: number;
  totalQuestions: number;
  correctRate: number;
  weakPoints: WeakPoint[];
  suggestions: string[];
}

export interface WeakPoint {
  knowledgePointId: number;
  knowledgePointName: string;
  correctRate: number;
  questionCount: number;
}

// 学习进度
export interface LearningProgress {
  todayStudyTime: number; // 分钟
  continuousDays: number;
  weeklyQuestions: number;
  overallCorrectRate: number;
  knowledgePointProgress: {
    knowledgePointId: number;
    knowledgePointName: string;
    masteryLevel: number;
  }[];
}
