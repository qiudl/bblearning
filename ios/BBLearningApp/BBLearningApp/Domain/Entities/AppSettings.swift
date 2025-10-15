//
//  AppSettings.swift
//  BBLearning
//
//  Created by Claude Code on 2025-10-15.
//

import Foundation

struct AppSettings: Codable {
    var notifications: NotificationSettings
    var privacy: PrivacySettings
    var learning: LearningSettings

    static let `default` = AppSettings(
        notifications: NotificationSettings(),
        privacy: PrivacySettings(),
        learning: LearningSettings()
    )

    // MARK: - Notification Settings

    struct NotificationSettings: Codable {
        var enabled: Bool = true
        var studyReminder: Bool = true
        var reviewReminder: Bool = true
        var achievementNotification: Bool = true
        var studyReminderTime: Date? = Calendar.current.date(
            bySettingHour: 19,
            minute: 0,
            second: 0,
            of: Date()
        )

        enum CodingKeys: String, CodingKey {
            case enabled
            case studyReminder
            case reviewReminder
            case achievementNotification
            case studyReminderTime
        }
    }

    // MARK: - Privacy Settings

    struct PrivacySettings: Codable {
        var shareProgress: Bool = false
        var showInRanking: Bool = true
        var allowAnalytics: Bool = true
    }

    // MARK: - Learning Settings

    struct LearningSettings: Codable {
        var dailyGoal: Int = 10
        var difficultPreference: String? = nil  // "easy", "medium", "hard"
        var autoSaveProgress: Bool = true
    }
}

// MARK: - Settings Manager

class SettingsManager {
    static let shared = SettingsManager()

    private let userDefaults = UserDefaults.standard
    private let settingsKey = "app_settings"

    private init() {}

    func loadSettings() -> AppSettings {
        guard let data = userDefaults.data(forKey: settingsKey),
              let settings = try? JSONDecoder().decode(AppSettings.self, from: data) else {
            return .default
        }
        return settings
    }

    func saveSettings(_ settings: AppSettings) {
        if let data = try? JSONEncoder().encode(settings) {
            userDefaults.set(data, forKey: settingsKey)
        }
    }

    func resetToDefault() {
        userDefaults.removeObject(forKey: settingsKey)
    }
}
