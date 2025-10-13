//
//  ContentView.swift
//  BBLearning
//
//  Created by Claude Code on 2025-10-13.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var appState = AppState()

    var body: some View {
        Group {
            if appState.isLoggedIn {
                MainTabView()
            } else {
                LoginView()
            }
        }
        .environmentObject(appState)
    }
}

/// 应用状态管理
class AppState: ObservableObject {
    @Published var isLoggedIn: Bool = false
    @Published var currentUser: User?

    init() {
        checkLoginStatus()
    }

    private func checkLoginStatus() {
        // 检查是否有有效的Token
        let loginUseCase = DIContainer.shared.resolve(LoginUseCase.self)
        isLoggedIn = loginUseCase.isLoggedIn()
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

#if DEBUG
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
#endif
