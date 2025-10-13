# BBLearning 性能优化指南

本文档提供BBLearning项目的性能优化建议和最佳实践。

---

## 性能目标

### 响应时间目标

| 指标 | 目标值 | 说明 |
|-----|--------|------|
| 首屏加载 | < 2s | 用户首次访问到可交互 |
| API响应 | < 500ms | 95%的API请求 |
| 页面切换 | < 300ms | 路由切换时间 |
| AI响应 | < 3s | AI对话首次响应 |

### 吞吐量目标

| 端点 | QPS目标 | 说明 |
|-----|---------|------|
| 登录/注册 | 500+ | 高峰期并发 |
| 知识点查询 | 800+ | 高频访问 |
| 题目获取 | 600+ | 练习场景 |
| AI对话 | 50+ | 资源密集型 |

---

## 后端优化

### 1. 数据库优化

#### 索引优化

```sql
-- 用户表索引
CREATE INDEX idx_users_username ON users(username);
CREATE INDEX idx_users_email ON users(email);

-- 知识点表索引
CREATE INDEX idx_knowledge_points_grade ON knowledge_points(grade);
CREATE INDEX idx_knowledge_points_chapter ON knowledge_points(chapter_id);

-- 练习记录索引
CREATE INDEX idx_practice_records_user_id ON practice_records(user_id);
CREATE INDEX idx_practice_records_created_at ON practice_records(created_at DESC);

-- 复合索引
CREATE INDEX idx_learning_records_user_kp ON learning_records(user_id, knowledge_point_id);
```

#### 查询优化

**避免N+1问题**:
```go
// ❌ 不好的做法
chapters := getChapters()
for _, chapter := range chapters {
    chapter.KnowledgePoints = getKnowledgePoints(chapter.ID) // N+1
}

// ✅ 好的做法
chapters := getChaptersWithKnowledgePoints() // 使用JOIN或预加载
```

**使用分页**:
```go
// 限制结果集大小
func GetPracticeRecords(userID int, page, pageSize int) ([]PracticeRecord, error) {
    offset := (page - 1) * pageSize
    return db.Where("user_id = ?", userID).
        Limit(pageSize).
        Offset(offset).
        Order("created_at DESC").
        Find(&records)
}
```

#### 连接池配置

```go
// database/postgres.go
db.SetMaxOpenConns(25)           // 最大打开连接数
db.SetMaxIdleConns(5)            // 最大空闲连接数
db.SetConnMaxLifetime(5 * time.Minute) // 连接最大生命周期
db.SetConnMaxIdleTime(10 * time.Minute) // 空闲连接最大生命周期
```

### 2. 缓存策略

#### Redis缓存层

```go
// 用户信息缓存（30分钟）
func GetUserByID(id int) (*User, error) {
    cacheKey := fmt.Sprintf("user:%d", id)

    // 尝试从缓存获取
    if cached, err := redis.Get(cacheKey); err == nil {
        var user User
        json.Unmarshal([]byte(cached), &user)
        return &user, nil
    }

    // 从数据库获取
    user, err := db.FindUserByID(id)
    if err != nil {
        return nil, err
    }

    // 写入缓存
    data, _ := json.Marshal(user)
    redis.Set(cacheKey, data, 30*time.Minute)

    return user, nil
}

// 知识点树缓存（24小时）
func GetKnowledgeTree(grade int) ([]Chapter, error) {
    cacheKey := fmt.Sprintf("knowledge:tree:grade:%d", grade)

    if cached, err := redis.Get(cacheKey); err == nil {
        var chapters []Chapter
        json.Unmarshal([]byte(cached), &chapters)
        return chapters, nil
    }

    chapters, err := db.GetChaptersWithKnowledgePoints(grade)
    if err != nil {
        return nil, err
    }

    data, _ := json.Marshal(chapters)
    redis.Set(cacheKey, data, 24*time.Hour)

    return chapters, nil
}
```

#### 缓存失效策略

```go
// 用户信息更新时清除缓存
func UpdateUser(userID int, updates map[string]interface{}) error {
    if err := db.UpdateUser(userID, updates); err != nil {
        return err
    }

    // 清除缓存
    redis.Del(fmt.Sprintf("user:%d", userID))
    redis.Del(fmt.Sprintf("user:%d:progress", userID))

    return nil
}
```

### 3. API优化

#### 响应压缩

```go
// 使用Gzip中间件
import "github.com/gin-contrib/gzip"

router.Use(gzip.Gzip(gzip.DefaultCompression))
```

#### 字段选择

```go
// 允许客户端指定需要的字段
type GetUserRequest struct {
    Fields []string `form:"fields"` // ?fields=id,username,grade
}

func GetUser(c *gin.Context) {
    var req GetUserRequest
    c.ShouldBindQuery(&req)

    user := getUserFromDB()

    // 根据fields过滤响应
    response := filterFields(user, req.Fields)
    c.JSON(200, response)
}
```

#### 批量操作

```go
// 批量获取题目
POST /api/v1/questions/batch
{
  "ids": [1, 2, 3, 4, 5]
}

// 一次查询替代多次请求
func GetQuestionsBatch(ids []int) ([]Question, error) {
    return db.Where("id IN ?", ids).Find(&questions)
}
```

### 4. 并发处理

#### 使用Goroutines

```go
// 并发获取用户数据
func GetUserDashboard(userID int) (*Dashboard, error) {
    var (
        user           *User
        progress       []LearningProgress
        wrongQuestions []WrongQuestion
        err error
    )

    var wg sync.WaitGroup
    errChan := make(chan error, 3)

    // 并发获取用户信息
    wg.Add(1)
    go func() {
        defer wg.Done()
        user, err = GetUser(userID)
        if err != nil {
            errChan <- err
        }
    }()

    // 并发获取学习进度
    wg.Add(1)
    go func() {
        defer wg.Done()
        progress, err = GetLearningProgress(userID)
        if err != nil {
            errChan <- err
        }
    }()

    // 并发获取错题
    wg.Add(1)
    go func() {
        defer wg.Done()
        wrongQuestions, err = GetWrongQuestions(userID)
        if err != nil {
            errChan <- err
        }
    }()

    wg.Wait()
    close(errChan)

    // 检查错误
    if err := <-errChan; err != nil {
        return nil, err
    }

    return &Dashboard{
        User:           user,
        Progress:       progress,
        WrongQuestions: wrongQuestions,
    }, nil
}
```

#### 限流

```go
import "golang.org/x/time/rate"

// 全局限流器（100 req/s）
var limiter = rate.NewLimiter(100, 200)

func RateLimitMiddleware() gin.HandlerFunc {
    return func(c *gin.Context) {
        if !limiter.Allow() {
            c.JSON(429, gin.H{"error": "Too many requests"})
            c.Abort()
            return
        }
        c.Next()
    }
}
```

---

## 前端优化

### 1. 代码分割

```typescript
// 使用React.lazy动态导入
import React, { lazy, Suspense } from 'react';

const LearnPage = lazy(() => import('./pages/Learn'));
const PracticePage = lazy(() => import('./pages/Practice'));
const AIChatPage = lazy(() => import('./pages/AIChat'));

function App() {
  return (
    <Suspense fallback={<Loading />}>
      <Routes>
        <Route path="/learn" element={<LearnPage />} />
        <Route path="/practice" element={<PracticePage />} />
        <Route path="/ai-chat" element={<AIChatPage />} />
      </Routes>
    </Suspense>
  );
}
```

### 2. 组件优化

#### React.memo

```typescript
// 避免不必要的重渲染
import React, { memo } from 'react';

const KnowledgeCard = memo(({ knowledgePoint }) => {
  return (
    <Card>
      <h3>{knowledgePoint.name}</h3>
      <p>{knowledgePoint.content}</p>
    </Card>
  );
}, (prevProps, nextProps) => {
  // 仅当knowledge point变化时重渲染
  return prevProps.knowledgePoint.id === nextProps.knowledgePoint.id &&
         prevProps.knowledgePoint.masteryLevel === nextProps.knowledgePoint.masteryLevel;
});
```

#### useMemo和useCallback

```typescript
import { useMemo, useCallback } from 'react';

function LearnPage() {
  const chapters = useAppStore(state => state.chapters);

  // 缓存计算结果
  const sortedChapters = useMemo(() => {
    return [...chapters].sort((a, b) => a.order - b.order);
  }, [chapters]);

  // 缓存回调函数
  const handleStartPractice = useCallback((kp: KnowledgePoint) => {
    navigate('/practice', { state: { knowledgePointId: kp.id } });
  }, [navigate]);

  return (
    <ChapterList
      chapters={sortedChapters}
      onStartPractice={handleStartPractice}
    />
  );
}
```

### 3. 列表优化

#### 虚拟滚动

```typescript
import { FixedSizeList } from 'react-window';

function WrongQuestionList({ questions }) {
  const Row = ({ index, style }) => (
    <div style={style}>
      <QuestionCard question={questions[index]} />
    </div>
  );

  return (
    <FixedSizeList
      height={600}
      itemCount={questions.length}
      itemSize={150}
      width="100%"
    >
      {Row}
    </FixedSizeList>
  );
}
```

### 4. 图片优化

```typescript
// 图片懒加载
import { LazyLoadImage } from 'react-lazy-load-image-component';

function Avatar({ src }) {
  return (
    <LazyLoadImage
      src={src}
      alt="avatar"
      effect="blur"
      placeholderSrc="/placeholder.jpg"
    />
  );
}

// 使用WebP格式
<picture>
  <source srcSet="/images/avatar.webp" type="image/webp" />
  <img src="/images/avatar.jpg" alt="avatar" />
</picture>
```

### 5. 请求优化

#### 请求去抖

```typescript
import { debounce } from 'lodash';

function SearchInput() {
  const debouncedSearch = useMemo(
    () => debounce((query: string) => {
      api.search(query);
    }, 500),
    []
  );

  const handleChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    debouncedSearch(e.target.value);
  };

  return <Input onChange={handleChange} />;
}
```

#### 请求取消

```typescript
import axios from 'axios';

function useKnowledgePoints(grade: number) {
  const [data, setData] = useState([]);

  useEffect(() => {
    const cancelToken = axios.CancelToken.source();

    axios.get(`/knowledge?grade=${grade}`, {
      cancelToken: cancelToken.token
    }).then(res => setData(res.data));

    // 组件卸载时取消请求
    return () => cancelToken.cancel();
  }, [grade]);

  return data;
}
```

#### SWR缓存

```typescript
import useSWR from 'swr';

function useUser() {
  const { data, error, mutate } = useSWR('/users/me', fetcher, {
    revalidateOnFocus: false,
    revalidateOnReconnect: false,
    dedupingInterval: 60000, // 60秒内不重复请求
  });

  return {
    user: data,
    isLoading: !error && !data,
    isError: error,
    mutate,
  };
}
```

---

## 监控和分析

### 1. 性能监控

#### 前端性能监控

```typescript
// 使用Performance API
const performanceObserver = new PerformanceObserver((list) => {
  list.getEntries().forEach((entry) => {
    console.log(`${entry.name}: ${entry.duration}ms`);

    // 上报到监控服务
    analytics.track('performance', {
      name: entry.name,
      duration: entry.duration,
      type: entry.entryType,
    });
  });
});

performanceObserver.observe({ entryTypes: ['navigation', 'resource'] });
```

#### 后端性能监控

```go
// 使用中间件记录请求时间
func PerformanceMiddleware() gin.HandlerFunc {
    return func(c *gin.Context) {
        start := time.Now()

        c.Next()

        duration := time.Since(start)

        // 记录慢请求
        if duration > 500*time.Millisecond {
            log.Warn().
                Str("method", c.Request.Method).
                Str("path", c.Request.URL.Path).
                Dur("duration", duration).
                Msg("Slow request detected")
        }

        // 上报到监控服务
        metrics.RecordAPILatency(c.Request.URL.Path, duration.Milliseconds())
    }
}
```

### 2. 数据库监控

```go
// 监控数据库查询性能
import "gorm.io/plugin/prometheus"

db.Use(prometheus.New(prometheus.Config{
    RefreshInterval: 15,
    MetricsCollector: []prometheus.MetricsCollector{
        &prometheus.MySQL{},
    },
}))

// 慢查询日志
db.Logger = logger.New(
    log.New(os.Stdout, "\r\n", log.LstdFlags),
    logger.Config{
        SlowThreshold: 200 * time.Millisecond,
        LogLevel:      logger.Warn,
    },
)
```

---

## 性能测试工具

### 1. Apache Bench (ab)

```bash
# 基本测试
ab -n 1000 -c 100 http://localhost:8080/api/v1/health

# POST请求测试
ab -n 1000 -c 100 -p data.json -T application/json \
   http://localhost:8080/api/v1/auth/login

# 带认证头
ab -n 1000 -c 100 -H "Authorization: Bearer TOKEN" \
   http://localhost:8080/api/v1/users/me
```

### 2. wrk

```bash
# 基本压测
wrk -t4 -c100 -d30s http://localhost:8080/api/v1/health

# 使用Lua脚本
cat > post.lua << 'EOF'
wrk.method = "POST"
wrk.body = '{"username":"test","password":"pass"}'
wrk.headers["Content-Type"] = "application/json"
EOF

wrk -t4 -c100 -d30s -s post.lua http://localhost:8080/api/v1/auth/login
```

### 3. Lighthouse (前端)

```bash
# 安装
npm install -g lighthouse

# 运行测试
lighthouse http://localhost:3000 --view

# 生成报告
lighthouse http://localhost:3000 \
  --output html \
  --output-path ./lighthouse-report.html
```

---

## 性能清单

### 后端性能清单

- [ ] 数据库索引已优化
- [ ] 使用连接池
- [ ] 实现Redis缓存
- [ ] 避免N+1查询
- [ ] API响应使用Gzip压缩
- [ ] 实现限流机制
- [ ] 长时间操作使用异步处理
- [ ] 实现健康检查端点
- [ ] 配置日志级别（生产环境使用WARN）
- [ ] 监控慢查询

### 前端性能清单

- [ ] 实现代码分割
- [ ] 使用React.memo优化组件
- [ ] 图片懒加载
- [ ] 使用WebP格式图片
- [ ] 实现列表虚拟滚动
- [ ] 请求去抖和节流
- [ ] 使用SWR或React Query缓存
- [ ] 压缩和优化Bundle大小
- [ ] 使用CDN加速静态资源
- [ ] Service Worker缓存

### 数据库性能清单

- [ ] 添加必要索引
- [ ] 定期VACUUM（PostgreSQL）
- [ ] 监控连接数
- [ ] 配置合理的work_mem
- [ ] 使用EXPLAIN ANALYZE分析查询
- [ ] 定期备份和优化
- [ ] 监控慢查询日志
- [ ] 配置适当的shared_buffers

---

## 性能优化案例

### 案例1: 知识点树加载优化

**问题**: 知识点树查询耗时2000ms

**分析**:
- 多次数据库查询（N+1问题）
- 没有使用缓存
- 返回了不必要的字段

**优化方案**:
```go
// 优化前
func GetKnowledgeTree(grade int) ([]Chapter, error) {
    chapters, _ := db.Find(&Chapter{}, "grade = ?", grade)
    for i, chapter := range chapters {
        points, _ := db.Find(&KnowledgePoint{}, "chapter_id = ?", chapter.ID)
        chapters[i].KnowledgePoints = points
    }
    return chapters, nil
}

// 优化后
func GetKnowledgeTree(grade int) ([]Chapter, error) {
    // 检查缓存
    cacheKey := fmt.Sprintf("knowledge:tree:%d", grade)
    if cached, err := redis.Get(cacheKey); err == nil {
        var chapters []Chapter
        json.Unmarshal([]byte(cached), &chapters)
        return chapters, nil
    }

    // 使用预加载
    var chapters []Chapter
    err := db.Preload("KnowledgePoints").
        Where("grade = ?", grade).
        Find(&chapters).Error

    // 写入缓存
    data, _ := json.Marshal(chapters)
    redis.Set(cacheKey, data, 24*time.Hour)

    return chapters, err
}
```

**结果**: 响应时间从2000ms降至50ms (首次) / 10ms (缓存命中)

### 案例2: 首屏加载优化

**问题**: 首屏加载时间5秒

**分析**:
- Bundle过大 (2MB)
- 未使用代码分割
- 同步加载所有资源

**优化方案**:
1. 实现路由级代码分割
2. 使用dynamic import
3. 压缩图片
4. 启用Gzip

**结果**: 首屏加载时间从5s降至1.8s

---

**文档版本**: v1.0
**最后更新**: 2025-10-13
