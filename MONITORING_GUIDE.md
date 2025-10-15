# BBLearning 监控指南

## 概述

BBLearning 使用 **Prometheus + Grafana + Zap** 实现完整的 APM (Application Performance Monitoring) 和日志分析解决方案。

### 技术栈

- **Prometheus**: 时序数据库和指标收集
- **Grafana**: 可视化仪表板
- **Zap**: 结构化日志框架
- **OpenTelemetry** (未来): 分布式追踪 (可选)

## 架构

```
┌─────────────┐
│   Frontend  │
└──────┬──────┘
       │ HTTP Requests
       ↓
┌─────────────────────────────────┐
│      Backend (Gin + Middleware) │
│  ┌──────────────────────────┐  │
│  │ Request ID Middleware    │  │
│  │ Prometheus Middleware    │──┼───→ Prometheus (时序数据)
│  │ Logging Middleware       │──┼───→ Logs (结构化JSON)
│  │ CORS Middleware          │  │
│  └──────────────────────────┘  │
└─────────────────────────────────┘
         │                 │
         ↓                 ↓
┌─────────────┐   ┌─────────────┐
│  PostgreSQL │   │   Redis     │
└─────────────┘   └─────────────┘

Prometheus ←───→ Grafana (可视化)
     │
     ↓
Alertmanager (告警)
```

## 监控指标

### HTTP 指标

| 指标名称 | 类型 | 说明 | 标签 |
|---------|------|------|------|
| `bblearning_http_requests_total` | Counter | HTTP请求总数 | method, endpoint, status |
| `bblearning_http_request_duration_seconds` | Histogram | HTTP请求延迟 | method, endpoint, status |
| `bblearning_http_request_size_bytes` | Histogram | HTTP请求大小 | method, endpoint |
| `bblearning_http_response_size_bytes` | Histogram | HTTP响应大小 | method, endpoint |
| `bblearning_http_active_connections` | Gauge | 活跃连接数 | - |

### AI 服务指标

| 指标名称 | 类型 | 说明 | 标签 |
|---------|------|------|------|
| `bblearning_ai_api_calls_total` | Counter | AI API调用次数 | provider, model, status |
| `bblearning_ai_api_call_duration_seconds` | Histogram | AI API调用延迟 | provider, model, status |

### 数据库指标

| 指标名称 | 类型 | 说明 | 标签 |
|---------|------|------|------|
| `bblearning_db_queries_total` | Counter | 数据库查询次数 | operation, table, status |
| `bblearning_db_query_duration_seconds` | Histogram | 数据库查询延迟 | operation, table |

### Redis 指标

| 指标名称 | 类型 | 说明 | 标签 |
|---------|------|------|------|
| `bblearning_redis_ops_total` | Counter | Redis操作次数 | operation, status |
| `bblearning_redis_ops_duration_seconds` | Histogram | Redis操作延迟 | operation |

### 业务指标

| 指标名称 | 类型 | 说明 | 标签 |
|---------|------|------|------|
| `bblearning_user_logins_total` | Counter | 用户登录次数 | status |
| `bblearning_practice_submissions_total` | Counter | 练习题提交次数 | knowledge_point, difficulty, result |
| `bblearning_wrong_questions_total` | Counter | 错题本添加次数 | knowledge_point, difficulty |

## 快速开始

### 1. 启动监控栈

使用 Docker Compose 启动完整的监控栈：

```bash
# 启动所有服务（包括 Prometheus 和 Grafana）
cd /Users/johnqiu/coding/www/projects/bblearning
docker-compose up -d

# 查看服务状态
docker-compose ps

# 查看 Prometheus 日志
docker-compose logs -f prometheus

# 查看 Grafana 日志
docker-compose logs -f grafana
```

### 2. 访问监控界面

**Prometheus UI**:
- URL: http://localhost:9090
- 功能: 查询指标、查看告警状态

**Grafana 仪表板**:
- URL: http://localhost:3001
- 默认账号: `admin` / `admin`
- 导入仪表板: `monitoring/grafana-dashboard.json`

**应用 Metrics 端点**:
- URL: http://localhost:8080/metrics
- 格式: Prometheus文本格式

### 3. 配置 Grafana 数据源

1. 登录 Grafana: http://localhost:3001
2. 进入 Configuration → Data Sources
3. 添加 Prometheus 数据源:
   - Name: `Prometheus`
   - URL: `http://prometheus:9090`
   - Access: `Server (default)`
4. 点击 "Save & Test"

### 4. 导入仪表板

**方式一: 使用 JSON 文件**
1. 进入 Dashboards → Import
2. 上传 `monitoring/grafana-dashboard.json`
3. 选择 Prometheus 数据源
4. 点击 Import

**方式二: 手动创建面板**
```
示例查询:
- HTTP请求速率: rate(bblearning_http_requests_total[5m])
- P95延迟: histogram_quantile(0.95, rate(bblearning_http_request_duration_seconds_bucket[5m]))
- 错误率: rate(bblearning_http_requests_total{status=~"5.."}[5m])
```

## 日志分析

### 日志格式

所有日志以 **结构化 JSON** 格式输出，便于解析和搜索：

```json
{
  "level": "info",
  "ts": "2025-10-15T16:00:00.000+0800",
  "caller": "middleware/logging.go:45",
  "msg": "HTTP Request",
  "method": "POST",
  "path": "/api/v1/ai/chat/stream",
  "query": "",
  "ip": "127.0.0.1",
  "user_agent": "Mozilla/5.0...",
  "status": 200,
  "latency": "2.5s",
  "response_size": 1024,
  "user_id": 123,
  "request_id": "20251015160000-abc123"
}
```

### 日志级别

| 级别 | 使用场景 | 示例 |
|------|---------|------|
| `DEBUG` | 调试信息 | 变量值、函数调用 |
| `INFO` | 常规信息 | 正常的HTTP请求 |
| `WARN` | 警告信息 | 慢请求、4xx错误 |
| `ERROR` | 错误信息 | 5xx错误、数据库失败 |
| `FATAL` | 致命错误 | 服务无法启动 |

### 日志查询示例

使用 `jq` 查询日志：

```bash
# 查看所有ERROR级别日志
cat /tmp/bblearning.log | jq 'select(.level == "error")'

# 查看特定用户的请求
cat /tmp/bblearning.log | jq 'select(.user_id == 123)'

# 查看慢请求 (>2秒)
cat /tmp/bblearning.log | jq 'select(.latency | tonumber > 2)'

# 统计各状态码数量
cat /tmp/bblearning.log | jq -r '.status' | sort | uniq -c

# 查看特定时间范围的日志
cat /tmp/bblearning.log | jq 'select(.ts > "2025-10-15T16:00:00" and .ts < "2025-10-15T17:00:00")'
```

### 集中式日志管理（可选）

可以集成 **ELK Stack** 或 **Loki**：

**使用 Loki + Promtail**:
```yaml
# docker-compose.yml 中添加
loki:
  image: grafana/loki:latest
  ports:
    - "3100:3100"

promtail:
  image: grafana/promtail:latest
  volumes:
    - /tmp/bblearning.log:/var/log/app.log:ro
    - ./monitoring/promtail.yml:/etc/promtail/config.yml
```

## 告警规则

### 已配置的告警

见 `monitoring/alerts.yml`，包括：

1. **HighErrorRate**: 5xx错误率超过5%
2. **SlowRequests**: P99延迟超过5秒
3. **ServiceDown**: 服务宕机
4. **HighAIAPILatency**: AI API延迟超过30秒
5. **HighAIAPIFailureRate**: AI API失败率超过10%
6. **SlowDatabaseQueries**: 数据库查询P95超过1秒
7. **HighRedisLatency**: Redis延迟超过100ms
8. **HighConcurrency**: 并发连接超过1000
9. **HighLoginFailureRate**: 登录失败率超过30%

### 查看告警状态

Prometheus UI → Alerts: http://localhost:9090/alerts

### 配置告警通知

**使用 Alertmanager**:

```yaml
# monitoring/alertmanager.yml
global:
  resolve_timeout: 5m

route:
  receiver: 'default-receiver'
  group_by: ['alertname', 'severity']
  group_wait: 10s
  group_interval: 10s
  repeat_interval: 12h

receivers:
  - name: 'default-receiver'
    email_configs:
      - to: 'your-email@example.com'
        from: 'alertmanager@bblearning.com'
        smarthost: 'smtp.gmail.com:587'
        auth_username: 'your-email@gmail.com'
        auth_password: 'your-app-password'

  - name: 'slack-receiver'
    slack_configs:
      - api_url: 'https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK'
        channel: '#alerts'
```

## 指标收集最佳实践

### 在业务代码中记录指标

**示例: AI 服务**

```go
// internal/service/ai/ai_service.go
import "github.com/qiudl/bblearning-backend/internal/pkg/metrics"

func (s *AIService) Chat(ctx context.Context, userID uint, req *dto.AIChatRequest) (*dto.AIChatResponse, error) {
    start := time.Now()

    // 调用 AI API
    reply, err := s.callAIAPI(ctx, req.Message)

    // 记录指标
    duration := time.Since(start).Seconds()
    status := "success"
    if err != nil {
        status = "failure"
    }

    metrics.RecordAIAPICall("openai", s.model, status, duration)

    return &dto.AIChatResponse{Reply: reply}, err
}
```

**示例: 用户登录**

```go
// internal/service/user/auth_service.go
import "github.com/qiudl/bblearning-backend/internal/pkg/metrics"

func (s *AuthService) Login(ctx context.Context, req *dto.LoginRequest) (*dto.LoginResponse, error) {
    user, err := s.userRepo.FindByUsername(ctx, req.Username)

    if err != nil || !user.VerifyPassword(req.Password) {
        metrics.RecordUserLogin("failure")
        return nil, errors.New("invalid credentials")
    }

    metrics.RecordUserLogin("success")
    return &dto.LoginResponse{Token: token}, nil
}
```

### 日志记录最佳实践

**DO ✅**:
```go
// 使用结构化字段
logger.Info("User logged in",
    zap.Uint("user_id", userID),
    zap.String("username", username),
    zap.String("ip", clientIP),
)

// 记录关键业务事件
logger.Info("Practice submitted",
    zap.Uint("user_id", userID),
    zap.String("knowledge_point", kpName),
    zap.Bool("is_correct", isCorrect),
    zap.Float64("score", score),
)
```

**DON'T ❌**:
```go
// 避免日志注入
logger.Info(fmt.Sprintf("User %s logged in", userInput)) // ❌

// 避免记录敏感信息
logger.Info("Password attempt", zap.String("password", req.Password)) // ❌

// 避免过度日志
for _, item := range items {
    logger.Debug("Processing item", zap.Any("item", item)) // ❌ 在循环中打印大量日志
}
```

## 性能优化

### 指标采样

对于高频操作，考虑采样：

```go
// 仅记录 1% 的请求
if rand.Float64() < 0.01 {
    metrics.RecordDetailedMetrics(...)
}
```

### 异步日志写入

Zap 默认使用缓冲IO，但可以进一步优化：

```go
// 使用异步日志写入
zapcore.NewCore(
    encoder,
    zapcore.AddSync(&lumberjack.Logger{
        Filename:   "/var/log/bblearning.log",
        MaxSize:    100, // MB
        MaxBackups: 3,
        MaxAge:     28, // days
        Compress:   true,
    }),
    level,
)
```

## 故障排查

### 问题 1: Prometheus 无法抓取指标

**症状**: Prometheus UI 显示 target 为 DOWN

**解决**:
```bash
# 1. 检查后端 /metrics 端点
curl http://localhost:8080/metrics

# 2. 检查网络连通性
docker-compose exec prometheus wget -O- http://backend:8080/metrics

# 3. 查看 Prometheus 日志
docker-compose logs prometheus
```

### 问题 2: Grafana 无数据

**症状**: 仪表板显示 "No data"

**解决**:
1. 检查 Prometheus 数据源配置
2. 在 Grafana Explore 手动查询: `up{job="bblearning-backend"}`
3. 检查时间范围是否正确

### 问题 3: 日志文件过大

**症状**: `/tmp/bblearning.log` 占用大量磁盘空间

**解决**:
```bash
# 使用 logrotate 或 lumberjack
# backend/internal/pkg/logger/logger.go
import "gopkg.in/natefinch/lumberjack.v2"

log := &lumberjack.Logger{
    Filename:   "/var/log/bblearning/app.log",
    MaxSize:    100, // MB
    MaxBackups: 5,
    MaxAge:     30, // days
    Compress:   true,
}
```

## 监控清单

### 日常检查

- [ ] 错误率 < 1%
- [ ] P95 延迟 < 500ms
- [ ] AI API 成功率 > 95%
- [ ] 数据库查询延迟 < 100ms
- [ ] 无活跃告警
- [ ] 日志无ERROR级别异常

### 每周检查

- [ ] 审查慢查询日志
- [ ] 分析错误趋势
- [ ] 检查磁盘空间
- [ ] 验证备份状态
- [ ] 更新告警阈值

### 每月检查

- [ ] 性能趋势分析
- [ ] 容量规划评估
- [ ] SLA 报告生成
- [ ] 安全日志审计

## 相关资源

- **Prometheus 文档**: https://prometheus.io/docs/
- **Grafana 文档**: https://grafana.com/docs/
- **Zap 日志库**: https://github.com/uber-go/zap
- **Gin 框架**: https://gin-gonic.com/docs/

## 联系方式

- 技术支持: 查看 README.md
- 问题反馈: GitHub Issues

---

**文档版本**: v1.0
**最后更新**: 2025-10-15
**维护者**: Claude Code
