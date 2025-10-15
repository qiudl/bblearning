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

    init(apiClient: APIClient = .shared) {
        self.apiClient = apiClient
    }

    func getKnowledgeTree(grade: Int) -> AnyPublisher<[KnowledgePoint], APIError> {
        let endpoint = KnowledgeEndpoint.tree(grade: grade)
        return apiClient.request(endpoint, type: [KnowledgePointDTO].self)
            .map { $0.map { $0.toDomain() } }
            .eraseToAnyPublisher()
    }

    func getKnowledgePoint(id: Int) -> AnyPublisher<KnowledgePoint, APIError> {
        let endpoint = KnowledgeEndpoint.detail(id: id)
        return apiClient.request(endpoint, type: KnowledgePointDTO.self)
            .map { $0.toDomain() }
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
