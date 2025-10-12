package main

import (
	"fmt"
	"log"

	"github.com/gin-gonic/gin"
	"github.com/qiudl/bblearning-backend/internal/api/routes"
	"github.com/qiudl/bblearning-backend/internal/pkg/cache"
	"github.com/qiudl/bblearning-backend/internal/pkg/database"
	"github.com/qiudl/bblearning-backend/internal/pkg/logger"
	"github.com/qiudl/bblearning-backend/internal/pkg/storage"
	"github.com/spf13/viper"
)

func main() {
	// 初始化配置
	if err := initConfig(); err != nil {
		log.Fatal("Failed to initialize config:", err)
	}

	// 初始化日志
	if err := logger.Init(); err != nil {
		log.Fatal("Failed to initialize logger:", err)
	}
	defer logger.Sync()

	// 初始化数据库
	if err := database.Init(); err != nil {
		logger.Fatal("Failed to initialize database: " + err.Error())
	}
	defer database.Close()

	// 自动迁移数据库
	if err := database.AutoMigrate(); err != nil {
		logger.Fatal("Failed to migrate database: " + err.Error())
	}

	// 初始化Redis
	if err := cache.Init(); err != nil {
		logger.Fatal("Failed to initialize redis: " + err.Error())
	}
	defer cache.Close()

	// 初始化MinIO
	if err := storage.Init(); err != nil {
		logger.Fatal("Failed to initialize minio: " + err.Error())
	}

	// 设置 Gin 模式
	mode := viper.GetString("server.mode")
	if mode == "release" {
		gin.SetMode(gin.ReleaseMode)
	}

	// 创建 Gin 引擎
	r := gin.Default()

	// 设置路由
	routes.Setup(r)

	// 启动服务器
	port := viper.GetString("server.port")
	if port == "" {
		port = "8080"
	}

	logger.Info(fmt.Sprintf("Server starting on port %s", port))
	if err := r.Run(":" + port); err != nil {
		logger.Fatal("Failed to start server: " + err.Error())
	}
}

func initConfig() error {
	viper.SetConfigName("config")
	viper.SetConfigType("yaml")
	viper.AddConfigPath("./config")
	viper.AddConfigPath(".")

	// 设置默认值
	viper.SetDefault("server.port", "8080")
	viper.SetDefault("server.mode", "debug")

	// 读取环境变量
	viper.AutomaticEnv()

	if err := viper.ReadInConfig(); err != nil {
		if _, ok := err.(viper.ConfigFileNotFoundError); ok {
			// 配置文件未找到，使用默认值
			logger.Warn("Config file not found, using defaults")
			return nil
		}
		return err
	}

	return nil
}
