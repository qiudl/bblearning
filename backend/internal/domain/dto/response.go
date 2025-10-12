package dto

// Response 通用响应结构
type Response struct {
	Code      int         `json:"code"`
	Message   string      `json:"message"`
	Data      interface{} `json:"data,omitempty"`
	RequestID string      `json:"requestId,omitempty"`
}

// Success 成功响应
func Success(data interface{}) *Response {
	return &Response{
		Code:    0,
		Message: "success",
		Data:    data,
	}
}

// Error 错误响应
func Error(code int, message string) *Response {
	return &Response{
		Code:    code,
		Message: message,
	}
}

// Pagination 分页信息
type Pagination struct {
	Page  int `json:"page"`
	Size  int `json:"size"`
	Total int64 `json:"total"`
}

// PagedResponse 分页响应
type PagedResponse struct {
	List       interface{} `json:"list"`
	Pagination *Pagination `json:"pagination"`
}
