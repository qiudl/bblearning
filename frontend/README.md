# Math智学 - 初中数学AI学习APP 前端

基于 **React + TypeScript + Ant Design** 构建的现代化学习应用前端。

## 技术栈

- **React 18** - UI 框架
- **TypeScript** - 类型安全
- **Ant Design** - UI 组件库
- **React Router** - 路由管理
- **Zustand** - 状态管理
- **Axios** - HTTP 请求

## 项目结构

```
frontend/
├── src/
│   ├── components/          # 公共组件
│   │   └── Layout/          # 布局组件
│   ├── pages/               # 页面组件
│   │   ├── Learn/           # 知识点学习
│   │   ├── Practice/        # 智能练习
│   │   ├── AIChat/          # AI问答助手
│   │   ├── WrongQuestions/  # 错题本
│   │   └── Progress/        # 学习进度
│   ├── config/              # 配置文件
│   ├── services/            # 服务层
│   ├── store/               # 状态管理
│   ├── types/               # TypeScript 类型定义
│   ├── App.tsx              # 应用入口
│   └── index.tsx            # 渲染入口
└── package.json
```

## 核心功能

### 1. 知识点学习 (`/learn`)
- 📚 按章节展示知识点
- 📊 显示掌握度进度
- 🎬 支持视频讲解
- ✏️ 快速开始练习

### 2. 智能练习 (`/practice`)
- ✅ 支持选择题、填空题、解答题
- 🎯 难度自适应
- 📝 即时批改和解析
- 📈 实时答题统计

### 3. AI问答助手 (`/ai-chat`)
- 💬 苏格拉底式引导
- 📷 拍照识别题目（OCR）
- 🤖 智能对话交互
- ⏱️ 每日提问次数限制

### 4. 错题本 (`/wrong-questions`)
- 📖 自动收录错题
- 🔄 支持重做
- 🏷️ 按章节、难度分类

### 5. 学习进度 (`/progress`)
- 📊 今日学习数据
- 🔥 连续学习天数
- 📈 知识点掌握度可视化
- 💡 薄弱点分析和建议

## 开始使用

### 安装依赖

```bash
npm install
```

### 启动开发服务器

```bash
npm start
```

应用将在 http://localhost:3000 打开

### 构建生产版本

```bash
npm run build
```

## 环境变量

创建 `.env` 文件配置后端 API 地址：

```env
REACT_APP_API_URL=http://localhost:3000/api
```

## 状态管理

使用 Zustand 进行全局状态管理：

```typescript
import { useAppStore } from './store';

function MyComponent() {
  const { user, setUser, logout } = useAppStore();
  // ...
}
```

## 下一步开发计划

- [ ] 添加用户登录/注册页面
- [ ] 集成真实后端 API
- [ ] 添加单元测试
- [ ] 优化移动端体验
- [ ] 性能优化和懒加载
