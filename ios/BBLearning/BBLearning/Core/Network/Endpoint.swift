//
//  Endpoint.swift
//  BBLearning
//
//  Created by Claude Code on 2025-10-13.
//

import Foundation
import Alamofire

/// API端点协议
protocol Endpoint {
    var path: String { get }
    var method: HTTPMethod { get }
    var parameters: Parameters? { get }
    var encoding: ParameterEncoding { get }
    var headers: HTTPHeaders? { get }
}

// MARK: - Auth Endpoints

enum AuthEndpoint: Endpoint {
    case login(username: String, password: String)
    case register(username: String, password: String, nickname: String, grade: Int)
    case refreshToken(refreshToken: String)
    case logout

    var path: String {
        switch self {
        case .login: return "/auth/login"
        case .register: return "/auth/register"
        case .refreshToken: return "/auth/refresh"
        case .logout: return "/auth/logout"
        }
    }

    var method: HTTPMethod {
        return .post
    }

    var parameters: Parameters? {
        switch self {
        case .login(let username, let password):
            return [
                "username": username,
                "password": password
            ]
        case .register(let username, let password, let nickname, let grade):
            return [
                "username": username,
                "password": password,
                "nickname": nickname,
                "grade": grade
            ]
        case .refreshToken(let token):
            return ["refresh_token": token]
        case .logout:
            return nil
        }
    }

    var encoding: ParameterEncoding {
        return JSONEncoding.default
    }

    var headers: HTTPHeaders? {
        return ["Content-Type": "application/json"]
    }
}

// MARK: - Knowledge Endpoints

enum KnowledgeEndpoint: Endpoint {
    case getTree(grade: Int)
    case getDetail(id: Int)
    case updateProgress(id: Int, progress: Double)

    var path: String {
        switch self {
        case .getTree:
            return "/knowledge/tree"
        case .getDetail(let id):
            return "/knowledge/\(id)"
        case .updateProgress(let id, _):
            return "/knowledge/\(id)/progress"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .getTree, .getDetail:
            return .get
        case .updateProgress:
            return .put
        }
    }

    var parameters: Parameters? {
        switch self {
        case .getTree(let grade):
            return ["grade": grade]
        case .getDetail:
            return nil
        case .updateProgress(_, let progress):
            return ["progress": progress]
        }
    }

    var encoding: ParameterEncoding {
        switch self {
        case .getTree, .getDetail:
            return URLEncoding.default
        case .updateProgress:
            return JSONEncoding.default
        }
    }

    var headers: HTTPHeaders? {
        return nil
    }
}

// MARK: - Practice Endpoints

enum PracticeEndpoint: Endpoint {
    case generateQuestions(knowledgePointIds: [Int], difficulty: String, count: Int)
    case submitAnswer(questionId: Int, userAnswer: String, timeSpent: Int)
    case getHistory(page: Int, pageSize: Int)
    case getWrongQuestions(page: Int, pageSize: Int)

    var path: String {
        switch self {
        case .generateQuestions:
            return "/practice/generate"
        case .submitAnswer:
            return "/practice/submit"
        case .getHistory:
            return "/practice/history"
        case .getWrongQuestions:
            return "/practice/wrong-questions"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .generateQuestions, .submitAnswer:
            return .post
        case .getHistory, .getWrongQuestions:
            return .get
        }
    }

    var parameters: Parameters? {
        switch self {
        case .generateQuestions(let ids, let difficulty, let count):
            return [
                "knowledge_point_ids": ids,
                "difficulty": difficulty,
                "count": count
            ]
        case .submitAnswer(let questionId, let answer, let timeSpent):
            return [
                "question_id": questionId,
                "user_answer": answer,
                "time_spent": timeSpent
            ]
        case .getHistory(let page, let pageSize):
            return [
                "page": page,
                "page_size": pageSize
            ]
        case .getWrongQuestions(let page, let pageSize):
            return [
                "page": page,
                "page_size": pageSize
            ]
        }
    }

    var encoding: ParameterEncoding {
        switch self {
        case .generateQuestions, .submitAnswer:
            return JSONEncoding.default
        case .getHistory, .getWrongQuestions:
            return URLEncoding.default
        }
    }

    var headers: HTTPHeaders? {
        return nil
    }
}

// MARK: - AI Endpoints

enum AIEndpoint: Endpoint {
    case chat(message: String, conversationId: String?)
    case recognizeQuestion(imageData: Data)
    case diagnose(userId: Int)
    case recommend(userId: Int)

    var path: String {
        switch self {
        case .chat:
            return "/ai/chat"
        case .recognizeQuestion:
            return "/ai/recognize"
        case .diagnose:
            return "/ai/diagnose"
        case .recommend:
            return "/ai/recommend"
        }
    }

    var method: HTTPMethod {
        return .post
    }

    var parameters: Parameters? {
        switch self {
        case .chat(let message, let conversationId):
            var params: Parameters = ["message": message]
            if let id = conversationId {
                params["conversation_id"] = id
            }
            return params
        case .recognizeQuestion:
            return nil // Will use multipart form data
        case .diagnose(let userId):
            return ["user_id": userId]
        case .recommend(let userId):
            return ["user_id": userId]
        }
    }

    var encoding: ParameterEncoding {
        return JSONEncoding.default
    }

    var headers: HTTPHeaders? {
        return nil
    }
}

// MARK: - Statistics Endpoints

enum StatisticsEndpoint: Endpoint {
    case getLearningStats(userId: Int, startDate: String?, endDate: String?)
    case getKnowledgeMastery(userId: Int, grade: Int)
    case getProgressCurve(userId: Int, days: Int)

    var path: String {
        switch self {
        case .getLearningStats:
            return "/statistics/learning"
        case .getKnowledgeMastery:
            return "/statistics/knowledge-mastery"
        case .getProgressCurve:
            return "/statistics/progress"
        }
    }

    var method: HTTPMethod {
        return .get
    }

    var parameters: Parameters? {
        switch self {
        case .getLearningStats(let userId, let startDate, let endDate):
            var params: Parameters = ["user_id": userId]
            if let start = startDate {
                params["start_date"] = start
            }
            if let end = endDate {
                params["end_date"] = end
            }
            return params
        case .getKnowledgeMastery(let userId, let grade):
            return [
                "user_id": userId,
                "grade": grade
            ]
        case .getProgressCurve(let userId, let days):
            return [
                "user_id": userId,
                "days": days
            ]
        }
    }

    var encoding: ParameterEncoding {
        return URLEncoding.default
    }

    var headers: HTTPHeaders? {
        return nil
    }
}
