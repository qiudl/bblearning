package handlers

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/qiudl/bblearning-backend/internal/domain/dto"
)

// GetWrongQuestions 获取错题列表
func GetWrongQuestions(c *gin.Context) {
	userID, _ := c.Get("userId")

	// TODO: 从数据库获取错题列表
	wrongQuestions := []gin.H{
		{
			"id":            1,
			"userId":        userID,
			"questionId":    1,
			"wrongCount":    2,
			"lastWrongTime": "2025-10-12T19:00:00Z",
		},
	}

	c.JSON(http.StatusOK, dto.Success(wrongQuestions))
}

// GetWrongQuestion 获取单个错题详情
func GetWrongQuestion(c *gin.Context) {
	id := c.Param("id")

	// TODO: 从数据库获取错题详情
	wrongQuestion := gin.H{
		"id":            id,
		"wrongCount":    2,
		"lastWrongTime": "2025-10-12T19:00:00Z",
		"question": gin.H{
			"id":      1,
			"content": "题目内容...",
			"answer":  "正确答案",
		},
	}

	c.JSON(http.StatusOK, dto.Success(wrongQuestion))
}

// DeleteWrongQuestion 删除错题（标记为已解决）
func DeleteWrongQuestion(c *gin.Context) {
	id := c.Param("id")

	// TODO: 从数据库删除或标记错题
	_ = id

	c.JSON(http.StatusOK, dto.Success(gin.H{
		"message": "删除成功",
	}))
}
