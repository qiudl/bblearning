//
//  LearningReportView.swift
//  BBLearning
//
//  Created by Claude Code on 2025-10-15.
//

import SwiftUI
import Charts

/// 学习报告视图
struct LearningReportView: View {
    @StateObject private var viewModel = LearningReportViewModel()
    @State private var selectedPeriod: ReportPeriod = .weekly
    @State private var showShareSheet = false

    var body: some View {
        ScrollView {
            if let report = viewModel.report {
                VStack(spacing: 20) {
                    // 报告头部
                    reportHeader(report: report)

                    // 总体概况
                    summarySection(summary: report.summary)

                    // 进步曲线
                    progressChart

                    // 知识点掌握
                    knowledgeSection(progress: report.knowledgeProgress)

                    // 练习分析
                    practiceSection(analysis: report.practiceAnalysis)

                    // 错题统计
                    wrongQuestionSection(stats: report.wrongQuestionStats)

                    // AI建议
                    recommendationsSection(recommendations: report.aiRecommendations)

                    // 分享按钮
                    shareButton
                }
                .padding()
            } else if viewModel.isLoading {
                ProgressView()
            }
        }
        .navigationTitle("学习报告")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    ForEach(ReportPeriod.allCases, id: \.self) { period in
                        Button(period.rawValue) {
                            selectedPeriod = period
                            viewModel.generateReport(period: period)
                        }
                    }
                } label: {
                    HStack {
                        Text(selectedPeriod.rawValue)
                        Image(systemName: "chevron.down")
                    }
                }
            }
        }
        .onAppear {
            viewModel.generateReport(period: selectedPeriod)
        }
        .sheet(isPresented: $showShareSheet) {
            if let report = viewModel.report {
                ShareReportView(report: report)
            }
        }
    }

    // MARK: - Report Header

    private func reportHeader(report: LearningReport) -> some View {
        VStack(spacing: 8) {
            Text(report.period.rawValue)
                .font(.title2)
                .fontWeight(.bold)

            Text("\(formatDate(report.startDate)) - \(formatDate(report.endDate))")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            LinearGradient(
                colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .cornerRadius(12)
    }

    // MARK: - Summary Section

    private func summarySection(summary: ReportSummary) -> some View {
        VStack(spacing: 12) {
            Text("总体概况")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                SummaryCard(
                    title: "学习天数",
                    value: "\(summary.totalStudyDays)",
                    unit: "天",
                    icon: "calendar",
                    color: .blue
                )

                SummaryCard(
                    title: "完成题数",
                    value: "\(summary.totalQuestions)",
                    unit: "题",
                    icon: "checkmark.circle",
                    color: .green
                )

                SummaryCard(
                    title: "正确率",
                    value: String(format: "%.0f", summary.averageAccuracy * 100),
                    unit: "%",
                    icon: "chart.line.uptrend.xyaxis",
                    color: .purple
                )

                SummaryCard(
                    title: "总用时",
                    value: formatHours(summary.totalTime),
                    unit: "小时",
                    icon: "clock",
                    color: .orange
                )
            }
        }
    }

    // MARK: - Progress Chart

    private var progressChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("进步曲线")
                .font(.headline)

            if !viewModel.progressData.isEmpty {
                Chart {
                    ForEach(viewModel.progressData) { data in
                        LineMark(
                            x: .value("日期", data.date, unit: .day),
                            y: .value("正确率", data.accuracy)
                        )
                        .foregroundStyle(Color.blue)
                        .symbol(Circle().strokeBorder(lineWidth: 2))

                        AreaMark(
                            x: .value("日期", data.date, unit: .day),
                            y: .value("正确率", data.accuracy)
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
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
            } else {
                Text("暂无数据")
                    .foregroundColor(.secondary)
                    .frame(height: 200)
            }
        }
        .padding()
        .background(Color.surface)
        .cornerRadius(12)
    }

    // MARK: - Knowledge Section

    private func knowledgeSection(progress: [KnowledgeProgress]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("知识点掌握")
                .font(.headline)

            ForEach(progress, id: \.knowledgePointId) { item in
                KnowledgeMasteryRow(progress: item)
            }
        }
        .padding()
        .background(Color.surface)
        .cornerRadius(12)
    }

    // MARK: - Practice Section

    private func practiceSection(analysis: PracticeAnalysis) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("练习分析")
                .font(.headline)

            VStack(alignment: .leading, spacing: 8) {
                InfoRow(label: "练习次数", value: "\(analysis.totalPractices)次")
                InfoRow(label: "平均题数", value: "\(analysis.averageQuestionsPerPractice)题/次")
                InfoRow(label: "活跃时段", value: analysis.peakPracticeTime)
            }
        }
        .padding()
        .background(Color.surface)
        .cornerRadius(12)
    }

    // MARK: - Wrong Question Section

    private func wrongQuestionSection(stats: WrongQuestionStats) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("错题统计")
                .font(.headline)

            HStack(spacing: 12) {
                StatBadge(label: "错题", value: "\(stats.totalWrong)", color: .red)
                StatBadge(label: "已纠正", value: "\(stats.corrected)", color: .green)
                StatBadge(label: "待复习", value: "\(stats.pending)", color: .orange)
            }

            if !stats.topErrorTypes.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("常见错误")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    ForEach(stats.topErrorTypes, id: \.self) { errorType in
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                                .font(.caption)
                            Text(errorType)
                                .font(.subheadline)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color.surface)
        .cornerRadius(12)
    }

    // MARK: - Recommendations Section

    private func recommendationsSection(recommendations: [String]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundColor(.yellow)
                Text("AI学习建议")
                    .font(.headline)
            }

            ForEach(Array(recommendations.enumerated()), id: \.offset) { index, recommendation in
                HStack(alignment: .top, spacing: 12) {
                    Text("\(index + 1)")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .frame(width: 24, height: 24)
                        .background(Circle().fill(Color.blue))

                    Text(recommendation)
                        .font(.subheadline)
                }
            }
        }
        .padding()
        .background(Color.purple.opacity(0.1))
        .cornerRadius(12)
    }

    // MARK: - Share Button

    private var shareButton: some View {
        Button(action: { showShareSheet = true }) {
            HStack {
                Image(systemName: "square.and.arrow.up")
                Text("分享给家长")
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
    }

    // MARK: - Helper Methods

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd"
        return formatter.string(from: date)
    }

    private func formatHours(_ seconds: Int) -> String {
        let hours = Double(seconds) / 3600.0
        return String(format: "%.1f", hours)
    }
}

// MARK: - Supporting Views

struct SummaryCard: View {
    let title: String
    let value: String
    let unit: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(color)

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                Text(unit)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.background)
        .cornerRadius(8)
    }
}

struct KnowledgeMasteryRow: View {
    let progress: KnowledgeProgress

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(progress.knowledgePointName)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Spacer()

                Text(String(format: "%.0f%%", progress.masteryLevel * 100))
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(masteryColor)

                if progress.improvement > 0 {
                    HStack(spacing: 2) {
                        Image(systemName: "arrow.up")
                        Text(String(format: "+%.0f%%", progress.improvement * 100))
                    }
                    .font(.caption)
                    .foregroundColor(.green)
                }
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.2))

                    RoundedRectangle(cornerRadius: 4)
                        .fill(masteryColor)
                        .frame(width: geometry.size.width * progress.masteryLevel)
                }
            }
            .frame(height: 8)
        }
    }

    private var masteryColor: Color {
        if progress.masteryLevel >= 0.8 {
            return .green
        } else if progress.masteryLevel >= 0.6 {
            return .orange
        } else {
            return .red
        }
    }
}

struct StatBadge: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(color)

            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
}

struct ShareReportView: View {
    let report: LearningReport
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            VStack {
                Text("分享学习报告功能")
                Text("TODO: 实现报告分享")
            }
            .navigationTitle("分享报告")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("关闭") { dismiss() }
                }
            }
        }
    }
}

// MARK: - ViewModel

class LearningReportViewModel: BaseViewModel {
    @Published var report: LearningReport?
    @Published var progressData: [ProgressDataPoint] = []

    struct ProgressDataPoint: Identifiable {
        let id = UUID()
        let date: Date
        let accuracy: Double
    }

    func generateReport(period: ReportPeriod) {
        isLoading = true

        DispatchQueue.global().asyncAfter(deadline: .now() + 1.0) { [weak self] in
            let report = LearningReportGenerator.shared.generateReport(period: period)

            DispatchQueue.main.async {
                self?.report = report
                self?.generateProgressData(period: period)
                self?.isLoading = false
            }
        }
    }

    private func generateProgressData(period: ReportPeriod) {
        let calendar = Calendar.current
        let now = Date()
        let days = period == .weekly ? 7 : (period == .monthly ? 30 : 180)

        progressData = (0..<days).compactMap { dayOffset in
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: now) else {
                return nil
            }

            // 模拟数据：逐步提升的正确率
            let baseAccuracy = 0.65 + Double(days - dayOffset) * 0.003
            let randomVariation = Double.random(in: -0.05...0.05)
            let accuracy = min(0.95, max(0.50, baseAccuracy + randomVariation))

            return ProgressDataPoint(date: date, accuracy: accuracy)
        }.reversed()
    }
}

#if DEBUG
struct LearningReportView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            LearningReportView()
        }
    }
}
#endif
