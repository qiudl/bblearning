//
//  RequestInterceptor.swift
//  BBLearning
//
//  Created by Claude Code on 2025-10-13.
//

import Foundation
import Alamofire
import Combine

/// 请求拦截器 - 处理认证和Token刷新
final class AuthRequestInterceptor: RequestInterceptor {

    private let keychainManager: KeychainManager
    private var isRefreshing = false
    private var requestsToRetry: [(RetryResult) -> Void] = []

    init(keychainManager: KeychainManager = .shared) {
        self.keychainManager = keychainManager
    }

    // MARK: - RequestAdapter

    func adapt(
        _ urlRequest: URLRequest,
        for session: Session,
        completion: @escaping (Result<URLRequest, Error>) -> Void
    ) {
        var urlRequest = urlRequest

        // 添加认证Token
        if let accessToken = keychainManager.getAccessToken() {
            urlRequest.headers.add(.authorization(bearerToken: accessToken))
        }

        // 添加通用Headers
        urlRequest.headers.add(name: "Accept", value: "application/json")
        urlRequest.headers.add(name: "Accept-Language", value: "zh-CN")

        // 添加应用版本信息
        let version = Configuration.appVersion
        let build = Configuration.buildNumber
        urlRequest.headers.add(name: "X-App-Version", value: "\(version).\(build)")
        urlRequest.headers.add(name: "X-Platform", value: "iOS")

        completion(.success(urlRequest))
    }

    // MARK: - RequestRetrier

    func retry(
        _ request: Request,
        for session: Session,
        dueTo error: Error,
        completion: @escaping (RetryResult) -> Void
    ) {
        // 只处理401未授权错误
        guard let response = request.task?.response as? HTTPURLResponse,
              response.statusCode == 401 else {
            completion(.doNotRetryWithError(error))
            return
        }

        // 如果正在刷新Token，加入等待队列
        guard !isRefreshing else {
            requestsToRetry.append(completion)
            return
        }

        isRefreshing = true

        // 刷新Token
        refreshToken { [weak self] success in
            guard let self = self else { return }

            self.isRefreshing = false

            if success {
                // Token刷新成功，重试所有等待的请求
                self.requestsToRetry.forEach { $0(.retry) }
                self.requestsToRetry.removeAll()
                completion(.retry)
            } else {
                // Token刷新失败，不重试
                self.requestsToRetry.forEach { $0(.doNotRetry) }
                self.requestsToRetry.removeAll()
                completion(.doNotRetry)

                // 发送登出通知
                NotificationCenter.default.post(name: .userDidLogout, object: nil)
            }
        }
    }

    // MARK: - Private Methods

    private func refreshToken(completion: @escaping (Bool) -> Void) {
        guard let refreshToken = keychainManager.getRefreshToken() else {
            completion(false)
            return
        }

        let endpoint = AuthEndpoint.refreshToken(refreshToken: refreshToken)
        let baseURL = Configuration.baseURL

        AF.request(
            baseURL + endpoint.path,
            method: endpoint.method,
            parameters: endpoint.parameters,
            encoding: endpoint.encoding,
            headers: endpoint.headers
        )
        .validate()
        .responseDecodable(of: TokenResponse.self) { [weak self] response in
            guard let self = self else {
                completion(false)
                return
            }

            switch response.result {
            case .success(let tokenResponse):
                // 保存新Token
                self.keychainManager.saveAccessToken(tokenResponse.accessToken)
                self.keychainManager.saveRefreshToken(tokenResponse.refreshToken)
                completion(true)

            case .failure:
                // 刷新失败，清除Token
                self.keychainManager.clearAll()
                completion(false)
            }
        }
    }
}

// MARK: - Token Response

struct TokenResponse: Decodable {
    let accessToken: String
    let refreshToken: String
    let expiresIn: Int

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case expiresIn = "expires_in"
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let userDidLogout = Notification.Name("userDidLogout")
}
