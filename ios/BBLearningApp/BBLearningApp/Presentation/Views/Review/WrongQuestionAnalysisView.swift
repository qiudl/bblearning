//
//  WrongQuestionAnalysisView.swift
//  BBLearning
//
//  Created by Claude Code on 2025-10-15.
//

import SwiftUI
import Charts

/// 错题分析视图
struct WrongQuestionAnalysisView: View {
    @StateObject private var viewModel = WrongQuestionAnalysisViewModel()
    @State private var selectedTimeRange: TimeRange = .week
    @State private var showShareSheet = false
    @State private var pdfURL: URL?

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 时间范围选择器
                timeRangePicker

                // 统计卡片
                if let stats = viewModel.statistics {
                    statisticsCards(stats: stats)

                    // 错误类型分布图
                    errorTypeChart(stats: stats)

                    // 知识点分布图
                    knowledgePointChart(stats: stats)

                    // 难度分布图
                    difficultyChart(stats: stats)

                    // 复习趋势图
                    reviewTrendChart

                    // 薄弱知识点列表
                    weakKnowledgePointsList(stats: stats)
                }
            }
            .padding()
        }
        .navigationTitle("错题分析")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: exportPDF) {
                    Label("导出PDF", systemImage: "square.and.arrow.up")
                }
            }
        }
        .onAppear {
            viewModel.loadStatistics(timeRange: selectedTimeRange)
        }
        .overlay {
            if viewModel.isLoading {
                ProgressView()
            }
        }
        .sheet(isPresented: $showShareSheet) {
            if let url = pdfURL {
                ShareSheet(activityItems: [url])
            }
        }
    }

    // MARK: - Time Range Picker

    private var timeRangePicker: some View {
        Picker("时间范围", selection: $selectedTimeRange) {
            ForEach(TimeRange.allCases, id: \.self) { range in
                Text(range.displayName).tag(range)
            }
        }
        .pickerStyle(.segmented)
        .onChange(of: selectedTimeRange) { newValue in
            viewModel.loadStatistics(timeRange: newValue)
        }
    }

    // MARK: - Statistics Cards

    private func statisticsCards(stats: WrongQuestionStatistics) -> some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                StatCardView(
                    title: "总错题数",
                    value: "\(stats.totalCount)",
                    icon: "exclamationmark.triangle",
                    color: .red
                )

                StatCardView(
                    title: "今日待复习",
                    value: "\(stats.todayReviewCount ?? 0)",
                    icon: "calendar.badge.clock",
                    color: .orange
                )
            }

            HStack(spacing: 12) {
                StatCardView(
                    title: "本周已复习",
                    value: "\(stats.weeklyCompletedCount ?? 0)",
                    icon: "checkmark.circle",
                    color: .green
                )

                StatCardView(
                    title: "已掌握",
                    value: "\(stats.masteredCount)",
                    icon: "star.fill",
                    color: .blue
                )
            }

            // 复习完成率进度条
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("复习完成率")
                        .font(.subheadline)
                        .fontWeight(.medium)

                    Spacer()

                    Text("\(Int(stats.reviewCompletionRate * 100))%")
                        .font(.headline)
                        .foregroundColor(.blue)
                }

                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.2))

                        RoundedRectangle(cornerRadius: 4)
                            .fill(
                                LinearGradient(
                                    colors: [Color.blue, Color.green],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geometry.size.width * stats.reviewCompletionRate)
                            .animation(.easeInOut(duration: 0.5), value: stats.reviewCompletionRate)
                    }
                }
                .frame(height: 8)
            }
            .padding()
            .background(Color.surface)
            .cornerRadius(12)
        }
    }

    // MARK: - Error Type Chart

    private func errorTypeChart(stats: WrongQuestionStatistics) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("错误类型分布")
                .font(.headline)
                .padding(.horizontal)

            if let errorTypes = stats.byErrorType, !errorTypes.isEmpty {
                Chart {
                    ForEach(Array(errorTypes.sorted(by: { $0.value > $1.value })), id: \.key) { key, value in
                        let errorType = WrongQuestion.ErrorType(rawValue: key) ?? .unknown
                        BarMark(
                            x: .value("数量", value),
                            y: .value("类型", errorType.displayName)
                        )
                        .foregroundStyle(by: .value("类型", errorType.displayName))
                        .annotation(position: .trailing) {
                            Text("\(value)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .frame(height: 200)
                .padding()
                .background(Color.surface)
                .cornerRadius(12)

                // 最常见错误类型提示
                if let commonType = stats.mostCommonErrorType {
                    HStack {
                        Image(systemName: "lightbulb.fill")
                            .foregroundColor(.yellow)

                        Text("您最常见的错误类型是：\(commonType.displayName)")
                            .font(.subheadline)

                        Spacer()
                    }
                    .padding()
                    .background(Color.yellow.opacity(0.1))
                    .cornerRadius(8)
                    .padding(.horizontal)
                }
            } else {
                emptyChartPlaceholder
            }
        }
    }

    // MARK: - Knowledge Point Chart

    private func knowledgePointChart(stats: WrongQuestionStatistics) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("知识点错题分布")
                .font(.headline)
                .padding(.horizontal)

            if !stats.byKnowledgePoint.isEmpty {
                Chart {
                    ForEach(Array(stats.byKnowledgePoint.sorted(by: { $0.value > $1.value }).prefix(5)), id: \.key) { key, value in
                        SectorMark(
                            angle: .value("数量", value),
                            innerRadius: .ratio(0.5),
                            angularInset: 1.5
                        )
                        .foregroundStyle(by: .value("知识点", "知识点\(key)"))
                        .annotation(position: .overlay) {
                            Text("\(value)")
                                .font(.caption)
                                .fontWeight(.bold)
                        }
                    }
                }
                .frame(height: 250)
                .padding()
                .background(Color.surface)
                .cornerRadius(12)
            } else {
                emptyChartPlaceholder
            }
        }
    }

    // MARK: - Difficulty Chart

    private func difficultyChart(stats: WrongQuestionStatistics) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("难度分布")
                .font(.headline)
                .padding(.horizontal)

            if !stats.byDifficulty.isEmpty {
                Chart {
                    ForEach(Array(stats.byDifficulty.sorted(by: { $0.key < $1.key })), id: \.key) { key, value in
                        BarMark(
                            x: .value("难度", difficultyDisplayName(key)),
                            y: .value("数量", value)
                        )
                        .foregroundStyle(difficultyColor(key))
                        .annotation(position: .top) {
                            Text("\(value)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .frame(height: 180)
                .padding()
                .background(Color.surface)
                .cornerRadius(12)
            } else {
                emptyChartPlaceholder
            }
        }
    }

    // MARK: - Review Trend Chart

    private var reviewTrendChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("复习趋势")
                .font(.headline)
                .padding(.horizontal)

            if !viewModel.reviewTrend.isEmpty {
                Chart {
                    ForEach(viewModel.reviewTrend) { trend in
                        LineMark(
                            x: .value("日期", trend.date, unit: .day),
                            y: .value("复习数", trend.count)
                        )
                        .foregroundStyle(Color.blue)
                        .symbol(Circle().strokeBorder(lineWidth: 2))

                        AreaMark(
                            x: .value("日期", trend.date, unit: .day),
                            y: .value("复习数", trend.count)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.blue.opacity(0.3), Color.blue.opacity(0.1)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                    }
                }
                .frame(height: 200)
                .padding()
                .background(Color.surface)
                .cornerRadius(12)
            } else {
                emptyChartPlaceholder
            }
        }
    }

    // MARK: - Weak Knowledge Points List

    private func weakKnowledgePointsList(stats: WrongQuestionStatistics) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("薄弱知识点")
                .font(.headline)
                .padding(.horizontal)

            VStack(spacing: 8) {
                ForEach(stats.weakKnowledgePoints, id: \.self) { pointId in
                    if let count = stats.byKnowledgePoint[pointId] {
                        WeakKnowledgePointRow(
                            knowledgePointId: pointId,
                            errorCount: count
                        )
                    }
                }
            }
            .padding()
            .background(Color.surface)
            .cornerRadius(12)
        }
    }

    // MARK: - Empty Placeholder

    private var emptyChartPlaceholder: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.bar.xaxis")
                .font(.largeTitle)
                .foregroundColor(.gray)

            Text("暂无数据")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(height: 150)
        .frame(maxWidth: .infinity)
        .background(Color.surface)
        .cornerRadius(12)
        .padding(.horizontal)
    }

    // MARK: - Helper Functions

    private func difficultyDisplayName(_ key: String) -> String {
        switch key {
        case "easy": return "简单"
        case "medium": return "中等"
        case "hard": return "困难"
        default: return key
        }
    }

    private func difficultyColor(_ key: String) -> Color {
        switch key {
        case "easy": return .green
        case "medium": return .orange
        case "hard": return .red
        default: return .gray
        }
    }

    // MARK: - Export PDF

    private func exportPDF() {
        // TODO: 获取完整的错题列表
        // 这里使用mock数据作为示例
        let wrongQuestions = WrongQuestion.mockList

        if let url = viewModel.exportAnalysisReport(wrongQuestions: wrongQuestions) {
            pdfURL = url
            showShareSheet = true
        }
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: nil
        )
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Time Range Enum

enum TimeRange: String, CaseIterable {
    case week = "week"
    case month = "month"
    case all = "all"

    var displayName: String {
        switch self {
        case .week: return "本周"
        case .month: return "本月"
        case .all: return "全部"
        }
    }
}

// MARK: - Stat Card View

struct StatCardView: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Spacer()
            }

            Text(value)
                .font(.title)
                .fontWeight(.bold)

            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.surface)
        .cornerRadius(12)
    }
}

// MARK: - Weak Knowledge Point Row

struct WeakKnowledgePointRow: View {
    let knowledgePointId: Int
    let errorCount: Int

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("知识点 #\(knowledgePointId)")
                    .font(.subheadline)
                    .fontWeight(.medium)

                // TODO: 从API获取知识点名称
                Text("需要加强练习")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text("\(errorCount)")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.red)

                Text("道错题")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color.background)
        .cornerRadius(8)
    }
}

// MARK: - Preview

#if DEBUG
struct WrongQuestionAnalysisView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            WrongQuestionAnalysisView()
        }
    }
}
#endif
