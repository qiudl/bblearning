//
//  HomeViewModel.swift
//  BBLearning
//
//  Created by Claude Code on 2025-10-15.
//

import Foundation
import Combine

final class HomeViewModel: BaseViewModel {
    // MARK: - Published Properties

    /// 今日统计
    @Published var dailyStats: DailyStatistics?

    /// 总体统计
    @Published var overallStats: OverallStatistics?

    /// 知识点掌握度
    @Published var knowledgeMastery: [KnowledgeMastery] = []

    /// AI推荐题目
    @Published var recommendations: [RecommendedPractice] = []

    /// 刷新状态
    @Published var isRefreshing: Bool = false

    // MARK: - Dependencies

    private let statisticsRepository: StatisticsRepositoryProtocol
    private let aiRepository: AIRepositoryProtocol

    // MARK: - Initialization

    init(
        statisticsRepository: StatisticsRepositoryProtocol = DIContainer.shared.resolve(StatisticsRepositoryProtocol.self),
        aiRepository: AIRepositoryProtocol = DIContainer.shared.resolve(AIRepositoryProtocol.self)
    ) {
        self.statisticsRepository = statisticsRepository
        self.aiRepository = aiRepository
        super.init()
        loadData()
    }

    // MARK: - Data Loading

    func loadData() {
        loadDailyStatistics()
        loadOverallStatistics()
        loadKnowledgeMastery()
        loadRecommendations()
    }

    func loadDailyStatistics() {
        let today = Date()
        executeTask(
            statisticsRepository.getDailyStatistics(date: today),
            onSuccess: { [weak self] stats in
                self?.dailyStats = stats
            }
        )
    }

    func loadOverallStatistics() {
        executeTask(
            statisticsRepository.getOverallStatistics(),
            onSuccess: { [weak self] stats in
                self?.overallStats = stats
            }
        )
    }

    func loadKnowledgeMastery() {
        executeTask(
            statisticsRepository.getKnowledgeMastery(grade: nil, knowledgePointId: nil),
            onSuccess: { [weak self] mastery in
                self?.knowledgeMastery = mastery
            }
        )
    }

    func loadRecommendations() {
        executeTask(
            aiRepository.getRecommendations(limit: 3),
            onSuccess: { [weak self] recommendations in
                self?.recommendations = recommendations
            }
        )
    }

    @MainActor
    func refresh() async {
        isRefreshing = true
        loadData()

        // 等待刷新完成
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        isRefreshing = false
    }

    // MARK: - Computed Properties

    /// 知识点掌握率
    var knowledgeMasteryRate: Double {
        guard !knowledgeMastery.isEmpty else { return 0.0 }
        let total = knowledgeMastery.reduce(0.0) { $0 + $1.masteryLevel }
        return total / Double(knowledgeMastery.count)
    }

    /// 练习完成度（假设每天目标10题）
    var practiceCompletionRate: Double {
        guard let daily = dailyStats else { return 0.0 }
        let target = 10.0
        return min(Double(daily.practiceCount) / target, 1.0)
    }

    /// 错题复习率
    var wrongQuestionReviewRate: Double {
        guard let overall = overallStats else { return 0.0 }
        guard overall.totalWrongQuestions > 0 else { return 1.0 }
        return Double(overall.masteredWrongQuestions) / Double(overall.totalWrongQuestions)
    }

    /// 学习天数
    var studyDays: Int {
        overallStats?.accountAge ?? 0
    }

    /// 累计题目
    var totalProblems: Int {
        overallStats?.totalPracticeCount ?? 0
    }

    /// 今日学习时长(分钟)
    var todayStudyMinutes: Int {
        dailyStats?.studyTime ?? 0
    }

    /// 今日完成题数
    var todayCompletedCount: Int {
        dailyStats?.practiceCount ?? 0
    }

    /// 今日正确率
    var todayAccuracy: Double {
        dailyStats?.accuracy ?? 0.0
    }
}
