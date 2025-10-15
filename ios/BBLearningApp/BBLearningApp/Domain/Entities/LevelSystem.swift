//
//  LevelSystem.swift
//  BBLearning
//
//  Created by Claude Code on 2025-10-15.
//

import Foundation

struct LevelSystem {
    /// 计算指定等级所需的总经验值
    /// - Parameter level: 等级
    /// - Returns: 该等级所需的总经验值
    static func experienceForLevel(_ level: Int) -> Int {
        guard level > 0 else { return 0 }
        // 等级所需经验公式：100 * level^1.5
        return Int(100.0 * pow(Double(level), 1.5))
    }

    /// 根据经验值计算当前等级
    /// - Parameter exp: 总经验值
    /// - Returns: 当前等级
    static func levelForExperience(_ exp: Int) -> Int {
        guard exp > 0 else { return 1 }

        var level = 1
        while experienceForLevel(level + 1) <= exp {
            level += 1
        }
        return level
    }

    /// 获取等级称号
    /// - Parameter level: 等级
    /// - Returns: 称号
    static func titleForLevel(_ level: Int) -> String {
        switch level {
        case 1...5:
            return "初学者"
        case 6...10:
            return "学习者"
        case 11...20:
            return "进步者"
        case 21...30:
            return "优秀者"
        case 31...50:
            return "精英者"
        default:
            return "大师"
        }
    }

    /// 计算当前等级的进度
    /// - Parameters:
    ///   - currentExp: 当前总经验值
    ///   - level: 当前等级
    /// - Returns: 进度百分比 (0.0-1.0)
    static func progressForLevel(_ currentExp: Int, level: Int) -> Double {
        let currentLevelExp = experienceForLevel(level)
        let nextLevelExp = experienceForLevel(level + 1)
        let progressExp = currentExp - currentLevelExp
        let totalExp = nextLevelExp - currentLevelExp

        guard totalExp > 0 else { return 0.0 }
        return Double(progressExp) / Double(totalExp)
    }

    /// 获取升级所需经验
    /// - Parameters:
    ///   - currentExp: 当前总经验值
    ///   - level: 当前等级
    /// - Returns: 距离下一级所需经验
    static func experienceToNextLevel(_ currentExp: Int, level: Int) -> Int {
        let nextLevelExp = experienceForLevel(level + 1)
        return max(0, nextLevelExp - currentExp)
    }
}

// MARK: - LevelInfo

struct LevelInfo {
    let level: Int
    let title: String
    let currentExp: Int
    let nextLevelExp: Int
    let progress: Double
    let experienceToNext: Int

    init(totalExperience: Int) {
        self.level = LevelSystem.levelForExperience(totalExperience)
        self.title = LevelSystem.titleForLevel(level)
        self.currentExp = totalExperience
        self.nextLevelExp = LevelSystem.experienceForLevel(level + 1)
        self.progress = LevelSystem.progressForLevel(totalExperience, level: level)
        self.experienceToNext = LevelSystem.experienceToNextLevel(totalExperience, level: level)
    }
}

// MARK: - UserStats

struct UserStats {
    let studyDays: Int
    let totalQuestions: Int
    let averageAccuracy: Double
    let currentStreak: Int
    let longestStreak: Int

    var accuracyPercentage: String {
        String(format: "%.1f%%", averageAccuracy * 100)
    }
}
