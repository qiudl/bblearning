package auth

import (
	"errors"
	"time"

	"github.com/golang-jwt/jwt/v5"
	"github.com/spf13/viper"
)

// Claims JWT声明
type Claims struct {
	UserID   uint   `json:"user_id"`
	Username string `json:"username"`
	Grade    int    `json:"grade"`
	Role     string `json:"role"`
	jwt.RegisteredClaims
}

// GenerateToken 生成JWT Token
func GenerateToken(userID uint, username string, grade int, role string) (string, error) {
	expirationSeconds := viper.GetInt("jwt.expiration")
	if expirationSeconds == 0 {
		expirationSeconds = 3600 // 默认1小时
	}

	claims := Claims{
		UserID:   userID,
		Username: username,
		Grade:    grade,
		Role:     role,
		RegisteredClaims: jwt.RegisteredClaims{
			ExpiresAt: jwt.NewNumericDate(time.Now().Add(time.Duration(expirationSeconds) * time.Second)),
			IssuedAt:  jwt.NewNumericDate(time.Now()),
			NotBefore: jwt.NewNumericDate(time.Now()),
			Issuer:    "bblearning",
		},
	}

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	return token.SignedString([]byte(getJWTSecret()))
}

// GenerateRefreshToken 生成刷新Token (有效期7天)
func GenerateRefreshToken(userID uint) (string, error) {
	claims := Claims{
		UserID: userID,
		RegisteredClaims: jwt.RegisteredClaims{
			ExpiresAt: jwt.NewNumericDate(time.Now().Add(7 * 24 * time.Hour)),
			IssuedAt:  jwt.NewNumericDate(time.Now()),
			Issuer:    "bblearning",
		},
	}

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	return token.SignedString([]byte(getJWTSecret()))
}

// ParseToken 解析JWT Token
func ParseToken(tokenString string) (*Claims, error) {
	token, err := jwt.ParseWithClaims(tokenString, &Claims{}, func(token *jwt.Token) (interface{}, error) {
		// 验证签名方法
		if _, ok := token.Method.(*jwt.SigningMethodHMAC); !ok {
			return nil, errors.New("unexpected signing method")
		}
		return []byte(getJWTSecret()), nil
	})

	if err != nil {
		return nil, err
	}

	if claims, ok := token.Claims.(*Claims); ok && token.Valid {
		return claims, nil
	}

	return nil, errors.New("invalid token")
}

// ValidateToken 验证Token是否有效
func ValidateToken(tokenString string) (bool, error) {
	claims, err := ParseToken(tokenString)
	if err != nil {
		return false, err
	}

	// 检查是否过期
	if time.Now().After(claims.ExpiresAt.Time) {
		return false, errors.New("token expired")
	}

	return true, nil
}

// getJWTSecret 获取JWT密钥
func getJWTSecret() string {
	secret := viper.GetString("jwt.secret")
	if secret == "" {
		// 开发环境默认密钥(生产环境必须配置)
		return "bblearning-dev-secret-key-change-in-production"
	}
	return secret
}
