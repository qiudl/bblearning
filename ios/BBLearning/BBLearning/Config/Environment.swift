//
//  Environment.swift
//  BBLearning
//
//  Created by Claude Code on 2025-10-13.
//

import Foundation

enum Environment {
    case development
    case staging
    case production

    static var current: Environment {
        #if DEBUG
        return .development
        #elseif STAGING
        return .staging
        #else
        return .production
        #endif
    }

    var baseURL: String {
        switch self {
        case .development:
            return "http://localhost:8080/api/v1"
        case .staging:
            return "https://staging-api.bblearning.com/api/v1"
        case .production:
            return "https://api.bblearning.com/api/v1"
        }
    }

    var wsURL: String {
        switch self {
        case .development:
            return "ws://localhost:8080/ws"
        case .staging:
            return "wss://staging-api.bblearning.com/ws"
        case .production:
            return "wss://api.bblearning.com/ws"
        }
    }

    var name: String {
        switch self {
        case .development: return "Development"
        case .staging: return "Staging"
        case .production: return "Production"
        }
    }

    var isDebug: Bool {
        return self == .development
    }
}
