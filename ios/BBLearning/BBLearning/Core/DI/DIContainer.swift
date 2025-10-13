//
//  DIContainer.swift
//  BBLearning
//
//  Created by Claude Code on 2025-10-13.
//

import Foundation
import Swinject

/// 依赖注入容器
final class DIContainer {

    static let shared = DIContainer()

    let container = Container()

    private init() {
        registerDependencies()
    }

    private func registerDependencies() {
        // MARK: - Core Layer

        // Network
        container.register(APIClient.self) { _ in
            APIClient.shared
        }.inObjectScope(.container)

        // Storage
        container.register(RealmManager.self) { _ in
            RealmManager.shared
        }.inObjectScope(.container)

        container.register(KeychainManager.self) { _ in
            KeychainManager.shared
        }.inObjectScope(.container)

        container.register(UserDefaultsManager.self) { _ in
            UserDefaultsManager.shared
        }.inObjectScope(.container)

        // MARK: - Repositories

        container.register(AuthRepositoryProtocol.self) { r in
            AuthRepository(apiClient: r.resolve(APIClient.self)!)
        }.inObjectScope(.container)

        container.register(KnowledgeRepositoryProtocol.self) { r in
            KnowledgeRepository(apiClient: r.resolve(APIClient.self)!)
        }.inObjectScope(.container)

        container.register(PracticeRepositoryProtocol.self) { r in
            PracticeRepository(apiClient: r.resolve(APIClient.self)!)
        }.inObjectScope(.container)

        container.register(AIRepositoryProtocol.self) { r in
            AIRepository(apiClient: r.resolve(APIClient.self)!)
        }.inObjectScope(.container)

        container.register(WrongQuestionRepositoryProtocol.self) { r in
            WrongQuestionRepository(apiClient: r.resolve(APIClient.self)!)
        }.inObjectScope(.container)

        container.register(StatisticsRepositoryProtocol.self) { r in
            StatisticsRepository(apiClient: r.resolve(APIClient.self)!)
        }.inObjectScope(.container)

        // MARK: - Use Cases

        container.register(LoginUseCase.self) { r in
            LoginUseCase(
                authRepository: r.resolve(AuthRepositoryProtocol.self)!,
                keychainManager: r.resolve(KeychainManager.self)!,
                userDefaultsManager: r.resolve(UserDefaultsManager.self)!
            )
        }

        container.register(RegisterUseCase.self) { r in
            RegisterUseCase(authRepository: r.resolve(AuthRepositoryProtocol.self)!)
        }

        container.register(LogoutUseCase.self) { r in
            LogoutUseCase(
                authRepository: r.resolve(AuthRepositoryProtocol.self)!,
                keychainManager: r.resolve(KeychainManager.self)!,
                realmManager: r.resolve(RealmManager.self)!
            )
        }

        container.register(GetKnowledgeTreeUseCase.self) { r in
            GetKnowledgeTreeUseCase(
                knowledgeRepository: r.resolve(KnowledgeRepositoryProtocol.self)!,
                userDefaultsManager: r.resolve(UserDefaultsManager.self)!
            )
        }

        container.register(GenerateQuestionsUseCase.self) { r in
            GenerateQuestionsUseCase(
                practiceRepository: r.resolve(PracticeRepositoryProtocol.self)!,
                knowledgeRepository: r.resolve(KnowledgeRepositoryProtocol.self)!
            )
        }

        container.register(SubmitAnswerUseCase.self) { r in
            SubmitAnswerUseCase(
                practiceRepository: r.resolve(PracticeRepositoryProtocol.self)!,
                knowledgeRepository: r.resolve(KnowledgeRepositoryProtocol.self)!,
                wrongQuestionRepository: r.resolve(WrongQuestionRepositoryProtocol.self)!
            )
        }

        container.register(ChatWithAIUseCase.self) { r in
            ChatWithAIUseCase(aiRepository: r.resolve(AIRepositoryProtocol.self)!)
        }

        // MARK: - ViewModels
        // Will be added in Presentation layer tasks

        Logger.shared.info("DI Container initialized")
    }

    /// 解析依赖
    func resolve<T>(_ type: T.Type) -> T {
        guard let resolved = container.resolve(type) else {
            fatalError("Failed to resolve \(type)")
        }
        return resolved
    }

    /// 可选解析
    func resolveOptional<T>(_ type: T.Type) -> T? {
        return container.resolve(type)
    }
}
