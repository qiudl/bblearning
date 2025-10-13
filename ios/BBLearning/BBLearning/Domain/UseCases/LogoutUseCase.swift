//
//  LogoutUseCase.swift
//  BBLearning
//
//  Created by Claude Code on 2025-10-13.
//

import Foundation
import Combine

/// 登出用例
final class LogoutUseCase {
    private let authRepository: AuthRepositoryProtocol
    private let keychainManager: KeychainManager
    private let realmManager: RealmManager

    init(authRepository: AuthRepositoryProtocol,
         keychainManager: KeychainManager = .shared,
         realmManager: RealmManager = .shared) {
        self.authRepository = authRepository
        self.keychainManager = keychainManager
        self.realmManager = realmManager
    }

    /// 执行登出
    /// - Parameter clearLocalData: 是否清除本地数据
    /// - Returns: 成功标识
    func execute(clearLocalData: Bool = false) -> AnyPublisher<Void, APIError> {
        // 1. 调用API登出（通知服务器）
        return authRepository.logout()
            .handleEvents(
                receiveOutput: { [weak self] _ in
                    self?.clearLocalSession(clearData: clearLocalData)
                },
                receiveCompletion: { [weak self] completion in
                    // 即使API调用失败，也要清除本地会话
                    if case .failure = completion {
                        self?.clearLocalSession(clearData: clearLocalData)
                    }
                }
            )
            .catch { [weak self] error -> AnyPublisher<Void, APIError> in
                // 即使登出API失败，仍然清除本地数据
                self?.clearLocalSession(clearData: clearLocalData)
                Logger.shared.warning("登出API调用失败，但已清除本地会话: \(error.localizedDescription)")
                return Just(()).setFailureType(to: APIError.self).eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }

    /// 清除本地会话数据
    /// - Parameter clearData: 是否清除所有本地数据
    private func clearLocalSession(clearData: Bool) {
        // 1. 清除Keychain中的认证信息
        keychainManager.deleteAccessToken()
        keychainManager.deleteRefreshToken()
        keychainManager.deleteUserId()
        keychainManager.deleteUsername()

        // 2. 如果需要清除所有数据
        if clearData {
            // 清除Keychain中的所有数据（包括记住的密码）
            keychainManager.clearAll()

            // 清除Realm数据库
            do {
                try realmManager.deleteAll()
                Logger.shared.info("已清除所有本地数据")
            } catch {
                Logger.shared.error("清除Realm数据失败: \(error.localizedDescription)")
            }

            // 重置UserDefaults（除了一些基本设置）
            let isDarkMode = UserDefaultsManager.shared.isDarkMode
            let notificationsEnabled = UserDefaultsManager.shared.notificationsEnabled

            UserDefaults.standard.removePersistentDomain(forName: Bundle.main.bundleIdentifier!)
            UserDefaults.standard.synchronize()

            // 恢复一些基本设置
            UserDefaultsManager.shared.isDarkMode = isDarkMode
            UserDefaultsManager.shared.notificationsEnabled = notificationsEnabled
        }

        // 3. 记录日志
        Logger.shared.info("用户登出成功，本地会话已清除")
    }

    /// 快速登出（不调用API，仅清除本地）
    func quickLogout() {
        clearLocalSession(clearData: false)
    }
}
