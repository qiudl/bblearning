package user

import (
	"context"
	"errors"
	"fmt"
	"strconv"
	"time"

	"golang.org/x/crypto/bcrypt"

	"github.com/qiudl/bblearning-backend/internal/domain/dto"
	"github.com/qiudl/bblearning-backend/internal/domain/models"
	"github.com/qiudl/bblearning-backend/internal/pkg/auth"
	"github.com/qiudl/bblearning-backend/internal/pkg/cache"
	"github.com/qiudl/bblearning-backend/internal/repository/postgres"
)

// AuthService 认证服务
type AuthService struct {
	userRepo *postgres.UserRepository
}

// NewAuthService 创建认证服务
func NewAuthService(userRepo *postgres.UserRepository) *AuthService {
	return &AuthService{
		userRepo: userRepo,
	}
}

// Register 用户注册
func (s *AuthService) Register(ctx context.Context, req *dto.RegisterRequest) (*dto.RegisterResponse, error) {
	// 1. 检查用户名是否存在
	exists, err := s.userRepo.ExistsByUsername(ctx, req.Username)
	if err != nil {
		return nil, fmt.Errorf("check username exists failed: %w", err)
	}
	if exists {
		return nil, errors.New("username already exists")
	}

	// 2. 密码加密
	hashedPassword, err := bcrypt.GenerateFromPassword([]byte(req.Password), bcrypt.DefaultCost)
	if err != nil {
		return nil, fmt.Errorf("hash password failed: %w", err)
	}

	// 3. 创建用户
	user := &models.User{
		Username: req.Username,
		Password: string(hashedPassword),
		Nickname: req.Nickname,
		Grade:    req.Grade,
		Role:     "student",
		Status:   "active",
	}

	// 如果没有昵称,使用用户名
	if user.Nickname == "" {
		user.Nickname = user.Username
	}

	if err := s.userRepo.Create(ctx, user); err != nil {
		return nil, fmt.Errorf("create user failed: %w", err)
	}

	// 4. 生成令牌
	grade, _ := strconv.Atoi(user.Grade)
	accessToken, err := auth.GenerateToken(user.ID, user.Username, grade, user.Role)
	if err != nil {
		return nil, fmt.Errorf("generate access token failed: %w", err)
	}

	refreshToken, err := auth.GenerateRefreshToken(user.ID)
	if err != nil {
		return nil, fmt.Errorf("generate refresh token failed: %w", err)
	}

	return &dto.RegisterResponse{
		User:         dto.ToUserInfo(user),
		AccessToken:  accessToken,
		RefreshToken: refreshToken,
	}, nil
}

// Login 用户登录
func (s *AuthService) Login(ctx context.Context, req *dto.LoginRequest) (*dto.LoginResponse, error) {
	// 1. 查询用户
	user, err := s.userRepo.FindByUsername(ctx, req.Username)
	if err != nil {
		return nil, errors.New("invalid username or password")
	}

	// 2. 验证密码
	if err := bcrypt.CompareHashAndPassword([]byte(user.Password), []byte(req.Password)); err != nil {
		return nil, errors.New("invalid username or password")
	}

	// 3. 检查用户状态
	if user.Status != "active" {
		return nil, errors.New("user account is inactive")
	}

	// 4. 更新最后登录时间
	now := time.Now()
	user.LastLoginAt = &now
	_ = s.userRepo.UpdateFields(ctx, user.ID, map[string]interface{}{
		"last_login_at": now,
	})

	// 5. 生成令牌
	grade, _ := strconv.Atoi(user.Grade)
	accessToken, err := auth.GenerateToken(user.ID, user.Username, grade, user.Role)
	if err != nil {
		return nil, fmt.Errorf("generate access token failed: %w", err)
	}

	refreshToken, err := auth.GenerateRefreshToken(user.ID)
	if err != nil {
		return nil, fmt.Errorf("generate refresh token failed: %w", err)
	}

	// 6. 缓存用户信息
	cacheKey := fmt.Sprintf("user:%d", user.ID)
	_ = cache.Set(ctx, cacheKey, dto.ToUserInfo(user), 30*time.Minute)

	return &dto.LoginResponse{
		User:         dto.ToUserInfo(user),
		AccessToken:  accessToken,
		RefreshToken: refreshToken,
	}, nil
}

// RefreshToken 刷新令牌
func (s *AuthService) RefreshToken(ctx context.Context, refreshToken string) (*dto.RefreshTokenResponse, error) {
	// 1. 解析刷新令牌
	claims, err := auth.ParseToken(refreshToken)
	if err != nil {
		return nil, errors.New("invalid refresh token")
	}

	// 2. 查询用户
	user, err := s.userRepo.FindByID(ctx, claims.UserID)
	if err != nil {
		return nil, errors.New("user not found")
	}

	// 3. 检查用户状态
	if user.Status != "active" {
		return nil, errors.New("user account is inactive")
	}

	// 4. 生成新的访问令牌
	grade, _ := strconv.Atoi(user.Grade)
	accessToken, err := auth.GenerateToken(user.ID, user.Username, grade, user.Role)
	if err != nil {
		return nil, fmt.Errorf("generate access token failed: %w", err)
	}

	return &dto.RefreshTokenResponse{
		AccessToken: accessToken,
	}, nil
}

// Logout 用户登出
func (s *AuthService) Logout(ctx context.Context, userID uint) error {
	// 清除缓存
	cacheKey := fmt.Sprintf("user:%d", userID)
	return cache.Delete(ctx, cacheKey)
}

// GetUserInfo 获取用户信息
func (s *AuthService) GetUserInfo(ctx context.Context, userID uint) (*dto.UserInfo, error) {
	// 1. 尝试从缓存获取
	cacheKey := fmt.Sprintf("user:%d", userID)
	var userInfo dto.UserInfo
	if err := cache.Get(ctx, cacheKey, &userInfo); err == nil {
		return &userInfo, nil
	}

	// 2. 从数据库查询
	user, err := s.userRepo.FindByID(ctx, userID)
	if err != nil {
		return nil, fmt.Errorf("user not found: %w", err)
	}

	// 3. 缓存用户信息
	userInfo = *dto.ToUserInfo(user)
	_ = cache.Set(ctx, cacheKey, userInfo, 30*time.Minute)

	return &userInfo, nil
}

// UpdateUser 更新用户信息
func (s *AuthService) UpdateUser(ctx context.Context, userID uint, req *dto.UpdateUserRequest) error {
	// 构建更新字段
	updates := make(map[string]interface{})

	if req.Nickname != nil {
		updates["nickname"] = *req.Nickname
	}
	if req.PhoneNumber != nil {
		updates["phone_number"] = *req.PhoneNumber
	}
	if req.Email != nil {
		updates["email"] = *req.Email
	}
	if req.Avatar != nil {
		updates["avatar"] = *req.Avatar
	}

	if len(updates) == 0 {
		return errors.New("no fields to update")
	}

	// 更新数据库
	if err := s.userRepo.UpdateFields(ctx, userID, updates); err != nil {
		return fmt.Errorf("update user failed: %w", err)
	}

	// 清除缓存
	cacheKey := fmt.Sprintf("user:%d", userID)
	_ = cache.Delete(ctx, cacheKey)

	return nil
}

// ChangePassword 修改密码
func (s *AuthService) ChangePassword(ctx context.Context, userID uint, req *dto.ChangePasswordRequest) error {
	// 1. 查询用户
	user, err := s.userRepo.FindByID(ctx, userID)
	if err != nil {
		return errors.New("user not found")
	}

	// 2. 验证旧密码
	if err := bcrypt.CompareHashAndPassword([]byte(user.Password), []byte(req.OldPassword)); err != nil {
		return errors.New("old password is incorrect")
	}

	// 3. 加密新密码
	hashedPassword, err := bcrypt.GenerateFromPassword([]byte(req.NewPassword), bcrypt.DefaultCost)
	if err != nil {
		return fmt.Errorf("hash password failed: %w", err)
	}

	// 4. 更新密码
	return s.userRepo.UpdateFields(ctx, userID, map[string]interface{}{
		"password": string(hashedPassword),
	})
}
