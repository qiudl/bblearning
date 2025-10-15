//
//  WrongQuestionView.swift
//  BBLearning
//
//  Created by Claude Code on 2025-10-13.
//

import SwiftUI

struct WrongQuestionView: View {
    @StateObject private var viewModel = WrongQuestionViewModel()
    @State private var showFilters = false

    var body: some View {
        VStack(spacing: 0) {
            // 统计卡片
            statisticsSection

            // 搜索和筛选
            searchAndFilterBar

            // 题目列表
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.filteredQuestions.isEmpty {
                emptyStateView
            } else {
                questionList
            }
        }
        .navigationTitle("错题本")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if viewModel.hasFilters {
                    Button("清除筛选") {
                        viewModel.clearFilters()
                    }
                }
            }
        }
        .errorAlert(error: $viewModel.errorMessage)
        .fullScreenCover(isPresented: $viewModel.showRetryView) {
            if let wrongQuestion = viewModel.selectedQuestion,
               let question = wrongQuestion.question {
                QuestionView(questions: [question])
            }
        }
    }

    // MARK: - Statistics Section

    private var statisticsSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                StatBadge(title: "总计", count: viewModel.totalCount, color: .blue)
                StatBadge(title: "待复习", count: viewModel.pendingCount, color: .orange)
                StatBadge(title: "复习中", count: viewModel.retryingCount, color: .purple)
                StatBadge(title: "已掌握", count: viewModel.masteredCount, color: .green)
                StatBadge(title: "需复习", count: viewModel.needsReviewCount, color: .red)
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 12)
        .background(Color.surface)
    }

    // MARK: - Search and Filter

    private var searchAndFilterBar: some View {
        HStack(spacing: 12) {
            SearchBar(text: $viewModel.searchText, placeholder: "搜索错题")

            Button(action: { showFilters.toggle() }) {
                Image(systemName: viewModel.hasFilters ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                    .font(.title3)
                    .foregroundColor(.primary)
            }
            .sheet(isPresented: $showFilters) {
                FilterSheet(viewModel: viewModel)
            }
        }
        .padding()
    }

    // MARK: - Question List

    private var questionList: some View {
        List {
            ForEach(viewModel.filteredQuestions) { wrongQuestion in
                NavigationLink(destination: WrongQuestionDetailView(wrongQuestion: wrongQuestion)) {
                    WrongQuestionRow(wrongQuestion: wrongQuestion)
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button(role: .destructive) {
                        viewModel.deleteQuestion(wrongQuestion)
                    } label: {
                        Label("删除", systemImage: "trash")
                    }

                    if wrongQuestion.status != .mastered {
                        Button {
                            viewModel.markAsMastered(wrongQuestion)
                        } label: {
                            Label("已掌握", systemImage: "checkmark")
                        }
                        .tint(.green)
                    }

                    Button {
                        viewModel.retryQuestion(wrongQuestion)
                    } label: {
                        Label("重做", systemImage: "arrow.clockwise")
                    }
                    .tint(.blue)
                }
            }
        }
        .listStyle(PlainListStyle())
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 60))
                .foregroundColor(.green)

            Text(viewModel.hasFilters ? "没有符合条件的错题" : "暂无错题")
                .font(.headline)
                .foregroundColor(.textSecondary)

            if !viewModel.hasFilters {
                Text("继续保持！做对每一道题")
                    .font(.caption)
                    .foregroundColor(.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Supporting Views

struct StatBadge: View {
    let title: String
    let count: Int
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text("\(count)")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)

            Text(title)
                .font(.caption)
                .foregroundColor(.textSecondary)
        }
        .frame(width: 80)
        .padding(.vertical, 12)
        .background(Color.background)
        .cornerRadius(12)
    }
}

struct WrongQuestionRow: View {
    let wrongQuestion: WrongQuestion

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 状态和时间
            HStack {
                StatusBadge(status: wrongQuestion.status)

                Spacer()

                Text(wrongQuestion.createdAt.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .foregroundColor(.textSecondary)
            }

            // 题目内容
            if let question = wrongQuestion.question {
                Text(question.content.stem)
                    .font(.body)
                    .lineLimit(2)
            }

            // 底部信息
            HStack {
                Label("第\(wrongQuestion.retryCount)次", systemImage: "arrow.clockwise")
                    .font(.caption)
                    .foregroundColor(.textSecondary)

                if wrongQuestion.needsReview {
                    Label("需复习", systemImage: "exclamationmark.circle")
                        .font(.caption)
                        .foregroundColor(.orange)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .padding(.vertical, 8)
    }
}

struct StatusBadge: View {
    let status: WrongQuestion.Status

    var body: some View {
        Text(status.displayText)
            .font(.caption)
            .fontWeight(.medium)
            .foregroundColor(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(statusColor)
            .cornerRadius(8)
    }

    private var statusColor: Color {
        switch status {
        case .pending:
            return .orange
        case .reviewing:
            return .purple
        case .mastered:
            return .green
        case .archived:
            return .gray
        }
    }
}

struct FilterSheet: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: WrongQuestionViewModel

    var body: some View {
        NavigationView {
            List {
                Section("状态") {
                    ForEach([WrongQuestion.Status.pending, .reviewing, .mastered], id: \.self) { status in
                        Button(action: {
                            viewModel.filterByStatus(status)
                            dismiss()
                        }) {
                            HStack {
                                Text(status.displayText)
                                Spacer()
                                if viewModel.selectedStatus == status {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.primary)
                                }
                            }
                        }
                    }

                    Button("显示全部") {
                        viewModel.filterByStatus(nil)
                        dismiss()
                    }
                }
            }
            .navigationTitle("筛选")
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
}


#if DEBUG
struct WrongQuestionView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            WrongQuestionView()
        }
    }
}
#endif
