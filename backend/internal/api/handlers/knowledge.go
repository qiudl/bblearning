package handlers

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/qiudl/bblearning-backend/internal/domain/dto"
)

// GetKnowledgePoints 获取知识点列表
func GetKnowledgePoints(c *gin.Context) {
	chapterId := c.Query("chapterId")

	// TODO: 从数据库获取知识点列表
	knowledgePoints := []gin.H{
		{
			"id":           1,
			"chapterId":    1,
			"name":         "三角形的边",
			"content":      "三角形任意两边之和大于第三边",
			"difficulty":   "basic",
			"masteryLevel": 85,
		},
		{
			"id":           2,
			"chapterId":    1,
			"name":         "三角形的角",
			"content":      "三角形内角和为180度",
			"difficulty":   "basic",
			"masteryLevel": 90,
		},
	}

	_ = chapterId // 避免编译警告

	c.JSON(http.StatusOK, dto.Success(knowledgePoints))
}

// GetKnowledgePoint 获取知识点详情
func GetKnowledgePoint(c *gin.Context) {
	id := c.Param("id")

	// TODO: 从数据库获取知识点详情
	knowledgePoint := gin.H{
		"id":           id,
		"chapterId":    1,
		"name":         "三角形的边",
		"content":      "三角形任意两边之和大于第三边",
		"videoUrl":     "",
		"difficulty":   "basic",
		"masteryLevel": 85,
	}

	c.JSON(http.StatusOK, dto.Success(knowledgePoint))
}
