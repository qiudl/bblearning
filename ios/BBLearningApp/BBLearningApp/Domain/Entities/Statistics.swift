//
//  Statistics.swift
//  BBLearning
//
//  Created by Claude Code on 2025-10-13.
//

import Foundation

/// 学习统计实体
struct LearningStatistics: Codable, Equatable {
    let userId: Int
    var dailyStats: DailyStatistics?
    var weeklyStats: WeeklyStatistics?
    var monthlyStats: MonthlyStatistics?
    var overallStats: OverallStatistics?
    let date: Date

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case dailyStats = "daily_stats"
        case weeklyStats = "weekly_stats"
        case monthlyStats = "monthly_stats"
        case overallStats = "overall_stats"
        case date
    }
}

// MARK: - Daily Statistics

/// 每日统计
struct DailyStatistics: Codable, Equatable {
    var practiceCount: Int              // 练习题数
    var correctCount: Int               // 正确题数
    var totalScore: Int                 // 总得分
    var studyTime: Int                  // 学习时长（分钟）
    var completedKnowledgePoints: [Int] // 完成的知识点
    var newMasteredPoints: Int          // 新掌握的知识点数
    var wrongQuestionsAdded: Int        // 新增错题数
    var streak: Int                     // 连续学习天数

    enum CodingKeys: String, CodingKey {
        case practiceCount = "practice_count"
        case correctCount = "correct_count"
        case totalScore = "total_score"
        case studyTime = "study_time"
        case completedKnowledgePoints = "completed_knowledge_points"
        case newMasteredPoints = "new_mastered_points"
        case wrongQuestionsAdded = "wrong_questions_added"
        case streak
    }

    /// 正确率
    var accuracy: Double {
        guard practiceCount > 0 else { return 0 }
        return Double(correctCount) / Double(practiceCount)
    }

    /// 平均分
    var averageScore: Double {
        guard practiceCount > 0 else { return 0 }
        return Double(totalScore) / Double(practiceCount)
    }

    /// 学习时长文本
    var studyTimeText: String {
        let hours = studyTime / 60
        let minutes = studyTime % 60
        if hours > 0 {
            return "\(hours)小时\(minutes)分钟"
        } else {
            return "\(minutes)分钟"
        }
    }

    /// 是否达成每日目标（假设目标是30分钟）
    func achievedDailyGoal(goalMinutes: Int = 30) -> Bool {
        return studyTime >= goalMinutes
    }
}

// MARK: - Weekly Statistics

/// 每周统计
struct WeeklyStatistics: Codable, Equatable {
    var totalPracticeCount: Int
    var totalCorrectCount: Int
    var totalStudyTime: Int
    var dailyRecords: [String: DailyStatistics] // 日期: 统计
    var activeDays: Int                         // 活跃天数
    var bestDay: String?                        // 表现最好的一天
    var improvement: Double?                    // 进步幅度

    enum CodingKeys: String, CodingKey {
        case totalPracticeCount = "total_practice_count"
        case totalCorrectCount = "total_correct_count"
        case totalStudyTime = "total_study_time"
        case dailyRecords = "daily_records"
        case activeDays = "active_days"
        case bestDay = "best_day"
        case improvement
    }

    /// 平均正确率
    var averageAccuracy: Double {
        guard totalPracticeCount > 0 else { return 0 }
        return Double(totalCorrectCount) / Double(totalPracticeCount)
    }

    /// 平均每日学习时长
    var averageDailyTime: Int {
        guard activeDays > 0 else { return 0 }
        return totalStudyTime / activeDays
    }
}

// MARK: - Monthly Statistics

/// 每月统计
struct MonthlyStatistics: Codable, Equatable {
    var totalPracticeCount: Int
    var totalCorrectCount: Int
    var totalStudyTime: Int
    var weeklyRecords: [String: WeeklyStatistics] // 周: 统计
    var masteredKnowledgePoints: Int
    var activeDays: Int
    var longestStreak: Int                       // 最长连续学习天数
    var rankInGrade: Int?                        // 年级排名

    enum CodingKeys: String, CodingKey {
        case totalPracticeCount = "total_practice_count"
        case totalCorrectCount = "total_correct_count"
        case totalStudyTime = "total_study_time"
        case weeklyRecords = "weekly_records"
        case masteredKnowledgePoints = "mastered_knowledge_points"
        case activeDays = "active_days"
        case longestStreak = "longest_streak"
        case rankInGrade = "rank_in_grade"
    }

    /// 平均正确率
    var averageAccuracy: Double {
        guard totalPracticeCount > 0 else { return 0 }
        return Double(totalCorrectCount) / Double(totalPracticeCount)
    }

    /// 学习覆盖率
    var studyCoverage: Double {
        let daysInMonth = 30.0
        return Double(activeDays) / daysInMonth
    }
}

// MARK: - Overall Statistics

/// 总体统计
struct OverallStatistics: Codable, Equatable {
    var totalPracticeCount: Int
    var totalCorrectCount: Int
    var totalStudyTime: Int
    var totalKnowledgePoints: Int
    var masteredKnowledgePoints: Int
    var totalWrongQuestions: Int
    var masteredWrongQuestions: Int
    var currentStreak: Int
    var longestStreak: Int
    var accountAge: Int                          // 账号天数

    enum CodingKeys: String, CodingKey {
        case totalPracticeCount = "total_practice_count"
        case totalCorrectCount = "total_correct_count"
        case totalStudyTime = "total_study_time"
        case totalKnowledgePoints = "total_knowledge_points"
        case masteredKnowledgePoints = "mastered_knowledge_points"
        case totalWrongQuestions = "total_wrong_questions"
        case masteredWrongQuestions = "mastered_wrong_questions"
        case currentStreak = "current_streak"
        case longestStreak = "longest_streak"
        case accountAge = "account_age"
    }

    /// 总正确率
    var accuracy: Double {
        guard totalPracticeCount > 0 else { return 0 }
        return Double(totalCorrectCount) / Double(totalPracticeCount)
    }

    /// 知识点掌握率
    var knowledgeMasteryRate: Double {
        guard totalKnowledgePoints > 0 else { return 0 }
        return Double(masteredKnowledgePoints) / Double(totalKnowledgePoints)
    }

    /// 错题攻克率
    var wrongQuestionMasteryRate: Double {
        guard totalWrongQuestions > 0 else { return 0 }
        return Double(masteredWrongQuestions) / Double(totalWrongQuestions)
    }

    /// 总学习时长文本
    var totalStudyTimeText: String {
        let hours = totalStudyTime / 60
        if hours < 24 {
            return "\(hours)小时"
        } else {
            let days = hours / 24
            let remainHours = hours % 24
            return "\(days)天\(remainHours)小时"
        }
    }

    /// 平均每日学习时长
    var averageDailyTime: Int {
        guard accountAge > 0 else { return 0 }
        return totalStudyTime / accountAge
    }
}

// MARK: - Knowledge Point Mastery

/// 知识点掌握情况
struct KnowledgeMastery: Codable, Equatable {
    let knowledgePointId: Int
    var knowledgePointName: String?
    var masteryLevel: Double                    // 掌握程度 0-1
    var practiceCount: Int
    var correctCount: Int
    var wrongCount: Int
    var lastPracticeTime: Date?
    var status: MasteryStatus
    var weekProgress: [WeekDay: Double]?        // 本周每天的进步

    enum CodingKeys: String, CodingKey {
        case knowledgePointId = "knowledge_point_id"
        case knowledgePointName = "knowledge_point_name"
        case masteryLevel = "mastery_level"
        case practiceCount = "practice_count"
        case correctCount = "correct_count"
        case wrongCount = "wrong_count"
        case lastPracticeTime = "last_practice_time"
        case status
        case weekProgress = "week_progress"
    }

    enum MasteryStatus: String, Codable {
        case notStarted = "not_started"
        case learning = "learning"
        case mastered = "mastered"

        var displayText: String {
            switch self {
            case .notStarted: return "未开始"
            case .learning: return "学习中"
            case .mastered: return "已掌握"
            }
        }

        var color: String {
            switch self {
            case .notStarted: return "gray"
            case .learning: return "orange"
            case .mastered: return "green"
            }
        }
    }

    enum WeekDay: String, Codable {
        case monday, tuesday, wednesday, thursday, friday, saturday, sunday

        var displayText: String {
            switch self {
            case .monday: return "周一"
            case .tuesday: return "周二"
            case .wednesday: return "周三"
            case .thursday: return "周四"
            case .friday: return "周五"
            case .saturday: return "周六"
            case .sunday: return "周日"
            }
        }
    }

    /// 正确率
    var accuracy: Double {
        guard practiceCount > 0 else { return 0 }
        return Double(correctCount) / Double(practiceCount)
    }

    /// 掌握程度百分比
    var masteryPercentage: Int {
        return Int(masteryLevel * 100)
    }

    /// 需要加强
    var needsImprovement: Bool {
        return masteryLevel < 0.6 || accuracy < 0.7
    }
}

// MARK: - Progress Curve

/// 进度曲线数据点
struct ProgressDataPoint: Codable, Equatable {
    let date: Date
    var practiceCount: Int
    var correctRate: Double
    var masteryLevel: Double
    var studyTime: Int

    enum CodingKeys: String, CodingKey {
        case date
        case practiceCount = "practice_count"
        case correctRate = "correct_rate"
        case masteryLevel = "mastery_level"
        case studyTime = "study_time"
    }
}

// MARK: - Mock Data

#if DEBUG
extension LearningStatistics {
    static let mock = LearningStatistics(
        userId: 1,
        dailyStats: DailyStatistics.mock,
        weeklyStats: WeeklyStatistics.mock,
        monthlyStats: MonthlyStatistics.mock,
        overallStats: OverallStatistics.mock,
        date: Date()
    )
}

extension DailyStatistics {
    static let mock = DailyStatistics(
        practiceCount: 20,
        correctCount: 15,
        totalScore: 75,
        studyTime: 45,
        completedKnowledgePoints: [11, 12],
        newMasteredPoints: 1,
        wrongQuestionsAdded: 5,
        streak: 7
    )
}

extension WeeklyStatistics {
    static let mock = WeeklyStatistics(
        totalPracticeCount: 100,
        totalCorrectCount: 80,
        totalStudyTime: 300,
        dailyRecords: [:],
        activeDays: 5,
        bestDay: "2025-10-12",
        improvement: 0.15
    )
}

extension MonthlyStatistics {
    static let mock = MonthlyStatistics(
        totalPracticeCount: 400,
        totalCorrectCount: 320,
        totalStudyTime: 1200,
        weeklyRecords: [:],
        masteredKnowledgePoints: 8,
        activeDays: 20,
        longestStreak: 14,
        rankInGrade: 15
    )
}

extension OverallStatistics {
    static let mock = OverallStatistics(
        totalPracticeCount: 1500,
        totalCorrectCount: 1200,
        totalStudyTime: 5000,
        totalKnowledgePoints: 50,
        masteredKnowledgePoints: 20,
        totalWrongQuestions: 150,
        masteredWrongQuestions: 80,
        currentStreak: 7,
        longestStreak: 21,
        accountAge: 60
    )
}

extension KnowledgeMastery {
    static let mock = KnowledgeMastery(
        knowledgePointId: 11,
        knowledgePointName: "正数和负数",
        masteryLevel: 0.75,
        practiceCount: 30,
        correctCount: 25,
        wrongCount: 5,
        lastPracticeTime: Date(),
        status: .learning,
        weekProgress: [
            .monday: 0.6,
            .tuesday: 0.65,
            .wednesday: 0.7,
            .thursday: 0.72,
            .friday: 0.75
        ]
    )

    static let mockList: [KnowledgeMastery] = [
        mock,
        KnowledgeMastery(
            knowledgePointId: 12,
            knowledgePointName: "有理数的加减",
            masteryLevel: 0.9,
            practiceCount: 50,
            correctCount: 48,
            wrongCount: 2,
            lastPracticeTime: Date(),
            status: .mastered,
            weekProgress: nil
        )
    ]
}

extension ProgressDataPoint {
    static let mockCurve: [ProgressDataPoint] = [
        ProgressDataPoint(date: Date().addingTimeInterval(-6 * 86400), practiceCount: 10, correctRate: 0.6, masteryLevel: 0.5, studyTime: 30),
        ProgressDataPoint(date: Date().addingTimeInterval(-5 * 86400), practiceCount: 15, correctRate: 0.65, masteryLevel: 0.55, studyTime: 40),
        ProgressDataPoint(date: Date().addingTimeInterval(-4 * 86400), practiceCount: 12, correctRate: 0.7, masteryLevel: 0.6, studyTime: 35),
        ProgressDataPoint(date: Date().addingTimeInterval(-3 * 86400), practiceCount: 18, correctRate: 0.72, masteryLevel: 0.65, studyTime: 50),
        ProgressDataPoint(date: Date().addingTimeInterval(-2 * 86400), practiceCount: 20, correctRate: 0.75, masteryLevel: 0.7, studyTime: 55),
        ProgressDataPoint(date: Date().addingTimeInterval(-1 * 86400), practiceCount: 22, correctRate: 0.78, masteryLevel: 0.75, studyTime: 60),
        ProgressDataPoint(date: Date(), practiceCount: 20, correctRate: 0.8, masteryLevel: 0.8, studyTime: 45)
    ]
}
#endif

// MARK: - Type Alias

/// 类型别名，方便使用
typealias Statistics = LearningStatistics
