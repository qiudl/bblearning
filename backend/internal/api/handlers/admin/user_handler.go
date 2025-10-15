package admin

import (
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"
	"github.com/qiudl/bblearning-backend/internal/domain/models"
	"github.com/qiudl/bblearning-backend/internal/service/admin"
)

// UserHandler 管理员用户管理处理器
type UserHandler struct {
	userService *admin.UserService
}

// NewUserHandler 创建用户管理处理器
func NewUserHandler(userService *admin.UserService) *UserHandler {
	return &UserHandler{
		userService: userService,
	}
}

// GetUserList 获取用户列表
// @Summary 获取用户列表
// @Description 管理员获取系统用户列表，支持分页、搜索、筛选
// @Tags Admin - User
// @Security BearerAuth
// @Param page query int false "页码" default(1)
// @Param pageSize query int false "每页数量" default(20)
// @Param search query string false "搜索关键词(用户名/邮箱/手机)"
// @Param role query string false "角色筛选(student/teacher/admin)"
// @Param status query string false "状态筛选(active/inactive/banned)"
// @Param grade query int false "年级筛选"
// @Success 200 {object} models.Response{data=models.PaginatedUserList}
// @Router /api/v1/admin/users [get]
func (h *UserHandler) GetUserList(c *gin.Context) {
	// 解析查询参数
	req := &models.UserListRequest{
		Page:     1,
		PageSize: 20,
	}

	if page := c.Query("page"); page != "" {
		if p, err := strconv.Atoi(page); err == nil && p > 0 {
			req.Page = p
		}
	}

	if pageSize := c.Query("pageSize"); pageSize != "" {
		if ps, err := strconv.Atoi(pageSize); err == nil && ps > 0 && ps <= 100 {
			req.PageSize = ps
		}
	}

	req.Search = c.Query("search")
	req.Role = c.Query("role")
	req.Status = c.Query("status")

	if grade := c.Query("grade"); grade != "" {
		if g, err := strconv.Atoi(grade); err == nil {
			req.Grade = g
		}
	}

	// 调用服务
	result, err := h.userService.GetUserList(c.Request.Context(), req)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"code":    5000,
			"message": "获取用户列表失败",
			"error":   err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"code":    0,
		"message": "success",
		"data":    result,
	})
}

// GetUserDetail 获取用户详情
// @Summary 获取用户详情
// @Description 管理员获取指定用户的详细信息
// @Tags Admin - User
// @Security BearerAuth
// @Param id path int true "用户ID"
// @Success 200 {object} models.Response{data=models.User}
// @Router /api/v1/admin/users/{id} [get]
func (h *UserHandler) GetUserDetail(c *gin.Context) {
	userID, err := strconv.ParseUint(c.Param("id"), 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"code":    1000,
			"message": "无效的用户ID",
		})
		return
	}

	user, err := h.userService.GetUserDetail(c.Request.Context(), uint(userID))
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"code":    5000,
			"message": "获取用户详情失败",
			"error":   err.Error(),
		})
		return
	}

	if user == nil {
		c.JSON(http.StatusNotFound, gin.H{
			"code":    2000,
			"message": "用户不存在",
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"code":    0,
		"message": "success",
		"data":    user,
	})
}

// UpdateUserStatus 更新用户状态
// @Summary 更新用户状态
// @Description 管理员更新用户状态(激活/禁用/封禁)
// @Tags Admin - User
// @Security BearerAuth
// @Param id path int true "用户ID"
// @Param request body models.UpdateUserStatusRequest true "状态更新请求"
// @Success 200 {object} models.Response
// @Router /api/v1/admin/users/{id}/status [put]
func (h *UserHandler) UpdateUserStatus(c *gin.Context) {
	userID, err := strconv.ParseUint(c.Param("id"), 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"code":    1000,
			"message": "无效的用户ID",
		})
		return
	}

	var req models.UpdateUserStatusRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"code":    1000,
			"message": "请求参数错误",
			"error":   err.Error(),
		})
		return
	}

	// 获取当前管理员ID
	adminID, _ := c.Get("user_id")

	err = h.userService.UpdateUserStatus(c.Request.Context(), uint(userID), req.Status, req.Reason, adminID.(uint))
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"code":    5000,
			"message": "更新用户状态失败",
			"error":   err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"code":    0,
		"message": "用户状态更新成功",
	})
}

// GetUserStatistics 获取用户统计
// @Summary 获取用户统计
// @Description 管理员获取用户统计信息
// @Tags Admin - User
// @Security BearerAuth
// @Success 200 {object} models.Response{data=models.UserStatistics}
// @Router /api/v1/admin/users/statistics [get]
func (h *UserHandler) GetUserStatistics(c *gin.Context) {
	stats, err := h.userService.GetUserStatistics(c.Request.Context())
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"code":    5000,
			"message": "获取用户统计失败",
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
