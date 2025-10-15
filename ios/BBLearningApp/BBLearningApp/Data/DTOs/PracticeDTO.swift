//
//  PracticeDTO.swift
//  BBLearning
//
//  Created by Claude Code on 2025-10-13.
//

import Foundation

struct PracticeRecordDTO: Codable {
    let id: Int
    let userId: Int
    let questionId: Int
    let question: QuestionDTO?
    let userAnswer: String
    let isCorrect: Bool
    let score: Int
    let timeSpent: Int
    let aiGrade: AIGradeDTO?
    let createdAt: String

    enum CodingKeys: String, CodingKey {
        case id, question, score
        case userId = "user_id"
        case questionId = "question_id"
        case userAnswer = "user_answer"
        case isCorrect = "is_correct"
        case timeSpent = "time_spent"
        case aiGrade = "ai_grade"
        case createdAt = "created_at"
    }

    func toDomain() -> PracticeRecord {
        return PracticeRecord(
            id: id,
            userId: userId,
            questionId: questionId,
            question: question?.toDomain(),
            userAnswer: userAnswer,
            isCorrect: isCorrect,
            score: score,
            timeSpent: timeSpent,
            aiGrade: aiGrade?.toDomain(),
            createdAt: createdAt.toDate() ?? Date()
        )
    }
}

struct AIGradeDTO: Codable {
    let score: Int
    let feedback: String
    let highlights: [String]?
    let mistakes: [String]?
    let suggestions: [String]?
    let similarQuestions: [Int]?

    enum CodingKeys: String, CodingKey {
        case score, feedback, highlights, mistakes, suggestions
        case similarQuestions = "similar_questions"
    }

    func toDomain() -> AIGrade {
        return AIGrade(score: score, feedback: feedback, highlights: highlights, mistakes: mistakes, suggestions: suggestions, similarQuestions: similarQuestions)
    }
}

struct SubmitAnswerRequestDTO: Codable {
    let questionId: Int
    let answer: String
    let timeSpent: Int

    enum CodingKeys: String, CodingKey {
        case answer
        case questionId = "question_id"
        case timeSpent = "time_spent"
    }
}

struct PracticeSessionDTO: Codable {
    let id: Int
    let userId: Int
    let knowledgePointId: Int?
    let records: [PracticeRecordDTO]
    let totalScore: Int
    let totalTime: Int
    let createdAt: String
    let completedAt: String?

    enum CodingKeys: String, CodingKey {
        case id, records
        case userId = "user_id"
        case knowledgePointId = "knowledge_point_id"
        case totalScore = "total_score"
        case totalTime = "total_time"
        case createdAt = "created_at"
        case completedAt = "completed_at"
    }

    func toDomain() -> PracticeSession {
        return PracticeSession(
            id: id,
            userId: userId,
            knowledgePointId: knowledgePointId,
            records: records.map { $0.toDomain() },
            totalScore: totalScore,
            totalTime: totalTime,
            createdAt: createdAt.toDate() ?? Date(),
            completedAt: completedAt?.toDate()
        )
    }
}

private extension String {
    func toDate() -> Date? { ISO8601DateFormatter().date(from: self) }
}
