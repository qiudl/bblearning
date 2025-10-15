//
//  PracticeRecord.swift
//  BBLearning
//
//  Created by Claude Code on 2025-10-13.
//

import Foundation

/// 练习记录实体
struct PracticeRecord: Identifiable, Codable, Equatable {
    let id: Int
    let userId: Int
    let questionId: Int
    var question: Question?           // 关联的题目
    var userAnswer: String            // 用户答案
    var isCorrect: Bool               // 是否正确
    var score: Int                    // 得分
    var timeSpent: Int                // 用时（秒）
    var aiGrade: AIGrade?             // AI评分
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case questionId = "question_id"
        case question
        case userAnswer = "user_answer"
        case isCorrect = "is_correct"
        case score
        case timeSpent = "time_spent"
        case aiGrade = "ai_grade"
        case createdAt = "created_at"
    }
}

// MARK: - AI Grade

/// AI评分
struct AIGrade: Codable, Equatable {
    var score: Int                    // 分数
    var feedback: String              // 反馈
    var highlights: [String]?         // 亮点
    var mistakes: [String]?           // 错误点
    var suggestions: [String]?        // 改进建议
    var similarQuestions: [Int]?      // 相似题目ID
}

// MARK: - Extensions

extension PracticeRecord {
    /// 正确率（百分比）
    var correctnessPercentage: Int {
        guard let question = question else { return 0 }
        return Int(Double(score) / Double(question.points) * 100)
    }

    /// 用时描述
    var timeSpentText: String {
        let minutes = timeSpent / 60
        let seconds = timeSpent % 60
        if minutes > 0 {
            return "\(minutes)分\(seconds)秒"
        } else {
            return "\(seconds)秒"
        }
    }

    /// 是否有AI评分
    var hasAIGrade: Bool {
        return aiGrade != nil
    }

    /// 是否有改进建议
    var hasSuggestions: Bool {
        return aiGrade?.suggestions != nil && !aiGrade!.suggestions!.isEmpty
    }

    /// 是否有相似题目
    var hasSimilarQuestions: Bool {
        return aiGrade?.similarQuestions != nil && !aiGrade!.similarQuestions!.isEmpty
    }

    /// 得分率
    var scoreRate: Double {
        guard let question = question else { return 0 }
        return Double(score) / Double(question.points)
    }

    /// 用时评级
    var timeRating: TimeRating {
        guard let question = question else { return .normal }

        let difficulty = question.difficulty
        let baseTime: Int

        switch difficulty {
        case .easy: baseTime = 60        // 简单题基准60秒
        case .medium: baseTime = 120     // 中等题基准120秒
        case .hard: baseTime = 300       // 困难题基准300秒
        }

        let ratio = Double(timeSpent) / Double(baseTime)

        if ratio < 0.5 {
            return .veryFast
        } else if ratio < 0.8 {
            return .fast
        } else if ratio < 1.2 {
            return .normal
        } else if ratio < 1.5 {
            return .slow
        } else {
            return .verySlow
        }
    }

    enum TimeRating {
        case veryFast
        case fast
        case normal
        case slow
        case verySlow

        var displayText: String {
            switch self {
            case .veryFast: return "非常快"
            case .fast: return "较快"
            case .normal: return "正常"
            case .slow: return "较慢"
            case .verySlow: return "很慢"
            }
        }

        var icon: String {
            switch self {
            case .veryFast: return "hare.fill"
            case .fast: return "hare"
            case .normal: return "figure.walk"
            case .slow: return "tortoise"
            case .verySlow: return "tortoise.fill"
            }
        }
    }
}

// MARK: - Practice Session

/// 练习会话（一次练习包含多道题）
struct PracticeSession: Identifiable, Codable, Equatable {
    let id: Int
    let userId: Int
    let knowledgePointId: Int?
    var records: [PracticeRecord]
    var totalScore: Int
    var totalTime: Int
    let createdAt: Date
    let completedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case knowledgePointId = "knowledge_point_id"
        case records
        case totalScore = "total_score"
        case totalTime = "total_time"
        case createdAt = "created_at"
        case completedAt = "completed_at"
    }

    /// 题目总数
    var questionCount: Int {
        return records.count
    }

    /// 正确题数
    var correctCount: Int {
        return records.filter { $0.isCorrect }.count
    }

    /// 正确率
    var correctRate: Double {
        guard questionCount > 0 else { return 0 }
        return Double(correctCount) / Double(questionCount)
    }

    /// 平均用时
    var averageTime: Int {
        guard questionCount > 0 else { return 0 }
        return totalTime / questionCount
    }

    /// 是否完成
    var isCompleted: Bool {
        return completedAt != nil
    }

    /// 进度百分比
    var progressPercentage: Int {
        guard questionCount > 0 else { return 0 }
        let answered = records.filter { !$0.userAnswer.isEmpty }.count
        return Int(Double(answered) / Double(questionCount) * 100)
    }
}

// MARK: - Mock Data

#if DEBUG
extension PracticeRecord {
    static let mock = PracticeRecord(
        id: 1,
        userId: 1,
        questionId: 1,
        question: Question.mockChoice,
        userAnswer: "C",
        isCorrect: true,
        score: 5,
        timeSpent: 45,
        aiGrade: AIGrade(
            score: 5,
            feedback: "回答完全正确！对正数的概念掌握很好。",
            highlights: ["正确识别了正数"],
            mistakes: nil,
            suggestions: ["可以尝试更难的题目"],
            similarQuestions: [2, 3, 4]
        ),
        createdAt: Date()
    )

    static let mockWrong = PracticeRecord(
        id: 2,
        userId: 1,
        questionId: 2,
        question: Question.mockFillBlank,
        userAnswer: "-2",
        isCorrect: false,
        score: 0,
        timeSpent: 120,
        aiGrade: AIGrade(
            score: 0,
            feedback: "符号判断错误，需要加强有理数加法法则的学习。",
            highlights: nil,
            mistakes: ["符号判断错误：应该取绝对值较大的加数的符号"],
            suggestions: [
                "复习有理数加法法则",
                "重点练习异号两数相加",
                "建议先做简单题巩固基础"
            ],
            similarQuestions: [5, 6]
        ),
        createdAt: Date()
    )

    static let mockList: [PracticeRecord] = [mock, mockWrong]
}

extension PracticeSession {
    static let mock = PracticeSession(
        id: 1,
        userId: 1,
        knowledgePointId: 11,
        records: PracticeRecord.mockList,
        totalScore: 5,
        totalTime: 165,
        createdAt: Date(),
        completedAt: Date()
    )
}
#endif
