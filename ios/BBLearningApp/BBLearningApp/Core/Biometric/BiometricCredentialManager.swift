//
//  BiometricCredentialManager.swift
//  BBLearningApp
//
//  Created by Claude Code on 2025-10-15.
//  生物识别凭证管理器 - 安全存储和管理登录凭证
//

import Foundation
import Security
import CryptoKit

/// 生物识别凭证
struct BiometricCredential: Codable {
    let username: String
    let accessToken: String
    let refreshToken: String
    let expiresAt: Date

    var isExpired: Bool {
        return Date() >= expiresAt
    }
}

/// 凭证存储错误
enum CredentialError: LocalizedError {
    case storeFailed            // 存储失败
    case retrieveFailed         // 读取失败
    case deleteFailed           // 删除失败
    case encryptionFailed       // 加密失败
    case decryptionFailed       // 解密失败
    case biometryInvalidated    // 生物识别数据已更改
    case notFound               // 未找到凭证

    var errorDescription: String? {
        switch self {
        case .storeFailed:
            return "凭证存储失败"
        case .retrieveFailed:
            return "凭证读取失败"
        case .deleteFailed:
            return "凭证删除失败"
        case .encryptionFailed:
            return "数据加密失败"
        case .decryptionFailed:
            return "数据解密失败"
        case .biometryInvalidated:
            return "生物识别数据已更改，请重新启用"
        case .notFound:
            return "未找到保存的凭证"
        }
    }
}

/// 生物识别凭证管理器
final class BiometricCredentialManager {

    // MARK: - Singleton

    static let shared = BiometricCredentialManager()

    private init() {}

    // MARK: - Constants

    private enum KeychainKey {
        static let service = "com.bblearning.app.biometric"
        static let account = "biometric_credential"
        static let encryptionKey = "encryption_key"
    }

    // MARK: - Public Methods

    /// 保存凭证到Keychain（加密存储）
    /// - Parameter credential: 要保存的凭证
    /// - Returns: 成功或失败
    func saveCredential(_ credential: BiometricCredential) -> Result<Void, CredentialError> {
        do {
            // 序列化凭证
            let data = try JSONEncoder().encode(credential)

            // 加密数据
            guard let encryptedData = encrypt(data) else {
                return .failure(.encryptionFailed)
            }

            // 删除旧的凭证
            _ = deleteCredential()

            // 构建Keychain查询
            let query: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: KeychainKey.service,
                kSecAttrAccount as String: KeychainKey.account,
                kSecValueData as String: encryptedData,
                kSecAttrAccessControl as String: createAccessControl()
            ]

            // 添加到Keychain
            let status = SecItemAdd(query as CFDictionary, nil)

            if status == errSecSuccess {
                Logger.shared.info("生物识别凭证保存成功")
                return .success(())
            } else {
                Logger.shared.error("生物识别凭证保存失败: \(status)")
                return .failure(.storeFailed)
            }
        } catch {
            Logger.shared.error("凭证序列化失败: \(error)")
            return .failure(.storeFailed)
        }
    }

    /// 读取凭证（需要生物识别验证）
    /// - Returns: 凭证或错误
    func retrieveCredential() -> Result<BiometricCredential, CredentialError> {
        // 构建Keychain查询
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: KeychainKey.service,
            kSecAttrAccount as String: KeychainKey.account,
            kSecReturnData as String: true,
            kSecUseOperationPrompt as String: "验证您的身份以访问登录信息"
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        // 处理各种状态码
        switch status {
        case errSecSuccess:
            guard let encryptedData = result as? Data else {
                return .failure(.retrieveFailed)
            }

            // 解密数据
            guard let decryptedData = decrypt(encryptedData) else {
                return .failure(.decryptionFailed)
            }

            // 反序列化凭证
            do {
                let credential = try JSONDecoder().decode(BiometricCredential.self, from: decryptedData)
                Logger.shared.info("生物识别凭证读取成功")
                return .success(credential)
            } catch {
                Logger.shared.error("凭证反序列化失败: \(error)")
                return .failure(.retrieveFailed)
            }

        case errSecItemNotFound:
            return .failure(.notFound)

        case errSecAuthFailed:
            // 生物识别验证失败或已更改
            return .failure(.biometryInvalidated)

        default:
            Logger.shared.error("Keychain读取失败: \(status)")
            return .failure(.retrieveFailed)
        }
    }

    /// 删除保存的凭证
    /// - Returns: 成功或失败
    @discardableResult
    func deleteCredential() -> Result<Void, CredentialError> {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: KeychainKey.service,
            kSecAttrAccount as String: KeychainKey.account
        ]

        let status = SecItemDelete(query as CFDictionary)

        if status == errSecSuccess || status == errSecItemNotFound {
            Logger.shared.info("生物识别凭证已删除")
            return .success(())
        } else {
            Logger.shared.error("凭证删除失败: \(status)")
            return .failure(.deleteFailed)
        }
    }

    /// 检查是否已保存凭证
    /// - Returns: 是否存在凭证
    func hasCredential() -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: KeychainKey.service,
            kSecAttrAccount as String: KeychainKey.account,
            kSecReturnData as String: false
        ]

        let status = SecItemCopyMatching(query as CFDictionary, nil)
        return status == errSecSuccess
    }

    // MARK: - Private Methods

    /// 创建访问控制配置
    /// - biometryCurrentSet: 当生物识别数据更改时自动失效
    /// - whenUnlockedThisDeviceOnly: 仅在设备解锁时可访问，不同步到iCloud
    private func createAccessControl() -> SecAccessControl {
        var error: Unmanaged<CFError>?

        let access = SecAccessControlCreateWithFlags(
            kCFAllocatorDefault,
            kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
            .biometryCurrentSet,  // 关键标志：生物识别数据更改时自动失效
            &error
        )

        if let error = error {
            Logger.shared.error("创建访问控制失败: \(error.takeRetainedValue())")
        }

        return access!
    }

    /// 获取或创建加密密钥
    private func getOrCreateEncryptionKey() -> SymmetricKey {
        // 尝试从Keychain读取
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: KeychainKey.service,
            kSecAttrAccount as String: KeychainKey.encryptionKey,
            kSecReturnData as String: true
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        if status == errSecSuccess, let keyData = result as? Data {
            return SymmetricKey(data: keyData)
        }

        // 创建新密钥
        let key = SymmetricKey(size: .bits256)
        let keyData = key.withUnsafeBytes { Data($0) }

        // 保存到Keychain
        let addQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: KeychainKey.service,
            kSecAttrAccount as String: KeychainKey.encryptionKey,
            kSecValueData as String: keyData,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]

        SecItemAdd(addQuery as CFDictionary, nil)

        return key
    }

    /// 使用AES-256-GCM加密数据
    private func encrypt(_ data: Data) -> Data? {
        do {
            let key = getOrCreateEncryptionKey()
            let sealedBox = try AES.GCM.seal(data, using: key)
            return sealedBox.combined
        } catch {
            Logger.shared.error("AES加密失败: \(error)")
            return nil
        }
    }

    /// 使用AES-256-GCM解密数据
    private func decrypt(_ data: Data) -> Data? {
        do {
            let key = getOrCreateEncryptionKey()
            let sealedBox = try AES.GCM.SealedBox(combined: data)
            return try AES.GCM.open(sealedBox, using: key)
        } catch {
            Logger.shared.error("AES解密失败: \(error)")
            return nil
        }
    }
}

// MARK: - Extensions

extension BiometricCredentialManager {
    /// 清除所有凭证和加密密钥
    func clearAll() {
        // 删除凭证
        _ = deleteCredential()

        // 删除加密密钥
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: KeychainKey.service,
            kSecAttrAccount as String: KeychainKey.encryptionKey
        ]
        SecItemDelete(query as CFDictionary)

        Logger.shared.info("所有生物识别数据已清除")
    }
}

// MARK: - Preview Helper

#if DEBUG
extension BiometricCredentialManager {
    static var mock: BiometricCredentialManager {
        return BiometricCredentialManager.shared
    }

    func saveMockCredential() -> Result<Void, CredentialError> {
        let credential = BiometricCredential(
            username: "test@example.com",
            accessToken: "mock_access_token",
            refreshToken: "mock_refresh_token",
            expiresAt: Date().addingTimeInterval(3600)
        )
        return saveCredential(credential)
    }
}
#endif
