package handlers

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/qiudl/bblearning-backend/internal/domain/dto"
	"github.com/qiudl/bblearning-backend/internal/service/ai"
)

// AIHandler AI处理器
type AIHandler struct {
	aiService *ai.AIService
}

// NewAIHandler 创建AI处理器
func NewAIHandler(aiService *ai.AIService) *AIHandler {
	return &AIHandler{
		aiService: aiService,
	}
}

// GenerateQuestion AI生成题目
// @Summary AI生成题目
// @Description 使用AI根据知识点生成题目
// @Tags AI
// @Security Bearer
// @Accept json
// @Produce json
// @Param request body dto.AIGenerateQuestionRequest true "生成题目请求"
// @Success 200 {object} Response{data=dto.AIGenerateQuestionResponse}
// @Failure 400 {object} Response
// @Failure 500 {object} Response
// @Router /api/v1/ai/generate-question [post]
func (h *AIHandler) GenerateQuestion(c *gin.Context) {
	var req dto.AIGenerateQuestionRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		ErrorResponse(c, http.StatusBadRequest, 1000, "参数错误: "+err.Error())
		return
	}

	resp, err := h.aiService.GenerateQuestion(c.Request.Context(), &req)
	if err != nil {
		ErrorResponse(c, http.StatusInternalServerError, 4000, "AI生成题目失败: "+err.Error())
		return
	}

	SuccessResponse(c, resp)
}

// GradeAnswer AI批改答案
// @Summary AI批改答案
// @Description 使用AI批改学生答案并给出详细反馈
// @Tags AI
// @Security Bearer
// @Accept json
// @Produce json
// @Param request body dto.AIGradeAnswerRequest true "批改答案请求"
// @Success 200 {object} Response{data=dto.AIGradeAnswerResponse}
// @Failure 400 {object} Response
// @Failure 500 {object} Response
// @Router /api/v1/ai/grade [post]
func (h *AIHandler) GradeAnswer(c *gin.Context) {
	var req dto.AIGradeAnswerRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		ErrorResponse(c, http.StatusBadRequest, 1000, "参数错误: "+err.Error())
		return
	}

	resp, err := h.aiService.GradeAnswer(c.Request.Context(), &req)
	if err != nil {
		ErrorResponse(c, http.StatusInternalServerError, 4000, "AI批改失败: "+err.Error())
		return
	}

	SuccessResponse(c, resp)
}

// Chat AI对话
// @Summary AI对话
// @Description 与AI进行数学辅导对话
// @Tags AI
// @Security Bearer
// @Accept json
// @Produce json
// @Param request body dto.AIChatRequest true "对话请求"
// @Success 200 {object} Response{data=dto.AIChatResponse}
// @Failure 400 {object} Response
// @Failure 401 {object} Response
// @Failure 500 {object} Response
// @Router /api/v1/ai/chat [post]
func (h *AIHandler) Chat(c *gin.Context) {
	// 获取用户ID
	userID, exists := c.Get("user_id")
	if !exists {
		ErrorResponse(c, http.StatusUnauthorized, 1001, "未授权")
		return
	}

	var req dto.AIChatRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		ErrorResponse(c, http.StatusBadRequest, 1000, "参数错误: "+err.Error())
		return
	}

	resp, err := h.aiService.Chat(c.Request.Context(), userID.(uint), &req)
	if err != nil {
		ErrorResponse(c, http.StatusInternalServerError, 4000, "AI对话失败: "+err.Error())
		return
	}

	SuccessResponse(c, resp)
}

// Diagnose AI学习诊断
// @Summary AI学习诊断
// @Description AI分析学习数据并给出诊断报告
// @Tags AI
// @Security Bearer
// @Accept json
// @Produce json
// @Param request body dto.AIDiagnoseRequest true "诊断请求"
// @Success 200 {object} Response{data=dto.AIDiagnoseResponse}
// @Failure 401 {object} Response
// @Failure 500 {object} Response
// @Router /api/v1/ai/diagnose [post]
func (h *AIHandler) Diagnose(c *gin.Context) {
	// 获取用户ID
	userID, exists := c.Get("user_id")
	if !exists {
		ErrorResponse(c, http.StatusUnauthorized, 1001, "未授权")
		return
	}

	var req dto.AIDiagnoseRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		ErrorResponse(c, http.StatusBadRequest, 1000, "参数错误: "+err.Error())
		return
	}

	resp, err := h.aiService.Diagnose(c.Request.Context(), userID.(uint), &req)
	if err != nil {
		ErrorResponse(c, http.StatusInternalServerError, 4000, "AI诊断失败: "+err.Error())
		return
	}

	SuccessResponse(c, resp)
}

// Explain AI解题讲解
// @Summary AI解题讲解
// @Description AI对题目进行详细讲解
// @Tags AI
// @Security Bearer
// @Accept json
// @Produce json
// @Param request body dto.AIExplainRequest true "讲解请求"
// @Success 200 {object} Response{data=dto.AIExplainResponse}
// @Failure 400 {object} Response
// @Failure 500 {object} Response
// @Router /api/v1/ai/explain [post]
func (h *AIHandler) Explain(c *gin.Context) {
	var req dto.AIExplainRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		ErrorResponse(c, http.StatusBadRequest, 1000, "参数错误: "+err.Error())
		return
	}

	resp, err := h.aiService.Explain(c.Request.Context(), &req)
	if err != nil {
		ErrorResponse(c, http.StatusInternalServerError, 4000, "AI讲解失败: "+err.Error())
		return
	}

	SuccessResponse(c, resp)
}
