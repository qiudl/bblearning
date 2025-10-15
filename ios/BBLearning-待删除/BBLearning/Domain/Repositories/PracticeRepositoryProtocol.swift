//
//  PracticeRepositoryProtocol.swift
//  BBLearning
//
//  Created by Claude Code on 2025-10-13.
//

import Foundation
import Combine

/// 练习仓储协议
protocol PracticeRepositoryProtocol {
    /// 生成练习题
    /// - Parameters:
    ///   - knowledgePointIds: 知识点ID列表
    ///   - count: 题目数量
    ///   - difficulty: 难度级别（可选）
    /// - Returns: 题目列表
    func generateQuestions(knowledgePointIds: [Int], count: Int, difficulty: Question.Difficulty?) -> AnyPublisher<[Question], APIError>

    /// 获取题目详情
    /// - Parameter questionId: 题目ID
    /// - Returns: 题目详情
    func getQuestion(id: Int) -> AnyPublisher<Question, APIError>

    /// 提交答案
    /// - Parameters:
    ///   - questionId: 题目ID
    ///   - answer: 用户答案
    ///   - timeSpent: 用时（秒）
    /// - Returns: 练习记录（包含AI评分）
    func submitAnswer(questionId: Int, answer: String, timeSpent: Int) -> AnyPublisher<PracticeRecord, APIError>

    /// 获取练习历史
    /// - Parameters:
    ///   - page: 页码
    ///   - pageSize: 每页数量
    ///   - knowledgePointId: 知识点筛选（可选）
    /// - Returns: 分页的练习记录
    func getPracticeHistory(page: Int, pageSize: Int, knowledgePointId: Int?) -> AnyPublisher<PagedResponse<PracticeRecord>, APIError>

    /// 获取练习记录详情
    /// - Parameter recordId: 记录ID
    /// - Returns: 练习记录详情
    func getPracticeRecord(id: Int) -> AnyPublisher<PracticeRecord, APIError>

    /// 创建练习会话
    /// - Parameters:
    ///   - knowledgePointId: 知识点ID（可选）
    ///   - questionCount: 题目数量
    /// - Returns: 练习会话
    func createPracticeSession(knowledgePointId: Int?, questionCount: Int) -> AnyPublisher<PracticeSession, APIError>

    /// 完成练习会话
    /// - Parameter sessionId: 会话ID
    /// - Returns: 完成后的会话
    func completePracticeSession(sessionId: Int) -> AnyPublisher<PracticeSession, APIError>

    /// 获取当前正在进行的练习会话
    /// - Returns: 练习会话（如果有）
    func getCurrentSession() -> AnyPublisher<PracticeSession?, APIError>
}
