//
//  RegisterUseCase.swift
//  BBLearning
//
//  Created by Claude Code on 2025-10-13.
//

import Foundation
import Combine

/// 注册用例
final class RegisterUseCase {
    private let authRepository: AuthRepositoryProtocol

    init(authRepository: AuthRepositoryProtocol) {
        self.authRepository = authRepository
    }

    /// 执行注册
    /// - Parameters:
    ///   - username: 用户名
    ///   - password: 密码
    ///   - confirmPassword: 确认密码
    ///   - nickname: 昵称
    ///   - grade: 年级
    /// - Returns: 注册的用户信息
    func execute(username: String, password: String, confirmPassword: String, nickname: String, grade: Int) -> AnyPublisher<User, APIError> {
        // 1. 验证用户名
        guard Validator.isValidUsername(username) else {
            let error = Validator.usernameError(for: username) ?? "用户名格式错误"
            return Fail(error: APIError.parameterError(error)).eraseToAnyPublisher()
        }

        // 2. 验证密码
        guard Validator.isValidPassword(password) else {
            let error = Validator.passwordError(for: password) ?? "密码格式错误"
            return Fail(error: APIError.parameterError(error)).eraseToAnyPublisher()
        }

        // 3. 验证两次密码是否一致
        guard password == confirmPassword else {
            return Fail(error: APIError.parameterError("两次输入的密码不一致")).eraseToAnyPublisher()
        }

        // 4. 验证昵称
        guard Validator.isValidNickname(nickname) else {
            let error = Validator.nicknameError(for: nickname) ?? "昵称格式错误"
            return Fail(error: APIError.parameterError(error)).eraseToAnyPublisher()
        }

        // 5. 验证年级
        guard Validator.isValidGrade(grade) else {
            let error = Validator.gradeError(for: grade) ?? "年级选择错误"
            return Fail(error: APIError.parameterError(error)).eraseToAnyPublisher()
        }

        // 6. 检查用户名是否可用
        return authRepository.checkUsernameAvailability(username)
            .flatMap { [weak self] isAvailable -> AnyPublisher<User, APIError> in
                guard let self = self else {
                    return Fail(error: APIError.unknown).eraseToAnyPublisher()
                }

                guard isAvailable else {
                    return Fail(error: APIError.parameterError("用户名已被使用")).eraseToAnyPublisher()
                }

                // 7. 调用API注册
                return self.authRepository.register(username: username, password: password, nickname: nickname, grade: grade)
                    .handleEvents(receiveOutput: { user in
                        // 8. 记录日志
                        Logger.shared.info("用户注册成功: \(username)")
                    })
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }

    /// 检查用户名是否可用
    /// - Parameter username: 用户名
    /// - Returns: 是否可用
    func checkUsernameAvailability(_ username: String) -> AnyPublisher<Bool, APIError> {
        guard Validator.isValidUsername(username) else {
            return Just(false)
                .setFailureType(to: APIError.self)
                .eraseToAnyPublisher()
        }

        return authRepository.checkUsernameAvailability(username)
    }

    /// 验证密码强度
    /// - Parameter password: 密码
    /// - Returns: 密码强度等级和提示
    func checkPasswordStrength(_ password: String) -> (strength: PasswordStrength, message: String) {
        if password.isEmpty {
            return (.weak, "请输入密码")
        }

        if password.count < Configuration.minPasswordLength {
            return (.weak, "密码长度至少\(Configuration.minPasswordLength)位")
        }

        if password.count > Configuration.maxPasswordLength {
            return (.weak, "密码长度不能超过\(Configuration.maxPasswordLength)位")
        }

        if Validator.isStrongPassword(password) {
            return (.strong, "密码强度高")
        } else if Validator.isValidPassword(password) {
            return (.medium, "密码强度中等")
        } else {
            return (.weak, "密码强度弱")
        }
    }

    enum PasswordStrength {
        case weak
        case medium
        case strong

        var color: String {
            switch self {
            case .weak: return "red"
            case .medium: return "orange"
            case .strong: return "green"
            }
        }
    }
}
