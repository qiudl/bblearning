//
//  LoginView.swift
//  BBLearning
//
//  Created by Claude Code on 2025-10-13.
//

import SwiftUI

struct LoginView: View {
    @StateObject private var viewModel = LoginViewModel()
    @State private var navigateToRegister = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Logo和标题
                    VStack(spacing: 16) {
                        Image(systemName: "graduationcap.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 80, height: 80)
                            .foregroundColor(.primary)

                        Text("BBLearning")
                            .font(.largeTitle)
                            .fontWeight(.bold)

                        Text("初中数学AI学习平台")
                            .font(.subheadline)
                            .foregroundColor(.textSecondary)
                    }
                    .padding(.top, 60)

                    // 登录表单
                    VStack(spacing: 16) {
                        CustomTextField(
                            title: "用户名",
                            text: $viewModel.username,
                            placeholder: "请输入用户名",
                            icon: "person"
                        )

                        CustomTextField(
                            title: "密码",
                            text: $viewModel.password,
                            placeholder: "请输入密码",
                            isSecure: true,
                            icon: "lock"
                        )

                        // 记住密码
                        HStack {
                            Toggle("记住密码", isOn: $viewModel.rememberPassword)
                                .font(.subheadline)

                            Spacer()

                            Button("忘记密码?") {
                                // TODO: 忘记密码逻辑
                            }
                            .font(.subheadline)
                            .foregroundColor(.primary)
                        }
                    }
                    .padding(.top, 32)

                    // 登录按钮
                    CustomButton(
                        title: "登录",
                        action: viewModel.login,
                        isEnabled: !viewModel.username.isEmpty && !viewModel.password.isEmpty,
                        isLoading: viewModel.isLoading
                    )
                    .padding(.top, 16)

                    // 注册
                    HStack {
                        Text("还没有账号?")
                            .foregroundColor(.textSecondary)

                        Button("立即注册") {
                            navigateToRegister = true
                        }
                        .foregroundColor(.primary)
                    }
                    .font(.subheadline)
                    .padding(.top, 8)

                    Spacer()
                }
                .padding(.horizontal, 32)
            }
            .background(Color.background.ignoresSafeArea())
            .navigationBarHidden(true)
        }
        .errorAlert(error: $viewModel.errorMessage)
        .fullScreenCover(isPresented: $viewModel.isLoginSuccessful) {
            MainTabView()
        }
        .sheet(isPresented: $navigateToRegister) {
            RegisterView()
        }
    }
}

#if DEBUG
struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
    }
}
#endif
