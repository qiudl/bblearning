package handlers

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/qiudl/bblearning-backend/internal/domain/dto"
)

// GeneratePractice 生成练习题
func GeneratePractice(c *gin.Context) {
	type GenerateRequest struct {
		KnowledgePointID uint `json:"knowledgePointId"`
		Count            int  `json:"count"`
		Difficulty       string `json:"difficulty"`
	}

	var req GenerateRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, dto.Error(1000, "参数错误"))
		return
	}

	// TODO: 从数据库或AI生成题目
	questions := []gin.H{
		{
			"id":               1,
			"knowledgePointId": req.KnowledgePointID,
			"type":             "choice",
			"content":          "三角形的两边长分别为3和5，第三边的长度可能是（）",
			"options":          []string{"A. 1", "B. 2", "C. 6", "D. 9"},
			"answer":           "C",
			"explanation":      "详细解析...",
			"difficulty":       "medium",
		},
	}

	c.JSON(http.StatusOK, dto.Success(questions))
}

// SubmitPractice 提交练习答案
func SubmitPractice(c *gin.Context) {
	type SubmitRequest struct {
		QuestionID uint   `json:"questionId"`
		UserAnswer string `json:"userAnswer"`
	}

	var req SubmitRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, dto.Error(1000, "参数错误"))
		return
	}

	userID, _ := c.Get("userId")

	// TODO: 保存练习记录，判断正误，更新学习进度
	isCorrect := req.UserAnswer == "C" // Mock

	c.JSON(http.StatusOK, dto.Success(gin.H{
		"isCorrect":  isCorrect,
		"userId":     userID,
		"questionId": req.QuestionID,
		"explanation": "详细解析...",
	}))
}

// GetPracticeRecords 获取练习记录
func GetPracticeRecords(c *gin.Context) {
	userID, _ := c.Get("userId")

	// TODO: 从数据库获取练习记录
	records := []gin.H{
		{
			"id":         1,
			"userId":     userID,
			"questionId": 1,
			"userAnswer": "C",
			"isCorrect":  true,
			"timestamp":  "2025-10-12T19:00:00Z",
		},
	}

	c.JSON(http.StatusOK, dto.Success(records))
}
