//
//  PDFGenerator.swift
//  BBLearning
//
//  Created by Claude Code on 2025-10-15.
//

import UIKit
import PDFKit

/// PDF生成器
class PDFGenerator {
    static let shared = PDFGenerator()

    private init() {}

    /// 生成错题集PDF
    /// - Parameters:
    ///   - wrongQuestions: 错题列表
    ///   - statistics: 统计数据
    /// - Returns: PDF数据
    func generateWrongQuestionsPDF(
        wrongQuestions: [WrongQuestion],
        statistics: WrongQuestionStatistics?
    ) -> Data? {
        let pdfMetaData = [
            kCGPDFContextCreator: "BBLearning",
            kCGPDFContextAuthor: "AI学习助手",
            kCGPDFContextTitle: "错题集"
        ]

        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]

        let pageWidth = 8.5 * 72.0  // Letter size: 8.5 x 11 inches
        let pageHeight = 11 * 72.0
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)

        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)

        let data = renderer.pdfData { context in
            // 封面页
            drawCoverPage(context: context, pageRect: pageRect, statistics: statistics)

            // 统计页
            if let stats = statistics {
                drawStatisticsPage(context: context, pageRect: pageRect, statistics: stats)
            }

            // 错题详情页
            drawWrongQuestionsPages(
                context: context,
                pageRect: pageRect,
                wrongQuestions: wrongQuestions
            )
        }

        return data
    }

    // MARK: - Cover Page

    private func drawCoverPage(
        context: UIGraphicsPDFRendererContext,
        pageRect: CGRect,
        statistics: WrongQuestionStatistics?
    ) {
        context.beginPage()

        // 标题
        let titleFont = UIFont.boldSystemFont(ofSize: 36)
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: titleFont,
            .foregroundColor: UIColor.systemBlue
        ]

        let title = "BBLearning 错题集"
        let titleSize = title.size(withAttributes: titleAttributes)
        let titleRect = CGRect(
            x: (pageRect.width - titleSize.width) / 2,
            y: 150,
            width: titleSize.width,
            height: titleSize.height
        )
        title.draw(in: titleRect, withAttributes: titleAttributes)

        // 日期
        let dateFont = UIFont.systemFont(ofSize: 18)
        let dateAttributes: [NSAttributedString.Key: Any] = [
            .font: dateFont,
            .foregroundColor: UIColor.systemGray
        ]

        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .long
        dateFormatter.timeStyle = .none
        let dateString = "生成日期: \(dateFormatter.string(from: Date()))"

        let dateSize = dateString.size(withAttributes: dateAttributes)
        let dateRect = CGRect(
            x: (pageRect.width - dateSize.width) / 2,
            y: 220,
            width: dateSize.width,
            height: dateSize.height
        )
        dateString.draw(in: dateRect, withAttributes: dateAttributes)

        // 统计摘要
        if let stats = statistics {
            let summaryY: CGFloat = 300
            let summaryFont = UIFont.systemFont(ofSize: 16)
            let summaryAttributes: [NSAttributedString.Key: Any] = [
                .font: summaryFont,
                .foregroundColor: UIColor.label
            ]

            let summaryLines = [
                "总错题数: \(stats.totalCount)",
                "待复习: \(stats.pendingCount)",
                "复习中: \(stats.reviewingCount)",
                "已掌握: \(stats.masteredCount)",
                "掌握率: \(Int(stats.masteredRate * 100))%"
            ]

            for (index, line) in summaryLines.enumerated() {
                let lineSize = line.size(withAttributes: summaryAttributes)
                let lineRect = CGRect(
                    x: (pageRect.width - lineSize.width) / 2,
                    y: summaryY + CGFloat(index * 30),
                    width: lineSize.width,
                    height: lineSize.height
                )
                line.draw(in: lineRect, withAttributes: summaryAttributes)
            }
        }

        // 页脚
        drawPageFooter(context: context, pageRect: pageRect, pageNumber: 1)
    }

    // MARK: - Statistics Page

    private func drawStatisticsPage(
        context: UIGraphicsPDFRendererContext,
        pageRect: CGRect,
        statistics: WrongQuestionStatistics
    ) {
        context.beginPage()

        var currentY: CGFloat = 80

        // 页面标题
        let titleFont = UIFont.boldSystemFont(ofSize: 24)
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: titleFont,
            .foregroundColor: UIColor.label
        ]

        "错题统计分析".draw(
            at: CGPoint(x: 60, y: currentY),
            withAttributes: titleAttributes
        )
        currentY += 50

        // 按知识点统计
        currentY = drawSection(
            title: "知识点分布",
            data: statistics.byKnowledgePoint.map { ("知识点\($0.key)", $0.value) },
            startY: currentY,
            pageRect: pageRect
        )

        // 按难度统计
        currentY = drawSection(
            title: "难度分布",
            data: statistics.byDifficulty.map { (difficultyName($0.key), $0.value) },
            startY: currentY,
            pageRect: pageRect
        )

        // 按错误类型统计
        if let errorTypes = statistics.byErrorType {
            currentY = drawSection(
                title: "错误类型分布",
                data: errorTypes.map {
                    (WrongQuestion.ErrorType(rawValue: $0.key)?.displayName ?? $0.key, $0.value)
                },
                startY: currentY,
                pageRect: pageRect
            )
        }

        drawPageFooter(context: context, pageRect: pageRect, pageNumber: 2)
    }

    // MARK: - Wrong Questions Pages

    private func drawWrongQuestionsPages(
        context: UIGraphicsPDFRendererContext,
        pageRect: CGRect,
        wrongQuestions: [WrongQuestion]
    ) {
        var pageNumber = 3

        for (index, wrongQuestion) in wrongQuestions.enumerated() {
            context.beginPage()

            var currentY: CGFloat = 80

            // 题号
            let questionNumberFont = UIFont.boldSystemFont(ofSize: 20)
            let questionNumberAttributes: [NSAttributedString.Key: Any] = [
                .font: questionNumberFont,
                .foregroundColor: UIColor.systemBlue
            ]

            "题目 \(index + 1)".draw(
                at: CGPoint(x: 60, y: currentY),
                withAttributes: questionNumberAttributes
            )
            currentY += 35

            // 错误类型和状态
            if let errorType = wrongQuestion.errorType {
                let tagFont = UIFont.systemFont(ofSize: 12)
                let tagAttributes: [NSAttributedString.Key: Any] = [
                    .font: tagFont,
                    .foregroundColor: UIColor.systemGray
                ]

                "[\(errorType.displayName)] [\(wrongQuestion.status.displayText)]".draw(
                    at: CGPoint(x: 60, y: currentY),
                    withAttributes: tagAttributes
                )
                currentY += 25
            }

            // 题目内容
            if let question = wrongQuestion.question {
                currentY = drawQuestionContent(
                    question: question,
                    startY: currentY,
                    pageRect: pageRect
                )
            }

            // 我的答案（错误）
            if let record = wrongQuestion.practiceRecord {
                let wrongLabelFont = UIFont.boldSystemFont(ofSize: 14)
                let wrongLabelAttributes: [NSAttributedString.Key: Any] = [
                    .font: wrongLabelFont,
                    .foregroundColor: UIColor.systemRed
                ]

                "✗ 我的答案:".draw(
                    at: CGPoint(x: 60, y: currentY),
                    withAttributes: wrongLabelAttributes
                )
                currentY += 25

                currentY = drawTextContent(
                    record.userAnswer,
                    startY: currentY,
                    pageRect: pageRect,
                    backgroundColor: UIColor.systemRed.withAlphaComponent(0.1)
                )
            }

            // 正确答案
            if let question = wrongQuestion.question {
                let correctLabelFont = UIFont.boldSystemFont(ofSize: 14)
                let correctLabelAttributes: [NSAttributedString.Key: Any] = [
                    .font: correctLabelFont,
                    .foregroundColor: UIColor.systemGreen
                ]

                "✓ 正确答案:".draw(
                    at: CGPoint(x: 60, y: currentY),
                    withAttributes: correctLabelAttributes
                )
                currentY += 25

                currentY = drawTextContent(
                    question.standardAnswer,
                    startY: currentY,
                    pageRect: pageRect,
                    backgroundColor: UIColor.systemGreen.withAlphaComponent(0.1)
                )
            }

            // AI诊断
            if let aiGrade = wrongQuestion.practiceRecord?.aiGrade {
                if let mistakes = aiGrade.mistakes, !mistakes.isEmpty {
                    let diagnosisFont = UIFont.boldSystemFont(ofSize: 14)
                    let diagnosisAttributes: [NSAttributedString.Key: Any] = [
                        .font: diagnosisFont,
                        .foregroundColor: UIColor.systemPurple
                    ]

                    "💡 AI诊断:".draw(
                        at: CGPoint(x: 60, y: currentY),
                        withAttributes: diagnosisAttributes
                    )
                    currentY += 25

                    for mistake in mistakes {
                        currentY = drawTextContent(
                            "• \(mistake)",
                            startY: currentY,
                            pageRect: pageRect
                        )
                    }
                }
            }

            // 学习笔记
            if let note = wrongQuestion.learningNote {
                let noteFont = UIFont.boldSystemFont(ofSize: 14)
                let noteAttributes: [NSAttributedString.Key: Any] = [
                    .font: noteFont,
                    .foregroundColor: UIColor.systemOrange
                ]

                "📝 学习笔记:".draw(
                    at: CGPoint(x: 60, y: currentY),
                    withAttributes: noteAttributes
                )
                currentY += 25

                currentY = drawTextContent(
                    note,
                    startY: currentY,
                    pageRect: pageRect,
                    backgroundColor: UIColor.systemOrange.withAlphaComponent(0.1)
                )
            }

            drawPageFooter(context: context, pageRect: pageRect, pageNumber: pageNumber)
            pageNumber += 1
        }
    }

    // MARK: - Helper Methods

    private func drawSection(
        title: String,
        data: [(String, Int)],
        startY: CGFloat,
        pageRect: CGRect
    ) -> CGFloat {
        var currentY = startY

        // Section标题
        let sectionTitleFont = UIFont.boldSystemFont(ofSize: 18)
        let sectionTitleAttributes: [NSAttributedString.Key: Any] = [
            .font: sectionTitleFont,
            .foregroundColor: UIColor.label
        ]

        title.draw(at: CGPoint(x: 60, y: currentY), withAttributes: sectionTitleAttributes)
        currentY += 30

        // 数据行
        let dataFont = UIFont.systemFont(ofSize: 14)
        let dataAttributes: [NSAttributedString.Key: Any] = [
            .font: dataFont,
            .foregroundColor: UIColor.label
        ]

        for (key, value) in data.sorted(by: { $0.1 > $1.1 }) {
            let line = "\(key): \(value)"
            line.draw(at: CGPoint(x: 80, y: currentY), withAttributes: dataAttributes)
            currentY += 22
        }

        currentY += 20
        return currentY
    }

    private func drawQuestionContent(
        question: Question,
        startY: CGFloat,
        pageRect: CGRect
    ) -> CGFloat {
        var currentY = startY

        // 题干
        let contentFont = UIFont.systemFont(ofSize: 14)
        let contentAttributes: [NSAttributedString.Key: Any] = [
            .font: contentFont,
            .foregroundColor: UIColor.label
        ]

        let contentText = question.content
        let contentRect = CGRect(
            x: 60,
            y: currentY,
            width: pageRect.width - 120,
            height: 1000
        )

        let boundingRect = contentText.boundingRect(
            with: contentRect.size,
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: contentAttributes,
            context: nil
        )

        contentText.draw(in: contentRect, withAttributes: contentAttributes)
        currentY += boundingRect.height + 20

        return currentY
    }

    private func drawTextContent(
        _ text: String,
        startY: CGFloat,
        pageRect: CGRect,
        backgroundColor: UIColor? = nil
    ) -> CGFloat {
        let padding: CGFloat = 10
        let rect = CGRect(
            x: 60,
            y: startY,
            width: pageRect.width - 120,
            height: 1000
        )

        let font = UIFont.systemFont(ofSize: 14)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: UIColor.label
        ]

        let boundingRect = text.boundingRect(
            with: rect.size,
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: attributes,
            context: nil
        )

        // 背景色
        if let bgColor = backgroundColor {
            let bgRect = CGRect(
                x: rect.origin.x - padding,
                y: startY - padding,
                width: rect.width + padding * 2,
                height: boundingRect.height + padding * 2
            )
            bgColor.setFill()
            UIBezierPath(roundedRect: bgRect, cornerRadius: 6).fill()
        }

        text.draw(in: rect, withAttributes: attributes)

        return startY + boundingRect.height + padding * 2 + 10
    }

    private func drawPageFooter(
        context: UIGraphicsPDFRendererContext,
        pageRect: CGRect,
        pageNumber: Int
    ) {
        let footerFont = UIFont.systemFont(ofSize: 10)
        let footerAttributes: [NSAttributedString.Key: Any] = [
            .font: footerFont,
            .foregroundColor: UIColor.systemGray
        ]

        let footerText = "BBLearning - 第 \(pageNumber) 页"
        let footerSize = footerText.size(withAttributes: footerAttributes)
        let footerRect = CGRect(
            x: (pageRect.width - footerSize.width) / 2,
            y: pageRect.height - 50,
            width: footerSize.width,
            height: footerSize.height
        )

        footerText.draw(in: footerRect, withAttributes: footerAttributes)
    }

    private func difficultyName(_ key: String) -> String {
        switch key {
        case "easy": return "简单"
        case "medium": return "中等"
        case "hard": return "困难"
        default: return key
        }
    }

    // MARK: - Save PDF

    /// 保存PDF到文件
    /// - Parameters:
    ///   - data: PDF数据
    ///   - filename: 文件名
    /// - Returns: 文件路径
    func savePDF(_ data: Data, filename: String) -> URL? {
        let documentsPath = FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask
        ).first

        guard let documentsPath = documentsPath else {
            return nil
        }

        let pdfPath = documentsPath.appendingPathComponent("\(filename).pdf")

        do {
            try data.write(to: pdfPath)
            Logger.shared.info("PDF已保存至: \(pdfPath.path)")
            return pdfPath
        } catch {
            Logger.shared.error("PDF保存失败: \(error.localizedDescription)")
            return nil
        }
    }

    /// 分享PDF
    /// - Parameter url: PDF文件路径
    /// - Returns: UIActivityViewController
    func sharePDF(url: URL) -> UIActivityViewController {
        let activityVC = UIActivityViewController(
            activityItems: [url],
            applicationActivities: nil
        )
        return activityVC
    }
}
