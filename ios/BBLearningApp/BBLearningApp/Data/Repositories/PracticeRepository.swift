//
//  PracticeRepository.swift
//  BBLearning
//
//  Created by Claude Code on 2025-10-13.
//

import Foundation
import Combine

final class PracticeRepository: PracticeRepositoryProtocol {
    private let apiClient: APIClient

    init(apiClient: APIClient = .shared) {
        self.apiClient = apiClient
    }

    func generateQuestions(knowledgePointIds: [Int], count: Int, difficulty: Question.Difficulty?) -> AnyPublisher<[Question], APIError> {
        let endpoint = PracticeEndpoint.generateQuestions(
            knowledgePointIds: knowledgePointIds,
            difficulty: difficulty?.rawValue ?? "medium",
            count: count
        )
        return apiClient.request(endpoint, type: [QuestionDTO].self)
            .map { $0.map { $0.toDomain() } }
            .eraseToAnyPublisher()
    }

    func getQuestion(id: Int) -> AnyPublisher<Question, APIError> {
        let endpoint = PracticeEndpoint.questionDetail(id: id)
        return apiClient.request(endpoint, type: QuestionDTO.self)
            .map { $0.toDomain() }
            .eraseToAnyPublisher()
    }

    func submitAnswer(questionId: Int, answer: String, timeSpent: Int) -> AnyPublisher<PracticeRecord, APIError> {
        let endpoint = PracticeEndpoint.submitAnswer(
            questionId: questionId,
            userAnswer: answer,
            timeSpent: timeSpent
        )
        return apiClient.request(endpoint, type: PracticeRecordDTO.self)
            .map { $0.toDomain() }
            .eraseToAnyPublisher()
    }

    func getPracticeHistory(page: Int, pageSize: Int, knowledgePointId: Int?) -> AnyPublisher<PagedResponse<PracticeRecord>, APIError> {
        let endpoint = PracticeEndpoint.history(page: page, pageSize: pageSize, knowledgePointId: knowledgePointId)
        return apiClient.request(endpoint, type: PagedResponse<PracticeRecordDTO>.self)
            .tryMap { pagedDTO in
                PagedResponse(
                    items: pagedDTO.items.map { $0.toDomain() },
                    total: pagedDTO.total,
                    page: pagedDTO.page,
                    pageSize: pagedDTO.pageSize,
                    hasMore: pagedDTO.hasMore
                )
            }
            .mapError { $0 as? APIError ?? .unknown }
            .eraseToAnyPublisher()
    }

    func getPracticeRecord(id: Int) -> AnyPublisher<PracticeRecord, APIError> {
        let endpoint = PracticeEndpoint.recordDetail(id: id)
        return apiClient.request(endpoint, type: PracticeRecordDTO.self)
            .map { $0.toDomain() }
            .eraseToAnyPublisher()
    }

    func createPracticeSession(knowledgePointId: Int?, questionCount: Int) -> AnyPublisher<PracticeSession, APIError> {
        guard let knowledgePointId = knowledgePointId else {
            return Fail(error: APIError.badRequest("Knowledge point ID is required"))
                .eraseToAnyPublisher()
        }
        let endpoint = PracticeEndpoint.createSession(knowledgePointId: knowledgePointId, count: questionCount)
        return apiClient.request(endpoint, type: PracticeSessionDTO.self)
            .map { $0.toDomain() }
            .eraseToAnyPublisher()
    }

    func completePracticeSession(sessionId: Int) -> AnyPublisher<PracticeSession, APIError> {
        let endpoint = PracticeEndpoint.completeSession(id: sessionId)
        return apiClient.request(endpoint, type: PracticeSessionDTO.self)
            .map { $0.toDomain() }
            .eraseToAnyPublisher()
    }

    func getCurrentSession() -> AnyPublisher<PracticeSession?, APIError> {
        let endpoint = PracticeEndpoint.currentSession
        return apiClient.request(endpoint, type: PracticeSessionDTO?.self)
            .map { $0?.toDomain() }
            .eraseToAnyPublisher()
    }
}
