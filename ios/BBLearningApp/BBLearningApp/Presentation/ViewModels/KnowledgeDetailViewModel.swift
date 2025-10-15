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
    @Published var breadcrumbPath: [KnowledgePoint] = []
    @Published var isFavorite: Bool = false

    private let getKnowledgeTreeUseCase: GetKnowledgeTreeUseCase
    private let favoriteManager: FavoriteKnowledgeManager

    init(knowledgePoint: KnowledgePoint,
         getKnowledgeTreeUseCase: GetKnowledgeTreeUseCase = DIContainer.shared.resolve(GetKnowledgeTreeUseCase.self),
         favoriteManager: FavoriteKnowledgeManager = .shared) {
        self.knowledgePoint = knowledgePoint
        self.getKnowledgeTreeUseCase = getKnowledgeTreeUseCase
        self.favoriteManager = favoriteManager
        super.init()

        // 初始化收藏状态
        self.isFavorite = favoriteManager.isFavorite(knowledgePoint.id)

        loadChildren()
        loadBreadcrumbPath()
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
        guard knowledgePoint.progress != nil else {
            return "未开始学习"
        }
        return "\(knowledgePoint.progressPercentage)% 掌握度"
    }

    var accuracyText: String {
        let accuracy = knowledgePoint.accuracyRate
        return String(format: "%.1f%% 正确率", accuracy * 100)
    }

    // MARK: - 面包屑导航

    func loadBreadcrumbPath() {
        executeTask(
            getKnowledgeTreeUseCase.buildPath(for: knowledgePoint),
            onSuccess: { [weak self] path in
                self?.breadcrumbPath = path
            }
        )
    }

    // MARK: - 收藏功能

    func toggleFavorite() {
        favoriteManager.toggleFavorite(knowledgePoint.id)
        isFavorite = favoriteManager.isFavorite(knowledgePoint.id)
    }
}
