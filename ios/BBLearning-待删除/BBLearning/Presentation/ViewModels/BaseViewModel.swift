//
//  BaseViewModel.swift
//  BBLearning
//
//  Created by Claude Code on 2025-10-13.
//

import Foundation
import Combine

/// ViewModel基类
class BaseViewModel: ObservableObject {
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    var cancellables = Set<AnyCancellable>()

    /// 显示错误消息
    func showError(_ error: Error) {
        if let apiError = error as? APIError {
            errorMessage = apiError.localizedDescription
        } else {
            errorMessage = error.localizedDescription
        }
        Logger.shared.error("Error: \(error.localizedDescription)")
    }

    /// 清除错误
    func clearError() {
        errorMessage = nil
    }

    /// 执行异步任务
    func executeTask<T>(
        _ publisher: AnyPublisher<T, APIError>,
        onSuccess: @escaping (T) -> Void,
        onError: ((APIError) -> Void)? = nil
    ) {
        isLoading = true
        clearError()

        publisher
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        if let onError = onError {
                            onError(error)
                        } else {
                            self?.showError(error)
                        }
                    }
                },
                receiveValue: { value in
                    onSuccess(value)
                }
            )
            .store(in: &cancellables)
    }
}
