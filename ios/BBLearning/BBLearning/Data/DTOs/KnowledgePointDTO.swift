//
//  KnowledgePointDTO.swift
//  BBLearning
//
//  Created by Claude Code on 2025-10-13.
//

import Foundation

/// 知识点DTO
struct KnowledgePointDTO: Codable {
    let id: Int
    let name: String
    let grade: Int
    let parentId: Int?
    let level: Int
    let sortOrder: Int
    let description: String?
    let difficulty: String
    let children: [KnowledgePointDTO]?
    let progress: LearningProgressDTO?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case grade
        case parentId = "parent_id"
        case level
        case sortOrder = "sort_order"
        case description
        case difficulty
        case children
        case progress
    }

    /// 转换为Domain模型
    func toDomain() -> KnowledgePoint {
        return KnowledgePoint(
            id: id,
            name: name,
            grade: grade,
            parentId: parentId,
            level: level,
            sortOrder: sortOrder,
            description: description,
            difficulty: KnowledgePoint.Difficulty(rawValue: difficulty) ?? .medium,
            children: children?.map { $0.toDomain() },
            progress: progress?.toDomain()
        )
    }
}

/// 学习进度DTO
struct LearningProgressDTO: Codable {
    let userId: Int
    let knowledgePointId: Int
    let masteryLevel: Double
    let practiceCount: Int
    let correctCount: Int
    let lastPracticeTime: String?
    let status: String

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case knowledgePointId = "knowledge_point_id"
        case masteryLevel = "mastery_level"
        case practiceCount = "practice_count"
        case correctCount = "correct_count"
        case lastPracticeTime = "last_practice_time"
        case status
    }

    /// 转换为Domain模型
    func toDomain() -> LearningProgress {
        return LearningProgress(
            userId: userId,
            knowledgePointId: knowledgePointId,
            masteryLevel: masteryLevel,
            practiceCount: practiceCount,
            correctCount: correctCount,
            lastPracticeTime: lastPracticeTime?.toDate(),
            status: LearningProgress.Status(rawValue: status) ?? .notStarted
        )
    }

    /// 从Domain模型创建
    static func from(_ progress: LearningProgress) -> LearningProgressDTO {
        return LearningProgressDTO(
            userId: progress.userId,
            knowledgePointId: progress.knowledgePointId,
            masteryLevel: progress.masteryLevel,
            practiceCount: progress.practiceCount,
            correctCount: progress.correctCount,
            lastPracticeTime: progress.lastPracticeTime?.toISO8601String(),
            status: progress.status.rawValue
        )
    }
}

/// 更新进度请求DTO
struct UpdateProgressRequestDTO: Codable {
    let masteryLevel: Double
    let practiceCount: Int
    let correctCount: Int
    let status: String

    enum CodingKeys: String, CodingKey {
        case masteryLevel = "mastery_level"
        case practiceCount = "practice_count"
        case correctCount = "correct_count"
        case status
    }

    /// 从Domain模型创建
    static func from(_ progress: LearningProgress) -> UpdateProgressRequestDTO {
        return UpdateProgressRequestDTO(
            masteryLevel: progress.masteryLevel,
            practiceCount: progress.practiceCount,
            correctCount: progress.correctCount,
            status: progress.status.rawValue
        )
    }
}

// MARK: - Extensions

private extension String {
    func toDate() -> Date? {
        let formatter = ISO8601DateFormatter()
        return formatter.date(from: self)
    }
}
