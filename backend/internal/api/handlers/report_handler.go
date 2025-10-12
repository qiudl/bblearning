package handlers

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/qiudl/bblearning-backend/internal/domain/dto"
	"github.com/qiudl/bblearning-backend/internal/service/analytics"
)

// ReportHandler 学习报告处理器
type ReportHandler struct {
	reportService *analytics.ReportService
}

// NewReportHandler 创建学习报告处理器
func NewReportHandler(reportService *analytics.ReportService) *ReportHandler {
	return &ReportHandler{
		reportService: reportService,
	}
}

// GetLearningReport 获取学习报告
// @Summary 获取学习报告
// @Description 获取用户的详细学习报告,包含概况、练习分析、知识点分析等
// @Tags 学习报告
// @Security Bearer
// @Produce json
// @Param start_date query string false "开始日期 (YYYY-MM-DD)"
// @Param end_date query string false "结束日期 (YYYY-MM-DD)"
// @Param period query string false "统计周期" Enums(day, week, month) default(week)
// @Success 200 {object} Response{data=dto.LearningReportResponse}
// @Failure 401 {object} Response
// @Failure 500 {object} Response
// @Router /api/v1/reports/learning [get]
func (h *ReportHandler) GetLearningReport(c *gin.Context) {
	// 获取用户ID
	userID, exists := c.Get("user_id")
	if !exists {
		ErrorResponse(c, http.StatusUnauthorized, 1001, "未授权")
		return
	}

	var req dto.LearningReportRequest
	if err := c.ShouldBindQuery(&req); err != nil {
		ErrorResponse(c, http.StatusBadRequest, 1000, "参数错误: "+err.Error())
		return
	}

	report, err := h.reportService.GetLearningReport(c.Request.Context(), userID.(uint), &req)
	if err != nil {
		ErrorResponse(c, http.StatusInternalServerError, 3000, "获取学习报告失败: "+err.Error())
		return
	}

	SuccessResponse(c, report)
}

// GetWeakPoints 获取薄弱点分析
// @Summary 获取薄弱点分析
// @Description 获取用户的薄弱知识点列表及详细分析
// @Tags 学习报告
// @Security Bearer
// @Produce json
// @Success 200 {object} Response{data=dto.WeakPointsResponse}
// @Failure 401 {object} Response
// @Failure 500 {object} Response
// @Router /api/v1/reports/weak-points [get]
func (h *ReportHandler) GetWeakPoints(c *gin.Context) {
	// 获取用户ID
	userID, exists := c.Get("user_id")
	if !exists {
		ErrorResponse(c, http.StatusUnauthorized, 1001, "未授权")
		return
	}

	weakPoints, err := h.reportService.GetWeakPoints(c.Request.Context(), userID.(uint))
	if err != nil {
		ErrorResponse(c, http.StatusInternalServerError, 3000, "获取薄弱点失败: "+err.Error())
		return
	}

	SuccessResponse(c, weakPoints)
}

// GetProgressOverview 获取进度总览
// @Summary 获取进度总览
// @Description 获取用户的整体学习进度和章节进度
// @Tags 学习报告
// @Security Bearer
// @Produce json
// @Param grade query string false "年级" Enums(7, 8, 9)
// @Success 200 {object} Response{data=dto.ProgressOverviewResponse}
// @Failure 401 {object} Response
// @Failure 500 {object} Response
// @Router /api/v1/reports/progress [get]
func (h *ReportHandler) GetProgressOverview(c *gin.Context) {
	// 获取用户ID
	userID, exists := c.Get("user_id")
	if !exists {
		ErrorResponse(c, http.StatusUnauthorized, 1001, "未授权")
		return
	}

	grade := c.DefaultQuery("grade", "")

	overview, err := h.reportService.GetProgressOverview(c.Request.Context(), userID.(uint), grade)
	if err != nil {
		ErrorResponse(c, http.StatusInternalServerError, 3000, "获取进度总览失败: "+err.Error())
		return
	}

	SuccessResponse(c, overview)
}

// GetLearningStatistics 获取学习统计
// @Summary 获取学习统计
// @Description 获取用户的学习统计数据(今日/本周/本月/总计)
// @Tags 学习报告
// @Security Bearer
// @Produce json
// @Success 200 {object} Response{data=dto.LearningStatisticsResponse}
// @Failure 401 {object} Response
// @Failure 500 {object} Response
// @Router /api/v1/reports/statistics [get]
func (h *ReportHandler) GetLearningStatistics(c *gin.Context) {
	// 获取用户ID
	userID, exists := c.Get("user_id")
	if !exists {
		ErrorResponse(c, http.StatusUnauthorized, 1001, "未授权")
		return
	}

	statistics, err := h.reportService.GetLearningStatistics(c.Request.Context(), userID.(uint))
	if err != nil {
		ErrorResponse(c, http.StatusInternalServerError, 3000, "获取学习统计失败: "+err.Error())
		return
	}

	SuccessResponse(c, statistics)
}
