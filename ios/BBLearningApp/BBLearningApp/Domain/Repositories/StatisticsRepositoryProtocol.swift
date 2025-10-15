//
//  StatisticsRepositoryProtocol.swift
//  BBLearning
//
//  Created by Claude Code on 2025-10-13.
//

import Foundation
import Combine

/// 统计仓储协议
protocol StatisticsRepositoryProtocol {
    /// 获取学习统计
    /// - Parameter date: 日期
    /// - Returns: 学习统计数据
    func getLearningStatistics(date: Date) -> AnyPublisher<LearningStatistics, APIError>

    /// 获取每日统计
    /// - Parameter date: 日期
    /// - Returns: 每日统计
    func getDailyStatistics(date: Date) -> AnyPublisher<DailyStatistics, APIError>

    /// 获取周统计
    /// - Parameter weekStart: 周起始日期
    /// - Returns: 周统计
    func getWeeklyStatistics(weekStart: Date) -> AnyPublisher<WeeklyStatistics, APIError>

    /// 获取月统计
    /// - Parameter month: 月份（格式：yyyy-MM）
    /// - Returns: 月统计
    func getMonthlyStatistics(month: String) -> AnyPublisher<MonthlyStatistics, APIError>

    /// 获取总体统计
    /// - Returns: 总体统计
    func getOverallStatistics() -> AnyPublisher<OverallStatistics, APIError>

    /// 获取知识点掌握情况
    /// - Parameters:
    ///   - grade: 年级（可选）
    ///   - knowledgePointId: 知识点ID（可选）
    /// - Returns: 知识点掌握列表
    func getKnowledgeMastery(grade: Int?, knowledgePointId: Int?) -> AnyPublisher<[KnowledgeMastery], APIError>

    /// 获取进度曲线
    /// - Parameters:
    ///   - startDate: 起始日期
    ///   - endDate: 结束日期
    ///   - knowledgePointId: 知识点ID（可选）
    /// - Returns: 进度曲线数据点列表
    func getProgressCurve(startDate: Date, endDate: Date, knowledgePointId: Int?) -> AnyPublisher<[ProgressDataPoint], APIError>

    /// 记录练习统计
    /// - Parameters:
    ///   - practiceCount: 练习数量
    ///   - correctCount: 正确数量
    ///   - studyTime: 学习时长（分钟）
    /// - Returns: 成功标识
    func recordPracticeStats(practiceCount: Int, correctCount: Int, studyTime: Int) -> AnyPublisher<Void, APIError>

    /// 更新学习连续天数
    /// - Returns: 当前连续天数
    func updateStreak() -> AnyPublisher<Int, APIError>

    /// 获取排行榜
    /// - Parameters:
    ///   - grade: 年级
    ///   - type: 排行类型（练习数、正确率、学习时长等）
    ///   - limit: 返回数量
    /// - Returns: 排行数据
    func getLeaderboard(grade: Int, type: LeaderboardType, limit: Int) -> AnyPublisher<[LeaderboardEntry], APIError>
}

// MARK: - Leaderboard Models

/// 排行榜类型
enum LeaderboardType: String, Codable {
    case practiceCount = "practice_count"       // 练习数排行
    case accuracy = "accuracy"                  // 正确率排行
    case studyTime = "study_time"               // 学习时长排行
    case masteryLevel = "mastery_level"         // 掌握度排行
    case streak = "streak"                      // 连续学习天数排行

    var displayText: String {
        switch self {
        case .practiceCount: return "练习数"
        case .accuracy: return "正确率"
        case .studyTime: return "学习时长"
        case .masteryLevel: return "掌握度"
        case .streak: return "连续学习"
        }
    }

    var unit: String {
        switch self {
        case .practiceCount: return "题"
        case .accuracy: return "%"
        case .studyTime: return "分钟"
        case .masteryLevel: return "%"
        case .streak: return "天"
        }
    }
}

/// 排行榜条目
struct LeaderboardEntry: Codable, Identifiable {
    let id: Int
    let rank: Int
    let userId: Int
    let username: String
    let nickname: String
    let avatar: String?
    let value: Double                   // 排行值
    let isCurrentUser: Bool

    enum CodingKeys: String, CodingKey {
        case id
        case rank
        case userId = "user_id"
        case username
        case nickname
        case avatar
        case value
        case isCurrentUser = "is_current_user"
    }

    /// 显示值
    func displayValue(for type: LeaderboardType) -> String {
        switch type {
        case .practiceCount:
            return "\(Int(value))"
        case .accuracy, .masteryLevel:
            return String(format: "%.1f%%", value * 100)
        case .studyTime:
            let hours = Int(value) / 60
            let minutes = Int(value) % 60
            if hours > 0 {
                return "\(hours)h\(minutes)m"
            } else {
                return "\(minutes)m"
            }
        case .streak:
            return "\(Int(value))天"
        }
    }
}
