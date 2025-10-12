package handlers

import (
	"net/http"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/golang-jwt/jwt/v5"
	"github.com/qiudl/bblearning-backend/internal/api/middleware"
	"github.com/qiudl/bblearning-backend/internal/domain/dto"
	"github.com/spf13/viper"
	"golang.org/x/crypto/bcrypt"
)

type RegisterRequest struct {
	Username string `json:"username" binding:"required,min=3,max=50"`
	Password string `json:"password" binding:"required,min=6"`
	Grade    string `json:"grade"`
}

type LoginRequest struct {
	Username string `json:"username" binding:"required"`
	Password string `json:"password" binding:"required"`
}

// Register 用户注册
func Register(c *gin.Context) {
	var req RegisterRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, dto.Error(1000, "参数错误: "+err.Error()))
		return
	}

	// TODO: 实现实际的注册逻辑
	// 1. 检查用户名是否已存在
	// 2. 加密密码
	// 3. 保存到数据库

	hashedPassword, err := bcrypt.GenerateFromPassword([]byte(req.Password), bcrypt.DefaultCost)
	if err != nil {
		c.JSON(http.StatusInternalServerError, dto.Error(3000, "密码加密失败"))
		return
	}

	// Mock response
	c.JSON(http.StatusOK, dto.Success(gin.H{
		"message": "注册成功",
		"user": gin.H{
			"id":       1,
			"username": req.Username,
			"grade":    req.Grade,
		},
		"password": string(hashedPassword), // 仅用于演示，实际不应返回
	}))
}

// Login 用户登录
func Login(c *gin.Context) {
	var req LoginRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, dto.Error(1000, "参数错误: "+err.Error()))
		return
	}

	// TODO: 实现实际的登录逻辑
	// 1. 从数据库查询用户
	// 2. 验证密码
	// 3. 生成JWT token

	// Mock user
	userID := uint(1)
	username := req.Username

	// 生成 JWT token
	token, err := generateToken(userID, username)
	if err != nil{
		c.JSON(http.StatusInternalServerError, dto.Error(3000, "生成token失败"))
		return
	}

	c.JSON(http.StatusOK, dto.Success(gin.H{
		"token": token,
		"user": gin.H{
			"id":       userID,
			"username": username,
			"grade":    "初二",
		},
	}))
}

// Logout 用户登出
func Logout(c *gin.Context) {
	// TODO: 如果使用 Redis 存储 token，在这里将 token 加入黑名单
	c.JSON(http.StatusOK, dto.Success(gin.H{
		"message": "登出成功",
	}))
}

// GetCurrentUser 获取当前用户信息
func GetCurrentUser(c *gin.Context) {
	userID, _ := c.Get("userId")
	username, _ := c.Get("username")

	// TODO: 从数据库获取完整的用户信息

	c.JSON(http.StatusOK, dto.Success(gin.H{
		"id":       userID,
		"username": username,
		"grade":    "初二",
		"avatar":   "",
	}))
}

// generateToken 生成 JWT token
func generateToken(userID uint, username string) (string, error) {
	expiration := viper.GetInt("jwt.expiration")
	if expiration == 0 {
		expiration = 3600 // 默认1小时
	}

	claims := middleware.Claims{
		UserID:   userID,
		Username: username,
		RegisteredClaims: jwt.RegisteredClaims{
			ExpiresAt: jwt.NewNumericDate(time.Now().Add(time.Duration(expiration) * time.Second)),
			IssuedAt:  jwt.NewNumericDate(time.Now()),
		},
	}

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	return token.SignedString([]byte(viper.GetString("jwt.secret")))
}
