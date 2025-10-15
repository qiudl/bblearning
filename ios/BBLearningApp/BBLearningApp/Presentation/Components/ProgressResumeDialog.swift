//
//  ProgressResumeDialog.swift
//  BBLearning
//
//  Created by Claude Code on 2025-10-15.
//

import SwiftUI

/// 进度恢复对话框
struct ProgressResumeDialog: View {
    let progress: PracticeProgress
    let onResume: () -> Void
    let onDiscard: () -> Void
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(spacing: 24) {
            // 图标
            Image(systemName: "arrow.clockwise.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.blue)

            // 标题
            Text("发现未完成的练习")
                .font(.title2)
                .fontWeight(.bold)

            // 进度信息
            VStack(spacing: 12) {
                InfoRow(
                    label: "练习模式",
                    value: progress.mode.displayName,
                    icon: progress.mode.icon
                )

                InfoRow(
                    label: "已完成",
                    value: "\(progress.currentIndex)/\(progress.targetCount) 题",
                    icon: "checkmark.circle"
                )

                InfoRow(
                    label: "保存时间",
                    value: progress.savedAt.formatted(date: .abbreviated, time: .shortened),
                    icon: "clock"
                )

                // 进度条
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("进度")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        Spacer()

                        Text("\(progressPercentage)%")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.blue)
                    }

                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.gray.opacity(0.2))

                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.blue)
                                .frame(width: geometry.size.width * CGFloat(progressPercentage) / 100.0)
                        }
                    }
                    .frame(height: 8)
                }
                .padding(.top, 8)
            }
            .padding()
            .background(Color.surface)
            .cornerRadius(12)

            // 按钮
            VStack(spacing: 12) {
                Button(action: {
                    dismiss()
                    onResume()
                }) {
                    HStack {
                        Image(systemName: "play.fill")
                        Text("继续练习")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        LinearGradient(
                            colors: [Color.blue, Color.purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }

                Button(action: {
                    dismiss()
                    onDiscard()
                }) {
                    HStack {
                        Image(systemName: "xmark")
                        Text("放弃并开始新练习")
                            .fontWeight(.medium)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.secondary.opacity(0.1))
                    .foregroundColor(.secondary)
                    .cornerRadius(12)
                }
            }
        }
        .padding(24)
    }

    private var progressPercentage: Int {
        guard progress.targetCount > 0 else { return 0 }
        return Int(Double(progress.currentIndex) / Double(progress.targetCount) * 100)
    }
}

// MARK: - Info Row

struct InfoRow: View {
    let label: String
    let value: String
    let icon: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 24)

            Text(label)
                .foregroundColor(.secondary)

            Spacer()

            Text(value)
                .fontWeight(.medium)
        }
        .font(.subheadline)
    }
}

// MARK: - Preview

#if DEBUG
struct ProgressResumeDialog_Previews: PreviewProvider {
    static var previews: some View {
        let progress = PracticeProgress(
            sessionId: "test-session",
            mode: .standard,
            questions: [],
            currentIndex: 7,
            answers: [],
            startTime: Date().addingTimeInterval(-1800),
            savedAt: Date(),
            knowledgePointIds: [11, 12],
            targetCount: 10
        )

        ProgressResumeDialog(
            progress: progress,
            onResume: {},
            onDiscard: {}
        )
        .previewLayout(.sizeThatFits)
    }
}
#endif
