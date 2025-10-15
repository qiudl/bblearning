//
//  WrongQuestionDetailViewModel.swift
//  BBLearning
//
//  Created by Claude Code on 2025-10-15.
//

import Foundation
import Combine

/// 错题详情ViewModel
final class WrongQuestionDetailViewModel: BaseViewModel {
    private let wrongQuestionRepository: WrongQuestionRepository

    init(wrongQuestionRepository: WrongQuestionRepository = DIContainer.shared.resolve(WrongQuestionRepository.self)) {
        self.wrongQuestionRepository = wrongQuestionRepository
        super.init()
    }

    /// 标记为已掌握
    /// - Parameter wrongQuestion: 错题
    func markAsMastered(_ wrongQuestion: WrongQuestion) {
        var updated = wrongQuestion
        updated.status = .mastered
        updated.mastered = true
        updated.updatedAt = Date()

        executeTask(
            wrongQuestionRepository.update(updated),
            onSuccess: { _ in
                Logger.shared.info("错题已标记为掌握")
                // 发送通知更新UI
                NotificationCenter.default.post(name: .wrongQuestionUpdated, object: updated)
            }
        )
    }

    /// 保存学习笔记
    /// - Parameters:
    ///   - note: 笔记内容
    ///   - wrongQuestion: 错题
    func saveLearningNote(_ note: String, for wrongQuestion: WrongQuestion) {
        var updated = wrongQuestion
        updated.learningNote = note
        updated.updatedAt = Date()

        executeTask(
            wrongQuestionRepository.update(updated),
            onSuccess: { _ in
                Logger.shared.info("学习笔记已保存")
                NotificationCenter.default.post(name: .wrongQuestionUpdated, object: updated)
            }
        )
    }

    /// 添加到收藏
    func addToFavorites() {
        // TODO: 实现收藏功能
        Logger.shared.info("添加到收藏")
    }

    /// 分享题目
    func shareQuestion() {
        // TODO: 实现分享功能
        Logger.shared.info("分享题目")
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let wrongQuestionUpdated = Notification.Name("wrongQuestionUpdated")
}
