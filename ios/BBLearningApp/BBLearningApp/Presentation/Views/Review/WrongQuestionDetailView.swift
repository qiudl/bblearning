//
//  WrongQuestionDetailView.swift
//  BBLearning
//
//  Created by Claude Code on 2025-10-15.
//

import SwiftUI

/// 错题详情视图
struct WrongQuestionDetailView: View {
    let wrongQuestion: WrongQuestion
    @StateObject private var viewModel = WrongQuestionDetailViewModel()
    @Environment(\.dismiss) var dismiss

    @State private var showRetrySheet = false
    @State private var showNoteEditor = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // 错题状态标签
                statusSection

                // 题目内容
                if let question = wrongQuestion.question {
                    QuestionContentView(question: question)
                }

                // 错误答案和正确答案
                answersSection

                // AI诊断
                aiDiagnosisSection

                // 错误类型
                errorTypeSection

                // 复习计划
                reviewScheduleSection

                // 学习笔记
                learningNoteSection

                // 相似题目
                similarQuestionsSection

                // 操作按钮
                actionButtons
            }
            .padding()
        }
        .navigationTitle("错题详情")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(action: { showNoteEditor = true }) {
                        Label("编辑笔记", systemImage: "pencil")
                    }

                    Button(action: viewModel.addToFavorites) {
                        Label("收藏", systemImage: "star")
                    }

                    Button(action: viewModel.shareQuestion) {
                        Label("分享", systemImage: "square.and.arrow.up")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showRetrySheet) {
            // TODO: 显示重做题目界面
            Text("重做题目")
        }
        .sheet(isPresented: $showNoteEditor) {
            NoteEditorView(
                note: wrongQuestion.learningNote ?? "",
                onSave: { note in
                    viewModel.saveLearningNote(note, for: wrongQuestion)
                }
            )
        }
    }

    // MARK: - Status Section

    private var statusSection: some View {
        HStack(spacing: 12) {
            // 状态标签
            Label(wrongQuestion.status.displayText, systemImage: wrongQuestion.status.icon)
                .font(.subheadline)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(statusColor(wrongQuestion.status).opacity(0.2))
                .foregroundColor(statusColor(wrongQuestion.status))
                .cornerRadius(8)

            // 错误类型标签
            if let errorType = wrongQuestion.errorType {
                Label(errorType.displayName, systemImage: errorType.icon)
                    .font(.subheadline)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color(errorType.color).opacity(0.2))
                    .foregroundColor(Color(errorType.color))
                    .cornerRadius(8)
            }

            Spacer()

            // 复习次数
            VStack(alignment: .trailing, spacing: 2) {
                Text("已复习")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("\(wrongQuestion.retryCount)次")
                    .font(.headline)
            }
        }
        .padding()
        .background(Color.surface)
        .cornerRadius(12)
    }

    // MARK: - Answers Section

    private var answersSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 我的答案（错误）
            if let record = wrongQuestion.practiceRecord {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.red)
                        Text("我的答案")
                            .font(.headline)
                    }

                    Text(record.userAnswer)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)
                }
            }

            // 正确答案
            if let question = wrongQuestion.question {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("正确答案")
                            .font(.headline)
                    }

                    Text(question.standardAnswer)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(Color.surface)
        .cornerRadius(12)
    }

    // MARK: - AI Diagnosis Section

    private var aiDiagnosisSection: some View {
        Group {
            if let aiGrade = wrongQuestion.practiceRecord?.aiGrade {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "sparkles")
                            .foregroundColor(.purple)
                        Text("AI诊断")
                            .font(.headline)
                    }

                    // 错误分析
                    if let mistakes = aiGrade.mistakes, !mistakes.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("错误原因：")
                                .font(.subheadline)
                                .fontWeight(.medium)

                            ForEach(mistakes, id: \.self) { mistake in
                                HStack(alignment: .top, spacing: 8) {
                                    Text("•")
                                    Text(mistake)
                                        .font(.subheadline)
                                }
                            }
                        }
                    }

                    // 改进建议
                    if let suggestions = aiGrade.suggestions, !suggestions.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("改进建议：")
                                .font(.subheadline)
                                .fontWeight(.medium)

                            ForEach(suggestions, id: \.self) { suggestion in
                                HStack(alignment: .top, spacing: 8) {
                                    Text("💡")
                                    Text(suggestion)
                                        .font(.subheadline)
                                }
                            }
                        }
                    }
                }
                .padding()
                .background(Color.purple.opacity(0.1))
                .cornerRadius(12)
            }
        }
    }

    // MARK: - Error Type Section

    private var errorTypeSection: some View {
        Group {
            if let errorType = wrongQuestion.errorType {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: errorType.icon)
                            .foregroundColor(Color(errorType.color))
                        Text("错误类型分析")
                            .font(.headline)
                    }

                    Text(errorTypeDescription(errorType))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color.surface)
                .cornerRadius(12)
            }
        }
    }

    // MARK: - Review Schedule Section

    private var reviewScheduleSection: some View {
        Group {
            if let schedule = wrongQuestion.reviewSchedule {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "calendar.badge.clock")
                            .foregroundColor(.blue)
                        Text("复习计划")
                            .font(.headline)

                        Spacer()

                        Text(wrongQuestion.reviewProgressText)
                            .font(.subheadline)
                            .foregroundColor(.blue)
                    }

                    // 复习历史
                    if !schedule.reviewDates.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("复习记录：")
                                .font(.subheadline)
                                .fontWeight(.medium)

                            ForEach(schedule.reviewDates.suffix(5), id: \.self) { date in
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                        .font(.caption)

                                    Text(date.formatted(date: .abbreviated, time: .omitted))
                                        .font(.caption)

                                    Spacer()
                                }
                            }
                        }
                    }

                    // 下次复习时间
                    HStack {
                        Text("下次复习：")
                            .font(.subheadline)
                            .fontWeight(.medium)

                        Spacer()

                        Text(schedule.nextReviewDate.formatted(date: .abbreviated, time: .omitted))
                            .font(.subheadline)
                            .foregroundColor(.blue)
                    }
                }
                .padding()
                .background(Color.surface)
                .cornerRadius(12)
            }
        }
    }

    // MARK: - Learning Note Section

    private var learningNoteSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "note.text")
                    .foregroundColor(.orange)
                Text("学习笔记")
                    .font(.headline)

                Spacer()

                Button(action: { showNoteEditor = true }) {
                    Text(wrongQuestion.learningNote == nil ? "添加" : "编辑")
                        .font(.subheadline)
                }
            }

            if let note = wrongQuestion.learningNote {
                Text(note)
                    .font(.subheadline)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(8)
            } else {
                Text("暂无笔记，点击上方添加按钮记录学习心得")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .italic()
            }
        }
        .padding()
        .background(Color.surface)
        .cornerRadius(12)
    }

    // MARK: - Similar Questions Section

    private var similarQuestionsSection: some View {
        Group {
            if let similarIds = wrongQuestion.similarQuestionIds, !similarIds.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "rectangle.3.group")
                            .foregroundColor(.blue)
                        Text("相似题目")
                            .font(.headline)

                        Spacer()

                        Text("\(similarIds.count)道")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    Button(action: {
                        // TODO: 跳转到相似题目列表
                    }) {
                        HStack {
                            Text("查看相似题目，巩固知识点")
                                .font(.subheadline)

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.caption)
                        }
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
                .padding()
                .background(Color.surface)
                .cornerRadius(12)
            }
        }
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        VStack(spacing: 12) {
            // 重做题目按钮
            Button(action: { showRetrySheet = true }) {
                HStack {
                    Image(systemName: "arrow.clockwise")
                    Text("重做题目")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    LinearGradient(
                        colors: [Color.blue, Color.purple],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .foregroundColor(.white)
                .cornerRadius(12)
            }

            // 标记为已掌握
            if wrongQuestion.status != .mastered {
                Button(action: {
                    viewModel.markAsMastered(wrongQuestion)
                }) {
                    HStack {
                        Image(systemName: "checkmark.circle")
                        Text("标记为已掌握")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
            }
        }
    }

    // MARK: - Helper Functions

    private func statusColor(_ status: WrongQuestion.Status) -> Color {
        switch status {
        case .pending: return .red
        case .reviewing: return .orange
        case .mastered: return .green
        case .archived: return .gray
        }
    }

    private func errorTypeDescription(_ type: WrongQuestion.ErrorType) -> String {
        switch type {
        case .conceptual:
            return "概念理解不够透彻，建议重新学习相关知识点的定义和基本原理。"
        case .calculation:
            return "计算过程出现错误，需要加强基本运算能力，注意计算步骤的准确性。"
        case .careless:
            return "因粗心大意导致错误，建议做题时更加细心，养成检查的好习惯。"
        case .method:
            return "解题方法选择不当，需要掌握该类型题目的正确解法和思路。"
        case .unknown:
            return "错误原因待分析，建议咨询老师或查阅相关资料。"
        }
    }
}

// MARK: - Note Editor View

struct NoteEditorView: View {
    @Environment(\.dismiss) var dismiss
    let note: String
    let onSave: (String) -> Void

    @State private var editedNote: String

    init(note: String, onSave: @escaping (String) -> Void) {
        self.note = note
        self.onSave = onSave
        _editedNote = State(initialValue: note)
    }

    var body: some View {
        NavigationView {
            VStack {
                TextEditor(text: $editedNote)
                    .padding()
            }
            .navigationTitle("学习笔记")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        onSave(editedNote)
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Preview

#if DEBUG
struct WrongQuestionDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            WrongQuestionDetailView(wrongQuestion: WrongQuestion.mock)
        }
    }
}
#endif
