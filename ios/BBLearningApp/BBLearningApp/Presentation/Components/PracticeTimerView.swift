//
//  PracticeTimerView.swift
//  BBLearning
//
//  Created by Claude Code on 2025-10-15.
//

import SwiftUI

/// 练习计时器视图
struct PracticeTimerView: View {
    @ObservedObject var timerManager: PracticeTimerManager
    let type: TimerType

    enum TimerType {
        case session    // 会话计时
        case question   // 单题计时
    }

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: iconName)
                .font(.caption)

            Text(timeString)
                .font(.system(.caption, design: .monospaced))
                .fontWeight(.medium)
        }
        .foregroundColor(timerColor)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(timerColor.opacity(0.1))
        )
    }

    private var iconName: String {
        if timerManager.isPaused {
            return "pause.circle.fill"
        } else {
            return type == .session ? "clock.fill" : "timer"
        }
    }

    private var timeString: String {
        let seconds = type == .session ? timerManager.sessionElapsed : timerManager.questionElapsed
        return PracticeTimerManager.formatTime(seconds)
    }

    private var timerColor: Color {
        if timerManager.isPaused {
            return .orange
        }

        switch type {
        case .session:
            // 会话时间：超过30分钟变橙色
            return timerManager.sessionElapsed > 1800 ? .orange : .blue
        case .question:
            // 题目时间：根据用时分级
            if timerManager.questionElapsed < 30 {
                return .green
            } else if timerManager.questionElapsed < 90 {
                return .blue
            } else {
                return .orange
            }
        }
    }
}

// MARK: - Timer Control Button

/// 计时器控制按钮
struct TimerControlButton: View {
    @ObservedObject var timerManager: PracticeTimerManager
    let onPause: () -> Void
    let onResume: () -> Void

    var body: some View {
        Button(action: {
            if timerManager.isPaused {
                timerManager.resume()
                onResume()
            } else {
                timerManager.pause()
                onPause()
            }
        }) {
            Image(systemName: timerManager.isPaused ? "play.circle.fill" : "pause.circle.fill")
                .font(.title2)
                .foregroundColor(timerManager.isPaused ? .green : .orange)
        }
    }
}

// MARK: - Time Statistics Card

/// 时间统计卡片
struct TimeStatisticsCard: View {
    let totalTime: Int
    let averageTime: Int
    let fastestTime: Int
    let slowestTime: Int

    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 12) {
                TimeStatItem(
                    title: "总用时",
                    time: totalTime,
                    icon: "clock",
                    color: .blue
                )

                TimeStatItem(
                    title: "平均用时",
                    time: averageTime,
                    icon: "chart.bar",
                    color: .purple
                )
            }

            HStack(spacing: 12) {
                TimeStatItem(
                    title: "最快",
                    time: fastestTime,
                    icon: "hare.fill",
                    color: .green
                )

                TimeStatItem(
                    title: "最慢",
                    time: slowestTime,
                    icon: "tortoise.fill",
                    color: .orange
                )
            }
        }
        .padding()
        .background(Color.surface)
        .cornerRadius(12)
    }
}

struct TimeStatItem: View {
    let title: String
    let time: Int
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Spacer()
            }

            Text(PracticeTimerManager.formatTime(time))
                .font(.title3)
                .fontWeight(.bold)
                .monospacedDigit()

            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.background)
        .cornerRadius(8)
    }
}

// MARK: - Preview

#if DEBUG
struct PracticeTimerView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            let timerManager = PracticeTimerManager()

            PracticeTimerView(timerManager: timerManager, type: .session)

            PracticeTimerView(timerManager: timerManager, type: .question)

            TimeStatisticsCard(
                totalTime: 600,
                averageTime: 60,
                fastestTime: 30,
                slowestTime: 120
            )
        }
        .padding()
    }
}
#endif
