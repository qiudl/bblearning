package middleware

import (
	"net/http"
	"strings"

	"github.com/gin-gonic/gin"
	"github.com/qiudl/bblearning-backend/internal/pkg/auth"
)

// AuthMiddleware JWT认证中间件
func AuthMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		// 获取Authorization头
		authHeader := c.GetHeader("Authorization")
		if authHeader == "" {
			c.JSON(http.StatusUnauthorized, gin.H{
				"code":    1001,
				"message": "缺少认证令牌",
			})
			c.Abort()
			return
		}

		// 检查Bearer前缀
		parts := strings.SplitN(authHeader, " ", 2)
		if len(parts) != 2 || parts[0] != "Bearer" {
			c.JSON(http.StatusUnauthorized, gin.H{
				"code":    1001,
				"message": "认证令牌格式错误",
			})
			c.Abort()
			return
		}

		tokenString := parts[1]

		// 验证令牌
		valid, err := auth.ValidateToken(tokenString)
		if err != nil || !valid {
			c.JSON(http.StatusUnauthorized, gin.H{
				"code":    1002,
				"message": "令牌无效或已过期",
			})
			c.Abort()
			return
		}

		// 解析令牌
		claims, err := auth.ParseToken(tokenString)
		if err != nil {
			c.JSON(http.StatusUnauthorized, gin.H{
				"code":    1002,
				"message": "令牌解析失败",
			})
			c.Abort()
			return
		}

		// 将用户信息存入上下文
		c.Set("user_id", claims.UserID)
		c.Set("username", claims.Username)
		c.Set("grade", claims.Grade)
		c.Set("role", claims.Role)

		c.Next()
	}
}

// RoleMiddleware 角色验证中间件
func RoleMiddleware(allowedRoles ...string) gin.HandlerFunc {
	return func(c *gin.Context) {
		// 获取用户角色
		role, exists := c.Get("role")
		if !exists {
			c.JSON(http.StatusUnauthorized, gin.H{
				"code":    1001,
				"message": "未授权",
			})
			c.Abort()
			return
		}

		// 检查角色
		roleStr := role.(string)
		allowed := false
		for _, allowedRole := range allowedRoles {
			if roleStr == allowedRole {
				allowed = true
				break
			}
		}

		if !allowed {
			c.JSON(http.StatusForbidden, gin.H{
				"code":    1003,
				"message": "权限不足",
			})
			c.Abort()
			return
		}

		c.Next()
	}
}

// OptionalAuthMiddleware 可选认证中间件（不强制要求认证）
func OptionalAuthMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		// 获取Authorization头
		authHeader := c.GetHeader("Authorization")
		if authHeader == "" {
			c.Next()
			return
		}

		// 检查Bearer前缀
		parts := strings.SplitN(authHeader, " ", 2)
		if len(parts) != 2 || parts[0] != "Bearer" {
			c.Next()
			return
		}

		tokenString := parts[1]

		// 尝试解析令牌
		claims, err := auth.ParseToken(tokenString)
		if err == nil {
			// 将用户信息存入上下文
			c.Set("user_id", claims.UserID)
			c.Set("username", claims.Username)
			c.Set("grade", claims.Grade)
			c.Set("role", claims.Role)
		}

		c.Next()
	}
}
