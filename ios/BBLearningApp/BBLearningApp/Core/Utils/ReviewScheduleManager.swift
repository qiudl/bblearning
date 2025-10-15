//
//  ReviewScheduleManager.swift
//  BBLearning
//
//  Created by Claude Code on 2025-10-15.
//

import Foundation

/// 复习计划模型
struct ReviewSchedule: Codable, Equatable {
    var nextReviewDate: Date
    var reviewCount: Int
    var reviewDates: [Date]
    var intervals: [Int]

    /// 艾宾浩斯遗忘曲线间隔（天）：1, 2, 4, 7, 15
    static let ebbinghausIntervals = [1, 2, 4, 7, 15]

    init(
        nextReviewDate: Date = Date(),
        reviewCount: Int = 0,
        reviewDates: [Date] = [],
        intervals: [Int] = []
    ) {
        self.nextReviewDate = nextReviewDate
        self.reviewCount = reviewCount
        self.reviewDates = reviewDates
        self.intervals = intervals
    }
}

/// 复习计划管理器
class ReviewScheduleManager {
    static let shared = ReviewScheduleManager()

    private init() {}

    /// 计算下次复习时间
    /// - Parameter reviewCount: 当前已复习次数
    /// - Returns: 下次复习的日期
    func calculateNextReviewDate(reviewCount: Int) -> Date {
        let interval = getInterval(for: reviewCount)
        let calendar = Calendar.current
        return calendar.date(byAdding: .day, value: interval, to: Date()) ?? Date()
    }

    /// 获取复习间隔天数
    /// - Parameter reviewCount: 复习次数
    /// - Returns: 间隔天数
    private func getInterval(for reviewCount: Int) -> Int {
        let intervals = ReviewSchedule.ebbinghausIntervals
        let index = min(reviewCount, intervals.count - 1)
        return intervals[index]
    }

    /// 获取今日待复习列表
    /// - Parameter allSchedules: 所有复习计划
    /// - Returns: 今日需要复习的计划列表
    func getTodayReviewList(from allSchedules: [ReviewSchedule]) -> [ReviewSchedule] {
        let today = Calendar.current.startOfDay(for: Date())

        return allSchedules.filter { schedule in
            let reviewDay = Calendar.current.startOfDay(for: schedule.nextReviewDate)
            return reviewDay <= today
        }
    }

    /// 更新复习记录
    /// - Parameters:
    ///   - schedule: 当前复习计划
    ///   - isCorrect: 本次复习是否正确
    /// - Returns: 更新后的复习计划
    func recordReview(for schedule: ReviewSchedule, isCorrect: Bool) -> ReviewSchedule {
        var updatedSchedule = schedule
        let now = Date()

        // 添加复习记录
        updatedSchedule.reviewDates.append(now)

        if isCorrect {
            // 正确：进入下一个复习阶段
            updatedSchedule.reviewCount += 1
            let interval = getInterval(for: updatedSchedule.reviewCount)
            updatedSchedule.intervals.append(interval)

            let calendar = Calendar.current
            updatedSchedule.nextReviewDate = calendar.date(
                byAdding: .day,
                value: interval,
                to: now
            ) ?? now
        } else {
            // 错误：重新开始
            updatedSchedule.reviewCount = 0
            updatedSchedule.intervals.append(1)

            let calendar = Calendar.current
            updatedSchedule.nextReviewDate = calendar.date(
                byAdding: .day,
                value: 1,
                to: now
            ) ?? now
        }

        return updatedSchedule
    }

    /// 创建新的复习计划
    /// - Returns: 新的复习计划
    func createNewSchedule() -> ReviewSchedule {
        let calendar = Calendar.current
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: Date()) ?? Date()

        return ReviewSchedule(
            nextReviewDate: tomorrow,
            reviewCount: 0,
            reviewDates: [],
            intervals: []
        )
    }

    /// 判断是否需要复习
    /// - Parameter schedule: 复习计划
    /// - Returns: 是否需要复习
    func needsReview(_ schedule: ReviewSchedule) -> Bool {
        let today = Calendar.current.startOfDay(for: Date())
        let reviewDay = Calendar.current.startOfDay(for: schedule.nextReviewDate)
        return reviewDay <= today
    }

    /// 计算距离下次复习的天数
    /// - Parameter schedule: 复习计划
    /// - Returns: 天数
    func daysUntilNextReview(_ schedule: ReviewSchedule) -> Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let reviewDay = calendar.startOfDay(for: schedule.nextReviewDate)

        let components = calendar.dateComponents([.day], from: today, to: reviewDay)
        return components.day ?? 0
    }
}
