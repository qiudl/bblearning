package handlers

import (
	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

// Response 统一响应结构
type Response struct {
	Code      int         `json:"code"`                // 0=成功, 其他=错误码
	Message   string      `json:"message"`             // 提示信息
	Data      interface{} `json:"data,omitempty"`      // 响应数据
	RequestID string      `json:"request_id,omitempty"` // 请求ID(用于追踪)
}

// SuccessResponse 成功响应
func SuccessResponse(c *gin.Context, data interface{}) {
	c.JSON(200, Response{
		Code:      0,
		Message:   "success",
		Data:      data,
		RequestID: getRequestID(c),
	})
}

// ErrorResponse 错误响应
func ErrorResponse(c *gin.Context, httpStatus int, code int, message string) {
	c.JSON(httpStatus, Response{
		Code:      code,
		Message:   message,
		RequestID: getRequestID(c),
	})
}

// getRequestID 获取或生成请求ID
func getRequestID(c *gin.Context) string {
	requestID := c.GetString("request_id")
	if requestID == "" {
		requestID = uuid.New().String()
	}
	return requestID
}
