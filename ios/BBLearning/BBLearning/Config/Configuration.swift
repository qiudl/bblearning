//
//  Configuration.swift
//  BBLearning
//
//  Created by Claude Code on 2025-10-13.
//

import Foundation

struct Configuration {
    // MARK: - Environment
    static let environment = Environment.current
    static let baseURL = environment.baseURL
    static let wsURL = environment.wsURL

    // MARK: - App Info
    static let appVersion: String = {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }()

    static let buildNumber: String = {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }()

    static let bundleIdentifier: String = {
        Bundle.main.bundleIdentifier ?? "com.bblearning.ios"
    }()

    // MARK: - API Configuration
    static let apiTimeout: TimeInterval = 30
    static let maxRetryCount = 3
    static let retryDelay: TimeInterval = 1

    // MARK: - Cache Configuration
    static let imageCacheMaxAge: TimeInterval = 7 * 24 * 60 * 60 // 7 days
    static let dataCacheMaxAge: TimeInterval = 24 * 60 * 60 // 1 day
    static let maxDiskCacheSize: Int = 100 * 1024 * 1024 // 100MB
    static let maxMemoryCacheSize: Int = 50 * 1024 * 1024 // 50MB

    // MARK: - Feature Flags
    static let enableOfflineMode = true
    static let enableAITutor = true
    static let enableVoiceInput = true
    static let enablePhotoRecognition = true
    static let enableDebugLogging = environment.isDebug

    // MARK: - UI Configuration
    static let defaultPageSize = 20
    static let maxQuestionCount = 50
    static let practiceTimeLimit: TimeInterval = 60 * 60 // 1 hour

    // MARK: - Validation Rules
    static let minPasswordLength = 6
    static let maxPasswordLength = 20
    static let minUsernameLength = 3
    static let maxUsernameLength = 20
}
