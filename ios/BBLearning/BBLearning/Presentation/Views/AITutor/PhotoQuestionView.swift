//
//  PhotoQuestionView.swift
//  BBLearning
//
//  Created by Claude Code on 2025-10-13.
//

import SwiftUI

struct PhotoQuestionView: View {
    @Environment(\.dismiss) var dismiss
    let image: UIImage
    let recognizedText: String
    let onSubmit: () -> Void
    let onCancel: () -> Void

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // 图片预览
                    imagePreview

                    // 识别结果
                    recognizedTextView

                    // 提示
                    tipsView

                    // 按钮
                    actionButtons
                }
                .padding()
            }
            .navigationTitle("拍照识题")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        onCancel()
                    }
                }
            }
        }
    }

    // MARK: - Image Preview

    private var imagePreview: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("拍摄的题目")
                .font(.headline)

            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .frame(maxHeight: 300)
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.1), radius: 5)
        }
    }

    // MARK: - Recognized Text

    private var recognizedTextView: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("识别结果")
                    .font(.headline)

                Spacer()

                if recognizedText == "识别中..." {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }

            Text(recognizedText)
                .font(.body)
                .foregroundColor(recognizedText == "识别中..." ? .textSecondary : .text)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.surface)
                .cornerRadius(12)
        }
    }

    // MARK: - Tips

    private var tipsView: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "lightbulb.fill")
                .foregroundColor(.orange)

            VStack(alignment: .leading, spacing: 4) {
                Text("拍照提示")
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Text("• 确保题目清晰可见\n• 光线充足\n• 避免反光和阴影\n• 题目占据画面主体")
                    .font(.caption)
                    .foregroundColor(.textSecondary)
                    .lineSpacing(4)
            }
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(12)
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        VStack(spacing: 12) {
            // 提交按钮
            CustomButton(
                title: "请AI解答",
                action: {
                    onSubmit()
                    dismiss()
                },
                isEnabled: recognizedText != "识别中..."
            )

            // 重新拍摄
            Button(action: {
                onCancel()
            }) {
                Text("重新拍摄")
                    .font(.headline)
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.surface)
                    .cornerRadius(12)
            }
        }
    }
}

#if DEBUG
struct PhotoQuestionView_Previews: PreviewProvider {
    static var previews: some View {
        PhotoQuestionView(
            image: UIImage(systemName: "photo")!,
            recognizedText: "已识别题目：\n\n求解方程：2x + 5 = 15",
            onSubmit: {},
            onCancel: {}
        )
    }
}
#endif
