//
//  BiometricSettingsRow.swift
//  BBLearningApp
//
//  Created by Claude Code on 2025-10-15.
//  生物识别设置行组件
//

import SwiftUI

/// 生物识别设置行
struct BiometricSettingsRow: View {
    @Binding var isEnabled: Bool
    let biometricType: BiometricType
    let onToggle: (Bool) -> Void

    var body: some View {
        HStack(spacing: 12) {
            // 图标
            Image(systemName: biometricType.iconName)
                .font(.title3)
                .foregroundColor(.blue)
                .frame(width: 24)

            // 文本
            VStack(alignment: .leading, spacing: 4) {
                Text("\(biometricType.displayName)登录")
                    .font(.body)

                Text(statusText)
                    .font(.caption)
                    .foregroundColor(.textSecondary)
            }

            Spacer()

            // 开关
            Toggle("", isOn: $isEnabled)
                .labelsHidden()
                .onChange(of: isEnabled) { newValue in
                    onToggle(newValue)
                }
        }
        .padding(.vertical, 4)
    }

    private var statusText: String {
        if isEnabled {
            return "已启用 - 使用\(biometricType.displayName)快速登录"
        } else {
            return "未启用 - 启用后可快速登录"
        }
    }
}

// MARK: - Preview

#if DEBUG
struct BiometricSettingsRow_Previews: PreviewProvider {
    static var previews: some View {
        List {
            BiometricSettingsRow(
                isEnabled: .constant(true),
                biometricType: .faceID,
                onToggle: { _ in }
            )

            BiometricSettingsRow(
                isEnabled: .constant(false),
                biometricType: .touchID,
                onToggle: { _ in }
            )
        }
    }
}
#endif
