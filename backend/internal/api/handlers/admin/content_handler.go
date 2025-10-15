package admin

import (
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"
	"github.com/qiudl/bblearning-backend/internal/domain/models"
	"github.com/qiudl/bblearning-backend/internal/service/admin"
)

// ContentHandler 内容管理处理器
type ContentHandler struct {
	contentService *admin.ContentService
}

// NewContentHandler 创建内容管理处理器
func NewContentHandler(contentService *admin.ContentService) *ContentHandler {
	return &ContentHandler{
		contentService: contentService,
	}
}

// GetChapterList 获取章节列表
// @Summary 获取章节列表
// @Description 管理员获取所有章节列表
// @Tags Admin - Content
// @Security BearerAuth
// @Param grade query int false "年级筛选"
// @Success 200 {object} models.Response{data=[]models.Chapter}
// @Router /api/v1/admin/chapters [get]
func (h *ContentHandler) GetChapterList(c *gin.Context) {
	var grade int
	if g := c.Query("grade"); g != "" {
		if parsed, err := strconv.Atoi(g); err == nil {
			grade = parsed
		}
	}

	chapters, err := h.contentService.GetChapterList(c.Request.Context(), grade)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"code":    5000,
			"message": "获取章节列表失败",
			"error":   err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"code":    0,
		"message": "success",
		"data":    chapters,
	})
}

// CreateChapter 创建章节
// @Summary 创建章节
// @Description 管理员创建新章节
// @Tags Admin - Content
// @Security BearerAuth
// @Param request body models.CreateChapterRequest true "章节创建请求"
// @Success 200 {object} models.Response{data=models.Chapter}
// @Router /api/v1/admin/chapters [post]
func (h *ContentHandler) CreateChapter(c *gin.Context) {
	var req models.CreateChapterRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"code":    1000,
			"message": "请求参数错误",
			"error":   err.Error(),
		})
		return
	}

	adminID, _ := c.Get("user_id")

	chapter, err := h.contentService.CreateChapter(c.Request.Context(), &req, adminID.(uint))
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"code":    5000,
			"message": "创建章节失败",
			"error":   err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"code":    0,
		"message": "章节创建成功",
		"data":    chapter,
	})
}

// UpdateChapter 更新章节
// @Summary 更新章节
// @Description 管理员更新章节信息
// @Tags Admin - Content
// @Security BearerAuth
// @Param id path int true "章节ID"
// @Param request body models.UpdateChapterRequest true "章节更新请求"
// @Success 200 {object} models.Response
// @Router /api/v1/admin/chapters/{id} [put]
func (h *ContentHandler) UpdateChapter(c *gin.Context) {
	chapterID, err := strconv.ParseUint(c.Param("id"), 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"code":    1000,
			"message": "无效的章节ID",
		})
		return
	}

	var req models.UpdateChapterRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"code":    1000,
			"message": "请求参数错误",
			"error":   err.Error(),
		})
		return
	}

	adminID, _ := c.Get("user_id")

	err = h.contentService.UpdateChapter(c.Request.Context(), uint(chapterID), &req, adminID.(uint))
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"code":    5000,
			"message": "更新章节失败",
			"error":   err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"code":    0,
		"message": "章节更新成功",
	})
}

// DeleteChapter 删除章节
// @Summary 删除章节
// @Description 管理员删除章节(软删除)
// @Tags Admin - Content
// @Security BearerAuth
// @Param id path int true "章节ID"
// @Success 200 {object} models.Response
// @Router /api/v1/admin/chapters/{id} [delete]
func (h *ContentHandler) DeleteChapter(c *gin.Context) {
	chapterID, err := strconv.ParseUint(c.Param("id"), 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"code":    1000,
			"message": "无效的章节ID",
		})
		return
	}

	adminID, _ := c.Get("user_id")

	err = h.contentService.DeleteChapter(c.Request.Context(), uint(chapterID), adminID.(uint))
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"code":    5000,
			"message": "删除章节失败",
			"error":   err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"code":    0,
		"message": "章节删除成功",
	})
}

// GetKnowledgePointList 获取知识点列表
// @Summary 获取知识点列表
// @Description 管理员获取知识点列表(支持章节筛选)
// @Tags Admin - Content
// @Security BearerAuth
// @Param chapterId query int false "章节ID"
// @Param parentId query int false "父知识点ID"
// @Success 200 {object} models.Response{data=[]models.KnowledgePoint}
// @Router /api/v1/admin/knowledge-points [get]
func (h *ContentHandler) GetKnowledgePointList(c *gin.Context) {
	var chapterID, parentID uint

	if id := c.Query("chapterId"); id != "" {
		if parsed, err := strconv.ParseUint(id, 10, 32); err == nil {
			chapterID = uint(parsed)
		}
	}

	if id := c.Query("parentId"); id != "" {
		if parsed, err := strconv.ParseUint(id, 10, 32); err == nil {
			parentID = uint(parsed)
		}
	}

	knowledgePoints, err := h.contentService.GetKnowledgePointList(c.Request.Context(), chapterID, parentID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"code":    5000,
			"message": "获取知识点列表失败",
			"error":   err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"code":    0,
		"message": "success",
		"data":    knowledgePoints,
	})
}

// CreateKnowledgePoint 创建知识点
// @Summary 创建知识点
// @Description 管理员创建新知识点
// @Tags Admin - Content
// @Security BearerAuth
// @Param request body models.CreateKnowledgePointRequest true "知识点创建请求"
// @Success 200 {object} models.Response{data=models.KnowledgePoint}
// @Router /api/v1/admin/knowledge-points [post]
func (h *ContentHandler) CreateKnowledgePoint(c *gin.Context) {
	var req models.CreateKnowledgePointRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"code":    1000,
			"message": "请求参数错误",
			"error":   err.Error(),
		})
		return
	}

	adminID, _ := c.Get("user_id")

	kp, err := h.contentService.CreateKnowledgePoint(c.Request.Context(), &req, adminID.(uint))
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"code":    5000,
			"message": "创建知识点失败",
			"error":   err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"code":    0,
		"message": "知识点创建成功",
		"data":    kp,
	})
}

// UpdateKnowledgePoint 更新知识点
// @Summary 更新知识点
// @Description 管理员更新知识点信息
// @Tags Admin - Content
// @Security BearerAuth
// @Param id path int true "知识点ID"
// @Param request body models.UpdateKnowledgePointRequest true "知识点更新请求"
// @Success 200 {object} models.Response
// @Router /api/v1/admin/knowledge-points/{id} [put]
func (h *ContentHandler) UpdateKnowledgePoint(c *gin.Context) {
	kpID, err := strconv.ParseUint(c.Param("id"), 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"code":    1000,
			"message": "无效的知识点ID",
		})
		return
	}

	var req models.UpdateKnowledgePointRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"code":    1000,
			"message": "请求参数错误",
			"error":   err.Error(),
		})
		return
	}

	adminID, _ := c.Get("user_id")

	err = h.contentService.UpdateKnowledgePoint(c.Request.Context(), uint(kpID), &req, adminID.(uint))
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"code":    5000,
			"message": "更新知识点失败",
			"error":   err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"code":    0,
		"message": "知识点更新成功",
	})
}

// DeleteKnowledgePoint 删除知识点
// @Summary 删除知识点
// @Description 管理员删除知识点(软删除)
// @Tags Admin - Content
// @Security BearerAuth
// @Param id path int true "知识点ID"
// @Success 200 {object} models.Response
// @Router /api/v1/admin/knowledge-points/{id} [delete]
func (h *ContentHandler) DeleteKnowledgePoint(c *gin.Context) {
	kpID, err := strconv.ParseUint(c.Param("id"), 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"code":    1000,
			"message": "无效的知识点ID",
		})
		return
	}

	adminID, _ := c.Get("user_id")

	err = h.contentService.DeleteKnowledgePoint(c.Request.Context(), uint(kpID), adminID.(uint))
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"code":    5000,
			"message": "删除知识点失败",
			"error":   err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"code":    0,
		"message": "知识点删除成功",
	})
}
