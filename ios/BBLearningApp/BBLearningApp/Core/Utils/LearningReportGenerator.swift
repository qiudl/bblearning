//
//  LearningReportGenerator.swift
//  BBLearning
//
//  Created by Claude Code on 2025-10-15.
//

import Foundation

/// 学习报告类型
enum ReportPeriod: String, CaseIterable {
    case weekly = "周报"
    case monthly = "月报"
    case semester = "学期报告"
}

/// 学习报告数据
struct LearningReport: Codable {
    let period: ReportPeriod
    let startDate: Date
    let endDate: Date
    let summary: ReportSummary
    let knowledgeProgress: [KnowledgeProgress]
    let practiceAnalysis: PracticeAnalysis
    let wrongQuestionStats: WrongQuestionStats
    let improvement: ImprovementAnalysis
    let aiRecommendations: [String]
    let generatedAt: Date
}

struct ReportSummary: Codable {
    let totalStudyDays: Int
    let totalQuestions: Int
    let totalCorrect: Int
    let totalTime: Int  // 秒
    let averageAccuracy: Double
    let rankPercentile: Int?  // 百分位
}

struct KnowledgeProgress: Codable {
    let knowledgePointId: Int
    let knowledgePointName: String
    let masteryLevel: Double  // 0-1
    let questionCount: Int
    let accuracy: Double
    let improvement: Double  // 相比上期的提升
}

struct PracticeAnalysis: Codable {
    let totalPractices: Int
    let practicesByMode: [String: Int]
    let averageQuestionsPerPractice: Int
    let peakPracticeTime: String  // 最常练习的时间段
}

struct WrongQuestionStats: Codable {
    let totalWrong: Int
    let corrected: Int
    let pending: Int
    let topErrorTypes: [String]
    let weakKnowledgePoints: [Int]
}

struct ImprovementAnalysis: Codable {
    let accuracyChange: Double  // 正确率变化
    let speedChange: Double  // 答题速度变化
    let consistencyScore: Double  // 学习稳定性评分
    let strengths: [String]
    let weaknesses: [String]
}

/// 学习报告生成器
class LearningReportGenerator {
    static let shared = LearningReportGenerator()

    private init() {}

    /// 生成学习报告
    func generateReport(
        period: ReportPeriod,
        endDate: Date = Date()
    ) -> LearningReport {
        let (startDate, reportEndDate) = calculatePeriodDates(period: period, endDate: endDate)

        // TODO: 从数据库或API获取真实数据
        // 这里使用模拟数据

        let summary = generateSummary(startDate: startDate, endDate: reportEndDate)
        let knowledgeProgress = generateKnowledgeProgress()
        let practiceAnalysis = generatePracticeAnalysis()
        let wrongQuestionStats = generateWrongQuestionStats()
        let improvement = generateImprovementAnalysis()
        let recommendations = generateAIRecommendations(
            summary: summary,
            weaknesses: improvement.weaknesses
        )

        return LearningReport(
            period: period,
            startDate: startDate,
            endDate: reportEndDate,
            summary: summary,
            knowledgeProgress: knowledgeProgress,
            practiceAnalysis: practiceAnalysis,
            wrongQuestionStats: wrongQuestionStats,
            improvement: improvement,
            aiRecommendations: recommendations,
            generatedAt: Date()
        )
    }

    // MARK: - Helper Methods

    private func calculatePeriodDates(period: ReportPeriod, endDate: Date) -> (Date, Date) {
        let calendar = Calendar.current
        let end = calendar.startOfDay(for: endDate)

        let start: Date
        switch period {
        case .weekly:
            start = calendar.date(byAdding: .day, value: -7, to: end)!
        case .monthly:
            start = calendar.date(byAdding: .month, value: -1, to: end)!
        case .semester:
            start = calendar.date(byAdding: .month, value: -6, to: end)!
        }

        return (start, end)
    }

    private func generateSummary(startDate: Date, endDate: Date) -> ReportSummary {
        // TODO: 从数据库查询真实数据
        return ReportSummary(
            totalStudyDays: 20,
            totalQuestions: 250,
            totalCorrect: 200,
            totalTime: 18000,  // 5小时
            averageAccuracy: 0.80,
            rankPercentile: 75
        )
    }

    private func generateKnowledgeProgress() -> [KnowledgeProgress] {
        return [
            KnowledgeProgress(
                knowledgePointId: 11,
                knowledgePointName: "有理数运算",
                masteryLevel: 0.85,
                questionCount: 50,
                accuracy: 0.88,
                improvement: 0.15
            ),
            KnowledgeProgress(
                knowledgePointId: 12,
                knowledgePointName: "代数式",
                masteryLevel: 0.70,
                questionCount: 40,
                accuracy: 0.72,
                improvement: 0.10
            )
        ]
    }

    private func generatePracticeAnalysis() -> PracticeAnalysis {
        return PracticeAnalysis(
            totalPractices: 15,
            practicesByMode: [
                "标准模式": 10,
                "自适应模式": 3,
                "错题模式": 2
            ],
            averageQuestionsPerPractice: 17,
            peakPracticeTime: "晚上19:00-21:00"
        )
    }

    private func generateWrongQuestionStats() -> WrongQuestionStats {
        return WrongQuestionStats(
            totalWrong: 50,
            corrected: 30,
            pending: 20,
            topErrorTypes: ["计算错误", "概念理解"],
            weakKnowledgePoints: [12, 21]
        )
    }

    private func generateImprovementAnalysis() -> ImprovementAnalysis {
        return ImprovementAnalysis(
            accuracyChange: 0.12,
            speedChange: -15,  // 答题速度提升15%
            consistencyScore: 0.85,
            strengths: ["有理数运算掌握扎实", "答题速度稳步提升"],
            weaknesses: ["代数式概念理解不够", "粗心错误较多"]
        )
    }

    private func generateAIRecommendations(
        summary: ReportSummary,
        weaknesses: [String]
    ) -> [String] {
        var recommendations: [String] = []

        if summary.averageAccuracy < 0.7 {
            recommendations.append("建议加强基础知识学习，重点复习薄弱知识点")
        }

        if !weaknesses.isEmpty {
            recommendations.append("针对性练习：\(weaknesses.joined(separator: "、"))")
        }

        recommendations.append("保持每天学习的良好习惯，稳定提升")
        recommendations.append("多做错题复习，巩固薄弱环节")

        return recommendations
    }
}
