//
//  WrongQuestionRepository.swift
//  BBLearning
//
//  Created by Claude Code on 2025-10-13.
//

import Foundation
import Combine

final class WrongQuestionRepository: WrongQuestionRepositoryProtocol {
    private let apiClient: APIClient

    init(apiClient: APIClient = .shared) {
        self.apiClient = apiClient
    }

    func getWrongQuestions(page: Int, pageSize: Int, status: WrongQuestion.Status?, knowledgePointId: Int?) -> AnyPublisher<PagedResponse<WrongQuestion>, APIError> {
        let endpoint = PracticeEndpoint.wrongQuestions(page: page, pageSize: pageSize, status: status?.rawValue, knowledgePointId: knowledgePointId)
        return apiClient.request(endpoint, type: PagedResponse<WrongQuestionDTO>.self)
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

    func getWrongQuestion(id: Int) -> AnyPublisher<WrongQuestion, APIError> {
        let endpoint = PracticeEndpoint.wrongQuestionDetail(id: id)
        return apiClient.request(endpoint, type: WrongQuestionDTO.self)
            .map { $0.toDomain() }
            .eraseToAnyPublisher()
    }

    func addWrongQuestion(practiceRecordId: Int) -> AnyPublisher<WrongQuestion, APIError> {
        let endpoint = PracticeEndpoint.addWrongQuestion(recordId: practiceRecordId)
        return apiClient.request(endpoint, type: WrongQuestionDTO.self)
            .map { $0.toDomain() }
            .eraseToAnyPublisher()
    }

    func deleteWrongQuestion(id: Int) -> AnyPublisher<Void, APIError> {
        let endpoint = PracticeEndpoint.deleteWrongQuestion(id: id)
        return apiClient.request(endpoint, type: EmptyResponse.self)
            .map { _ in () }
            .eraseToAnyPublisher()
    }

    func updateStatus(id: Int, status: WrongQuestion.Status) -> AnyPublisher<WrongQuestion, APIError> {
        let endpoint = PracticeEndpoint.updateWrongQuestionStatus(id: id, status: status.rawValue)
        return apiClient.request(endpoint, type: WrongQuestionDTO.self)
            .map { $0.toDomain() }
            .eraseToAnyPublisher()
    }

    func recordRetry(id: Int, isCorrect: Bool) -> AnyPublisher<WrongQuestion, APIError> {
        let endpoint = PracticeEndpoint.retryWrongQuestion(id: id, isCorrect: isCorrect)
        return apiClient.request(endpoint, type: WrongQuestionDTO.self)
            .map { $0.toDomain() }
            .eraseToAnyPublisher()
    }

    func markAsMastered(id: Int) -> AnyPublisher<Void, APIError> {
        let endpoint = PracticeEndpoint.markWrongQuestionMastered(id: id)
        return apiClient.request(endpoint, type: EmptyResponse.self)
            .map { _ in () }
            .eraseToAnyPublisher()
    }

    func getQuestionsNeedReview(limit: Int) -> AnyPublisher<[WrongQuestion], APIError> {
        let endpoint = PracticeEndpoint.wrongQuestionsNeedReview(limit: limit)
        return apiClient.request(endpoint, type: [WrongQuestionDTO].self)
            .map { $0.map { $0.toDomain() } }
            .eraseToAnyPublisher()
    }

    func getStatistics() -> AnyPublisher<WrongQuestionStatistics, APIError> {
        let endpoint = PracticeEndpoint.wrongQuestionStats
        return apiClient.request(endpoint, type: WrongQuestionStatistics.self)
    }

    func batchMarkAsMastered(ids: [Int]) -> AnyPublisher<Void, APIError> {
        let endpoint = PracticeEndpoint.batchMarkMastered(ids: ids)
        return apiClient.request(endpoint, type: EmptyResponse.self)
            .map { _ in () }
            .eraseToAnyPublisher()
    }

    func archiveOldQuestions(daysBefore: Int) -> AnyPublisher<Int, APIError> {
        let endpoint = PracticeEndpoint.archiveOldWrongQuestions(days: daysBefore)
        return apiClient.request(endpoint, type: ArchiveResponse.self)
            .map { $0.count }
            .eraseToAnyPublisher()
    }
}

// MARK: - DTOs

struct WrongQuestionDTO: Codable {
    let id: Int
    let userId: Int
    let practiceRecordId: Int
    let question: QuestionDTO?
    let practiceRecord: PracticeRecordDTO?
    let status: String
    let retryCount: Int
    let lastRetryTime: String?
    let mastered: Bool
    let createdAt: String
    let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case id, question, status, mastered
        case userId = "user_id"
        case practiceRecordId = "practice_record_id"
        case practiceRecord = "practice_record"
        case retryCount = "retry_count"
        case lastRetryTime = "last_retry_time"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    func toDomain() -> WrongQuestion {
        WrongQuestion(
            id: id,
            userId: userId,
            practiceRecordId: practiceRecordId,
            question: question?.toDomain(),
            practiceRecord: practiceRecord?.toDomain(),
            status: WrongQuestion.Status(rawValue: status) ?? .pending,
            retryCount: retryCount,
            lastRetryTime: lastRetryTime?.toDate(),
            mastered: mastered,
            createdAt: createdAt.toDate() ?? Date(),
            updatedAt: updatedAt.toDate() ?? Date()
        )
    }
}

struct ArchiveResponse: Codable {
    let count: Int
}

private extension String {
    func toDate() -> Date? { ISO8601DateFormatter().date(from: self) }
}
