//
//  HomeView.swift
//  BBLearning
//
//  Created by Claude Code on 2025-10-13.
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = HomeViewModel()

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 欢迎卡片
                welcomeCard

                // 快捷入口
                quickActionsGrid

                // 学习进度
                learningProgressSection

                // 推荐练习
                recommendedPracticeSection
            }
            .padding()
        }
        .navigationTitle("BBLearning")
        .refreshable {
            await viewModel.refresh()
        }
        .alert("加载失败", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("重试") {
                viewModel.loadData()
            }
            Button("取消", role: .cancel) {
                viewModel.errorMessage = nil
            }
        } message: {
            Text(viewModel.errorMessage ?? "未知错误")
        }
        .onAppear {
            viewModel.loadData()
        }
    }

    // MARK: - Welcome Card

    private var welcomeCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("你好，\(appState.currentUser?.nickname ?? "同学")")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("开始今天的学习吧")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.9))
                }

                Spacer()

                Image(systemName: timeBasedIcon)
                    .font(.largeTitle)
                    .foregroundColor(.yellow)
            }

            // 今日数据展示
            if let daily = viewModel.dailyStats {
                Divider()
                    .background(Color.white.opacity(0.3))

                HStack(spacing: 24) {
                    StatItem(
                        icon: "clock.fill",
                        value: "\(daily.studyTimeMinutes)",
                        unit: "分钟",
                        label: "学习时长"
                    )

                    StatItem(
                        icon: "checkmark.circle.fill",
                        value: "\(daily.practiceCount)",
                        unit: "题",
                        label: "完成题目"
                    )

                    StatItem(
                        icon: "chart.bar.fill",
                        value: String(format: "%.0f", daily.accuracy * 100),
                        unit: "%",
                        label: "正确率"
                    )
                }
            } else if viewModel.isLoading {
                ProgressView()
                    .tint(.white)
                    .padding(.top, 8)
            }
        }
        .padding()
        .background(
            LinearGradient(
                colors: [Color.blue.opacity(0.6), Color.purple.opacity(0.6)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .foregroundColor(.white)
        .cornerRadius(16)
    }

    private var timeBasedIcon: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 6..<12:
            return "sun.max.fill"
        case 12..<18:
            return "sun.min.fill"
        case 18..<22:
            return "moon.stars.fill"
        default:
            return "moon.fill"
        }
    }

    // MARK: - Quick Actions

    private var quickActionsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
            QuickActionCard(
                icon: "pencil",
                title: "开始练习",
                color: .blue,
                destination: AnyView(PracticeView())
            )

            QuickActionCard(
                icon: "exclamationmark.triangle.fill",
                title: "错题本",
                color: .orange,
                destination: AnyView(WrongQuestionView())
            )

            QuickActionCard(
                icon: "brain",
                title: "AI辅导",
                color: .purple,
                destination: AnyView(AITutorView())
            )

            QuickActionCard(
                icon: "chart.bar.fill",
                title: "学习报告",
                color: .green,
                destination: AnyView(Text("学习报告"))
            )
        }
    }

    // MARK: - Learning Progress

    private var learningProgressSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("学习进度")
                .font(.headline)

            if viewModel.isLoading && viewModel.knowledgeMastery.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                VStack(spacing: 12) {
                    ProgressItem(
                        title: "知识点掌握",
                        progress: viewModel.knowledgeMasteryRate,
                        color: .blue
                    )

                    ProgressItem(
                        title: "练习完成度",
                        progress: viewModel.practiceCompletionRate,
                        color: .green
                    )

                    ProgressItem(
                        title: "错题复习率",
                        progress: viewModel.wrongQuestionReviewRate,
                        color: .orange
                    )
                }
                .padding()
                .background(Color.surface)
                .cornerRadius(12)
            }
        }
    }

    // MARK: - Recommended Practice

    private var recommendedPracticeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("推荐练习")
                    .font(.headline)

                Spacer()

                if viewModel.isLoading && viewModel.recommendations.isEmpty {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }

            if viewModel.recommendations.isEmpty && !viewModel.isLoading {
                EmptyStateView(
                    icon: "lightbulb",
                    title: "暂无推荐",
                    message: "完成更多练习后，AI会为你推荐适合的题目"
                )
            } else {
                VStack(spacing: 12) {
                    ForEach(viewModel.recommendations.prefix(3)) { recommendation in
                        NavigationLink(
                            destination: PracticeView()
                        ) {
                            RecommendedCard(
                                title: recommendation.title,
                                subtitle: "建议练习\(recommendation.recommendedCount)题",
                                icon: "\(recommendation.priority).circle.fill",
                                color: recommendation.color,
                                badge: recommendation.priorityText
                            )
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Supporting Views

struct QuickActionCard: View {
    let icon: String
    let title: String
    let color: Color
    let destination: AnyView

    var body: some View {
        NavigationLink(destination: destination) {
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.largeTitle)
                    .foregroundColor(.white)

                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 120)
            .background(color)
            .cornerRadius(16)
        }
    }
}

struct ProgressItem: View {
    let title: String
    let progress: Double
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.subheadline)

                Spacer()

                Text("\(Int(progress * 100))%")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(color)
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))

                    Rectangle()
                        .fill(color)
                        .frame(width: geometry.size.width * CGFloat(progress))
                        .animation(.easeInOut(duration: 0.5), value: progress)
                }
            }
            .frame(height: 8)
            .cornerRadius(4)
        }
    }
}

struct RecommendedCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let badge: String?

    init(title: String, subtitle: String, icon: String, color: Color, badge: String? = nil) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.color = color
        self.badge = badge
    }

    var body: some View {
        HStack(spacing: 16) {
            ZStack(alignment: .topTrailing) {
                Image(systemName: icon)
                    .font(.title)
                    .foregroundColor(.white)
                    .frame(width: 50, height: 50)
                    .background(color)
                    .cornerRadius(12)

                if let badge = badge {
                    Text(badge)
                        .font(.system(size: 8))
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 2)
                        .background(Color.red)
                        .cornerRadius(4)
                        .offset(x: 8, y: -8)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.text)

                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.textSecondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
        }
        .padding()
        .background(Color.surface)
        .cornerRadius(12)
    }
}

struct StatItem: View {
    let icon: String
    let value: String
    let unit: String
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                Text(value)
                    .font(.title3)
                    .fontWeight(.bold)
                Text(unit)
                    .font(.caption2)
            }
            Text(label)
                .font(.caption2)
                .opacity(0.8)
        }
        .frame(maxWidth: .infinity)
    }
}

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.largeTitle)
                .foregroundColor(.secondary)

            Text(title)
                .font(.headline)
                .foregroundColor(.text)

            Text(message)
                .font(.subheadline)
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .background(Color.surface)
        .cornerRadius(12)
    }
}

#if DEBUG
struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            HomeView()
                .environmentObject(AppState())
        }
    }
}
#endif
