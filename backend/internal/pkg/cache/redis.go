package cache

import (
	"context"
	"encoding/json"
	"time"

	"github.com/qiudl/bblearning-backend/internal/pkg/logger"
	"github.com/redis/go-redis/v9"
	"github.com/spf13/viper"
)

var redisClient *redis.Client

// Init 初始化Redis客户端
func Init() error {
	redisClient = redis.NewClient(&redis.Options{
		Addr:     viper.GetString("redis.host") + ":" + viper.GetString("redis.port"),
		Password: viper.GetString("redis.password"),
		DB:       viper.GetInt("redis.db"),
	})

	// 测试连接
	ctx := context.Background()
	if err := redisClient.Ping(ctx).Err(); err != nil {
		return err
	}

	logger.Info("Redis connected successfully")
	return nil
}

// Get 获取缓存
func Get(ctx context.Context, key string, dest interface{}) error {
	val, err := redisClient.Get(ctx, key).Result()
	if err != nil {
		return err
	}
	return json.Unmarshal([]byte(val), dest)
}

// Set 设置缓存
func Set(ctx context.Context, key string, value interface{}, expiration time.Duration) error {
	data, err := json.Marshal(value)
	if err != nil {
		return err
	}
	return redisClient.Set(ctx, key, data, expiration).Err()
}

// Delete 删除缓存
func Delete(ctx context.Context, keys ...string) error {
	return redisClient.Del(ctx, keys...).Err()
}

// Exists 检查key是否存在
func Exists(ctx context.Context, keys ...string) (int64, error) {
	return redisClient.Exists(ctx, keys...).Result()
}

// Expire 设置过期时间
func Expire(ctx context.Context, key string, expiration time.Duration) error {
	return redisClient.Expire(ctx, key, expiration).Err()
}

// Close 关闭Redis连接
func Close() error {
	if redisClient != nil {
		return redisClient.Close()
	}
	return nil
}

// GetClient 获取Redis客户端(用于高级操作)
func GetClient() *redis.Client {
	return redisClient
}
