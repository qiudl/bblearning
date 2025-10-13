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

    private let loginUseCase: LoginUseCase

    init(loginUseCase: LoginUseCase = DIContainer.shared.resolve(LoginUseCase.self)) {
        self.loginUseCase = loginUseCase
        super.init()
        loadSavedCredentials()
    }

    /// 加载保存的凭证
    private func loadSavedCredentials() {
        if UserDefaultsManager.shared.rememberPassword {
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
                Logger.shared.info("登录成功: \(user.username)")
                self?.isLoginSuccessful = true
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
}
