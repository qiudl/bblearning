package database

import (
	"fmt"

	"github.com/qiudl/bblearning-backend/internal/domain/models"
	"github.com/qiudl/bblearning-backend/internal/pkg/logger"
	"github.com/spf13/viper"
	"gorm.io/driver/postgres"
	"gorm.io/gorm"
	gormlogger "gorm.io/gorm/logger"
)

var DB *gorm.DB

// Init 初始化数据库连接
func Init() error {
	// 构建 DSN
	dsn := fmt.Sprintf(
		"host=%s port=%d user=%s password=%s dbname=%s sslmode=disable TimeZone=Asia/Shanghai",
		viper.GetString("database.host"),
		viper.GetInt("database.port"),
		viper.GetString("database.user"),
		viper.GetString("database.password"),
		viper.GetString("database.dbname"),
	)

	// 配置 GORM 日志级别
	logLevel := gormlogger.Silent
	if viper.GetString("server.mode") == "debug" {
		logLevel = gormlogger.Info
	}

	// 打开数据库连接
	db, err := gorm.Open(postgres.Open(dsn), &gorm.Config{
		Logger: gormlogger.Default.LogMode(logLevel),
	})
	if err != nil {
		return fmt.Errorf("failed to connect to database: %w", err)
	}

	// 获取底层 sql.DB 对象以配置连接池
	sqlDB, err := db.DB()
	if err != nil {
		return fmt.Errorf("failed to get database instance: %w", err)
	}

	// 设置连接池参数
	sqlDB.SetMaxIdleConns(viper.GetInt("database.max_idle_conns"))
	sqlDB.SetMaxOpenConns(viper.GetInt("database.max_open_conns"))
	sqlDB.SetConnMaxLifetime(viper.GetDuration("database.conn_max_lifetime"))

	DB = db
	logger.Info("Database connected successfully")

	return nil
}

// AutoMigrate 自动迁移数据库表结构
func AutoMigrate() error {
	logger.Info("Starting database migration...")

	err := DB.AutoMigrate(
		&models.User{},
		&models.Chapter{},
		&models.KnowledgePoint{},
		&models.Question{},
		&models.PracticeRecord{},
		&models.WrongQuestion{},
		&models.LearningProgress{},
		&models.AIConversation{},
		&models.DailyGoal{},
		&models.LearningStatistics{},
	)

	if err != nil {
		return fmt.Errorf("failed to migrate database: %w", err)
	}

	logger.Info("Database migration completed successfully")
	return nil
}

// Close 关闭数据库连接
func Close() error {
	sqlDB, err := DB.DB()
	if err != nil {
		return err
	}
	return sqlDB.Close()
}
