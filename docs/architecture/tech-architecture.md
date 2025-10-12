# 初中数学AI学习APP - 技术架构设计

## 1. 架构概览

### 1.1 整体架构图

```
┌─────────────────────────────────────────────────────────────┐
│                        客户端层                              │
├──────────────────────┬──────────────────────────────────────┤
│   Web App (React)    │    iOS App (React Native)           │
│   - 响应式设计        │    - iPhone优化                      │
│   - PWA支持          │    - 离线功能                        │
└──────────────────────┴──────────────────────────────────────┘
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                      API网关层                               │
│   - 路由分发  - 认证鉴权  - 限流熔断  - 日志追踪            │
└─────────────────────────────────────────────────────────────┘
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                     后端服务层 (Golang)                      │
├──────────────────────┬──────────────────────────────────────┤
│   业务服务模块        │         AI服务模块                   │
│   - 用户服务          │   - 题目生成服务                     │
│   - 知识点服务        │   - 智能批改服务                     │
│   - 学习记录服务      │   - 学习诊断服务                     │
│   - 练习服务          │   - 推荐算法服务                     │
└──────────────────────┴──────────────────────────────────────┘
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                      数据持久层                              │
├──────────────┬──────────────┬──────────────┬───────────────┤
│  PostgreSQL  │    Redis     │   MinIO/S3   │   Elasticsearch│
│  (主数据库)  │   (缓存)     │  (文件存储)  │   (搜索引擎)  │
└──────────────┴──────────────┴──────────────┴───────────────┘
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                    外部服务集成                              │
│   - 大语言模型API (OpenAI/Claude)                           │
│   - 数学符号渲染 (MathJax/KaTeX)                            │
│   - 图表绘制 (D3.js/ECharts)                                │
└─────────────────────────────────────────────────────────────┘
```

## 2. 前端技术栈

### 2.1 Web端 (React)

#### 核心技术
- **框架**: React 18+ (使用函数组件 + Hooks)
- **状态管理**: Zustand / Redux Toolkit
- **路由**: React Router v6
- **UI框架**: Ant Design / Material-UI
- **样式方案**: Tailwind CSS + CSS Modules
- **构建工具**: Vite

#### 功能模块
```typescript
src/
├── components/          # 通用组件
│   ├── Layout/         # 布局组件
│   ├── MathInput/      # 数学公式输入组件
│   ├── MathRenderer/   # 数学公式渲染组件
│   └── Charts/         # 图表组件
├── pages/              # 页面组件
│   ├── Dashboard/      # 仪表盘
│   ├── Knowledge/      # 知识点学习
│   ├── Practice/       # 练习模块
│   ├── Review/         # 错题本
│   └── Profile/        # 个人中心
├── hooks/              # 自定义Hooks
├── services/           # API服务
├── store/              # 状态管理
├── utils/              # 工具函数
└── types/              # TypeScript类型定义
```

#### 关键技术点
- **数学公式渲染**: KaTeX (性能优于MathJax)
- **手写识别**: 集成第三方手写识别SDK或自建模型
- **图形绘制**: Canvas API + Fabric.js
- **响应式设计**: 移动优先，适配平板和桌面
- **PWA**: Service Worker实现离线缓存

### 2.2 iOS端 (React Native)

#### 核心技术
- **框架**: React Native 0.73+
- **导航**: React Navigation 6
- **状态管理**: Zustand (与Web端共享)
- **UI组件**: React Native Paper / NativeBase
- **样式**: StyleSheet + Styled Components
- **构建**: Expo (开发阶段) / 原生构建 (生产)

#### iOS特性
```typescript
ios-app/
├── src/
│   ├── components/     # 组件（与Web端最大化复用）
│   ├── screens/        # 屏幕页面
│   ├── navigation/     # 导航配置
│   ├── hooks/          # 自定义Hooks
│   └── native/         # 原生模块桥接
│       ├── HandwritingRecognition/  # 手写识别
│       └── LocalStorage/            # 本地存储
├── ios/                # iOS原生代码
└── package.json
```

#### 关键功能
- **离线支持**: 
  - 使用 AsyncStorage 缓存题目和学习数据
  - 离线做题，联网后同步
- **手写输入**: 
  - 使用 Apple Pencil API（如果支持）
  - react-native-sketch-canvas 用于绘图
- **推送通知**: 
  - 学习提醒
  - 每日推荐
- **数据同步**: 
  - 增量同步机制
  - 冲突解决策略

#### 非App Store发布方案
- **TestFlight**: 用于测试分发（最多90天）
- **Ad Hoc分发**: 通过UDID注册设备
- **Enterprise证书**: 如果有企业开发者账号
- **开发者证书**: 直接安装到已信任的设备

## 3. 后端技术栈 (Golang)

### 3.1 框架选择

```go
// 核心框架
- Web框架: Gin / Echo
- ORM: GORM
- 配置管理: Viper
- 日志: Zap
- 参数验证: validator
- 定时任务: cron
```

### 3.2 项目结构

```
backend/
├── cmd/
│   └── server/
│       └── main.go              # 入口文件
├── internal/
│   ├── api/                     # API处理层
│   │   ├── handlers/           # HTTP处理器
│   │   ├── middleware/         # 中间件
│   │   └── routes/             # 路由配置
│   ├── service/                # 业务逻辑层
│   │   ├── user/              # 用户服务
│   │   ├── knowledge/         # 知识点服务
│   │   ├── practice/          # 练习服务
│   │   ├── ai/                # AI服务
│   │   └── analytics/         # 数据分析服务
│   ├── repository/            # 数据访问层
│   │   ├── postgres/         # PostgreSQL仓库
│   │   ├── redis/            # Redis仓库
│   │   └── minio/            # 文件存储仓库
│   ├── domain/                # 领域模型
│   │   ├── models/           # 数据模型
│   │   ├── dto/              # 数据传输对象
│   │   └── enum/             # 枚举类型
│   └── pkg/                   # 内部工具包
│       ├── auth/             # 认证工具
│       ├── cache/            # 缓存工具
│       ├── logger/           # 日志工具
│       └── validator/        # 验证工具
├── pkg/                       # 可导出的公共包
├── config/                    # 配置文件
├── migrations/                # 数据库迁移
├── scripts/                   # 脚本文件
├── test/                      # 测试文件
├── docs/                      # API文档
├── go.mod
└── go.sum
```

### 3.3 核心模块设计

#### 3.3.1 用户认证模块

```go
// JWT Token认证
type AuthService interface {
    Register(ctx context.Context, req *RegisterRequest) (*User, error)
    Login(ctx context.Context, req *LoginRequest) (*TokenPair, error)
    RefreshToken(ctx context.Context, refreshToken string) (*TokenPair, error)
    Logout(ctx context.Context, userID string) error
}

// Token结构
type TokenPair struct {
    AccessToken  string `json:"access_token"`
    RefreshToken string `json:"refresh_token"`
    ExpiresIn    int64  `json:"expires_in"`
}
```

#### 3.3.2 知识点服务

```go
type KnowledgeService interface {
    // 获取知识点树
    GetKnowledgeTree(ctx context.Context, grade int) ([]*KnowledgeNode, error)
    
    // 获取知识点详情
    GetKnowledgeDetail(ctx context.Context, knowledgeID string) (*KnowledgeDetail, error)
    
    // 获取知识点学习进度
    GetLearningProgress(ctx context.Context, userID, knowledgeID string) (*LearningProgress, error)
    
    // 更新学习进度
    UpdateLearningProgress(ctx context.Context, req *UpdateProgressRequest) error
}
```

#### 3.3.3 练习生成服务

```go
type PracticeService interface {
    // 生成练习题
    GeneratePractice(ctx context.Context, req *GeneratePracticeRequest) ([]*Question, error)
    
    // 提交答案
    SubmitAnswer(ctx context.Context, req *SubmitAnswerRequest) (*AnswerResult, error)
    
    // 获取练习历史
    GetPracticeHistory(ctx context.Context, userID string, page, size int) ([]*PracticeRecord, error)
    
    // 获取错题集
    GetWrongQuestions(ctx context.Context, userID string, filters *QuestionFilters) ([]*Question, error)
}
```

#### 3.3.4 AI服务集成

```go
type AIService interface {
    // AI题目生成
    GenerateQuestion(ctx context.Context, req *AIQuestionRequest) (*Question, error)
    
    // AI批改
    GradeAnswer(ctx context.Context, req *GradeRequest) (*GradeResult, error)
    
    // AI诊断分析
    DiagnoseWeakness(ctx context.Context, userID string) (*DiagnosisReport, error)
    
    // AI推荐学习路径
    RecommendLearningPath(ctx context.Context, userID string) (*LearningPath, error)
}

// AI服务实现（使用OpenAI或Claude）
type OpenAIService struct {
    client *openai.Client
    cache  cache.Cache
}
```

### 3.4 数据库设计

#### 核心表结构

```sql
-- 用户表
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(100) UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    grade INT NOT NULL,
    avatar_url VARCHAR(500),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 知识点表
CREATE TABLE knowledge_points (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code VARCHAR(50) UNIQUE NOT NULL,
    name VARCHAR(100) NOT NULL,
    grade INT NOT NULL,
    parent_id UUID REFERENCES knowledge_points(id),
    description TEXT,
    order_index INT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 题目表
CREATE TABLE questions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    knowledge_point_id UUID REFERENCES knowledge_points(id),
    type VARCHAR(20) NOT NULL, -- 选择题/填空题/解答题
    difficulty INT NOT NULL, -- 1-5难度等级
    content JSONB NOT NULL, -- 题目内容（支持数学公式、图片）
    answer JSONB NOT NULL, -- 标准答案
    solution JSONB, -- 解题过程
    source VARCHAR(100), -- 题目来源
    tags JSONB, -- 标签
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 学习记录表
CREATE TABLE learning_records (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id),
    knowledge_point_id UUID REFERENCES knowledge_points(id),
    status VARCHAR(20) NOT NULL, -- 未学习/学习中/已掌握
    mastery_level DECIMAL(3,2), -- 掌握程度 0-1
    last_learned_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 练习记录表
CREATE TABLE practice_records (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id),
    question_id UUID REFERENCES questions(id),
    user_answer JSONB, -- 用户答案
    is_correct BOOLEAN,
    score DECIMAL(5,2), -- 得分
    time_spent INT, -- 用时（秒）
    ai_feedback JSONB, -- AI反馈
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 错题本表
CREATE TABLE wrong_questions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id),
    question_id UUID REFERENCES questions(id),
    wrong_count INT DEFAULT 1,
    last_wrong_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    is_resolved BOOLEAN DEFAULT FALSE,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 学习统计表
CREATE TABLE learning_statistics (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id),
    date DATE NOT NULL,
    study_time INT DEFAULT 0, -- 学习时长（分钟）
    questions_completed INT DEFAULT 0, -- 完成题目数
    correct_rate DECIMAL(5,2), -- 正确率
    knowledge_points_learned INT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, date)
);
```

### 3.5 Redis缓存策略

```go
// 缓存键设计
const (
    UserCacheKey              = "user:%s"                    // 用户信息
    KnowledgeTreeCacheKey     = "knowledge:tree:grade:%d"    // 知识点树
    QuestionCacheKey          = "question:%s"                // 题目详情
    UserProgressCacheKey      = "user:%s:progress"           // 用户进度
    DailyStatsCacheKey        = "user:%s:stats:daily:%s"     // 每日统计
)

// 缓存过期时间
const (
    UserCacheTTL         = 30 * time.Minute
    KnowledgeTreeTTL     = 24 * time.Hour
    QuestionCacheTTL     = 1 * time.Hour
    UserProgressTTL      = 10 * time.Minute
    DailyStatsTTL        = 24 * time.Hour
)
```

## 4. AI功能实现

### 4.1 AI题目生成

```go
// Prompt模板
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
- question: 题目内容
- answer: 标准答案
- solution: 详细解题步骤
- difficulty_analysis: 难点分析
- knowledge_points: 涉及的知识点列表
`

// AI服务实现
func (s *AIService) GenerateQuestion(ctx context.Context, req *AIQuestionRequest) (*Question, error) {
    // 构建prompt
    prompt := s.buildPrompt(QuestionGeneratePrompt, req)
    
    // 调用AI API
    response, err := s.client.CreateChatCompletion(ctx, openai.ChatCompletionRequest{
        Model: openai.GPT4,
        Messages: []openai.ChatCompletionMessage{
            {
                Role:    openai.ChatMessageRoleSystem,
                Content: "你是一位专业的数学教师AI助手",
            },
            {
                Role:    openai.ChatMessageRoleUser,
                Content: prompt,
            },
        },
        Temperature: 0.7,
    })
    
    if err != nil {
        return nil, err
    }
    
    // 解析结果
    question, err := s.parseQuestionResponse(response.Choices[0].Message.Content)
    if err != nil {
        return nil, err
    }
    
    // 保存到数据库
    return s.repository.SaveQuestion(ctx, question)
}
```

### 4.2 AI智能批改

```go
const GradingPrompt = `
请批改以下数学题的答案：

题目：{{.Question}}
标准答案：{{.StandardAnswer}}
学生答案：{{.UserAnswer}}

请分析：
1. 答案是否正确
2. 解题思路是否正确
3. 具体错在哪里
4. 给出改进建议
5. 给出分数（0-100）

以JSON格式返回结果。
`

func (s *AIService) GradeAnswer(ctx context.Context, req *GradeRequest) (*GradeResult, error) {
    // 构建prompt
    prompt := s.buildPrompt(GradingPrompt, req)
    
    // 调用AI进行批改
    response, err := s.callAI(ctx, prompt)
    if err != nil {
        return nil, err
    }
    
    // 解析批改结果
    result := &GradeResult{}
    if err := json.Unmarshal([]byte(response), result); err != nil {
        return nil, err
    }
    
    // 记录批改历史
    s.repository.SaveGradeRecord(ctx, req.UserID, req.QuestionID, result)
    
    return result, nil
}
```

### 4.3 AI学习诊断

```go
func (s *AIService) DiagnoseWeakness(ctx context.Context, userID string) (*DiagnosisReport, error) {
    // 1. 获取用户最近的练习记录
    records, err := s.repository.GetRecentPracticeRecords(ctx, userID, 100)
    if err != nil {
        return nil, err
    }
    
    // 2. 统计分析
    stats := s.analyzeRecords(records)
    
    // 3. 构建诊断prompt
    prompt := fmt.Sprintf(`
根据以下学习数据，分析学生的薄弱环节：

总题目数：%d
正确率：%.2f%%
各知识点掌握情况：%v
常见错误类型：%v

请给出：
1. 主要薄弱知识点
2. 错误原因分析
3. 学习建议
4. 推荐练习重点
`, stats.TotalQuestions, stats.CorrectRate*100, stats.KnowledgeStats, stats.ErrorTypes)
    
    // 4. 调用AI进行诊断
    diagnosis, err := s.callAI(ctx, prompt)
    if err != nil {
        return nil, err
    }
    
    // 5. 解析并返回诊断报告
    report := &DiagnosisReport{
        UserID:      userID,
        GeneratedAt: time.Now(),
        Content:     diagnosis,
        Statistics:  stats,
    }
    
    return report, nil
}
```

## 5. 部署架构

### 5.1 开发环境

```yaml
# docker-compose.yml
version: '3.8'

services:
  postgres:
    image: postgres:15
    environment:
      POSTGRES_DB: bblearning
      POSTGRES_USER: admin
      POSTGRES_PASSWORD: password
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data

  redis:
    image: redis:7
    ports:
      - "6379:6379"
    volumes:
      - redis_data:/data

  minio:
    image: minio/minio
    command: server /data --console-address ":9001"
    ports:
      - "9000:9000"
      - "9001:9001"
    environment:
      MINIO_ROOT_USER: admin
      MINIO_ROOT_PASSWORD: password
    volumes:
      - minio_data:/data

  backend:
    build: ./backend
    ports:
      - "8080:8080"
    environment:
      DB_HOST: postgres
      REDIS_HOST: redis
      MINIO_ENDPOINT: minio:9000
    depends_on:
      - postgres
      - redis
      - minio

  web:
    build: ./web
    ports:
      - "3000:3000"
    environment:
      REACT_APP_API_URL: http://localhost:8080
    depends_on:
      - backend

volumes:
  postgres_data:
  redis_data:
  minio_data:
```

### 5.2 生产环境（云服务器部署）

```
┌─────────────────────────────────────────────────────────┐
│                    Nginx (反向代理)                      │
│   - SSL终止  - 负载均衡  - 静态文件服务                 │
└─────────────────────────────────────────────────────────┘
                          ▼
        ┌─────────────────┴─────────────────┐
        ▼                                    ▼
┌──────────────────┐              ┌──────────────────┐
│   Web服务         │              │  API服务 (多实例) │
│   (React Build)   │              │  (Golang)        │
└──────────────────┘              └──────────────────┘
                                            ▼
                          ┌─────────────────────────────┐
                          │  数据库服务                  │
                          │  - PostgreSQL (主从)         │
                          │  - Redis Cluster            │
                          │  - MinIO                    │
                          └─────────────────────────────┘
```

### 5.3 配置管理

```go
// config/config.go
type Config struct {
    Server   ServerConfig
    Database DatabaseConfig
    Redis    RedisConfig
    Minio    MinioConfig
    AI       AIConfig
}

type ServerConfig struct {
    Port         int
    Mode         string // debug, release
    ReadTimeout  time.Duration
    WriteTimeout time.Duration
}

type AIConfig struct {
    Provider     string // openai, claude
    APIKey       string
    Model        string
    MaxTokens    int
    Temperature  float64
}
```

## 6. 安全设计

### 6.1 认证授权
- JWT Token认证
- Refresh Token机制
- RBAC权限控制（虽然是个人使用，但保留扩展性）

### 6.2 数据安全
- 密码使用bcrypt加密
- 敏感数据加密存储
- HTTPS传输
- SQL注入防护（参数化查询）
- XSS防护

### 6.3 API安全
- 限流（Rate Limiting）
- 请求签名验证
- CORS配置
- API版本控制

## 7. 监控与日志

### 7.1 日志系统
```go
// 使用Zap结构化日志
logger.Info("User login",
    zap.String("user_id", userID),
    zap.String("ip", clientIP),
    zap.Time("timestamp", time.Now()),
)
```

### 7.2 性能监控
- 接口响应时间监控
- 数据库查询性能监控
- 缓存命中率监控
- 错误率监控

### 7.3 告警
- 服务异常告警
- 数据库连接异常告警
- AI服务调用失败告警

## 8. 开发规范

### 8.1 Git工作流
```
main (生产环境)
  └── develop (开发环境)
       ├── feature/xxx (功能分支)
       ├── bugfix/xxx (bug修复)
       └── hotfix/xxx (紧急修复)
```

### 8.2 代码规范
- **Golang**: 遵循官方Go Code Review Comments
- **React**: 使用ESLint + Prettier
- **提交规范**: Conventional Commits

### 8.3 测试策略
- 单元测试覆盖率 > 80%
- 集成测试覆盖核心业务流程
- E2E测试覆盖关键用户路径

## 9. 性能优化

### 9.1 前端优化
- 代码分割（Code Splitting）
- 懒加载（Lazy Loading）
- 图片优化（WebP格式）
- 缓存策略（Service Worker）

### 9.2 后端优化
- 数据库连接池
- Redis缓存热点数据
- 批量操作优化
- 分页查询
- 异步处理耗时任务

### 9.3 数据库优化
- 合理创建索引
- 查询优化
- 读写分离（如需要）

## 10. 开发路线图

### Phase 1: 基础架构搭建（2周）
- [ ] 项目初始化
- [ ] 数据库设计与创建
- [ ] 后端基础框架搭建
- [ ] 前端基础框架搭建
- [ ] Docker开发环境配置

### Phase 2: 核心功能开发（4-6周）
- [ ] 用户认证系统
- [ ] 知识点管理
- [ ] 题目生成与管理
- [ ] 练习功能
- [ ] 学习记录与统计

### Phase 3: AI功能集成（3-4周）
- [ ] AI题目生成
- [ ] AI批改
- [ ] AI学习诊断
- [ ] 个性化推荐

### Phase 4: iOS App开发（4-6周）
- [ ] React Native环境搭建
- [ ] 核心页面开发
- [ ] 离线功能实现
- [ ] 数据同步机制
- [ ] TestFlight测试

### Phase 5: 优化与上线（2-3周）
- [ ] 性能优化
- [ ] Bug修复
- [ ] 用户测试
- [ ] 部署上线

---

## 附录

### A. 技术选型理由

#### 为什么选择Golang？
1. **高性能**: 并发处理能力强
2. **简洁**: 语法简单，易于维护
3. **部署方便**: 单一二进制文件
4. **生态丰富**: 有大量优秀的库和框架

#### 为什么选择React？
1. **组件化**: 代码复用性强
2. **生态成熟**: 丰富的第三方库
3. **跨平台**: Web和移动端共享代码
4. **社区活跃**: 问题解决快

#### 为什么选择React Native？
1. **代码复用**: 与Web端共享大部分代码
2. **性能好**: 接近原生体验
3. **开发效率高**: 热更新，快速迭代
4. **社区支持**: 成熟的生态系统

### B. 成本估算

#### 开发成本
- 个人开发，主要是时间投入
- 预计3-4个月开发周期

#### 运营成本（月）
- 云服务器: ¥100-300
- 数据库: ¥50-150
- AI API调用: ¥100-500（取决于使用量）
- 对象存储: ¥10-50
- 总计: ¥260-1000/月

### C. 风险评估

1. **技术风险**: AI服务稳定性依赖第三方
2. **成本风险**: AI调用费用可能超预算
3. **时间风险**: 首次全栈开发可能延期

### D. 备选方案

1. **AI服务**: 可以同时接入多个AI服务作为备份
2. **部署**: 初期可使用免费层云服务（如Vercel、Railway）
3. **数据库**: 可考虑使用SQLite降低成本
