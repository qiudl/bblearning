//
//  LoginViewModel.swift
//  BBLearning
//
//  Created by Claude Code on 2025-10-13.
//

import Foundation
import Combine

final class LoginViewModel: BaseViewModel {
    @Published var username: String = ""
    @Published var password: String = ""
    @Published var rememberPassword: Bool = false
    @Published var isLoginSuccessful: Bool = false

    // 生物识别相关状态
    @Published var isBiometricAvailable: Bool = false
    @Published var isBiometricEnabled: Bool = false
    @Published var biometricType: BiometricType = .none
    @Published var showBiometricEnablePrompt: Bool = false

    private let loginUseCase: LoginUseCase
    private let biometricAuthUseCase: BiometricAuthUseCase

    // 保存登录响应（用于启用生物识别）
    private var lastLoginResponse: (accessToken: String, refreshToken: String, expiresIn: TimeInterval)?

    init(
        loginUseCase: LoginUseCase = DIContainer.shared.resolve(LoginUseCase.self),
        biometricAuthUseCase: BiometricAuthUseCase = BiometricAuthUseCase()
    ) {
        self.loginUseCase = loginUseCase
        self.biometricAuthUseCase = biometricAuthUseCase
        super.init()
        loadSavedCredentials()
        checkBiometricAvailability()
    }

    /// 加载保存的凭证
    private func loadSavedCredentials() {
        if UserDefaultsManager.shared.isRememberPassword {
            // 可以在这里加载上次登录的用户名
        }
    }

    /// 登录
    func login() {
        // 验证输入
        guard !username.trimmed.isEmpty else {
            errorMessage = "请输入用户名"
            return
        }

        guard !password.isEmpty else {
            errorMessage = "请输入密码"
            return
        }

        executeTask(
            loginUseCase.execute(username: username, password: password, rememberPassword: rememberPassword),
            onSuccess: { [weak self] user in
                guard let self = self else { return }
                Logger.shared.info("登录成功: \(user.username)")

                // 从Keychain读取刚保存的tokens
                if let accessToken = KeychainManager.shared.getAccessToken(),
                   let refreshToken = KeychainManager.shared.getRefreshToken() {
                    // 保存登录响应（假设token有效期1小时）
                    self.lastLoginResponse = (
                        accessToken: accessToken,
                        refreshToken: refreshToken,
                        expiresIn: 3600
                    )

                    // 提示启用生物识别（如果设备支持且未启用）
                    self.promptEnableBiometric()
                }

                self.isLoginSuccessful = true
            }
        )
    }

    /// 快速登录（使用已保存的密码）
    func quickLogin() {
        guard !username.trimmed.isEmpty else { return }

        if let savedPassword = loginUseCase.getSavedPassword(for: username) {
            password = savedPassword
            rememberPassword = true
            login()
        }
    }

    /// 检查是否已登录
    var isLoggedIn: Bool {
        loginUseCase.isLoggedIn()
    }

    // MARK: - 生物识别功能

    /// 检查生物识别可用性
    private func checkBiometricAvailability() {
        isBiometricAvailable = biometricAuthUseCase.isBiometricAvailable()
        isBiometricEnabled = biometricAuthUseCase.isBiometricAuthEnabled()
        biometricType = biometricAuthUseCase.getBiometricType()

        print("🔐 [LoginViewModel] 生物识别状态检查:")
        print("   - isBiometricAvailable: \(isBiometricAvailable)")
        print("   - isBiometricEnabled: \(isBiometricEnabled)")
        print("   - biometricType: \(biometricType)")

        Logger.shared.info("生物识别状态 - 可用: \(isBiometricAvailable), 已启用: \(isBiometricEnabled), 类型: \(biometricType)")
    }

    /// 刷新生物识别状态（供View层调用）
    func refreshBiometricStatus() {
        DispatchQueue.main.async { [weak self] in
            self?.checkBiometricAvailability()
        }
    }

    /// 使用生物识别登录
    func loginWithBiometric() {
        guard isBiometricAvailable else {
            errorMessage = "您的设备不支持生物识别"
            return
        }

        guard isBiometricEnabled else {
            errorMessage = "请先启用生物识别登录"
            return
        }

        executeTask(
            biometricAuthUseCase.loginWithBiometric(),
            onSuccess: { [weak self] response in
                Logger.shared.info("生物识别登录成功: \(response.user.username)")
                self?.isLoginSuccessful = true
            },
            onError: { [weak self] error in
                // 处理特定的生物识别错误
                if let biometricError = error as? BiometricError {
                    switch biometricError {
                    case .userCancel:
                        // 用户取消，不显示错误
                        break
                    case .userFallback:
                        // 用户选择密码登录，不做处理
                        Logger.shared.info("用户选择密码登录")
                    case .biometryChanged:
                        // 生物识别数据已更改，禁用功能
                        self?.disableBiometricAuth()
                    default:
                        self?.errorMessage = biometricError.errorDescription
                    }
                } else {
                    self?.errorMessage = "生物识别登录失败: \(error.localizedDescription)"
                }
            }
        )
    }

    /// 启用生物识别登录（在登录成功后调用）
    func enableBiometricAuth(accessToken: String, refreshToken: String, expiresIn: TimeInterval) {
        guard isBiometricAvailable else {
            Logger.shared.warning("设备不支持生物识别，跳过启用")
            return
        }

        executeTask(
            biometricAuthUseCase.enableBiometricAuth(
                username: username,
                accessToken: accessToken,
                refreshToken: refreshToken,
                expiresIn: expiresIn
            ),
            onSuccess: { [weak self] in
                Logger.shared.info("生物识别登录已启用")
                self?.isBiometricEnabled = true
                self?.showBiometricEnablePrompt = false
            }
        )
    }

    /// 使用保存的登录响应启用生物识别
    func enableBiometricAuthFromLastLogin() {
        guard let response = lastLoginResponse else {
            Logger.shared.error("未找到登录响应信息")
            return
        }

        enableBiometricAuth(
            accessToken: response.accessToken,
            refreshToken: response.refreshToken,
            expiresIn: response.expiresIn
        )
    }

    /// 禁用生物识别登录
    func disableBiometricAuth() {
        executeTask(
            biometricAuthUseCase.disableBiometricAuth(),
            onSuccess: { [weak self] in
                Logger.shared.info("生物识别登录已禁用")
                self?.isBiometricEnabled = false
            }
        )
    }

    /// 显示启用生物识别提示（在登录成功后调用）
    func promptEnableBiometric() {
        // 只在设备支持且未启用时提示
        if isBiometricAvailable && !isBiometricEnabled {
            showBiometricEnablePrompt = true
        }
    }

    /// 获取生物识别类型描述
    var biometricTypeDescription: String {
        biometricAuthUseCase.getBiometricTypeDescription()
    }
}
