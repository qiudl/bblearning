//
//  AIRepositoryProtocol.swift
//  BBLearning
//
//  Created by Claude Code on 2025-10-13.
//

import Foundation
import Combine

/// AI服务仓储协议
protocol AIRepositoryProtocol {
    /// 与AI聊天
    /// - Parameters:
    ///   - conversationId: 会话ID（可选，新建会话时不传）
    ///   - message: 用户消息
    /// - Returns: AI回复消息
    func chat(conversationId: Int?, message: String) -> AnyPublisher<AIMessage, APIError>

    /// 拍照识题
    /// - Parameter imageData: 图片数据
    /// - Returns: 识别结果（题目和解答）
    func recognizeQuestion(imageData: Data) -> AnyPublisher<QuestionRecognitionResult, APIError>

    /// 获取聊天历史
    /// - Parameters:
    ///   - conversationId: 会话ID
    ///   - page: 页码
    ///   - pageSize: 每页数量
    /// - Returns: 分页的消息列表
    func getChatHistory(conversationId: Int, page: Int, pageSize: Int) -> AnyPublisher<PagedResponse<AIMessage>, APIError>

    /// 获取会话列表
    /// - Parameters:
    ///   - page: 页码
    ///   - pageSize: 每页数量
    /// - Returns: 分页的会话列表
    func getConversations(page: Int, pageSize: Int) -> AnyPublisher<PagedResponse<ChatConversation>, APIError>

    /// 创建新会话
    /// - Parameter title: 会话标题
    /// - Returns: 新建的会话
    func createConversation(title: String) -> AnyPublisher<ChatConversation, APIError>

    /// 删除会话
    /// - Parameter conversationId: 会话ID
    /// - Returns: 成功标识
    func deleteConversation(conversationId: Int) -> AnyPublisher<Void, APIError>

    /// 获取学习诊断
    /// - Parameter knowledgePointId: 知识点ID（可选，不传则诊断全部）
    /// - Returns: 诊断报告
    func getDiagnosis(knowledgePointId: Int?) -> AnyPublisher<DiagnosisReport, APIError>

    /// 获取个性化推荐
    /// - Returns: 推荐内容
    func getRecommendations() -> AnyPublisher<Recommendations, APIError>

    /// AI生成自定义题目
    /// - Parameters:
    ///   - knowledgePointId: 知识点ID
    ///   - difficulty: 难度级别
    ///   - requirements: 特殊要求（可选）
    /// - Returns: 生成的题目
    func generateCustomQuestion(knowledgePointId: Int, difficulty: Question.Difficulty, requirements: String?) -> AnyPublisher<Question, APIError>

    /// AI评分和反馈
    /// - Parameters:
    ///   - questionId: 题目ID
    ///   - userAnswer: 用户答案
    /// - Returns: AI评分结果
    func gradeAnswer(questionId: Int, userAnswer: String) -> AnyPublisher<AIGrade, APIError>
}

// MARK: - Response Models

/// 题目识别结果
struct QuestionRecognitionResult: Codable {
    let imageUrl: String                // 上传后的图片URL
    let recognizedText: String          // 识别的文本
    let question: Question?             // 识别出的题目（如果匹配到题库）
    let aiSolution: String?             // AI给出的解答
    let confidence: Double              // 识别置信度

    enum CodingKeys: String, CodingKey {
        case imageUrl = "image_url"
        case recognizedText = "recognized_text"
        case question
        case aiSolution = "ai_solution"
        case confidence
    }
}

/// 诊断报告
struct DiagnosisReport: Codable {
    let userId: Int
    let overallLevel: String            // 总体水平
    let strengths: [String]             // 优势项
    let weaknesses: [String]            // 薄弱项
    let suggestions: [String]           // 改进建议
    let focusKnowledgePoints: [Int]     // 重点关注知识点
    let recommendedDifficulty: String   // 推荐难度
    let estimatedStudyTime: Int         // 预计学习时长（分钟）

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case overallLevel = "overall_level"
        case strengths
        case weaknesses
        case suggestions
        case focusKnowledgePoints = "focus_knowledge_points"
        case recommendedDifficulty = "recommended_difficulty"
        case estimatedStudyTime = "estimated_study_time"
    }
}

/// 个性化推荐
struct Recommendations: Codable {
    let knowledgePoints: [KnowledgePoint]   // 推荐学习的知识点
    let questions: [Question]               // 推荐练习的题目
    let topics: [String]                    // 推荐的学习主题
    let studyPlan: StudyPlan?               // 学习计划建议

    enum CodingKeys: String, CodingKey {
        case knowledgePoints = "knowledge_points"
        case questions
        case topics
        case studyPlan = "study_plan"
    }
}

/// 学习计划
struct StudyPlan: Codable {
    let duration: Int                       // 计划时长（天）
    let dailyGoal: Int                      // 每日目标（分钟）
    let phases: [StudyPhase]                // 学习阶段

    enum CodingKeys: String, CodingKey {
        case duration
        case dailyGoal = "daily_goal"
        case phases
    }
}

/// 学习阶段
struct StudyPhase: Codable {
    let name: String
    let knowledgePointIds: [Int]
    let estimatedDays: Int
    let description: String

    enum CodingKeys: String, CodingKey {
        case name
        case knowledgePointIds = "knowledge_point_ids"
        case estimatedDays = "estimated_days"
        case description
    }
}
