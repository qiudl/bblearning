import React from 'react';
import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import { ConfigProvider } from 'antd';
import zhCN from 'antd/locale/zh_CN';
import MainLayout from './components/Layout/MainLayout';
import LearnPage from './pages/Learn';
import PracticePage from './pages/Practice';
import AIChatPage from './pages/AIChat';
import WrongQuestionsPage from './pages/WrongQuestions';
import ProgressPage from './pages/Progress';
import './App.css';

function App() {
  return (
    <ConfigProvider locale={zhCN}>
      <BrowserRouter>
        <Routes>
          <Route path="/" element={<MainLayout />}>
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
