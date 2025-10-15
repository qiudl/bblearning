//
//  AITutorViewModel.swift
//  BBLearning
//
//  Created by Claude Code on 2025-10-13.
//

import Foundation
import Combine
#if canImport(UIKit)
import UIKit
#endif

final class AITutorViewModel: BaseViewModel {
    @Published var messages: [ChatMessage] = []
    @Published var inputText: String = ""
    @Published var isTyping: Bool = false
    @Published var showPhotoPicker = false
    @Published var showPhotoQuestionSheet = false
    #if canImport(UIKit)
    @Published var selectedImage: UIImage?
    #endif
    @Published var recognizedQuestion: String?

    private let chatWithAIUseCase: ChatWithAIUseCase
    private var conversationId: Int?

    init(chatWithAIUseCase: ChatWithAIUseCase = DIContainer.shared.resolve(ChatWithAIUseCase.self)) {
        self.chatWithAIUseCase = chatWithAIUseCase
        super.init()
        loadWelcomeMessage()
    }

    // MARK: - Welcome Message

    private func loadWelcomeMessage() {
        let welcome = ChatMessage(
            id: UUID().uuidString,
            role: .assistant,
            content: "你好！我是你的AI数学助手。\n\n我可以帮你：\n• 解答数学问题\n• 讲解解题步骤\n• 分析错题原因\n• 推荐学习方法\n\n有什么问题尽管问我吧！📚",
            timestamp: Date(),
            imageUrl: nil
        )
        messages.append(welcome)
    }

    // MARK: - Send Message

    var canSend: Bool {
        return !inputText.trimmed.isEmpty && !isTyping
    }

    func sendMessage() {
        guard canSend else { return }

        let userMessage = ChatMessage(
            id: UUID().uuidString,
            role: .user,
            content: inputText.trimmed,
            timestamp: Date(),
            imageUrl: nil
        )

        messages.append(userMessage)
        let question = inputText
        inputText = ""

        // 开始AI回复
        isTyping = true

        executeTask(
            chatWithAIUseCase.execute(
                message: question,
                conversationId: conversationId
            ),
            onSuccess: { [weak self] response in
                self?.handleAIResponse(response)
                self?.isTyping = false
            },
            onError: { [weak self] error in
                self?.isTyping = false
                self?.showErrorMessage(error.localizedDescription)
            }
        )
    }

    private func handleAIResponse(_ response: AIMessage) {
        conversationId = response.conversationId

        let aiMessage = ChatMessage(
            id: String(response.id),
            role: .assistant,
            content: response.content,
            timestamp: response.createdAt,
            imageUrl: response.metadata?.imageUrl
        )

        messages.append(aiMessage)
    }

    private func showErrorMessage(_ errorText: String) {
        let errorMessage = ChatMessage(
            id: UUID().uuidString,
            role: .system,
            content: "抱歉，发生了错误：\(errorText)\n请稍后再试。",
            timestamp: Date(),
            imageUrl: nil
        )
        messages.append(errorMessage)
    }

    // MARK: - Photo Question

    func openPhotoPicker() {
        showPhotoPicker = true
    }

    #if canImport(UIKit)
    func processSelectedImage(_ image: UIImage) {
        selectedImage = image
        showPhotoQuestionSheet = true

        // TODO: 调用OCR识别API
        // 这里模拟识别结果
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.recognizedQuestion = "已识别题目：\n\n求解方程：2x + 5 = 15"
        }
    }
    #endif

    func submitPhotoQuestion() {
        #if canImport(UIKit)
        guard selectedImage != nil,
              let question = recognizedQuestion else { return }
        #else
        guard let question = recognizedQuestion else { return }
        #endif

        // 发送带图片的消息
        let userMessage = ChatMessage(
            id: UUID().uuidString,
            role: .user,
            content: question,
            timestamp: Date(),
            imageUrl: nil // TODO: 上传图片到服务器获取URL
        )

        messages.append(userMessage)
        showPhotoQuestionSheet = false

        // 请求AI解答
        isTyping = true

        executeTask(
            chatWithAIUseCase.execute(
                message: question,
                conversationId: conversationId
            ),
            onSuccess: { [weak self] response in
                self?.handleAIResponse(response)
                self?.isTyping = false
            },
            onError: { [weak self] error in
                self?.isTyping = false
                self?.showErrorMessage(error.localizedDescription)
            }
        )

        // 清理
        #if canImport(UIKit)
        selectedImage = nil
        #endif
        recognizedQuestion = nil
    }

    // MARK: - Quick Actions

    func sendQuickQuestion(_ question: String) {
        inputText = question
        sendMessage()
    }

    func clearConversation() {
        messages.removeAll()
        conversationId = nil
        loadWelcomeMessage()
    }

    // MARK: - Helpers

    var hasMessages: Bool {
        return messages.count > 1 // 除了欢迎消息
    }
}

// MARK: - Chat Message Model

struct ChatMessage: Identifiable, Equatable {
    let id: String
    let role: Role
    let content: String
    let timestamp: Date
    let imageUrl: String?

    enum Role: String {
        case user
        case assistant
        case system

        var displayName: String {
            switch self {
            case .user:
                return "我"
            case .assistant:
                return "AI助手"
            case .system:
                return "系统"
            }
        }
    }

    var isUser: Bool {
        return role == .user
    }

    var isAssistant: Bool {
        return role == .assistant
    }

    var isSystem: Bool {
        return role == .system
    }

    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: timestamp)
    }
}
