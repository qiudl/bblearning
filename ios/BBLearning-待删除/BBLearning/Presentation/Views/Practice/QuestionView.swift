//
//  QuestionView.swift
//  BBLearning
//
//  Created by Claude Code on 2025-10-13.
//

import SwiftUI

struct QuestionView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel: QuestionAnswerViewModel

    init(questions: [Question]) {
        _viewModel = StateObject(wrappedValue: QuestionAnswerViewModel(questions: questions))
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 进度条
                progressBar

                // 题目内容
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // 题目信息
                        questionHeader

                        // 题目内容
                        questionContent

                        // 答案输入
                        answerInput

                        // 反馈
                        if let feedback = viewModel.feedback {
                            AnswerFeedbackView(feedback: feedback)
                        }
                    }
                    .padding()
                }

                // 底部操作栏
                bottomToolbar
            }
            .navigationTitle("答题")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { viewModel.exitPractice() }) {
                        Image(systemName: "xmark")
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    questionNavigator
                }
            }
            .alert("退出练习", isPresented: $viewModel.showExitAlert) {
                Button("取消", role: .cancel) {}
                Button("确定", role: .destructive) {
                    viewModel.confirmExit()
                    dismiss()
                }
            } message: {
                Text("当前进度将不会保存，确定要退出吗？")
            }
            .fullScreenCover(isPresented: $viewModel.showResultView) {
                if let result = viewModel.practiceResult {
                    PracticeResultView(result: result)
                }
            }
        }
    }

    // MARK: - Progress Bar

    private var progressBar: some View {
        VStack(spacing: 8) {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))

                    Rectangle()
                        .fill(Color.primary)
                        .frame(width: geometry.size.width * CGFloat(viewModel.progress))
                }
            }
            .frame(height: 4)

            HStack {
                Text(viewModel.progressText)
                    .font(.caption)
                    .foregroundColor(.textSecondary)

                Spacer()

                Text("\(Int(viewModel.progress * 100))%")
                    .font(.caption)
                    .foregroundColor(.textSecondary)
            }
            .padding(.horizontal)
        }
        .padding(.bottom, 8)
    }

    // MARK: - Question Header

    private var questionHeader: some View {
        HStack {
            // 难度标签
            HStack(spacing: 4) {
                Image(systemName: "star.fill")
                    .font(.caption)
                Text(viewModel.currentQuestion.difficulty.displayName)
                    .font(.caption)
            }
            .foregroundColor(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(difficultyColor)
            .cornerRadius(8)

            Spacer()

            // 题型标签
            Text(viewModel.currentQuestion.type.displayName)
                .font(.caption)
                .foregroundColor(.textSecondary)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Color.surface)
                .cornerRadius(8)
        }
    }

    private var difficultyColor: Color {
        switch viewModel.currentQuestion.difficulty {
        case .easy:
            return .green
        case .medium:
            return .orange
        case .hard:
            return .red
        }
    }

    // MARK: - Question Content

    private var questionContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("题目 \\(viewModel.currentIndex + 1)")
                .font(.title3)
                .bold()

            // 题目文本
            Text(viewModel.currentQuestion.content.stem)
                .font(.body)
                .lineSpacing(6)

            // TODO: 支持LaTeX公式渲染（使用KaTeX）
            // TODO: 支持图片显示

            // 选择题选项
            if viewModel.currentQuestion.type == .choice,
               let options = viewModel.currentQuestion.content.options {
                optionsView(options)
            }
        }
        .padding()
        .background(Color.surface)
        .cornerRadius(12)
    }

    private func optionsView(_ options: [String]) -> some View {
        VStack(spacing: 12) {
            ForEach(Array(options.enumerated()), id: \.offset) { index, option in
                optionButton(index: index, text: option)
            }
        }
    }

    private func optionButton(index: Int, text: String) -> some View {
        let optionLabel = String(UnicodeScalar(65 + index)!) // A, B, C, D
        let isSelected = viewModel.currentUserAnswer == optionLabel

        return Button(action: {
            viewModel.currentUserAnswer = optionLabel
        }) {
            HStack(spacing: 12) {
                Text(optionLabel)
                    .font(.headline)
                    .foregroundColor(isSelected ? .white : .text)
                    .frame(width: 30, height: 30)
                    .background(isSelected ? Color.primary : Color.gray.opacity(0.2))
                    .cornerRadius(15)

                Text(text)
                    .font(.body)
                    .foregroundColor(.text)
                    .multilineTextAlignment(.leading)

                Spacer()
            }
            .padding()
            .background(isSelected ? Color.primary.opacity(0.1) : Color.clear)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? Color.primary : Color.gray.opacity(0.3), lineWidth: 1.5)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - Answer Input

    private var answerInput: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("你的答案")
                .font(.headline)

            if viewModel.currentQuestion.type == .choice {
                Text(viewModel.currentUserAnswer.isEmpty ? "请选择答案" : "已选择：\(viewModel.currentUserAnswer)")
                    .font(.body)
                    .foregroundColor(viewModel.currentUserAnswer.isEmpty ? .textSecondary : .primary)
            } else {
                TextEditor(text: $viewModel.currentUserAnswer)
                    .frame(minHeight: 100)
                    .padding(8)
                    .background(Color.surface)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                    .disabled(viewModel.isAnswered)
            }

            // 提交按钮
            if !viewModel.isAnswered {
                CustomButton(
                    title: "提交答案",
                    action: viewModel.submitAnswer,
                    isEnabled: viewModel.canSubmit,
                    isLoading: viewModel.isLoading
                )
            }
        }
    }

    // MARK: - Question Navigator

    private var questionNavigator: some View {
        Menu {
            ForEach(0..<viewModel.questions.count, id: \.self) { index in
                Button(action: {
                    viewModel.currentIndex = index
                }) {
                    HStack {
                        Text("第 \(index + 1) 题")

                        if viewModel.isQuestionAnswered(index) {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "list.bullet")
                Text("题目")
            }
        }
    }

    // MARK: - Bottom Toolbar

    private var bottomToolbar: some View {
        HStack(spacing: 16) {
            // 上一题
            Button(action: viewModel.previousQuestion) {
                HStack {
                    Image(systemName: "chevron.left")
                    Text("上一题")
                }
                .font(.body)
                .foregroundColor(viewModel.hasPrevious ? .primary : .gray)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.surface)
                .cornerRadius(10)
            }
            .disabled(!viewModel.hasPrevious)

            // 下一题 / 完成
            Button(action: {
                if viewModel.hasNext {
                    viewModel.nextQuestion()
                } else {
                    viewModel.finishPractice()
                }
            }) {
                HStack {
                    Text(viewModel.hasNext ? "下一题" : "完成")
                    if viewModel.hasNext {
                        Image(systemName: "chevron.right")
                    } else {
                        Image(systemName: "checkmark")
                    }
                }
                .font(.body)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.primary)
                .cornerRadius(10)
            }
        }
        .padding()
        .background(Color.background)
        .shadow(color: .black.opacity(0.1), radius: 5, y: -2)
    }
}

// MARK: - Extensions

extension Question.QuestionType {
    var displayName: String {
        switch self {
        case .choice:
            return "选择题"
        case .fillBlank:
            return "填空题"
        case .shortAnswer:
            return "简答题"
        }
    }
}

#if DEBUG
struct QuestionView_Previews: PreviewProvider {
    static var previews: some View {
        QuestionView(questions: [Question.mock()])
    }
}

extension Question {
    static func mock() -> Question {
        Question(
            id: 1,
            knowledgePointId: 1,
            type: .choice,
            difficulty: .medium,
            content: QuestionContent(
                stem: "下列各数中，是有理数的是（  ）",
                options: ["A. √2", "B. π", "C. 0.5", "D. √3"],
                images: nil,
                blanks: nil,
                tips: "有理数定义：可表示为两个整数之比"
            ),
            answer: Answer(
                content: "C",
                steps: ["有理数是可以表示为两个整数之比的数", "0.5 = 1/2，是有理数"],
                keyPoints: ["有理数的定义"],
                commonMistakes: ["将无理数误判为有理数"]
            ),
            points: 5,
            createdAt: Date(),
            updatedAt: Date()
        )
    }
}
#endif
