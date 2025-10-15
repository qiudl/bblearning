//
//  RecommendedPractice.swift
//  BBLearning
//
//  Created by Claude Code on 2025-10-15.
//

import Foundation
import SwiftUI

/// AI推荐练习题目
struct RecommendedPractice: Identifiable, Codable {
    let id: Int
    let knowledgePointId: Int
    let title: String
    let recommendedCount: Int
    let priority: Int
    let reason: String

    enum CodingKeys: String, CodingKey {
        case id
        case knowledgePointId = "knowledge_point_id"
        case title
        case recommendedCount = "recommended_count"
        case priority
        case reason
    }

    /// 根据优先级返回对应颜色
    var color: Color {
        switch priority {
        case 1: return .red        // 紧急，需要加强
        case 2: return .orange     // 重要
        case 3: return .blue       // 正常
        default: return .green     // 巩固
        }
    }

    /// 优先级文本
    var priorityText: String {
        switch priority {
        case 1: return "紧急"
        case 2: return "重要"
        case 3: return "推荐"
        default: return "巩固"
        }
    }
}

// MARK: - Mock Data

extension RecommendedPractice {
    static var mockData: [RecommendedPractice] {
        [
            RecommendedPractice(
                id: 1,
                knowledgePointId: 101,
                title: "有理数运算",
                recommendedCount: 10,
                priority: 1,
                reason: "错误率较高，需要加强练习"
            ),
            RecommendedPractice(
                id: 2,
                knowledgePointId: 102,
                title: "代数式化简",
                recommendedCount: 15,
                priority: 2,
                reason: "掌握度中等，建议巩固"
            ),
            RecommendedPractice(
                id: 3,
                knowledgePointId: 103,
                title: "一元一次方程",
                recommendedCount: 8,
                priority: 3,
                reason: "新知识点，建议练习"
            )
        ]
    }
}
