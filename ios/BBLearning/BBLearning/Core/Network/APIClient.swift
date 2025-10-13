//
//  APIClient.swift
//  BBLearning
//
//  Created by Claude Code on 2025-10-13.
//

import Foundation
import Alamofire
import Combine

/// API客户端 - 负责所有网络请求
final class APIClient {

    static let shared = APIClient()

    private let session: Session
    private let baseURL: String

    private init() {
        self.baseURL = Configuration.baseURL

        // 配置URLSession
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = Configuration.apiTimeout
        configuration.timeoutIntervalForResource = Configuration.apiTimeout * 2
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData

        // 创建拦截器
        let interceptor = AuthRequestInterceptor()

        // 创建Session
        self.session = Session(
            configuration: configuration,
            interceptor: interceptor,
            eventMonitors: Configuration.enableDebugLogging ? [NetworkLogger()] : []
        )
    }

    // MARK: - Request Methods

    /// 通用请求方法
    func request<T: Decodable>(
        _ endpoint: Endpoint,
        type: T.Type
    ) -> AnyPublisher<T, APIError> {
        let url = baseURL + endpoint.path

        return session.request(
            url,
            method: endpoint.method,
            parameters: endpoint.parameters,
            encoding: endpoint.encoding,
            headers: endpoint.headers
        )
        .validate()
        .publishDecodable(type: T.self)
        .value()
        .mapError { error in
            return self.mapAFError(error)
        }
        .eraseToAnyPublisher()
    }

    /// 请求返回APIResponse包装的数据
    func requestAPIResponse<T: Decodable>(
        _ endpoint: Endpoint,
        type: T.Type
    ) -> AnyPublisher<T, APIError> {
        return request(endpoint, type: APIResponse<T>.self)
            .tryMap { response in
                guard response.code == 0, let data = response.data else {
                    throw APIError.badRequest(response.message)
                }
                return data
            }
            .mapError { error in
                if let apiError = error as? APIError {
                    return apiError
                }
                return APIError.unknown
            }
            .eraseToAnyPublisher()
    }

    /// 上传文件
    func upload<T: Decodable>(
        _ endpoint: Endpoint,
        fileData: Data,
        fileName: String,
        mimeType: String,
        type: T.Type
    ) -> AnyPublisher<T, APIError> {
        let url = baseURL + endpoint.path

        return Future<T, APIError> { promise in
            self.session.upload(
                multipartFormData: { multipartFormData in
                    multipartFormData.append(
                        fileData,
                        withName: "file",
                        fileName: fileName,
                        mimeType: mimeType
                    )

                    // 添加其他参数
                    if let parameters = endpoint.parameters {
                        for (key, value) in parameters {
                            if let data = "\(value)".data(using: .utf8) {
                                multipartFormData.append(data, withName: key)
                            }
                        }
                    }
                },
                to: url,
                method: endpoint.method,
                headers: endpoint.headers
            )
            .validate()
            .responseDecodable(of: T.self) { response in
                switch response.result {
                case .success(let value):
                    promise(.success(value))
                case .failure(let error):
                    promise(.failure(self.mapAFError(error)))
                }
            }
        }
        .eraseToAnyPublisher()
    }

    /// 下载文件
    func download(
        _ endpoint: Endpoint,
        to destination: URL
    ) -> AnyPublisher<URL, APIError> {
        let url = baseURL + endpoint.path

        return Future<URL, APIError> { promise in
            self.session.download(
                url,
                method: endpoint.method,
                parameters: endpoint.parameters,
                encoding: endpoint.encoding,
                headers: endpoint.headers,
                to: { _, _ in
                    return (destination, [.removePreviousFile, .createIntermediateDirectories])
                }
            )
            .validate()
            .response { response in
                if let error = response.error {
                    promise(.failure(self.mapAFError(error)))
                } else {
                    promise(.success(destination))
                }
            }
        }
        .eraseToAnyPublisher()
    }

    // MARK: - Error Mapping

    private func mapAFError(_ error: AFError) -> APIError {
        if let underlyingError = error.underlyingError as? URLError {
            switch underlyingError.code {
            case .timedOut:
                return .timeout
            case .notConnectedToInternet, .networkConnectionLost:
                return .noConnection
            default:
                return .networkError(underlyingError)
            }
        }

        if let statusCode = error.responseCode {
            switch statusCode {
            case 400:
                return .badRequest("请求参数错误")
            case 401:
                return .unauthorized
            case 403:
                return .forbidden
            case 404:
                return .notFound
            case 500...599:
                return .serverError(statusCode, "服务器错误")
            default:
                return .serverError(statusCode, "未知错误")
            }
        }

        if error.isResponseSerializationError {
            return .decodingError(error)
        }

        if error.isParameterEncodingError {
            return .encodingError(error)
        }

        return .unknown
    }
}

// MARK: - Network Logger

/// 网络请求日志监听器
final class NetworkLogger: EventMonitor {
    let queue = DispatchQueue(label: "com.bblearning.networklogger")

    func requestDidResume(_ request: Request) {
        let method = request.request?.method?.rawValue ?? "UNKNOWN"
        let url = request.request?.url?.absoluteString ?? "UNKNOWN"

        Logger.shared.network("🚀 [\(method)] \(url)")

        if let headers = request.request?.headers {
            Logger.shared.network("Headers: \(headers.dictionary)")
        }

        if let body = request.request?.httpBody,
           let bodyString = String(data: body, encoding: .utf8) {
            Logger.shared.network("Body: \(bodyString)")
        }
    }

    func request<Value>(_ request: DataRequest, didParseResponse response: DataResponse<Value, AFError>) {
        let statusCode = response.response?.statusCode ?? 0
        let url = request.request?.url?.absoluteString ?? "UNKNOWN"

        switch response.result {
        case .success:
            Logger.shared.network("✅ [\(statusCode)] \(url)")
        case .failure(let error):
            Logger.shared.network("❌ [\(statusCode)] \(url) - \(error.localizedDescription)")
        }

        if let data = response.data,
           let jsonString = String(data: data, encoding: .utf8) {
            Logger.shared.network("Response: \(jsonString)")
        }
    }
}
