package metrics

import (
	"strconv"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/promauto"
)

var (
	// HTTP请求总数
	httpRequestsTotal = promauto.NewCounterVec(
		prometheus.CounterOpts{
			Name: "bblearning_http_requests_total",
			Help: "Total number of HTTP requests",
		},
		[]string{"method", "endpoint", "status"},
	)

	// HTTP请求延迟（直方图）
	httpRequestDuration = promauto.NewHistogramVec(
		prometheus.HistogramOpts{
			Name:    "bblearning_http_request_duration_seconds",
			Help:    "HTTP request latency distributions",
			Buckets: prometheus.DefBuckets, // 0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1, 2.5, 5, 10
		},
		[]string{"method", "endpoint", "status"},
	)

	// HTTP请求大小
	httpRequestSize = promauto.NewHistogramVec(
		prometheus.HistogramOpts{
			Name:    "bblearning_http_request_size_bytes",
			Help:    "HTTP request size in bytes",
			Buckets: []float64{100, 1000, 5000, 10000, 50000, 100000, 500000, 1000000},
		},
		[]string{"method", "endpoint"},
	)

	// HTTP响应大小
	httpResponseSize = promauto.NewHistogramVec(
		prometheus.HistogramOpts{
			Name:    "bblearning_http_response_size_bytes",
			Help:    "HTTP response size in bytes",
			Buckets: []float64{100, 1000, 5000, 10000, 50000, 100000, 500000, 1000000},
		},
		[]string{"method", "endpoint"},
	)

	// 活跃连接数
	httpActiveConnections = promauto.NewGauge(
		prometheus.GaugeOpts{
			Name: "bblearning_http_active_connections",
			Help: "Number of active HTTP connections",
		},
	)

	// AI API调用次数
	aiAPICallsTotal = promauto.NewCounterVec(
		prometheus.CounterOpts{
			Name: "bblearning_ai_api_calls_total",
			Help: "Total number of AI API calls",
		},
		[]string{"provider", "model", "status"},
	)

	// AI API调用延迟
	aiAPICallDuration = promauto.NewHistogramVec(
		prometheus.HistogramOpts{
			Name:    "bblearning_ai_api_call_duration_seconds",
			Help:    "AI API call duration in seconds",
			Buckets: []float64{0.1, 0.5, 1, 2, 5, 10, 30, 60},
		},
		[]string{"provider", "model", "status"},
	)

	// 数据库查询次数
	dbQueriesTotal = promauto.NewCounterVec(
		prometheus.CounterOpts{
			Name: "bblearning_db_queries_total",
			Help: "Total number of database queries",
		},
		[]string{"operation", "table", "status"},
	)

	// 数据库查询延迟
	dbQueryDuration = promauto.NewHistogramVec(
		prometheus.HistogramOpts{
			Name:    "bblearning_db_query_duration_seconds",
			Help:    "Database query duration in seconds",
			Buckets: []float64{0.001, 0.005, 0.01, 0.05, 0.1, 0.5, 1, 5},
		},
		[]string{"operation", "table"},
	)

	// Redis操作次数
	redisOpsTotal = promauto.NewCounterVec(
		prometheus.CounterOpts{
			Name: "bblearning_redis_ops_total",
			Help: "Total number of Redis operations",
		},
		[]string{"operation", "status"},
	)

	// Redis操作延迟
	redisOpsDuration = promauto.NewHistogramVec(
		prometheus.HistogramOpts{
			Name:    "bblearning_redis_ops_duration_seconds",
			Help:    "Redis operation duration in seconds",
			Buckets: []float64{0.0001, 0.0005, 0.001, 0.005, 0.01, 0.05, 0.1},
		},
		[]string{"operation"},
	)

	// 用户登录次数
	userLoginsTotal = promauto.NewCounterVec(
		prometheus.CounterOpts{
			Name: "bblearning_user_logins_total",
			Help: "Total number of user logins",
		},
		[]string{"status"},
	)

	// 练习题提交次数
	practiceSubmissionsTotal = promauto.NewCounterVec(
		prometheus.CounterOpts{
			Name: "bblearning_practice_submissions_total",
			Help: "Total number of practice question submissions",
		},
		[]string{"knowledge_point", "difficulty", "result"},
	)

	// 错题本添加次数
	wrongQuestionsTotal = promauto.NewCounterVec(
		prometheus.CounterOpts{
			Name: "bblearning_wrong_questions_total",
			Help: "Total number of questions added to wrong question book",
		},
		[]string{"knowledge_point", "difficulty"},
	)
)

// PrometheusMiddleware Prometheus监控中间件
func PrometheusMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		// 记录请求开始时间
		start := time.Now()

		// 增加活跃连接数
		httpActiveConnections.Inc()
		defer httpActiveConnections.Dec()

		// 记录请求大小
		if c.Request.ContentLength > 0 {
			httpRequestSize.WithLabelValues(
				c.Request.Method,
				c.FullPath(),
			).Observe(float64(c.Request.ContentLength))
		}

		// 继续处理请求
		c.Next()

		// 计算请求持续时间
		duration := time.Since(start).Seconds()
		status := strconv.Itoa(c.Writer.Status())

		// 记录HTTP请求指标
		httpRequestsTotal.WithLabelValues(
			c.Request.Method,
			c.FullPath(),
			status,
		).Inc()

		httpRequestDuration.WithLabelValues(
			c.Request.Method,
			c.FullPath(),
			status,
		).Observe(duration)

		// 记录响应大小
		responseSize := c.Writer.Size()
		if responseSize > 0 {
			httpResponseSize.WithLabelValues(
				c.Request.Method,
				c.FullPath(),
			).Observe(float64(responseSize))
		}
	}
}

// RecordAIAPICall 记录AI API调用
func RecordAIAPICall(provider, model, status string, duration float64) {
	aiAPICallsTotal.WithLabelValues(provider, model, status).Inc()
	aiAPICallDuration.WithLabelValues(provider, model, status).Observe(duration)
}

// RecordDBQuery 记录数据库查询
func RecordDBQuery(operation, table, status string, duration float64) {
	dbQueriesTotal.WithLabelValues(operation, table, status).Inc()
	dbQueryDuration.WithLabelValues(operation, table).Observe(duration)
}

// RecordRedisOp 记录Redis操作
func RecordRedisOp(operation, status string, duration float64) {
	redisOpsTotal.WithLabelValues(operation, status).Inc()
	redisOpsDuration.WithLabelValues(operation).Observe(duration)
}

// RecordUserLogin 记录用户登录
func RecordUserLogin(status string) {
	userLoginsTotal.WithLabelValues(status).Inc()
}

// RecordPracticeSubmission 记录练习提交
func RecordPracticeSubmission(knowledgePoint, difficulty, result string) {
	practiceSubmissionsTotal.WithLabelValues(knowledgePoint, difficulty, result).Inc()
}

// RecordWrongQuestion 记录错题
func RecordWrongQuestion(knowledgePoint, difficulty string) {
	wrongQuestionsTotal.WithLabelValues(knowledgePoint, difficulty).Inc()
}
