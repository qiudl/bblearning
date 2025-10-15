//
//  WrongQuestion.swift
//  BBLearning
//
//  Created by Claude Code on 2025-10-13.
//

import Foundation

/// 错题实体
struct WrongQuestion: Identifiable, Codable, Equatable {
    let id: Int
    let userId: Int
    let practiceRecordId: Int
    var question: Question?
    var practiceRecord: PracticeRecord?
    var status: Status
    var retryCount: Int
    var lastRetryTime: Date?
    var mastered: Bool
    let createdAt: Date
    var updatedAt: Date

    // 新增：错误类型分类
    var errorType: ErrorType?

    // 新增：复习计划
    var reviewSchedule: ReviewSchedule?

    // 新增：相似题目ID列表
    var similarQuestionIds: [Int]?

    // 新增：学习笔记
    var learningNote: String?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case practiceRecordId = "practice_record_id"
        case question
        case practiceRecord = "practice_record"
        case status
        case retryCount = "retry_count"
        case lastRetryTime = "last_retry_time"
        case mastered
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case errorType = "error_type"
        case reviewSchedule = "review_schedule"
        case similarQuestionIds = "similar_question_ids"
        case learningNote = "learning_note"
    }

    /// 错误类型枚举
    enum ErrorType: String, Codable, CaseIterable {
        case conceptual = "conceptual"      // 概念不清
        case calculation = "calculation"    // 计算错误
        case careless = "careless"          // 粗心大意
        case method = "method"              // 方法错误
        case unknown = "unknown"            // 未分类

        var displayName: String {
            switch self {
            case .conceptual: return "概念不清"
            case .calculation: return "计算错误"
            case .careless: return "粗心大意"
            case .method: return "方法错误"
            case .unknown: return "未分类"
            }
        }

        var icon: String {
            switch self {
            case .conceptual: return "book.closed"
            case .calculation: return "function"
            case .careless: return "exclamationmark.triangle"
            case .method: return "pencil.and.outline"
            case .unknown: return "questionmark.circle"
            }
        }

        var color: String {
            switch self {
            case .conceptual: return "purple"
            case .calculation: return "orange"
            case .careless: return "yellow"
            case .method: return "blue"
            case .unknown: return "gray"
            }
        }
    }

    /// 错题状态
    enum Status: String, Codable {
        case pending = "pending"         // 待复习
        case reviewing = "reviewing"     // 复习中
        case mastered = "mastered"       // 已掌握
        case archived = "archived"       // 已归档

        var displayText: String {
            switch self {
            case .pending: return "待复习"
            case .reviewing: return "复习中"
            case .mastered: return "已掌握"
            case .archived: return "已归档"
            }
        }

        var color: String {
            switch self {
            case .pending: return "red"
            case .reviewing: return "orange"
            case .mastered: return "green"
            case .archived: return "gray"
            }
        }

        var icon: String {
            switch self {
            case .pending: return "exclamationmark.circle"
            case .reviewing: return "arrow.clockwise.circle"
            case .mastered: return "checkmark.circle"
            case .archived: return "archivebox"
            }
        }
    }
}

// MARK: - Wrong Question Statistics

/// 错题统计
struct WrongQuestionStatistics: Codable, Equatable {
    var totalCount: Int                  // 总错题数
    var pendingCount: Int                // 待复习数
    var reviewingCount: Int              // 复习中数
    var masteredCount: Int               // 已掌握数
    var byKnowledgePoint: [Int: Int]     // 按知识点统计（知识点ID: 错题数）
    var byDifficulty: [String: Int]      // 按难度统计
    var recentAdded: [WrongQuestion]?    // 最近添加

    // 新增：按错误类型统计
    var byErrorType: [String: Int]?      // 按错误类型统计

    // 新增：今日待复习数
    var todayReviewCount: Int?

    // 新增：本周复习完成数
    var weeklyCompletedCount: Int?

    enum CodingKeys: String, CodingKey {
        case totalCount = "total_count"
        case pendingCount = "pending_count"
        case reviewingCount = "reviewing_count"
        case masteredCount = "mastered_count"
        case byKnowledgePoint = "by_knowledge_point"
        case byDifficulty = "by_difficulty"
        case recentAdded = "recent_added"
        case byErrorType = "by_error_type"
        case todayReviewCount = "today_review_count"
        case weeklyCompletedCount = "weekly_completed_count"
    }

    /// 待复习比例
    var pendingRate: Double {
        guard totalCount > 0 else { return 0 }
        return Double(pendingCount) / Double(totalCount)
    }

    /// 掌握比例
    var masteredRate: Double {
        guard totalCount > 0 else { return 0 }
        return Double(masteredCount) / Double(totalCount)
    }

    /// 重点薄弱知识点（错题最多的前3个）
    var weakKnowledgePoints: [Int] {
        return byKnowledgePoint
            .sorted { $0.value > $1.value }
            .prefix(3)
            .map { $0.key }
    }

    /// 最常见的错误类型
    var mostCommonErrorType: WrongQuestion.ErrorType? {
        guard let errorTypes = byErrorType else { return nil }

        let sorted = errorTypes.sorted { $0.value > $1.value }
        guard let topType = sorted.first?.key else { return nil }

        return WrongQuestion.ErrorType(rawValue: topType)
    }

    /// 复习完成率
    var reviewCompletionRate: Double {
        let completedCount = masteredCount + (weeklyCompletedCount ?? 0)
        let totalNeedReview = pendingCount + reviewingCount + completedCount
        guard totalNeedReview > 0 else { return 0 }
        return Double(completedCount) / Double(totalNeedReview)
    }
}

// MARK: - Extensions

extension WrongQuestion {
    /// 智能分析错误类型
    /// - Returns: 分析出的错误类型
    func analyzeErrorType() -> ErrorType {
        guard let aiGrade = practiceRecord?.aiGrade else {
            return .unknown
        }

        // 分析AI评分中的错误信息
        let mistakes = aiGrade.mistakes ?? []
        let suggestions = aiGrade.suggestions ?? []
        let allText = (mistakes + suggestions).joined(separator: " ")

        // 关键词匹配
        if allText.contains("概念") || allText.contains("定义") || allText.contains("理解") {
            return .conceptual
        } else if allText.contains("计算") || allText.contains("运算") || allText.contains("结果错误") {
            return .calculation
        } else if allText.contains("粗心") || allText.contains("符号") || allText.contains("抄写") {
            return .careless
        } else if allText.contains("方法") || allText.contains("思路") || allText.contains("步骤") {
            return .method
        }

        return .unknown
    }

    /// 使用ReviewScheduleManager更新复习计划
    /// - Parameter isCorrect: 本次复习是否正确
    /// - Returns: 更新后的WrongQuestion
    func updateReviewSchedule(isCorrect: Bool) -> WrongQuestion {
        var updated = self
        let manager = ReviewScheduleManager.shared

        if let schedule = reviewSchedule {
            // 更新现有复习计划
            updated.reviewSchedule = manager.recordReview(for: schedule, isCorrect: isCorrect)
        } else {
            // 创建新的复习计划
            updated.reviewSchedule = manager.createNewSchedule()
        }

        // 更新其他字段
        updated.lastRetryTime = Date()
        if isCorrect {
            updated.retryCount += 1
            // 连续正确5次视为掌握
            if updated.retryCount >= 5 {
                updated.status = .mastered
                updated.mastered = true
            }
        } else {
            // 错误则重置计数
            updated.retryCount = 0
            updated.status = .reviewing
        }
        updated.updatedAt = Date()

        return updated
    }

    /// 是否需要复习（基于ReviewSchedule）
    var needsReview: Bool {
        // 优先使用ReviewSchedule判断
        if let schedule = reviewSchedule {
            return ReviewScheduleManager.shared.needsReview(schedule)
        }

        // 降级到原有逻辑
        guard let lastRetry = lastRetryTime else {
            return status == .pending
        }

        let daysSinceLastRetry = Date().daysBetween(lastRetry)

        // 根据重做次数确定复习间隔
        let reviewInterval: Int
        switch retryCount {
        case 0: reviewInterval = 1        // 首次：1天
        case 1: reviewInterval = 3        // 第二次：3天
        case 2: reviewInterval = 7        // 第三次：7天
        case 3: reviewInterval = 14       // 第四次：14天
        default: reviewInterval = 30      // 之后：30天
        }

        return daysSinceLastRetry >= reviewInterval
    }

    /// 下次复习时间
    var nextReviewTime: Date? {
        // 优先使用ReviewSchedule
        if let schedule = reviewSchedule {
            return schedule.nextReviewDate
        }

        // 降级到原有逻辑
        guard let lastRetry = lastRetryTime else {
            return Date()  // 立即复习
        }

        let reviewInterval: TimeInterval
        switch retryCount {
        case 0: reviewInterval = 1 * 86400
        case 1: reviewInterval = 3 * 86400
        case 2: reviewInterval = 7 * 86400
        case 3: reviewInterval = 14 * 86400
        default: reviewInterval = 30 * 86400
        }

        return lastRetry.addingTimeInterval(reviewInterval)
    }

    /// 获取复习进度文本描述
    var reviewProgressText: String {
        if let schedule = reviewSchedule {
            let days = ReviewScheduleManager.shared.daysUntilNextReview(schedule)
            if days < 0 {
                return "待复习"
            } else if days == 0 {
                return "今日复习"
            } else {
                return "\(days)天后复习"
            }
        }

        return reviewProgress >= 100 ? "已掌握" : "复习中"
    }

    /// 复习进度（0-100）
    var reviewProgress: Int {
        let maxRetries = 5
        return min(Int(Double(retryCount) / Double(maxRetries) * 100), 100)
    }

    /// 错误原因标签
    var errorTags: [String] {
        guard let aiGrade = practiceRecord?.aiGrade else { return [] }
        var tags: [String] = []

        if let mistakes = aiGrade.mistakes, !mistakes.isEmpty {
            for mistake in mistakes {
                if mistake.contains("概念") || mistake.contains("定义") {
                    tags.append("概念理解")
                } else if mistake.contains("计算") || mistake.contains("运算") {
                    tags.append("计算错误")
                } else if mistake.contains("符号") {
                    tags.append("符号问题")
                } else if mistake.contains("步骤") {
                    tags.append("步骤遗漏")
                } else {
                    tags.append("其他")
                }
            }
        }

        return Array(Set(tags))  // 去重
    }

    /// 是否为高频错题（重做3次以上仍未掌握）
    var isFrequentMistake: Bool {
        return retryCount >= 3 && !mastered
    }

    /// 优先级评分（用于排序）
    var priorityScore: Double {
        var score = 0.0

        // 状态权重
        switch status {
        case .pending: score += 100
        case .reviewing: score += 50
        case .mastered: score += 10
        case .archived: score += 0
        }

        // 题目难度权重
        if let difficulty = question?.difficulty {
            switch difficulty {
            case .hard: score += 30
            case .medium: score += 20
            case .easy: score += 10
            }
        }

        // 重做次数权重（重做次数越多，优先级越高）
        score += Double(retryCount) * 5

        // 时间权重（越久未复习，优先级越高）
        if let lastRetry = lastRetryTime {
            let daysSince = Date().daysBetween(lastRetry)
            score += Double(daysSince) * 2
        } else {
            score += 50  // 从未重做
        }

        return score
    }
}

// MARK: - Mock Data

#if DEBUG
extension WrongQuestion {
    static let mock = WrongQuestion(
        id: 1,
        userId: 1,
        practiceRecordId: 2,
        question: Question.mockFillBlank,
        practiceRecord: PracticeRecord.mockWrong,
        status: .pending,
        retryCount: 0,
        lastRetryTime: nil,
        mastered: false,
        createdAt: Date(),
        updatedAt: Date(),
        errorType: .calculation,
        reviewSchedule: ReviewScheduleManager.shared.createNewSchedule(),
        similarQuestionIds: [101, 102, 103],
        learningNote: "需要加强分数运算的练习"
    )

    static let mockReviewing = WrongQuestion(
        id: 2,
        userId: 1,
        practiceRecordId: 3,
        question: Question.mockShortAnswer,
        practiceRecord: nil,
        status: .reviewing,
        retryCount: 2,
        lastRetryTime: Date().addingTimeInterval(-2 * 86400),
        mastered: false,
        createdAt: Date().addingTimeInterval(-7 * 86400),
        updatedAt: Date().addingTimeInterval(-2 * 86400),
        errorType: .conceptual,
        reviewSchedule: ReviewSchedule(
            nextReviewDate: Date().addingTimeInterval(2 * 86400),
            reviewCount: 2,
            reviewDates: [
                Date().addingTimeInterval(-7 * 86400),
                Date().addingTimeInterval(-2 * 86400)
            ],
            intervals: [1, 2]
        ),
        similarQuestionIds: [201, 202],
        learningNote: "代数式的概念需要再理解"
    )

    static let mockMastered = WrongQuestion(
        id: 3,
        userId: 1,
        practiceRecordId: 4,
        question: Question.mockChoice,
        practiceRecord: nil,
        status: .mastered,
        retryCount: 5,
        lastRetryTime: Date().addingTimeInterval(-1 * 86400),
        mastered: true,
        createdAt: Date().addingTimeInterval(-14 * 86400),
        updatedAt: Date().addingTimeInterval(-1 * 86400),
        errorType: .careless,
        reviewSchedule: ReviewSchedule(
            nextReviewDate: Date().addingTimeInterval(15 * 86400),
            reviewCount: 5,
            reviewDates: [
                Date().addingTimeInterval(-14 * 86400),
                Date().addingTimeInterval(-13 * 86400),
                Date().addingTimeInterval(-11 * 86400),
                Date().addingTimeInterval(-7 * 86400),
                Date().addingTimeInterval(-1 * 86400)
            ],
            intervals: [1, 2, 4, 7, 15]
        ),
        similarQuestionIds: nil,
        learningNote: "已掌握，注意细心"
    )

    static let mockList: [WrongQuestion] = [mock, mockReviewing, mockMastered]
}

extension WrongQuestionStatistics {
    static var mockStats: WrongQuestionStatistics {
        WrongQuestionStatistics(
            totalCount: 15,
            pendingCount: 5,
            reviewingCount: 7,
            masteredCount: 3,
            byKnowledgePoint: [
                11: 3,  // 正数和负数
                12: 5,  // 有理数的加减
                21: 4,  // 单项式
                22: 3   // 多项式
            ],
            byDifficulty: [
                "easy": 3,
                "medium": 8,
                "hard": 4
            ],
            recentAdded: [WrongQuestion.mock],
            byErrorType: [
                "calculation": 6,
                "conceptual": 4,
                "careless": 3,
                "method": 2
            ],
            todayReviewCount: 3,
            weeklyCompletedCount: 8
        )
    }
}
#endif
