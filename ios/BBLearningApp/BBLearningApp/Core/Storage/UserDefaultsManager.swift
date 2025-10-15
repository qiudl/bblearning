//
//  UserDefaultsManager.swift
//  BBLearning
//
//  Created by Claude Code on 2025-10-13.
//

import Foundation

/// UserDefaults管理器 - 用于存储用户偏好设置
final class UserDefaultsManager {

    static let shared = UserDefaultsManager()

    private let defaults = UserDefaults.standard

    private enum Keys {
        static let isFirstLaunch = "is_first_launch"
        static let selectedGrade = "selected_grade"
        static let isDarkMode = "is_dark_mode"
        static let isRememberPassword = "is_remember_password"
        static let lastSyncTime = "last_sync_time"
        static let enableNotifications = "enable_notifications"
        static let enableSound = "enable_sound"
        static let enableVibration = "enable_vibration"
        static let practiceReminderTime = "practice_reminder_time"
        static let dailyGoal = "daily_goal"
        static let lastUsername = "last_username"
    }

    private init() {}

    // MARK: - First Launch

    var isFirstLaunch: Bool {
        get {
            if defaults.object(forKey: Keys.isFirstLaunch) == nil {
                defaults.set(true, forKey: Keys.isFirstLaunch)
                return true
            }
            return defaults.bool(forKey: Keys.isFirstLaunch)
        }
        set {
            defaults.set(newValue, forKey: Keys.isFirstLaunch)
        }
    }

    // MARK: - User Preferences

    var selectedGrade: Int {
        get {
            let grade = defaults.integer(forKey: Keys.selectedGrade)
            return grade == 0 ? 7 : grade // 默认7年级
        }
        set {
            defaults.set(newValue, forKey: Keys.selectedGrade)
        }
    }

    var isDarkMode: Bool? {
        get {
            guard defaults.object(forKey: Keys.isDarkMode) != nil else {
                return nil // 未设置，使用系统默认
            }
            return defaults.bool(forKey: Keys.isDarkMode)
        }
        set {
            if let value = newValue {
                defaults.set(value, forKey: Keys.isDarkMode)
            } else {
                defaults.removeObject(forKey: Keys.isDarkMode)
            }
        }
    }

    var isRememberPassword: Bool {
        get {
            return defaults.bool(forKey: Keys.isRememberPassword)
        }
        set {
            defaults.set(newValue, forKey: Keys.isRememberPassword)
        }
    }

    var lastUsername: String? {
        get {
            return defaults.string(forKey: Keys.lastUsername)
        }
        set {
            defaults.set(newValue, forKey: Keys.lastUsername)
        }
    }

    // MARK: - Sync

    var lastSyncTime: Date? {
        get {
            return defaults.object(forKey: Keys.lastSyncTime) as? Date
        }
        set {
            defaults.set(newValue, forKey: Keys.lastSyncTime)
        }
    }

    // MARK: - Notifications

    var enableNotifications: Bool {
        get {
            if defaults.object(forKey: Keys.enableNotifications) == nil {
                return true // 默认开启
            }
            return defaults.bool(forKey: Keys.enableNotifications)
        }
        set {
            defaults.set(newValue, forKey: Keys.enableNotifications)
        }
    }

    var enableSound: Bool {
        get {
            if defaults.object(forKey: Keys.enableSound) == nil {
                return true // 默认开启
            }
            return defaults.bool(forKey: Keys.enableSound)
        }
        set {
            defaults.set(newValue, forKey: Keys.enableSound)
        }
    }

    var enableVibration: Bool {
        get {
            if defaults.object(forKey: Keys.enableVibration) == nil {
                return true // 默认开启
            }
            return defaults.bool(forKey: Keys.enableVibration)
        }
        set {
            defaults.set(newValue, forKey: Keys.enableVibration)
        }
    }

    var practiceReminderTime: Date? {
        get {
            return defaults.object(forKey: Keys.practiceReminderTime) as? Date
        }
        set {
            defaults.set(newValue, forKey: Keys.practiceReminderTime)
        }
    }

    // MARK: - Learning Settings

    var dailyGoal: Int {
        get {
            let goal = defaults.integer(forKey: Keys.dailyGoal)
            return goal == 0 ? 10 : goal // 默认每天10题
        }
        set {
            defaults.set(newValue, forKey: Keys.dailyGoal)
        }
    }

    // MARK: - Generic Methods

    func save<T>(_ value: T, forKey key: String) where T: Codable {
        if let encoded = try? JSONEncoder().encode(value) {
            defaults.set(encoded, forKey: key)
        }
    }

    func get<T>(forKey key: String, as type: T.Type) -> T? where T: Codable {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }

    func remove(forKey key: String) {
        defaults.removeObject(forKey: key)
    }

    // MARK: - Clear All

    func clearAll() {
        if let bundleID = Bundle.main.bundleIdentifier {
            defaults.removePersistentDomain(forName: bundleID)
        }
        Logger.shared.info("UserDefaults cleared")
    }

    func synchronize() {
        defaults.synchronize()
    }
}
