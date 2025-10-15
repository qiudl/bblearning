//
//  ProfileViewModel.swift
//  BBLearning
//
//  Created by Claude Code on 2025-10-13.
//

import Foundation
import Combine

final class ProfileViewModel: BaseViewModel {
    @Published var user: User?
    @Published var showLogoutAlert = false

    private let logoutUseCase: LogoutUseCase

    init(logoutUseCase: LogoutUseCase = DIContainer.shared.resolve(LogoutUseCase.self)) {
        self.logoutUseCase = logoutUseCase
        super.init()
        loadUserProfile()
    }

    private func loadUserProfile() {
        // 从AppState或Keychain获取用户信息
        // User info should be passed from AppState via environment object
        // or retrieved from a user repository
    }

    func logout() {
        executeTask(
            logoutUseCase.execute(),
            onSuccess: { _ in
                // 触发AppState登出
                NotificationCenter.default.post(name: .userDidLogout, object: nil)
            }
        )
    }
}
