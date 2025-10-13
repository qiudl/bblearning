//
//  HomeView.swift
//  BBLearning
//
//  Created by Claude Code on 2025-10-13.
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject var appState: AppState

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
                        .foregroundColor(.textSecondary)
                }

                Spacer()

                Image(systemName: "sun.max.fill")
                    .font(.largeTitle)
                    .foregroundColor(.orange)
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

            VStack(spacing: 12) {
                ProgressItem(
                    title: "知识点掌握",
                    progress: 0.65,
                    color: .blue
                )

                ProgressItem(
                    title: "练习完成度",
                    progress: 0.80,
                    color: .green
                )

                ProgressItem(
                    title: "错题复习率",
                    progress: 0.45,
                    color: .orange
                )
            }
            .padding()
            .background(Color.surface)
            .cornerRadius(12)
        }
    }

    // MARK: - Recommended Practice

    private var recommendedPracticeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("推荐练习")
                .font(.headline)

            VStack(spacing: 12) {
                NavigationLink(destination: KnowledgeTreeView()) {
                    RecommendedCard(
                        title: "有理数运算",
                        subtitle: "建议练习10题",
                        icon: "1.circle.fill",
                        color: .blue
                    )
                }

                NavigationLink(destination: KnowledgeTreeView()) {
                    RecommendedCard(
                        title: "代数式化简",
                        subtitle: "建议练习15题",
                        icon: "2.circle.fill",
                        color: .green
                    )
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

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title)
                .foregroundColor(.white)
                .frame(width: 50, height: 50)
                .background(color)
                .cornerRadius(12)

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
