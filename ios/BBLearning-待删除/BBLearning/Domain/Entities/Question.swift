//
//  Question.swift
//  BBLearning
//
//  Created by Claude Code on 2025-10-13.
//

import Foundation

/// 题目实体
struct Question: Identifiable, Codable, Equatable {
    let id: Int
    let knowledgePointId: Int
    let type: QuestionType
    let difficulty: Difficulty
    var content: QuestionContent
    var answer: Answer
    var analysis: String?
    var points: Int
    let createdAt: Date
    var updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case knowledgePointId = "knowledge_point_id"
        case type
        case difficulty
        case content
        case answer
        case analysis
        case points
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    /// 题目类型
    enum QuestionType: String, Codable {
        case choice = "choice"           // 选择题
        case fillBlank = "fill_blank"    // 填空题
        case shortAnswer = "short_answer" // 解答题

        var displayText: String {
            switch self {
            case .choice: return "选择题"
            case .fillBlank: return "填空题"
            case .shortAnswer: return "解答题"
            }
        }

        var icon: String {
            switch self {
            case .choice: return "checklist"
            case .fillBlank: return "square.and.pencil"
            case .shortAnswer: return "doc.text"
            }
        }
    }

    /// 难度级别
    enum Difficulty: String, Codable {
        case easy
        case medium
        case hard

        var displayText: String {
            switch self {
            case .easy: return "简单"
            case .medium: return "中等"
            case .hard: return "困难"
            }
        }

        var level: Int {
            switch self {
            case .easy: return 1
            case .medium: return 2
            case .hard: return 3
            }
        }
    }
}

// MARK: - Question Content

/// 题目内容
struct QuestionContent: Codable, Equatable {
    var stem: String              // 题干（支持LaTeX公式）
    var options: [String]?        // 选项（选择题使用）
    var images: [String]?         // 图片URL列表
    var blanks: Int?              // 填空数量（填空题使用）
    var tips: String?             // 提示信息
}

// MARK: - Answer

/// 答案
struct Answer: Codable, Equatable {
    var content: String           // 答案内容（支持LaTeX）
    var steps: [String]?          // 解题步骤
    var keyPoints: [String]?      // 关键点
    var commonMistakes: [String]? // 常见错误
}

// MARK: - Extensions

extension Question {
    /// 是否为选择题
    var isChoice: Bool {
        return type == .choice
    }

    /// 是否为填空题
    var isFillBlank: Bool {
        return type == .fillBlank
    }

    /// 是否为解答题
    var isShortAnswer: Bool {
        return type == .shortAnswer
    }

    /// 是否有图片
    var hasImages: Bool {
        return content.images != nil && !content.images!.isEmpty
    }

    /// 选项数量
    var optionCount: Int {
        return content.options?.count ?? 0
    }

    /// 是否有解题步骤
    var hasSteps: Bool {
        return answer.steps != nil && !answer.steps!.isEmpty
    }

    /// 难度分数（用于推荐算法）
    var difficultyScore: Double {
        switch difficulty {
        case .easy: return 1.0
        case .medium: return 2.0
        case .hard: return 3.0
        }
    }
}

// MARK: - Mock Data

#if DEBUG
extension Question {
    static let mockChoice = Question(
        id: 1,
        knowledgePointId: 11,
        type: .choice,
        difficulty: .easy,
        content: QuestionContent(
            stem: "下列各数中，是正数的是（  ）",
            options: ["A. -3", "B. 0", "C. 5", "D. -1/2"],
            images: nil,
            blanks: nil,
            tips: "正数是大于0的数"
        ),
        answer: Answer(
            content: "C",
            steps: ["正数是大于0的数", "5 > 0，所以5是正数"],
            keyPoints: ["正数的定义"],
            commonMistakes: ["误认为0是正数"]
        ),
        analysis: "正数是大于零的数，A、D选项是负数，B选项是0，只有C选项5是正数。",
        points: 5,
        createdAt: Date(),
        updatedAt: Date()
    )

    static let mockFillBlank = Question(
        id: 2,
        knowledgePointId: 12,
        type: .fillBlank,
        difficulty: .medium,
        content: QuestionContent(
            stem: "计算：$(-3) + 5 = $ ______",
            options: nil,
            images: nil,
            blanks: 1,
            tips: "异号两数相加，取绝对值较大的符号"
        ),
        answer: Answer(
            content: "2",
            steps: [
                "确定符号：|5| > |-3|，结果为正",
                "计算绝对值之差：5 - 3 = 2",
                "所以 (-3) + 5 = 2"
            ],
            keyPoints: ["有理数加法法则", "绝对值"],
            commonMistakes: ["忘记判断符号", "计算错误"]
        ),
        analysis: "异号两数相加，取绝对值较大的加数的符号，并用较大的绝对值减去较小的绝对值。",
        points: 5,
        createdAt: Date(),
        updatedAt: Date()
    )

    static let mockShortAnswer = Question(
        id: 3,
        knowledgePointId: 12,
        type: .shortAnswer,
        difficulty: .hard,
        content: QuestionContent(
            stem: "已知 $a$ 和 $b$ 是两个有理数，且 $|a| = 5$，$|b| = 3$，$a < b$，求 $a + b$ 的值。",
            options: nil,
            images: nil,
            blanks: nil,
            tips: "注意绝对值的两种可能性"
        ),
        answer: Answer(
            content: "$a + b = -2$ 或 $a + b = -8$",
            steps: [
                "由 $|a| = 5$ 得：$a = 5$ 或 $a = -5$",
                "由 $|b| = 3$ 得：$b = 3$ 或 $b = -3$",
                "因为 $a < b$，所以：",
                "  情况1：$a = -5$，$b = 3$，则 $a + b = -2$",
                "  情况2：$a = -5$，$b = -3$，则 $a + b = -8$"
            ],
            keyPoints: ["绝对值的定义", "不等式", "分类讨论"],
            commonMistakes: ["遗漏某种情况", "忽略 a < b 的条件"]
        ),
        analysis: "根据绝对值的定义确定a和b的所有可能取值，再根据a<b的条件筛选出符合的情况。",
        points: 10,
        createdAt: Date(),
        updatedAt: Date()
    )

    static let mockList: [Question] = [mockChoice, mockFillBlank, mockShortAnswer]
}
#endif
