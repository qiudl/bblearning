//
//  AnswerFeedbackView.swift
//  BBLearning
//
//  Created by Claude Code on 2025-10-13.
//

import SwiftUI

struct AnswerFeedbackView: View {
    let feedback: AnswerFeedback

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 结果标题
            resultHeader

            // 标准答案
            standardAnswerSection

            // 解析
            if let explanation = feedback.explanation {
                explanationSection(explanation)
            }

            // 提示
            if let hints = feedback.hints, !hints.isEmpty {
                hintsSection(hints)
            }
        }
        .padding()
        .background(feedbackBackgroundColor)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(feedbackBorderColor, lineWidth: 2)
        )
    }

    // MARK: - Result Header

    private var resultHeader: some View {
        HStack(spacing: 12) {
            Image(systemName: feedback.isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                .font(.title)
                .foregroundColor(feedback.isCorrect ? .success : .error)

            VStack(alignment: .leading, spacing: 4) {
                Text(feedback.isCorrect ? "回答正确" : "回答错误")
                    .font(.headline)
                    .foregroundColor(feedback.isCorrect ? .success : .error)

                if feedback.score > 0 && feedback.score < 1 {
                    Text("得分：\(Int(feedback.score * 100))%")
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                }
            }

            Spacer()

            if feedback.isCorrect {
                Image(systemName: "hand.thumbsup.fill")
                    .font(.title2)
                    .foregroundColor(.success)
            }
        }
    }

    // MARK: - Standard Answer Section

    private var standardAnswerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("标准答案", systemImage: "doc.text")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.textSecondary)

            Text(feedback.standardAnswer)
                .font(.body)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.background)
                .cornerRadius(8)
        }
    }

    // MARK: - Explanation Section

    private func explanationSection(_ explanation: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("详细解析", systemImage: "lightbulb")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.textSecondary)

            Text(explanation)
                .font(.body)
                .lineSpacing(4)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.background)
                .cornerRadius(8)
        }
    }

    // MARK: - Hints Section

    private func hintsSection(_ hints: [String]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("提示", systemImage: "info.circle")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.textSecondary)

            VStack(alignment: .leading, spacing: 8) {
                ForEach(Array(hints.enumerated()), id: \.offset) { index, hint in
                    HStack(alignment: .top, spacing: 8) {
                        Text("\(index + 1).")
                            .font(.caption)
                            .foregroundColor(.textSecondary)

                        Text(hint)
                            .font(.caption)
                            .foregroundColor(.textSecondary)
                    }
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.background)
            .cornerRadius(8)
        }
    }

    // MARK: - Colors

    private var feedbackBackgroundColor: Color {
        if feedback.isCorrect {
            return Color.success.opacity(0.1)
        } else {
            return Color.error.opacity(0.1)
        }
    }

    private var feedbackBorderColor: Color {
        feedback.isCorrect ? .success : .error
    }
}

// MARK: - Color Extensions

extension Color {
    static let success = Color.green
    static let error = Color.red
    static let background = Color(.systemBackground)
    static let surface = Color(.secondarySystemBackground)
    static let text = Color(.label)
    static let textSecondary = Color(.secondaryLabel)
}

#if DEBUG
struct AnswerFeedbackView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // 正确答案
            AnswerFeedbackView(feedback: AnswerFeedback(
                isCorrect: true,
                score: 1.0,
                standardAnswer: "C",
                explanation: "0.5可以表示为分数1/2，因此是有理数。有理数是可以表示为两个整数之比的数。",
                hints: ["有理数包括整数和分数", "无理数包括无限不循环小数"]
            ))
            .padding()
            .previewDisplayName("正确答案")

            // 错误答案
            AnswerFeedbackView(feedback: AnswerFeedback(
                isCorrect: false,
                score: 0.0,
                standardAnswer: "C",
                explanation: "√2是无理数，不能表示为两个整数之比。而0.5 = 1/2是有理数。",
                hints: ["注意区分有理数和无理数的定义", "开方不尽的数是无理数"]
            ))
            .padding()
            .previewDisplayName("错误答案")
        }
    }
}
#endif
