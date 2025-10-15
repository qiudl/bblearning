//
//  SmartQuestionSelector.swift
//  BBLearning
//
//  Created by Claude Code on 2025-10-15.
//

import Foundation

/// 智能组卷算法
class SmartQuestionSelector {
    static let shared = SmartQuestionSelector()

    private init() {}

    /// 智能选题策略
    struct SelectionStrategy {
        let knowledgePointIds: [Int]
        let targetCount: Int
        let difficulty: Question.Difficulty?
        let mode: PracticeMode
        let userLevel: Int
        let recentWrongQuestions: [WrongQuestion]
    }

    /// 选题结果
    struct SelectionResult {
        let questions: [Question]
        let distribution: DifficultyDistribution
        let estimatedTime: Int  // 预估完成时间（秒）
    }

    struct DifficultyDistribution {
        let easy: Int
        let medium: Int
        let hard: Int

        var total: Int {
            easy + medium + hard
        }
    }

    /// 智能选题主方法
    /// - Parameter strategy: 选题策略
    /// - Returns: 选题结果
    func selectQuestions(strategy: SelectionStrategy) -> SelectionResult {
        switch strategy.mode {
        case .standard:
            return selectStandardQuestions(strategy: strategy)
        case .adaptive:
            return selectAdaptiveQuestions(strategy: strategy)
        case .wrongQuestions:
            return selectWrongQuestions(strategy: strategy)
        }
    }

    // MARK: - Standard Mode

    private func selectStandardQuestions(strategy: SelectionStrategy) -> SelectionResult {
        var distribution: DifficultyDistribution

        if let difficulty = strategy.difficulty {
            // 指定难度：80%目标难度 + 20%相邻难度
            distribution = createFixedDistribution(
                targetCount: strategy.targetCount,
                mainDifficulty: difficulty
            )
        } else {
            // 未指定难度：根据用户水平自动分配
            distribution = createBalancedDistribution(
                targetCount: strategy.targetCount,
                userLevel: strategy.userLevel
            )
        }

        let questions = generateQuestionList(
            knowledgePointIds: strategy.knowledgePointIds,
            distribution: distribution
        )

        let estimatedTime = calculateEstimatedTime(
            questionCount: questions.count,
            avgDifficulty: questions.averageDifficulty
        )

        return SelectionResult(
            questions: questions,
            distribution: distribution,
            estimatedTime: estimatedTime
        )
    }

    // MARK: - Adaptive Mode

    private func selectAdaptiveQuestions(strategy: SelectionStrategy) -> SelectionResult {
        // 自适应难度：根据用户历史表现动态调整
        let initialDifficulty = determineInitialDifficulty(userLevel: strategy.userLevel)

        var questions: [Question] = []
        var currentDifficulty = initialDifficulty

        for i in 0..<strategy.targetCount {
            let question = selectAdaptiveQuestion(
                knowledgePointIds: strategy.knowledgePointIds,
                difficulty: currentDifficulty,
                index: i
            )
            questions.append(question)

            // 根据前面题目的难度调整后续题目
            if i > 0 && i % 5 == 0 {
                // 每5题评估一次，调整难度
                currentDifficulty = adjustDifficulty(
                    current: currentDifficulty,
                    userLevel: strategy.userLevel
                )
            }
        }

        let distribution = calculateDistribution(questions: questions)
        let estimatedTime = calculateEstimatedTime(
            questionCount: questions.count,
            avgDifficulty: questions.averageDifficulty
        )

        return SelectionResult(
            questions: questions,
            distribution: distribution,
            estimatedTime: estimatedTime
        )
    }

    // MARK: - Wrong Questions Mode

    private func selectWrongQuestions(strategy: SelectionStrategy) -> SelectionResult {
        // 错题模式：优先选择高频错题和薄弱知识点
        let prioritizedWrongQuestions = strategy.recentWrongQuestions.sorted {
            $0.priorityScore > $1.priorityScore
        }

        var questions: [Question] = []
        var count = 0

        for wrongQ in prioritizedWrongQuestions {
            guard count < strategy.targetCount else { break }

            if let question = wrongQ.question,
               strategy.knowledgePointIds.isEmpty ||
               strategy.knowledgePointIds.contains(question.knowledgePointId) {
                questions.append(question)
                count += 1
            }
        }

        // 如果错题不够，补充相关题目
        if count < strategy.targetCount {
            let additionalQuestions = generateSimilarQuestions(
                wrongQuestions: Array(prioritizedWrongQuestions.prefix(5)),
                needed: strategy.targetCount - count
            )
            questions.append(contentsOf: additionalQuestions)
        }

        let distribution = calculateDistribution(questions: questions)
        let estimatedTime = calculateEstimatedTime(
            questionCount: questions.count,
            avgDifficulty: questions.averageDifficulty
        )

        return SelectionResult(
            questions: questions,
            distribution: distribution,
            estimatedTime: estimatedTime
        )
    }

    // MARK: - Helper Methods

    /// 创建固定难度分布（80%主难度 + 20%相邻难度）
    private func createFixedDistribution(
        targetCount: Int,
        mainDifficulty: Question.Difficulty
    ) -> DifficultyDistribution {
        let mainCount = Int(Double(targetCount) * 0.8)
        let adjacentCount = targetCount - mainCount

        switch mainDifficulty {
        case .easy:
            return DifficultyDistribution(
                easy: mainCount,
                medium: adjacentCount,
                hard: 0
            )
        case .medium:
            return DifficultyDistribution(
                easy: adjacentCount / 2,
                medium: mainCount,
                hard: adjacentCount - adjacentCount / 2
            )
        case .hard:
            return DifficultyDistribution(
                easy: 0,
                medium: adjacentCount,
                hard: mainCount
            )
        }
    }

    /// 创建平衡难度分布（根据用户水平）
    private func createBalancedDistribution(
        targetCount: Int,
        userLevel: Int
    ) -> DifficultyDistribution {
        // 用户等级越高，难题比例越大
        let hardRatio: Double
        let mediumRatio: Double
        let easyRatio: Double

        switch userLevel {
        case 1...10:  // 初级
            easyRatio = 0.5
            mediumRatio = 0.4
            hardRatio = 0.1
        case 11...25:  // 中级
            easyRatio = 0.3
            mediumRatio = 0.5
            hardRatio = 0.2
        default:  // 高级
            easyRatio = 0.2
            mediumRatio = 0.4
            hardRatio = 0.4
        }

        return DifficultyDistribution(
            easy: Int(Double(targetCount) * easyRatio),
            medium: Int(Double(targetCount) * mediumRatio),
            hard: Int(Double(targetCount) * hardRatio)
        )
    }

    /// 确定初始难度
    private func determineInitialDifficulty(userLevel: Int) -> Question.Difficulty {
        switch userLevel {
        case 1...10: return .easy
        case 11...25: return .medium
        default: return .hard
        }
    }

    /// 调整自适应难度
    private func adjustDifficulty(
        current: Question.Difficulty,
        userLevel: Int
    ) -> Question.Difficulty {
        // TODO: 根据实际答题情况动态调整
        // 这里简化为根据用户等级返回
        return determineInitialDifficulty(userLevel: userLevel)
    }

    /// 生成题目列表
    private func generateQuestionList(
        knowledgePointIds: [Int],
        distribution: DifficultyDistribution
    ) -> [Question] {
        // TODO: 从题库中按分布抽取题目
        // 这里返回模拟数据
        var questions: [Question] = []

        // 简单题
        for _ in 0..<distribution.easy {
            questions.append(Question.mockChoice)  // 使用mock数据
        }

        // 中等题
        for _ in 0..<distribution.medium {
            questions.append(Question.mockFillBlank)
        }

        // 困难题
        for _ in 0..<distribution.hard {
            questions.append(Question.mockShortAnswer)
        }

        return questions.shuffled()
    }

    /// 选择自适应题目
    private func selectAdaptiveQuestion(
        knowledgePointIds: [Int],
        difficulty: Question.Difficulty,
        index: Int
    ) -> Question {
        // TODO: 从题库中选择符合条件的题目
        // 这里返回mock数据
        switch difficulty {
        case .easy: return Question.mockChoice
        case .medium: return Question.mockFillBlank
        case .hard: return Question.mockShortAnswer
        }
    }

    /// 生成相似题目
    private func generateSimilarQuestions(
        wrongQuestions: [WrongQuestion],
        needed: Int
    ) -> [Question] {
        // TODO: 根据错题生成相似题目
        // 这里返回mock数据
        return Array(repeating: Question.mockChoice, count: needed)
    }

    /// 计算实际分布
    private func calculateDistribution(questions: [Question]) -> DifficultyDistribution {
        let easy = questions.filter { $0.difficulty == .easy }.count
        let medium = questions.filter { $0.difficulty == .medium }.count
        let hard = questions.filter { $0.difficulty == .hard }.count

        return DifficultyDistribution(easy: easy, medium: medium, hard: hard)
    }

    /// 计算预估时间（秒）
    private func calculateEstimatedTime(
        questionCount: Int,
        avgDifficulty: Double
    ) -> Int {
        // 基准时间：简单60秒，中等90秒，困难120秒
        // avgDifficulty: 1.0=easy, 2.0=medium, 3.0=hard
        let baseTime = 30 + Int(avgDifficulty * 30)
        return baseTime * questionCount
    }
}

// MARK: - Question Extension

extension Array where Element == Question {
    /// 计算平均难度（1.0-3.0）
    var averageDifficulty: Double {
        guard !isEmpty else { return 2.0 }

        let sum = reduce(0.0) { result, question in
            switch question.difficulty {
            case .easy: return result + 1.0
            case .medium: return result + 2.0
            case .hard: return result + 3.0
            }
        }

        return sum / Double(count)
    }
}
