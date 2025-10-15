//
//  NotificationSettingsView.swift
//  BBLearning
//
//  Created by Claude Code on 2025-10-15.
//

import SwiftUI
import UserNotifications

struct NotificationSettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()

    var body: some View {
        Form {
            Section {
                Toggle("推送通知", isOn: $viewModel.settings.notifications.enabled)
                    .onChange(of: viewModel.settings.notifications.enabled) { newValue in
                        if newValue {
                            viewModel.requestNotificationPermission()
                        }
                    }
            } footer: {
                if viewModel.notificationPermission == .denied {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("通知权限已被拒绝")
                            .foregroundColor(.orange)

                        Button("在系统设置中开启通知") {
                            viewModel.openAppSettings()
                        }
                        .font(.caption)
                    }
                }
            }

            if viewModel.settings.notifications.enabled {
                Section("提醒设置") {
                    Toggle("学习提醒", isOn: $viewModel.settings.notifications.studyReminder)

                    if viewModel.settings.notifications.studyReminder {
                        DatePicker(
                            "提醒时间",
                            selection: Binding(
                                get: { viewModel.settings.notifications.studyReminderTime ?? Date() },
                                set: { viewModel.settings.notifications.studyReminderTime = $0 }
                            ),
                            displayedComponents: .hourAndMinute
                        )
                    }

                    Toggle("错题复习提醒", isOn: $viewModel.settings.notifications.reviewReminder)

                    Toggle("成就通知", isOn: $viewModel.settings.notifications.achievementNotification)
                }
            }
        }
        .navigationTitle("通知设置")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.loadSettings()
        }
        .onDisappear {
            viewModel.saveSettings()
        }
    }
}

// MARK: - SettingsViewModel

class SettingsViewModel: BaseViewModel {
    @Published var settings: AppSettings
    @Published var notificationPermission: UNAuthorizationStatus = .notDetermined

    private let settingsManager = SettingsManager.shared

    override init() {
        self.settings = settingsManager.loadSettings()
        super.init()
        checkNotificationPermission()
    }

    func loadSettings() {
        settings = settingsManager.loadSettings()
    }

    func saveSettings() {
        settingsManager.saveSettings(settings)
    }

    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
            DispatchQueue.main.async {
                self.checkNotificationPermission()
            }
        }
    }

    func checkNotificationPermission() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.notificationPermission = settings.authorizationStatus
            }
        }
    }

    func openAppSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}

#if DEBUG
struct NotificationSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            NotificationSettingsView()
        }
    }
}
#endif
