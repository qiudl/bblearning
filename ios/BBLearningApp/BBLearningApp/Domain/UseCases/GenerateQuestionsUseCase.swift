//
//  GenerateQuestionsUseCase.swift
//  BBLearning
//
//  Created by Claude Code on 2025-10-13.
//

import Foundation
import Combine

/// 生成练习题用例
final class GenerateQuestionsUseCase {
    private let practiceRepository: PracticeRepositoryProtocol
    private let knowledgeRepository: KnowledgeRepositoryProtocol

    init(practiceRepository: PracticeRepositoryProtocol,
         knowledgeRepository: KnowledgeRepositoryProtocol) {
        self.practiceRepository = practiceRepository
        self.knowledgeRepository = knowledgeRepository
    }

    /// 为指定知识点生成练习题
    /// - Parameters:
    ///   - knowledgePointIds: 知识点ID列表
    ///   - count: 题目数量
    ///   - difficulty: 难度级别（可选，不指定则混合难度）
    /// - Returns: 题目列表
    func execute(knowledgePointIds: [Int], count: Int = 10, difficulty: Question.Difficulty? = nil) -> AnyPublisher<[Question], APIError> {
        // 1. 验证参数
        guard !knowledgePointIds.isEmpty else {
            return Fail(error: APIError.badRequest("请选择至少一个知识点")).eraseToAnyPublisher()
        }

        guard count > 0 && count <= 50 else {
            return Fail(error: APIError.badRequest("题目数量应在1-50之间")).eraseToAnyPublisher()
        }

        // 2. 调用Repository生成题目
        return practiceRepository.generateQuestions(
            knowledgePointIds: knowledgePointIds,
            count: count,
            difficulty: difficulty
        )
        .handleEvents(receiveOutput: { questions in
            Logger.shared.info("成功生成\(questions.count)道练习题")
        })
        .eraseToAnyPublisher()
    }

    /// 根据用户当前水平智能生成练习题
    /// - Parameters:
    ///   - knowledgePointId: 知识点ID
    ///   - count: 题目数量
    /// - Returns: 题目列表
    func generateAdaptive(knowledgePointId: Int, count: Int = 10) -> AnyPublisher<[Question], APIError> {
        // 1. 获取知识点进度，判断用户水平
        return knowledgeRepository.getProgress(knowledgePointId: knowledgePointId)
            .flatMap { [weak self] progress -> AnyPublisher<[Question], APIError> in
                guard let self = self else {
                    return Fail(error: APIError.unknown).eraseToAnyPublisher()
                }

                // 2. 根据掌握度选择难度
                let difficulty = self.determineDifficulty(from: progress)

                Logger.shared.info("根据掌握度\(progress?.masteryLevel ?? 0)选择难度：\(difficulty)")

                // 3. 生成题目
                return self.execute(
                    knowledgePointIds: [knowledgePointId],
                    count: count,
                    difficulty: difficulty
                )
            }
            .eraseToAnyPublisher()
    }

    /// 为多个知识点生成综合练习
    /// - Parameters:
    ///   - knowledgePointIds: 知识点ID列表
    ///   - totalCount: 总题目数量
    ///   - distribution: 难度分布（简单:中等:困难）
    /// - Returns: 题目列表
    func generateComprehensive(
        knowledgePointIds: [Int],
        totalCount: Int = 20,
        distribution: DifficultyDistribution = .balanced
    ) -> AnyPublisher<[Question], APIError> {
        guard !knowledgePointIds.isEmpty else {
            return Fail(error: APIError.badRequest("请选择知识点")).eraseToAnyPublisher()
        }

        // 根据分布策略生成不同难度的题目
        let counts = distribution.calculateCounts(total: totalCount)

        let publishers = [
            counts.easy > 0 ? execute(knowledgePointIds: knowledgePointIds, count: counts.easy, difficulty: .easy) : Just([]).setFailureType(to: APIError.self).eraseToAnyPublisher(),
            counts.medium > 0 ? execute(knowledgePointIds: knowledgePointIds, count: counts.medium, difficulty: .medium) : Just([]).setFailureType(to: APIError.self).eraseToAnyPublisher(),
            counts.hard > 0 ? execute(knowledgePointIds: knowledgePointIds, count: counts.hard, difficulty: .hard) : Just([]).setFailureType(to: APIError.self).eraseToAnyPublisher()
        ]

        return Publishers.MergeMany(publishers)
            .collect()
            .map { results in
                // 合并所有难度的题目并打乱顺序
                let allQuestions = results.flatMap { $0 }
                return allQuestions.shuffled()
            }
            .eraseToAnyPublisher()
    }

    // MARK: - Private Helpers

    /// 根据学习进度确定合适的难度
    private func determineDifficulty(from progress: LearningProgress?) -> Question.Difficulty {
        guard let progress = progress else {
            return .easy  // 未学习，从简单开始
        }

        let masteryLevel = progress.masteryLevel
        let accuracy = progress.practiceCount > 0 ? Double(progress.correctCount) / Double(progress.practiceCount) : 0

        // 综合掌握度和正确率判断
        let score = (masteryLevel + accuracy) / 2

        if score < 0.5 {
            return .easy
        } else if score < 0.75 {
            return .medium
        } else {
            return .hard
        }
    }
}

// MARK: - Difficulty Distribution

/// 难度分布策略
enum DifficultyDistribution {
    case easy           // 简单为主 (70% 简单, 25% 中等, 5% 困难)
    case balanced       // 均衡 (30% 简单, 50% 中等, 20% 困难)
    case challenging    // 挑战 (10% 简单, 40% 中等, 50% 困难)
    case custom(easy: Double, medium: Double, hard: Double)  // 自定义比例

    func calculateCounts(total: Int) -> (easy: Int, medium: Int, hard: Int) {
        let (easyRatio, mediumRatio, _): (Double, Double, Double)

        switch self {
        case .easy:
            (easyRatio, mediumRatio, _) = (0.7, 0.25, 0.05)
        case .balanced:
            (easyRatio, mediumRatio, _) = (0.3, 0.5, 0.2)
        case .challenging:
            (easyRatio, mediumRatio, _) = (0.1, 0.4, 0.5)
        case .custom(let e, let m, let h):
            let sum = e + m + h
            (easyRatio, mediumRatio, _) = (e / sum, m / sum, h / sum)
        }

        let easyCount = Int(Double(total) * easyRatio)
        let mediumCount = Int(Double(total) * mediumRatio)
        let hardCount = total - easyCount - mediumCount  // 确保总数正确

        return (easyCount, mediumCount, hardCount)
    }
}
