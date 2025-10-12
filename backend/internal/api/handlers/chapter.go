package handlers

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/qiudl/bblearning-backend/internal/domain/dto"
)

// GetChapters 获取章节列表
func GetChapters(c *gin.Context) {
	// TODO: 从数据库获取章节列表
	chapters := []gin.H{
		{
			"id":          1,
			"name":        "三角形",
			"description": "学习三角形的基本性质和判定",
			"order":       1,
		},
		{
			"id":          2,
			"name":        "整式的乘除",
			"description": "学习整式的乘法和除法运算",
			"order":       2,
		},
		{
			"id":          3,
			"name":        "因式分解",
			"description": "学习因式分解的方法",
			"order":       3,
		},
	}

	c.JSON(http.StatusOK, dto.Success(chapters))
}

// GetChapter 获取单个章节详情
func GetChapter(c *gin.Context) {
	id := c.Param("id")

	// TODO: 从数据库获取章节详情
	chapter := gin.H{
		"id":          id,
		"name":        "三角形",
		"description": "学习三角形的基本性质和判定",
		"order":       1,
	}

	c.JSON(http.StatusOK, dto.Success(chapter))
}
