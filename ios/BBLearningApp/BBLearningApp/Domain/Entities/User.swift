//
//  User.swift
//  BBLearning
//
//  Created by Claude Code on 2025-10-13.
//

import Foundation

/// 用户实体
struct User: Identifiable, Codable, Equatable {
    let id: Int
    var username: String
    var nickname: String
    var grade: Int
    var avatar: String?
    var phone: String?
    var email: String?
    var gender: Gender?
    var school: String?
    var experience: Int
    let createdAt: Date
    var updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case username
        case nickname
        case grade
        case avatar
        case phone
        case email
        case gender
        case school
        case experience
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    // MARK: - Gender

    enum Gender: String, Codable, CaseIterable {
        case male = "male"
        case female = "female"
        case other = "other"

        var displayName: String {
            switch self {
            case .male: return "男"
            case .female: return "女"
            case .other: return "其他"
            }
        }
    }
}

// MARK: - User Extensions

extension User {
    /// 显示名称
    var displayName: String {
        return nickname.isEmpty ? username : nickname
    }

    /// 年级显示文本
    var gradeText: String {
        return "\(grade)年级"
    }

    /// 是否有头像
    var hasAvatar: Bool {
        return avatar != nil && !avatar!.isEmpty
    }

    /// 头像URL
    var avatarURL: URL? {
        guard let avatar = avatar else { return nil }
        return URL(string: avatar)
    }

    /// 当前等级
    var level: Int {
        return LevelSystem.levelForExperience(experience)
    }

    /// 等级信息
    var levelInfo: LevelInfo {
        return LevelInfo(totalExperience: experience)
    }

    /// 等级进度 (0.0-1.0)
    func levelProgress() -> Double {
        return LevelSystem.progressForLevel(experience, level: level)
    }
}

// MARK: - Mock Data

#if DEBUG
extension User {
    static let mock = User(
        id: 1,
        username: "testuser",
        nickname: "测试用户",
        grade: 7,
        avatar: nil,
        phone: "13800138000",
        email: "test@example.com",
        createdAt: Date(),
        updatedAt: Date()
    )

    static let mockList: [User] = [
        User(id: 1, username: "user1", nickname: "张三", grade: 7, avatar: nil, phone: nil, email: nil, createdAt: Date(), updatedAt: Date()),
        User(id: 2, username: "user2", nickname: "李四", grade: 8, avatar: nil, phone: nil, email: nil, createdAt: Date(), updatedAt: Date()),
        User(id: 3, username: "user3", nickname: "王五", grade: 9, avatar: nil, phone: nil, email: nil, createdAt: Date(), updatedAt: Date())
    ]
}
#endif
