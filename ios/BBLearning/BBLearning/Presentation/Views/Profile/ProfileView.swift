//
//  ProfileView.swift
//  BBLearning
//
//  Created by Claude Code on 2025-10-13.
//

import SwiftUI

struct ProfileView: View {
    @StateObject private var viewModel = ProfileViewModel()
    @EnvironmentObject var appState: AppState

    var body: some View {
        List {
            // 用户信息
            userInfoSection

            // 学习数据
            Section("学习数据") {
                NavigationLink(destination: Text("学习报告")) {
                    Label("学习报告", systemImage: "chart.bar.fill")
                }

                NavigationLink(destination: WrongQuestionView()) {
                    Label("错题本", systemImage: "exclamationmark.triangle.fill")
                }
            }

            // 设置
            Section("设置") {
                NavigationLink(destination: Text("账号设置")) {
                    Label("账号设置", systemImage: "person.circle")
                }

                NavigationLink(destination: Text("通知设置")) {
                    Label("通知设置", systemImage: "bell")
                }

                NavigationLink(destination: Text("关于")) {
                    Label("关于", systemImage: "info.circle")
                }
            }

            // 退出登录
            Section {
                Button(action: {
                    viewModel.showLogoutAlert = true
                }) {
                    HStack {
                        Spacer()
                        Text("退出登录")
                            .foregroundColor(.red)
                        Spacer()
                    }
                }
            }
        }
        .navigationTitle("我的")
        .alert("退出登录", isPresented: $viewModel.showLogoutAlert) {
            Button("取消", role: .cancel) {}
            Button("退出", role: .destructive) {
                viewModel.logout()
                appState.logout()
            }
        } message: {
            Text("确定要退出登录吗？")
        }
    }

    // MARK: - User Info Section

    private var userInfoSection: some View {
        Section {
            HStack(spacing: 16) {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)

                VStack(alignment: .leading, spacing: 4) {
                    Text(appState.currentUser?.nickname ?? "学生")
                        .font(.title2)
                        .fontWeight(.semibold)

                    Text("\(appState.currentUser?.grade ?? 7)年级")
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
            }
            .padding(.vertical, 8)
        }
    }
}

#if DEBUG
struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ProfileView()
                .environmentObject(AppState())
        }
    }
}
#endif
