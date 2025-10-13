//
//  KnowledgeDetailView.swift
//  BBLearning
//
//  Created by Claude Code on 2025-10-13.
//

import SwiftUI

struct KnowledgeDetailView: View {
    @StateObject private var viewModel: KnowledgeDetailViewModel
    @State private var showPractice = false

    init(knowledgePoint: KnowledgePoint) {
        _viewModel = StateObject(wrappedValue: KnowledgeDetailViewModel(knowledgePoint: knowledgePoint))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // 标题和难度
                headerSection

                // 进度统计
                if viewModel.knowledgePoint.progress != nil {
                    progressSection
                }

                // 描述
                if let description = viewModel.knowledgePoint.description {
                    descriptionSection(description)
                }

                // 子知识点
                if !viewModel.children.isEmpty {
                    childrenSection
                }

                // 操作按钮
                actionButtons
            }
            .padding()
        }
        .navigationTitle(viewModel.knowledgePoint.name)
        .navigationBarTitleDisplayMode(.large)
        .errorAlert(error: $viewModel.errorMessage)
        .sheet(isPresented: $showPractice) {
            // TODO: 在 Task #2426 中实现 PracticeView
            Text("练习模块")
        }
        .refreshable {
            viewModel.refresh()
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        HStack(spacing: 16) {
            // 难度指示器
            DifficultyBadge(difficulty: viewModel.knowledgePoint.difficulty)

            VStack(alignment: .leading, spacing: 4) {
                Text("难度等级")
                    .font(.caption)
                    .foregroundColor(.textSecondary)

                Text(viewModel.knowledgePoint.difficulty.displayName)
                    .font(.headline)
            }

            Spacer()

            // 年级标签
            GradeBadge(grade: viewModel.knowledgePoint.grade)
        }
        .padding()
        .background(Color.surface)
        .cornerRadius(12)
    }

    // MARK: - Progress Section

    private var progressSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("学习进度")
                .font(.title3)
                .fontWeight(.semibold)

            VStack(spacing: 12) {
                // 掌握度
                StatRow(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "掌握度",
                    value: viewModel.progressText,
                    color: .primary
                )

                // 正确率
                StatRow(
                    icon: "checkmark.circle",
                    title: "正确率",
                    value: viewModel.accuracyText,
                    color: .success
                )

                // 练习次数
                if let progress = viewModel.knowledgePoint.progress {
                    StatRow(
                        icon: "pencil",
                        title: "练习次数",
                        value: "\(progress.practiceCount) 次",
                        color: .blue
                    )
                }

                // 学习状态
                if let progress = viewModel.knowledgePoint.progress {
                    StatRow(
                        icon: "flag",
                        title: "学习状态",
                        value: progress.status.displayName,
                        color: Color.forStatus(progress.status)
                    )
                }
            }
            .padding()
            .background(Color.surface)
            .cornerRadius(12)
        }
    }

    // MARK: - Description Section

    private func descriptionSection(_ description: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("知识点说明")
                .font(.title3)
                .fontWeight(.semibold)

            Text(description)
                .font(.body)
                .foregroundColor(.textSecondary)
                .lineSpacing(4)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.surface)
                .cornerRadius(12)
        }
    }

    // MARK: - Children Section

    private var childrenSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("包含的知识点 (\(viewModel.children.count))")
                .font(.title3)
                .fontWeight(.semibold)

            VStack(spacing: 8) {
                ForEach(viewModel.children) { child in
                    NavigationLink(destination: KnowledgeDetailView(knowledgePoint: child)) {
                        ChildKnowledgePointRow(knowledgePoint: child)
                    }
                }
            }
            .padding()
            .background(Color.surface)
            .cornerRadius(12)
        }
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        VStack(spacing: 12) {
            // 开始练习按钮
            CustomButton(
                title: "开始练习",
                action: { showPractice = true },
                isEnabled: !viewModel.isLoading,
                isLoading: viewModel.isLoading
            )

            // 如果有错题，显示错题复习按钮
            if let progress = viewModel.knowledgePoint.progress,
               progress.practiceCount > 0,
               progress.correctCount < progress.practiceCount {
                Button(action: {
                    // TODO: 跳转到错题本，筛选当前知识点
                }) {
                    HStack {
                        Image(systemName: "exclamationmark.triangle")
                        Text("复习错题")
                    }
                    .font(.headline)
                    .foregroundColor(.orange)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(12)
                }
            }
        }
        .padding(.top, 8)
    }
}

// MARK: - Supporting Views

struct DifficultyBadge: View {
    let difficulty: KnowledgePoint.Difficulty

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.forDifficulty(difficulty.rawValue))
                .frame(width: 50, height: 50)

            Image(systemName: iconName)
                .font(.title3)
                .foregroundColor(.white)
        }
    }

    private var iconName: String {
        switch difficulty {
        case .easy:
            return "1.circle.fill"
        case .medium:
            return "2.circle.fill"
        case .hard:
            return "3.circle.fill"
        }
    }
}

struct GradeBadge: View {
    let grade: Int

    var body: some View {
        Text("\(grade)年级")
            .font(.caption)
            .fontWeight(.medium)
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.primary.opacity(0.8))
            .cornerRadius(8)
    }
}

struct StatRow: View {
    let icon: String
    let title: String
    let value: String
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
                .frame(width: 30)

            Text(title)
                .font(.body)
                .foregroundColor(.textSecondary)

            Spacer()

            Text(value)
                .font(.body)
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
    }
}

struct ChildKnowledgePointRow: View {
    let knowledgePoint: KnowledgePoint

    var body: some View {
        HStack(spacing: 12) {
            // 难度指示器
            Circle()
                .fill(Color.forDifficulty(knowledgePoint.difficulty.rawValue))
                .frame(width: 10, height: 10)

            // 知识点名称
            Text(knowledgePoint.name)
                .font(.body)
                .foregroundColor(.text)

            Spacer()

            // 进度指示
            if let progress = knowledgePoint.progress {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundColor(Color.forProgress(progress.masteryLevel))

                    Text("\(knowledgePoint.progressPercentage)%")
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                }
            } else {
                Text("未学习")
                    .font(.caption)
                    .foregroundColor(.textSecondary)
            }

            // 箭头
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Extensions

extension KnowledgePoint.Difficulty {
    var displayName: String {
        switch self {
        case .easy:
            return "简单"
        case .medium:
            return "中等"
        case .hard:
            return "困难"
        }
    }
}

extension LearningProgress.Status {
    var displayName: String {
        switch self {
        case .notStarted:
            return "未开始"
        case .learning:
            return "学习中"
        case .mastered:
            return "已掌握"
        }
    }
}

extension Color {
    static func forStatus(_ status: LearningProgress.Status) -> Color {
        switch status {
        case .notStarted:
            return .gray
        case .learning:
            return .blue
        case .mastered:
            return .success
        }
    }

    static func forProgress(_ progress: Double) -> Color {
        if progress < 0.5 {
            return .red
        } else if progress < 0.75 {
            return .orange
        } else if progress < 0.9 {
            return .blue
        } else {
            return .success
        }
    }

    static func forDifficulty(_ difficulty: String) -> Color {
        switch difficulty {
        case "easy":
            return .green
        case "medium":
            return .orange
        case "hard":
            return .red
        default:
            return .gray
        }
    }
}

#if DEBUG
struct KnowledgeDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            KnowledgeDetailView(knowledgePoint: KnowledgePoint.mock())
        }
    }
}

extension KnowledgePoint {
    static func mock() -> KnowledgePoint {
        KnowledgePoint(
            id: 1,
            name: "有理数",
            grade: 7,
            parentId: nil,
            level: 1,
            sortOrder: 1,
            description: "有理数是整数和分数的统称，是实数的一个子集。在数学中，有理数可以用分数 p/q 表示，其中 p 和 q 为整数且 q 不为零。",
            difficulty: .easy,
            children: nil,
            progress: LearningProgress(
                userId: 1,
                knowledgePointId: 1,
                masteryLevel: 0.75,
                practiceCount: 20,
                correctCount: 15,
                lastPracticeTime: Date(),
                status: .learning
            )
        )
    }
}
#endif
