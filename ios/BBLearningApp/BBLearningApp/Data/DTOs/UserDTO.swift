//
//  UserDTO.swift
//  BBLearning
//
//  Created by Claude Code on 2025-10-13.
//

import Foundation

/// 用户DTO（Data Transfer Object）
struct UserDTO: Codable {
    let id: Int
    let username: String
    let nickname: String
    let grade: Int
    let avatar: String?
    let phone: String?
    let email: String?
    let createdAt: String
    let updatedAt: String

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

    /// 转换为Domain模型
    func toDomain() -> User {
        return User(
            id: id,
            username: username,
            nickname: nickname,
            grade: grade,
            avatar: avatar,
            phone: phone,
            email: email,
            createdAt: createdAt.toDate() ?? Date(),
            updatedAt: updatedAt.toDate() ?? Date()
        )
    }
}

/// 用户更新请求DTO
struct UpdateUserRequestDTO: Codable {
    let nickname: String?
    let grade: Int?
    let avatar: String?
    let phone: String?
    let email: String?

    enum CodingKeys: String, CodingKey {
        case nickname
        case grade
        case avatar
        case phone
        case email
    }

    /// 从Domain模型创建
    static func from(_ user: User) -> UpdateUserRequestDTO {
        return UpdateUserRequestDTO(
            nickname: user.nickname,
            grade: user.grade,
            avatar: user.avatar,
            phone: user.phone,
            email: user.email
        )
    }
}

/// 修改密码请求DTO
struct ChangePasswordRequestDTO: Codable {
    let oldPassword: String
    let newPassword: String

    enum CodingKeys: String, CodingKey {
        case oldPassword = "old_password"
        case newPassword = "new_password"
    }
}

// MARK: - Extensions

private extension String {
    func toDate() -> Date? {
        let formatter = ISO8601DateFormatter()
        return formatter.date(from: self)
    }
}
