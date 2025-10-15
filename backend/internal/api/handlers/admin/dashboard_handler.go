package admin

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/qiudl/bblearning-backend/internal/service/admin"
)

// DashboardHandler 仪表板处理器
type DashboardHandler struct {
	dashboardService *admin.DashboardService
}

// NewDashboardHandler 创建仪表板处理器
func NewDashboardHandler(dashboardService *admin.DashboardService) *DashboardHandler {
	return &DashboardHandler{
		dashboardService: dashboardService,
	}
}

// GetStatistics 获取仪表板统计数据
// @Summary 获取仪表板统计数据
// @Description 管理员获取系统核心统计指标
// @Tags Admin - Dashboard
// @Security BearerAuth
// @Success 200 {object} models.Response{data=models.DashboardStatistics}
// @Router /api/v1/admin/dashboard/statistics [get]
func (h *DashboardHandler) GetStatistics(c *gin.Context) {
	stats, err := h.dashboardService.GetStatistics(c.Request.Context())
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"code":    5000,
			"message": "获取统计数据失败",
			"error":   err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"code":    0,
		"message": "success",
		"data":    stats,
	})
}
