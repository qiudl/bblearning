//
//  SubmitAnswerUseCase.swift
//  BBLearning
//
//  Created by Claude Code on 2025-10-13.
//

import Foundation
import Combine

/// 提交答案用例
final class SubmitAnswerUseCase {
    private let practiceRepository: PracticeRepositoryProtocol
    private let knowledgeRepository: KnowledgeRepositoryProtocol
    private let wrongQuestionRepository: WrongQuestionRepositoryProtocol

    init(practiceRepository: PracticeRepositoryProtocol,
         knowledgeRepository: KnowledgeRepositoryProtocol,
         wrongQuestionRepository: WrongQuestionRepositoryProtocol) {
        self.practiceRepository = practiceRepository
        self.knowledgeRepository = knowledgeRepository
        self.wrongQuestionRepository = wrongQuestionRepository
    }

    /// 提交答案并获取评分
    /// - Parameters:
    ///   - questionId: 题目ID
    ///   - answer: 用户答案
    ///   - timeSpent: 用时（秒）
    /// - Returns: 练习记录（包含AI评分）
    func execute(questionId: Int, answer: String, timeSpent: Int) -> AnyPublisher<PracticeRecord, APIError> {
        // 1. 验证参数
        guard !answer.trimmed.isEmpty else {
            return Fail(error: APIError.badRequest("答案不能为空")).eraseToAnyPublisher()
        }

        guard timeSpent > 0 else {
            return Fail(error: APIError.badRequest("用时无效")).eraseToAnyPublisher()
        }

        // 2. 提交答案到服务器进行AI评分
        return practiceRepository.submitAnswer(
            questionId: questionId,
            answer: answer,
            timeSpent: timeSpent
        )
        .flatMap { [weak self] record -> AnyPublisher<PracticeRecord, APIError> in
            guard let self = self else {
                return Fail(error: APIError.unknown).eraseToAnyPublisher()
            }

            // 3. 处理提交后的逻辑
            return self.handleSubmissionResult(record)
        }
        .eraseToAnyPublisher()
    }

    /// 批量提交答案（用于练习会话）
    /// - Parameter submissions: 提交列表
    /// - Returns: 练习记录列表
    func submitBatch(_ submissions: [AnswerSubmission]) -> AnyPublisher<[PracticeRecord], APIError> {
        let publishers = submissions.map { submission in
            execute(questionId: submission.questionId, answer: submission.answer, timeSpent: submission.timeSpent)
        }

        return Publishers.MergeMany(publishers)
            .collect()
            .eraseToAnyPublisher()
    }

    // MARK: - Private Helpers

    /// 处理提交结果
    private func handleSubmissionResult(_ record: PracticeRecord) -> AnyPublisher<PracticeRecord, APIError> {
        var publishers: [AnyPublisher<Void, APIError>] = []

        // 1. 如果答错了，添加到错题本
        if !record.isCorrect {
            let addWrongQuestion = wrongQuestionRepository.addWrongQuestion(practiceRecordId: record.id)
                .map { _ in () }
                .eraseToAnyPublisher()
            publishers.append(addWrongQuestion)
        }

        // 2. 更新知识点学习进度
        if let question = record.question {
            let updateProgress = updateKnowledgeProgress(
                knowledgePointId: question.knowledgePointId,
                isCorrect: record.isCorrect
            )
            publishers.append(updateProgress)
        }

        // 3. 如果没有需要执行的副作用，直接返回
        if publishers.isEmpty {
            return Just(record)
                .setFailureType(to: APIError.self)
                .eraseToAnyPublisher()
        }

        // 4. 执行所有副作用，然后返回记录
        return Publishers.MergeMany(publishers)
            .collect()
            .map { _ in record }
            .eraseToAnyPublisher()
    }

    /// 更新知识点学习进度
    private func updateKnowledgeProgress(knowledgePointId: Int, isCorrect: Bool) -> AnyPublisher<Void, APIError> {
        return knowledgeRepository.getProgress(knowledgePointId: knowledgePointId)
            .flatMap { [weak self] currentProgress -> AnyPublisher<Void, APIError> in
                guard let self = self else {
                    return Fail(error: APIError.unknown).eraseToAnyPublisher()
                }

                // 计算新的掌握度
                let newProgress = self.calculateNewProgress(current: currentProgress, isCorrect: isCorrect, knowledgePointId: knowledgePointId)

                return self.knowledgeRepository.updateProgress(knowledgePointId: knowledgePointId, progress: newProgress)
                    .map { _ in () }
                    .eraseToAnyPublisher()
            }
            .catch { error -> AnyPublisher<Void, APIError> in
                Logger.shared.warning("更新知识点进度失败: \(error.localizedDescription)")
                // 即使更新进度失败，也不影响提交结果
                return Just(()).setFailureType(to: APIError.self).eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }

    /// 计算新的学习进度
    private func calculateNewProgress(current: LearningProgress?, isCorrect: Bool, knowledgePointId: Int) -> LearningProgress {
        // 如果没有现有进度，创建新的
        guard var progress = current else {
            guard let userId = KeychainManager.shared.getUserId() else {
                fatalError("用户未登录")
            }

            return LearningProgress(
                userId: userId,
                knowledgePointId: knowledgePointId,
                masteryLevel: isCorrect ? 0.2 : 0.0,
                practiceCount: 1,
                correctCount: isCorrect ? 1 : 0,
                lastPracticeTime: Date(),
                status: .learning
            )
        }

        // 更新练习次数和正确次数
        progress.practiceCount += 1
        if isCorrect {
            progress.correctCount += 1
        }

        // 计算新的掌握度（使用指数加权移动平均）
        let currentAccuracy = Double(progress.correctCount) / Double(progress.practiceCount)
        let learningRate = 0.3  // 学习率
        progress.masteryLevel = progress.masteryLevel * (1 - learningRate) + currentAccuracy * learningRate

        // 更新时间
        progress.lastPracticeTime = Date()

        // 更新状态
        if progress.masteryLevel >= 0.9 && currentAccuracy >= 0.9 {
            progress.status = .mastered
        } else if progress.practiceCount > 0 {
            progress.status = .learning
        }

        return progress
    }
}

// MARK: - Answer Submission

/// 答案提交数据
struct AnswerSubmission {
    let questionId: Int
    let answer: String
    let timeSpent: Int
}
