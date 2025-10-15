//
//  PracticeTimerManager.swift
//  BBLearning
//
//  Created by Claude Code on 2025-10-15.
//

import Foundation
import Combine

/// 练习计时器管理器
class PracticeTimerManager: ObservableObject {
    // MARK: - Published Properties

    @Published var sessionElapsed: Int = 0  // 会话总用时（秒）
    @Published var questionElapsed: Int = 0  // 当前题用时（秒）
    @Published var isRunning: Bool = false
    @Published var isPaused: Bool = false

    // MARK: - Private Properties

    private var sessionStartTime: Date?
    private var questionStartTime: Date?
    private var pauseStartTime: Date?
    private var totalPausedTime: TimeInterval = 0

    private var timer: AnyCancellable?

    // MARK: - Session Control

    /// 开始计时会话
    func startSession() {
        guard !isRunning else { return }

        sessionStartTime = Date()
        questionStartTime = Date()
        sessionElapsed = 0
        questionElapsed = 0
        totalPausedTime = 0
        isRunning = true
        isPaused = false

        startTimer()
        Logger.shared.info("练习计时会话已开始")
    }

    /// 结束计时会话
    func endSession() {
        guard isRunning else { return }

        stopTimer()
        isRunning = false
        isPaused = false

        Logger.shared.info("练习计时会话已结束，总用时：\(sessionElapsed)秒")
    }

    /// 暂停计时
    func pause() {
        guard isRunning && !isPaused else { return }

        pauseStartTime = Date()
        isPaused = true
        stopTimer()

        Logger.shared.info("练习计时已暂停")
    }

    /// 恢复计时
    func resume() {
        guard isRunning && isPaused else { return }

        if let pauseStart = pauseStartTime {
            totalPausedTime += Date().timeIntervalSince(pauseStart)
        }

        isPaused = false
        pauseStartTime = nil
        startTimer()

        Logger.shared.info("练习计时已恢复")
    }

    // MARK: - Question Control

    /// 开始新题计时
    func startQuestion() {
        questionStartTime = Date()
        questionElapsed = 0

        Logger.shared.info("新题计时已开始")
    }

    /// 结束当前题计时
    /// - Returns: 本题用时（秒）
    func endQuestion() -> Int {
        guard let startTime = questionStartTime else {
            return 0
        }

        let elapsed = Int(Date().timeIntervalSince(startTime))
        questionElapsed = elapsed

        Logger.shared.info("题目完成，用时：\(elapsed)秒")
        return elapsed
    }

    // MARK: - Timer Management

    private func startTimer() {
        timer = Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.updateElapsedTime()
            }
    }

    private func stopTimer() {
        timer?.cancel()
        timer = nil
    }

    private func updateElapsedTime() {
        guard let sessionStart = sessionStartTime,
              let questionStart = questionStartTime else {
            return
        }

        // 计算会话总用时（扣除暂停时间）
        let totalElapsed = Date().timeIntervalSince(sessionStart) - totalPausedTime
        sessionElapsed = max(0, Int(totalElapsed))

        // 计算当前题用时
        let questionTotalElapsed = Date().timeIntervalSince(questionStart)
        questionElapsed = max(0, Int(questionTotalElapsed))
    }

    // MARK: - Helper Methods

    /// 格式化时间显示（MM:SS）
    /// - Parameter seconds: 秒数
    /// - Returns: 格式化字符串
    static func formatTime(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let secs = seconds % 60
        return String(format: "%02d:%02d", minutes, secs)
    }

    /// 格式化时间显示（HH:MM:SS）
    /// - Parameter seconds: 秒数
    /// - Returns: 格式化字符串
    static func formatLongTime(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let secs = seconds % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, secs)
        } else {
            return String(format: "%02d:%02d", minutes, secs)
        }
    }

    /// 获取时间等级（用于UI颜色）
    /// - Parameter seconds: 秒数
    /// - Parameter avgTime: 平均时间
    /// - Returns: 等级（fast/normal/slow）
    static func getTimeLevel(seconds: Int, avgTime: Int) -> TimeLevel {
        let ratio = Double(seconds) / Double(max(avgTime, 1))

        if ratio < 0.7 {
            return .fast
        } else if ratio > 1.5 {
            return .slow
        } else {
            return .normal
        }
    }

    enum TimeLevel {
        case fast
        case normal
        case slow

        var color: String {
            switch self {
            case .fast: return "green"
            case .normal: return "blue"
            case .slow: return "orange"
            }
        }

        var icon: String {
            switch self {
            case .fast: return "hare.fill"
            case .normal: return "figure.walk"
            case .slow: return "tortoise.fill"
            }
        }
    }

    // MARK: - Reset

    /// 重置计时器
    func reset() {
        stopTimer()
        sessionStartTime = nil
        questionStartTime = nil
        pauseStartTime = nil
        totalPausedTime = 0
        sessionElapsed = 0
        questionElapsed = 0
        isRunning = false
        isPaused = false

        Logger.shared.info("计时器已重置")
    }
}
