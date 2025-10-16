package tests

import (
	"testing"
	"time"

	"github.com/qiudl/bblearning-backend/internal/pkg/metrics"
	"github.com/stretchr/testify/assert"
)

// TestMetricsRecordHTTPRequest 测试HTTP请求指标记录
func TestMetricsRecordHTTPRequest(t *testing.T) {
	m := metrics.GetMetrics()
	m.Reset() // 重置指标

	// 记录成功请求
	m.RecordHTTPRequest("GET", "/api/v1/users", 200, 100*time.Millisecond)
	m.RecordHTTPRequest("GET", "/api/v1/users", 200, 200*time.Millisecond)

	// 记录错误请求
	m.RecordHTTPRequest("POST", "/api/v1/users", 400, 50*time.Millisecond)

	httpMetrics := m.GetHTTPMetrics()

	// 验证GET /api/v1/users指标
	getMetric := httpMetrics["GET:/api/v1/users"]
	assert.Equal(t, int64(2), getMetric.Total)
	assert.Equal(t, int64(0), getMetric.Errors)
	assert.Equal(t, int64(150), getMetric.AvgDuration) // (100 + 200) / 2

	// 验证POST /api/v1/users指标
	postMetric := httpMetrics["POST:/api/v1/users"]
	assert.Equal(t, int64(1), postMetric.Total)
	assert.Equal(t, int64(1), postMetric.Errors)
	assert.Equal(t, int64(50), postMetric.AvgDuration)
}

// TestMetricsRecordDBQuery 测试数据库查询指标记录
func TestMetricsRecordDBQuery(t *testing.T) {
	m := metrics.GetMetrics()
	m.Reset()

	// 记录快速查询
	m.RecordDBQuery(50*time.Millisecond, false, false)
	m.RecordDBQuery(100*time.Millisecond, false, false)

	// 记录慢查询
	m.RecordDBQuery(1500*time.Millisecond, false, true)

	// 记录失败查询
	m.RecordDBQuery(200*time.Millisecond, true, false)

	dbMetrics := m.GetDBMetrics()
	assert.Equal(t, int64(4), dbMetrics.Total)
	assert.Equal(t, int64(1), dbMetrics.Errors)
	assert.Equal(t, int64(1), dbMetrics.SlowQueries)
	// 平均响应时间: (50 + 100 + 1500 + 200) / 4 = 462.5
	assert.InDelta(t, int64(462), dbMetrics.AvgResponseTime, 1)
}

// TestMetricsRecordAIRequest 测试AI服务指标记录
func TestMetricsRecordAIRequest(t *testing.T) {
	m := metrics.GetMetrics()
	m.Reset()

	// 记录成功的AI请求
	m.RecordAIRequest(2*time.Second, 500, false)
	m.RecordAIRequest(3*time.Second, 800, false)

	// 记录失败的AI请求
	m.RecordAIRequest(1*time.Second, 0, true)

	aiMetrics := m.GetAIMetrics()
	assert.Equal(t, int64(3), aiMetrics.Total)
	assert.Equal(t, int64(1), aiMetrics.Errors)
	assert.Equal(t, int64(1300), aiMetrics.TokensUsed)
	// 平均响应时间: (2000 + 3000 + 1000) / 3 = 2000ms
	assert.Equal(t, int64(2000), aiMetrics.AvgResponseTime)
}

// TestMetricsRecordCacheOperation 测试缓存操作指标记录
func TestMetricsRecordCacheOperation(t *testing.T) {
	m := metrics.GetMetrics()
	m.Reset()

	// 记录缓存命中
	m.RecordCacheOperation(true, false)
	m.RecordCacheOperation(true, false)
	m.RecordCacheOperation(true, false)

	// 记录缓存未命中
	m.RecordCacheOperation(false, false)

	// 记录缓存错误
	m.RecordCacheOperation(false, true)

	cacheMetrics := m.GetCacheMetrics()
	assert.Equal(t, int64(3), cacheMetrics.Hits)
	assert.Equal(t, int64(1), cacheMetrics.Misses)
	assert.Equal(t, int64(1), cacheMetrics.Errors)
	// 命中率: 3 / (3 + 1) * 100 = 75%
	assert.InDelta(t, 75.0, cacheMetrics.HitRate, 0.1)
}

// TestMetricsBusinessOperations 测试业务指标记录
func TestMetricsBusinessOperations(t *testing.T) {
	m := metrics.GetMetrics()
	m.Reset()

	// 记录业务操作
	m.RecordUserRegistration()
	m.RecordUserRegistration()
	m.RecordUserLogin()
	m.RecordUserLogin()
	m.RecordUserLogin()
	m.RecordQuestionGeneration()
	m.RecordQuestionGeneration()
	m.RecordAnswerGrading()
	m.RecordDiagnosis()

	businessMetrics := m.GetBusinessMetrics()
	assert.Equal(t, int64(2), businessMetrics.UserRegistrations)
	assert.Equal(t, int64(3), businessMetrics.UserLogins)
	assert.Equal(t, int64(2), businessMetrics.QuestionsGenerated)
	assert.Equal(t, int64(1), businessMetrics.AnswersGraded)
	assert.Equal(t, int64(1), businessMetrics.DiagnosesGenerated)
}

// TestMetricsGetAllMetrics 测试获取所有指标
func TestMetricsGetAllMetrics(t *testing.T) {
	m := metrics.GetMetrics()
	m.Reset()

	// 记录各种指标
	m.RecordHTTPRequest("GET", "/test", 200, 100*time.Millisecond)
	m.RecordDBQuery(50*time.Millisecond, false, false)
	m.RecordAIRequest(2*time.Second, 500, false)
	m.RecordCacheOperation(true, false)
	m.RecordUserRegistration()

	allMetrics := m.GetAllMetrics()

	assert.NotNil(t, allMetrics.HTTP)
	assert.NotNil(t, allMetrics.DB)
	assert.NotNil(t, allMetrics.AI)
	assert.NotNil(t, allMetrics.Cache)
	assert.NotNil(t, allMetrics.Business)

	assert.Len(t, allMetrics.HTTP, 1)
	assert.Equal(t, int64(1), allMetrics.DB.Total)
	assert.Equal(t, int64(1), allMetrics.AI.Total)
	assert.Equal(t, int64(1), allMetrics.Cache.Hits)
	assert.Equal(t, int64(1), allMetrics.Business.UserRegistrations)
}

// TestMetricsReset 测试重置指标
func TestMetricsReset(t *testing.T) {
	m := metrics.GetMetrics()

	// 记录一些指标
	m.RecordHTTPRequest("GET", "/test", 200, 100*time.Millisecond)
	m.RecordUserRegistration()

	// 重置
	m.Reset()

	// 验证所有指标已清零
	allMetrics := m.GetAllMetrics()
	assert.Len(t, allMetrics.HTTP, 0)
	assert.Equal(t, int64(0), allMetrics.DB.Total)
	assert.Equal(t, int64(0), allMetrics.AI.Total)
	assert.Equal(t, int64(0), allMetrics.Cache.Hits)
	assert.Equal(t, int64(0), allMetrics.Business.UserRegistrations)
}

// BenchmarkRecordHTTPRequest 性能测试：记录HTTP请求
func BenchmarkRecordHTTPRequest(b *testing.B) {
	m := metrics.GetMetrics()
	b.ResetTimer()

	for i := 0; i < b.N; i++ {
		m.RecordHTTPRequest("GET", "/api/v1/users", 200, 100*time.Millisecond)
	}
}

// BenchmarkGetAllMetrics 性能测试：获取所有指标
func BenchmarkGetAllMetrics(b *testing.B) {
	m := metrics.GetMetrics()
	m.Reset()

	// 预先记录一些指标
	for i := 0; i < 100; i++ {
		m.RecordHTTPRequest("GET", "/api/v1/users", 200, 100*time.Millisecond)
	}

	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		m.GetAllMetrics()
	}
}
