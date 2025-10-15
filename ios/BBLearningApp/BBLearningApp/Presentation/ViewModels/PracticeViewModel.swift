//
//  PracticeViewModel.swift
//  BBLearning
//
//  Created by Claude Code on 2025-10-13.
//

import Foundation
import Combine

final class PracticeViewModel: BaseViewModel {
    @Published var knowledgePoints: [KnowledgePoint] = []
    @Published var selectedKnowledgePointIds: Set<Int> = []
    @Published var questionCount: Int = 10
    @Published var selectedDifficulty: Question.Difficulty = .medium
    @Published var generationMode: GenerationMode = .standard

    @Published var showQuestionView = false
    @Published var generatedQuestions: [Question] = []

    private let getKnowledgeTreeUseCase: GetKnowledgeTreeUseCase
    private let generateQuestionsUseCase: GenerateQuestionsUseCase

    enum GenerationMode {
        case standard       // 标准模式：手动选择知识点和难度
        case adaptive       // 自适应模式：根据学习进度自动调整难度
        case wrong          // 错题模式：从错题本抽取类似题目
    }

    init(
        getKnowledgeTreeUseCase: GetKnowledgeTreeUseCase = DIContainer.shared.resolve(GetKnowledgeTreeUseCase.self),
        generateQuestionsUseCase: GenerateQuestionsUseCase = DIContainer.shared.resolve(GenerateQuestionsUseCase.self)
    ) {
        self.getKnowledgeTreeUseCase = getKnowledgeTreeUseCase
        self.generateQuestionsUseCase = generateQuestionsUseCase
        super.init()
        loadKnowledgePoints()
    }

    // MARK: - Load Knowledge Points

    func loadKnowledgePoints() {
        let grade = UserDefaultsManager.shared.selectedGrade
        executeTask(
            getKnowledgeTreeUseCase.execute(forGrade: grade),
            onSuccess: { [weak self] tree in
                self?.knowledgePoints = self?.flattenTree(tree) ?? []
            }
        )
    }

    private func flattenTree(_ tree: [KnowledgePoint]) -> [KnowledgePoint] {
        var result: [KnowledgePoint] = []
        for kp in tree {
            result.append(kp)
            if let children = kp.children {
                result.append(contentsOf: flattenTree(children))
            }
        }
        return result
    }

    // MARK: - Knowledge Point Selection

    func toggleKnowledgePoint(_ id: Int) {
        if selectedKnowledgePointIds.contains(id) {
            selectedKnowledgePointIds.remove(id)
        } else {
            selectedKnowledgePointIds.insert(id)
        }
    }

    func selectAll() {
        selectedKnowledgePointIds = Set(knowledgePoints.map { $0.id })
    }

    func clearSelection() {
        selectedKnowledgePointIds.removeAll()
    }

    var canGenerate: Bool {
        return !selectedKnowledgePointIds.isEmpty && questionCount > 0
    }

    // MARK: - Generate Questions

    func generateQuestions() {
        guard canGenerate else { return }

        let ids = Array(selectedKnowledgePointIds)

        let publisher: AnyPublisher<[Question], APIError>

        switch generationMode {
        case .standard:
            publisher = generateQuestionsUseCase.execute(
                knowledgePointIds: ids,
                count: questionCount,
                difficulty: selectedDifficulty
            )

        case .adaptive:
            // 对于自适应模式，为每个知识点单独生成，然后合并
            guard let firstId = ids.first else { return }
            publisher = generateQuestionsUseCase.generateAdaptive(
                knowledgePointId: firstId,
                count: questionCount
            )

        case .wrong:
            // TODO: 在实现错题本模块后集成
            publisher = generateQuestionsUseCase.execute(
                knowledgePointIds: ids,
                count: questionCount,
                difficulty: selectedDifficulty
            )
        }

        executeTask(
            publisher,
            onSuccess: { [weak self] questions in
                self?.generatedQuestions = questions
                self?.showQuestionView = true
            }
        )
    }

    // MARK: - Helpers

    var selectedKnowledgePointNames: String {
        let selectedNames = knowledgePoints
            .filter { selectedKnowledgePointIds.contains($0.id) }
            .map { $0.name }

        if selectedNames.isEmpty {
            return "未选择"
        } else if selectedNames.count <= 3 {
            return selectedNames.joined(separator: "、")
        } else {
            return "\(selectedNames.prefix(3).joined(separator: "、")) 等\(selectedNames.count)个"
        }
    }

    var questionCountOptions: [Int] {
        return [5, 10, 15, 20, 30]
    }
}
