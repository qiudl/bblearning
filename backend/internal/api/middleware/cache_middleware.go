package middleware

import (
	"bytes"
	"crypto/md5"
	"encoding/hex"
	"fmt"
	"io"
	"net/http"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/qiudl/bblearning-backend/internal/pkg/cache"
)

// CacheMiddleware API响应缓存中间件
// 只缓存GET请求且状态码为200的响应
func CacheMiddleware(ttl time.Duration) gin.HandlerFunc {
	return func(c *gin.Context) {
		// 只缓存GET请求
		if c.Request.Method != http.MethodGet {
			c.Next()
			return
		}

		// 生成缓存键
		cacheKey := generateCacheKey(c)

		// 尝试从缓存获取
		var cachedResponse CachedResponse
		err := cache.Get(c.Request.Context(), cacheKey, &cachedResponse)
		if err == nil {
			// 缓存命中，直接返回
			for key, values := range cachedResponse.Headers {
				for _, value := range values {
					c.Header(key, value)
				}
			}
			c.Header("X-Cache", "HIT")
			c.Data(cachedResponse.StatusCode, cachedResponse.ContentType, cachedResponse.Body)
			c.Abort()
			return
		}

		// 缓存未命中，继续处理请求
		c.Header("X-Cache", "MISS")

		// 创建响应写入器包装
		writer := &responseWriter{
			ResponseWriter: c.Writer,
			body:           &bytes.Buffer{},
		}
		c.Writer = writer

		// 处理请求
		c.Next()

		// 只缓存成功响应
		if writer.Status() == http.StatusOK {
			cachedResp := CachedResponse{
				StatusCode:  writer.Status(),
				ContentType: writer.Header().Get("Content-Type"),
				Headers:     writer.Header(),
				Body:        writer.body.Bytes(),
			}

			// 设置缓存
			if err := cache.Set(c.Request.Context(), cacheKey, cachedResp, ttl); err != nil {
				// 缓存设置失败不影响业务，只记录日志
				fmt.Printf("Failed to cache response: %v\n", err)
			}
		}
	}
}

// CachedResponse 缓存的响应
type CachedResponse struct {
	StatusCode  int                 `json:"status_code"`
	ContentType string              `json:"content_type"`
	Headers     map[string][]string `json:"headers"`
	Body        []byte              `json:"body"`
}

// responseWriter 响应写入器包装
type responseWriter struct {
	gin.ResponseWriter
	body       *bytes.Buffer
	statusCode int
}

func (w *responseWriter) Write(b []byte) (int, error) {
	w.body.Write(b)
	return w.ResponseWriter.Write(b)
}

func (w *responseWriter) WriteString(s string) (int, error) {
	w.body.WriteString(s)
	return w.ResponseWriter.WriteString(s)
}

func (w *responseWriter) WriteHeader(statusCode int) {
	w.statusCode = statusCode
	w.ResponseWriter.WriteHeader(statusCode)
}

func (w *responseWriter) Status() int {
	if w.statusCode == 0 {
		return http.StatusOK
	}
	return w.statusCode
}

// generateCacheKey 生成缓存键
func generateCacheKey(c *gin.Context) string {
	// 使用URL + 查询参数 + 用户ID生成唯一键
	userID, _ := c.Get("user_id")

	var keyParts []byte
	keyParts = append(keyParts, []byte(c.Request.URL.Path)...)
	keyParts = append(keyParts, []byte(c.Request.URL.RawQuery)...)
	if userID != nil {
		keyParts = append(keyParts, []byte(fmt.Sprintf("%v", userID))...)
	}

	// MD5 hash
	hash := md5.Sum(keyParts)
	return fmt.Sprintf("api:response:%s", hex.EncodeToString(hash[:]))
}
