import { create } from 'zustand';
import { User, Chapter, KnowledgePoint, LearningProgress } from '../types';

interface AppState {
  // 用户状态
  user: User | null;
  isAuthenticated: boolean;
  setUser: (user: User | null) => void;
  logout: () => void;

  // 章节和知识点
  chapters: Chapter[];
  currentKnowledgePoint: KnowledgePoint | null;
  setChapters: (chapters: Chapter[]) => void;
  setCurrentKnowledgePoint: (kp: KnowledgePoint | null) => void;

  // 学习进度
  learningProgress: LearningProgress | null;
  setLearningProgress: (progress: LearningProgress) => void;

  // UI 状态
  sidebarCollapsed: boolean;
  toggleSidebar: () => void;
}

export const useAppStore = create<AppState>((set) => ({
  // 用户状态初始值
  user: null,
  isAuthenticated: false,
  setUser: (user) => set({ user, isAuthenticated: !!user }),
  logout: () => {
    localStorage.removeItem('token');
    set({ user: null, isAuthenticated: false });
  },

  // 章节和知识点初始值
  chapters: [],
  currentKnowledgePoint: null,
  setChapters: (chapters) => set({ chapters }),
  setCurrentKnowledgePoint: (currentKnowledgePoint) => set({ currentKnowledgePoint }),

  // 学习进度初始值
  learningProgress: null,
  setLearningProgress: (learningProgress) => set({ learningProgress }),

  // UI 状态初始值
  sidebarCollapsed: false,
  toggleSidebar: () => set((state) => ({ sidebarCollapsed: !state.sidebarCollapsed })),
}));
