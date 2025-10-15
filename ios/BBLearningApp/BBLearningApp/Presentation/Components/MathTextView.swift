//
//  MathTextView.swift
//  BBLearningApp
//
//  Created by Claude Code on 2025-10-15.
//  LaTeX数学公式渲染组件
//

import SwiftUI
import WebKit

/// LaTeX数学公式渲染视图
struct MathTextView: UIViewRepresentable {
    let content: String
    @Binding var height: CGFloat

    init(content: String, height: Binding<CGFloat> = .constant(0)) {
        self.content = content
        self._height = height
    }

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        webView.scrollView.isScrollEnabled = false
        webView.backgroundColor = .clear
        webView.isOpaque = false
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        let html = generateHTML(content: content)
        webView.loadHTMLString(html, baseURL: nil)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: MathTextView

        init(_ parent: MathTextView) {
            self.parent = parent
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            // 获取内容高度
            webView.evaluateJavaScript("document.documentElement.scrollHeight") { (result, error) in
                if let height = result as? CGFloat {
                    DispatchQueue.main.async {
                        self.parent.height = height
                    }
                }
            }
        }
    }

    private func generateHTML(content: String) -> String {
        let processedContent = preprocessLatex(content)

        return """
        <!DOCTYPE html>
        <html>
        <head>
            <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
            <script src="https://polyfill.io/v3/polyfill.min.js?features=es6"></script>
            <script id="MathJax-script" async src="https://cdn.jsdelivr.net/npm/mathjax@3/es5/tex-mml-chtml.js"></script>
            <style>
                body {
                    font-family: -apple-system, BlinkMacSystemFont, "SF Pro Text", "Helvetica Neue", Helvetica, Arial, sans-serif;
                    font-size: 17px;
                    line-height: 1.6;
                    color: #000000;
                    padding: 0;
                    margin: 0;
                    background-color: transparent;
                }
                p {
                    margin: 8px 0;
                }
                .math-inline {
                    display: inline;
                }
                .math-block {
                    display: block;
                    text-align: center;
                    margin: 16px 0;
                }
                @media (prefers-color-scheme: dark) {
                    body {
                        color: #ffffff;
                    }
                }
            </style>
            <script>
                MathJax = {
                    tex: {
                        inlineMath: [['$', '$']],
                        displayMath: [['$$', '$$']],
                        processEscapes: true
                    },
                    svg: {
                        fontCache: 'global'
                    }
                };
            </script>
        </head>
        <body>
            \(processedContent)
        </body>
        </html>
        """
    }

    /// 预处理LaTeX内容，确保正确识别
    private func preprocessLatex(_ content: String) -> String {
        var result = content

        // 处理换行
        result = result.replacingOccurrences(of: "\n", with: "<br>")

        // 转义HTML特殊字符（除了已经在LaTeX中的）
        result = result.replacingOccurrences(of: "&", with: "&amp;")
        result = result.replacingOccurrences(of: "<br>", with: "<br>") // 保留换行

        return result
    }
}

/// 自适应高度的LaTeX文本视图
struct AdaptiveMathTextView: View {
    let content: String
    @State private var contentHeight: CGFloat = 100

    var body: some View {
        MathTextView(content: content, height: $contentHeight)
            .frame(height: contentHeight)
    }
}

// MARK: - Preview

#if DEBUG
struct MathTextView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            Text("行内公式示例")
                .font(.headline)

            AdaptiveMathTextView(content: "勾股定理：$a^2 + b^2 = c^2$")
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)

            Text("块级公式示例")
                .font(.headline)

            AdaptiveMathTextView(content: """
                二次方程求根公式：
                $$x = \\frac{-b \\pm \\sqrt{b^2 - 4ac}}{2a}$$
                """)
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)

            Text("混合内容示例")
                .font(.headline)

            AdaptiveMathTextView(content: """
                有理数是整数和分数的统称。有理数可以表示为 $\\frac{p}{q}$ 的形式，其中 $p$ 和 $q$ 为整数且 $q \\neq 0$。

                常见的有理数运算法则：
                $$\\frac{a}{b} + \\frac{c}{d} = \\frac{ad + bc}{bd}$$
                """)
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
        }
        .padding()
    }
}
#endif
