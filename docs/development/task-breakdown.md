# 开发任务清单

## 项目信息
- **项目名称**: 初中数学AI学习APP (bblearning)
- **开发周期**: 预计3-4个月
- **开始日期**: 2025-10-12
- **项目类型**: 个人学习项目（供孩子使用）

---

## Phase 1: 基础架构搭建 (2周)

### 1.1 项目初始化

#### 任务 1.1.1: 创建后端项目结构 ⏱️ 4小时
**优先级**: 🔴 高
**负责人**: 开发者
**前置条件**: 已安装Golang 1.21+

**详细步骤**:
```bash
# 1. 创建项目目录
mkdir backend && cd backend
go mod init github.com/qiudl/bblearning-backend

# 2. 创建目录结构
mkdir -p cmd/server
mkdir -p internal/{api,service,repository,domain,pkg}
mkdir -p internal/api/{handlers,middleware,routes}
mkdir -p internal/service/{user,knowledge,practice,ai,analytics}
mkdir -p internal/repository/{postgres,redis,minio}
mkdir -p internal/domain/{models,dto,enum}
mkdir -p internal/pkg/{auth,cache,logger,validator}
mkdir -p config migrations scripts test docs

# 3. 创建基础文件
touch cmd/server/main.go
touch config/config.yaml
touch .env.example
touch .gitignore
touch Dockerfile
touch Makefile
touch README.md
```

**核心文件内容**:
- `cmd/server/main.go`: 应用入口
- `config/config.yaml`: 配置文件模板
- `.env.example`: 环境变量示例
- `Makefile`: 构建脚本

**验收标准**:
- [ ] 项目结构完整
- [ ] go.mod 文件正确
- [ ] 能够运行 `go build`

---

#### 任务 1.1.2: 创建前端Web项目 ⏱️ 3小时
**优先级**: 🔴 高
**负责人**: 开发者
**前置条件**: 已安装Node.js 18+

**详细步骤**:
```bash
# 1. 使用Vite创建React项目
npm create vite@latest web -- --template react-ts
cd web
npm install

# 2. 安装核心依赖
npm install react-router-dom zustand
npm install axios
npm install @ant-design/icons antd
npm install tailwindcss postcss autoprefixer
npm install katex @types/katex

# 3. 安装开发依赖
npm install -D @types/node
npm install -D eslint prettier
npm install -D @typescript-eslint/eslint-plugin

# 4. 创建目录结构
mkdir -p src/{components,pages,hooks,services,store,utils,types}
mkdir -p src/components/{Layout,MathInput,MathRenderer,Charts}
mkdir -p src/pages/{Dashboard,Knowledge,Practice,Review,Profile}
```

**配置文件**:
- `tailwind.config.js`: Tailwind CSS配置
- `tsconfig.json`: TypeScript配置
- `.eslintrc.json`: ESLint规则
- `.prettierrc`: 代码格式化规则

**验收标准**:
- [ ] 项目能够启动 `npm run dev`
- [ ] TypeScript 配置正确
- [ ] Tailwind CSS 生效
- [ ] 路由配置完成

---

#### 任务 1.1.3: Git工作流设置 ⏱️ 1小时
**优先级**: 🟡 中
**负责人**: 开发者

**详细步骤**:
```bash
# 1. 创建分支
git checkout -b develop
git push -u origin develop

# 2. 创建 .gitignore
cat > .gitignore << EOF
# Backend
backend/bin/
backend/tmp/
*.log

# Frontend
web/node_modules/
web/dist/
web/.env.local

# IDE
.vscode/
.idea/
*.swp

# OS
.DS_Store
Thumbs.db

# Env files
.env
.env.local
EOF

# 3. 配置 Git Hooks
# 安装 husky
cd web && npx husky-init && npm install
```

**验收标准**:
- [ ] develop 分支已创建
- [ ] .gitignore 配置完整
- [ ] 提交规范已设置

---

### 1.2 数据库设计与创建

#### 任务 1.2.1: 编写数据库迁移脚本 ⏱️ 6小时
**优先级**: 🔴 高
**负责人**: 开发者
**前置条件**: PostgreSQL 15+

**详细步骤**:

1. **安装迁移工具**:
```bash
go install -tags 'postgres' github.com/golang-migrate/migrate/v4/cmd/migrate@latest
```

2. **创建迁移文件**:
```bash
cd backend/migrations

# 001 - 用户表
migrate create -ext sql -dir . -seq create_users_table

# 002 - 知识点表
migrate create -ext sql -dir . -seq create_knowledge_points_table

# 003 - 题目表
migrate create -ext sql -dir . -seq create_questions_table

# 004 - 学习记录表
migrate create -ext sql -dir . -seq create_learning_records_table

# 005 - 练习记录表
migrate create -ext sql -dir . -seq create_practice_records_table

# 006 - 错题本表
migrate create -ext sql -dir . -seq create_wrong_questions_table

# 007 - 学习统计表
migrate create -ext sql -dir . -seq create_learning_statistics_table

# 008 - 索引
migrate create -ext sql -dir . -seq create_indexes
```

3. **编写SQL内容** (参考tech-architecture.md第3.4节)

**验收标准**:
- [ ] 所有迁移文件已创建
- [ ] UP和DOWN脚本都已编写
- [ ] 本地测试迁移成功
- [ ] 索引已优化

---

#### 任务 1.2.2: 初始化种子数据 ⏱️ 4小时
**优先级**: 🟡 中
**负责人**: 开发者

**详细步骤**:

1. **创建种子数据脚本**:
```bash
cd backend/scripts
touch seed_data.go
```

2. **准备数据**:
- 初中7-9年级知识点树结构
- 测试用户数据
- 示例题目数据（每个知识点5-10道）

3. **编写种子数据**:
```go
// scripts/seed_data.go
package main

import (
    "database/sql"
    "log"
    _ "github.com/lib/pq"
)

func main() {
    // 连接数据库
    // 插入知识点
    // 插入示例题目
    // 插入测试用户
}
```

**数据要求**:
- 七年级知识点: 20+个
- 八年级知识点: 20+个
- 九年级知识点: 20+个
- 示例题目: 150+道

**验收标准**:
- [ ] 种子数据脚本可运行
- [ ] 知识点树结构完整
- [ ] 示例题目覆盖各难度

---

### 1.3 Docker开发环境配置

#### 任务 1.3.1: 编写Docker配置文件 ⏱️ 3小时
**优先级**: 🔴 高
**负责人**: 开发者

**详细步骤**:

1. **创建docker-compose.yml**:
```yaml
version: '3.8'

services:
  postgres:
    image: postgres:15-alpine
    container_name: bblearning-postgres
    environment:
      POSTGRES_DB: bblearning_dev
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./backend/migrations:/migrations
    networks:
      - bblearning

  redis:
    image: redis:7-alpine
    container_name: bblearning-redis
    ports:
      - "6379:6379"
    volumes:
      - redis_data:/data
    networks:
      - bblearning

  minio:
    image: minio/minio:latest
    container_name: bblearning-minio
    command: server /data --console-address ":9001"
    ports:
      - "9000:9000"
      - "9001:9001"
    environment:
      MINIO_ROOT_USER: minioadmin
      MINIO_ROOT_PASSWORD: minioadmin
    volumes:
      - minio_data:/data
    networks:
      - bblearning

volumes:
  postgres_data:
  redis_data:
  minio_data:

networks:
  bblearning:
    driver: bridge
```

2. **创建后端Dockerfile**:
```dockerfile
# backend/Dockerfile
FROM golang:1.21-alpine AS builder

WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download

COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -o main cmd/server/main.go

FROM alpine:latest
RUN apk --no-cache add ca-certificates
WORKDIR /root/
COPY --from=builder /app/main .
COPY --from=builder /app/config ./config

EXPOSE 8080
CMD ["./main"]
```

3. **创建前端Dockerfile**:
```dockerfile
# web/Dockerfile
FROM node:18-alpine AS builder

WORKDIR /app
COPY package*.json ./
RUN npm ci

COPY . .
RUN npm run build

FROM nginx:alpine
COPY --from=builder /app/dist /usr/share/nginx/html
COPY nginx.conf /etc/nginx/nginx.conf

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
```

**验收标准**:
- [ ] docker-compose 能够启动所有服务
- [ ] PostgreSQL 可连接
- [ ] Redis 可连接
- [ ] MinIO 控制台可访问

---

#### 任务 1.3.2: 配置开发环境脚本 ⏱️ 2小时
**优先级**: 🟡 中
**负责人**: 开发者

**详细步骤**:

1. **创建启动脚本** (`scripts/dev-setup.sh`):
```bash
#!/bin/bash

echo "🚀 启动开发环境..."

# 启动Docker服务
docker-compose up -d postgres redis minio

# 等待数据库就绪
echo "⏳ 等待数据库就绪..."
sleep 5

# 运行迁移
echo "📊 运行数据库迁移..."
cd backend && make migrate-up

# 运行种子数据
echo "🌱 插入种子数据..."
go run scripts/seed_data.go

echo "✅ 开发环境就绪！"
```

2. **创建Makefile** (`backend/Makefile`):
```makefile
.PHONY: build run test migrate-up migrate-down seed

build:
	go build -o bin/server cmd/server/main.go

run:
	go run cmd/server/main.go

test:
	go test -v ./...

migrate-up:
	migrate -path migrations -database "postgresql://postgres:postgres@localhost:5432/bblearning_dev?sslmode=disable" up

migrate-down:
	migrate -path migrations -database "postgresql://postgres:postgres@localhost:5432/bblearning_dev?sslmode=disable" down

seed:
	go run scripts/seed_data.go
```

**验收标准**:
- [ ] 一键启动脚本可用
- [ ] Makefile 命令正常工作
- [ ] 开发环境完整可用

---

## Phase 2: 核心功能开发 (4-6周)

### 2.1 用户认证系统

#### 任务 2.1.1: 实现JWT认证 ⏱️ 8小时
**优先级**: 🔴 高
**负责人**: 开发者

**详细步骤**:

1. **安装依赖**:
```bash
go get github.com/golang-jwt/jwt/v5
go get golang.org/x/crypto/bcrypt
```

2. **创建认证服务**:
```go
// internal/pkg/auth/jwt.go
package auth

import (
    "time"
    "github.com/golang-jwt/jwt/v5"
)

type JWTManager struct {
    secretKey     string
    tokenDuration time.Duration
}

func NewJWTManager(secretKey string, duration time.Duration) *JWTManager {
    return &JWTManager{secretKey, duration}
}

func (m *JWTManager) Generate(userID string) (string, error) {
    // 生成token
}

func (m *JWTManager) Verify(token string) (*Claims, error) {
    // 验证token
}
```

3. **实现用户服务**:
- `internal/service/user/auth.go`: 注册/登录逻辑
- `internal/service/user/password.go`: 密码加密
- `internal/repository/postgres/user.go`: 用户数据访问

4. **实现API处理器**:
- `internal/api/handlers/auth.go`: 认证接口
- `internal/api/middleware/auth.go`: 认证中间件

**API端点**:
- POST `/api/v1/auth/register` - 用户注册
- POST `/api/v1/auth/login` - 用户登录
- POST `/api/v1/auth/refresh` - 刷新Token
- POST `/api/v1/auth/logout` - 登出

**验收标准**:
- [ ] 用户可以注册
- [ ] 用户可以登录获取Token
- [ ] Token可以刷新
- [ ] 密码正确加密存储
- [ ] 中间件验证Token正常
- [ ] 单元测试覆盖率>80%

**测试清单**:
- [ ] 注册时用户名已存在
- [ ] 登录密码错误
- [ ] Token过期处理
- [ ] 并发登录安全性

---

#### 任务 2.1.2: 前端认证模块 ⏱️ 6小时
**优先级**: 🔴 高
**负责人**: 开发者

**详细步骤**:

1. **创建认证Store**:
```typescript
// src/store/authStore.ts
import { create } from 'zustand';
import { persist } from 'zustand/middleware';

interface AuthState {
  user: User | null;
  token: string | null;
  login: (username: string, password: string) => Promise<void>;
  logout: () => void;
  register: (data: RegisterData) => Promise<void>;
}

export const useAuthStore = create<AuthState>()(
  persist(
    (set) => ({
      user: null,
      token: null,
      login: async (username, password) => {
        // 调用API
      },
      logout: () => {
        // 清除状态
      },
      register: async (data) => {
        // 调用API
      },
    }),
    {
      name: 'auth-storage',
    }
  )
);
```

2. **创建API服务**:
```typescript
// src/services/api.ts
import axios from 'axios';

const api = axios.create({
  baseURL: import.meta.env.VITE_API_URL,
});

// 请求拦截器
api.interceptors.request.use((config) => {
  const token = localStorage.getItem('token');
  if (token) {
    config.headers.Authorization = `Bearer ${token}`;
  }
  return config;
});

// 响应拦截器
api.interceptors.response.use(
  (response) => response,
  (error) => {
    if (error.response?.status === 401) {
      // Token过期，跳转登录
    }
    return Promise.reject(error);
  }
);

export default api;
```

3. **创建登录/注册页面**:
- `src/pages/Login.tsx`
- `src/pages/Register.tsx`

4. **路由守卫**:
```typescript
// src/components/ProtectedRoute.tsx
import { Navigate } from 'react-router-dom';
import { useAuthStore } from '@/store/authStore';

export const ProtectedRoute = ({ children }: { children: React.ReactNode }) => {
  const token = useAuthStore((state) => state.token);
  
  if (!token) {
    return <Navigate to="/login" replace />;
  }
  
  return <>{children}</>;
};
```

**验收标准**:
- [ ] 登录页面完成
- [ ] 注册页面完成
- [ ] Token持久化
- [ ] 路由守卫生效
- [ ] 自动刷新Token

---

### 2.2 知识点管理

#### 任务 2.2.1: 知识点后端服务 ⏱️ 10小时
**优先级**: 🔴 高
**负责人**: 开发者

**详细步骤**:

1. **定义领域模型**:
```go
// internal/domain/models/knowledge.go
package models

type KnowledgePoint struct {
    ID          string    `json:"id" gorm:"primaryKey"`
    Code        string    `json:"code" gorm:"uniqueIndex"`
    Name        string    `json:"name"`
    Grade       int       `json:"grade"`
    ParentID    *string   `json:"parent_id"`
    Description string    `json:"description"`
    Content     JSONB     `json:"content" gorm:"type:jsonb"`
    OrderIndex  int       `json:"order_index"`
    CreatedAt   time.Time `json:"created_at"`
}

type LearningProgress struct {
    ID               string    `json:"id"`
    UserID           string    `json:"user_id"`
    KnowledgePointID string    `json:"knowledge_point_id"`
    Status           string    `json:"status"` // not_started, learning, mastered
    MasteryLevel     float64   `json:"mastery_level"`
    LastLearnedAt    time.Time `json:"last_learned_at"`
}
```

2. **实现仓库层**:
```go
// internal/repository/postgres/knowledge.go
package postgres

type KnowledgeRepository struct {
    db *gorm.DB
}

func (r *KnowledgeRepository) GetTree(grade int) ([]*models.KnowledgeNode, error) {
    // 查询知识点树
}

func (r *KnowledgeRepository) GetByID(id string) (*models.KnowledgePoint, error) {
    // 查询单个知识点
}
```

3. **实现服务层**:
```go
// internal/service/knowledge/service.go
package knowledge

type Service struct {
    repo  repository.KnowledgeRepository
    cache cache.Cache
}

func (s *Service) GetKnowledgeTree(ctx context.Context, grade int) ([]*dto.KnowledgeNode, error) {
    // 1. 检查缓存
    // 2. 查询数据库
    // 3. 构建树结构
    // 4. 缓存结果
}
```

4. **实现API处理器**:
```go
// internal/api/handlers/knowledge.go
package handlers

func (h *KnowledgeHandler) GetTree(c *gin.Context) {
    // 处理请求
}

func (h *KnowledgeHandler) GetDetail(c *gin.Context) {
    // 处理请求
}

func (h *KnowledgeHandler) UpdateProgress(c *gin.Context) {
    // 处理请求
}
```

**API端点**:
- GET `/api/v1/knowledge/tree?grade=7` - 获取知识点树
- GET `/api/v1/knowledge/:id` - 获取知识点详情
- PUT `/api/v1/knowledge/:id/progress` - 更新学习进度

**验收标准**:
- [ ] 知识点树正确构建
- [ ] 学习进度可更新
- [ ] Redis缓存生效
- [ ] 单元测试通过

---

#### 任务 2.2.2: 知识点前端页面 ⏱️ 12小时
**优先级**: 🔴 高
**负责人**: 开发者

**详细步骤**:

1. **创建知识点Tree组件**:
```typescript
// src/components/KnowledgeTree.tsx
import { Tree } from 'antd';

interface KnowledgeTreeProps {
  grade: number;
  onSelect: (knowledgeId: string) => void;
}

export const KnowledgeTree: React.FC<KnowledgeTreeProps> = ({ grade, onSelect }) => {
  const [treeData, setTreeData] = useState([]);
  
  useEffect(() => {
    // 加载知识点树
  }, [grade]);
  
  return <Tree treeData={treeData} onSelect={onSelect} />;
};
```

2. **创建知识点详情页**:
```typescript
// src/pages/Knowledge/Detail.tsx
export const KnowledgeDetail = () => {
  const { id } = useParams();
  const [knowledge, setKnowledge] = useState(null);
  const [progress, setProgress] = useState(null);
  
  return (
    <div className="knowledge-detail">
      <h1>{knowledge?.name}</h1>
      <div className="content">
        {/* 知识点内容 */}
      </div>
      <div className="progress">
        {/* 学习进度 */}
      </div>
      <div className="actions">
        <Button onClick={startPractice}>开始练习</Button>
      </div>
    </div>
  );
};
```

3. **创建学习进度组件**:
```typescript
// src/components/LearningProgress.tsx
export const LearningProgress = ({ masteryLevel }) => {
  return (
    <div className="progress-bar">
      <Progress percent={masteryLevel * 100} />
      <span>{getLevelText(masteryLevel)}</span>
    </div>
  );
};
```

**页面要求**:
- 知识点列表页（树形结构）
- 知识点详情页
- 学习进度可视化
- 相关练习题链接

**验收标准**:
- [ ] 知识点树渲染正确
- [ ] 详情页展示完整
- [ ] 进度更新实时
- [ ] 响应式设计

---

### 2.3 练习功能

#### 任务 2.3.1: 题目管理后端 ⏱️ 12小时
**优先级**: 🔴 高
**负责人**: 开发者

**详细步骤**:

1. **定义题目模型**:
```go
// internal/domain/models/question.go
type Question struct {
    ID               string    `json:"id"`
    KnowledgePointID string    `json:"knowledge_point_id"`
    Type             string    `json:"type"` // choice, blank, solve
    Difficulty       int       `json:"difficulty"` // 1-5
    Content          JSONB     `json:"content"`
    Answer           JSONB     `json:"answer"`
    Solution         JSONB     `json:"solution"`
    Source           string    `json:"source"`
    Tags             JSONB     `json:"tags"`
    CreatedAt        time.Time `json:"created_at"`
}

type PracticeRecord struct {
    ID         string    `json:"id"`
    UserID     string    `json:"user_id"`
    QuestionID string    `json:"question_id"`
    UserAnswer JSONB     `json:"user_answer"`
    IsCorrect  bool      `json:"is_correct"`
    Score      float64   `json:"score"`
    TimeSpent  int       `json:"time_spent"`
    AIFeedback JSONB     `json:"ai_feedback"`
    CreatedAt  time.Time `json:"created_at"`
}
```

2. **实现练习服务**:
```go
// internal/service/practice/service.go
func (s *Service) GeneratePractice(ctx context.Context, req *dto.GeneratePracticeRequest) ([]*models.Question, error) {
    // 1. 根据知识点和难度筛选题目
    // 2. 随机选择题目
    // 3. 记录练习会话
    return questions, nil
}

func (s *Service) SubmitAnswer(ctx context.Context, req *dto.SubmitAnswerRequest) (*dto.AnswerResult, error) {
    // 1. 验证答案
    // 2. 计算得分
    // 3. 调用AI批改（如果是解答题）
    // 4. 记录练习结果
    // 5. 更新学习进度
    return result, nil
}
```

3. **实现错题本**:
```go
// internal/service/practice/wrong_questions.go
func (s *Service) AddToWrongQuestions(ctx context.Context, userID, questionID string) error {
    // 添加到错题本
}

func (s *Service) GetWrongQuestions(ctx context.Context, userID string, filters *Filters) ([]*models.Question, error) {
    // 获取错题列表
}
```

**API端点**:
- POST `/api/v1/practice/generate` - 生成练习题
- POST `/api/v1/practice/submit` - 提交答案
- GET `/api/v1/practice/history` - 练习历史
- GET `/api/v1/practice/wrong-questions` - 错题本
- PUT `/api/v1/practice/wrong-questions/:id/resolve` - 标记已解决

**验收标准**:
- [ ] 题目生成算法合理
- [ ] 答案判定准确
- [ ] 错题本功能完整
- [ ] 练习记录可查询

---

#### 任务 2.3.2: 练习页面前端 ⏱️ 16小时
**优先级**: 🔴 高
**负责人**: 开发者

**详细步骤**:

1. **创建题目渲染组件**:
```typescript
// src/components/QuestionRenderer.tsx
export const QuestionRenderer = ({ question, onAnswer }) => {
  const renderContent = () => {
    switch (question.type) {
      case 'choice':
        return <ChoiceQuestion question={question} onAnswer={onAnswer} />;
      case 'blank':
        return <BlankQuestion question={question} onAnswer={onAnswer} />;
      case 'solve':
        return <SolveQuestion question={question} onAnswer={onAnswer} />;
    }
  };
  
  return (
    <div className="question-container">
      <div className="question-header">
        <span>难度: {question.difficulty}</span>
        <span>知识点: {question.knowledge_point}</span>
      </div>
      <div className="question-content">
        <MathRenderer content={question.content} />
      </div>
      {renderContent()}
    </div>
  );
};
```

2. **创建数学公式组件**:
```typescript
// src/components/MathRenderer.tsx
import katex from 'katex';
import 'katex/dist/katex.min.css';

export const MathRenderer = ({ content }) => {
  const renderMath = (text) => {
    // 解析 $ ... $ 和 $$ ... $$
    // 使用KaTeX渲染
  };
  
  return <div dangerouslySetInnerHTML={{ __html: renderMath(content) }} />;
};
```

3. **创建练习页面**:
```typescript
// src/pages/Practice/index.tsx
export const Practice = () => {
  const [questions, setQuestions] = useState([]);
  const [currentIndex, setCurrentIndex] = useState(0);
  const [answers, setAnswers] = useState({});
  
  const handleSubmit = async () => {
    const result = await submitAnswers(answers);
    // 显示结果
  };
  
  return (
    <div className="practice-page">
      <Progress current={currentIndex + 1} total={questions.length} />
      <QuestionRenderer 
        question={questions[currentIndex]} 
        onAnswer={(answer) => setAnswers({...answers, [currentIndex]: answer})}
      />
      <div className="actions">
        <Button onClick={prevQuestion}>上一题</Button>
        <Button onClick={nextQuestion}>下一题</Button>
        <Button onClick={handleSubmit}>提交</Button>
      </div>
    </div>
  );
};
```

4. **创建结果页面**:
```typescript
// src/pages/Practice/Result.tsx
export const PracticeResult = () => {
  // 显示得分
  // 显示错题分析
  // 显示AI反馈
  // 提供查看详解按钮
};
```

**验收标准**:
- [ ] 数学公式正确渲染
- [ ] 三种题型正常显示
- [ ] 答题计时功能
- [ ] 结果反馈清晰
- [ ] 错题可收藏

---

### 2.4 学习记录与统计

#### 任务 2.4.1: 统计服务后端 ⏱️ 8小时
**优先级**: 🟡 中
**负责人**: 开发者

**详细步骤**:

1. **实现统计服务**:
```go
// internal/service/analytics/service.go
func (s *Service) GetLearningStatistics(ctx context.Context, userID string, startDate, endDate time.Time) (*dto.Statistics, error) {
    // 查询学习数据
    // 计算各项指标
}

func (s *Service) UpdateDailyStats(ctx context.Context, userID string) error {
    // 更新每日统计
}
```

2. **定时任务**:
```go
// 每天凌晨更新统计
c := cron.New()
c.AddFunc("0 0 * * *", func() {
    analyticsService.UpdateAllUsersStats()
})
c.Start()
```

**API端点**:
- GET `/api/v1/statistics/learning` - 学习统计
- GET `/api/v1/statistics/knowledge-mastery` - 知识点掌握
- GET `/api/v1/statistics/progress` - 进步曲线

**验收标准**:
- [ ] 统计数据准确
- [ ] 定时任务正常
- [ ] 性能优化完成

---

#### 任务 2.4.2: 数据可视化前端 ⏱️ 10小时
**优先级**: 🟡 中
**负责人**: 开发者

**详细步骤**:

1. **安装图表库**:
```bash
npm install echarts recharts
```

2. **创建Dashboard页面**:
```typescript
// src/pages/Dashboard/index.tsx
export const Dashboard = () => {
  return (
    <div className="dashboard">
      <div className="stats-cards">
        <StatCard title="学习时长" value="120小时" />
        <StatCard title="完成题目" value="500题" />
        <StatCard title="正确率" value="85%" />
        <StatCard title="掌握知识点" value="15个" />
      </div>
      
      <div className="charts">
        <LearningTimeChart />
        <ProgressCurve />
        <KnowledgeRadar />
      </div>
      
      <div className="recent-activities">
        <RecentPractices />
        <WrongQuestions />
      </div>
    </div>
  );
};
```

3. **创建图表组件**:
- 学习时长趋势图
- 正确率曲线
- 知识点掌握雷达图
- 每日练习量柱状图

**验收标准**:
- [ ] 图表数据准确
- [ ] 图表交互流畅
- [ ] 响应式布局

---

## Phase 3: AI功能集成 (3-4周)

### 3.1 AI题目生成

#### 任务 3.1.1: 集成OpenAI API ⏱️ 6小时
**优先级**: 🔴 高
**负责人**: 开发者

**详细步骤**:

1. **安装SDK**:
```bash
go get github.com/sashabaranov/go-openai
```

2. **创建AI服务**:
```go
// internal/service/ai/openai.go
package ai

import (
    "context"
    "github.com/sashabaranov/go-openai"
)

type OpenAIService struct {
    client *openai.Client
    config *Config
}

func NewOpenAIService(apiKey string) *OpenAIService {
    client := openai.NewClient(apiKey)
    return &OpenAIService{
        client: client,
        config: &Config{
            Model:       openai.GPT4,
            Temperature: 0.7,
            MaxTokens:   2000,
        },
    }
}

func (s *OpenAIService) GenerateQuestion(ctx context.Context, req *GenerateQuestionRequest) (*Question, error) {
    prompt := s.buildPrompt(req)
    
    resp, err := s.client.CreateChatCompletion(ctx, openai.ChatCompletionRequest{
        Model: s.config.Model,
        Messages: []openai.ChatCompletionMessage{
            {
                Role:    openai.ChatMessageRoleSystem,
                Content: "你是一位经验丰富的初中数学教师",
            },
            {
                Role:    openai.ChatMessageRoleUser,
                Content: prompt,
            },
        },
        Temperature: s.config.Temperature,
        MaxTokens:   s.config.MaxTokens,
    })
    
    if err != nil {
        return nil, err
    }
    
    question, err := s.parseQuestionResponse(resp.Choices[0].Message.Content)
    return question, err
}
```

3. **编写Prompt模板**:
```go
// internal/service/ai/prompts.go
const QuestionGeneratePrompt = `
你是一位经验丰富的初中数学老师，请根据以下要求生成一道数学题：

知识点：{{.KnowledgePoint}}
年级：{{.Grade}}
难度：{{.Difficulty}} (1-5，5最难)
题目类型：{{.QuestionType}}

要求：
1. 题目要符合初中生认知水平
2. 语言表达清晰准确
3. 题目有一定的思考性
4. 提供详细的解题步骤
5. 标注所用到的知识点

请以JSON格式返回，包含：
{
  "question": "题目内容（使用LaTeX表示数学公式，用$符号包裹）",
  "answer": "标准答案",
  "solution": {
    "steps": ["步骤1", "步骤2", ...],
    "explanation": "详细解释"
  },
  "difficulty_analysis": "难点分析",
  "knowledge_points": ["涉及的知识点列表"]
}
`
```

**验收标准**:
- [ ] API调用成功
- [ ] Prompt工程优化
- [ ] 错误处理完善
- [ ] 响应缓存机制

---

#### 任务 3.1.2: AI题目生成API ⏱️ 4小时
**优先级**: 🔴 高
**负责人**: 开发者

**API端点**:
- POST `/api/v1/ai/generate-question` - 生成题目

**验收标准**:
- [ ] 生成的题目质量高
- [ ] 答案准确
- [ ] 解题步骤清晰
- [ ] 响应时间<5秒

---

### 3.2 AI智能批改

#### 任务 3.2.1: 实现批改服务 ⏱️ 8小时
**优先级**: 🔴 高
**负责人**: 开发者

**详细步骤**:

1. **创建批改服务**:
```go
// internal/service/ai/grading.go
func (s *OpenAIService) GradeAnswer(ctx context.Context, req *GradeRequest) (*GradeResult, error) {
    prompt := s.buildGradingPrompt(req)
    
    resp, err := s.callAPI(ctx, prompt)
    if err != nil {
        return nil, err
    }
    
    result := &GradeResult{}
    err = json.Unmarshal([]byte(resp), result)
    
    return result, err
}
```

2. **批改Prompt**:
```go
const GradingPrompt = `
请批改以下数学题的答案：

题目：{{.Question}}
标准答案：{{.StandardAnswer}}
学生答案：{{.UserAnswer}}
解题步骤：{{.UserSolution}}

请分析：
1. 答案是否正确
2. 解题思路是否正确
3. 具体错在哪里
4. 给出改进建议
5. 给出分数（0-100）

以JSON格式返回：
{
  "is_correct": true/false,
  "score": 0-100,
  "analysis": {
    "correctness": "答案正确性分析",
    "process": "解题过程分析",
    "errors": ["错误点1", "错误点2"],
    "suggestions": ["建议1", "建议2"]
  },
  "detailed_feedback": "详细反馈"
}
`
```

**验收标准**:
- [ ] 批改准确
- [ ] 反馈有价值
- [ ] 支持图片答案（OCR）

---

### 3.3 AI学习诊断

#### 任务 3.3.1: 实现诊断服务 ⏱️ 10小时
**优先级**: 🟡 中
**负责人**: 开发者

**详细步骤**:

1. **数据分析**:
```go
// internal/service/ai/diagnosis.go
func (s *AIService) DiagnoseWeakness(ctx context.Context, userID string) (*DiagnosisReport, error) {
    // 1. 获取用户最近100次练习记录
    records := s.repo.GetRecentPracticeRecords(ctx, userID, 100)
    
    // 2. 统计分析
    stats := analyzeRecords(records)
    
    // 3. 构建诊断prompt
    prompt := buildDiagnosisPrompt(stats)
    
    // 4. 调用AI
    diagnosis := s.callAI(ctx, prompt)
    
    // 5. 保存诊断报告
    report := &DiagnosisReport{
        UserID:      userID,
        GeneratedAt: time.Now(),
        Content:     diagnosis,
        Statistics:  stats,
    }
    
    s.repo.SaveDiagnosisReport(ctx, report)
    
    return report, nil
}
```

2. **分析维度**:
- 知识点掌握情况
- 常见错误类型
- 答题速度分析
- 进步趋势

**API端点**:
- GET `/api/v1/ai/diagnose` - 学习诊断
- GET `/api/v1/ai/recommend` - 学习推荐

**验收标准**:
- [ ] 诊断报告准确
- [ ] 推荐有针对性
- [ ] 每周自动生成

---

### 3.4 个性化推荐

#### 任务 3.4.1: 推荐算法实现 ⏱️ 12小时
**优先级**: 🟡 中
**负责人**: 开发者

**推荐策略**:
1. 基于薄弱知识点推荐
2. 基于错题类型推荐
3. 基于学习进度推荐
4. 基于难度梯度推荐

**验收标准**:
- [ ] 推荐算法合理
- [ ] 推荐效果好
- [ ] 每日自动推荐

---

## Phase 4: iOS App开发 (4-6周)

### 4.1 React Native环境搭建

#### 任务 4.1.1: 初始化RN项目 ⏱️ 4小时
**优先级**: 🔴 高
**负责人**: 开发者

**详细步骤**:

1. **创建项目**:
```bash
npx react-native@latest init BBLearning
cd BBLearning

# 安装依赖
npm install @react-navigation/native @react-navigation/stack
npm install react-native-screens react-native-safe-area-context
npm install zustand axios
npm install @react-native-async-storage/async-storage
npm install react-native-svg
npm install react-native-webview  # 用于渲染数学公式
```

2. **配置iOS**:
```bash
cd ios
pod install
cd ..
```

3. **项目结构**:
```
ios-app/
├── src/
│   ├── components/    # 共享组件
│   ├── screens/       # 页面
│   ├── navigation/    # 导航
│   ├── services/      # API服务
│   ├── store/         # 状态管理
│   ├── utils/         # 工具函数
│   └── types/         # 类型定义
├── ios/               # iOS原生代码
├── android/           # Android原生代码（暂不开发）
└── package.json
```

**验收标准**:
- [ ] 项目可在Xcode中打开
- [ ] 能在模拟器运行
- [ ] 能在真机运行

---

#### 任务 4.1.2: 代码复用策略 ⏱️ 6小时
**优先级**: 🔴 高
**负责人**: 开发者

**复用策略**:

1. **共享业务逻辑**:
```typescript
// shared/store/ - 状态管理（完全复用）
// shared/services/ - API服务（完全复用）
// shared/utils/ - 工具函数（完全复用）
// shared/types/ - 类型定义（完全复用）
```

2. **平台特定UI**:
```typescript
// src/components/Button.tsx (Web)
// src/components/Button.native.tsx (React Native)
```

3. **创建Monorepo结构**:
```bash
bblearning/
├── packages/
│   ├── shared/        # 共享代码
│   ├── web/          # Web应用
│   └── mobile/       # 移动应用
└── package.json
```

**验收标准**:
- [ ] 共享代码正常工作
- [ ] 平台特定代码隔离
- [ ] 构建流程顺畅

---

### 4.2 核心页面开发

#### 任务 4.2.1: 导航结构 ⏱️ 4小时
**优先级**: 🔴 高
**负责人**: 开发者

**导航设计**:
```typescript
// src/navigation/AppNavigator.tsx
import { createStackNavigator } from '@react-navigation/stack';
import { createBottomTabNavigator } from '@react-navigation/bottom-tabs';

const Tab = createBottomTabNavigator();
const Stack = createStackNavigator();

function MainTabs() {
  return (
    <Tab.Navigator>
      <Tab.Screen name="Dashboard" component={DashboardScreen} />
      <Tab.Screen name="Knowledge" component={KnowledgeScreen} />
      <Tab.Screen name="Practice" component={PracticeScreen} />
      <Tab.Screen name="Profile" component={ProfileScreen} />
    </Tab.Navigator>
  );
}

function AppNavigator() {
  return (
    <Stack.Navigator>
      <Stack.Screen name="Login" component={LoginScreen} />
      <Stack.Screen name="Main" component={MainTabs} />
      <Stack.Screen name="PracticeDetail" component={PracticeDetailScreen} />
    </Stack.Navigator>
  );
}
```

**验收标准**:
- [ ] 导航流畅
- [ ] 返回逻辑正确
- [ ] 深度链接支持

---

#### 任务 4.2.2: 主要页面实现 ⏱️ 20小时
**优先级**: 🔴 高
**负责人**: 开发者

**页面清单**:
1. 登录/注册页 (4h)
2. 首页Dashboard (4h)
3. 知识点列表页 (4h)
4. 练习页面 (6h)
5. 个人中心 (2h)

**验收标准**:
- [ ] 所有页面完成
- [ ] UI符合iOS规范
- [ ] 交互流畅

---

### 4.3 离线功能实现

#### 任务 4.3.1: 本地数据存储 ⏱️ 8小时
**优先级**: 🟡 中
**负责人**: 开发者

**详细步骤**:

1. **配置AsyncStorage**:
```typescript
// src/services/storage.ts
import AsyncStorage from '@react-native-async-storage/async-storage';

class StorageService {
  async saveQuestions(questions: Question[]) {
    await AsyncStorage.setItem('offline_questions', JSON.stringify(questions));
  }
  
  async getQuestions(): Promise<Question[]> {
    const data = await AsyncStorage.getItem('offline_questions');
    return data ? JSON.parse(data) : [];
  }
  
  async savePracticeRecord(record: PracticeRecord) {
    const records = await this.getPracticeRecords();
    records.push(record);
    await AsyncStorage.setItem('offline_records', JSON.stringify(records));
  }
}
```

2. **离线检测**:
```typescript
// src/hooks/useNetworkStatus.ts
import NetInfo from '@react-native-community/netinfo';

export const useNetworkStatus = () => {
  const [isConnected, setIsConnected] = useState(true);
  
  useEffect(() => {
    const unsubscribe = NetInfo.addEventListener(state => {
      setIsConnected(state.isConnected);
    });
    
    return () => unsubscribe();
  }, []);
  
  return isConnected;
};
```

**验收标准**:
- [ ] 离线可做题
- [ ] 离线数据存储
- [ ] 联网自动同步

---

### 4.4 数据同步机制

#### 任务 4.4.1: 增量同步 ⏱️ 10小时
**优先级**: 🔴 高
**负责人**: 开发者

**同步策略**:

1. **同步服务**:
```typescript
// src/services/sync.ts
class SyncService {
  async sync() {
    const lastSyncTime = await this.getLastSyncTime();
    
    // 1. 获取服务器增量更新
    const updates = await api.get('/sync/delta', {
      params: { last_sync_time: lastSyncTime }
    });
    
    // 2. 应用更新到本地
    await this.applyUpdates(updates);
    
    // 3. 上传本地未同步数据
    const localRecords = await this.getUnsyncedRecords();
    await api.post('/sync/upload', { records: localRecords });
    
    // 4. 更新同步时间
    await this.setLastSyncTime(new Date());
  }
  
  async conflictResolution(localData, serverData) {
    // 冲突解决策略：服务器优先
    return serverData;
  }
}
```

2. **自动同步**:
```typescript
// 应用启动时同步
// 从后台返回时同步
// 定时同步（每30分钟）
```

**验收标准**:
- [ ] 增量同步正常
- [ ] 冲突处理正确
- [ ] 性能优化完成

---

### 4.5 TestFlight测试

#### 任务 4.5.1: 准备发布 ⏱️ 6小时
**优先级**: 🟡 中
**负责人**: 开发者

**详细步骤**:

1. **配置签名**:
- 创建Apple Developer账号
- 创建App ID
- 配置证书和描述文件

2. **配置Info.plist**:
```xml
<key>CFBundleDisplayName</key>
<string>数学学习</string>
<key>CFBundleShortVersionString</key>
<string>1.0.0</string>
```

3. **打包上传**:
```bash
# 在Xcode中
# Product -> Archive
# Upload to App Store Connect
```

4. **TestFlight配置**:
- 添加测试用户（孩子的Apple ID）
- 配置测试说明
- 提交审核

**验收标准**:
- [ ] 成功上传到TestFlight
- [ ] 测试用户可安装
- [ ] 基本功能正常

---

## Phase 5: 优化与上线 (2-3周)

### 5.1 性能优化

#### 任务 5.1.1: 后端性能优化 ⏱️ 8小时
**优先级**: 🟡 中
**负责人**: 开发者

**优化项目**:

1. **数据库优化**:
```sql
-- 创建索引
CREATE INDEX idx_practice_records_user_id ON practice_records(user_id);
CREATE INDEX idx_practice_records_created_at ON practice_records(created_at);
CREATE INDEX idx_questions_knowledge_point_id ON questions(knowledge_point_id);
CREATE INDEX idx_questions_difficulty ON questions(difficulty);

-- 查询优化
EXPLAIN ANALYZE SELECT * FROM questions WHERE ...;
```

2. **缓存优化**:
```go
// 热点数据缓存
// 查询结果缓存
// 计算结果缓存
```

3. **并发优化**:
```go
// 使用goroutine处理耗时任务
// 使用channel协调并发
// 连接池优化
```

**性能目标**:
- API响应时间 < 300ms (P95)
- 数据库查询 < 100ms
- 缓存命中率 > 80%

**验收标准**:
- [ ] 性能测试通过
- [ ] 优化效果明显
- [ ] 无性能瓶颈

---

#### 任务 5.1.2: 前端性能优化 ⏱️ 6小时
**优先级**: 🟡 中
**负责人**: 开发者

**优化项目**:

1. **代码分割**:
```typescript
// 路由懒加载
const Dashboard = lazy(() => import('./pages/Dashboard'));
const Practice = lazy(() => import('./pages/Practice'));
```

2. **图片优化**:
- 使用WebP格式
- 图片懒加载
- 使用CDN

3. **Bundle优化**:
```bash
# 分析bundle大小
npm run build -- --report

# Tree shaking
# 移除未使用代码
```

**性能目标**:
- 首屏加载 < 2s
- FCP < 1.5s
- TTI < 3s

**验收标准**:
- [ ] Lighthouse评分 > 90
- [ ] Bundle大小优化
- [ ] 加载速度提升

---

### 5.2 Bug修复

#### 任务 5.2.1: Bug修复周 ⏱️ 40小时
**优先级**: 🔴 高
**负责人**: 开发者

**修复流程**:
1. 收集所有Bug
2. 按优先级排序
3. 逐个修复
4. 回归测试

**Bug分类**:
- 🔴 致命Bug（阻塞功能）
- 🟡 严重Bug（影响体验）
- 🟢 一般Bug（小问题）

**验收标准**:
- [ ] 致命Bug 100%修复
- [ ] 严重Bug 90%修复
- [ ] 一般Bug 70%修复

---

### 5.3 用户测试

#### 任务 5.3.1: 内部测试 ⏱️ 1周
**优先级**: 🔴 高
**负责人**: 开发者 + 孩子

**测试内容**:
1. 功能测试
2. 易用性测试
3. 性能测试
4. 兼容性测试

**测试清单**:
- [ ] 注册登录流程
- [ ] 知识点浏览
- [ ] 练习做题
- [ ] 错题复习
- [ ] 数据统计
- [ ] AI功能
- [ ] 离线功能（iOS）
- [ ] 数据同步（iOS）

**收集反馈**:
- 功能缺失
- 体验问题
- Bug报告
- 改进建议

---

### 5.4 部署上线

#### 任务 5.4.1: 服务器部署 ⏱️ 8小时
**优先级**: 🔴 高
**负责人**: 开发者

**详细步骤**:

1. **购买服务器**:
- 阿里云/腾讯云 2核4G
- 带宽 5M
- 系统盘 40G

2. **环境配置**:
```bash
# 安装Docker
curl -fsSL https://get.docker.com | sh

# 安装Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/download/v2.20.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# 安装Nginx
sudo apt install nginx
```

3. **部署应用**:
```bash
# 1. 上传代码
git clone https://github.com/qiudl/bblearning.git
cd bblearning

# 2. 配置环境变量
cp .env.example .env
# 编辑 .env

# 3. 启动服务
docker-compose -f docker-compose.prod.yml up -d

# 4. 运行迁移
docker-compose exec backend make migrate-up

# 5. 配置Nginx
sudo cp nginx.conf /etc/nginx/sites-available/bblearning
sudo ln -s /etc/nginx/sites-available/bblearning /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
```

4. **配置SSL证书**:
```bash
# 使用Let's Encrypt
sudo apt install certbot python3-certbot-nginx
sudo certbot --nginx -d api.bblearning.com
```

5. **配置监控**:
- 安装监控工具
- 配置告警
- 日志收集

**验收标准**:
- [ ] 应用正常运行
- [ ] HTTPS配置完成
- [ ] 监控正常工作
- [ ] 备份策略制定

---

#### 任务 5.4.2: Web前端部署 ⏱️ 3小时
**优先级**: 🔴 高
**负责人**: 开发者

**部署方案**:

**方案一：Nginx托管**
```bash
# 构建
npm run build

# 上传到服务器
scp -r dist/* user@server:/var/www/bblearning/

# Nginx配置
server {
    listen 80;
    server_name bblearning.com;
    
    root /var/www/bblearning;
    index index.html;
    
    location / {
        try_files $uri $uri/ /index.html;
    }
    
    location /api {
        proxy_pass http://localhost:8080;
    }
}
```

**方案二：Vercel部署**
```bash
npm install -g vercel
vercel --prod
```

**验收标准**:
- [ ] 网站可访问
- [ ] API调用正常
- [ ] 静态资源加载

---

#### 任务 5.4.3: 文档编写 ⏱️ 6小时
**优先级**: 🟡 中
**负责人**: 开发者

**文档清单**:

1. **用户手册**:
- 注册登录指南
- 功能使用说明
- 常见问题FAQ

2. **开发文档**:
- 架构说明
- API文档
- 数据库文档
- 部署文档

3. **运维文档**:
- 部署流程
- 备份恢复
- 故障处理
- 监控告警

**验收标准**:
- [ ] 文档完整
- [ ] 内容准确
- [ ] 易于理解

---

## 附录

### A. 开发环境要求

**硬件要求**:
- CPU: 4核+
- 内存: 16GB+
- 硬盘: 256GB+ SSD

**软件要求**:
- Golang 1.21+
- Node.js 18+
- PostgreSQL 15+
- Redis 7+
- Docker & Docker Compose
- Git

**开发工具**:
- VSCode / GoLand
- Xcode (iOS开发)
- Postman (API测试)
- TablePlus (数据库管理)

### B. 时间估算说明

- ⏱️ 后面的时间为预估开发时间
- 实际时间可能因技能熟练度而异
- 建议每天开发4-6小时
- 每周休息1-2天

### C. 风险管理

**技术风险**:
- AI API调用失败 → 备用服务
- 性能瓶颈 → 提前优化
- 数据丢失 → 定期备份

**时间风险**:
- 功能延期 → MVP优先
- Bug过多 → 增加测试
- 学习曲线 → 降低预期

### D. 里程碑

- 🏁 Week 2: 基础架构完成
- 🏁 Week 6: 核心功能完成
- 🏁 Week 10: AI功能集成
- 🏁 Week 14: iOS App完成
- 🏁 Week 16: 正式上线

### E. 联系与支持

**问题反馈**:
- GitHub Issues
- 邮件联系

**技术支持**:
- 开发文档
- 社区讨论

---

**祝开发顺利！🎉**
