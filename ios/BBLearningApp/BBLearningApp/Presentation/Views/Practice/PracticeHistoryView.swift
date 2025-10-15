//
//  PracticeHistoryView.swift
//  BBLearning
//
//  Created by Claude Code on 2025-10-15.
//

import SwiftUI

/// 练习历史视图
struct PracticeHistoryView: View {
    @StateObject private var viewModel = PracticeHistoryViewModel()
    @State private var selectedPeriod: TimePeriod = .week

    enum TimePeriod: String, CaseIterable {
        case week = "本周"
        case month = "本月"
        case all = "全部"
    }

    var body: some View {
        VStack(spacing: 0) {
            // 时间段筛选
            periodPicker

            // 统计概览
            if !viewModel.records.isEmpty {
                statisticsSection
            }

            // 练习记录列表
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxHeight: .infinity)
            } else if viewModel.filteredRecords.isEmpty {
                emptyView
            } else {
                recordsList
            }
        }
        .navigationTitle("练习历史")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            viewModel.loadHistory()
        }
    }

    // MARK: - Period Picker

    private var periodPicker: some View {
        Picker("时间段", selection: $selectedPeriod) {
            ForEach(TimePeriod.allCases, id: \.self) { period in
                Text(period.rawValue).tag(period)
            }
        }
        .pickerStyle(.segmented)
        .padding()
        .onChange(of: selectedPeriod) { newPeriod in
            viewModel.filterByPeriod(newPeriod)
        }
    }

    // MARK: - Statistics Section

    private var statisticsSection: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                StatCard(
                    title: "总练习数",
                    value: "\(viewModel.statistics.totalCount)",
                    icon: "list.bullet.clipboard",
                    color: .blue
                )

                StatCard(
                    title: "平均正确率",
                    value: "\(viewModel.statistics.averageAccuracy)%",
                    icon: "chart.line.uptrend.xyaxis",
                    color: .green
                )
            }

            HStack(spacing: 12) {
                StatCard(
                    title: "总题数",
                    value: "\(viewModel.statistics.totalQuestions)",
                    icon: "checkmark.circle",
                    color: .purple
                )

                StatCard(
                    title: "总用时",
                    value: PracticeTimerManager.formatLongTime(viewModel.statistics.totalTime),
                    icon: "clock",
                    color: .orange
                )
            }
        }
        .padding(.horizontal)
        .padding(.bottom)
    }

    // MARK: - Records List

    private var recordsList: some View {
        List {
            ForEach(viewModel.filteredRecords) { record in
                NavigationLink(destination: PracticeDetailView(record: record)) {
                    PracticeRecordRow(record: record)
                }
            }
            .onDelete { indexSet in
                indexSet.forEach { index in
                    let record = viewModel.filteredRecords[index]
                    viewModel.deleteRecord(record)
                }
            }
        }
        .listStyle(.plain)
    }

    // MARK: - Empty View

    private var emptyView: some View {
        VStack(spacing: 16) {
            Image(systemName: "tray")
                .font(.system(size: 60))
                .foregroundColor(.gray)

            Text("还没有练习记录")
                .font(.headline)
                .foregroundColor(.secondary)

            Text("开始练习后记录会显示在这里")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxHeight: .infinity)
    }
}

// MARK: - Stat Card

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.title3)

            Text(value)
                .font(.title2)
                .fontWeight(.bold)

            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.surface)
        .cornerRadius(12)
    }
}

// MARK: - Practice Record Row

struct PracticeRecordRow: View {
    let record: PracticeRecord

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                // 模式标签
                HStack(spacing: 4) {
                    Image(systemName: record.mode.icon)
                    Text(record.mode.displayName)
                }
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(modeColor.opacity(0.2))
                .foregroundColor(modeColor)
                .cornerRadius(6)

                Spacer()

                // 时间
                Text(record.formattedDate)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            // 成绩信息
            HStack(spacing: 20) {
                ScoreIndicator(
                    label: "题数",
                    value: "\(record.totalQuestions)",
                    icon: "number"
                )

                ScoreIndicator(
                    label: "正确率",
                    value: record.accuracyPercentage,
                    icon: "percent",
                    color: accuracyColor
                )

                ScoreIndicator(
                    label: "用时",
                    value: PracticeTimerManager.formatTime(record.totalTimeSeconds),
                    icon: "clock"
                )
            }
        }
        .padding(.vertical, 8)
    }

    private var modeColor: Color {
        switch record.mode {
        case .standard: return .blue
        case .adaptive: return .purple
        case .wrongQuestions: return .orange
        }
    }

    private var accuracyColor: Color {
        let rate = Double(record.correctCount) / Double(max(record.totalQuestions, 1))
        if rate >= 0.8 {
            return .green
        } else if rate >= 0.6 {
            return .orange
        } else {
            return .red
        }
    }
}

struct ScoreIndicator: View {
    let label: String
    let value: String
    let icon: String
    var color: Color = .primary

    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption2)
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
            .foregroundColor(color)

            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - ViewModel

class PracticeHistoryViewModel: BaseViewModel {
    @Published var records: [PracticeRecord] = []
    @Published var filteredRecords: [PracticeRecord] = []
    @Published var statistics: PracticeStatistics = .empty

    private let cacheManager = PracticeCacheManager.shared

    struct PracticeStatistics {
        let totalCount: Int
        let totalQuestions: Int
        let totalTime: Int
        let averageAccuracy: Int

        static let empty = PracticeStatistics(
            totalCount: 0,
            totalQuestions: 0,
            totalTime: 0,
            averageAccuracy: 0
        )
    }

    func loadHistory() {
        isLoading = true

        // 从缓存加载
        records = cacheManager.getCachedRecords()
        filteredRecords = records

        calculateStatistics()
        isLoading = false

        // TODO: 从服务器加载最新数据
    }

    func filterByPeriod(_ period: PracticeHistoryView.TimePeriod) {
        let calendar = Calendar.current
        let now = Date()

        switch period {
        case .week:
            let weekAgo = calendar.date(byAdding: .day, value: -7, to: now)!
            filteredRecords = records.filter { $0.startTime >= weekAgo }

        case .month:
            let monthAgo = calendar.date(byAdding: .month, value: -1, to: now)!
            filteredRecords = records.filter { $0.startTime >= monthAgo }

        case .all:
            filteredRecords = records
        }

        calculateStatistics()
    }

    func deleteRecord(_ record: PracticeRecord) {
        cacheManager.deleteRecord(recordId: record.id)
        loadHistory()
    }

    private func calculateStatistics() {
        guard !filteredRecords.isEmpty else {
            statistics = .empty
            return
        }

        let totalQuestions = filteredRecords.reduce(0) { $0 + $1.totalQuestions }
        let totalCorrect = filteredRecords.reduce(0) { $0 + $1.correctCount }
        let totalTime = filteredRecords.reduce(0) { $0 + $1.totalTimeSeconds }

        statistics = PracticeStatistics(
            totalCount: filteredRecords.count,
            totalQuestions: totalQuestions,
            totalTime: totalTime,
            averageAccuracy: totalQuestions > 0 ? (totalCorrect * 100 / totalQuestions) : 0
        )
    }
}

// MARK: - Extensions

extension PracticeRecord {
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: startTime)
    }

    var accuracyPercentage: String {
        let rate = Double(correctCount) / Double(max(totalQuestions, 1)) * 100
        return String(format: "%.0f%%", rate)
    }
}

// MARK: - Preview

#if DEBUG
struct PracticeHistoryView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            PracticeHistoryView()
        }
    }
}
#endif
