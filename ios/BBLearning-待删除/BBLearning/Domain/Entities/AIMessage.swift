//
//  AIMessage.swift
//  BBLearning
//
//  Created by Claude Code on 2025-10-13.
//

import Foundation

/// AI消息实体
struct AIMessage: Identifiable, Codable, Equatable {
    let id: Int
    let conversationId: Int
    let role: MessageRole
    var content: String
    var messageType: MessageType
    var metadata: MessageMetadata?
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case conversationId = "conversation_id"
        case role
        case content
        case messageType = "message_type"
        case metadata
        case createdAt = "created_at"
    }

    /// 消息角色
    enum MessageRole: String, Codable {
        case user = "user"
        case assistant = "assistant"
        case system = "system"

        var displayName: String {
            switch self {
            case .user: return "我"
            case .assistant: return "AI老师"
            case .system: return "系统"
            }
        }

        var isUser: Bool {
            return self == .user
        }

        var isAssistant: Bool {
            return self == .assistant
        }
    }

    /// 消息类型
    enum MessageType: String, Codable {
        case text = "text"                    // 文本消息
        case image = "image"                  // 图片消息（拍照识题）
        case question = "question"            // 题目相关
        case explanation = "explanation"      // 知识点讲解
        case diagnosis = "diagnosis"          // 学习诊断
        case recommendation = "recommendation" // 推荐内容

        var displayText: String {
            switch self {
            case .text: return "文本"
            case .image: return "图片"
            case .question: return "题目"
            case .explanation: return "讲解"
            case .diagnosis: return "诊断"
            case .recommendation: return "推荐"
            }
        }

        var icon: String {
            switch self {
            case .text: return "text.bubble"
            case .image: return "photo"
            case .question: return "questionmark.circle"
            case .explanation: return "book"
            case .diagnosis: return "stethoscope"
            case .recommendation: return "lightbulb"
            }
        }
    }
}

// MARK: - Message Metadata

/// 消息元数据
struct MessageMetadata: Codable, Equatable {
    var imageUrl: String?                 // 图片URL（拍照识题）
    var questionId: Int?                  // 关联题目ID
    var knowledgePointIds: [Int]?         // 关联知识点ID
    var relatedQuestions: [Int]?          // 相关题目
    var confidence: Double?               // AI置信度（0-1）
    var processingTime: Double?           // 处理耗时（秒）
}

// MARK: - Chat Conversation

/// 聊天会话
struct ChatConversation: Identifiable, Codable, Equatable {
    let id: Int
    let userId: Int
    var title: String
    var messages: [AIMessage]?
    var context: ConversationContext?
    let createdAt: Date
    var updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case title
        case messages
        case context
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    /// 消息数量
    var messageCount: Int {
        return messages?.count ?? 0
    }

    /// 最后一条消息
    var lastMessage: AIMessage? {
        return messages?.last
    }

    /// 最后更新时间描述
    var lastUpdateText: String {
        return updatedAt.relativeString()
    }

    /// 是否为空会话
    var isEmpty: Bool {
        return messageCount == 0
    }
}

// MARK: - Conversation Context

/// 会话上下文（用于维持对话连贯性）
struct ConversationContext: Codable, Equatable {
    var currentTopic: String?             // 当前话题
    var knowledgePointIds: [Int]?         // 讨论的知识点
    var difficulty: String?               // 难度级别
    var recentQuestions: [Int]?           // 最近讨论的题目
    var userPreferences: UserPreferences? // 用户偏好
}

/// 用户偏好
struct UserPreferences: Codable, Equatable {
    var verboseLevel: VerboseLevel       // 详细程度
    var examplePreference: Bool          // 是否喜欢举例
    var stepByStep: Bool                 // 是否需要分步讲解

    enum VerboseLevel: String, Codable {
        case brief = "brief"             // 简洁
        case normal = "normal"           // 正常
        case detailed = "detailed"       // 详细

        var displayText: String {
            switch self {
            case .brief: return "简洁"
            case .normal: return "正常"
            case .detailed: return "详细"
            }
        }
    }
}

// MARK: - Extensions

extension AIMessage {
    /// 是否有图片
    var hasImage: Bool {
        return metadata?.imageUrl != nil
    }

    /// 是否关联题目
    var hasQuestion: Bool {
        return metadata?.questionId != nil
    }

    /// 是否有相关题目推荐
    var hasRelatedQuestions: Bool {
        return metadata?.relatedQuestions != nil && !metadata!.relatedQuestions!.isEmpty
    }

    /// 置信度文本
    var confidenceText: String? {
        guard let confidence = metadata?.confidence else { return nil }
        let percentage = Int(confidence * 100)
        return "\(percentage)%"
    }

    /// 内容预览（用于列表显示）
    var preview: String {
        let maxLength = 50
        if content.count > maxLength {
            let index = content.index(content.startIndex, offsetBy: maxLength)
            return String(content[..<index]) + "..."
        }
        return content
    }
}

extension ChatConversation {
    /// 会话摘要（首条用户消息）
    var summary: String {
        guard let messages = messages else { return title }
        let firstUserMessage = messages.first { $0.role == .user }
        return firstUserMessage?.preview ?? title
    }
}

// MARK: - Mock Data

#if DEBUG
extension AIMessage {
    static let mockUser = AIMessage(
        id: 1,
        conversationId: 1,
        role: .user,
        content: "我不太理解有理数加法的符号法则，能帮我讲解一下吗？",
        messageType: .text,
        metadata: nil,
        createdAt: Date()
    )

    static let mockAssistant = AIMessage(
        id: 2,
        conversationId: 1,
        role: .assistant,
        content: "当然可以！有理数加法的符号法则主要分为两种情况：\n\n1. **同号两数相加**：取相同的符号，并把绝对值相加。\n   例如：(+3) + (+5) = +8，(-3) + (-5) = -8\n\n2. **异号两数相加**：取绝对值较大的加数的符号，并用较大的绝对值减去较小的绝对值。\n   例如：(+5) + (-3) = +2，(-5) + (+3) = -2\n\n你可以通过一些练习题来巩固这个知识点，需要我为你生成几道练习题吗？",
        messageType: .explanation,
        metadata: MessageMetadata(
            imageUrl: nil,
            questionId: nil,
            knowledgePointIds: [12],
            relatedQuestions: [1, 2, 3],
            confidence: 0.95,
            processingTime: 1.2
        ),
        createdAt: Date()
    )

    static let mockImage = AIMessage(
        id: 3,
        conversationId: 1,
        role: .user,
        content: "[图片识别中...]",
        messageType: .image,
        metadata: MessageMetadata(
            imageUrl: "https://example.com/image.jpg",
            questionId: nil,
            knowledgePointIds: nil,
            relatedQuestions: nil,
            confidence: nil,
            processingTime: nil
        ),
        createdAt: Date()
    )

    static let mockList: [AIMessage] = [mockUser, mockAssistant]
}

extension ChatConversation {
    static let mock = ChatConversation(
        id: 1,
        userId: 1,
        title: "有理数加法讨论",
        messages: AIMessage.mockList,
        context: ConversationContext(
            currentTopic: "有理数加法",
            knowledgePointIds: [12],
            difficulty: "medium",
            recentQuestions: [1, 2],
            userPreferences: UserPreferences(
                verboseLevel: .normal,
                examplePreference: true,
                stepByStep: true
            )
        ),
        createdAt: Date(),
        updatedAt: Date()
    )

    static let mockList: [ChatConversation] = [
        mock,
        ChatConversation(
            id: 2,
            userId: 1,
            title: "整式加减运算",
            messages: nil,
            context: nil,
            createdAt: Date().addingTimeInterval(-86400),
            updatedAt: Date().addingTimeInterval(-86400)
        )
    ]
}
#endif
