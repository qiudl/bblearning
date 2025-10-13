//
//  StatisticsRepository.swift
//  BBLearning
//
//  Created by Claude Code on 2025-10-13.
//

import Foundation
import Combine

final class StatisticsRepository: StatisticsRepositoryProtocol {
    private let apiClient: APIClient

    init(apiClient: APIClient = .shared) {
        self.apiClient = apiClient
    }

    func getLearningStatistics(date: Date) -> AnyPublisher<LearningStatistics, APIError> {
        let endpoint = StatisticsEndpoint.learning(date: date.toString())
        return apiClient.request(endpoint, type: LearningStatistics.self)
    }

    func getDailyStatistics(date: Date) -> AnyPublisher<DailyStatistics, APIError> {
        let endpoint = StatisticsEndpoint.daily(date: date.toString())
        return apiClient.request(endpoint, type: DailyStatistics.self)
    }

    func getWeeklyStatistics(weekStart: Date) -> AnyPublisher<WeeklyStatistics, APIError> {
        let endpoint = StatisticsEndpoint.weekly(weekStart: weekStart.toString())
        return apiClient.request(endpoint, type: WeeklyStatistics.self)
    }

    func getMonthlyStatistics(month: String) -> AnyPublisher<MonthlyStatistics, APIError> {
        let endpoint = StatisticsEndpoint.monthly(month: month)
        return apiClient.request(endpoint, type: MonthlyStatistics.self)
    }

    func getOverallStatistics() -> AnyPublisher<OverallStatistics, APIError> {
        let endpoint = StatisticsEndpoint.overall
        return apiClient.request(endpoint, type: OverallStatistics.self)
    }

    func getKnowledgeMastery(grade: Int?, knowledgePointId: Int?) -> AnyPublisher<[KnowledgeMastery], APIError> {
        let endpoint = StatisticsEndpoint.knowledgeMastery(grade: grade, knowledgePointId: knowledgePointId)
        return apiClient.request(endpoint, type: [KnowledgeMastery].self)
    }

    func getProgressCurve(startDate: Date, endDate: Date, knowledgePointId: Int?) -> AnyPublisher<[ProgressDataPoint], APIError> {
        let endpoint = StatisticsEndpoint.progressCurve(start: startDate.toString(), end: endDate.toString(), knowledgePointId: knowledgePointId)
        return apiClient.request(endpoint, type: [ProgressDataPoint].self)
    }

    func recordPracticeStats(practiceCount: Int, correctCount: Int, studyTime: Int) -> AnyPublisher<Void, APIError> {
        let endpoint = StatisticsEndpoint.recordPractice(count: practiceCount, correct: correctCount, time: studyTime)
        return apiClient.request(endpoint, type: EmptyResponse.self)
            .map { _ in () }
            .eraseToAnyPublisher()
    }

    func updateStreak() -> AnyPublisher<Int, APIError> {
        let endpoint = StatisticsEndpoint.updateStreak
        return apiClient.request(endpoint, type: StreakResponse.self)
            .map { $0.streak }
            .eraseToAnyPublisher()
    }

    func getLeaderboard(grade: Int, type: LeaderboardType, limit: Int) -> AnyPublisher<[LeaderboardEntry], APIError> {
        let endpoint = StatisticsEndpoint.leaderboard(grade: grade, type: type.rawValue, limit: limit)
        return apiClient.request(endpoint, type: [LeaderboardEntry].self)
    }
}

struct StreakResponse: Codable {
    let streak: Int
}
