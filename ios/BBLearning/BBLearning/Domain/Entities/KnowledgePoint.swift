//
//  KnowledgePoint.swift
//  BBLearning
//
//  Created by Claude Code on 2025-10-13.
//

import Foundation

/// 知识点实体
struct KnowledgePoint: Identifiable, Codable, Equatable {
    let id: Int
    let name: String
    let grade: Int
    let parentId: Int?
    let level: Int
    let sortOrder: Int
    var description: String?
    var difficulty: Difficulty
    var children: [KnowledgePoint]?
    var progress: LearningProgress?

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

    /// 难度级别
    enum Difficulty: String, Codable {
        case easy
        case medium
        case hard

        var displayText: String {
            switch self {
            case .easy: return "简单"
            case .medium: return "中等"
            case .hard: return "困难"
            }
        }
    }
}

// MARK: - Learning Progress

/// 学习进度
struct LearningProgress: Codable, Equatable {
    let userId: Int
    let knowledgePointId: Int
    var masteryLevel: Double // 0.0 - 1.0
    var practiceCount: Int
    var correctCount: Int
    var lastPracticeTime: Date?
    var status: Status

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case knowledgePointId = "knowledge_point_id"
        case masteryLevel = "mastery_level"
        case practiceCount = "practice_count"
        case correctCount = "correct_count"
        case lastPracticeTime = "last_practice_time"
        case status
    }

    /// 掌握状态
    enum Status: String, Codable {
        case notStarted = "not_started"
        case learning = "learning"
        case mastered = "mastered"

        var displayText: String {
            switch self {
            case .notStarted: return "未开始"
            case .learning: return "学习中"
            case .mastered: return "已掌握"
            }
        }
    }
}

// MARK: - Extensions

extension KnowledgePoint {
    /// 是否有子节点
    var hasChildren: Bool {
        return children != nil && !children!.isEmpty
    }

    /// 是否根节点
    var isRoot: Bool {
        return parentId == nil
    }

    /// 进度百分比
    var progressPercentage: Int {
        guard let progress = progress else { return 0 }
        return Int(progress.masteryLevel * 100)
    }

    /// 正确率
    var accuracyRate: Double {
        guard let progress = progress, progress.practiceCount > 0 else {
            return 0
        }
        return Double(progress.correctCount) / Double(progress.practiceCount)
    }
}

// MARK: - Mock Data

#if DEBUG
extension KnowledgePoint {
    static let mock = KnowledgePoint(
        id: 1,
        name: "有理数",
        grade: 7,
        parentId: nil,
        level: 1,
        sortOrder: 1,
        description: "有理数的概念和运算",
        difficulty: .medium,
        children: nil,
        progress: LearningProgress(
            userId: 1,
            knowledgePointId: 1,
            masteryLevel: 0.6,
            practiceCount: 20,
            correctCount: 15,
            lastPracticeTime: Date(),
            status: .learning
        )
    )

    static let mockTree: [KnowledgePoint] = [
        KnowledgePoint(
            id: 1,
            name: "有理数",
            grade: 7,
            parentId: nil,
            level: 1,
            sortOrder: 1,
            description: "有理数的概念和运算",
            difficulty: .medium,
            children: [
                KnowledgePoint(id: 11, name: "正数和负数", grade: 7, parentId: 1, level: 2, sortOrder: 1, description: nil, difficulty: .easy, children: nil, progress: nil),
                KnowledgePoint(id: 12, name: "有理数的加减", grade: 7, parentId: 1, level: 2, sortOrder: 2, description: nil, difficulty: .medium, children: nil, progress: nil)
            ],
            progress: nil
        ),
        KnowledgePoint(
            id: 2,
            name: "整式",
            grade: 7,
            parentId: nil,
            level: 1,
            sortOrder: 2,
            description: "整式的概念和运算",
            difficulty: .medium,
            children: [
                KnowledgePoint(id: 21, name: "单项式", grade: 7, parentId: 2, level: 2, sortOrder: 1, description: nil, difficulty: .easy, children: nil, progress: nil),
                KnowledgePoint(id: 22, name: "多项式", grade: 7, parentId: 2, level: 2, sortOrder: 2, description: nil, difficulty: .medium, children: nil, progress: nil)
            ],
            progress: nil
        )
    ]
}
#endif
