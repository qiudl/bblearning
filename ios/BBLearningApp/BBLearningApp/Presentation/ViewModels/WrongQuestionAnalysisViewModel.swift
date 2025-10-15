//
//  WrongQuestionAnalysisViewModel.swift
//  BBLearning
//
//  Created by Claude Code on 2025-10-15.
//

import Foundation
import Combine

/// 错题分析ViewModel
final class WrongQuestionAnalysisViewModel: BaseViewModel {
    @Published var statistics: WrongQuestionStatistics?
    @Published var reviewTrend: [ReviewTrendData] = []

    private let wrongQuestionRepository: WrongQuestionRepository

    init(wrongQuestionRepository: WrongQuestionRepository = DIContainer.shared.resolve(WrongQuestionRepository.self)) {
        self.wrongQuestionRepository = wrongQuestionRepository
        super.init()
    }

    /// 加载错题统计数据
    /// - Parameter timeRange: 时间范围
    func loadStatistics(timeRange: TimeRange) {
        executeTask(
            wrongQuestionRepository.getStatistics(timeRange: timeRange.rawValue),
            onSuccess: { [weak self] stats in
                self?.statistics = stats
                self?.loadReviewTrend(timeRange: timeRange)
            }
        )
    }

    /// 加载复习趋势数据
    /// - Parameter timeRange: 时间范围
    private func loadReviewTrend(timeRange: TimeRange) {
        let calendar = Calendar.current
        let now = Date()

        // 根据时间范围确定天数
        let days: Int
        switch timeRange {
        case .week: days = 7
        case .month: days = 30
        case .all: days = 90
        }

        // 生成日期范围
        var trendData: [ReviewTrendData] = []
        for i in 0..<days {
            if let date = calendar.date(byAdding: .day, value: -i, to: now) {
                // TODO: 从API获取真实数据，这里使用模拟数据
                let count = Int.random(in: 0...5)
                trendData.append(ReviewTrendData(date: date, count: count))
            }
        }

        reviewTrend = trendData.sorted { $0.date < $1.date }
    }

    /// 导出错题分析报告（PDF）
    /// - Parameter wrongQuestions: 错题列表
    /// - Returns: PDF文件路径
    func exportAnalysisReport(wrongQuestions: [WrongQuestion]) -> URL? {
        isLoading = true

        guard let pdfData = PDFGenerator.shared.generateWrongQuestionsPDF(
            wrongQuestions: wrongQuestions,
            statistics: statistics
        ) else {
            errorMessage = "PDF生成失败"
            isLoading = false
            return nil
        }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd_HHmmss"
        let filename = "错题集_\(dateFormatter.string(from: Date()))"

        let url = PDFGenerator.shared.savePDF(pdfData, filename: filename)
        isLoading = false

        if url != nil {
            Logger.shared.info("PDF导出成功: \(filename)")
        } else {
            errorMessage = "PDF保存失败"
        }

        return url
    }

    /// 获取分享PDF的ActivityViewController
    /// - Parameter url: PDF文件路径
    /// - Returns: UIActivityViewController
    func getShareController(for url: URL) -> UIActivityViewController {
        return PDFGenerator.shared.sharePDF(url: url)
    }
}

// MARK: - Review Trend Data

/// 复习趋势数据
struct ReviewTrendData: Identifiable {
    let id = UUID()
    let date: Date
    let count: Int
}
