package storage

import (
	"context"
	"io"
	"time"

	"github.com/minio/minio-go/v7"
	"github.com/minio/minio-go/v7/pkg/credentials"
	"github.com/qiudl/bblearning-backend/internal/pkg/logger"
	"github.com/spf13/viper"
)

var minioClient *minio.Client

// Init 初始化MinIO客户端
func Init() error {
	var err error
	minioClient, err = minio.New(viper.GetString("minio.endpoint"), &minio.Options{
		Creds:  credentials.NewStaticV4(viper.GetString("minio.access_key"), viper.GetString("minio.secret_key"), ""),
		Secure: viper.GetBool("minio.use_ssl"),
	})
	if err != nil {
		return err
	}

	// 确保bucket存在
	ctx := context.Background()
	bucketName := viper.GetString("minio.bucket")
	exists, err := minioClient.BucketExists(ctx, bucketName)
	if err != nil {
		return err
	}

	if !exists {
		err = minioClient.MakeBucket(ctx, bucketName, minio.MakeBucketOptions{})
		if err != nil {
			return err
		}
		logger.Info("MinIO bucket created: " + bucketName)
	}

	logger.Info("MinIO initialized successfully")
	return nil
}

// UploadFile 上传文件
func UploadFile(ctx context.Context, objectName string, reader io.Reader, size int64, contentType string) error {
	_, err := minioClient.PutObject(ctx, viper.GetString("minio.bucket"), objectName, reader, size, minio.PutObjectOptions{
		ContentType: contentType,
	})
	return err
}

// DownloadFile 下载文件
func DownloadFile(ctx context.Context, objectName string) (*minio.Object, error) {
	return minioClient.GetObject(ctx, viper.GetString("minio.bucket"), objectName, minio.GetObjectOptions{})
}

// DeleteFile 删除文件
func DeleteFile(ctx context.Context, objectName string) error {
	return minioClient.RemoveObject(ctx, viper.GetString("minio.bucket"), objectName, minio.RemoveObjectOptions{})
}

// GetFileURL 获取文件访问URL (7天有效期)
func GetFileURL(ctx context.Context, objectName string) (string, error) {
	url, err := minioClient.PresignedGetObject(ctx, viper.GetString("minio.bucket"), objectName, 7*24*time.Hour, nil)
	if err != nil {
		return "", err
	}
	return url.String(), nil
}

// GetFileInfo 获取文件信息
func GetFileInfo(ctx context.Context, objectName string) (minio.ObjectInfo, error) {
	return minioClient.StatObject(ctx, viper.GetString("minio.bucket"), objectName, minio.StatObjectOptions{})
}

// ListFiles 列出文件
func ListFiles(ctx context.Context, prefix string) <-chan minio.ObjectInfo {
	return minioClient.ListObjects(ctx, viper.GetString("minio.bucket"), minio.ListObjectsOptions{
		Prefix:    prefix,
		Recursive: true,
	})
}

// GetClient 获取MinIO客户端(用于高级操作)
func GetClient() *minio.Client {
	return minioClient
}
