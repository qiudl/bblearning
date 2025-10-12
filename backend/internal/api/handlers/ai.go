package handlers

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/qiudl/bblearning-backend/internal/domain/dto"
)

// AIChat AI问答
func AIChat(c *gin.Context) {
	type ChatRequest struct {
		Message string   `json:"message" binding:"required"`
		Images  []string `json:"images"`
	}

	var req ChatRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, dto.Error(1000, "参数错误"))
		return
	}

	// TODO: 调用AI服务进行问答
	response := gin.H{
		"role":    "assistant",
		"content": "这是AI的回复内容...",
	}

	c.JSON(http.StatusOK, dto.Success(response))
}

// AIOCR OCR识别题目
func AIOCR(c *gin.Context) {
	type OCRRequest struct {
		Image string `json:"image" binding:"required"`
	}

	var req OCRRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, dto.Error(1000, "参数错误"))
		return
	}

	// TODO: 调用OCR服务识别图片中的题目
	result := gin.H{
		"text": "识别出的题目文字...",
	}

	c.JSON(http.StatusOK, dto.Success(result))
}
