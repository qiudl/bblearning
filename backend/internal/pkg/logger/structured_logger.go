package logger

import (
	"go.uber.org/zap"
	"go.uber.org/zap/zapcore"
)

// StructuredLogger 结构化日志记录器
type StructuredLogger struct {
	logger *zap.Logger
}

// NewStructuredLogger 创建结构化日志记录器
func NewStructuredLogger() *StructuredLogger {
	return &StructuredLogger{
		logger: log,
	}
}

// WithFields 添加字段
func (l *StructuredLogger) WithFields(fields map[string]interface{}) *StructuredLogger {
	zapFields := make([]zap.Field, 0, len(fields))
	for k, v := range fields {
		zapFields = append(zapFields, zap.Any(k, v))
	}
	return &StructuredLogger{
		logger: l.logger.With(zapFields...),
	}
}

// InfoWithFields 记录Info日志并附带字段
func InfoWithFields(msg string, fields map[string]interface{}) {
	zapFields := make([]zap.Field, 0, len(fields))
	for k, v := range fields {
		zapFields = append(zapFields, zap.Any(k, v))
	}
	log.Info(msg, zapFields...)
}

// ErrorWithFields 记录Error日志并附带字段
func ErrorWithFields(msg string, fields map[string]interface{}) {
	zapFields := make([]zap.Field, 0, len(fields))
	for k, v := range fields {
		zapFields = append(zapFields, zap.Any(k, v))
	}
	log.Error(msg, zapFields...)
}

// WarnWithFields 记录Warn日志并附带字段
func WarnWithFields(msg string, fields map[string]interface{}) {
	zapFields := make([]zap.Field, 0, len(fields))
	for k, v := range fields {
		zapFields = append(zapFields, zap.Any(k, v))
	}
	log.Warn(msg, zapFields...)
}

// RequestLogger 请求日志记录器
type RequestLogger struct {
	RequestID  string
	Method     string
	Path       string
	UserID     uint
	IP         string
	UserAgent  string
	StatusCode int
	Latency    int64 // 毫秒
	Error      string
}

// LogRequest 记录请求日志
func (rl *RequestLogger) LogRequest() {
	fields := []zapcore.Field{
		zap.String("request_id", rl.RequestID),
		zap.String("method", rl.Method),
		zap.String("path", rl.Path),
		zap.Uint("user_id", rl.UserID),
		zap.String("ip", rl.IP),
		zap.String("user_agent", rl.UserAgent),
		zap.Int("status_code", rl.StatusCode),
		zap.Int64("latency_ms", rl.Latency),
	}

	if rl.Error != "" {
		fields = append(fields, zap.String("error", rl.Error))
		log.Error("HTTP Request Failed", fields...)
	} else {
		log.Info("HTTP Request", fields...)
	}
}

// DatabaseLogger 数据库操作日志
type DatabaseLogger struct {
	Operation string
	Table     string
	Query     string
	Duration  int64 // 毫秒
	RowsAffected int64
	Error     string
}

// LogQuery 记录数据库查询日志
func (dl *DatabaseLogger) LogQuery() {
	fields := []zapcore.Field{
		zap.String("operation", dl.Operation),
		zap.String("table", dl.Table),
		zap.String("query", dl.Query),
		zap.Int64("duration_ms", dl.Duration),
		zap.Int64("rows_affected", dl.RowsAffected),
	}

	if dl.Error != "" {
		fields = append(fields, zap.String("error", dl.Error))
		log.Error("Database Query Failed", fields...)
	} else if dl.Duration > 1000 {
		// 慢查询警告
		log.Warn("Slow Database Query", fields...)
	} else {
		log.Debug("Database Query", fields...)
	}
}

// AIServiceLogger AI服务日志
type AIServiceLogger struct {
	Provider   string
	Model      string
	Operation  string
	TokensUsed int
	Duration   int64 // 毫秒
	Error      string
}

// LogAIRequest 记录AI服务请求日志
func (al *AIServiceLogger) LogAIRequest() {
	fields := []zapcore.Field{
		zap.String("provider", al.Provider),
		zap.String("model", al.Model),
		zap.String("operation", al.Operation),
		zap.Int("tokens_used", al.TokensUsed),
		zap.Int64("duration_ms", al.Duration),
	}

	if al.Error != "" {
		fields = append(fields, zap.String("error", al.Error))
		log.Error("AI Service Request Failed", fields...)
	} else {
		log.Info("AI Service Request", fields...)
	}
}

// CacheLogger 缓存操作日志
type CacheLogger struct {
	Operation string // get, set, delete
	Key       string
	Hit       bool
	TTL       int64 // 秒
	Error     string
}

// LogCacheOperation 记录缓存操作日志
func (cl *CacheLogger) LogCacheOperation() {
	fields := []zapcore.Field{
		zap.String("operation", cl.Operation),
		zap.String("key", cl.Key),
		zap.Bool("hit", cl.Hit),
		zap.Int64("ttl", cl.TTL),
	}

	if cl.Error != "" {
		fields = append(fields, zap.String("error", cl.Error))
		log.Error("Cache Operation Failed", fields...)
	} else {
		log.Debug("Cache Operation", fields...)
	}
}

// BusinessLogger 业务日志
type BusinessLogger struct {
	Action   string
	UserID   uint
	Resource string
	Details  map[string]interface{}
	Success  bool
	Error    string
}

// LogBusinessEvent 记录业务事件日志
func (bl *BusinessLogger) LogBusinessEvent() {
	fields := []zapcore.Field{
		zap.String("action", bl.Action),
		zap.Uint("user_id", bl.UserID),
		zap.String("resource", bl.Resource),
		zap.Bool("success", bl.Success),
	}

	if bl.Details != nil {
		for k, v := range bl.Details {
			fields = append(fields, zap.Any(k, v))
		}
	}

	if bl.Error != "" {
		fields = append(fields, zap.String("error", bl.Error))
		log.Error("Business Event Failed", fields...)
	} else {
		log.Info("Business Event", fields...)
	}
}
