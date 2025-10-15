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
    case profile
    case updateProfile(nickname: String?, avatar: String?, grade: Int?)
    case changePassword(oldPassword: String, newPassword: String)
    case checkUsername(username: String)

    var path: String {
        switch self {
        case .login: return "/auth/login"
        case .register: return "/auth/register"
        case .refreshToken: return "/auth/refresh"
        case .logout: return "/auth/logout"
        case .profile: return "/users/me"
        case .updateProfile: return "/users/me"
        case .changePassword: return "/users/me/password"
        case .checkUsername: return "/auth/check-username"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .profile:
            return .get
        case .updateProfile:
            return .put
        default:
            return .post
        }
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
        case .profile:
            return nil
        case .updateProfile(let nickname, let avatar, let grade):
            var params: Parameters = [:]
            if let nickname = nickname {
                params["nickname"] = nickname
            }
            if let avatar = avatar {
                params["avatar"] = avatar
            }
            if let grade = grade {
                params["grade"] = grade
            }
            return params
        case .changePassword(let oldPassword, let newPassword):
            return [
                "old_password": oldPassword,
                "new_password": newPassword
            ]
        case .checkUsername(let username):
            return ["username": username]
        }
    }

    var encoding: ParameterEncoding {
        switch self {
        case .profile:
            return URLEncoding.default
        default:
            return JSONEncoding.default
        }
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
    case tree(grade: Int)
    case detail(id: Int)
    case children(parentId: Int)
    case progress(id: Int)
    case search(keyword: String, grade: Int?)
    case recommended(limit: Int)
    case weak(limit: Int)
    case markMastered(id: Int)

    var path: String {
        switch self {
        case .getTree, .tree:
            return "/knowledge/tree"
        case .getDetail(let id), .detail(let id):
            return "/knowledge/\(id)"
        case .updateProgress(let id, _):
            return "/knowledge/\(id)/progress"
        case .children(let parentId):
            return "/knowledge/\(parentId)/children"
        case .progress(let id):
            return "/knowledge/\(id)/progress"
        case .search:
            return "/knowledge/search"
        case .recommended:
            return "/knowledge/recommended"
        case .weak:
            return "/knowledge/weak"
        case .markMastered(let id):
            return "/knowledge/\(id)/mastered"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .getTree, .getDetail, .tree, .detail, .children, .progress, .search, .recommended, .weak:
            return .get
        case .updateProgress, .markMastered:
            return .put
        }
    }

    var parameters: Parameters? {
        switch self {
        case .getTree(let grade), .tree(let grade):
            return ["grade": grade]
        case .getDetail, .detail, .children:
            return nil
        case .updateProgress(_, let progress):
            return ["progress": progress]
        case .progress:
            return nil
        case .search(let keyword, let grade):
            var params: Parameters = ["keyword": keyword]
            if let g = grade {
                params["grade"] = g
            }
            return params
        case .recommended(let limit):
            return ["limit": limit]
        case .weak(let limit):
            return ["limit": limit]
        case .markMastered:
            return nil
        }
    }

    var encoding: ParameterEncoding {
        switch self {
        case .updateProgress, .markMastered:
            return JSONEncoding.default
        default:
            return URLEncoding.default
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
    case questionDetail(id: Int)
    case history(page: Int, pageSize: Int, knowledgePointId: Int?)
    case recordDetail(id: Int)
    case createSession(knowledgePointId: Int, count: Int)
    case completeSession(id: Int)
    case currentSession
    case wrongQuestions(page: Int, pageSize: Int, status: String?, knowledgePointId: Int?)
    case wrongQuestionDetail(id: Int)
    case addWrongQuestion(recordId: Int)
    case deleteWrongQuestion(id: Int)
    case updateWrongQuestionStatus(id: Int, status: String)
    case retryWrongQuestion(id: Int, isCorrect: Bool)
    case markWrongQuestionMastered(id: Int)
    case wrongQuestionsNeedReview(limit: Int)
    case wrongQuestionStats
    case batchMarkMastered(ids: [Int])
    case archiveOldWrongQuestions(days: Int)

    var path: String {
        switch self {
        case .generateQuestions:
            return "/practice/generate"
        case .submitAnswer:
            return "/practice/submit"
        case .getHistory, .history:
            return "/practice/history"
        case .getWrongQuestions, .wrongQuestions:
            return "/practice/wrong-questions"
        case .questionDetail(let id):
            return "/practice/questions/\(id)"
        case .recordDetail(let id):
            return "/practice/records/\(id)"
        case .createSession:
            return "/practice/sessions"
        case .completeSession(let id):
            return "/practice/sessions/\(id)/complete"
        case .currentSession:
            return "/practice/sessions/current"
        case .wrongQuestionDetail(let id):
            return "/practice/wrong-questions/\(id)"
        case .addWrongQuestion:
            return "/practice/wrong-questions"
        case .deleteWrongQuestion(let id):
            return "/practice/wrong-questions/\(id)"
        case .updateWrongQuestionStatus(let id, _):
            return "/practice/wrong-questions/\(id)/status"
        case .retryWrongQuestion(let id, _):
            return "/practice/wrong-questions/\(id)/retry"
        case .markWrongQuestionMastered(let id):
            return "/practice/wrong-questions/\(id)/mastered"
        case .wrongQuestionsNeedReview:
            return "/practice/wrong-questions/need-review"
        case .wrongQuestionStats:
            return "/practice/wrong-questions/stats"
        case .batchMarkMastered:
            return "/practice/wrong-questions/batch-mastered"
        case .archiveOldWrongQuestions:
            return "/practice/wrong-questions/archive"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .generateQuestions, .submitAnswer, .createSession, .completeSession, .addWrongQuestion, .retryWrongQuestion, .batchMarkMastered, .archiveOldWrongQuestions:
            return .post
        case .getHistory, .getWrongQuestions, .questionDetail, .history, .recordDetail, .currentSession, .wrongQuestions, .wrongQuestionDetail, .wrongQuestionsNeedReview, .wrongQuestionStats:
            return .get
        case .deleteWrongQuestion:
            return .delete
        case .updateWrongQuestionStatus, .markWrongQuestionMastered:
            return .put
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
        case .questionDetail, .recordDetail, .currentSession, .wrongQuestionDetail, .wrongQuestionStats:
            return nil
        case .history(let page, let pageSize, let knowledgePointId):
            var params: Parameters = ["page": page, "page_size": pageSize]
            if let kpId = knowledgePointId {
                params["knowledge_point_id"] = kpId
            }
            return params
        case .createSession(let knowledgePointId, let count):
            return ["knowledge_point_id": knowledgePointId, "count": count]
        case .completeSession:
            return nil
        case .wrongQuestions(let page, let pageSize, let status, let knowledgePointId):
            var params: Parameters = ["page": page, "page_size": pageSize]
            if let s = status {
                params["status"] = s
            }
            if let kpId = knowledgePointId {
                params["knowledge_point_id"] = kpId
            }
            return params
        case .addWrongQuestion(let recordId):
            return ["practice_record_id": recordId]
        case .deleteWrongQuestion:
            return nil
        case .updateWrongQuestionStatus(_, let status):
            return ["status": status]
        case .retryWrongQuestion(_, let isCorrect):
            return ["is_correct": isCorrect]
        case .markWrongQuestionMastered:
            return nil
        case .wrongQuestionsNeedReview(let limit):
            return ["limit": limit]
        case .batchMarkMastered(let ids):
            return ["ids": ids]
        case .archiveOldWrongQuestions(let days):
            return ["days": days]
        }
    }

    var encoding: ParameterEncoding {
        switch self {
        case .generateQuestions, .submitAnswer, .createSession, .completeSession, .addWrongQuestion, .updateWrongQuestionStatus, .retryWrongQuestion, .batchMarkMastered, .archiveOldWrongQuestions:
            return JSONEncoding.default
        default:
            return URLEncoding.default
        }
    }

    var headers: HTTPHeaders? {
        return nil
    }
}

// MARK: - AI Endpoints

enum AIEndpoint: Endpoint {
    case chat(message: String, conversationId: Int?)
    case recognizeQuestion(imageData: Data)
    case diagnose(userId: Int)
    case recommend(userId: Int)
    case chatHistory(conversationId: Int, page: Int, pageSize: Int)
    case conversations(page: Int, pageSize: Int)
    case createConversation(title: String)
    case deleteConversation(id: Int)
    case diagnosis(knowledgePointId: Int?)
    case recommendations
    case recommendPractices(limit: Int)
    case generateQuestion(knowledgePointId: Int, difficulty: String, requirements: String?)
    case gradeAnswer(questionId: Int, answer: String)

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
        case .chatHistory(let conversationId, _, _):
            return "/ai/conversations/\(conversationId)/messages"
        case .conversations:
            return "/ai/conversations"
        case .createConversation:
            return "/ai/conversations"
        case .deleteConversation(let id):
            return "/ai/conversations/\(id)"
        case .diagnosis:
            return "/ai/diagnosis"
        case .recommendations:
            return "/ai/recommendations"
        case .recommendPractices:
            return "/ai/recommend-practices"
        case .generateQuestion:
            return "/ai/generate-question"
        case .gradeAnswer:
            return "/ai/grade"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .chatHistory, .conversations, .diagnosis, .recommendations, .recommendPractices:
            return .get
        case .deleteConversation:
            return .delete
        case .chat, .recognizeQuestion, .diagnose, .recommend, .createConversation, .generateQuestion, .gradeAnswer:
            return .post
        }
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
        case .chatHistory(_, let page, let pageSize):
            return ["page": page, "page_size": pageSize]
        case .conversations(let page, let pageSize):
            return ["page": page, "page_size": pageSize]
        case .createConversation(let title):
            return ["title": title]
        case .deleteConversation:
            return nil
        case .diagnosis(let knowledgePointId):
            if let id = knowledgePointId {
                return ["knowledge_point_id": id]
            }
            return nil
        case .recommendations:
            return nil
        case .recommendPractices(let limit):
            return ["limit": limit]
        case .generateQuestion(let knowledgePointId, let difficulty, let requirements):
            var params: Parameters = [
                "knowledge_point_id": knowledgePointId,
                "difficulty": difficulty
            ]
            if let req = requirements {
                params["requirements"] = req
            }
            return params
        case .gradeAnswer(let questionId, let answer):
            return [
                "question_id": questionId,
                "user_answer": answer
            ]
        }
    }

    var encoding: ParameterEncoding {
        switch self {
        case .chatHistory, .conversations, .diagnosis, .recommendations, .recommendPractices:
            return URLEncoding.default
        default:
            return JSONEncoding.default
        }
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
    case learning(date: String)
    case daily(date: String)
    case weekly(weekStart: String)
    case monthly(month: String)
    case overall
    case knowledgeMastery(grade: Int?, knowledgePointId: Int?)
    case progressCurve(start: String, end: String, knowledgePointId: Int?)
    case recordPractice(count: Int, correct: Int, time: Int)
    case updateStreak
    case leaderboard(grade: Int?, type: String, limit: Int)

    var path: String {
        switch self {
        case .getLearningStats, .learning:
            return "/statistics/learning"
        case .getKnowledgeMastery, .knowledgeMastery:
            return "/statistics/knowledge-mastery"
        case .getProgressCurve, .progressCurve:
            return "/statistics/progress"
        case .daily:
            return "/statistics/daily"
        case .weekly:
            return "/statistics/weekly"
        case .monthly:
            return "/statistics/monthly"
        case .overall:
            return "/statistics/overall"
        case .recordPractice:
            return "/statistics/practice"
        case .updateStreak:
            return "/statistics/streak"
        case .leaderboard:
            return "/statistics/leaderboard"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .recordPractice, .updateStreak:
            return .post
        default:
            return .get
        }
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
        case .learning(let date):
            return ["date": date]
        case .daily(let date):
            return ["date": date]
        case .weekly(let weekStart):
            return ["week_start": weekStart]
        case .monthly(let month):
            return ["month": month]
        case .overall:
            return nil
        case .knowledgeMastery(let grade, let knowledgePointId):
            var params: Parameters = [:]
            if let g = grade {
                params["grade"] = g
            }
            if let kpId = knowledgePointId {
                params["knowledge_point_id"] = kpId
            }
            return params
        case .progressCurve(let start, let end, let knowledgePointId):
            var params: Parameters = ["start": start, "end": end]
            if let kpId = knowledgePointId {
                params["knowledge_point_id"] = kpId
            }
            return params
        case .recordPractice(let count, let correct, let time):
            return [
                "practice_count": count,
                "correct_count": correct,
                "study_time": time
            ]
        case .updateStreak:
            return nil
        case .leaderboard(let grade, let type, let limit):
            var params: Parameters = ["type": type, "limit": limit]
            if let g = grade {
                params["grade"] = g
            }
            return params
        }
    }

    var encoding: ParameterEncoding {
        switch self {
        case .recordPractice:
            return JSONEncoding.default
        default:
            return URLEncoding.default
        }
    }

    var headers: HTTPHeaders? {
        return nil
    }
}
