//
//  AuthRepositoryProtocol.swift
//  BBLearning
//
//  Created by Claude Code on 2025-10-13.
//

import Foundation
import Combine

/// 认证仓储协议
protocol AuthRepositoryProtocol {
    /// 用户注册
    /// - Parameters:
    ///   - username: 用户名
    ///   - password: 密码
    ///   - nickname: 昵称
    ///   - grade: 年级
    /// - Returns: 用户对象
    func register(username: String, password: String, nickname: String, grade: Int) -> AnyPublisher<User, APIError>

    /// 用户登录
    /// - Parameters:
    ///   - username: 用户名
    ///   - password: 密码
    /// - Returns: 登录响应（包含token和用户信息）
    func login(username: String, password: String) -> AnyPublisher<LoginResponse, APIError>

    /// 刷新Token
    /// - Parameter refreshToken: 刷新令牌
    /// - Returns: 新的访问令牌
    func refreshToken(_ refreshToken: String) -> AnyPublisher<TokenResponse, APIError>

    /// 用户登出
    /// - Returns: 成功标识
    func logout() -> AnyPublisher<Void, APIError>

    /// 获取当前用户信息
    /// - Returns: 用户对象
    func getCurrentUser() -> AnyPublisher<User, APIError>

    /// 更新用户信息
    /// - Parameter user: 用户对象
    /// - Returns: 更新后的用户对象
    func updateUser(_ user: User) -> AnyPublisher<User, APIError>

    /// 修改密码
    /// - Parameters:
    ///   - oldPassword: 旧密码
    ///   - newPassword: 新密码
    /// - Returns: 成功标识
    func changePassword(oldPassword: String, newPassword: String) -> AnyPublisher<Void, APIError>

    /// 检查用户名是否可用
    /// - Parameter username: 用户名
    /// - Returns: 是否可用
    func checkUsernameAvailability(_ username: String) -> AnyPublisher<Bool, APIError>
}

// MARK: - Response Models

/// 登录响应
struct LoginResponse: Codable {
    let accessToken: String
    let refreshToken: String
    let user: User

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case user
    }
}

/// Token响应
struct TokenResponse: Codable {
    let accessToken: String
    let refreshToken: String?

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
    }
}
