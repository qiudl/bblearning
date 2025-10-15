//
//  WrongQuestionRepositoryProtocol.swift
//  BBLearning
//
//  Created by Claude Code on 2025-10-13.
//

import Foundation
import Combine

/// 错题本仓储协议
protocol WrongQuestionRepositoryProtocol {
    /// 获取错题列表
    /// - Parameters:
    ///   - page: 页码
    ///   - pageSize: 每页数量
    ///   - status: 状态筛选（可选）
    ///   - knowledgePointId: 知识点筛选（可选）
    /// - Returns: 分页的错题列表
    func getWrongQuestions(page: Int, pageSize: Int, status: WrongQuestion.Status?, knowledgePointId: Int?) -> AnyPublisher<PagedResponse<WrongQuestion>, APIError>

    /// 获取错题详情
    /// - Parameter id: 错题ID
    /// - Returns: 错题详情
    func getWrongQuestion(id: Int) -> AnyPublisher<WrongQuestion, APIError>

    /// 添加错题
    /// - Parameter practiceRecordId: 练习记录ID
    /// - Returns: 新增的错题
    func addWrongQuestion(practiceRecordId: Int) -> AnyPublisher<WrongQuestion, APIError>

    /// 删除错题
    /// - Parameter id: 错题ID
    /// - Returns: 成功标识
    func deleteWrongQuestion(id: Int) -> AnyPublisher<Void, APIError>

    /// 更新错题状态
    /// - Parameters:
    ///   - id: 错题ID
    ///   - status: 新状态
    /// - Returns: 更新后的错题
    func updateStatus(id: Int, status: WrongQuestion.Status) -> AnyPublisher<WrongQuestion, APIError>

    /// 记录错题重做
    /// - Parameters:
    ///   - id: 错题ID
    ///   - isCorrect: 是否正确
    /// - Returns: 更新后的错题
    func recordRetry(id: Int, isCorrect: Bool) -> AnyPublisher<WrongQuestion, APIError>

    /// 标记错题为已掌握
    /// - Parameter id: 错题ID
    /// - Returns: 成功标识
    func markAsMastered(id: Int) -> AnyPublisher<Void, APIError>

    /// 获取需要复习的错题
    /// - Parameter limit: 返回数量限制
    /// - Returns: 需要复习的错题列表
    func getQuestionsNeedReview(limit: Int) -> AnyPublisher<[WrongQuestion], APIError>

    /// 获取错题统计
    /// - Returns: 错题统计数据
    func getStatistics() -> AnyPublisher<WrongQuestionStatistics, APIError>

    /// 批量标记为已掌握
    /// - Parameter ids: 错题ID列表
    /// - Returns: 成功标识
    func batchMarkAsMastered(ids: [Int]) -> AnyPublisher<Void, APIError>

    /// 归档旧错题
    /// - Parameter daysBefore: 多少天前的错题
    /// - Returns: 归档数量
    func archiveOldQuestions(daysBefore: Int) -> AnyPublisher<Int, APIError>
}
