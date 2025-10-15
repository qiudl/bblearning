//
//  WrongQuestionDetailView.swift
//  BBLearning
//
//  Created by Claude Code on 2025-10-13.
//

import SwiftUI

struct WrongQuestionDetailView: View {
    let wrongQuestion: WrongQuestion
    @State private var showRetryView = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // 状态信息
                statusSection

                // 题目内容
                questionSection

                // 你的错误答案
                wrongAnswerSection

                // 正确答案
                correctAnswerSection

                // 错因分析（使用AI评分反馈作为分析）
                if let analysis = wrongQuestion.practiceRecord?.aiGrade?.feedback, !analysis.isEmpty {
                    analysisSection(analysis)
                }

                // 复习记录
                retryHistorySection

                // 操作按钮
                actionButtons
            }
            .padding()
        }
        .navigationTitle("错题详情")
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(isPresented: $showRetryView) {
            if let question = wrongQuestion.question {
                QuestionView(questions: [question])
            }
        }
    }

    // MARK: - Status Section

    private var statusSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    StatusBadge(status: wrongQuestion.status)

                    if wrongQuestion.needsReview {
                        Label("需复习", systemImage: "bell.fill")
                            .font(.caption)
                            .foregroundColor(.orange)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color.orange.opacity(0.2))
                            .cornerRadius(8)
                    }
                }

                Text("错误时间：\(wrongQuestion.createdAt.formatted())")
                    .font(.caption)
                    .foregroundColor(.textSecondary)

                if let lastRetry = wrongQuestion.lastRetryTime {
                    Text("上次复习：\(lastRetry.formatted())")
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text("复习 \\(wrongQuestion.retryCount) 次")
                    .font(.title3)
                    .bold()

                Text(retryProgressText)
                    .font(.caption)
                    .foregroundColor(.textSecondary)
            }
        }
        .padding()
        .background(Color.surface)
        .cornerRadius(12)
    }

    private var retryProgressText: String {
        let intervals = [1, 3, 7, 14, 30]
        guard wrongQuestion.retryCount < intervals.count else {
            return "已完成所有复习"
        }
        return "下次复习：\(intervals[wrongQuestion.retryCount])天后"
    }

    // MARK: - Question Section

    private var questionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("题目")
                .font(.headline)

            VStack(alignment: .leading, spacing: 12) {
                if let question = wrongQuestion.question {
                    Text(question.content.stem)
                        .font(.body)
                }

                if let options = wrongQuestion.question?.content.options {
                    ForEach(Array(options.enumerated()), id: \.offset) { index, option in
                        HStack {
                            Text(String(UnicodeScalar(65 + index)!))
                                .font(.caption)
                                .foregroundColor(.white)
                                .frame(width: 24, height: 24)
                                .background(Color.gray)
                                .cornerRadius(12)

                            Text(option)
                                .font(.body)
                        }
                    }
                }
            }
            .padding()
            .background(Color.surface)
            .cornerRadius(12)
        }
    }

    // MARK: - Wrong Answer Section

    private var wrongAnswerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("你的答案", systemImage: "xmark.circle.fill")
                .font(.headline)
                .foregroundColor(.error)

            Text(wrongQuestion.practiceRecord?.userAnswer ?? "-")
                .font(.body)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.error.opacity(0.1))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.error, lineWidth: 1)
                )
        }
    }

    // MARK: - Correct Answer Section

    private var correctAnswerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("正确答案", systemImage: "checkmark.circle.fill")
                .font(.headline)
                .foregroundColor(.success)

            VStack(alignment: .leading, spacing: 12) {
                Text(wrongQuestion.question?.answer.content ?? "-")
                    .font(.body)
                    .bold()

                if let steps = wrongQuestion.question?.answer.steps, !steps.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("解题步骤：")
                            .font(.subheadline)
                            .bold()

                        ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                            HStack(alignment: .top, spacing: 8) {
                                Text("\(index + 1).")
                                    .font(.caption)
                                    .foregroundColor(.textSecondary)

                                Text(step)
                                    .font(.caption)
                            }
                        }
                    }
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.success.opacity(0.1))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.success, lineWidth: 1)
            )
        }
    }

    // MARK: - Analysis Section

    private func analysisSection(_ analysis: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("错因分析", systemImage: "lightbulb.fill")
                .font(.headline)
                .foregroundColor(.orange)

            Text(analysis)
                .font(.body)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(12)
        }
    }

    // MARK: - Retry History

    private var retryHistorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("复习计划（艾宾浩斯遗忘曲线）")
                .font(.headline)

            VStack(spacing: 8) {
                RetryPlanRow(day: 1, isCompleted: wrongQuestion.retryCount >= 1)
                RetryPlanRow(day: 3, isCompleted: wrongQuestion.retryCount >= 2)
                RetryPlanRow(day: 7, isCompleted: wrongQuestion.retryCount >= 3)
                RetryPlanRow(day: 14, isCompleted: wrongQuestion.retryCount >= 4)
                RetryPlanRow(day: 30, isCompleted: wrongQuestion.retryCount >= 5)
            }
            .padding()
            .background(Color.surface)
            .cornerRadius(12)
        }
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        VStack(spacing: 12) {
            CustomButton(
                title: "立即复习",
                action: { showRetryView = true }
            )

            if wrongQuestion.status != .mastered {
                Button(action: {
                    // TODO: 标记为已掌握
                }) {
                    Text("标记为已掌握")
                        .font(.headline)
                        .foregroundColor(.success)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.success.opacity(0.1))
                        .cornerRadius(12)
                }
            }
        }
    }
}

// MARK: - Retry Plan Row

struct RetryPlanRow: View {
    let day: Int
    let isCompleted: Bool

    var body: some View {
        HStack {
            Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                .foregroundColor(isCompleted ? .success : .gray)

            Text("第 \(day) 天")
                .font(.body)
                .foregroundColor(isCompleted ? .textSecondary : .text)

            Spacer()

            if isCompleted {
                Text("已完成")
                    .font(.caption)
                    .foregroundColor(.success)
            } else {
                Text("未完成")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
    }
}

#if DEBUG
struct WrongQuestionDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            WrongQuestionDetailView(wrongQuestion: WrongQuestion.mock)
        }
    }
}
#endif
