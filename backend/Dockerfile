# Build stage
FROM golang:1.21-alpine AS builder

# 安装必要的构建工具
RUN apk add --no-cache git make

# 设置工作目录
WORKDIR /app

# 复制 go mod 文件
COPY go.mod go.sum ./

# 下载依赖
RUN go mod download

# 复制源代码
COPY . .

# 构建应用
RUN make build

# Runtime stage
FROM alpine:latest

# 安装必要的运行时依赖
RUN apk --no-cache add ca-certificates tzdata curl bash

# 设置时区
ENV TZ=Asia/Shanghai

# 创建非 root 用户
RUN addgroup -g 1000 appuser && \
    adduser -D -u 1000 -G appuser appuser

# 设置工作目录
WORKDIR /app

# 复制编译好的二进制文件
COPY --from=builder /app/bin/server /app/server

# 复制配置文件
COPY --from=builder /app/config /app/config

# 复制 wait-for-it 脚本
COPY wait-for-it.sh /app/wait-for-it.sh
RUN chmod +x /app/wait-for-it.sh /app/server

# 切换到非 root 用户
USER appuser

# 暴露端口
EXPOSE 8080

# 健康检查
HEALTHCHECK --interval=30s --timeout=3s --start-period=40s --retries=3 \
  CMD curl -f http://localhost:8080/health || exit 1

# 启动应用
CMD ["/app/server"]
