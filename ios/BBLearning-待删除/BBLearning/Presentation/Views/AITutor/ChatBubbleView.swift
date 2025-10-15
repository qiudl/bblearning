//
//  ChatBubbleView.swift
//  BBLearning
//
//  Created by Claude Code on 2025-10-13.
//

import SwiftUI

struct ChatBubbleView: View {
    let message: ChatMessage

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            if message.isUser {
                Spacer()
            }

            if message.isAssistant {
                avatarView
            }

            VStack(alignment: message.isUser ? .trailing : .leading, spacing: 4) {
                // 消息气泡
                bubbleContent

                // 时间戳
                Text(message.formattedTime)
                    .font(.caption2)
                    .foregroundColor(.textSecondary)
            }

            if message.isUser {
                avatarView
            } else {
                Spacer()
            }
        }
    }

    // MARK: - Avatar

    private var avatarView: some View {
        Image(systemName: message.isUser ? "person.circle.fill" : "brain.head.profile")
            .font(.title2)
            .foregroundColor(message.isUser ? .blue : .green)
            .frame(width: 36, height: 36)
    }

    // MARK: - Bubble Content

    private var bubbleContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 图片（如果有）
            if let imageUrl = message.imageUrl {
                imageView(imageUrl)
            }

            // 文本内容
            Text(message.content)
                .font(.body)
                .foregroundColor(bubbleTextColor)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(bubbleBackground)
        .cornerRadius(18)
    }

    private func imageView(_ url: String) -> some View {
        // TODO: 使用Nuke加载图片
        AsyncImage(url: URL(string: url)) { phase in
            switch phase {
            case .empty:
                ProgressView()
                    .frame(width: 200, height: 200)
            case .success(let image):
                image
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 200)
                    .cornerRadius(12)
            case .failure:
                Image(systemName: "photo")
                    .frame(width: 200, height: 200)
                    .foregroundColor(.gray)
            @unknown default:
                EmptyView()
            }
        }
    }

    // MARK: - Styling

    private var bubbleBackground: some View {
        Group {
            if message.isUser {
                Color.primary
            } else if message.isAssistant {
                Color.surface
            } else { // system
                Color.orange.opacity(0.2)
            }
        }
    }

    private var bubbleTextColor: Color {
        message.isUser ? .white : .text
    }
}

#if DEBUG
struct ChatBubbleView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 16) {
            // User message
            ChatBubbleView(message: ChatMessage(
                id: "1",
                role: .user,
                content: "如何判断一个数是否为有理数？",
                timestamp: Date(),
                imageUrl: nil
            ))

            // Assistant message
            ChatBubbleView(message: ChatMessage(
                id: "2",
                role: .assistant,
                content: "有理数的判断方法很简单：\n\n1. 能表示为两个整数之比 p/q（q≠0）的数就是有理数\n2. 有理数包括整数和分数\n3. 小数可以通过判断是否为有限小数或循环小数来确定\n\n比如：\n• 0.5 = 1/2，是有理数\n• √2 不能表示为分数，是无理数\n\n有什么不明白的地方吗？",
                timestamp: Date(),
                imageUrl: nil
            ))

            // System message
            ChatBubbleView(message: ChatMessage(
                id: "3",
                role: .system,
                content: "网络连接异常，请检查网络设置后重试。",
                timestamp: Date(),
                imageUrl: nil
            ))
        }
        .padding()
    }
}
#endif
