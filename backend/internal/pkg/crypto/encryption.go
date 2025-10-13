package crypto

import (
	"crypto/aes"
	"crypto/cipher"
	"crypto/rand"
	"crypto/sha256"
	"encoding/base64"
	"encoding/hex"
	"errors"
	"fmt"
	"io"

	"golang.org/x/crypto/pbkdf2"
)

const (
	// SaltSize 盐值大小（字节）
	SaltSize = 32
	// NonceSize GCM nonce大小（字节）
	NonceSize = 12
	// KeySize 密钥大小（字节）- AES-256
	KeySize = 32
	// PBKDF2Iterations PBKDF2迭代次数
	PBKDF2Iterations = 100000
)

var (
	// ErrInvalidMasterKey 主密钥无效
	ErrInvalidMasterKey = errors.New("invalid master key")
	// ErrInvalidCiphertext 密文无效
	ErrInvalidCiphertext = errors.New("invalid ciphertext")
	// ErrDecryptionFailed 解密失败
	ErrDecryptionFailed = errors.New("decryption failed")
)

// Encryptor 加密器接口
type Encryptor interface {
	// Encrypt 加密明文，返回base64编码的密文和nonce
	Encrypt(plaintext string, salt []byte) (ciphertext, nonce string, err error)
	// Decrypt 解密密文
	Decrypt(ciphertext, nonce string, salt []byte) (plaintext string, err error)
	// GenerateSalt 生成随机盐值
	GenerateSalt() ([]byte, error)
}

// AESEncryptor AES-256-GCM加密器
type AESEncryptor struct {
	masterKey []byte
}

// NewAESEncryptor 创建AES加密器
// masterKey 必须是32字节（256位）
func NewAESEncryptor(masterKey []byte) (*AESEncryptor, error) {
	if len(masterKey) != KeySize {
		return nil, fmt.Errorf("%w: expected %d bytes, got %d", ErrInvalidMasterKey, KeySize, len(masterKey))
	}

	return &AESEncryptor{
		masterKey: masterKey,
	}, nil
}

// NewAESEncryptorFromHex 从hex编码的主密钥创建加密器
func NewAESEncryptorFromHex(masterKeyHex string) (*AESEncryptor, error) {
	masterKey, err := hex.DecodeString(masterKeyHex)
	if err != nil {
		return nil, fmt.Errorf("failed to decode master key: %w", err)
	}

	return NewAESEncryptor(masterKey)
}

// deriveKey 使用PBKDF2从主密钥和盐值派生加密密钥
func (e *AESEncryptor) deriveKey(salt []byte) []byte {
	return pbkdf2.Key(e.masterKey, salt, PBKDF2Iterations, KeySize, sha256.New)
}

// Encrypt 加密明文
func (e *AESEncryptor) Encrypt(plaintext string, salt []byte) (ciphertext, nonce string, err error) {
	if len(salt) != SaltSize {
		return "", "", fmt.Errorf("invalid salt size: expected %d, got %d", SaltSize, len(salt))
	}

	// 派生加密密钥
	key := e.deriveKey(salt)

	// 创建AES cipher
	block, err := aes.NewCipher(key)
	if err != nil {
		return "", "", fmt.Errorf("failed to create cipher: %w", err)
	}

	// 创建GCM模式
	gcm, err := cipher.NewGCM(block)
	if err != nil {
		return "", "", fmt.Errorf("failed to create GCM: %w", err)
	}

	// 生成随机nonce
	nonceBytes := make([]byte, NonceSize)
	if _, err := io.ReadFull(rand.Reader, nonceBytes); err != nil {
		return "", "", fmt.Errorf("failed to generate nonce: %w", err)
	}

	// 加密
	plaintextBytes := []byte(plaintext)
	ciphertextBytes := gcm.Seal(nil, nonceBytes, plaintextBytes, nil)

	// 返回base64编码的密文和hex编码的nonce
	return base64.StdEncoding.EncodeToString(ciphertextBytes),
		hex.EncodeToString(nonceBytes),
		nil
}

// Decrypt 解密密文
func (e *AESEncryptor) Decrypt(ciphertext, nonce string, salt []byte) (plaintext string, err error) {
	if len(salt) != SaltSize {
		return "", fmt.Errorf("invalid salt size: expected %d, got %d", SaltSize, len(salt))
	}

	// 解码密文
	ciphertextBytes, err := base64.StdEncoding.DecodeString(ciphertext)
	if err != nil {
		return "", fmt.Errorf("%w: failed to decode ciphertext: %v", ErrInvalidCiphertext, err)
	}

	// 解码nonce
	nonceBytes, err := hex.DecodeString(nonce)
	if err != nil {
		return "", fmt.Errorf("%w: failed to decode nonce: %v", ErrInvalidCiphertext, err)
	}

	if len(nonceBytes) != NonceSize {
		return "", fmt.Errorf("%w: invalid nonce size: expected %d, got %d", ErrInvalidCiphertext, NonceSize, len(nonceBytes))
	}

	// 派生解密密钥
	key := e.deriveKey(salt)

	// 创建AES cipher
	block, err := aes.NewCipher(key)
	if err != nil {
		return "", fmt.Errorf("failed to create cipher: %w", err)
	}

	// 创建GCM模式
	gcm, err := cipher.NewGCM(block)
	if err != nil {
		return "", fmt.Errorf("failed to create GCM: %w", err)
	}

	// 解密
	plaintextBytes, err := gcm.Open(nil, nonceBytes, ciphertextBytes, nil)
	if err != nil {
		return "", fmt.Errorf("%w: %v", ErrDecryptionFailed, err)
	}

	return string(plaintextBytes), nil
}

// GenerateSalt 生成随机盐值
func (e *AESEncryptor) GenerateSalt() ([]byte, error) {
	salt := make([]byte, SaltSize)
	if _, err := io.ReadFull(rand.Reader, salt); err != nil {
		return nil, fmt.Errorf("failed to generate salt: %w", err)
	}
	return salt, nil
}

// GenerateMasterKey 生成随机主密钥（用于初始化）
func GenerateMasterKey() ([]byte, error) {
	key := make([]byte, KeySize)
	if _, err := io.ReadFull(rand.Reader, key); err != nil {
		return nil, fmt.Errorf("failed to generate master key: %w", err)
	}
	return key, nil
}

// GenerateMasterKeyHex 生成hex编码的随机主密钥
func GenerateMasterKeyHex() (string, error) {
	key, err := GenerateMasterKey()
	if err != nil {
		return "", err
	}
	return hex.EncodeToString(key), nil
}

// ClearBytes 安全清除字节数组（覆写内存）
func ClearBytes(b []byte) {
	for i := range b {
		b[i] = 0
	}
}

// ClearString 安全清除字符串（尽力而为，Go字符串不可变）
// 注意：Go的字符串是不可变的，此函数仅用于清除变量引用
func ClearString(s *string) {
	*s = ""
}
