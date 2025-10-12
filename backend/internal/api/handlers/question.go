package handlers

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/qiudl/bblearning-backend/internal/domain/dto"
)

// GetQuestions 获取题目列表
func GetQuestions(c *gin.Context) {
	knowledgePointId := c.Query("knowledgePointId")

	// TODO: 从数据库获取题目列表
	questions := []gin.H{
		{
			"id":               1,
			"knowledgePointId": 1,
			"type":             "choice",
			"content":          "三角形的两边长分别为3和5，第三边的长度可能是（）",
			"options":          []string{"A. 1", "B. 2", "C. 6", "D. 9"},
			"answer":           "C",
			"explanation":      "根据三角形两边之和大于第三边，两边之差小于第三边的性质...",
			"difficulty":       "medium",
		},
	}

	_ = knowledgePointId

	c.JSON(http.StatusOK, dto.Success(questions))
}

// GetQuestion 获取单个题目
func GetQuestion(c *gin.Context) {
	id := c.Param("id")

	// TODO: 从数据库获取题目详情
	question := gin.H{
		"id":               id,
		"knowledgePointId": 1,
		"type":             "choice",
		"content":          "三角形的两边长分别为3和5，第三边的长度可能是（）",
		"options":          []string{"A. 1", "B. 2", "C. 6", "D. 9"},
		"answer":           "C",
		"explanation":      "根据三角形两边之和大于第三边...",
		"difficulty":       "medium",
	}

	c.JSON(http.StatusOK, dto.Success(question))
}
