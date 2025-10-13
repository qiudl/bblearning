//
//  MainTabView.swift
//  BBLearning
//
//  Created by Claude Code on 2025-10-13.
//

import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            // 首页
            NavigationView {
                HomeView()
            }
            .tabItem {
                Label("首页", systemImage: "house.fill")
            }
            .tag(0)

            // 知识点
            NavigationView {
                KnowledgeView()
            }
            .tabItem {
                Label("知识点", systemImage: "book.fill")
            }
            .tag(1)

            // 练习
            NavigationView {
                PracticeView()
            }
            .tabItem {
                Label("练习", systemImage: "pencil")
            }
            .tag(2)

            // AI辅导
            NavigationView {
                AITutorView()
            }
            .tabItem {
                Label("AI辅导", systemImage: "brain")
            }
            .tag(3)

            // 我的
            NavigationView {
                ProfileView()
            }
            .tabItem {
                Label("我的", systemImage: "person.fill")
            }
            .tag(4)
        }
        .accentColor(.primary)
    }
}

// MARK: - Placeholder Views

struct HomeView: View {
    var body: some View {
        Text("首页")
            .navigationTitle("BBLearning")
    }
}

struct KnowledgeView: View {
    var body: some View {
        Text("知识点")
            .navigationTitle("知识点")
    }
}

struct PracticeView: View {
    var body: some View {
        Text("练习")
            .navigationTitle("练习")
    }
}

struct AITutorView: View {
    var body: some View {
        Text("AI辅导")
            .navigationTitle("AI辅导")
    }
}

struct ProfileView: View {
    var body: some View {
        Text("个人中心")
            .navigationTitle("我的")
    }
}

#if DEBUG
struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabView()
    }
}
#endif
