package metrics

import (
	"sync"
	"time"
)

// Metrics 监控指标收集器
type Metrics struct {
	mu sync.RWMutex

	// HTTP请求指标
	HTTPRequestTotal   map[string]int64 // method:path -> count
	HTTPRequestErrors  map[string]int64 // method:path -> error_count
	HTTPResponseTime   map[string]int64 // method:path -> avg_ms

	// 数据库指标
	DBQueryTotal       int64
	DBQueryErrors      int64
	DBSlowQueries      int64
	DBAvgResponseTime  int64

	// AI服务指标
	AIRequestTotal     int64
	AIRequestErrors    int64
	AITokensUsed       int64
	AIAvgResponseTime  int64

	// 缓存指标
	CacheHits          int64
	CacheMisses        int64
	CacheErrors        int64

	// 业务指标
	UserRegistrations  int64
	UserLogins         int64
	QuestionsGenerated int64
	AnswersGraded      int64
	DiagnosesGenerated int64
}

var (
	globalMetrics *Metrics
	once          sync.Once
)

// GetMetrics 获取全局指标实例
func GetMetrics() *Metrics {
	once.Do(func() {
		globalMetrics = &Metrics{
			HTTPRequestTotal:  make(map[string]int64),
			HTTPRequestErrors: make(map[string]int64),
			HTTPResponseTime:  make(map[string]int64),
		}
	})
	return globalMetrics
}

// RecordHTTPRequest 记录HTTP请求
func (m *Metrics) RecordHTTPRequest(method, path string, statusCode int, duration time.Duration) {
	m.mu.Lock()
	defer m.mu.Unlock()

	key := method + ":" + path
	m.HTTPRequestTotal[key]++

	if statusCode >= 400 {
		m.HTTPRequestErrors[key]++
	}

	// 简单移动平均
	currentAvg := m.HTTPResponseTime[key]
	totalRequests := m.HTTPRequestTotal[key]
	m.HTTPResponseTime[key] = (currentAvg*(totalRequests-1) + duration.Milliseconds()) / totalRequests
}

// RecordDBQuery 记录数据库查询
func (m *Metrics) RecordDBQuery(duration time.Duration, isError bool, isSlow bool) {
	m.mu.Lock()
	defer m.mu.Unlock()

	m.DBQueryTotal++

	if isError {
		m.DBQueryErrors++
	}

	if isSlow {
		m.DBSlowQueries++
	}

	// 移动平均
	m.DBAvgResponseTime = (m.DBAvgResponseTime*(m.DBQueryTotal-1) + duration.Milliseconds()) / m.DBQueryTotal
}

// RecordAIRequest 记录AI服务请求
func (m *Metrics) RecordAIRequest(duration time.Duration, tokensUsed int, isError bool) {
	m.mu.Lock()
	defer m.mu.Unlock()

	m.AIRequestTotal++
	m.AITokensUsed += int64(tokensUsed)

	if isError {
		m.AIRequestErrors++
	}

	// 移动平均
	m.AIAvgResponseTime = (m.AIAvgResponseTime*(m.AIRequestTotal-1) + duration.Milliseconds()) / m.AIRequestTotal
}

// RecordCacheOperation 记录缓存操作
func (m *Metrics) RecordCacheOperation(hit bool, isError bool) {
	m.mu.Lock()
	defer m.mu.Unlock()

	if isError {
		m.CacheErrors++
		return
	}

	if hit {
		m.CacheHits++
	} else {
		m.CacheMisses++
	}
}

// RecordUserRegistration 记录用户注册
func (m *Metrics) RecordUserRegistration() {
	m.mu.Lock()
	defer m.mu.Unlock()
	m.UserRegistrations++
}

// RecordUserLogin 记录用户登录
func (m *Metrics) RecordUserLogin() {
	m.mu.Lock()
	defer m.mu.Unlock()
	m.UserLogins++
}

// RecordQuestionGeneration 记录题目生成
func (m *Metrics) RecordQuestionGeneration() {
	m.mu.Lock()
	defer m.mu.Unlock()
	m.QuestionsGenerated++
}

// RecordAnswerGrading 记录答案批改
func (m *Metrics) RecordAnswerGrading() {
	m.mu.Lock()
	defer m.mu.Unlock()
	m.AnswersGraded++
}

// RecordDiagnosis 记录诊断生成
func (m *Metrics) RecordDiagnosis() {
	m.mu.Lock()
	defer m.mu.Unlock()
	m.DiagnosesGenerated++
}

// GetHTTPMetrics 获取HTTP指标
func (m *Metrics) GetHTTPMetrics() map[string]HTTPMetric {
	m.mu.RLock()
	defer m.mu.RUnlock()

	result := make(map[string]HTTPMetric)
	for key, total := range m.HTTPRequestTotal {
		result[key] = HTTPMetric{
			Total:       total,
			Errors:      m.HTTPRequestErrors[key],
			AvgDuration: m.HTTPResponseTime[key],
		}
	}
	return result
}

// HTTPMetric HTTP指标
type HTTPMetric struct {
	Total       int64 `json:"total"`
	Errors      int64 `json:"errors"`
	AvgDuration int64 `json:"avg_duration_ms"`
}

// GetDBMetrics 获取数据库指标
func (m *Metrics) GetDBMetrics() DBMetric {
	m.mu.RLock()
	defer m.mu.RUnlock()

	return DBMetric{
		Total:          m.DBQueryTotal,
		Errors:         m.DBQueryErrors,
		SlowQueries:    m.DBSlowQueries,
		AvgResponseTime: m.DBAvgResponseTime,
	}
}

// DBMetric 数据库指标
type DBMetric struct {
	Total          int64 `json:"total"`
	Errors         int64 `json:"errors"`
	SlowQueries    int64 `json:"slow_queries"`
	AvgResponseTime int64 `json:"avg_response_time_ms"`
}

// GetAIMetrics 获取AI服务指标
func (m *Metrics) GetAIMetrics() AIMetric {
	m.mu.RLock()
	defer m.mu.RUnlock()

	return AIMetric{
		Total:          m.AIRequestTotal,
		Errors:         m.AIRequestErrors,
		TokensUsed:     m.AITokensUsed,
		AvgResponseTime: m.AIAvgResponseTime,
	}
}

// AIMetric AI服务指标
type AIMetric struct {
	Total          int64 `json:"total"`
	Errors         int64 `json:"errors"`
	TokensUsed     int64 `json:"tokens_used"`
	AvgResponseTime int64 `json:"avg_response_time_ms"`
}

// GetCacheMetrics 获取缓存指标
func (m *Metrics) GetCacheMetrics() CacheMetric {
	m.mu.RLock()
	defer m.mu.RUnlock()

	total := m.CacheHits + m.CacheMisses
	hitRate := float64(0)
	if total > 0 {
		hitRate = float64(m.CacheHits) / float64(total) * 100
	}

	return CacheMetric{
		Hits:    m.CacheHits,
		Misses:  m.CacheMisses,
		Errors:  m.CacheErrors,
		HitRate: hitRate,
	}
}

// CacheMetric 缓存指标
type CacheMetric struct {
	Hits    int64   `json:"hits"`
	Misses  int64   `json:"misses"`
	Errors  int64   `json:"errors"`
	HitRate float64 `json:"hit_rate_percent"`
}

// GetBusinessMetrics 获取业务指标
func (m *Metrics) GetBusinessMetrics() BusinessMetric {
	m.mu.RLock()
	defer m.mu.RUnlock()

	return BusinessMetric{
		UserRegistrations:  m.UserRegistrations,
		UserLogins:         m.UserLogins,
		QuestionsGenerated: m.QuestionsGenerated,
		AnswersGraded:      m.AnswersGraded,
		DiagnosesGenerated: m.DiagnosesGenerated,
	}
}

// BusinessMetric 业务指标
type BusinessMetric struct {
	UserRegistrations  int64 `json:"user_registrations"`
	UserLogins         int64 `json:"user_logins"`
	QuestionsGenerated int64 `json:"questions_generated"`
	AnswersGraded      int64 `json:"answers_graded"`
	DiagnosesGenerated int64 `json:"diagnoses_generated"`
}

// GetAllMetrics 获取所有指标
func (m *Metrics) GetAllMetrics() AllMetrics {
	return AllMetrics{
		HTTP:     m.GetHTTPMetrics(),
		DB:       m.GetDBMetrics(),
		AI:       m.GetAIMetrics(),
		Cache:    m.GetCacheMetrics(),
		Business: m.GetBusinessMetrics(),
	}
}

// AllMetrics 所有指标
type AllMetrics struct {
	HTTP     map[string]HTTPMetric `json:"http"`
	DB       DBMetric              `json:"database"`
	AI       AIMetric              `json:"ai"`
	Cache    CacheMetric           `json:"cache"`
	Business BusinessMetric        `json:"business"`
}

// Reset 重置所有指标（用于测试或定期清理）
func (m *Metrics) Reset() {
	m.mu.Lock()
	defer m.mu.Unlock()

	m.HTTPRequestTotal = make(map[string]int64)
	m.HTTPRequestErrors = make(map[string]int64)
	m.HTTPResponseTime = make(map[string]int64)

	m.DBQueryTotal = 0
	m.DBQueryErrors = 0
	m.DBSlowQueries = 0
	m.DBAvgResponseTime = 0

	m.AIRequestTotal = 0
	m.AIRequestErrors = 0
	m.AITokensUsed = 0
	m.AIAvgResponseTime = 0

	m.CacheHits = 0
	m.CacheMisses = 0
	m.CacheErrors = 0

	m.UserRegistrations = 0
	m.UserLogins = 0
	m.QuestionsGenerated = 0
	m.AnswersGraded = 0
	m.DiagnosesGenerated = 0
}
