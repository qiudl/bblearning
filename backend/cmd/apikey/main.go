package main

import (
	"context"
	"flag"
	"fmt"
	"log"
	"os"

	"github.com/qiudl/bblearning-backend/internal/domain"
	"github.com/qiudl/bblearning-backend/internal/pkg/crypto"
	"github.com/qiudl/bblearning-backend/internal/pkg/database"
	"github.com/qiudl/bblearning-backend/internal/pkg/logger"
	"github.com/qiudl/bblearning-backend/internal/repository"
	"github.com/qiudl/bblearning-backend/internal/service"
	"github.com/spf13/viper"
)

// CLI工具用于管理API密钥
func main() {
	// 定义命令行参数
	action := flag.String("action", "add", "操作: add, list, delete")
	provider := flag.String("provider", "", "服务提供商: deepseek, openai, anthropic, gemini")
	keyName := flag.String("name", "default", "密钥名称")
	apiKey := flag.String("key", "", "API密钥")
	description := flag.String("desc", "", "描述")
	priority := flag.Int("priority", 100, "优先级")

	flag.Parse()

	// 初始化日志
	if err := logger.Init(); err != nil {
		log.Fatalf("初始化日志失败: %v", err)
	}

	// 加载配置
	if err := loadEnv(); err != nil {
		log.Fatalf("加载环境变量失败: %v", err)
	}

	// 初始化数据库
	if err := database.Init(); err != nil {
		log.Fatalf("初始化数据库失败: %v", err)
	}
	defer database.Close()

	// 初始化加密器
	masterKeyHex := os.Getenv("ENCRYPTION_MASTER_KEY")
	if masterKeyHex == "" {
		log.Fatal("ENCRYPTION_MASTER_KEY 环境变量未设置")
	}

	encryptor, err := crypto.NewAESEncryptorFromHex(masterKeyHex)
	if err != nil {
		log.Fatalf("初始化加密器失败: %v", err)
	}

	// 初始化服务
	repo := repository.NewAPIKeyRepository(database.DB)
	svc := service.NewAPIKeyService(repo, encryptor)

	ctx := context.Background()

	// 执行操作
	switch *action {
	case "add":
		if *provider == "" || *apiKey == "" {
			log.Fatal("添加密钥需要指定 -provider 和 -key 参数")
		}
		if err := addKey(ctx, svc, *provider, *keyName, *apiKey, *description, *priority); err != nil {
			log.Fatalf("添加密钥失败: %v", err)
		}
		fmt.Println("✓ API密钥添加成功")

	case "list":
		if err := listKeys(ctx, svc, *provider); err != nil {
			log.Fatalf("列出密钥失败: %v", err)
		}

	case "test":
		if *provider == "" {
			log.Fatal("测试需要指定 -provider 参数")
		}
		if err := testDecrypt(ctx, svc, *provider, *keyName); err != nil {
			log.Fatalf("测试失败: %v", err)
		}
		fmt.Println("✓ 密钥解密测试成功")

	default:
		log.Fatalf("未知操作: %s", *action)
	}
}

func addKey(ctx context.Context, svc service.APIKeyService, provider, keyName, apiKey, description string, priority int) error {
	req := &domain.CreateAPIKeyRequest{
		Provider:    provider,
		KeyName:     keyName,
		APIKey:      apiKey,
		Description: description,
		Priority:    priority,
	}

	dto, err := svc.Create(ctx, req, 1) // operatorID = 1 (系统管理员)
	if err != nil {
		return err
	}

	fmt.Printf("ID: %d\n", dto.ID)
	fmt.Printf("Provider: %s\n", dto.Provider)
	fmt.Printf("KeyName: %s\n", dto.KeyName)
	fmt.Printf("IsActive: %v\n", dto.IsActive)
	fmt.Printf("Priority: %d\n", dto.Priority)

	return nil
}

func listKeys(ctx context.Context, svc service.APIKeyService, provider string) error {
	dtos, err := svc.List(ctx, provider)
	if err != nil {
		return err
	}

	if len(dtos) == 0 {
		fmt.Println("没有找到API密钥")
		return nil
	}

	fmt.Printf("共找到 %d 个API密钥:\n\n", len(dtos))
	for _, dto := range dtos {
		fmt.Printf("ID: %d\n", dto.ID)
		fmt.Printf("Provider: %s\n", dto.Provider)
		fmt.Printf("KeyName: %s\n", dto.KeyName)
		fmt.Printf("IsActive: %v\n", dto.IsActive)
		fmt.Printf("Priority: %d\n", dto.Priority)
		fmt.Printf("Description: %s\n", dto.Description)
		fmt.Printf("UsageCount: %d\n", dto.UsageCount)
		fmt.Printf("CreatedAt: %s\n", dto.CreatedAt.Format("2006-01-02 15:04:05"))
		fmt.Println("---")
	}

	return nil
}

func testDecrypt(ctx context.Context, svc service.APIKeyService, provider, keyName string) error {
	plaintext, err := svc.GetDecrypted(ctx, provider, keyName)
	if err != nil {
		return err
	}

	// 只显示前8个字符（脱敏）
	masked := plaintext
	if len(plaintext) > 8 {
		masked = plaintext[:8] + "..." + plaintext[len(plaintext)-4:]
	}

	fmt.Printf("成功解密密钥: %s\n", masked)
	return nil
}

func loadEnv() error {
	// 加载配置文件
	viper.SetConfigName("config")
	viper.SetConfigType("yaml")
	viper.AddConfigPath("./config")
	viper.AddConfigPath(".")
	viper.AddConfigPath("../config")
	viper.AddConfigPath("../../config")

	// 设置默认值
	viper.SetDefault("database.host", "localhost")
	viper.SetDefault("database.port", 5432)

	// 读取环境变量
	viper.AutomaticEnv()

	// 尝试读取配置文件，如果失败则使用环境变量
	if err := viper.ReadInConfig(); err != nil {
		if _, ok := err.(viper.ConfigFileNotFoundError); !ok {
			return fmt.Errorf("读取配置文件失败: %w", err)
		}
		// 配置文件未找到，使用环境变量
		log.Println("配置文件未找到，使用环境变量")
	}

	return nil
}
