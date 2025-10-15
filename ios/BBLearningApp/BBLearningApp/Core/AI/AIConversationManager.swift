//
//  AIConversationManager.swift
//  BBLearning
//
//  Created by Claude Code on 2025-10-15.
//

import Foundation
import Combine

/// AI对话消息
struct AIMessage: Identifiable, Codable {
    let id: String
    let role: Role
    let content: String
    let timestamp: Date
    let questionId: Int?

    enum Role: String, Codable {
        case user = "user"
        case assistant = "assistant"
        case system = "system"
    }
}

/// AI对话管理器
class AIConversationManager: ObservableObject {
    @Published var messages: [AIMessage] = []
    @Published var isTyping: Bool = false

    private var conversationHistory: [AIMessage] = []
    private let maxHistorySize = 20

    /// 发送消息
    func sendMessage(_ content: String, questionId: Int? = nil) {
        let userMessage = AIMessage(
            id: UUID().uuidString,
            role: .user,
            content: content,
            timestamp: Date(),
            questionId: questionId
        )

        messages.append(userMessage)
        conversationHistory.append(userMessage)

        // 请求AI回复
        requestAIResponse(for: content, questionId: questionId)
    }

    /// 请求AI回复
    private func requestAIResponse(for userMessage: String, questionId: Int?) {
        isTyping = true

        // TODO: 调用后端AI接口
        // 这里使用模拟延迟
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            self?.receiveAIResponse(userMessage: userMessage, questionId: questionId)
        }
    }

    /// 接收AI回复
    private func receiveAIResponse(userMessage: String, questionId: Int?) {
        let response = generateMockResponse(for: userMessage)

        let aiMessage = AIMessage(
            id: UUID().uuidString,
            role: .assistant,
            content: response,
            timestamp: Date(),
            questionId: questionId
        )

        messages.append(aiMessage)
        conversationHistory.append(aiMessage)
        isTyping = false

        // 限制历史记录大小
        if conversationHistory.count > maxHistorySize {
            conversationHistory = Array(conversationHistory.suffix(maxHistorySize))
        }
    }

    /// 生成模拟回复
    private func generateMockResponse(for message: String) -> String {
        if message.contains("怎么解") || message.contains("如何") {
            return "让我来帮你分析这道题：\n\n1. 首先，我们需要理解题目要求\n2. 然后确定解题思路\n3. 最后按步骤计算\n\n你具体在哪一步遇到困难？"
        } else if message.contains("不懂") || message.contains("不会") {
            return "没关系，让我给你详细讲解一下相关知识点。我们可以从基础概念开始，一步步理解。"
        } else {
            return "我理解你的问题了。让我帮你逐步分析。"
        }
    }

    /// 清空对话
    func clearConversation() {
        messages.removeAll()
        conversationHistory.removeAll()
    }
}

/// 解题步骤
struct SolutionStep: Identifiable {
    let id = UUID()
    let stepNumber: Int
    let title: String
    let description: String
    let formula: String?
    let result: String?
    let explanation: String?
}

/// 解题步骤管理器
class SolutionStepManager {
    /// 解析AI返回的解题步骤
    func parseSolutionSteps(from aiResponse: String) -> [SolutionStep] {
        // TODO: 实现真实的解析逻辑
        // 这里返回模拟数据
        return [
            SolutionStep(
                stepNumber: 1,
                title: "理解题意",
                description: "分析题目给出的条件和要求",
                formula: nil,
                result: nil,
                explanation: "题目要求我们计算..."
            ),
            SolutionStep(
                stepNumber: 2,
                title: "建立方程",
                description: "根据条件列出方程式",
                formula: "2x + 5 = 15",
                result: nil,
                explanation: "根据题目条件，可以得到方程"
            ),
            SolutionStep(
                stepNumber: 3,
                title: "求解",
                description: "解方程得出答案",
                formula: "x = (15 - 5) ÷ 2",
                result: "x = 5",
                explanation: "移项后除以2得到结果"
            )
        ]
    }
}
