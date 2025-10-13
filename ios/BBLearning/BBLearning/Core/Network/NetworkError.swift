//
//  NetworkError.swift
//  BBLearning
//
//  Created by Claude Code on 2025-10-13.
//

import Foundation

/// API错误类型
enum APIError: Error {
    case networkError(Error)
    case decodingError(Error)
    case encodingError(Error)
    case unauthorized
    case forbidden
    case notFound
    case serverError(Int, String)
    case badRequest(String)
    case timeout
    case noConnection
    case unknown

    var localizedDescription: String {
        switch self {
        case .networkError(let error):
            return "网络错误: \(error.localizedDescription)"
        case .decodingError:
            return "数据解析失败"
        case .encodingError:
            return "数据编码失败"
        case .unauthorized:
            return "未授权，请重新登录"
        case .forbidden:
            return "没有访问权限"
        case .notFound:
            return "请求的资源不存在"
        case .serverError(let code, let message):
            return "服务器错误 (\(code)): \(message)"
        case .badRequest(let message):
            return "请求错误: \(message)"
        case .timeout:
            return "请求超时，请检查网络连接"
        case .noConnection:
            return "网络未连接，请检查网络设置"
        case .unknown:
            return "未知错误"
        }
    }

    var code: Int {
        switch self {
        case .networkError: return -1
        case .decodingError: return -2
        case .encodingError: return -3
        case .unauthorized: return 401
        case .forbidden: return 403
        case .notFound: return 404
        case .serverError(let code, _): return code
        case .badRequest: return 400
        case .timeout: return -1001
        case .noConnection: return -1009
        case .unknown: return -999
        }
    }
}

/// API响应包装
struct APIResponse<T: Decodable>: Decodable {
    let code: Int
    let message: String
    let data: T?
    let requestId: String?

    enum CodingKeys: String, CodingKey {
        case code
        case message
        case data
        case requestId = "request_id"
    }
}

/// 空响应
struct EmptyResponse: Decodable {}

/// 分页响应
struct PagedResponse<T: Decodable>: Decodable {
    let items: [T]
    let total: Int
    let page: Int
    let pageSize: Int
    let hasMore: Bool

    enum CodingKeys: String, CodingKey {
        case items
        case total
        case page
        case pageSize = "page_size"
        case hasMore = "has_more"
    }
}
