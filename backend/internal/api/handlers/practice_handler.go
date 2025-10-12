package handlers

import (
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"
	"github.com/qiudl/bblearning-backend/internal/domain/dto"
	"github.com/qiudl/bblearning-backend/internal/service/practice"
)

// PracticeHandler 练习处理器
type PracticeHandler struct {
	practiceService *practice.PracticeService
}

// NewPracticeHandler 创建练习处理器
func NewPracticeHandler(practiceService *practice.PracticeService) *PracticeHandler {
	return &PracticeHandler{
		practiceService: practiceService,
	}
}

// GetQuestionList 获取题目列表
// @Summary 获取题目列表
// @Description 根据条件查询题目列表
// @Tags 练习
// @Produce json
// @Param knowledge_point_id query int false "知识点ID"
// @Param type query string false "题型" Enums(choice, fill, answer)
// @Param difficulty query string false "难度" Enums(basic, medium, advanced)
// @Param page query int false "页码" default(1)
// @Param page_size query int false "每页数量" default(20)
// @Success 200 {object} Response{data=dto.QuestionListResponse}
// @Failure 400 {object} Response
// @Router /api/v1/questions [get]
func (h *PracticeHandler) GetQuestionList(c *gin.Context) {
	var req dto.QuestionListRequest
	if err := c.ShouldBindQuery(&req); err != nil {
		ErrorResponse(c, http.StatusBadRequest, 1000, "参数错误: "+err.Error())
		return
	}

	resp, err := h.practiceService.GetQuestionList(c.Request.Context(), &req)
	if err != nil {
		ErrorResponse(c, http.StatusInternalServerError, 3000, err.Error())
		return
	}

	SuccessResponse(c, resp)
}

// GetQuestionDetail 获取题目详情
// @Summary 获取题目详情
// @Description 获取题目详情(管理员可查看答案)
// @Tags 练习
// @Security Bearer
// @Produce json
// @Param id path int true "题目ID"
// @Success 200 {object} Response{data=dto.QuestionInfo}
// @Failure 404 {object} Response
// @Router /api/v1/questions/{id} [get]
func (h *PracticeHandler) GetQuestionDetail(c *gin.Context) {
	idStr := c.Param("id")
	id, err := strconv.ParseUint(idStr, 10, 32)
	if err != nil {
		ErrorResponse(c, http.StatusBadRequest, 1000, "无效的题目ID")
		return
	}

	// 检查是否为管理员
	role, _ := c.Get("role")
	includeAnswer := role == "admin" || role == "teacher"

	detail, err := h.practiceService.GetQuestionDetail(c.Request.Context(), uint(id), includeAnswer)
	if err != nil {
		ErrorResponse(c, http.StatusNotFound, 2000, err.Error())
		return
	}

	SuccessResponse(c, detail)
}

// GeneratePractice 生成练习
// @Summary 生成练习题目
// @Description 根据知识点随机生成练习题目
// @Tags 练习
// @Security Bearer
// @Accept json
// @Produce json
// @Param request body dto.GeneratePracticeRequest true "生成练习请求"
// @Success 200 {object} Response{data=dto.GeneratePracticeResponse}
// @Failure 400 {object} Response
// @Router /api/v1/practice/generate [post]
func (h *PracticeHandler) GeneratePractice(c *gin.Context) {
	var req dto.GeneratePracticeRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		ErrorResponse(c, http.StatusBadRequest, 1000, "参数错误: "+err.Error())
		return
	}

	resp, err := h.practiceService.GeneratePractice(c.Request.Context(), &req)
	if err != nil {
		ErrorResponse(c, http.StatusBadRequest, 1000, err.Error())
		return
	}

	SuccessResponse(c, resp)
}

// SubmitAnswer 提交答案
// @Summary 提交单个题目答案
// @Description 提交答案并获取批改结果
// @Tags 练习
// @Security Bearer
// @Accept json
// @Produce json
// @Param request body dto.SubmitAnswerRequest true "提交答案请求"
// @Success 200 {object} Response{data=dto.SubmitAnswerResponse}
// @Failure 400 {object} Response
// @Router /api/v1/practice/submit [post]
func (h *PracticeHandler) SubmitAnswer(c *gin.Context) {
	// 获取用户ID
	userID, exists := c.Get("user_id")
	if !exists {
		ErrorResponse(c, http.StatusUnauthorized, 1001, "未授权")
		return
	}

	var req dto.SubmitAnswerRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		ErrorResponse(c, http.StatusBadRequest, 1000, "参数错误: "+err.Error())
		return
	}

	resp, err := h.practiceService.SubmitAnswer(c.Request.Context(), userID.(uint), &req)
	if err != nil {
		ErrorResponse(c, http.StatusBadRequest, 1000, err.Error())
		return
	}

	SuccessResponse(c, resp)
}

// BatchSubmitAnswers 批量提交答案
// @Summary 批量提交答案
// @Description 批量提交多个题目的答案
// @Tags 练习
// @Security Bearer
// @Accept json
// @Produce json
// @Param request body dto.BatchSubmitRequest true "批量提交请求"
// @Success 200 {object} Response{data=dto.BatchSubmitResponse}
// @Failure 400 {object} Response
// @Router /api/v1/practice/batch-submit [post]
func (h *PracticeHandler) BatchSubmitAnswers(c *gin.Context) {
	// 获取用户ID
	userID, exists := c.Get("user_id")
	if !exists {
		ErrorResponse(c, http.StatusUnauthorized, 1001, "未授权")
		return
	}

	var req dto.BatchSubmitRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		ErrorResponse(c, http.StatusBadRequest, 1000, "参数错误: "+err.Error())
		return
	}

	resp, err := h.practiceService.BatchSubmitAnswers(c.Request.Context(), userID.(uint), &req)
	if err != nil {
		ErrorResponse(c, http.StatusBadRequest, 1000, err.Error())
		return
	}

	SuccessResponse(c, resp)
}

// GetPracticeRecords 获取练习记录
// @Summary 获取练习记录
// @Description 获取用户的练习记录列表
// @Tags 练习
// @Security Bearer
// @Produce json
// @Param knowledge_point_id query int false "知识点ID"
// @Param is_correct query bool false "是否正确"
// @Param start_date query string false "开始日期"
// @Param end_date query string false "结束日期"
// @Param page query int false "页码" default(1)
// @Param page_size query int false "每页数量" default(20)
// @Success 200 {object} Response{data=dto.PracticeRecordListResponse}
// @Failure 401 {object} Response
// @Router /api/v1/practice/records [get]
func (h *PracticeHandler) GetPracticeRecords(c *gin.Context) {
	// 获取用户ID
	userID, exists := c.Get("user_id")
	if !exists {
		ErrorResponse(c, http.StatusUnauthorized, 1001, "未授权")
		return
	}

	var req dto.PracticeRecordListRequest
	if err := c.ShouldBindQuery(&req); err != nil {
		ErrorResponse(c, http.StatusBadRequest, 1000, "参数错误: "+err.Error())
		return
	}

	resp, err := h.practiceService.GetPracticeRecords(c.Request.Context(), userID.(uint), &req)
	if err != nil {
		ErrorResponse(c, http.StatusInternalServerError, 3000, err.Error())
		return
	}

	SuccessResponse(c, resp)
}

// GetPracticeStatistics 获取练习统计
// @Summary 获取练习统计
// @Description 获取用户的练习统计数据
// @Tags 练习
// @Security Bearer
// @Produce json
// @Success 200 {object} Response{data=dto.PracticeStatistics}
// @Failure 401 {object} Response
// @Router /api/v1/practice/statistics [get]
func (h *PracticeHandler) GetPracticeStatistics(c *gin.Context) {
	// 获取用户ID
	userID, exists := c.Get("user_id")
	if !exists {
		ErrorResponse(c, http.StatusUnauthorized, 1001, "未授权")
		return
	}

	stats, err := h.practiceService.GetPracticeStatistics(c.Request.Context(), userID.(uint))
	if err != nil {
		ErrorResponse(c, http.StatusInternalServerError, 3000, err.Error())
		return
	}

	SuccessResponse(c, stats)
}
