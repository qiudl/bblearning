//
//  BBLearningApp.swift
//  BBLearning
//
//  Created by Claude Code on 2025-10-13.
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

#if os(iOS)
@main
struct BBLearningApp: App {
    @StateObject private var appState = AppState()

    init() {
        setupDependencies()
        setupAppearance()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .preferredColorScheme(appState.colorScheme)
        }
    }

    // MARK: - Setup

    private func setupDependencies() {
        // Initialize DI Container
        _ = DIContainer.shared
    }

    private func setupAppearance() {
        #if canImport(UIKit)
        // Configure navigation bar appearance
        let appearance = UINavigationBarAppearance()
        appearance.configureWithDefaultBackground()
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance

        // Configure tab bar appearance
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithDefaultBackground()
        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
        #endif
    }
}
#endif

// MARK: - App State

class AppState: ObservableObject {
    @Published var colorScheme: ColorScheme?
    @Published var isLoggedIn: Bool = false
    @Published var currentUser: User?

    init() {
        checkAuthStatus()
    }

    private func checkAuthStatus() {
        // Check if user is logged in
        if KeychainManager.shared.getAccessToken() != nil {
            isLoggedIn = true
            // Load user info if needed
        }
    }

    func login(user: User) {
        currentUser = user
        isLoggedIn = true
    }

    func logout() {
        currentUser = nil
        isLoggedIn = false
    }
}

// MARK: - Content View

struct ContentView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        if appState.isLoggedIn {
            MainTabView()
        } else {
            LoginView()
        }
    }
}
