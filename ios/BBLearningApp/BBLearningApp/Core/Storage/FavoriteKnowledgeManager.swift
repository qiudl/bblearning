//
//  FavoriteKnowledgeManager.swift
//  BBLearningApp
//
//  Created by Claude Code on 2025-10-15.
//  知识点收藏管理器
//

import Foundation
import Combine

/// 知识点收藏管理器
final class FavoriteKnowledgeManager: ObservableObject {
    static let shared = FavoriteKnowledgeManager()

    @Published var favoriteIds: Set<Int> = []

    private let userDefaults = UserDefaults.standard
    private let favoritesKey = "favorite_knowledge_points"

    private init() {
        loadFavorites()
    }

    // MARK: - Public Methods

    /// 切换收藏状态
    /// - Parameter id: 知识点ID
    func toggleFavorite(_ id: Int) {
        if favoriteIds.contains(id) {
            removeFavorite(id)
        } else {
            addFavorite(id)
        }
    }

    /// 添加收藏
    /// - Parameter id: 知识点ID
    func addFavorite(_ id: Int) {
        favoriteIds.insert(id)
        saveFavorites()
        Logger.shared.info("添加知识点收藏 - ID: \(id)")
    }

    /// 移除收藏
    /// - Parameter id: 知识点ID
    func removeFavorite(_ id: Int) {
        favoriteIds.remove(id)
        saveFavorites()
        Logger.shared.info("移除知识点收藏 - ID: \(id)")
    }

    /// 检查是否已收藏
    /// - Parameter id: 知识点ID
    /// - Returns: 是否已收藏
    func isFavorite(_ id: Int) -> Bool {
        return favoriteIds.contains(id)
    }

    /// 获取所有收藏的知识点ID
    /// - Returns: 收藏ID列表（按添加时间倒序）
    func getFavoriteIds() -> [Int] {
        return Array(favoriteIds).sorted(by: >)
    }

    /// 获取收藏数量
    var favoriteCount: Int {
        return favoriteIds.count
    }

    /// 清空所有收藏
    func clearAllFavorites() {
        favoriteIds.removeAll()
        saveFavorites()
        Logger.shared.info("已清空所有收藏")
    }

    // MARK: - Private Methods

    /// 从UserDefaults加载收藏
    private func loadFavorites() {
        if let data = userDefaults.data(forKey: favoritesKey),
           let ids = try? JSONDecoder().decode(Set<Int>.self, from: data) {
            favoriteIds = ids
            Logger.shared.info("加载收藏列表 - 数量: \(ids.count)")
        }
    }

    /// 保存收藏到UserDefaults
    private func saveFavorites() {
        if let data = try? JSONEncoder().encode(favoriteIds) {
            userDefaults.set(data, forKey: favoritesKey)
        }
    }
}
