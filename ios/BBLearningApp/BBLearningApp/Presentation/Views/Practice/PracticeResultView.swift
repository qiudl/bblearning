//
//  PracticeResultView.swift
//  BBLearning
//
//  Created by Claude Code on 2025-10-13.
//

import SwiftUI

struct PracticeResultView: View {
    @Environment(\.dismiss) var dismiss
    let result: PracticeResult

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 32) {
                    // 成绩展示
                    scoreSection

                    // 统计卡片
                    statsSection

                    // 评级
                    gradeSection

                    // 操作按钮
                    actionButtons
                }
                .padding()
            }
            .background(Color.background.ignoresSafeArea())
            .navigationTitle("练习结果")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
        }
    }

    // MARK: - Score Section

    private var scoreSection: some View {
        VStack(spacing: 16) {
            // 成绩圆环
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 15)
                    .frame(width: 160, height: 160)

                Circle()
                    .trim(from: 0, to: CGFloat(result.accuracy))
                    .stroke(gradeColor, style: StrokeStyle(lineWidth: 15, lineCap: .round))
                    .frame(width: 160, height: 160)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 1.0), value: result.accuracy)

                VStack(spacing: 4) {
                    Text(result.accuracyText)
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(gradeColor)

                    Text("正确率")
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                }
            }
            .padding(.top, 20)

            // 得分
            Text("\(result.correctCount)/\(result.totalQuestions) 题")
                .font(.title3)
                .foregroundColor(.textSecondary)
        }
        .padding()
        .background(Color.surface)
        .cornerRadius(16)
    }

    // MARK: - Stats Section

    private var statsSection: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                StatCard(
                    title: "总题数",
                    value: "\(result.totalQuestions)",
                    icon: "doc.text",
                    color: .blue
                )

                StatCard(
                    title: "已答",
                    value: "\(result.answeredCount)",
                    icon: "checkmark.circle",
                    color: .green
                )
            }

            HStack(spacing: 12) {
                StatCard(
                    title: "正确",
                    value: "\(result.correctCount)",
                    icon: "checkmark.circle.fill",
                    color: .success
                )

                StatCard(
                    title: "错误",
                    value: "\(result.answeredCount - result.correctCount)",
                    icon: "xmark.circle.fill",
                    color: .error
                )
            }

            if result.totalTime > 0 {
                StatCard(
                    title: "用时",
                    value: formatTime(result.totalTime),
                    icon: "clock",
                    color: .orange,
                    isFullWidth: true
                )
            }
        }
    }

    // MARK: - Grade Section

    private var gradeSection: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: gradeIcon)
                    .font(.system(size: 40))
                    .foregroundColor(gradeColor)

                VStack(alignment: .leading, spacing: 4) {
                    Text("评级")
                        .font(.caption)
                        .foregroundColor(.textSecondary)

                    Text(result.grade.displayName)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(gradeColor)
                }

                Spacer()
            }
            .padding()
            .background(gradeColor.opacity(0.1))
            .cornerRadius(12)

            // 鼓励语
            Text(encouragementText)
                .font(.body)
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.surface)
                .cornerRadius(12)
        }
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        VStack(spacing: 12) {
            // 查看错题
            if result.correctCount < result.answeredCount {
                Button(action: {
                    // TODO: 跳转到错题详情
                }) {
                    HStack {
                        Image(systemName: "exclamationmark.triangle")
                        Text("查看错题 (\(result.answeredCount - result.correctCount))")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.orange)
                    .cornerRadius(12)
                }
            }

            // 再来一次
            Button(action: {
                // TODO: 重新开始练习
                dismiss()
            }) {
                HStack {
                    Image(systemName: "arrow.clockwise")
                    Text("再来一次")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.primary)
                .cornerRadius(12)
            }

            // 返回首页
            Button(action: {
                dismiss()
            }) {
                Text("返回")
                    .font(.headline)
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.surface)
                    .cornerRadius(12)
            }
        }
    }

    // MARK: - Helpers

    private var gradeColor: Color {
        switch result.grade {
        case .excellent:
            return .green
        case .good:
            return .blue
        case .pass:
            return .orange
        case .fail:
            return .red
        }
    }

    private var gradeIcon: String {
        switch result.grade {
        case .excellent:
            return "star.fill"
        case .good:
            return "hand.thumbsup.fill"
        case .pass:
            return "checkmark.seal"
        case .fail:
            return "exclamationmark.triangle"
        }
    }

    private var encouragementText: String {
        switch result.grade {
        case .excellent:
            return "太棒了！你已经完全掌握了这些知识点！继续保持！"
        case .good:
            return "做得很好！继续努力，你会更优秀！"
        case .pass:
            return "不错的开始！多加练习会更好哦！"
        case .fail:
            return "加油！相信自己，多练习就会进步！"
        }
    }

    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        if minutes > 0 {
            return "\(minutes)分\(seconds)秒"
        } else {
            return "\(seconds)秒"
        }
    }
}

// MARK: - Stat Card

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    var isFullWidth: Bool = false

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 40)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.textSecondary)

                Text(value)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.text)
            }

            if !isFullWidth {
                Spacer()
            }
        }
        .padding()
        .frame(maxWidth: isFullWidth ? .infinity : nil)
        .background(Color.surface)
        .cornerRadius(12)
    }
}

#if DEBUG
struct PracticeResultView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // 优秀
            PracticeResultView(result: PracticeResult(
                totalQuestions: 10,
                answeredCount: 10,
                correctCount: 9,
                totalTime: 450,
                knowledgePoints: [1, 2, 3]
            ))
            .previewDisplayName("优秀")

            // 及格
            PracticeResultView(result: PracticeResult(
                totalQuestions: 10,
                answeredCount: 10,
                correctCount: 6,
                totalTime: 600,
                knowledgePoints: [1, 2]
            ))
            .previewDisplayName("及格")

            // 不及格
            PracticeResultView(result: PracticeResult(
                totalQuestions: 10,
                answeredCount: 8,
                correctCount: 3,
                totalTime: 300,
                knowledgePoints: [1]
            ))
            .previewDisplayName("不及格")
        }
    }
}
#endif
