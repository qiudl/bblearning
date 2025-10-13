//
//  AuthRepository.swift
//  BBLearning
//
//  Created by Claude Code on 2025-10-13.
//

import Foundation
import Combine

final class AuthRepository: AuthRepositoryProtocol {
    private let apiClient: APIClient

    init(apiClient: APIClient = .shared) {
        self.apiClient = apiClient
    }

    func register(username: String, password: String, nickname: String, grade: Int) -> AnyPublisher<User, APIError> {
        let endpoint = AuthEndpoint.register(username: username, password: password, nickname: nickname, grade: grade)
        return apiClient.request(endpoint, type: UserDTO.self)
            .map { $0.toDomain() }
            .eraseToAnyPublisher()
    }

    func login(username: String, password: String) -> AnyPublisher<LoginResponse, APIError> {
        let endpoint = AuthEndpoint.login(username: username, password: password)
        return apiClient.request(endpoint, type: LoginResponse.self)
    }

    func refreshToken(_ refreshToken: String) -> AnyPublisher<TokenResponse, APIError> {
        let endpoint = AuthEndpoint.refreshToken(refreshToken: refreshToken)
        return apiClient.request(endpoint, type: TokenResponse.self)
    }

    func logout() -> AnyPublisher<Void, APIError> {
        let endpoint = AuthEndpoint.logout
        return apiClient.request(endpoint, type: EmptyResponse.self)
            .map { _ in () }
            .eraseToAnyPublisher()
    }

    func getCurrentUser() -> AnyPublisher<User, APIError> {
        let endpoint = AuthEndpoint.profile
        return apiClient.request(endpoint, type: UserDTO.self)
            .map { $0.toDomain() }
            .eraseToAnyPublisher()
    }

    func updateUser(_ user: User) -> AnyPublisher<User, APIError> {
        let requestDTO = UpdateUserRequestDTO.from(user)
        let endpoint = AuthEndpoint.updateProfile(requestDTO)
        return apiClient.request(endpoint, type: UserDTO.self)
            .map { $0.toDomain() }
            .eraseToAnyPublisher()
    }

    func changePassword(oldPassword: String, newPassword: String) -> AnyPublisher<Void, APIError> {
        let requestDTO = ChangePasswordRequestDTO(oldPassword: oldPassword, newPassword: newPassword)
        let endpoint = AuthEndpoint.changePassword(requestDTO)
        return apiClient.request(endpoint, type: EmptyResponse.self)
            .map { _ in () }
            .eraseToAnyPublisher()
    }

    func checkUsernameAvailability(_ username: String) -> AnyPublisher<Bool, APIError> {
        let endpoint = AuthEndpoint.checkUsername(username)
        return apiClient.request(endpoint, type: AvailabilityResponse.self)
            .map { $0.available }
            .eraseToAnyPublisher()
    }
}

// MARK: - Response Models

struct EmptyResponse: Codable {}

struct AvailabilityResponse: Codable {
    let available: Bool
}
