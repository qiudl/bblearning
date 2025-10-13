//
//  KnowledgeTreeViewModel.swift
//  BBLearning
//
//  Created by Claude Code on 2025-10-13.
//

import Foundation
import Combine

final class KnowledgeTreeViewModel: BaseViewModel {
    @Published var knowledgeTree: [KnowledgePoint] = []
    @Published var selectedGrade: Int = 7
    @Published var searchText: String = ""
    @Published var searchResults: [KnowledgePoint] = []
    @Published var isSearching: Bool = false

    private let getKnowledgeTreeUseCase: GetKnowledgeTreeUseCase

    init(getKnowledgeTreeUseCase: GetKnowledgeTreeUseCase = DIContainer.shared.resolve(GetKnowledgeTreeUseCase.self)) {
        self.getKnowledgeTreeUseCase = getKnowledgeTreeUseCase
        super.init()

        selectedGrade = UserDefaultsManager.shared.selectedGrade
        loadKnowledgeTree()
        setupSearchObserver()
    }

    private func setupSearchObserver() {
        $searchText
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .removeDuplicates()
            .sink { [weak self] text in
                self?.performSearch(text)
            }
            .store(in: &cancellables)
    }

    func loadKnowledgeTree() {
        executeTask(
            getKnowledgeTreeUseCase.execute(forGrade: selectedGrade),
            onSuccess: { [weak self] tree in
                self?.knowledgeTree = tree
            }
        )
    }

    func changeGrade(_ grade: Int) {
        selectedGrade = grade
        UserDefaultsManager.shared.selectedGrade = grade
        loadKnowledgeTree()
    }

    private func performSearch(_ text: String) {
        guard !text.trimmed.isEmpty else {
            isSearching = false
            searchResults = []
            return
        }

        isSearching = true
        getKnowledgeTreeUseCase.search(keyword: text)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.showError(error)
                    }
                },
                receiveValue: { [weak self] results in
                    self?.searchResults = results
                }
            )
            .store(in: &cancellables)
    }

    func clearSearch() {
        searchText = ""
        isSearching = false
        searchResults = []
    }
}
