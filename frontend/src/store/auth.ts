import { create } from 'zustand';
import { persist } from 'zustand/middleware';

interface User {
  id: number;
  username: string;
  grade?: string;
  avatar?: string;
}

interface AuthState {
  user: User | null;
  accessToken: string | null;
  refreshToken: string | null;
  setAuth: (user: User, accessToken: string, refreshToken: string) => void;
  clearAuth: () => void;
  isAuthenticated: () => boolean;
}

export const useAuthStore = create<AuthState>()(
  persist(
    (set, get) => ({
      user: null,
      accessToken: null,
      refreshToken: null,

      setAuth: (user, accessToken, refreshToken) => {
        // 保存到localStorage
        localStorage.setItem('access_token', accessToken);
        localStorage.setItem('refresh_token', refreshToken);

        set({ user, accessToken, refreshToken });
      },

      clearAuth: () => {
        // 清除localStorage
        localStorage.removeItem('access_token');
        localStorage.removeItem('refresh_token');

        set({ user: null, accessToken: null, refreshToken: null });
      },

      isAuthenticated: () => {
        const { accessToken } = get();
        return !!accessToken;
      },
    }),
    {
      name: 'auth-storage',
    }
  )
);
