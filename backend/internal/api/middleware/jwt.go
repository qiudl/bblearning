package middleware

import (
	"net/http"
	"strings"

	"github.com/gin-gonic/gin"
	"github.com/golang-jwt/jwt/v5"
	"github.com/qiudl/bblearning-backend/internal/domain/dto"
	"github.com/spf13/viper"
)

// Claims JWT claims
type Claims struct {
	UserID uint   `json:"userId"`
	Username string `json:"username"`
	jwt.RegisteredClaims
}

// JWTAuth JWT认证中间件
func JWTAuth() gin.HandlerFunc {
	return func(c *gin.Context) {
		authHeader := c.GetHeader("Authorization")
		if authHeader == "" {
			c.JSON(http.StatusUnauthorized, dto.Error(1001, "未授权，请先登录"))
			c.Abort()
			return
		}

		parts := strings.SplitN(authHeader, " ", 2)
		if !(len(parts) == 2 && parts[0] == "Bearer") {
			c.JSON(http.StatusUnauthorized, dto.Error(1001, "认证格式错误"))
			c.Abort()
			return
		}

		tokenString := parts[1]
		claims := &Claims{}

		token, err := jwt.ParseWithClaims(tokenString, claims, func(token *jwt.Token) (interface{}, error) {
			return []byte(viper.GetString("jwt.secret")), nil
		})

		if err != nil || !token.Valid {
			c.JSON(http.StatusUnauthorized, dto.Error(1002, "Token已过期或无效"))
			c.Abort()
			return
		}

		// 将用户信息存储到上下文中
		c.Set("userId", claims.UserID)
		c.Set("username", claims.Username)

		c.Next()
	}
}
