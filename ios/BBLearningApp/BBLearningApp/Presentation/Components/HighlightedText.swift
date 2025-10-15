//
//  HighlightedText.swift
//  BBLearningApp
//
//  Created by Claude Code on 2025-10-15.
//  搜索高亮文本组件
//

import SwiftUI

/// 高亮文本视图
struct HighlightedText: View {
    let text: String
    let highlight: String
    let highlightColor: Color
    let font: Font

    init(
        text: String,
        highlight: String,
        highlightColor: Color = .yellow,
        font: Font = .body
    ) {
        self.text = text
        self.highlight = highlight
        self.highlightColor = highlightColor
        self.font = font
    }

    var body: some View {
        Text(attributedString)
            .font(font)
    }

    private var attributedString: AttributedString {
        var attributedString = AttributedString(text)

        // 如果高亮关键词为空，直接返回原文本
        guard !highlight.trimmed.isEmpty else {
            return attributedString
        }

        // 查找所有匹配位置并高亮
        let lowercasedText = text.lowercased()
        let lowercasedHighlight = highlight.lowercased()

        var searchRange = lowercasedText.startIndex..<lowercasedText.endIndex

        while let range = lowercasedText.range(of: lowercasedHighlight, range: searchRange) {
            // 转换为AttributedString的范围
            if let attributedRange = Range(range, in: attributedString) {
                attributedString[attributedRange].backgroundColor = highlightColor
                attributedString[attributedRange].foregroundColor = .black
            }

            // 移动搜索范围到当前匹配之后
            searchRange = range.upperBound..<lowercasedText.endIndex
        }

        return attributedString
    }
}

// MARK: - Preview

#if DEBUG
struct HighlightedText_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            HighlightedText(
                text: "有理数的加减法",
                highlight: "有理数",
                highlightColor: .yellow,
                font: .headline
            )

            HighlightedText(
                text: "勾股定理是直角三角形的重要定理",
                highlight: "定理",
                highlightColor: .orange.opacity(0.3),
                font: .body
            )

            HighlightedText(
                text: "二次函数的图像是抛物线",
                highlight: "函数",
                highlightColor: .green.opacity(0.3),
                font: .callout
            )

            HighlightedText(
                text: "No highlight if keyword is empty",
                highlight: "",
                font: .caption
            )
        }
        .padding()
    }
}
#endif
