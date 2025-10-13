//
//  KnowledgeDetailViewModel.swift
//  BBLearning
//
//  Created by Claude Code on 2025-10-13.
//

import Foundation
import Combine

final class KnowledgeDetailViewModel: BaseViewModel {
    @Published var knowledgePoint: KnowledgePoint
    @Published var children: [KnowledgePoint] = []

    private let getKnowledgeTreeUseCase: GetKnowledgeTreeUseCase

    init(knowledgePoint: KnowledgePoint, getKnowledgeTreeUseCase: GetKnowledgeTreeUseCase = DIContainer.shared.resolve(GetKnowledgeTreeUseCase.self)) {
        self.knowledgePoint = knowledgePoint
        self.getKnowledgeTreeUseCase = getKnowledgeTreeUseCase
        super.init()
        loadChildren()
    }

    func loadChildren() {
        guard knowledgePoint.hasChildren else { return }

        executeTask(
            getKnowledgeTreeUseCase.getChildren(parentId: knowledgePoint.id),
            onSuccess: { [weak self] children in
                self?.children = children
            }
        )
    }

    func refresh() {
        executeTask(
            getKnowledgeTreeUseCase.getKnowledgePoint(id: knowledgePoint.id),
            onSuccess: { [weak self] kp in
                self?.knowledgePoint = kp
                self?.loadChildren()
            }
        )
    }

    var progressText: String {
        guard let progress = knowledgePoint.progress else {
            return "未开始学习"
        }
        return "\(knowledgePoint.progressPercentage)% 掌握度"
    }

    var accuracyText: String {
        let accuracy = knowledgePoint.accuracyRate
        return String(format: "%.1f%% 正确率", accuracy * 100)
    }
}
