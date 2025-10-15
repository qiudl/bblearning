package admin

import (
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"
	"github.com/qiudl/bblearning-backend/internal/domain/models"
	"github.com/qiudl/bblearning-backend/internal/service/admin"
)

// AIQuestionHandler AI问题生成处理器
type AIQuestionHandler struct {
	aiQuestionService *admin.AIQuestionService
}

// NewAIQuestionHandler 创建AI问题生成处理器
func NewAIQuestionHandler(aiQuestionService *admin.AIQuestionService) *AIQuestionHandler {
	return &AIQuestionHandler{
		aiQuestionService: aiQuestionService,
	}
}

// GenerateQuestions AI生成题目
// @Summary AI生成题目
// @Description 管理员使用AI生成指定知识点的练习题
// @Tags Admin - AI Question
// @Security BearerAuth
// @Param request body models.AIGenerateQuestionRequest true "AI生成请求"
// @Success 200 {object} models.Response{data=models.AIGenerateResponse}
// @Router /api/v1/admin/questions/ai-generate [post]
func (h *AIQuestionHandler) GenerateQuestions(c *gin.Context) {
	var req models.AIGenerateQuestionRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"code":    1000,
			"message": "请求参数错误",
			"error":   err.Error(),
		})
		return
	}

	// 验证参数
	if req.KnowledgePointID == 0 {
		c.JSON(http.StatusBadRequest, gin.H{
			"code":    1000,
			"message": "知识点ID不能为空",
		})
		return
	}

	if req.Count <= 0 || req.Count > 10 {
		c.JSON(http.StatusBadRequest, gin.H{
			"code":    1000,
			"message": "生成数量必须在1-10之间",
		})
		return
	}

	// 获取管理员ID
	adminID, _ := c.Get("user_id")

	// 调用AI服务生成题目
	result, err := h.aiQuestionService.GenerateQuestions(c.Request.Context(), &req, adminID.(uint))
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"code":    4000,
			"message": "AI生成题目失败",
			"error":   err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"code":    0,
		"message": "题目生成成功",
		"data":    result,
	})
}

// BatchSaveQuestions 批量保存题目
// @Summary 批量保存AI生成的题目
// @Description 管理员审核后批量保存AI生成的题目到题库
// @Tags Admin - AI Question
// @Security BearerAuth
// @Param request body models.BatchSaveQuestionRequest true "批量保存请求"
// @Success 200 {object} models.Response{data=models.BatchSaveResponse}
// @Router /api/v1/admin/questions/batch-save [post]
func (h *AIQuestionHandler) BatchSaveQuestions(c *gin.Context) {
	var req models.BatchSaveQuestionRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"code":    1000,
			"message": "请求参数错误",
			"error":   err.Error(),
		})
		return
	}

	// 验证参数
	if req.GenerationID == "" {
		c.JSON(http.StatusBadRequest, gin.H{
			"code":    1000,
			"message": "生成记录ID不能为空",
		})
		return
	}

	if len(req.Questions) == 0 {
		c.JSON(http.StatusBadRequest, gin.H{
			"code":    1000,
			"message": "题目列表不能为空",
		})
		return
	}

	// 获取管理员ID
	adminID, _ := c.Get("user_id")

	// 批量保存题目
	result, err := h.aiQuestionService.BatchSaveQuestions(c.Request.Context(), &req, adminID.(uint))
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"code":    5000,
			"message": "批量保存题目失败",
			"error":   err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"code":    0,
		"message": "题目保存成功",
		"data":    result,
	})
}

// GetGenerationHistory 获取生成历史
// @Summary 获取AI题目生成历史
// @Description 管理员查看AI题目生成历史记录
// @Tags Admin - AI Question
// @Security BearerAuth
// @Param page query int false "页码" default(1)
// @Param pageSize query int false "每页数量" default(20)
// @Success 200 {object} models.Response{data=models.PaginatedGenerationHistory}
// @Router /api/v1/admin/questions/generation-history [get]
func (h *AIQuestionHandler) GetGenerationHistory(c *gin.Context) {
	page := 1
	pageSize := 20

	if p := c.Query("page"); p != "" {
		if parsed, err := strconv.Atoi(p); err == nil && parsed > 0 {
			page = parsed
		}
	}

	if ps := c.Query("pageSize"); ps != "" {
		if parsed, err := strconv.Atoi(ps); err == nil && parsed > 0 && parsed <= 100 {
			pageSize = parsed
		}
	}

	result, err := h.aiQuestionService.GetGenerationHistory(c.Request.Context(), page, pageSize)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"code":    5000,
			"message": "获取生成历史失败",
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

// GetQuestionList 获取题目列表
// @Summary 获取题目列表
// @Description 管理员获取题库题目列表
// @Tags Admin - Question
// @Security BearerAuth
// @Param page query int false "页码" default(1)
// @Param pageSize query int false "每页数量" default(20)
// @Param knowledgePointId query int false "知识点ID"
// @Param type query string false "题目类型"
// @Param difficulty query string false "难度"
// @Success 200 {object} models.Response{data=models.PaginatedQuestionList}
// @Router /api/v1/admin/questions [get]
func (h *AIQuestionHandler) GetQuestionList(c *gin.Context) {
	req := &models.QuestionListRequest{
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

	if kpID := c.Query("knowledgePointId"); kpID != "" {
		if id, err := strconv.ParseUint(kpID, 10, 32); err == nil {
			req.KnowledgePointID = uint(id)
		}
	}

	req.Type = c.Query("type")
	req.Difficulty = c.Query("difficulty")

	result, err := h.aiQuestionService.GetQuestionList(c.Request.Context(), req)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"code":    5000,
			"message": "获取题目列表失败",
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

// UpdateQuestion 更新题目
// @Summary 更新题目
// @Description 管理员更新题目内容
// @Tags Admin - Question
// @Security BearerAuth
// @Param id path int true "题目ID"
// @Param request body models.UpdateQuestionRequest true "更新请求"
// @Success 200 {object} models.Response
// @Router /api/v1/admin/questions/{id} [put]
func (h *AIQuestionHandler) UpdateQuestion(c *gin.Context) {
	questionID, err := strconv.ParseUint(c.Param("id"), 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"code":    1000,
			"message": "无效的题目ID",
		})
		return
	}

	var req models.UpdateQuestionRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"code":    1000,
			"message": "请求参数错误",
			"error":   err.Error(),
		})
		return
	}

	// 获取管理员ID
	adminID, _ := c.Get("user_id")

	err = h.aiQuestionService.UpdateQuestion(c.Request.Context(), uint(questionID), &req, adminID.(uint))
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"code":    5000,
			"message": "更新题目失败",
			"error":   err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"code":    0,
		"message": "题目更新成功",
	})
}

// DeleteQuestion 删除题目
// @Summary 删除题目
// @Description 管理员删除题目(软删除)
// @Tags Admin - Question
// @Security BearerAuth
// @Param id path int true "题目ID"
// @Success 200 {object} models.Response
// @Router /api/v1/admin/questions/{id} [delete]
func (h *AIQuestionHandler) DeleteQuestion(c *gin.Context) {
	questionID, err := strconv.ParseUint(c.Param("id"), 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"code":    1000,
			"message": "无效的题目ID",
		})
		return
	}

	// 获取管理员ID
	adminID, _ := c.Get("user_id")

	err = h.aiQuestionService.DeleteQuestion(c.Request.Context(), uint(questionID), adminID.(uint))
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"code":    5000,
			"message": "删除题目失败",
			"error":   err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"code":    0,
		"message": "题目删除成功",
	})
}
