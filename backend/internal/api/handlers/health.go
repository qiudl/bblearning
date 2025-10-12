package handlers

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/qiudl/bblearning-backend/internal/domain/dto"
)

// HealthCheck 健康检查
func HealthCheck(c *gin.Context) {
	c.JSON(http.StatusOK, dto.Success(gin.H{
		"status": "ok",
		"service": "bblearning-backend",
	}))
}
