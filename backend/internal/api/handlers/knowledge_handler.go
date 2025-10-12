package handlers

import (
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"
	"github.com/qiudl/bblearning-backend/internal/domain/dto"
	"github.com/qiudl/bblearning-backend/internal/service/knowledge"
)

// KnowledgeHandler 知识点处理器
type KnowledgeHandler struct {
	knowledgeService *knowledge.KnowledgeService
}

// NewKnowledgeHandler 创建知识点处理器
func NewKnowledgeHandler(knowledgeService *knowledge.KnowledgeService) *KnowledgeHandler {
	return &KnowledgeHandler{
		knowledgeService: knowledgeService,
	}
}

// GetChapterList 获取章节列表
// @Summary 获取章节列表
// @Description 根据条件查询章节列表(支持按年级、科目、学期筛选)
// @Tags 知识点
// @Accept json
// @Produce json
// @Param grade query string false "年级" Enums(7, 8, 9)
// @Param subject query string false "科目"
// @Param semester query string false "学期" Enums(first, second)
// @Param page query int false "页码" default(1)
// @Param page_size query int false "每页数量" default(20)
// @Success 200 {object} Response{data=dto.ChapterListResponse}
// @Failure 400 {object} Response
// @Router /api/v1/chapters [get]
func (h *KnowledgeHandler) GetChapterList(c *gin.Context) {
	var req dto.ChapterListRequest
	if err := c.ShouldBindQuery(&req); err != nil {
		ErrorResponse(c, http.StatusBadRequest, 1000, "参数错误: "+err.Error())
		return
	}

	resp, err := h.knowledgeService.GetChapterList(c.Request.Context(), &req)
	if err != nil {
		ErrorResponse(c, http.StatusInternalServerError, 3000, err.Error())
		return
	}

	SuccessResponse(c, resp)
}

// GetChapterDetail 获取章节详情
// @Summary 获取章节详情
// @Description 获取章节详情(包含知识点列表)
// @Tags 知识点
// @Produce json
// @Param id path int true "章节ID"
// @Success 200 {object} Response{data=dto.ChapterDetailResponse}
// @Failure 404 {object} Response
// @Router /api/v1/chapters/{id} [get]
func (h *KnowledgeHandler) GetChapterDetail(c *gin.Context) {
	idStr := c.Param("id")
	id, err := strconv.ParseUint(idStr, 10, 32)
	if err != nil {
		ErrorResponse(c, http.StatusBadRequest, 1000, "无效的章节ID")
		return
	}

	detail, err := h.knowledgeService.GetChapterDetail(c.Request.Context(), uint(id))
	if err != nil {
		ErrorResponse(c, http.StatusNotFound, 2000, err.Error())
		return
	}

	SuccessResponse(c, detail)
}

// GetKnowledgePointList 获取知识点列表
// @Summary 获取知识点列表
// @Description 根据条件查询知识点列表
// @Tags 知识点
// @Security Bearer
// @Produce json
// @Param chapter_id query int false "章节ID"
// @Param grade query string false "年级" Enums(7, 8, 9)
// @Param type query string false "类型" Enums(concept, theorem, formula, skill)
// @Param difficulty query string false "难度" Enums(basic, medium, advanced)
// @Param page query int false "页码" default(1)
// @Param page_size query int false "每页数量" default(20)
// @Success 200 {object} Response{data=dto.KnowledgePointListResponse}
// @Failure 400 {object} Response
// @Router /api/v1/knowledge-points [get]
func (h *KnowledgeHandler) GetKnowledgePointList(c *gin.Context) {
	var req dto.KnowledgePointListRequest
	if err := c.ShouldBindQuery(&req); err != nil {
		ErrorResponse(c, http.StatusBadRequest, 1000, "参数错误: "+err.Error())
		return
	}

	// 获取用户ID(可选)
	var userID uint
	if uid, exists := c.Get("user_id"); exists {
		userID = uid.(uint)
	}

	resp, err := h.knowledgeService.GetKnowledgePointList(c.Request.Context(), &req, userID)
	if err != nil {
		ErrorResponse(c, http.StatusInternalServerError, 3000, err.Error())
		return
	}

	SuccessResponse(c, resp)
}

// GetKnowledgePointDetail 获取知识点详情
// @Summary 获取知识点详情
// @Description 获取知识点详情(包含子知识点)
// @Tags 知识点
// @Security Bearer
// @Produce json
// @Param id path int true "知识点ID"
// @Success 200 {object} Response{data=dto.KnowledgePointInfo}
// @Failure 404 {object} Response
// @Router /api/v1/knowledge-points/{id} [get]
func (h *KnowledgeHandler) GetKnowledgePointDetail(c *gin.Context) {
	idStr := c.Param("id")
	id, err := strconv.ParseUint(idStr, 10, 32)
	if err != nil {
		ErrorResponse(c, http.StatusBadRequest, 1000, "无效的知识点ID")
		return
	}

	// 获取用户ID(可选)
	var userID uint
	if uid, exists := c.Get("user_id"); exists {
		userID = uid.(uint)
	}

	detail, err := h.knowledgeService.GetKnowledgePointDetail(c.Request.Context(), uint(id), userID)
	if err != nil {
		ErrorResponse(c, http.StatusNotFound, 2000, err.Error())
		return
	}

	SuccessResponse(c, detail)
}

// GetKnowledgeTree 获取知识树
// @Summary 获取知识树
// @Description 获取指定年级的完整知识树结构
// @Tags 知识点
// @Security Bearer
// @Produce json
// @Param grade query string true "年级" Enums(7, 8, 9)
// @Param chapter_id query int false "章节ID(可选,用于只获取某章节)"
// @Success 200 {object} Response{data=dto.KnowledgeTreeResponse}
// @Failure 400 {object} Response
// @Router /api/v1/knowledge/tree [get]
func (h *KnowledgeHandler) GetKnowledgeTree(c *gin.Context) {
	var req dto.KnowledgeTreeRequest
	if err := c.ShouldBindQuery(&req); err != nil {
		ErrorResponse(c, http.StatusBadRequest, 1000, "参数错误: "+err.Error())
		return
	}

	// 获取用户ID(可选)
	var userID uint
	if uid, exists := c.Get("user_id"); exists {
		userID = uid.(uint)
	}

	tree, err := h.knowledgeService.GetKnowledgeTree(c.Request.Context(), req.Grade, userID)
	if err != nil {
		ErrorResponse(c, http.StatusInternalServerError, 3000, err.Error())
		return
	}

	SuccessResponse(c, tree)
}

// UpdateLearningProgress 更新学习进度
// @Summary 更新学习进度
// @Description 更新用户对某知识点的学习进度
// @Tags 学习进度
// @Security Bearer
// @Accept json
// @Produce json
// @Param request body dto.LearningProgressRequest true "学习进度信息"
// @Success 200 {object} Response
// @Failure 400 {object} Response
// @Router /api/v1/learning/progress [put]
func (h *KnowledgeHandler) UpdateLearningProgress(c *gin.Context) {
	// 获取用户ID
	userID, exists := c.Get("user_id")
	if !exists {
		ErrorResponse(c, http.StatusUnauthorized, 1001, "未授权")
		return
	}

	var req dto.LearningProgressRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		ErrorResponse(c, http.StatusBadRequest, 1000, "参数错误: "+err.Error())
		return
	}

	err := h.knowledgeService.UpdateLearningProgress(c.Request.Context(), userID.(uint), &req)
	if err != nil {
		ErrorResponse(c, http.StatusBadRequest, 1000, err.Error())
		return
	}

	SuccessResponse(c, gin.H{"message": "学习进度更新成功"})
}

// GetUserProgress 获取用户学习进度
// @Summary 获取用户学习进度
// @Description 获取当前用户的学习进度列表
// @Tags 学习进度
// @Security Bearer
// @Produce json
// @Param page query int false "页码" default(1)
// @Param page_size query int false "每页数量" default(20)
// @Success 200 {object} Response{data=dto.UserProgressListResponse}
// @Failure 401 {object} Response
// @Router /api/v1/learning/progress [get]
func (h *KnowledgeHandler) GetUserProgress(c *gin.Context) {
	// 获取用户ID
	userID, exists := c.Get("user_id")
	if !exists {
		ErrorResponse(c, http.StatusUnauthorized, 1001, "未授权")
		return
	}

	// 解析分页参数
	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	pageSize, _ := strconv.Atoi(c.DefaultQuery("page_size", "20"))

	resp, err := h.knowledgeService.GetUserProgress(c.Request.Context(), userID.(uint), page, pageSize)
	if err != nil {
		ErrorResponse(c, http.StatusInternalServerError, 3000, err.Error())
		return
	}

	SuccessResponse(c, resp)
}
