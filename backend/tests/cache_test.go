package tests

import (
	"context"
	"testing"
	"time"

	"github.com/qiudl/bblearning-backend/internal/pkg/cache"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// TestCacheSetAndGet 测试缓存设置和获取
func TestCacheSetAndGet(t *testing.T) {
	ctx := context.Background()

	tests := []struct {
		name  string
		key   string
		value interface{}
		ttl   time.Duration
	}{
		{
			name:  "字符串缓存",
			key:   "test:string",
			value: "hello world",
			ttl:   time.Minute,
		},
		{
			name:  "数字缓存",
			key:   "test:number",
			value: 12345,
			ttl:   time.Minute,
		},
		{
			name: "结构体缓存",
			key:  "test:struct",
			value: map[string]interface{}{
				"name": "test",
				"age":  20,
			},
			ttl: time.Minute,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			// 设置缓存
			err := cache.Set(ctx, tt.key, tt.value, tt.ttl)
			require.NoError(t, err)

			// 获取缓存
			var result interface{}
			err = cache.Get(ctx, tt.key, &result)
			require.NoError(t, err)
			assert.Equal(t, tt.value, result)

			// 清理
			cache.Delete(ctx, tt.key)
		})
	}
}

// TestCacheExpiration 测试缓存过期
func TestCacheExpiration(t *testing.T) {
	ctx := context.Background()
	key := "test:expiration"
	value := "expires soon"

	// 设置1秒过期的缓存
	err := cache.Set(ctx, key, value, time.Second)
	require.NoError(t, err)

	// 立即获取应该成功
	var result string
	err = cache.Get(ctx, key, &result)
	require.NoError(t, err)
	assert.Equal(t, value, result)

	// 等待过期
	time.Sleep(2 * time.Second)

	// 过期后获取应该失败
	err = cache.Get(ctx, key, &result)
	assert.Error(t, err)
}

// TestCacheDelete 测试缓存删除
func TestCacheDelete(t *testing.T) {
	ctx := context.Background()
	key := "test:delete"
	value := "to be deleted"

	// 设置缓存
	err := cache.Set(ctx, key, value, time.Minute)
	require.NoError(t, err)

	// 删除缓存
	err = cache.Delete(ctx, key)
	require.NoError(t, err)

	// 获取应该失败
	var result string
	err = cache.Get(ctx, key, &result)
	assert.Error(t, err)
}

// TestCacheManager 测试缓存管理器
func TestCacheManager(t *testing.T) {
	ctx := context.Background()
	manager := cache.NewCacheManager()

	t.Run("GetOrSet成功", func(t *testing.T) {
		key := "test:getorset"
		expectedValue := "loaded value"

		// 第一次调用，应该执行loader
		var result string
		err := manager.GetOrSet(ctx, key, time.Minute, &result, func() (interface{}, error) {
			return expectedValue, nil
		})
		require.NoError(t, err)
		assert.Equal(t, expectedValue, result)

		// 第二次调用，应该从缓存获取
		var result2 string
		err = manager.GetOrSet(ctx, key, time.Minute, &result2, func() (interface{}, error) {
			return "should not be called", nil
		})
		require.NoError(t, err)
		assert.Equal(t, expectedValue, result2)

		// 清理
		cache.Delete(ctx, key)
	})

	t.Run("InvalidateUserCache", func(t *testing.T) {
		userID := uint(123)

		// 设置用户相关缓存
		cache.Set(ctx, cache.KeyUserInfo(userID), "user info", time.Minute)
		cache.Set(ctx, cache.KeyUserStats(userID), "user stats", time.Minute)

		// 清除用户缓存
		err := manager.InvalidateUserCache(ctx, userID)
		require.NoError(t, err)

		// 验证缓存已清除
		var result string
		err = cache.Get(ctx, cache.KeyUserInfo(userID), &result)
		assert.Error(t, err)
	})
}

// BenchmarkCacheSet 性能测试：设置缓存
func BenchmarkCacheSet(b *testing.B) {
	ctx := context.Background()
	value := map[string]interface{}{
		"name": "test",
		"age":  20,
	}

	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		cache.Set(ctx, "bench:set", value, time.Minute)
	}
}

// BenchmarkCacheGet 性能测试：获取缓存
func BenchmarkCacheGet(b *testing.B) {
	ctx := context.Background()
	key := "bench:get"
	value := map[string]interface{}{
		"name": "test",
		"age":  20,
	}

	// 预先设置缓存
	cache.Set(ctx, key, value, time.Minute)

	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		var result map[string]interface{}
		cache.Get(ctx, key, &result)
	}
}
