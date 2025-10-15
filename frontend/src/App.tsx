import React from 'react';
import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import { ConfigProvider } from 'antd';
import zhCN from 'antd/locale/zh_CN';
import MainLayout from './components/Layout/MainLayout';
import LoginPage from './pages/Login';
import LearnPage from './pages/Learn';
import PracticePage from './pages/Practice';
import AIChatPage from './pages/AIChat';
import WrongQuestionsPage from './pages/WrongQuestions';
import ProgressPage from './pages/Progress';
import { useAuthStore } from './store/auth';
import './App.css';

// 路由保护组件
const ProtectedRoute: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const isAuthenticated = useAuthStore((state) => state.isAuthenticated());
  const accessToken = useAuthStore((state) => state.accessToken);

  console.log('🔒 ProtectedRoute 检查:', { isAuthenticated, hasToken: !!accessToken });

  if (!isAuthenticated) {
    console.log('❌ 未认证，跳转到登录页');
    return <Navigate to="/login" replace />;
  }

  console.log('✅ 已认证，允许访问');
  return <>{children}</>;
};

function App() {
  return (
    <ConfigProvider locale={zhCN}>
      <BrowserRouter>
        <Routes>
          <Route path="/login" element={<LoginPage />} />
          <Route
            path="/"
            element={
              <ProtectedRoute>
                <MainLayout />
              </ProtectedRoute>
            }
          >
            <Route index element={<Navigate to="/learn" replace />} />
            <Route path="learn" element={<LearnPage />} />
            <Route path="practice" element={<PracticePage />} />
            <Route path="ai-chat" element={<AIChatPage />} />
            <Route path="wrong-questions" element={<WrongQuestionsPage />} />
            <Route path="progress" element={<ProgressPage />} />
          </Route>
        </Routes>
      </BrowserRouter>
    </ConfigProvider>
  );
}

export default App;
