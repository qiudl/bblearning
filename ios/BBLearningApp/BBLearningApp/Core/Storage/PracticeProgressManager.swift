//
//  PracticeProgressManager.swift
//  BBLearning
//
//  Created by Claude Code on 2025-10-15.
//

import Foundation

/// 练习进度模型
struct PracticeProgress: Codable {
    let sessionId: String
    let mode: PracticeMode
    let questions: [Question]
    let currentIndex: Int
    let answers: [QuestionAnswer]
    let startTime: Date
    let savedAt: Date
    let knowledgePointIds: [Int]
    let targetCount: Int
}

/// 题目答案记录
struct QuestionAnswer: Codable, Equatable {
    let questionId: Int
    let answer: String
    let isCorrect: Bool
    let timeSpent: Int  // 秒
    let submittedAt: Date
}

/// 练习进度管理器
class PracticeProgressManager {
    static let shared = PracticeProgressManager()

    private let userDefaults = UserDefaults.standard
    private let progressKey = "practice_progress"
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    private init() {
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
    }

    /// 保存练习进度
    /// - Parameter progress: 进度数据
    func saveProgress(_ progress: PracticeProgress) {
        do {
            let data = try encoder.encode(progress)
            userDefaults.set(data, forKey: progressKey)
            userDefaults.synchronize()
            Logger.shared.info("练习进度已保存: \(progress.sessionId)")
        } catch {
            Logger.shared.error("保存练习进度失败: \(error.localizedDescription)")
        }
    }

    /// 加载练习进度
    /// - Returns: 进度数据（如果存在）
    func loadProgress() -> PracticeProgress? {
        guard let data = userDefaults.data(forKey: progressKey) else {
            return nil
        }

        do {
            let progress = try decoder.decode(PracticeProgress.self, from: data)

            // 检查进度是否过期（超过24小时）
            if isProgressExpired(progress) {
                clearProgress()
                return nil
            }

            Logger.shared.info("练习进度已加载: \(progress.sessionId)")
            return progress
        } catch {
            Logger.shared.error("加载练习进度失败: \(error.localizedDescription)")
            clearProgress()  // 清除损坏的数据
            return nil
        }
    }

    /// 清除练习进度
    func clearProgress() {
        userDefaults.removeObject(forKey: progressKey)
        userDefaults.synchronize()
        Logger.shared.info("练习进度已清除")
    }

    /// 检查是否有保存的进度
    /// - Returns: 是否有进度
    func hasProgress() -> Bool {
        return loadProgress() != nil
    }

    /// 判断进度是否过期
    /// - Parameter progress: 进度数据
    /// - Returns: 是否过期
    private func isProgressExpired(_ progress: PracticeProgress) -> Bool {
        let expirationHours: TimeInterval = 24 * 3600  // 24小时
        return Date().timeIntervalSince(progress.savedAt) > expirationHours
    }

    /// 计算进度百分比
    /// - Parameter progress: 进度数据
    /// - Returns: 百分比（0-100）
    func calculateProgressPercentage(_ progress: PracticeProgress) -> Int {
        guard progress.targetCount > 0 else { return 0 }
        return Int(Double(progress.currentIndex) / Double(progress.targetCount) * 100)
    }

    /// 获取进度摘要文本
    /// - Parameter progress: 进度数据
    /// - Returns: 摘要文本
    func getProgressSummary(_ progress: PracticeProgress) -> String {
        let percentage = calculateProgressPercentage(progress)
        let remaining = progress.targetCount - progress.currentIndex

        return "已完成 \(progress.currentIndex)/\(progress.targetCount) 题 (\(percentage)%)，剩余 \(remaining) 题"
    }
}

// MARK: - Practice Cache Manager

/// 练习缓存管理器
class PracticeCacheManager {
    static let shared = PracticeCacheManager()

    private let cacheKey = "practice_history_cache"
    private let maxCacheSize = 50  // 最多缓存50条记录
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    private init() {
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
    }

    /// 缓存练习记录
    /// - Parameter record: 练习记录
    func cacheRecord(_ record: PracticeRecord) {
        var records = getCachedRecords()

        // 添加新记录到头部
        records.insert(record, at: 0)

        // 限制缓存大小
        if records.count > maxCacheSize {
            records = Array(records.prefix(maxCacheSize))
        }

        saveRecords(records)
        Logger.shared.info("练习记录已缓存: \(record.sessionId)")
    }

    /// 获取缓存的练习记录
    /// - Returns: 记录列表
    func getCachedRecords() -> [PracticeRecord] {
        guard let data = UserDefaults.standard.data(forKey: cacheKey) else {
            return []
        }

        do {
            return try decoder.decode([PracticeRecord].self, from: data)
        } catch {
            Logger.shared.error("加载缓存记录失败: \(error.localizedDescription)")
            return []
        }
    }

    /// 保存记录列表
    /// - Parameter records: 记录列表
    private func saveRecords(_ records: [PracticeRecord]) {
        do {
            let data = try encoder.encode(records)
            UserDefaults.standard.set(data, forKey: cacheKey)
            UserDefaults.standard.synchronize()
        } catch {
            Logger.shared.error("保存缓存记录失败: \(error.localizedDescription)")
        }
    }

    /// 删除缓存记录
    /// - Parameter recordId: 记录ID
    func deleteRecord(recordId: Int) {
        var records = getCachedRecords()
        records.removeAll { $0.id == recordId }
        saveRecords(records)
        Logger.shared.info("缓存记录已删除: \(recordId)")
    }

    /// 清除所有缓存
    func clearCache() {
        UserDefaults.standard.removeObject(forKey: cacheKey)
        UserDefaults.standard.synchronize()
        Logger.shared.info("练习缓存已清除")
    }

    /// 与服务器同步
    func syncWithServer() {
        // TODO: 实现与服务器的数据同步
        // 1. 上传本地缓存的记录到服务器
        // 2. 从服务器下载最新记录
        // 3. 合并数据并去重
        Logger.shared.info("开始同步练习记录...")
    }
}
