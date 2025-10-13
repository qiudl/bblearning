//
//  PracticeView.swift
//  BBLearning
//
//  Created by Claude Code on 2025-10-13.
//

import SwiftUI

struct PracticeView: View {
    @StateObject private var viewModel = PracticeViewModel()
    @State private var showKnowledgePointPicker = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // 模式选择
                modeSection

                // 知识点选择
                knowledgePointSection

                // 题目数量
                questionCountSection

                // 难度选择（标准模式）
                if viewModel.generationMode == .standard {
                    difficultySection
                }

                // 生成按钮
                generateButton
            }
            .padding()
        }
        .navigationTitle("智能练习")
        .errorAlert(error: $viewModel.errorMessage)
        .sheet(isPresented: $showKnowledgePointPicker) {
            KnowledgePointPickerView(
                knowledgePoints: viewModel.knowledgePoints,
                selectedIds: $viewModel.selectedKnowledgePointIds
            )
        }
        .fullScreenCover(isPresented: $viewModel.showQuestionView) {
            if !viewModel.generatedQuestions.isEmpty {
                QuestionView(questions: viewModel.generatedQuestions)
            }
        }
    }

    // MARK: - Mode Section

    private var modeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("练习模式")
                .font(.headline)

            VStack(spacing: 8) {
                ModeCard(
                    title: "标准模式",
                    description: "自定义知识点和难度",
                    icon: "doc.text",
                    isSelected: viewModel.generationMode == .standard
                ) {
                    viewModel.generationMode = .standard
                }

                ModeCard(
                    title: "自适应模式",
                    description: "AI根据学习情况推荐",
                    icon: "brain",
                    isSelected: viewModel.generationMode == .adaptive
                ) {
                    viewModel.generationMode = .adaptive
                }

                ModeCard(
                    title: "错题模式",
                    description: "针对错题进行强化训练",
                    icon: "exclamationmark.triangle",
                    isSelected: viewModel.generationMode == .wrong
                ) {
                    viewModel.generationMode = .wrong
                }
            }
        }
    }

    // MARK: - Knowledge Point Section

    private var knowledgePointSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("知识点选择")
                .font(.headline)

            Button(action: { showKnowledgePointPicker = true }) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("已选择知识点")
                            .font(.caption)
                            .foregroundColor(.textSecondary)

                        Text(viewModel.selectedKnowledgePointNames)
                            .font(.body)
                            .foregroundColor(.text)
                            .lineLimit(2)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .foregroundColor(.gray)
                }
                .padding()
                .background(Color.surface)
                .cornerRadius(12)
            }
        }
    }

    // MARK: - Question Count Section

    private var questionCountSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("题目数量")
                .font(.headline)

            HStack(spacing: 12) {
                ForEach(viewModel.questionCountOptions, id: \.self) { count in
                    CountOptionButton(
                        count: count,
                        isSelected: viewModel.questionCount == count
                    ) {
                        viewModel.questionCount = count
                    }
                }
            }
        }
    }

    // MARK: - Difficulty Section

    private var difficultySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("难度选择")
                .font(.headline)

            HStack(spacing: 12) {
                DifficultyButton(
                    difficulty: .easy,
                    isSelected: viewModel.selectedDifficulty == .easy
                ) {
                    viewModel.selectedDifficulty = .easy
                }

                DifficultyButton(
                    difficulty: .medium,
                    isSelected: viewModel.selectedDifficulty == .medium
                ) {
                    viewModel.selectedDifficulty = .medium
                }

                DifficultyButton(
                    difficulty: .hard,
                    isSelected: viewModel.selectedDifficulty == .hard
                ) {
                    viewModel.selectedDifficulty = .hard
                }
            }
        }
    }

    // MARK: - Generate Button

    private var generateButton: some View {
        CustomButton(
            title: "开始练习",
            action: viewModel.generateQuestions,
            isEnabled: viewModel.canGenerate,
            isLoading: viewModel.isLoading
        )
        .padding(.top, 8)
    }
}

// MARK: - Supporting Views

struct ModeCard: View {
    let title: String
    let description: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : .primary)
                    .frame(width: 40)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(isSelected ? .white : .text)

                    Text(description)
                        .font(.caption)
                        .foregroundColor(isSelected ? .white.opacity(0.9) : .textSecondary)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.white)
                }
            }
            .padding()
            .background(isSelected ? Color.primary : Color.surface)
            .cornerRadius(12)
        }
    }
}

struct CountOptionButton: View {
    let count: Int
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text("\(count)")
                .font(.headline)
                .foregroundColor(isSelected ? .white : .text)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(isSelected ? Color.primary : Color.surface)
                .cornerRadius(10)
        }
    }
}

struct DifficultyButton: View {
    let difficulty: Question.Difficulty
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: iconName)
                    .font(.title2)

                Text(difficulty.displayName)
                    .font(.body)
            }
            .foregroundColor(isSelected ? .white : .text)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(isSelected ? difficultyColor : Color.surface)
            .cornerRadius(12)
        }
    }

    private var iconName: String {
        switch difficulty {
        case .easy:
            return "1.circle"
        case .medium:
            return "2.circle"
        case .hard:
            return "3.circle"
        }
    }

    private var difficultyColor: Color {
        switch difficulty {
        case .easy:
            return .green
        case .medium:
            return .orange
        case .hard:
            return .red
        }
    }
}

// MARK: - Knowledge Point Picker

struct KnowledgePointPickerView: View {
    @Environment(\.dismiss) var dismiss
    let knowledgePoints: [KnowledgePoint]
    @Binding var selectedIds: Set<Int>

    @State private var searchText = ""

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 搜索栏
                SearchBar(text: $searchText, placeholder: "搜索知识点")
                    .padding()

                // 知识点列表
                List {
                    ForEach(filteredKnowledgePoints) { kp in
                        KnowledgePointPickerRow(
                            knowledgePoint: kp,
                            isSelected: selectedIds.contains(kp.id)
                        ) {
                            toggleSelection(kp.id)
                        }
                    }
                }
                .listStyle(PlainListStyle())
            }
            .navigationTitle("选择知识点")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }

    private var filteredKnowledgePoints: [KnowledgePoint] {
        if searchText.isEmpty {
            return knowledgePoints
        }
        return knowledgePoints.filter {
            $0.name.localizedCaseInsensitiveContains(searchText)
        }
    }

    private func toggleSelection(_ id: Int) {
        if selectedIds.contains(id) {
            selectedIds.remove(id)
        } else {
            selectedIds.insert(id)
        }
    }
}

struct KnowledgePointPickerRow: View {
    let knowledgePoint: KnowledgePoint
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .primary : .gray)

                Text(knowledgePoint.name)
                    .foregroundColor(.text)

                Spacer()
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Extensions

extension Question.Difficulty {
    var displayName: String {
        switch self {
        case .easy:
            return "简单"
        case .medium:
            return "中等"
        case .hard:
            return "困难"
        }
    }
}

#if DEBUG
struct PracticeView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            PracticeView()
        }
    }
}
#endif
