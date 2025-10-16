package handler

import (
	"net/http"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/qiudl/bblearning-backend/internal/pkg/metrics"
)

// MetricsHandler 监控指标处理器
type MetricsHandler struct{}

// NewMetricsHandler 创建监控指标处理器
func NewMetricsHandler() *MetricsHandler {
	return &MetricsHandler{}
}

// GetMetrics 获取所有监控指标
// @Summary 获取监控指标
// @Description 获取系统所有监控指标，包括HTTP、数据库、AI、缓存和业务指标
// @Tags metrics
// @Produce json
// @Success 200 {object} metrics.AllMetrics
// @Router /api/v1/metrics [get]
func (h *MetricsHandler) GetMetrics(c *gin.Context) {
	allMetrics := metrics.GetMetrics().GetAllMetrics()
	c.JSON(http.StatusOK, gin.H{
		"code":    0,
		"message": "success",
		"data":    allMetrics,
	})
}

// GetHTTPMetrics 获取HTTP指标
// @Summary 获取HTTP指标
// @Description 获取HTTP请求相关的监控指标
// @Tags metrics
// @Produce json
// @Success 200 {object} map[string]metrics.HTTPMetric
// @Router /api/v1/metrics/http [get]
func (h *MetricsHandler) GetHTTPMetrics(c *gin.Context) {
	httpMetrics := metrics.GetMetrics().GetHTTPMetrics()
	c.JSON(http.StatusOK, gin.H{
		"code":    0,
		"message": "success",
		"data":    httpMetrics,
	})
}

// GetDBMetrics 获取数据库指标
// @Summary 获取数据库指标
// @Description 获取数据库查询相关的监控指标
// @Tags metrics
// @Produce json
// @Success 200 {object} metrics.DBMetric
// @Router /api/v1/metrics/db [get]
func (h *MetricsHandler) GetDBMetrics(c *gin.Context) {
	dbMetrics := metrics.GetMetrics().GetDBMetrics()
	c.JSON(http.StatusOK, gin.H{
		"code":    0,
		"message": "success",
		"data":    dbMetrics,
	})
}

// GetAIMetrics 获取AI服务指标
// @Summary 获取AI服务指标
// @Description 获取AI服务相关的监控指标
// @Tags metrics
// @Produce json
// @Success 200 {object} metrics.AIMetric
// @Router /api/v1/metrics/ai [get]
func (h *MetricsHandler) GetAIMetrics(c *gin.Context) {
	aiMetrics := metrics.GetMetrics().GetAIMetrics()
	c.JSON(http.StatusOK, gin.H{
		"code":    0,
		"message": "success",
		"data":    aiMetrics,
	})
}

// GetCacheMetrics 获取缓存指标
// @Summary 获取缓存指标
// @Description 获取缓存相关的监控指标
// @Tags metrics
// @Produce json
// @Success 200 {object} metrics.CacheMetric
// @Router /api/v1/metrics/cache [get]
func (h *MetricsHandler) GetCacheMetrics(c *gin.Context) {
	cacheMetrics := metrics.GetMetrics().GetCacheMetrics()
	c.JSON(http.StatusOK, gin.H{
		"code":    0,
		"message": "success",
		"data":    cacheMetrics,
	})
}

// GetBusinessMetrics 获取业务指标
// @Summary 获取业务指标
// @Description 获取业务相关的监控指标
// @Tags metrics
// @Produce json
// @Success 200 {object} metrics.BusinessMetric
// @Router /api/v1/metrics/business [get]
func (h *MetricsHandler) GetBusinessMetrics(c *gin.Context) {
	businessMetrics := metrics.GetMetrics().GetBusinessMetrics()
	c.JSON(http.StatusOK, gin.H{
		"code":    0,
		"message": "success",
		"data":    businessMetrics,
	})
}

// ResetMetrics 重置所有指标（仅开发环境）
// @Summary 重置指标
// @Description 重置所有监控指标（仅在开发环境可用）
// @Tags metrics
// @Produce json
// @Success 200 {object} map[string]string
// @Router /api/v1/metrics/reset [post]
func (h *MetricsHandler) ResetMetrics(c *gin.Context) {
	// 仅在开发环境允许重置
	if gin.Mode() != gin.DebugMode {
		c.JSON(http.StatusForbidden, gin.H{
			"code":    1001,
			"message": "Reset metrics only allowed in debug mode",
		})
		return
	}

	metrics.GetMetrics().Reset()
	c.JSON(http.StatusOK, gin.H{
		"code":    0,
		"message": "Metrics reset successfully",
	})
}

// HealthCheck 健康检查
// @Summary 健康检查
// @Description 检查服务健康状态
// @Tags health
// @Produce json
// @Success 200 {object} map[string]interface{}
// @Router /health [get]
func (h *MetricsHandler) HealthCheck(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{
		"status":    "healthy",
		"timestamp": time.Now().Unix(),
		"service":   "bblearning-backend",
	})
}
