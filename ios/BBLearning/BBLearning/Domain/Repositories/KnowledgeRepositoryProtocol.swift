//
//  KnowledgeRepositoryProtocol.swift
//  BBLearning
//
//  Created by Claude Code on 2025-10-13.
//

import Foundation
import Combine

/// 知识点仓储协议
protocol KnowledgeRepositoryProtocol {
    /// 获取知识点树
    /// - Parameter grade: 年级
    /// - Returns: 知识点树（根节点列表）
    func getKnowledgeTree(grade: Int) -> AnyPublisher<[KnowledgePoint], APIError>

    /// 获取知识点详情
    /// - Parameter id: 知识点ID
    /// - Returns: 知识点详情
    func getKnowledgePoint(id: Int) -> AnyPublisher<KnowledgePoint, APIError>

    /// 获取子知识点
    /// - Parameter parentId: 父知识点ID
    /// - Returns: 子知识点列表
    func getChildren(parentId: Int) -> AnyPublisher<[KnowledgePoint], APIError>

    /// 更新学习进度
    /// - Parameters:
    ///   - knowledgePointId: 知识点ID
    ///   - progress: 学习进度
    /// - Returns: 更新后的学习进度
    func updateProgress(knowledgePointId: Int, progress: LearningProgress) -> AnyPublisher<LearningProgress, APIError>

    /// 获取用户在某知识点的学习进度
    /// - Parameter knowledgePointId: 知识点ID
    /// - Returns: 学习进度
    func getProgress(knowledgePointId: Int) -> AnyPublisher<LearningProgress?, APIError>

    /// 搜索知识点
    /// - Parameters:
    ///   - keyword: 搜索关键词
    ///   - grade: 年级（可选）
    /// - Returns: 匹配的知识点列表
    func searchKnowledgePoints(keyword: String, grade: Int?) -> AnyPublisher<[KnowledgePoint], APIError>

    /// 获取推荐的知识点
    /// - Parameter limit: 返回数量限制
    /// - Returns: 推荐的知识点列表
    func getRecommendedKnowledgePoints(limit: Int) -> AnyPublisher<[KnowledgePoint], APIError>

    /// 获取薄弱知识点
    /// - Parameter limit: 返回数量限制
    /// - Returns: 薄弱知识点列表（按掌握度排序）
    func getWeakKnowledgePoints(limit: Int) -> AnyPublisher<[KnowledgePoint], APIError>

    /// 标记知识点为已掌握
    /// - Parameter knowledgePointId: 知识点ID
    /// - Returns: 成功标识
    func markAsMastered(knowledgePointId: Int) -> AnyPublisher<Void, APIError>
}
