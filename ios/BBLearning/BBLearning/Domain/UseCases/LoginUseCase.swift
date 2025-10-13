//
//  LoginUseCase.swift
//  BBLearning
//
//  Created by Claude Code on 2025-10-13.
//

import Foundation
import Combine

/// 登录用例
final class LoginUseCase {
    private let authRepository: AuthRepositoryProtocol
    private let keychainManager: KeychainManager
    private let userDefaultsManager: UserDefaultsManager

    init(authRepository: AuthRepositoryProtocol,
         keychainManager: KeychainManager = .shared,
         userDefaultsManager: UserDefaultsManager = .shared) {
        self.authRepository = authRepository
        self.keychainManager = keychainManager
        self.userDefaultsManager = userDefaultsManager
    }

    /// 执行登录
    /// - Parameters:
    ///   - username: 用户名
    ///   - password: 密码
    ///   - rememberPassword: 是否记住密码
    /// - Returns: 登录的用户信息
    func execute(username: String, password: String, rememberPassword: Bool = false) -> AnyPublisher<User, APIError> {
        // 1. 验证输入
        guard Validator.isValidUsername(username) else {
            let error = Validator.usernameError(for: username) ?? "用户名格式错误"
            return Fail(error: APIError.parameterError(error)).eraseToAnyPublisher()
        }

        guard Validator.isValidPassword(password) else {
            let error = Validator.passwordError(for: password) ?? "密码格式错误"
            return Fail(error: APIError.parameterError(error)).eraseToAnyPublisher()
        }

        // 2. 调用API登录
        return authRepository.login(username: username, password: password)
            .flatMap { [weak self] response -> AnyPublisher<User, APIError> in
                guard let self = self else {
                    return Fail(error: APIError.unknown).eraseToAnyPublisher()
                }

                // 3. 保存Token到Keychain
                self.keychainManager.saveAccessToken(response.accessToken)
                self.keychainManager.saveRefreshToken(response.refreshToken)

                // 4. 保存用户ID和用户名
                self.keychainManager.saveUserId(response.user.id)
                self.keychainManager.saveUsername(response.user.username)

                // 5. 如果选择记住密码，保存到Keychain
                if rememberPassword {
                    self.keychainManager.savePassword(password, forUsername: username)
                } else {
                    self.keychainManager.deletePassword(forUsername: username)
                }

                // 6. 更新UserDefaults
                self.userDefaultsManager.selectedGrade = response.user.grade
                self.userDefaultsManager.rememberPassword = rememberPassword

                // 7. 记录日志
                Logger.shared.info("用户登录成功: \(username)")

                return Just(response.user)
                    .setFailureType(to: APIError.self)
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }

    /// 获取记住的密码
    /// - Parameter username: 用户名
    /// - Returns: 密码（如果有）
    func getSavedPassword(for username: String) -> String? {
        return keychainManager.getPassword(forUsername: username)
    }

    /// 检查是否有保存的登录信息
    /// - Returns: 是否已登录
    func isLoggedIn() -> Bool {
        return keychainManager.getAccessToken() != nil
    }
}
