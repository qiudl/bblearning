//
//  KeychainManager.swift
//  BBLearning
//
//  Created by Claude Code on 2025-10-13.
//

import Foundation
import KeychainAccess

/// Keychain管理器 - 用于安全存储敏感信息
final class KeychainManager {

    static let shared = KeychainManager()

    private let keychain: Keychain

    private enum Keys {
        static let accessToken = "access_token"
        static let refreshToken = "refresh_token"
        static let userId = "user_id"
        static let username = "username"
        static let userPassword = "user_password" // 可选：记住密码功能
    }

    private init() {
        self.keychain = Keychain(service: Configuration.bundleIdentifier)
            .accessibility(.afterFirstUnlock)
    }

    // MARK: - Access Token

    func saveAccessToken(_ token: String) {
        keychain[Keys.accessToken] = token
    }

    func getAccessToken() -> String? {
        return keychain[Keys.accessToken]
    }

    func deleteAccessToken() {
        try? keychain.remove(Keys.accessToken)
    }

    // MARK: - Refresh Token

    func saveRefreshToken(_ token: String) {
        keychain[Keys.refreshToken] = token
    }

    func getRefreshToken() -> String? {
        return keychain[Keys.refreshToken]
    }

    func deleteRefreshToken() {
        try? keychain.remove(Keys.refreshToken)
    }

    // MARK: - User Info

    func saveUserId(_ userId: Int) {
        keychain[Keys.userId] = String(userId)
    }

    func getUserId() -> Int? {
        guard let userIdString = keychain[Keys.userId] else { return nil }
        return Int(userIdString)
    }

    func deleteUserId() {
        try? keychain.remove(Keys.userId)
    }

    func saveUsername(_ username: String) {
        keychain[Keys.username] = username
    }

    func getUsername() -> String? {
        return keychain[Keys.username]
    }

    func deleteUsername() {
        try? keychain.remove(Keys.username)
    }

    // MARK: - Remember Password (Optional)

    func savePassword(_ password: String, for username: String) {
        keychain[Keys.userPassword + "_" + username] = password
    }

    func getPassword(for username: String) -> String? {
        return keychain[Keys.userPassword + "_" + username]
    }

    func deletePassword(for username: String) {
        try? keychain.remove(Keys.userPassword + "_" + username)
    }

    // MARK: - Clear All

    func clearAll() {
        try? keychain.removeAll()
        Logger.shared.info("Keychain cleared")
    }

    func clearAuthTokens() {
        try? keychain.remove(Keys.accessToken)
        try? keychain.remove(Keys.refreshToken)
        Logger.shared.info("Auth tokens cleared")
    }

    // MARK: - Generic Save/Get

    func save<T: Codable>(_ value: T, forKey key: String) throws {
        let encoder = JSONEncoder()
        let data = try encoder.encode(value)
        keychain[data: key] = data
    }

    func get<T: Codable>(forKey key: String, as type: T.Type) throws -> T? {
        guard let data = keychain[data: key] else { return nil }
        let decoder = JSONDecoder()
        return try decoder.decode(type, from: data)
    }

    func delete(forKey key: String) {
        try? keychain.remove(key)
    }
}
