package handlers

import (
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"
	"github.com/qiudl/bblearning-backend/internal/domain/dto"
	"github.com/qiudl/bblearning-backend/internal/service/practice"
)

// WrongQuestionHandler 错题本处理器
type WrongQuestionHandler struct {
	wrongQuestionService *practice.WrongQuestionService
}

// NewWrongQuestionHandler 创建错题本处理器
func NewWrongQuestionHandler(wrongQuestionService *practice.WrongQuestionService) *WrongQuestionHandler {
	return &WrongQuestionHandler{
		wrongQuestionService: wrongQuestionService,
	}
}

// GetWrongQuestionList 获取错题列表
// @Summary 获取错题列表
// @Description 获取用户的错题本列表
// @Tags 错题本
// @Security Bearer
// @Produce json
// @Param knowledge_point_id query int false "知识点ID"
// @Param difficulty query string false "难度" Enums(basic, medium, advanced)
// @Param page query int false "页码" default(1)
// @Param page_size query int false "每页数量" default(20)
// @Success 200 {object} Response{data=dto.WrongQuestionListResponse}
// @Failure 401 {object} Response
// @Router /api/v1/wrong-questions [get]
func (h *WrongQuestionHandler) GetWrongQuestionList(c *gin.Context) {
	// 获取用户ID
	userID, exists := c.Get("user_id")
	if !exists {
		ErrorResponse(c, http.StatusUnauthorized, 1001, "未授权")
		return
	}

	var req dto.WrongQuestionListRequest
	if err := c.ShouldBindQuery(&req); err != nil {
		ErrorResponse(c, http.StatusBadRequest, 1000, "参数错误: "+err.Error())
		return
	}

	resp, err := h.wrongQuestionService.GetWrongQuestionList(c.Request.Context(), userID.(uint), &req)
	if err != nil {
		ErrorResponse(c, http.StatusInternalServerError, 3000, err.Error())
		return
	}

	SuccessResponse(c, resp)
}

// GetWrongQuestionDetail 获取错题详情
// @Summary 获取错题详情
// @Description 获取错题详情(包含答案和解析)
// @Tags 错题本
// @Security Bearer
// @Produce json
// @Param id path int true "错题ID"
// @Success 200 {object} Response{data=dto.WrongQuestionInfo}
// @Failure 404 {object} Response
// @Router /api/v1/wrong-questions/{id} [get]
func (h *WrongQuestionHandler) GetWrongQuestionDetail(c *gin.Context) {
	// 获取用户ID
	userID, exists := c.Get("user_id")
	if !exists {
		ErrorResponse(c, http.StatusUnauthorized, 1001, "未授权")
		return
	}

	idStr := c.Param("id")
	id, err := strconv.ParseUint(idStr, 10, 32)
	if err != nil {
		ErrorResponse(c, http.StatusBadRequest, 1000, "无效的错题ID")
		return
	}

	detail, err := h.wrongQuestionService.GetWrongQuestionDetail(c.Request.Context(), userID.(uint), uint(id))
	if err != nil {
		ErrorResponse(c, http.StatusNotFound, 2000, err.Error())
		return
	}

	SuccessResponse(c, detail)
}

// RemoveWrongQuestion 从错题本移除
// @Summary 从错题本移除
// @Description 从错题本移除(表示已掌握)
// @Tags 错题本
// @Security Bearer
// @Produce json
// @Param id path int true "错题ID"
// @Success 200 {object} Response
// @Failure 404 {object} Response
// @Router /api/v1/wrong-questions/{id} [delete]
func (h *WrongQuestionHandler) RemoveWrongQuestion(c *gin.Context) {
	// 获取用户ID
	userID, exists := c.Get("user_id")
	if !exists {
		ErrorResponse(c, http.StatusUnauthorized, 1001, "未授权")
		return
	}

	idStr := c.Param("id")
	id, err := strconv.ParseUint(idStr, 10, 32)
	if err != nil {
		ErrorResponse(c, http.StatusBadRequest, 1000, "无效的错题ID")
		return
	}

	err = h.wrongQuestionService.RemoveWrongQuestion(c.Request.Context(), userID.(uint), uint(id))
	if err != nil {
		ErrorResponse(c, http.StatusBadRequest, 1000, err.Error())
		return
	}

	SuccessResponse(c, gin.H{"message": "移除成功"})
}

// GetTopWrongQuestions 获取错误最多的题目
// @Summary 获取错误最多的题目
// @Description 获取错误次数最多的题目(用于重点复习)
// @Tags 错题本
// @Security Bearer
// @Produce json
// @Param limit query int false "数量限制" default(10)
// @Success 200 {object} Response{data=[]dto.WrongQuestionInfo}
// @Failure 401 {object} Response
// @Router /api/v1/wrong-questions/top [get]
func (h *WrongQuestionHandler) GetTopWrongQuestions(c *gin.Context) {
	// 获取用户ID
	userID, exists := c.Get("user_id")
	if !exists {
		ErrorResponse(c, http.StatusUnauthorized, 1001, "未授权")
		return
	}

	limitStr := c.DefaultQuery("limit", "10")
	limit, _ := strconv.Atoi(limitStr)

	items, err := h.wrongQuestionService.GetTopWrongQuestions(c.Request.Context(), userID.(uint), limit)
	if err != nil {
		ErrorResponse(c, http.StatusInternalServerError, 3000, err.Error())
		return
	}

	SuccessResponse(c, gin.H{"items": items})
}
