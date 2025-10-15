//
//  KnowledgeRepository.swift
//  BBLearning
//
//  Created by Claude Code on 2025-10-13.
//

import Foundation
import Combine

final class KnowledgeRepository: KnowledgeRepositoryProtocol {
    private let apiClient: APIClient
    private let cacheManager: KnowledgeCacheManager

    init(apiClient: APIClient = .shared,
         cacheManager: KnowledgeCacheManager = .shared) {
        self.apiClient = apiClient
        self.cacheManager = cacheManager
    }

    func getKnowledgeTree(grade: Int) -> AnyPublisher<[KnowledgePoint], APIError> {
        // 先尝试从缓存加载
        if let cachedTree = cacheManager.getCachedKnowledgeTree(forGrade: grade) {
            return Just(cachedTree)
                .setFailureType(to: APIError.self)
                .eraseToAnyPublisher()
        }

        // 缓存未命中，从API获取
        let endpoint = KnowledgeEndpoint.tree(grade: grade)
        return apiClient.request(endpoint, type: [KnowledgePointDTO].self)
            .map { [weak self] dtos in
                let points = dtos.map { $0.toDomain() }
                // 缓存结果
                self?.cacheManager.cacheKnowledgeTree(points, forGrade: grade)
                return points
            }
            .eraseToAnyPublisher()
    }

    func getKnowledgePoint(id: Int) -> AnyPublisher<KnowledgePoint, APIError> {
        // 先尝试从缓存加载
        if let cachedPoint = cacheManager.getCachedKnowledgePoint(id: id) {
            return Just(cachedPoint)
                .setFailureType(to: APIError.self)
                .eraseToAnyPublisher()
        }

        // 缓存未命中，从API获取
        let endpoint = KnowledgeEndpoint.detail(id: id)
        return apiClient.request(endpoint, type: KnowledgePointDTO.self)
            .map { [weak self] dto in
                let point = dto.toDomain()
                // 缓存结果
                self?.cacheManager.cacheKnowledgePoint(point)
                return point
            }
            .eraseToAnyPublisher()
    }

    func getChildren(parentId: Int) -> AnyPublisher<[KnowledgePoint], APIError> {
        let endpoint = KnowledgeEndpoint.children(parentId: parentId)
        return apiClient.request(endpoint, type: [KnowledgePointDTO].self)
            .map { $0.map { $0.toDomain() } }
            .eraseToAnyPublisher()
    }

    func updateProgress(knowledgePointId: Int, progress: LearningProgress) -> AnyPublisher<LearningProgress, APIError> {
        let endpoint = KnowledgeEndpoint.updateProgress(id: knowledgePointId, progress: progress.masteryLevel)
        return apiClient.request(endpoint, type: LearningProgressDTO.self)
            .map { $0.toDomain() }
            .eraseToAnyPublisher()
    }

    func getProgress(knowledgePointId: Int) -> AnyPublisher<LearningProgress?, APIError> {
        let endpoint = KnowledgeEndpoint.progress(id: knowledgePointId)
        return apiClient.request(endpoint, type: LearningProgressDTO?.self)
            .map { $0?.toDomain() }
            .eraseToAnyPublisher()
    }

    func searchKnowledgePoints(keyword: String, grade: Int?) -> AnyPublisher<[KnowledgePoint], APIError> {
        let endpoint = KnowledgeEndpoint.search(keyword: keyword, grade: grade)
        return apiClient.request(endpoint, type: [KnowledgePointDTO].self)
            .map { $0.map { $0.toDomain() } }
            .eraseToAnyPublisher()
    }

    func getRecommendedKnowledgePoints(limit: Int) -> AnyPublisher<[KnowledgePoint], APIError> {
        let endpoint = KnowledgeEndpoint.recommended(limit: limit)
        return apiClient.request(endpoint, type: [KnowledgePointDTO].self)
            .map { $0.map { $0.toDomain() } }
            .eraseToAnyPublisher()
    }

    func getWeakKnowledgePoints(limit: Int) -> AnyPublisher<[KnowledgePoint], APIError> {
        let endpoint = KnowledgeEndpoint.weak(limit: limit)
        return apiClient.request(endpoint, type: [KnowledgePointDTO].self)
            .map { $0.map { $0.toDomain() } }
            .eraseToAnyPublisher()
    }

    func markAsMastered(knowledgePointId: Int) -> AnyPublisher<Void, APIError> {
        let endpoint = KnowledgeEndpoint.markMastered(id: knowledgePointId)
        return apiClient.request(endpoint, type: EmptyResponse.self)
            .map { _ in () }
            .eraseToAnyPublisher()
    }
}
