package handlers

import (
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"
	"github.com/qiudl/bblearning-backend/internal/domain/dto"
	"github.com/qiudl/bblearning-backend/internal/pkg/auth"
	"github.com/qiudl/bblearning-backend/internal/service/user"
)

// AuthHandler 认证处理器
type AuthHandler struct {
	authService *user.AuthService
}

// NewAuthHandler 创建认证处理器
func NewAuthHandler(authService *user.AuthService) *AuthHandler {
	return &AuthHandler{
		authService: authService,
	}
}

// Register 用户注册
// @Summary 用户注册
// @Description 注册新用户账号
// @Tags 认证
// @Accept json
// @Produce json
// @Param request body dto.RegisterRequest true "注册信息"
// @Success 200 {object} Response{data=dto.RegisterResponse}
// @Failure 400 {object} Response
// @Router /api/v1/auth/register [post]
func (h *AuthHandler) Register(c *gin.Context) {
	var req dto.RegisterRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		ErrorResponse(c, http.StatusBadRequest, 1000, "参数错误: "+err.Error())
		return
	}

	resp, err := h.authService.Register(c.Request.Context(), &req)
	if err != nil {
		ErrorResponse(c, http.StatusBadRequest, 1000, err.Error())
		return
	}

	SuccessResponse(c, resp)
}

// Login 用户登录
// @Summary 用户登录
// @Description 用户登录获取令牌
// @Tags 认证
// @Accept json
// @Produce json
// @Param request body dto.LoginRequest true "登录信息"
// @Success 200 {object} Response{data=dto.LoginResponse}
// @Failure 401 {object} Response
// @Router /api/v1/auth/login [post]
func (h *AuthHandler) Login(c *gin.Context) {
	var req dto.LoginRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		ErrorResponse(c, http.StatusBadRequest, 1000, "参数错误: "+err.Error())
		return
	}

	resp, err := h.authService.Login(c.Request.Context(), &req)
	if err != nil {
		ErrorResponse(c, http.StatusUnauthorized, 1001, err.Error())
		return
	}

	SuccessResponse(c, resp)
}

// RefreshToken 刷新令牌
// @Summary 刷新访问令牌
// @Description 使用刷新令牌获取新的访问令牌
// @Tags 认证
// @Accept json
// @Produce json
// @Param request body dto.RefreshTokenRequest true "刷新令牌"
// @Success 200 {object} Response{data=dto.RefreshTokenResponse}
// @Failure 401 {object} Response
// @Router /api/v1/auth/refresh [post]
func (h *AuthHandler) RefreshToken(c *gin.Context) {
	var req dto.RefreshTokenRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		ErrorResponse(c, http.StatusBadRequest, 1000, "参数错误: "+err.Error())
		return
	}

	resp, err := h.authService.RefreshToken(c.Request.Context(), req.RefreshToken)
	if err != nil {
		ErrorResponse(c, http.StatusUnauthorized, 1002, err.Error())
		return
	}

	SuccessResponse(c, resp)
}

// Logout 用户登出
// @Summary 用户登出
// @Description 用户登出，清除缓存
// @Tags 认证
// @Security Bearer
// @Produce json
// @Success 200 {object} Response
// @Failure 401 {object} Response
// @Router /api/v1/auth/logout [post]
func (h *AuthHandler) Logout(c *gin.Context) {
	// 从中间件获取用户ID
	userID, exists := c.Get("user_id")
	if !exists {
		ErrorResponse(c, http.StatusUnauthorized, 1001, "未授权")
		return
	}

	if err := h.authService.Logout(c.Request.Context(), userID.(uint)); err != nil {
		ErrorResponse(c, http.StatusInternalServerError, 3000, "登出失败: "+err.Error())
		return
	}

	SuccessResponse(c, gin.H{"message": "登出成功"})
}

// GetCurrentUser 获取当前用户信息
// @Summary 获取当前用户信息
// @Description 获取当前登录用户的详细信息
// @Tags 用户
// @Security Bearer
// @Produce json
// @Success 200 {object} Response{data=dto.UserInfo}
// @Failure 401 {object} Response
// @Router /api/v1/users/me [get]
func (h *AuthHandler) GetCurrentUser(c *gin.Context) {
	// 从中间件获取用户ID
	userID, exists := c.Get("user_id")
	if !exists {
		ErrorResponse(c, http.StatusUnauthorized, 1001, "未授权")
		return
	}

	userInfo, err := h.authService.GetUserInfo(c.Request.Context(), userID.(uint))
	if err != nil {
		ErrorResponse(c, http.StatusNotFound, 2000, err.Error())
		return
	}

	SuccessResponse(c, userInfo)
}

// UpdateCurrentUser 更新当前用户信息
// @Summary 更新当前用户信息
// @Description 更新当前登录用户的信息
// @Tags 用户
// @Security Bearer
// @Accept json
// @Produce json
// @Param request body dto.UpdateUserRequest true "更新信息"
// @Success 200 {object} Response
// @Failure 400 {object} Response
// @Router /api/v1/users/me [put]
func (h *AuthHandler) UpdateCurrentUser(c *gin.Context) {
	// 从中间件获取用户ID
	userID, exists := c.Get("user_id")
	if !exists {
		ErrorResponse(c, http.StatusUnauthorized, 1001, "未授权")
		return
	}

	var req dto.UpdateUserRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		ErrorResponse(c, http.StatusBadRequest, 1000, "参数错误: "+err.Error())
		return
	}

	if err := h.authService.UpdateUser(c.Request.Context(), userID.(uint), &req); err != nil {
		ErrorResponse(c, http.StatusBadRequest, 1000, err.Error())
		return
	}

	SuccessResponse(c, gin.H{"message": "更新成功"})
}

// ChangePassword 修改密码
// @Summary 修改密码
// @Description 修改当前用户密码
// @Tags 用户
// @Security Bearer
// @Accept json
// @Produce json
// @Param request body dto.ChangePasswordRequest true "密码信息"
// @Success 200 {object} Response
// @Failure 400 {object} Response
// @Router /api/v1/users/me/password [put]
func (h *AuthHandler) ChangePassword(c *gin.Context) {
	// 从中间件获取用户ID
	userID, exists := c.Get("user_id")
	if !exists {
		ErrorResponse(c, http.StatusUnauthorized, 1001, "未授权")
		return
	}

	var req dto.ChangePasswordRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		ErrorResponse(c, http.StatusBadRequest, 1000, "参数错误: "+err.Error())
		return
	}

	if err := h.authService.ChangePassword(c.Request.Context(), userID.(uint), &req); err != nil {
		ErrorResponse(c, http.StatusBadRequest, 1000, err.Error())
		return
	}

	SuccessResponse(c, gin.H{"message": "密码修改成功"})
}

// VerifyToken 验证令牌
// @Summary 验证令牌
// @Description 验证JWT令牌是否有效
// @Tags 认证
// @Security Bearer
// @Produce json
// @Success 200 {object} Response
// @Failure 401 {object} Response
// @Router /api/v1/auth/verify [get]
func (h *AuthHandler) VerifyToken(c *gin.Context) {
	// 获取Authorization头
	tokenString := c.GetHeader("Authorization")
	if tokenString == "" {
		ErrorResponse(c, http.StatusUnauthorized, 1001, "缺少令牌")
		return
	}

	// 移除 "Bearer " 前缀
	if len(tokenString) > 7 && tokenString[:7] == "Bearer " {
		tokenString = tokenString[7:]
	}

	// 验证令牌
	valid, err := auth.ValidateToken(tokenString)
	if err != nil || !valid {
		ErrorResponse(c, http.StatusUnauthorized, 1002, "令牌无效或已过期")
		return
	}

	// 解析令牌获取用户信息
	claims, err := auth.ParseToken(tokenString)
	if err != nil {
		ErrorResponse(c, http.StatusUnauthorized, 1002, "令牌解析失败")
		return
	}

	SuccessResponse(c, gin.H{
		"valid":    true,
		"user_id":  claims.UserID,
		"username": claims.Username,
		"role":     claims.Role,
		"grade":    strconv.Itoa(claims.Grade),
	})
}
