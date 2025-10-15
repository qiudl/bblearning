//
//  QuestionDTO.swift
//  BBLearning
//
//  Created by Claude Code on 2025-10-13.
//

import Foundation

struct QuestionDTO: Codable {
    let id: Int
    let knowledgePointId: Int
    let type: String
    let difficulty: String
    let content: QuestionContentDTO
    let answer: AnswerDTO
    let analysis: String?
    let points: Int
    let createdAt: String
    let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case id, type, difficulty, content, answer, analysis, points
        case knowledgePointId = "knowledge_point_id"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    func toDomain() -> Question {
        return Question(
            id: id,
            knowledgePointId: knowledgePointId,
            type: Question.QuestionType(rawValue: type) ?? .choice,
            difficulty: Question.Difficulty(rawValue: difficulty) ?? .medium,
            content: content.toDomain(),
            answer: answer.toDomain(),
            analysis: analysis,
            points: points,
            createdAt: createdAt.toDate() ?? Date(),
            updatedAt: updatedAt.toDate() ?? Date()
        )
    }
}

struct QuestionContentDTO: Codable {
    let stem: String
    let options: [String]?
    let images: [String]?
    let blanks: Int?
    let tips: String?

    func toDomain() -> QuestionContent {
        return QuestionContent(stem: stem, options: options, images: images, blanks: blanks, tips: tips)
    }
}

struct AnswerDTO: Codable {
    let content: String
    let steps: [String]?
    let keyPoints: [String]?
    let commonMistakes: [String]?

    enum CodingKeys: String, CodingKey {
        case content, steps
        case keyPoints = "key_points"
        case commonMistakes = "common_mistakes"
    }

    func toDomain() -> Answer {
        return Answer(content: content, steps: steps, keyPoints: keyPoints, commonMistakes: commonMistakes)
    }
}

struct GenerateQuestionsRequestDTO: Codable {
    let knowledgePointIds: [Int]
    let count: Int
    let difficulty: String?

    enum CodingKeys: String, CodingKey {
        case count, difficulty
        case knowledgePointIds = "knowledge_point_ids"
    }
}

private extension String {
    func toDate() -> Date? {
        ISO8601DateFormatter().date(from: self)
    }
}
