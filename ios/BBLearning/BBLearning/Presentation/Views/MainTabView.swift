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
                KnowledgeTreeView()
            }
            .tabItem {
                Label("知识点", systemImage: "book.fill")
            }
            .tag(1)

            // 练习
            PracticeView()
                .tabItem {
                    Label("练习", systemImage: "pencil")
                }
                .tag(2)

            // AI辅导
            AITutorView()
                .tabItem {
                    Label("AI辅导", systemImage: "brain")
                }
                .tag(3)

            // 我的
            ProfileView()
                .tabItem {
                    Label("我的", systemImage: "person.fill")
                }
                .tag(4)
        }
        .accentColor(.primary)
    }
}

// MARK: - Placeholder Views

// HomeView is now replaced by Home/HomeView.swift
// See Home/HomeView.swift

// KnowledgeView is now replaced by KnowledgeTreeView
// See Knowledge/KnowledgeTreeView.swift

// PracticeView is now replaced by Practice/PracticeView.swift
// See Practice/PracticeView.swift

// AITutorView is now replaced by AITutor/AITutorView.swift
// See AITutor/AITutorView.swift

// ProfileView is now replaced by Profile/ProfileView.swift
// See Profile/ProfileView.swift

#if DEBUG
struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabView()
    }
}
#endif
