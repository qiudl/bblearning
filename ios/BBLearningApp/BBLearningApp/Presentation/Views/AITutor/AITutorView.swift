//
//  AITutorView.swift
//  BBLearning
//
//  Created by Claude Code on 2025-10-13.
//

import SwiftUI

struct AITutorView: View {
    @StateObject private var viewModel = AITutorViewModel()
    @State private var showQuickActions = false

    var body: some View {
        VStack(spacing: 0) {
            // 消息列表
            messageList

            // 快捷操作（可选）
            if showQuickActions && !viewModel.hasMessages {
                quickActionsView
            }

            // 输入栏
            inputBar
        }
        .navigationTitle("AI辅导")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(action: { showQuickActions.toggle() }) {
                        Label(showQuickActions ? "隐藏快捷操作" : "显示快捷操作", systemImage: "bolt")
                    }

                    Button(role: .destructive, action: viewModel.clearConversation) {
                        Label("清空对话", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $viewModel.showPhotoPicker) {
            ImagePicker(image: $viewModel.selectedImage) { image in
                viewModel.processSelectedImage(image)
            }
        }
        .sheet(isPresented: $viewModel.showPhotoQuestionSheet) {
            if let image = viewModel.selectedImage {
                PhotoQuestionView(
                    image: image,
                    recognizedText: viewModel.recognizedQuestion ?? "识别中...",
                    onSubmit: viewModel.submitPhotoQuestion,
                    onCancel: {
                        viewModel.showPhotoQuestionSheet = false
                        viewModel.selectedImage = nil
                        viewModel.recognizedQuestion = nil
                    }
                )
            }
        }
    }

    // MARK: - Message List

    private var messageList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(viewModel.messages) { message in
                        ChatBubbleView(message: message)
                            .id(message.id)
                    }

                    // AI正在输入
                    if viewModel.isTyping {
                        typingIndicator
                    }
                }
                .padding()
            }
            .onChange(of: viewModel.messages.count) { _ in
                // 自动滚动到最新消息
                if let lastMessage = viewModel.messages.last {
                    withAnimation {
                        proxy.scrollTo(lastMessage.id, anchor: .bottom)
                    }
                }
            }
        }
    }

    private var typingIndicator: some View {
        HStack {
            HStack(spacing: 4) {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(Color.gray)
                        .frame(width: 8, height: 8)
                        .scaleEffect(viewModel.isTyping ? 1 : 0.5)
                        .animation(
                            Animation.easeInOut(duration: 0.6)
                                .repeatForever()
                                .delay(Double(index) * 0.2),
                            value: viewModel.isTyping
                        )
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.gray.opacity(0.2))
            .cornerRadius(20)

            Spacer()
        }
    }

    // MARK: - Quick Actions

    private var quickActionsView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                QuickActionButton(
                    title: "讲解知识点",
                    icon: "book"
                ) {
                    viewModel.sendQuickQuestion("请帮我讲解一下有理数的概念")
                }

                QuickActionButton(
                    title: "解答疑问",
                    icon: "questionmark.circle"
                ) {
                    viewModel.sendQuickQuestion("如何判断一个数是否为有理数？")
                }

                QuickActionButton(
                    title: "分析错题",
                    icon: "exclamationmark.triangle"
                ) {
                    viewModel.sendQuickQuestion("为什么我总是把有理数和无理数搞混？")
                }

                QuickActionButton(
                    title: "学习方法",
                    icon: "lightbulb"
                ) {
                    viewModel.sendQuickQuestion("有什么好的数学学习方法？")
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
        .background(Color.surface)
    }

    // MARK: - Input Bar

    private var inputBar: some View {
        HStack(spacing: 12) {
            // 拍照按钮
            Button(action: viewModel.openPhotoPicker) {
                Image(systemName: "camera.fill")
                    .font(.title3)
                    .foregroundColor(.primary)
            }

            // 输入框
            HStack {
                if #available(iOS 16.0, *) {
                    TextField("输入问题...", text: $viewModel.inputText, axis: .vertical)
                        .textFieldStyle(PlainTextFieldStyle())
                        .lineLimit(1...5)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                } else {
                    TextField("输入问题...", text: $viewModel.inputText)
                        .textFieldStyle(PlainTextFieldStyle())
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                }
            }
            .background(Color.surface)
            .cornerRadius(20)

            // 发送按钮
            Button(action: viewModel.sendMessage) {
                Image(systemName: viewModel.canSend ? "arrow.up.circle.fill" : "arrow.up.circle")
                    .font(.title2)
                    .foregroundColor(viewModel.canSend ? .primary : .gray)
            }
            .disabled(!viewModel.canSend)
        }
        .padding()
        .background(Color.background)
        .shadow(color: .black.opacity(0.1), radius: 5, y: -2)
    }
}

// MARK: - Quick Action Button

struct QuickActionButton: View {
    let title: String
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.caption)

                Text(title)
                    .font(.subheadline)
            }
            .foregroundColor(.primary)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color.background)
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.primary.opacity(0.3), lineWidth: 1)
            )
        }
    }
}

#if DEBUG
struct AITutorView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            AITutorView()
        }
    }
}
#endif
