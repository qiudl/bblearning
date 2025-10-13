package handlers

import (
	"bytes"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/gin-gonic/gin"
	"github.com/qiudl/bblearning-backend/internal/domain/dto"
	"github.com/qiudl/bblearning-backend/internal/service/user"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/mock"
)

// MockAuthService 模拟认证服务
type MockAuthService struct {
	mock.Mock
}

func (m *MockAuthService) Register(req *dto.RegisterRequest) (*dto.RegisterResponse, error) {
	args := m.Called(req)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*dto.RegisterResponse), args.Error(1)
}

func (m *MockAuthService) Login(req *dto.LoginRequest) (*dto.LoginResponse, error) {
	args := m.Called(req)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*dto.LoginResponse), args.Error(1)
}

func (m *MockAuthService) RefreshToken(refreshToken string) (*dto.RefreshTokenResponse, error) {
	args := m.Called(refreshToken)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*dto.RefreshTokenResponse), args.Error(1)
}

func (m *MockAuthService) Logout(userID uint) error {
	args := m.Called(userID)
	return args.Error(0)
}

func (m *MockAuthService) GetUserByID(userID uint) (*dto.UserInfo, error) {
	args := m.Called(userID)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*dto.UserInfo), args.Error(1)
}

func (m *MockAuthService) UpdateUser(userID uint, req *dto.UpdateUserRequest) error {
	args := m.Called(userID, req)
	return args.Error(0)
}

func (m *MockAuthService) ChangePassword(userID uint, req *dto.ChangePasswordRequest) error {
	args := m.Called(userID, req)
	return args.Error(0)
}

func (m *MockAuthService) VerifyToken(token string) (*dto.TokenInfo, error) {
	args := m.Called(token)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*dto.TokenInfo), args.Error(1)
}

// setupTestRouter 设置测试路由
func setupTestRouter(handler *AuthHandler) *gin.Engine {
	gin.SetMode(gin.TestMode)
	r := gin.New()

	v1 := r.Group("/api/v1")
	{
		v1.POST("/auth/register", handler.Register)
		v1.POST("/auth/login", handler.Login)
		v1.POST("/auth/refresh", handler.RefreshToken)
		v1.POST("/auth/logout", handler.Logout)
		v1.GET("/auth/verify", handler.VerifyToken)
		v1.GET("/users/me", handler.GetCurrentUser)
		v1.PUT("/users/me", handler.UpdateCurrentUser)
		v1.PUT("/users/me/password", handler.ChangePassword)
	}

	return r
}

// TestRegister 测试用户注册
func TestRegister(t *testing.T) {
	tests := []struct {
		name           string
		requestBody    dto.RegisterRequest
		mockReturn     *dto.RegisterResponse
		mockError      error
		expectedStatus int
		expectedCode   int
	}{
		{
			name: "成功注册",
			requestBody: dto.RegisterRequest{
				Username: "testuser",
				Password: "Test123456",
				Nickname: "测试用户",
				Email:    "test@example.com",
				Grade:    "7",
			},
			mockReturn: &dto.RegisterResponse{
				User: &dto.UserInfo{
					ID:       1,
					Username: "testuser",
					Nickname: "测试用户",
					Email:    "test@example.com",
					Grade:    "7",
				},
			},
			mockError:      nil,
			expectedStatus: http.StatusOK,
			expectedCode:   0,
		},
		{
			name: "用户名已存在",
			requestBody: dto.RegisterRequest{
				Username: "existuser",
				Password: "Test123456",
				Nickname: "测试用户",
				Email:    "test@example.com",
				Grade:    "7",
			},
			mockReturn:     nil,
			mockError:      user.ErrUsernameExists,
			expectedStatus: http.StatusBadRequest,
			expectedCode:   1000,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			// 创建模拟服务
			mockService := new(MockAuthService)
			mockService.On("Register", &tt.requestBody).Return(tt.mockReturn, tt.mockError)

			// 创建处理器
			handler := NewAuthHandler(mockService)
			router := setupTestRouter(handler)

			// 准备请求
			body, _ := json.Marshal(tt.requestBody)
			req, _ := http.NewRequest("POST", "/api/v1/auth/register", bytes.NewBuffer(body))
			req.Header.Set("Content-Type", "application/json")

			// 执行请求
			w := httptest.NewRecorder()
			router.ServeHTTP(w, req)

			// 验证响应
			assert.Equal(t, tt.expectedStatus, w.Code)

			var response dto.Response
			err := json.Unmarshal(w.Body.Bytes(), &response)
			assert.NoError(t, err)
			assert.Equal(t, tt.expectedCode, response.Code)

			// 验证模拟调用
			mockService.AssertExpectations(t)
		})
	}
}

// TestLogin 测试用户登录
func TestLogin(t *testing.T) {
	tests := []struct {
		name           string
		requestBody    dto.LoginRequest
		mockReturn     *dto.LoginResponse
		mockError      error
		expectedStatus int
		expectedCode   int
	}{
		{
			name: "成功登录",
			requestBody: dto.LoginRequest{
				Username: "testuser",
				Password: "Test123456",
			},
			mockReturn: &dto.LoginResponse{
				AccessToken:  "access_token",
				RefreshToken: "refresh_token",
				User: &dto.UserInfo{
					ID:       1,
					Username: "testuser",
					Nickname: "测试用户",
				},
			},
			mockError:      nil,
			expectedStatus: http.StatusOK,
			expectedCode:   0,
		},
		{
			name: "用户名或密码错误",
			requestBody: dto.LoginRequest{
				Username: "testuser",
				Password: "wrongpassword",
			},
			mockReturn:     nil,
			mockError:      user.ErrInvalidCredentials,
			expectedStatus: http.StatusUnauthorized,
			expectedCode:   1001,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			// 创建模拟服务
			mockService := new(MockAuthService)
			mockService.On("Login", &tt.requestBody).Return(tt.mockReturn, tt.mockError)

			// 创建处理器
			handler := NewAuthHandler(mockService)
			router := setupTestRouter(handler)

			// 准备请求
			body, _ := json.Marshal(tt.requestBody)
			req, _ := http.NewRequest("POST", "/api/v1/auth/login", bytes.NewBuffer(body))
			req.Header.Set("Content-Type", "application/json")

			// 执行请求
			w := httptest.NewRecorder()
			router.ServeHTTP(w, req)

			// 验证响应
			assert.Equal(t, tt.expectedStatus, w.Code)

			var response dto.Response
			err := json.Unmarshal(w.Body.Bytes(), &response)
			assert.NoError(t, err)
			assert.Equal(t, tt.expectedCode, response.Code)

			// 验证模拟调用
			mockService.AssertExpectations(t)
		})
	}
}

// TestRefreshToken 测试刷新Token
func TestRefreshToken(t *testing.T) {
	tests := []struct {
		name           string
		requestBody    dto.RefreshTokenRequest
		mockReturn     *dto.RefreshTokenResponse
		mockError      error
		expectedStatus int
		expectedCode   int
	}{
		{
			name: "成功刷新Token",
			requestBody: dto.RefreshTokenRequest{
				RefreshToken: "valid_refresh_token",
			},
			mockReturn: &dto.RefreshTokenResponse{
				AccessToken:  "new_access_token",
				RefreshToken: "new_refresh_token",
			},
			mockError:      nil,
			expectedStatus: http.StatusOK,
			expectedCode:   0,
		},
		{
			name: "无效的RefreshToken",
			requestBody: dto.RefreshTokenRequest{
				RefreshToken: "invalid_token",
			},
			mockReturn:     nil,
			mockError:      user.ErrInvalidToken,
			expectedStatus: http.StatusUnauthorized,
			expectedCode:   1002,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			// 创建模拟服务
			mockService := new(MockAuthService)
			mockService.On("RefreshToken", tt.requestBody.RefreshToken).Return(tt.mockReturn, tt.mockError)

			// 创建处理器
			handler := NewAuthHandler(mockService)
			router := setupTestRouter(handler)

			// 准备请求
			body, _ := json.Marshal(tt.requestBody)
			req, _ := http.NewRequest("POST", "/api/v1/auth/refresh", bytes.NewBuffer(body))
			req.Header.Set("Content-Type", "application/json")

			// 执行请求
			w := httptest.NewRecorder()
			router.ServeHTTP(w, req)

			// 验证响应
			assert.Equal(t, tt.expectedStatus, w.Code)

			var response dto.Response
			err := json.Unmarshal(w.Body.Bytes(), &response)
			assert.NoError(t, err)
			assert.Equal(t, tt.expectedCode, response.Code)

			// 验证模拟调用
			mockService.AssertExpectations(t)
		})
	}
}

// TestGetCurrentUser 测试获取当前用户
func TestGetCurrentUser(t *testing.T) {
	// 创建模拟服务
	mockService := new(MockAuthService)
	mockService.On("GetUserByID", uint(1)).Return(&dto.UserInfo{
		ID:       1,
		Username: "testuser",
		Nickname: "测试用户",
	}, nil)

	// 创建处理器
	handler := NewAuthHandler(mockService)
	router := setupTestRouter(handler)

	// 准备请求
	req, _ := http.NewRequest("GET", "/api/v1/users/me", nil)
	req.Header.Set("Content-Type", "application/json")

	// 模拟中间件设置user_id
	w := httptest.NewRecorder()
	c, _ := gin.CreateTestContext(w)
	c.Request = req
	c.Set("user_id", uint(1))

	handler.GetCurrentUser(c)

	// 验证响应
	assert.Equal(t, http.StatusOK, w.Code)

	var response dto.Response
	err := json.Unmarshal(w.Body.Bytes(), &response)
	assert.NoError(t, err)
	assert.Equal(t, 0, response.Code)

	// 验证模拟调用
	mockService.AssertExpectations(t)
}
