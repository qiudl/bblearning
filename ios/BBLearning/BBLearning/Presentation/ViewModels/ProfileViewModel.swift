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
        // 从UserDefaults或AppState获取用户信息
        if let userData = UserDefaultsManager.shared.currentUser {
            // TODO: 解析用户数据
        }
    }

    func logout() {
        executeTask(
            logoutUseCase.execute(),
            onSuccess: { [weak self] _ in
                // 触发AppState登出
                NotificationCenter.default.post(name: .userDidLogout, object: nil)
            }
        )
    }
}

extension Notification.Name {
    static let userDidLogout = Notification.Name("userDidLogout")
}
