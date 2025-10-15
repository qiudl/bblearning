//
//  BiometricManager.swift
//  BBLearningApp
//
//  Created by Claude Code on 2025-10-15.
//  生物识别管理器 - 负责Touch ID/Face ID检测和认证
//

import Foundation
import LocalAuthentication
import Combine

/// 生物识别类型
enum BiometricType {
    case touchID
    case faceID
    case none

    var displayName: String {
        switch self {
        case .touchID:
            return "Touch ID"
        case .faceID:
            return "Face ID"
        case .none:
            return "不支持"
        }
    }

    var iconName: String {
        switch self {
        case .touchID:
            return "touchid"
        case .faceID:
            return "faceid"
        case .none:
            return "xmark.circle"
        }
    }
}

/// 生物识别错误
enum BiometricError: LocalizedError {
    case notAvailable           // 设备不支持或未启用
    case notEnrolled            // 未录入生物识别数据
    case lockout                // 多次失败被锁定
    case userCancel             // 用户取消
    case userFallback           // 用户选择密码登录
    case systemCancel           // 系统取消（如来电）
    case passcodeNotSet         // 未设置设备密码
    case biometryChanged        // 生物识别数据已更改
    case unknown(Error)         // 其他错误

    var errorDescription: String? {
        switch self {
        case .notAvailable:
            return "您的设备不支持生物识别功能"
        case .notEnrolled:
            return "请先在系统设置中录入生物识别数据"
        case .lockout:
            return "生物识别已被锁定，请稍后再试或使用密码登录"
        case .userCancel:
            return "生物识别已取消"
        case .userFallback:
            return "已切换到密码登录"
        case .systemCancel:
            return "认证已被中断"
        case .passcodeNotSet:
            return "请先在系统设置中设置设备密码"
        case .biometryChanged:
            return "生物识别数据已更改，请重新启用生物识别登录"
        case .unknown(let error):
            return "认证失败: \(error.localizedDescription)"
        }
    }
}

/// 生物识别管理器
final class BiometricManager {

    // MARK: - Singleton

    static let shared = BiometricManager()

    private init() {}

    // MARK: - Debug Mode

    #if DEBUG
    /// 调试模式：强制启用生物识别（用于模拟器测试）
    var forceEnableForDebug: Bool = true
    #endif

    // MARK: - Public Methods

    /// 获取当前设备支持的生物识别类型
    func biometricType() -> BiometricType {
        #if DEBUG
        // 调试模式：在模拟器上返回Face ID
        if forceEnableForDebug {
            #if targetEnvironment(simulator)
            return .faceID
            #endif
        }
        #endif

        let context = LAContext()
        var error: NSError?

        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            return .none
        }

        switch context.biometryType {
        case .touchID:
            return .touchID
        case .faceID:
            return .faceID
        case .none:
            return .none
        @unknown default:
            return .none
        }
    }

    /// 检查设备是否支持生物识别
    func isBiometricAvailable() -> Bool {
        #if DEBUG
        // 调试模式：在模拟器上返回true
        if forceEnableForDebug {
            #if targetEnvironment(simulator)
            return true
            #endif
        }
        #endif

        let context = LAContext()
        var error: NSError?
        return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
    }

    /// 执行生物识别认证
    /// - Parameter reason: 认证原因提示
    /// - Returns: 认证结果的Publisher
    func authenticate(reason: String = "验证您的身份以登录") -> AnyPublisher<Void, BiometricError> {
        #if DEBUG
        // 调试模式：在模拟器上模拟成功
        if forceEnableForDebug {
            #if targetEnvironment(simulator)
            return Future { promise in
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    Logger.shared.info("⚠️ 模拟器模式：生物识别认证自动成功")
                    promise(.success(()))
                }
            }
            .eraseToAnyPublisher()
            #endif
        }
        #endif

        return Future { promise in
            let context = LAContext()

            // 配置认证上下文
            context.localizedCancelTitle = "取消"
            context.localizedFallbackTitle = "使用密码登录"

            // 检查设备支持
            var error: NSError?
            guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
                if let error = error {
                    promise(.failure(self.mapLAError(error)))
                } else {
                    promise(.failure(.notAvailable))
                }
                return
            }

            // 执行认证
            context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: reason
            ) { success, error in
                DispatchQueue.main.async {
                    if success {
                        promise(.success(()))
                    } else if let error = error as NSError? {
                        promise(.failure(self.mapLAError(error)))
                    } else {
                        promise(.failure(.unknown(NSError(domain: "BiometricManager", code: -1, userInfo: nil))))
                    }
                }
            }
        }
        .eraseToAnyPublisher()
    }

    /// 获取生物识别类型的用户友好描述
    func biometricTypeDescription() -> String {
        let type = biometricType()

        switch type {
        case .touchID:
            return "使用Touch ID快速登录"
        case .faceID:
            return "使用Face ID快速登录"
        case .none:
            return "您的设备不支持生物识别"
        }
    }

    /// 检查生物识别是否已录入
    func isBiometricEnrolled() -> Bool {
        let context = LAContext()
        var error: NSError?

        // 能够评估策略意味着已录入
        return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
    }

    // MARK: - Private Methods

    /// 将LAError映射为自定义BiometricError
    private func mapLAError(_ error: NSError) -> BiometricError {
        guard let laError = LAError.Code(rawValue: error.code) else {
            return .unknown(error)
        }

        switch laError {
        case .biometryNotAvailable:
            return .notAvailable
        case .biometryNotEnrolled:
            return .notEnrolled
        case .biometryLockout:
            return .lockout
        case .userCancel:
            return .userCancel
        case .userFallback:
            return .userFallback
        case .systemCancel:
            return .systemCancel
        case .passcodeNotSet:
            return .passcodeNotSet
        case .authenticationFailed:
            return .unknown(error)
        case .invalidContext:
            return .unknown(error)
        case .notInteractive:
            return .unknown(error)
        @unknown default:
            return .unknown(error)
        }
    }
}

// MARK: - Preview Helper

#if DEBUG
extension BiometricManager {
    /// 模拟认证成功（仅用于预览和测试）
    static var mock: BiometricManager {
        return BiometricManager.shared
    }
}
#endif
