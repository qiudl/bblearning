//
//  BiometricAuthUseCase.swift
//  BBLearningApp
//
//  Created by Claude Code on 2025-10-15.
//  生物识别认证用例 - 协调生物识别登录业务流程
//

import Foundation
import Combine

/// 生物识别认证用例
final class BiometricAuthUseCase {

    // MARK: - Dependencies

    private let biometricManager: BiometricManager
    private let credentialManager: BiometricCredentialManager
    private let authRepository: AuthRepositoryProtocol

    // MARK: - Initialization

    init(
        biometricManager: BiometricManager = .shared,
        credentialManager: BiometricCredentialManager = .shared,
        authRepository: AuthRepositoryProtocol = DIContainer.shared.resolve(AuthRepositoryProtocol.self)
    ) {
        self.biometricManager = biometricManager
        self.credentialManager = credentialManager
        self.authRepository = authRepository
    }

    // MARK: - Public Methods

    /// 启用生物识别登录（保存凭证）
    /// - Parameters:
    ///   - username: 用户名
    ///   - accessToken: 访问令牌
    ///   - refreshToken: 刷新令牌
    ///   - expiresIn: 令牌有效期（秒）
    /// - Returns: 成功或失败
    func enableBiometricAuth(
        username: String,
        accessToken: String,
        refreshToken: String,
        expiresIn: TimeInterval
    ) -> AnyPublisher<Void, Error> {
        return Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(NSError(domain: "BiometricAuthUseCase", code: -1)))
                return
            }

            // 检查设备支持
            guard self.biometricManager.isBiometricAvailable() else {
                promise(.failure(BiometricError.notAvailable))
                return
            }

            // 创建凭证
            let credential = BiometricCredential(
                username: username,
                accessToken: accessToken,
                refreshToken: refreshToken,
                expiresAt: Date().addingTimeInterval(expiresIn)
            )

            // 保存凭证
            let result = self.credentialManager.saveCredential(credential)

            switch result {
            case .success:
                Logger.shared.info("生物识别登录已启用: \(username)")
                promise(.success(()))
            case .failure(let error):
                Logger.shared.error("启用生物识别登录失败: \(error)")
                promise(.failure(error))
            }
        }
        .eraseToAnyPublisher()
    }

    /// 使用生物识别登录
    /// - Returns: 登录响应或错误
    func loginWithBiometric() -> AnyPublisher<LoginResponse, Error> {
        return biometricManager.authenticate(reason: "使用生物识别快速登录")
            .mapError { $0 as Error }
            .flatMap { [weak self] _ -> AnyPublisher<LoginResponse, Error> in
                guard let self = self else {
                    return Fail(error: NSError(domain: "BiometricAuthUseCase", code: -1))
                        .eraseToAnyPublisher()
                }

                // 认证成功，读取凭证
                let result = self.credentialManager.retrieveCredential()

                switch result {
                case .success(let credential):
                    // 检查令牌是否过期
                    if credential.isExpired {
                        Logger.shared.info("凭证已过期，尝试刷新令牌")
                        return self.refreshTokenAndLogin(credential: credential)
                    } else {
                        // 令牌有效，直接登录
                        Logger.shared.info("使用生物识别登录成功: \(credential.username)")
                        return Just(LoginResponse(
                            user: User(
                                id: 0,  // 需要从后端验证获取
                                username: credential.username,
                                email: credential.username,
                                grade: 7
                            ),
                            accessToken: credential.accessToken,
                            refreshToken: credential.refreshToken,
                            expiresIn: Int(credential.expiresAt.timeIntervalSince(Date()))
                        ))
                        .setFailureType(to: Error.self)
                        .eraseToAnyPublisher()
                    }

                case .failure(let error):
                    Logger.shared.error("读取凭证失败: \(error)")
                    return Fail(error: error)
                        .eraseToAnyPublisher()
                }
            }
            .eraseToAnyPublisher()
    }

    /// 禁用生物识别登录（删除凭证）
    /// - Returns: 成功或失败
    func disableBiometricAuth() -> AnyPublisher<Void, Error> {
        return Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(NSError(domain: "BiometricAuthUseCase", code: -1)))
                return
            }

            let result = self.credentialManager.deleteCredential()

            switch result {
            case .success:
                Logger.shared.info("生物识别登录已禁用")
                promise(.success(()))
            case .failure(let error):
                Logger.shared.error("禁用生物识别登录失败: \(error)")
                promise(.failure(error))
            }
        }
        .eraseToAnyPublisher()
    }

    /// 检查是否已启用生物识别登录
    /// - Returns: 是否已启用
    func isBiometricAuthEnabled() -> Bool {
        return credentialManager.hasCredential()
    }

    /// 检查设备是否支持生物识别
    /// - Returns: 是否支持
    func isBiometricAvailable() -> Bool {
        return biometricManager.isBiometricAvailable()
    }

    /// 获取生物识别类型
    /// - Returns: 生物识别类型
    func getBiometricType() -> BiometricType {
        return biometricManager.biometricType()
    }

    /// 获取生物识别类型描述
    /// - Returns: 用户友好的描述文本
    func getBiometricTypeDescription() -> String {
        return biometricManager.biometricTypeDescription()
    }

    // MARK: - Private Methods

    /// 刷新令牌并登录
    private func refreshTokenAndLogin(credential: BiometricCredential) -> AnyPublisher<LoginResponse, Error> {
        // 使用refreshToken刷新访问令牌
        return authRepository.refreshToken(credential.refreshToken)
            .handleEvents(
                receiveOutput: { [weak self] response in
                    // 更新保存的凭证
                    let newCredential = BiometricCredential(
                        username: credential.username,
                        accessToken: response.accessToken,
                        refreshToken: response.refreshToken,
                        expiresAt: Date().addingTimeInterval(TimeInterval(response.expiresIn))
                    )
                    _ = self?.credentialManager.saveCredential(newCredential)
                    Logger.shared.info("令牌刷新成功，凭证已更新")
                }
            )
            .mapError { error in
                // 刷新失败，可能refreshToken也过期了
                Logger.shared.error("令牌刷新失败: \(error)")
                // 删除无效凭证
                _ = self.credentialManager.deleteCredential()
                return error
            }
            .eraseToAnyPublisher()
    }
}

// MARK: - Preview Helper

#if DEBUG
extension BiometricAuthUseCase {
    static var mock: BiometricAuthUseCase {
        return BiometricAuthUseCase()
    }

    /// 模拟启用生物识别
    func mockEnableBiometric() -> AnyPublisher<Void, Error> {
        return enableBiometricAuth(
            username: "test@example.com",
            accessToken: "mock_access_token_" + UUID().uuidString,
            refreshToken: "mock_refresh_token_" + UUID().uuidString,
            expiresIn: 3600
        )
    }
}
#endif
