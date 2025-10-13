//
//  AIRepository.swift
//  BBLearning
//
//  Created by Claude Code on 2025-10-13.
//

import Foundation
import Combine

final class AIRepository: AIRepositoryProtocol {
    private let apiClient: APIClient

    init(apiClient: APIClient = .shared) {
        self.apiClient = apiClient
    }

    func chat(conversationId: Int?, message: String) -> AnyPublisher<AIMessage, APIError> {
        let endpoint = AIEndpoint.chat(conversationId: conversationId, message: message)
        return apiClient.request(endpoint, type: AIMessageDTO.self)
            .map { $0.toDomain() }
            .eraseToAnyPublisher()
    }

    func recognizeQuestion(imageData: Data) -> AnyPublisher<QuestionRecognitionResult, APIError> {
        let endpoint = AIEndpoint.recognizeQuestion
        return apiClient.upload(endpoint, data: imageData, type: QuestionRecognitionResult.self)
    }

    func getChatHistory(conversationId: Int, page: Int, pageSize: Int) -> AnyPublisher<PagedResponse<AIMessage>, APIError> {
        let endpoint = AIEndpoint.chatHistory(conversationId: conversationId, page: page, pageSize: pageSize)
        return apiClient.request(endpoint, type: PagedResponse<AIMessageDTO>.self)
            .map { pagedDTO in
                PagedResponse(
                    data: pagedDTO.data.map { $0.toDomain() },
                    total: pagedDTO.total,
                    page: pagedDTO.page,
                    pageSize: pagedDTO.pageSize
                )
            }
            .eraseToAnyPublisher()
    }

    func getConversations(page: Int, pageSize: Int) -> AnyPublisher<PagedResponse<ChatConversation>, APIError> {
        let endpoint = AIEndpoint.conversations(page: page, pageSize: pageSize)
        return apiClient.request(endpoint, type: PagedResponse<ChatConversationDTO>.self)
            .map { pagedDTO in
                PagedResponse(
                    data: pagedDTO.data.map { $0.toDomain() },
                    total: pagedDTO.total,
                    page: pagedDTO.page,
                    pageSize: pagedDTO.pageSize
                )
            }
            .eraseToAnyPublisher()
    }

    func createConversation(title: String) -> AnyPublisher<ChatConversation, APIError> {
        let endpoint = AIEndpoint.createConversation(title: title)
        return apiClient.request(endpoint, type: ChatConversationDTO.self)
            .map { $0.toDomain() }
            .eraseToAnyPublisher()
    }

    func deleteConversation(conversationId: Int) -> AnyPublisher<Void, APIError> {
        let endpoint = AIEndpoint.deleteConversation(id: conversationId)
        return apiClient.request(endpoint, type: EmptyResponse.self)
            .map { _ in () }
            .eraseToAnyPublisher()
    }

    func getDiagnosis(knowledgePointId: Int?) -> AnyPublisher<DiagnosisReport, APIError> {
        let endpoint = AIEndpoint.diagnosis(knowledgePointId: knowledgePointId)
        return apiClient.request(endpoint, type: DiagnosisReport.self)
    }

    func getRecommendations() -> AnyPublisher<Recommendations, APIError> {
        let endpoint = AIEndpoint.recommendations
        return apiClient.request(endpoint, type: RecommendationsDTO.self)
            .map { $0.toDomain() }
            .eraseToAnyPublisher()
    }

    func generateCustomQuestion(knowledgePointId: Int, difficulty: Question.Difficulty, requirements: String?) -> AnyPublisher<Question, APIError> {
        let endpoint = AIEndpoint.generateQuestion(knowledgePointId: knowledgePointId, difficulty: difficulty.rawValue, requirements: requirements)
        return apiClient.request(endpoint, type: QuestionDTO.self)
            .map { $0.toDomain() }
            .eraseToAnyPublisher()
    }

    func gradeAnswer(questionId: Int, userAnswer: String) -> AnyPublisher<AIGrade, APIError> {
        let endpoint = AIEndpoint.gradeAnswer(questionId: questionId, answer: userAnswer)
        return apiClient.request(endpoint, type: AIGradeDTO.self)
            .map { $0.toDomain() }
            .eraseToAnyPublisher()
    }
}

// MARK: - DTOs

struct AIMessageDTO: Codable {
    let id: Int
    let conversationId: Int
    let role: String
    let content: String
    let messageType: String
    let metadata: MessageMetadataDTO?
    let createdAt: String

    enum CodingKeys: String, CodingKey {
        case id, role, content, metadata
        case conversationId = "conversation_id"
        case messageType = "message_type"
        case createdAt = "created_at"
    }

    func toDomain() -> AIMessage {
        AIMessage(
            id: id,
            conversationId: conversationId,
            role: AIMessage.MessageRole(rawValue: role) ?? .user,
            content: content,
            messageType: AIMessage.MessageType(rawValue: messageType) ?? .text,
            metadata: metadata?.toDomain(),
            createdAt: createdAt.toDate() ?? Date()
        )
    }
}

struct MessageMetadataDTO: Codable {
    let imageUrl: String?
    let questionId: Int?
    let knowledgePointIds: [Int]?
    let relatedQuestions: [Int]?
    let confidence: Double?
    let processingTime: Double?

    enum CodingKeys: String, CodingKey {
        case confidence
        case imageUrl = "image_url"
        case questionId = "question_id"
        case knowledgePointIds = "knowledge_point_ids"
        case relatedQuestions = "related_questions"
        case processingTime = "processing_time"
    }

    func toDomain() -> MessageMetadata {
        MessageMetadata(imageUrl: imageUrl, questionId: questionId, knowledgePointIds: knowledgePointIds, relatedQuestions: relatedQuestions, confidence: confidence, processingTime: processingTime)
    }
}

struct ChatConversationDTO: Codable {
    let id: Int
    let userId: Int
    let title: String
    let messages: [AIMessageDTO]?
    let createdAt: String
    let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case id, title, messages
        case userId = "user_id"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    func toDomain() -> ChatConversation {
        ChatConversation(
            id: id,
            userId: userId,
            title: title,
            messages: messages?.map { $0.toDomain() },
            context: nil,
            createdAt: createdAt.toDate() ?? Date(),
            updatedAt: updatedAt.toDate() ?? Date()
        )
    }
}

struct RecommendationsDTO: Codable {
    let knowledgePoints: [KnowledgePointDTO]
    let questions: [QuestionDTO]
    let topics: [String]

    enum CodingKeys: String, CodingKey {
        case topics
        case knowledgePoints = "knowledge_points"
        case questions
    }

    func toDomain() -> Recommendations {
        Recommendations(
            knowledgePoints: knowledgePoints.map { $0.toDomain() },
            questions: questions.map { $0.toDomain() },
            topics: topics,
            studyPlan: nil
        )
    }
}

private extension String {
    func toDate() -> Date? { ISO8601DateFormatter().date(from: self) }
}
