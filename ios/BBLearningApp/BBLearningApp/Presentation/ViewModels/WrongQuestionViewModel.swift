//
//  WrongQuestionViewModel.swift
//  BBLearning
//
//  Created by Claude Code on 2025-10-13.
//

import Foundation
import Combine

final class WrongQuestionViewModel: BaseViewModel {
    @Published var wrongQuestions: [WrongQuestion] = []
    @Published var filteredQuestions: [WrongQuestion] = []
    @Published var selectedKnowledgePointId: Int?
    @Published var selectedStatus: WrongQuestion.Status?
    @Published var searchText: String = ""

    @Published var showRetryView = false
    @Published var selectedQuestion: WrongQuestion?

    private let wrongQuestionRepository: WrongQuestionRepositoryProtocol

    init(wrongQuestionRepository: WrongQuestionRepositoryProtocol = DIContainer.shared.resolve(WrongQuestionRepositoryProtocol.self)) {
        self.wrongQuestionRepository = wrongQuestionRepository
        super.init()
        loadWrongQuestions()
        setupSearchObserver()
    }

    // MARK: - Load Data

    func loadWrongQuestions() {
        executeTask(
            wrongQuestionRepository.getWrongQuestions(
                page: 1,
                pageSize: 1000,  // Load all for now
                status: nil,
                knowledgePointId: nil
            ),
            onSuccess: { [weak self] response in
                self?.wrongQuestions = response.items
                self?.applyFilters()
            }
        )
    }

    private func setupSearchObserver() {
        $searchText
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .removeDuplicates()
            .sink { [weak self] _ in
                self?.applyFilters()
            }
            .store(in: &cancellables)
    }

    // MARK: - Filters

    func filterByKnowledgePoint(_ id: Int?) {
        selectedKnowledgePointId = id
        applyFilters()
    }

    func filterByStatus(_ status: WrongQuestion.Status?) {
        selectedStatus = status
        applyFilters()
    }

    private func applyFilters() {
        var filtered = wrongQuestions

        // 按知识点过滤
        if let knowledgePointId = selectedKnowledgePointId {
            filtered = filtered.filter { $0.question?.knowledgePointId == knowledgePointId }
        }

        // 按状态过滤
        if let status = selectedStatus {
            filtered = filtered.filter { $0.status == status }
        }

        // 按搜索文本过滤
        if !searchText.trimmed.isEmpty {
            filtered = filtered.filter { question in
                question.question?.content.stem.localizedCaseInsensitiveContains(searchText) ?? false
            }
        }

        // 按最近时间排序
        filtered.sort { $0.createdAt > $1.createdAt }

        filteredQuestions = filtered
    }

    func clearFilters() {
        selectedKnowledgePointId = nil
        selectedStatus = nil
        searchText = ""
        applyFilters()
    }

    // MARK: - Actions

    func retryQuestion(_ question: WrongQuestion) {
        selectedQuestion = question
        showRetryView = true
    }

    func deleteQuestion(_ question: WrongQuestion) {
        executeTask(
            wrongQuestionRepository.deleteWrongQuestion(id: question.id),
            onSuccess: { [weak self] _ in
                self?.loadWrongQuestions()
            }
        )
    }

    func markAsMastered(_ question: WrongQuestion) {
        executeTask(
            wrongQuestionRepository.updateStatus(id: question.id, status: .mastered),
            onSuccess: { [weak self] _ in
                self?.loadWrongQuestions()
            }
        )
    }

    // MARK: - Statistics

    var totalCount: Int {
        wrongQuestions.count
    }

    var pendingCount: Int {
        wrongQuestions.filter { $0.status == .pending }.count
    }

    var retryingCount: Int {
        wrongQuestions.filter { $0.status == .reviewing }.count
    }

    var masteredCount: Int {
        wrongQuestions.filter { $0.status == .mastered }.count
    }

    var needsReviewCount: Int {
        wrongQuestions.filter { $0.needsReview }.count
    }

    var groupedByKnowledgePoint: [Int: [WrongQuestion]] {
        Dictionary(grouping: wrongQuestions.filter { $0.question?.knowledgePointId != nil }) { 
            $0.question!.knowledgePointId 
        }
    }

    // MARK: - Helpers

    var hasQuestions: Bool {
        !wrongQuestions.isEmpty
    }

    var hasFilters: Bool {
        selectedKnowledgePointId != nil || selectedStatus != nil || !searchText.isEmpty
    }
}
