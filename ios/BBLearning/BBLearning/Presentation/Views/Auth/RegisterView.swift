//
//  RegisterView.swift
//  BBLearning
//
//  Created by Claude Code on 2025-10-13.
//

import SwiftUI

struct RegisterView: View {
    @StateObject private var viewModel = RegisterViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // 标题
                    Text("创建账号")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 20)

                    // 表单
                    VStack(spacing: 16) {
                        // 用户名
                        VStack(alignment: .leading, spacing: 4) {
                            CustomTextField(
                                title: "用户名",
                                text: $viewModel.username,
                                placeholder: "3-20个字符，字母数字下划线",
                                icon: "person"
                            )

                            if let available = viewModel.usernameAvailable {
                                HStack {
                                    Image(systemName: available ? "checkmark.circle.fill" : "xmark.circle.fill")
                                    Text(available ? "用户名可用" : "用户名已被使用")
                                }
                                .font(.caption)
                                .foregroundColor(available ? .green : .red)
                            }
                        }

                        // 密码
                        VStack(alignment: .leading, spacing: 4) {
                            CustomTextField(
                                title: "密码",
                                text: $viewModel.password,
                                placeholder: "6-20个字符",
                                isSecure: true,
                                icon: "lock"
                            )

                            // 密码强度
                            HStack {
                                ForEach(0..<3) { index in
                                    Rectangle()
                                        .fill(strengthColor(index: index))
                                        .frame(height: 4)
                                        .cornerRadius(2)
                                }
                            }

                            Text(viewModel.passwordStrengthText)
                                .font(.caption)
                                .foregroundColor(Color(viewModel.passwordStrengthColor))
                        }

                        // 确认密码
                        CustomTextField(
                            title: "确认密码",
                            text: $viewModel.confirmPassword,
                            placeholder: "请再次输入密码",
                            isSecure: true,
                            icon: "lock"
                        )

                        // 昵称
                        CustomTextField(
                            title: "昵称",
                            text: $viewModel.nickname,
                            placeholder: "2-20个字符",
                            icon: "pencil"
                        )

                        // 年级选择
                        VStack(alignment: .leading, spacing: 8) {
                            Text("年级")
                                .font(.subheadline)
                                .foregroundColor(.textSecondary)

                            Picker("年级", selection: $viewModel.selectedGrade) {
                                ForEach(viewModel.grades, id: \.self) { grade in
                                    Text("\(grade)年级").tag(grade)
                                }
                            }
                            .pickerStyle(SegmentedPickerStyle())
                        }
                    }

                    // 注册按钮
                    CustomButton(
                        title: "注册",
                        action: viewModel.register,
                        isEnabled: viewModel.isFormValid,
                        isLoading: viewModel.isLoading
                    )
                    .padding(.top, 16)

                    Spacer()
                }
                .padding(.horizontal, 32)
            }
            .background(Color.background.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
            }
        }
        .errorAlert(error: $viewModel.errorMessage)
        .onChange(of: viewModel.isRegisterSuccessful) { success in
            if success {
                dismiss()
            }
        }
    }

    private func strengthColor(index: Int) -> Color {
        let strength = viewModel.passwordStrength
        switch strength {
        case .weak:
            return index == 0 ? .red : .gray.opacity(0.3)
        case .medium:
            return index < 2 ? .orange : .gray.opacity(0.3)
        case .strong:
            return .green
        }
    }
}

#if DEBUG
struct RegisterView_Previews: PreviewProvider {
    static var previews: some View {
        RegisterView()
    }
}
#endif
