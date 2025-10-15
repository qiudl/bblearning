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
        case createdAt = "created_at"
        case updatedAt = "updated_at"
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
