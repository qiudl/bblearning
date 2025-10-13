package crypto

import (
	"encoding/hex"
	"testing"
)

func TestNewAESEncryptor(t *testing.T) {
	tests := []struct {
		name      string
		masterKey []byte
		wantErr   bool
	}{
		{
			name:      "valid 32-byte key",
			masterKey: make([]byte, 32),
			wantErr:   false,
		},
		{
			name:      "invalid 16-byte key",
			masterKey: make([]byte, 16),
			wantErr:   true,
		},
		{
			name:      "invalid empty key",
			masterKey: []byte{},
			wantErr:   true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			_, err := NewAESEncryptor(tt.masterKey)
			if (err != nil) != tt.wantErr {
				t.Errorf("NewAESEncryptor() error = %v, wantErr %v", err, tt.wantErr)
			}
		})
	}
}

func TestNewAESEncryptorFromHex(t *testing.T) {
	tests := []struct {
		name         string
		masterKeyHex string
		wantErr      bool
	}{
		{
			name:         "valid 64-char hex key",
			masterKeyHex: "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef",
			wantErr:      false,
		},
		{
			name:         "invalid non-hex string",
			masterKeyHex: "not-a-hex-string",
			wantErr:      true,
		},
		{
			name:         "invalid short hex",
			masterKeyHex: "0123456789abcdef",
			wantErr:      true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			_, err := NewAESEncryptorFromHex(tt.masterKeyHex)
			if (err != nil) != tt.wantErr {
				t.Errorf("NewAESEncryptorFromHex() error = %v, wantErr %v", err, tt.wantErr)
			}
		})
	}
}

func TestEncryptDecrypt(t *testing.T) {
	// 生成主密钥
	masterKey, err := GenerateMasterKey()
	if err != nil {
		t.Fatalf("Failed to generate master key: %v", err)
	}

	encryptor, err := NewAESEncryptor(masterKey)
	if err != nil {
		t.Fatalf("Failed to create encryptor: %v", err)
	}

	// 生成盐值
	salt, err := encryptor.GenerateSalt()
	if err != nil {
		t.Fatalf("Failed to generate salt: %v", err)
	}

	tests := []struct {
		name      string
		plaintext string
	}{
		{
			name:      "simple text",
			plaintext: "Hello, World!",
		},
		{
			name:      "api key",
			plaintext: "sk-1234567890abcdef1234567890abcdef",
		},
		{
			name:      "empty string",
			plaintext: "",
		},
		{
			name:      "long text",
			plaintext: "This is a very long text that should be encrypted and decrypted correctly. It contains multiple sentences and special characters like @#$%^&*().",
		},
		{
			name:      "unicode characters",
			plaintext: "你好，世界！🌍🔐",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			// 加密
			ciphertext, nonce, err := encryptor.Encrypt(tt.plaintext, salt)
			if err != nil {
				t.Fatalf("Encrypt() error = %v", err)
			}

			// 验证密文不为空
			if ciphertext == "" {
				t.Error("Ciphertext should not be empty")
			}

			// 验证密文与明文不同（除非明文为空）
			if tt.plaintext != "" && ciphertext == tt.plaintext {
				t.Error("Ciphertext should differ from plaintext")
			}

			// 解密
			decrypted, err := encryptor.Decrypt(ciphertext, nonce, salt)
			if err != nil {
				t.Fatalf("Decrypt() error = %v", err)
			}

			// 验证解密结果
			if decrypted != tt.plaintext {
				t.Errorf("Decrypt() = %v, want %v", decrypted, tt.plaintext)
			}
		})
	}
}

func TestEncryptDecrypt_DifferentSalts(t *testing.T) {
	masterKey, _ := GenerateMasterKey()
	encryptor, _ := NewAESEncryptor(masterKey)

	plaintext := "secret-api-key-12345"

	// 使用不同的盐值加密
	salt1, _ := encryptor.GenerateSalt()
	salt2, _ := encryptor.GenerateSalt()

	ciphertext1, nonce1, _ := encryptor.Encrypt(plaintext, salt1)
	ciphertext2, _, _ := encryptor.Encrypt(plaintext, salt2)

	// 相同明文，不同盐值应该产生不同的密文
	if ciphertext1 == ciphertext2 {
		t.Error("Same plaintext with different salts should produce different ciphertexts")
	}

	// 用正确的盐值应该能解密
	decrypted1, err := encryptor.Decrypt(ciphertext1, nonce1, salt1)
	if err != nil || decrypted1 != plaintext {
		t.Errorf("Failed to decrypt with correct salt: %v", err)
	}

	// 用错误的盐值应该解密失败
	_, err = encryptor.Decrypt(ciphertext1, nonce1, salt2)
	if err == nil {
		t.Error("Decrypt with wrong salt should fail")
	}
}

func TestEncryptDecrypt_WrongMasterKey(t *testing.T) {
	plaintext := "secret-api-key"

	// 使用第一个主密钥加密
	masterKey1, _ := GenerateMasterKey()
	encryptor1, _ := NewAESEncryptor(masterKey1)
	salt, _ := encryptor1.GenerateSalt()
	ciphertext, nonce, _ := encryptor1.Encrypt(plaintext, salt)

	// 使用不同的主密钥尝试解密
	masterKey2, _ := GenerateMasterKey()
	encryptor2, _ := NewAESEncryptor(masterKey2)

	_, err := encryptor2.Decrypt(ciphertext, nonce, salt)
	if err == nil {
		t.Error("Decrypt with wrong master key should fail")
	}
}

func TestEncrypt_InvalidSaltSize(t *testing.T) {
	masterKey, _ := GenerateMasterKey()
	encryptor, _ := NewAESEncryptor(masterKey)

	invalidSalt := make([]byte, 16) // 错误的盐值大小

	_, _, err := encryptor.Encrypt("test", invalidSalt)
	if err == nil {
		t.Error("Encrypt with invalid salt size should fail")
	}
}

func TestDecrypt_InvalidCiphertext(t *testing.T) {
	masterKey, _ := GenerateMasterKey()
	encryptor, _ := NewAESEncryptor(masterKey)
	salt, _ := encryptor.GenerateSalt()

	tests := []struct {
		name       string
		ciphertext string
		nonce      string
	}{
		{
			name:       "invalid base64 ciphertext",
			ciphertext: "not-valid-base64!!!",
			nonce:      "0123456789abcdef01234567",
		},
		{
			name:       "invalid hex nonce",
			ciphertext: "dGVzdA==",
			nonce:      "not-valid-hex",
		},
		{
			name:       "wrong nonce size",
			ciphertext: "dGVzdA==",
			nonce:      "0123456789abcdef", // 只有16个hex字符 = 8字节，需要24个字符 = 12字节
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			_, err := encryptor.Decrypt(tt.ciphertext, tt.nonce, salt)
			if err == nil {
				t.Error("Decrypt with invalid input should fail")
			}
		})
	}
}

func TestGenerateSalt(t *testing.T) {
	masterKey, _ := GenerateMasterKey()
	encryptor, _ := NewAESEncryptor(masterKey)

	// 生成多个盐值
	salts := make([][]byte, 10)
	for i := 0; i < 10; i++ {
		salt, err := encryptor.GenerateSalt()
		if err != nil {
			t.Fatalf("GenerateSalt() error = %v", err)
		}

		// 验证长度
		if len(salt) != SaltSize {
			t.Errorf("Salt size = %d, want %d", len(salt), SaltSize)
		}

		salts[i] = salt
	}

	// 验证唯一性（随机生成的盐值应该都不同）
	for i := 0; i < len(salts); i++ {
		for j := i + 1; j < len(salts); j++ {
			if hex.EncodeToString(salts[i]) == hex.EncodeToString(salts[j]) {
				t.Error("Generated salts should be unique")
			}
		}
	}
}

func TestGenerateMasterKey(t *testing.T) {
	key1, err := GenerateMasterKey()
	if err != nil {
		t.Fatalf("GenerateMasterKey() error = %v", err)
	}

	// 验证长度
	if len(key1) != KeySize {
		t.Errorf("Master key size = %d, want %d", len(key1), KeySize)
	}

	// 生成多个密钥验证唯一性
	key2, _ := GenerateMasterKey()
	if hex.EncodeToString(key1) == hex.EncodeToString(key2) {
		t.Error("Generated master keys should be unique")
	}
}

func TestGenerateMasterKeyHex(t *testing.T) {
	keyHex, err := GenerateMasterKeyHex()
	if err != nil {
		t.Fatalf("GenerateMasterKeyHex() error = %v", err)
	}

	// 验证长度（32字节 = 64个hex字符）
	if len(keyHex) != KeySize*2 {
		t.Errorf("Master key hex length = %d, want %d", len(keyHex), KeySize*2)
	}

	// 验证是否为有效的hex字符串
	_, err = hex.DecodeString(keyHex)
	if err != nil {
		t.Errorf("Generated key hex is not valid: %v", err)
	}

	// 验证可以用于创建加密器
	_, err = NewAESEncryptorFromHex(keyHex)
	if err != nil {
		t.Errorf("Cannot create encryptor from generated key hex: %v", err)
	}
}

func TestClearBytes(t *testing.T) {
	data := []byte{1, 2, 3, 4, 5}
	ClearBytes(data)

	for i, b := range data {
		if b != 0 {
			t.Errorf("Byte at index %d = %d, want 0", i, b)
		}
	}
}

func TestClearString(t *testing.T) {
	str := "sensitive-data"
	ClearString(&str)

	if str != "" {
		t.Errorf("String = %q, want empty string", str)
	}
}

// Benchmark tests
func BenchmarkEncrypt(b *testing.B) {
	masterKey, _ := GenerateMasterKey()
	encryptor, _ := NewAESEncryptor(masterKey)
	salt, _ := encryptor.GenerateSalt()
	plaintext := "sk-1234567890abcdef1234567890abcdef"

	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		_, _, _ = encryptor.Encrypt(plaintext, salt)
	}
}

func BenchmarkDecrypt(b *testing.B) {
	masterKey, _ := GenerateMasterKey()
	encryptor, _ := NewAESEncryptor(masterKey)
	salt, _ := encryptor.GenerateSalt()
	plaintext := "sk-1234567890abcdef1234567890abcdef"
	ciphertext, nonce, _ := encryptor.Encrypt(plaintext, salt)

	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		_, _ = encryptor.Decrypt(ciphertext, nonce, salt)
	}
}

func BenchmarkGenerateSalt(b *testing.B) {
	masterKey, _ := GenerateMasterKey()
	encryptor, _ := NewAESEncryptor(masterKey)

	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		_, _ = encryptor.GenerateSalt()
	}
}
