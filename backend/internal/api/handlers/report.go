package handlers

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/qiudl/bblearning-backend/internal/domain/dto"
)

// GetLearningReport 获取学习报告
func GetLearningReport(c *gin.Context) {
	userID, _ := c.Get("userId")

	// TODO: 从数据库生成学习报告
	report := gin.H{
		"userId":          userID,
		"studyDays":       15,
		"totalQuestions":  120,
		"correctRate":     0.85,
		"weeklyQuestions": 45,
		"suggestions":     []string{"建议加强因式分解的练习"},
	}

	c.JSON(http.StatusOK, dto.Success(report))
}

// GetWeakPoints 获取薄弱知识点
func GetWeakPoints(c *gin.Context) {
	userID, _ := c.Get("userId")

	// TODO: 分析并返回薄弱知识点
	weakPoints := []gin.H{
		{
			"knowledgePointId":   3,
			"knowledgePointName": "全等三角形",
			"correctRate":        0.45,
			"questionCount":      20,
		},
	}

	_ = userID

	c.JSON(http.StatusOK, dto.Success(weakPoints))
}

// GetProgress 获取学习进度
func GetProgress(c *gin.Context) {
	userID, _ := c.Get("userId")

	// TODO: 从数据库获取学习进度
	progress := gin.H{
		"userId":              userID,
		"todayStudyTime":      45,
		"continuousDays":      7,
		"weeklyQuestions":     50,
		"overallCorrectRate":  0.82,
		"knowledgePointProgress": []gin.H{
			{
				"knowledgePointId":   1,
				"knowledgePointName": "三角形的边",
				"masteryLevel":       85,
			},
		},
	}

	c.JSON(http.StatusOK, dto.Success(progress))
}
