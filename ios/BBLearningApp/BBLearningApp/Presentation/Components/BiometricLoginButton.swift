//
//  BiometricLoginButton.swift
//  BBLearningApp
//
//  Created by Claude Code on 2025-10-15.
//  生物识别快速登录按钮
//

import SwiftUI

/// 生物识别登录按钮
struct BiometricLoginButton: View {
    let biometricType: BiometricType
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: biometricType.iconName)
                    .font(.title2)
                    .foregroundColor(.white)

                VStack(alignment: .leading, spacing: 4) {
                    Text("快速登录")
                        .font(.headline)
                        .foregroundColor(.white)

                    Text("使用\(biometricType.displayName)")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                }

                Spacer()

                Image(systemName: "arrow.right")
                    .font(.body)
                    .foregroundColor(.white)
            }
            .padding()
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [Color.blue, Color.purple]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(12)
            .shadow(color: Color.blue.opacity(0.3), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview

#if DEBUG
struct BiometricLoginButton_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            BiometricLoginButton(
                biometricType: .faceID,
                action: { print("Face ID login") }
            )

            BiometricLoginButton(
                biometricType: .touchID,
                action: { print("Touch ID login") }
            )
        }
        .padding()
        .background(Color.background)
    }
}
#endif
