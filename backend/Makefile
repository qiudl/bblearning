.PHONY: build run test clean deps migrate-up migrate-down seed

# 编译项目
build:
	@echo "Building..."
	@go build -o bin/server cmd/server/main.go
	@echo "Build complete!"

# 运行服务
run:
	@echo "Running server..."
	@go run cmd/server/main.go

# 运行测试
test:
	@echo "Running tests..."
	@go test -v ./...

# 清理编译文件
clean:
	@echo "Cleaning..."
	@rm -rf bin/
	@echo "Clean complete!"

# 安装依赖
deps:
	@echo "Downloading dependencies..."
	@go mod download
	@go mod tidy
	@echo "Dependencies installed!"

# 应用数据库迁移
migrate-up:
	@echo "Running migrations..."
	@migrate -path migrations -database "postgresql://$(DB_USER):$(DB_PASSWORD)@$(DB_HOST):$(DB_PORT)/$(DB_NAME)?sslmode=disable" up

# 回滚数据库迁移
migrate-down:
	@echo "Rolling back migrations..."
	@migrate -path migrations -database "postgresql://$(DB_USER):$(DB_PASSWORD)@$(DB_HOST):$(DB_PORT)/$(DB_NAME)?sslmode=disable" down 1

# 插入种子数据
seed:
	@echo "Inserting seed data..."
	@go run scripts/seed_data.go

# 开发模式（热重载）
dev:
	@which air > /dev/null || go install github.com/cosmtrek/air@latest
	@air
