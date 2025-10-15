//
//  Environment.swift
//  BBLearning
//
//  Created by Claude Code on 2025-10-13.
//

import Foundation

enum AppEnvironment {
    case development
    case staging
    case production

    static var current: AppEnvironment {
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
            return "http://192.168.1.18:8080/api/v1"
        case .staging:
            return "https://staging-api.bblearning.joylodging.com/api/v1"
        case .production:
            return "https://api.bblearning.joylodging.com/api/v1"
        }
    }

    var wsURL: String {
        switch self {
        case .development:
            return "ws://192.168.1.18:8080/ws"
        case .staging:
            return "wss://staging-api.bblearning.joylodging.com/ws"
        case .production:
            return "wss://api.bblearning.joylodging.com/ws"
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
