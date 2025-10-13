//
//  ChatWithAIUseCase.swift
//  BBLearning
//
//  Created by Claude Code on 2025-10-13.
//

import Foundation
import Combine

/// AI聊天用例
final class ChatWithAIUseCase {
    private let aiRepository: AIRepositoryProtocol

    init(aiRepository: AIRepositoryProtocol) {
        self.aiRepository = aiRepository
    }

    /// 发送消息给AI
    /// - Parameters:
    ///   - message: 用户消息
    ///   - conversationId: 会话ID（可选，新会话时不传）
    /// - Returns: AI回复
    func execute(message: String, conversationId: Int? = nil) -> AnyPublisher<AIMessage, APIError> {
        // 1. 验证消息
        guard !message.trimmed.isEmpty else {
            return Fail(error: APIError.parameterError("消息不能为空")).eraseToAnyPublisher()
        }

        guard message.count <= 2000 else {
            return Fail(error: APIError.parameterError("消息长度不能超过2000字符")).eraseToAnyPublisher()
        }

        // 2. 调用AI聊天API
        return aiRepository.chat(conversationId: conversationId, message: message)
            .handleEvents(receiveOutput: { response in
                Logger.shared.info("AI回复成功，消息长度：\(response.content.count)")
            })
            .eraseToAnyPublisher()
    }

    /// 创建新会话
    /// - Parameter title: 会话标题
    /// - Returns: 新会话
    func createConversation(title: String = "新对话") -> AnyPublisher<ChatConversation, APIError> {
        return aiRepository.createConversation(title: title)
    }

    /// 获取会话列表
    /// - Parameters:
    ///   - page: 页码
    ///   - pageSize: 每页数量
    /// - Returns: 会话列表
    func getConversations(page: Int = 1, pageSize: Int = 20) -> AnyPublisher<PagedResponse<ChatConversation>, APIError> {
        return aiRepository.getConversations(page: page, pageSize: pageSize)
    }

    /// 获取聊天历史
    /// - Parameters:
    ///   - conversationId: 会话ID
    ///   - page: 页码
    ///   - pageSize: 每页数量
    /// - Returns: 消息列表
    func getChatHistory(conversationId: Int, page: Int = 1, pageSize: Int = 50) -> AnyPublisher<PagedResponse<AIMessage>, APIError> {
        return aiRepository.getChatHistory(conversationId: conversationId, page: page, pageSize: pageSize)
    }

    /// 删除会话
    /// - Parameter conversationId: 会话ID
    /// - Returns: 成功标识
    func deleteConversation(conversationId: Int) -> AnyPublisher<Void, APIError> {
        return aiRepository.deleteConversation(conversationId: conversationId)
            .handleEvents(receiveOutput: { _ in
                Logger.shared.info("删除会话成功: \(conversationId)")
            })
            .eraseToAnyPublisher()
    }

    /// 请求AI讲解知识点
    /// - Parameters:
    ///   - knowledgePointName: 知识点名称
    ///   - conversationId: 会话ID（可选）
    /// - Returns: AI回复
    func explainKnowledgePoint(name: String, conversationId: Int? = nil) -> AnyPublisher<AIMessage, APIError> {
        let message = "请详细讲解一下「\(name)」这个知识点，包括定义、重点和常见例题。"
        return execute(message: message, conversationId: conversationId)
    }

    /// 请求AI解答题目
    /// - Parameters:
    ///   - question: 题目内容
    ///   - conversationId: 会话ID（可选）
    /// - Returns: AI回复
    func solveQuestion(question: String, conversationId: Int? = nil) -> AnyPublisher<AIMessage, APIError> {
        let message = "请帮我解答这道题：\n\(question)\n\n要求：给出详细的解题步骤和解释。"
        return execute(message: message, conversationId: conversationId)
    }

    /// 请求AI分析错误
    /// - Parameters:
    ///   - question: 题目
    ///   - userAnswer: 用户答案
    ///   - correctAnswer: 正确答案
    ///   - conversationId: 会话ID（可选）
    /// - Returns: AI回复
    func analyzeError(question: String, userAnswer: String, correctAnswer: String, conversationId: Int? = nil) -> AnyPublisher<AIMessage, APIError> {
        let message = """
        题目：\(question)

        我的答案：\(userAnswer)
        正确答案：\(correctAnswer)

        请帮我分析一下我的答案哪里错了，为什么会错，以及如何改进。
        """
        return execute(message: message, conversationId: conversationId)
    }

    /// 请求AI推荐相似题目
    /// - Parameters:
    ///   - question: 题目
    ///   - conversationId: 会话ID（可选）
    /// - Returns: AI回复
    func recommendSimilarQuestions(basedOn question: String, conversationId: Int? = nil) -> AnyPublisher<AIMessage, APIError> {
        let message = "基于这道题目，请推荐几道类似的练习题：\n\(question)"
        return execute(message: message, conversationId: conversationId)
    }
}
