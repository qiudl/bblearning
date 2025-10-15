//
//  RealmModels.swift
//  BBLearning
//
//  Created by Claude Code on 2025-10-13.
//

import Foundation
import RealmSwift

/// Realm用户模型
final class UserObject: Object {
    @Persisted(primaryKey: true) var id: Int
    @Persisted var username: String
    @Persisted var nickname: String
    @Persisted var grade: Int
    @Persisted var avatar: String?
    @Persisted var phone: String?
    @Persisted var email: String?
    @Persisted var createdAt: Date
    @Persisted var updatedAt: Date

    convenience init(from user: User) {
        self.init()
        self.id = user.id
        self.username = user.username
        self.nickname = user.nickname
        self.grade = user.grade
        self.avatar = user.avatar
        self.phone = user.phone
        self.email = user.email
        self.createdAt = user.createdAt
        self.updatedAt = user.updatedAt
    }

    func toDomain() -> User {
        User(id: id, username: username, nickname: nickname, grade: grade, avatar: avatar, phone: phone, email: email, createdAt: createdAt, updatedAt: updatedAt)
    }
}

/// Realm知识点模型
final class KnowledgePointObject: Object {
    @Persisted(primaryKey: true) var id: Int
    @Persisted var name: String
    @Persisted var grade: Int
    @Persisted var parentId: Int?
    @Persisted var level: Int
    @Persisted var sortOrder: Int
    @Persisted var desc: String?
    @Persisted var difficulty: String
    @Persisted var cachedAt: Date

    convenience init(from kp: KnowledgePoint) {
        self.init()
        self.id = kp.id
        self.name = kp.name
        self.grade = kp.grade
        self.parentId = kp.parentId
        self.level = kp.level
        self.sortOrder = kp.sortOrder
        self.desc = kp.description
        self.difficulty = kp.difficulty.rawValue
        self.cachedAt = Date()
    }

    func toDomain() -> KnowledgePoint {
        KnowledgePoint(id: id, name: name, grade: grade, parentId: parentId, level: level, sortOrder: sortOrder, description: desc, difficulty: KnowledgePoint.Difficulty(rawValue: difficulty) ?? .medium, children: nil, progress: nil)
    }
}

/// Realm题目模型（缓存）
final class QuestionObject: Object {
    @Persisted(primaryKey: true) var id: Int
    @Persisted var knowledgePointId: Int
    @Persisted var type: String
    @Persisted var difficulty: String
    @Persisted var contentJSON: String // JSON string
    @Persisted var answerJSON: String // JSON string
    @Persisted var analysis: String?
    @Persisted var points: Int
    @Persisted var cachedAt: Date

    convenience init(from question: Question) {
        self.init()
        self.id = question.id
        self.knowledgePointId = question.knowledgePointId
        self.type = question.type.rawValue
        self.difficulty = question.difficulty.rawValue
        self.contentJSON = try! JSONEncoder().encode(question.content).base64EncodedString()
        self.answerJSON = try! JSONEncoder().encode(question.answer).base64EncodedString()
        self.analysis = question.analysis
        self.points = question.points
        self.cachedAt = Date()
    }

    func toDomain() -> Question? {
        guard let contentData = Data(base64Encoded: contentJSON),
              let answerData = Data(base64Encoded: answerJSON),
              let content = try? JSONDecoder().decode(QuestionContent.self, from: contentData),
              let answer = try? JSONDecoder().decode(Answer.self, from: answerData) else {
            return nil
        }

        return Question(
            id: id,
            knowledgePointId: knowledgePointId,
            type: Question.QuestionType(rawValue: type) ?? .choice,
            difficulty: Question.Difficulty(rawValue: difficulty) ?? .medium,
            content: content,
            answer: answer,
            analysis: analysis,
            points: points,
            createdAt: Date(),
            updatedAt: Date()
        )
    }
}

/// Realm练习记录模型（离线支持）
final class PracticeRecordObject: Object {
    @Persisted(primaryKey: true) var id: Int
    @Persisted var userId: Int
    @Persisted var questionId: Int
    @Persisted var userAnswer: String
    @Persisted var isCorrect: Bool
    @Persisted var score: Int
    @Persisted var timeSpent: Int
    @Persisted var synced: Bool = false
    @Persisted var createdAt: Date

    convenience init(from record: PracticeRecord) {
        self.init()
        self.id = record.id
        self.userId = record.userId
        self.questionId = record.questionId
        self.userAnswer = record.userAnswer
        self.isCorrect = record.isCorrect
        self.score = record.score
        self.timeSpent = record.timeSpent
        self.createdAt = record.createdAt
    }
}

/// Realm错题模型
final class WrongQuestionObject: Object {
    @Persisted(primaryKey: true) var id: Int
    @Persisted var userId: Int
    @Persisted var practiceRecordId: Int
    @Persisted var questionId: Int
    @Persisted var status: String
    @Persisted var retryCount: Int
    @Persisted var lastRetryTime: Date?
    @Persisted var mastered: Bool
    @Persisted var createdAt: Date

    convenience init(from wq: WrongQuestion) {
        self.init()
        self.id = wq.id
        self.userId = wq.userId
        self.practiceRecordId = wq.practiceRecordId
        self.questionId = wq.question?.id ?? 0
        self.status = wq.status.rawValue
        self.retryCount = wq.retryCount
        self.lastRetryTime = wq.lastRetryTime
        self.mastered = wq.mastered
        self.createdAt = wq.createdAt
    }
}

/// Realm聊天消息模型（离线缓存）
final class AIMessageObject: Object {
    @Persisted(primaryKey: true) var id: Int
    @Persisted var conversationId: Int
    @Persisted var role: String
    @Persisted var content: String
    @Persisted var messageType: String
    @Persisted var createdAt: Date

    convenience init(from message: AIMessage) {
        self.init()
        self.id = message.id
        self.conversationId = message.conversationId
        self.role = message.role.rawValue
        self.content = message.content
        self.messageType = message.messageType.rawValue
        self.createdAt = message.createdAt
    }

    func toDomain() -> AIMessage {
        AIMessage(
            id: id,
            conversationId: conversationId,
            role: AIMessage.MessageRole(rawValue: role) ?? .user,
            content: content,
            messageType: AIMessage.MessageType(rawValue: messageType) ?? .text,
            metadata: nil,
            createdAt: createdAt
        )
    }
}
