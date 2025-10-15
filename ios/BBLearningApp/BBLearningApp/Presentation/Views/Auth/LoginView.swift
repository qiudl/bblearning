//
//  LoginView.swift
//  BBLearning
//
//  Created by Claude Code on 2025-10-13.
//

import SwiftUI

struct LoginViewWithBiometric: View {
    @StateObject private var viewModel = LoginViewModel()
    @State private var navigateToRegister = false
    @EnvironmentObject var appState: AppState

    var body: some View {
        let _ = print("🖥️ [LoginView] Rendering with:")
        let _ = print("   - isBiometricAvailable: \(viewModel.isBiometricAvailable)")
        let _ = print("   - isBiometricEnabled: \(viewModel.isBiometricEnabled)")
        let _ = print("   - biometricType: \(viewModel.biometricType)")

        return NavigationView {
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

                    // 生物识别快速登录按钮
                    if viewModel.isBiometricAvailable {
                        if viewModel.isBiometricEnabled {
                            // 已启用：显示快速登录按钮
                            BiometricLoginButton(
                                biometricType: viewModel.biometricType,
                                action: viewModel.loginWithBiometric
                            )
                            .padding(.top, 20)
                        } else {
                            // 未启用：显示提示信息
                            BiometricPromptView(biometricType: viewModel.biometricType)
                                .padding(.top, 20)
                        }
                    }

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
            .onAppear {
                print("🎬 [LoginView] onAppear - 强制刷新生物识别状态")
                viewModel.refreshBiometricStatus()
            }
        }
        .errorAlert(error: $viewModel.errorMessage)
        .alert("启用生物识别登录", isPresented: $viewModel.showBiometricEnablePrompt) {
            Button("启用") {
                viewModel.enableBiometricAuthFromLastLogin()
            }
            Button("暂不启用", role: .cancel) {
                viewModel.showBiometricEnablePrompt = false
            }
        } message: {
            Text(viewModel.biometricTypeDescription)
        }
        .onChange(of: viewModel.isLoginSuccessful) { isSuccessful in
            if isSuccessful {
                // 通知AppState更新登录状态
                appState.login()
            }
        }
        .sheet(isPresented: $navigateToRegister) {
            RegisterView()
        }
    }
}

#if DEBUG
struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginViewWithBiometric()
            .environmentObject(AppState())
    }
}
#endif
