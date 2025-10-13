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

    enum CodingKeys: String, CodingKey {
        case totalCount = "total_count"
        case pendingCount = "pending_count"
        case reviewingCount = "reviewing_count"
        case masteredCount = "mastered_count"
        case byKnowledgePoint = "by_knowledge_point"
        case byDifficulty = "by_difficulty"
        case recentAdded = "recent_added"
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
}

// MARK: - Extensions

extension WrongQuestion {
    /// 是否需要复习（根据遗忘曲线）
    var needsReview: Bool {
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
        updatedAt: Date()
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
        updatedAt: Date().addingTimeInterval(-2 * 86400)
    )

    static let mockMastered = WrongQuestion(
        id: 3,
        userId: 1,
        practiceRecordId: 4,
        question: Question.mockChoice,
        practiceRecord: nil,
        status: .mastered,
        retryCount: 3,
        lastRetryTime: Date().addingTimeInterval(-1 * 86400),
        mastered: true,
        createdAt: Date().addingTimeInterval(-14 * 86400),
        updatedAt: Date().addingTimeInterval(-1 * 86400)
    )

    static let mockList: [WrongQuestion] = [mock, mockReviewing, mockMastered]
}

extension WrongQuestionStatistics {
    static let mock = WrongQuestionStatistics(
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
        recentAdded: [WrongQuestion.mock]
    )
}
#endif
