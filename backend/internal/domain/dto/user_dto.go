package dto

import "github.com/qiudl/bblearning-backend/internal/domain/models"

// RegisterRequest 注册请求
type RegisterRequest struct {
	Username string `json:"username" binding:"required,min=3,max=50"`
	Password string `json:"password" binding:"required,min=6"`
	Nickname string `json:"nickname"`
	Grade    string `json:"grade" binding:"required,oneof=7 8 9"`
}

// RegisterResponse 注册响应
type RegisterResponse struct {
	User         *UserInfo `json:"user"`
	AccessToken  string    `json:"access_token"`
	RefreshToken string    `json:"refresh_token"`
}

// LoginRequest 登录请求
type LoginRequest struct {
	Username string `json:"username" binding:"required"`
	Password string `json:"password" binding:"required"`
}

// LoginResponse 登录响应
type LoginResponse struct {
	User         *UserInfo `json:"user"`
	AccessToken  string    `json:"access_token"`
	RefreshToken string    `json:"refresh_token"`
}

// RefreshTokenRequest 刷新令牌请求
type RefreshTokenRequest struct {
	RefreshToken string `json:"refresh_token" binding:"required"`
}

// RefreshTokenResponse 刷新令牌响应
type RefreshTokenResponse struct {
	AccessToken string `json:"access_token"`
}

// UserInfo 用户信息(不包含密码)
type UserInfo struct {
	ID          uint   `json:"id"`
	Username    string `json:"username"`
	Nickname    string `json:"nickname"`
	PhoneNumber string `json:"phone_number"`
	Email       string `json:"email"`
	Grade       string `json:"grade"`
	Avatar      string `json:"avatar"`
	Role        string `json:"role"`
	Status      string `json:"status"`
}

// ToUserInfo 将User模型转换为UserInfo
func ToUserInfo(user *models.User) *UserInfo {
	if user == nil {
		return nil
	}
	return &UserInfo{
		ID:          user.ID,
		Username:    user.Username,
		Nickname:    user.Nickname,
		PhoneNumber: user.PhoneNumber,
		Email:       user.Email,
		Grade:       user.Grade,
		Avatar:      user.Avatar,
		Role:        user.Role,
		Status:      user.Status,
	}
}

// UpdateUserRequest 更新用户信息请求
type UpdateUserRequest struct {
	Nickname    *string `json:"nickname"`
	PhoneNumber *string `json:"phone_number"`
	Email       *string `json:"email"`
	Avatar      *string `json:"avatar"`
}

// ChangePasswordRequest 修改密码请求
type ChangePasswordRequest struct {
	OldPassword string `json:"old_password" binding:"required"`
	NewPassword string `json:"new_password" binding:"required,min=6"`
}
