//
//  BiometricPromptView.swift
//  BBLearningApp
//
//  Created by Claude Code on 2025-10-15.
//  生物识别提示视图（未启用时显示）
//

import SwiftUI

/// 生物识别提示视图（引导用户启用）
struct BiometricPromptView: View {
    let biometricType: BiometricType

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: biometricType.iconName)
                .font(.title2)
                .foregroundColor(.blue.opacity(0.7))

            VStack(alignment: .leading, spacing: 4) {
                Text("支持\(biometricType.displayName)登录")
                    .font(.headline)
                    .foregroundColor(.text)

                Text("登录成功后即可启用快速登录")
                    .font(.caption)
                    .foregroundColor(.textSecondary)
            }

            Spacer()

            Image(systemName: "arrow.right.circle")
                .font(.title3)
                .foregroundColor(.blue.opacity(0.5))
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.blue.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.blue.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

// MARK: - Preview

#if DEBUG
struct BiometricPromptView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            BiometricPromptView(biometricType: .faceID)

            BiometricPromptView(biometricType: .touchID)
        }
        .padding()
        .background(Color.background)
    }
}
#endif
