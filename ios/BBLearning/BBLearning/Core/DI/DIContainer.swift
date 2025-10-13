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
        // Will be added in Data layer task

        // MARK: - Use Cases
        // Will be added in Domain layer task

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
