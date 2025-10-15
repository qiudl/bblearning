//
//  RegisterViewModel.swift
//  BBLearning
//
//  Created by Claude Code on 2025-10-13.
//

import Foundation
import Combine

final class RegisterViewModel: BaseViewModel {
    @Published var username: String = ""
    @Published var password: String = ""
    @Published var confirmPassword: String = ""
    @Published var nickname: String = ""
    @Published var selectedGrade: Int = 7
    @Published var isRegisterSuccessful: Bool = false
    @Published var usernameAvailable: Bool? = nil
    @Published var passwordStrength: RegisterUseCase.PasswordStrength = .weak

    private let registerUseCase: RegisterUseCase
    private var usernameCheckWorkItem: DispatchWorkItem?

    let grades = [7, 8, 9]

    init(registerUseCase: RegisterUseCase = DIContainer.shared.resolve(RegisterUseCase.self)) {
        self.registerUseCase = registerUseCase
        super.init()
        setupObservers()
    }

    private func setupObservers() {
        // 监听用户名变化，延迟检查可用性
        $username
            .debounce(for: .milliseconds(500), scheduler: DispatchQueue.main)
            .removeDuplicates()
            .sink { [weak self] username in
                self?.checkUsernameAvailability(username)
            }
            .store(in: &cancellables)

        // 监听密码变化，更新强度
        $password
            .sink { [weak self] password in
                self?.updatePasswordStrength(password)
            }
            .store(in: &cancellables)
    }

    /// 注册
    func register() {
        executeTask(
            registerUseCase.execute(
                username: username,
                password: password,
                confirmPassword: confirmPassword,
                nickname: nickname,
                grade: selectedGrade
            ),
            onSuccess: { [weak self] user in
                Logger.shared.info("注册成功: \(user.username)")
                self?.isRegisterSuccessful = true
            }
        )
    }

    /// 检查用户名可用性
    private func checkUsernameAvailability(_ username: String) {
        guard !username.trimmed.isEmpty else {
            usernameAvailable = nil
            return
        }

        usernameCheckWorkItem?.cancel()

        let workItem = DispatchWorkItem { [weak self] in
            guard let self = self else { return }

            self.registerUseCase.checkUsernameAvailability(username)
                .receive(on: DispatchQueue.main)
                .sink(
                    receiveCompletion: { _ in },
                    receiveValue: { [weak self] available in
                        self?.usernameAvailable = available
                    }
                )
                .store(in: &self.cancellables)
        }

        usernameCheckWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: workItem)
    }

    /// 更新密码强度
    private func updatePasswordStrength(_ password: String) {
        let (strength, _) = registerUseCase.checkPasswordStrength(password)
        passwordStrength = strength
    }

    /// 密码强度描述
    var passwordStrengthText: String {
        let (_, message) = registerUseCase.checkPasswordStrength(password)
        return message
    }

    /// 密码强度颜色
    var passwordStrengthColor: String {
        passwordStrength.color
    }

    /// 表单是否有效
    var isFormValid: Bool {
        return !username.isEmpty &&
               !password.isEmpty &&
               !confirmPassword.isEmpty &&
               !nickname.isEmpty &&
               usernameAvailable == true &&
               passwordStrength != .weak
    }
}
