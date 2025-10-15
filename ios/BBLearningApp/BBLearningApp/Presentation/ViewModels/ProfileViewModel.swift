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

    // 生物识别相关状态
    @Published var isBiometricAvailable: Bool = false
    @Published var isBiometricEnabled: Bool = false
    @Published var biometricType: BiometricType = .none

    // 用户统计数据
    @Published var userStats: UserStats?

    // 头像管理
    @Published var showImagePicker: Bool = false
    @Published var selectedAvatar: UIImage?

    // 编辑状态
    @Published var isEditingProfile: Bool = false
    @Published var editedNickname: String = ""
    @Published var editedGrade: Int = 7
    @Published var editedGender: User.Gender?
    @Published var editedSchool: String = ""

    // 应用版本
    var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }

    private let logoutUseCase: LogoutUseCase
    private let biometricAuthUseCase: BiometricAuthUseCase

    init(
        logoutUseCase: LogoutUseCase = DIContainer.shared.resolve(LogoutUseCase.self),
        biometricAuthUseCase: BiometricAuthUseCase = BiometricAuthUseCase()
    ) {
        self.logoutUseCase = logoutUseCase
        self.biometricAuthUseCase = biometricAuthUseCase
        super.init()
        loadUserProfile()
        checkBiometricStatus()
    }

    private func loadUserProfile() {
        // 从AppState或Keychain获取用户信息
        // User info should be passed from AppState via environment object
        // or retrieved from a user repository

        // TODO: 实际应从API获取用户统计数据
        // 这里先使用模拟数据
        loadUserStats()
    }

    private func loadUserStats() {
        // TODO: 调用API获取真实数据
        // 暂时使用模拟数据
        userStats = UserStats(
            studyDays: 0,
            totalQuestions: 0,
            averageAccuracy: 0.0,
            currentStreak: 0,
            longestStreak: 0
        )
    }

    // MARK: - 个人资料管理

    func prepareEditProfile(user: User) {
        editedNickname = user.nickname
        editedGrade = user.grade
        editedGender = user.gender
        editedSchool = user.school ?? ""
    }

    func updateProfile() {
        // TODO: 调用API更新用户资料
        Logger.shared.info("更新用户资料: \(editedNickname), \(editedGrade)")

        // 更新本地user对象
        // 实际应通过API返回更新后的user
    }

    func uploadAvatar(_ image: UIImage) {
        isLoading = true

        // TODO: 上传头像到服务器
        // 这里模拟上传过程
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.isLoading = false
            Logger.shared.info("头像上传成功")
            // 更新user的avatar字段
        }
    }

    func logout() {
        executeTask(
            logoutUseCase.execute(),
            onSuccess: { _ in
                // 清除生物识别凭证
                self.disableBiometric()
                // 触发AppState登出
                NotificationCenter.default.post(name: .userDidLogout, object: nil)
            }
        )
    }

    // MARK: - 生物识别功能

    /// 检查生物识别状态
    private func checkBiometricStatus() {
        isBiometricAvailable = biometricAuthUseCase.isBiometricAvailable()
        isBiometricEnabled = biometricAuthUseCase.isBiometricAuthEnabled()
        biometricType = biometricAuthUseCase.getBiometricType()

        Logger.shared.info("生物识别状态检查 - 可用: \(isBiometricAvailable), 已启用: \(isBiometricEnabled)")
    }

    /// 切换生物识别开关
    func toggleBiometric(_ enabled: Bool) {
        if enabled {
            // 启用生物识别
            errorMessage = "请先在登录页面成功登录后启用生物识别"
            // 注意：实际启用需要在登录成功时进行，因为需要保存token
            // 这里只是UI反馈，实际状态不会改变
            isBiometricEnabled = false
        } else {
            // 禁用生物识别
            disableBiometric()
        }
    }

    /// 禁用生物识别
    private func disableBiometric() {
        executeTask(
            biometricAuthUseCase.disableBiometricAuth(),
            onSuccess: { [weak self] in
                Logger.shared.info("生物识别已禁用")
                self?.isBiometricEnabled = false
            }
        )
    }
}
