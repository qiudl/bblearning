package api

import (
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"
	"github.com/qiudl/bblearning-backend/internal/domain"
	"github.com/qiudl/bblearning-backend/internal/service"
)

// APIKeyHandler API密钥管理处理器
type APIKeyHandler struct {
	service service.APIKeyService
}

// NewAPIKeyHandler 创建处理器
func NewAPIKeyHandler(service service.APIKeyService) *APIKeyHandler {
	return &APIKeyHandler{service: service}
}

// RegisterRoutes 注册路由
func (h *APIKeyHandler) RegisterRoutes(rg *gin.RouterGroup) {
	admin := rg.Group("/admin/api-keys")
	// TODO: 添加管理员权限中间件
	// admin.Use(middleware.RequireAdmin())
	{
		admin.POST("", h.Create)
		admin.GET("", h.List)
		admin.GET("/:id", h.GetByID)
		admin.PUT("/:id/status", h.UpdateStatus)
		admin.DELETE("/:id", h.Delete)
		admin.GET("/:id/audit-logs", h.GetAuditLogs)
	}
}

// Create 创建/更新API密钥
// @Summary 创建或更新API密钥
// @Description 创建新的API密钥或更新已存在的密钥
// @Tags Admin
// @Accept json
// @Produce json
// @Param request body domain.CreateAPIKeyRequest true "API密钥信息"
// @Success 200 {object} map[string]interface{} "成功"
// @Failure 400 {object} map[string]interface{} "参数错误"
// @Failure 500 {object} map[string]interface{} "服务器错误"
// @Router /api/v1/admin/api-keys [post]
func (h *APIKeyHandler) Create(c *gin.Context) {
	var req domain.CreateAPIKeyRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"code":    1000,
			"message": "参数错误: " + err.Error(),
		})
		return
	}

	// 获取操作者ID（从JWT中间件）
	// TODO: 从context获取当前用户ID
	operatorID := int64(1)
	if userID, exists := c.Get("user_id"); exists {
		if uid, ok := userID.(int64); ok {
			operatorID = uid
		}
	}

	dto, err := h.service.Create(c.Request.Context(), &req, operatorID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"code":    3000,
			"message": "创建API密钥失败: " + err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"code":    0,
		"message": "API密钥保存成功",
		"data":    dto,
	})
}

// List 列出API密钥
// @Summary 列出API密钥
// @Description 获取API密钥列表（不包含明文密钥）
// @Tags Admin
// @Accept json
// @Produce json
// @Param provider query string false "服务提供商"
// @Success 200 {object} map[string]interface{} "成功"
// @Failure 500 {object} map[string]interface{} "服务器错误"
// @Router /api/v1/admin/api-keys [get]
func (h *APIKeyHandler) List(c *gin.Context) {
	provider := c.Query("provider")

	dtos, err := h.service.List(c.Request.Context(), provider)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"code":    3000,
			"message": "获取API密钥列表失败: " + err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"code": 0,
		"data": dtos,
	})
}

// GetByID 获取API密钥详情
// @Summary 获取API密钥详情
// @Description 根据ID获取API密钥详情（不包含明文密钥）
// @Tags Admin
// @Accept json
// @Produce json
// @Param id path int true "API密钥ID"
// @Success 200 {object} map[string]interface{} "成功"
// @Failure 404 {object} map[string]interface{} "未找到"
// @Router /api/v1/admin/api-keys/{id} [get]
func (h *APIKeyHandler) GetByID(c *gin.Context) {
	id, err := strconv.ParseInt(c.Param("id"), 10, 64)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"code":    1000,
			"message": "无效的ID",
		})
		return
	}

	dto, err := h.service.GetByID(c.Request.Context(), id)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{
			"code":    2000,
			"message": "API密钥不存在",
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"code": 0,
		"data": dto,
	})
}

// UpdateStatus 更新状态
// @Summary 更新API密钥状态
// @Description 启用或禁用API密钥
// @Tags Admin
// @Accept json
// @Produce json
// @Param id path int true "API密钥ID"
// @Param request body domain.UpdateAPIKeyStatusRequest true "状态信息"
// @Success 200 {object} map[string]interface{} "成功"
// @Failure 400 {object} map[string]interface{} "参数错误"
// @Failure 500 {object} map[string]interface{} "服务器错误"
// @Router /api/v1/admin/api-keys/{id}/status [put]
func (h *APIKeyHandler) UpdateStatus(c *gin.Context) {
	id, err := strconv.ParseInt(c.Param("id"), 10, 64)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"code":    1000,
			"message": "无效的ID",
		})
		return
	}

	var req domain.UpdateAPIKeyStatusRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"code":    1000,
			"message": "参数错误: " + err.Error(),
		})
		return
	}

	// 获取操作者ID
	operatorID := int64(1)
	if userID, exists := c.Get("user_id"); exists {
		if uid, ok := userID.(int64); ok {
			operatorID = uid
		}
	}

	if err := h.service.UpdateStatus(c.Request.Context(), id, req.IsActive, operatorID); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"code":    3000,
			"message": "更新状态失败: " + err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"code":    0,
		"message": "状态更新成功",
	})
}

// Delete 删除API密钥
// @Summary 删除API密钥
// @Description 删除指定的API密钥
// @Tags Admin
// @Accept json
// @Produce json
// @Param id path int true "API密钥ID"
// @Success 200 {object} map[string]interface{} "成功"
// @Failure 400 {object} map[string]interface{} "参数错误"
// @Failure 500 {object} map[string]interface{} "服务器错误"
// @Router /api/v1/admin/api-keys/{id} [delete]
func (h *APIKeyHandler) Delete(c *gin.Context) {
	id, err := strconv.ParseInt(c.Param("id"), 10, 64)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"code":    1000,
			"message": "无效的ID",
		})
		return
	}

	// 获取操作者ID
	operatorID := int64(1)
	if userID, exists := c.Get("user_id"); exists {
		if uid, ok := userID.(int64); ok {
			operatorID = uid
		}
	}

	if err := h.service.Delete(c.Request.Context(), id, operatorID); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"code":    3000,
			"message": "删除失败: " + err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"code":    0,
		"message": "删除成功",
	})
}

// GetAuditLogs 获取审计日志
// @Summary 获取API密钥审计日志
// @Description 获取指定API密钥的操作审计日志
// @Tags Admin
// @Accept json
// @Produce json
// @Param id path int true "API密钥ID"
// @Param limit query int false "每页数量" default(20)
// @Param offset query int false "偏移量" default(0)
// @Success 200 {object} map[string]interface{} "成功"
// @Failure 400 {object} map[string]interface{} "参数错误"
// @Failure 500 {object} map[string]interface{} "服务器错误"
// @Router /api/v1/admin/api-keys/{id}/audit-logs [get]
func (h *APIKeyHandler) GetAuditLogs(c *gin.Context) {
	id, err := strconv.ParseInt(c.Param("id"), 10, 64)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"code":    1000,
			"message": "无效的ID",
		})
		return
	}

	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "20"))
	offset, _ := strconv.Atoi(c.DefaultQuery("offset", "0"))

	logs, err := h.service.GetAuditLogs(c.Request.Context(), id, limit, offset)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"code":    3000,
			"message": "获取审计日志失败: " + err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"code": 0,
		"data": logs,
	})
}
