//
//  StatisticsViewModel.swift
//  BBLearning
//
//  Created by Claude Code on 2025-10-13.
//

import Foundation
import Combine

final class StatisticsViewModel: BaseViewModel {
    @Published var statistics: Statistics?
    @Published var knowledgeMastery: [KnowledgePoint] = []
    @Published var selectedPeriod: Period = .week

    enum Period: String, CaseIterable {
        case day = "今日"
        case week = "本周"
        case month = "本月"
        case all = "全部"
    }

    private let statisticsRepository: StatisticsRepositoryProtocol

    init(statisticsRepository: StatisticsRepositoryProtocol = DIContainer.shared.resolve(StatisticsRepositoryProtocol.self)) {
        self.statisticsRepository = statisticsRepository
        super.init()
        loadStatistics()
    }

    func loadStatistics() {
        let dateRange = getDateRange(for: selectedPeriod)

        executeTask(
            statisticsRepository.getLearningStatistics(startDate: dateRange.start, endDate: dateRange.end),
            onSuccess: { [weak self] stats in
                self?.statistics = stats
            }
        )

        executeTask(
            statisticsRepository.getKnowledgeMastery(),
            onSuccess: { [weak self] mastery in
                self?.knowledgeMastery = mastery
            }
        )
    }

    func changePeriod(_ period: Period) {
        selectedPeriod = period
        loadStatistics()
    }

    private func getDateRange(for period: Period) -> (start: Date, end: Date) {
        let end = Date()
        let calendar = Calendar.current

        let start: Date
        switch period {
        case .day:
            start = calendar.startOfDay(for: end)
        case .week:
            start = calendar.date(byAdding: .day, value: -7, to: end)!
        case .month:
            start = calendar.date(byAdding: .month, value: -1, to: end)!
        case .all:
            start = calendar.date(byAdding: .year, value: -10, to: end)!
        }

        return (start, end)
    }
}
