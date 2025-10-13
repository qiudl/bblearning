//
//  GetKnowledgeTreeUseCase.swift
//  BBLearning
//
//  Created by Claude Code on 2025-10-13.
//

import Foundation
import Combine

/// 获取知识点树用例
final class GetKnowledgeTreeUseCase {
    private let knowledgeRepository: KnowledgeRepositoryProtocol
    private let userDefaultsManager: UserDefaultsManager

    init(knowledgeRepository: KnowledgeRepositoryProtocol,
         userDefaultsManager: UserDefaultsManager = .shared) {
        self.knowledgeRepository = knowledgeRepository
        self.userDefaultsManager = userDefaultsManager
    }

    /// 获取知识点树（使用当前用户年级）
    /// - Returns: 知识点树
    func execute() -> AnyPublisher<[KnowledgePoint], APIError> {
        let grade = userDefaultsManager.selectedGrade

        guard Validator.isValidGrade(grade) else {
            return Fail(error: APIError.parameterError("年级设置错误")).eraseToAnyPublisher()
        }

        return execute(for grade: grade)
    }

    /// 获取指定年级的知识点树
    /// - Parameter grade: 年级
    /// - Returns: 知识点树
    func execute(forGrade grade: Int) -> AnyPublisher<[KnowledgePoint], APIError> {
        guard Validator.isValidGrade(grade) else {
            return Fail(error: APIError.parameterError("年级参数错误：\(grade)")).eraseToAnyPublisher()
        }

        return knowledgeRepository.getKnowledgeTree(grade: grade)
            .handleEvents(receiveOutput: { tree in
                Logger.shared.info("获取知识点树成功，共\(tree.count)个根节点")
            })
            .eraseToAnyPublisher()
    }

    /// 获取知识点详情
    /// - Parameter id: 知识点ID
    /// - Returns: 知识点详情
    func getKnowledgePoint(id: Int) -> AnyPublisher<KnowledgePoint, APIError> {
        return knowledgeRepository.getKnowledgePoint(id: id)
    }

    /// 获取子知识点
    /// - Parameter parentId: 父知识点ID
    /// - Returns: 子知识点列表
    func getChildren(parentId: Int) -> AnyPublisher<[KnowledgePoint], APIError> {
        return knowledgeRepository.getChildren(parentId: parentId)
    }

    /// 构建完整的知识点路径（从根到当前节点）
    /// - Parameter knowledgePoint: 知识点
    /// - Returns: 路径节点列表
    func buildPath(for knowledgePoint: KnowledgePoint) -> AnyPublisher<[KnowledgePoint], APIError> {
        var path: [KnowledgePoint] = [knowledgePoint]

        func fetchParent(_ point: KnowledgePoint) -> AnyPublisher<[KnowledgePoint], APIError> {
            guard let parentId = point.parentId else {
                return Just(path.reversed())
                    .setFailureType(to: APIError.self)
                    .eraseToAnyPublisher()
            }

            return knowledgeRepository.getKnowledgePoint(id: parentId)
                .flatMap { parent -> AnyPublisher<[KnowledgePoint], APIError> in
                    path.append(parent)
                    return fetchParent(parent)
                }
                .eraseToAnyPublisher()
        }

        return fetchParent(knowledgePoint)
    }

    /// 搜索知识点
    /// - Parameter keyword: 搜索关键词
    /// - Returns: 匹配的知识点列表
    func search(keyword: String) -> AnyPublisher<[KnowledgePoint], APIError> {
        guard !keyword.trimmed.isEmpty else {
            return Just([]).setFailureType(to: APIError.self).eraseToAnyPublisher()
        }

        let grade = userDefaultsManager.selectedGrade
        return knowledgeRepository.searchKnowledgePoints(keyword: keyword, grade: grade)
    }
}
