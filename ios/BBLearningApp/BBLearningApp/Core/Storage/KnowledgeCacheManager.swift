//
//  KnowledgeCacheManager.swift
//  BBLearningApp
//
//  Created by Claude Code on 2025-10-15.
//  知识点本地缓存管理器
//

import Foundation

/// 知识点缓存管理器
final class KnowledgeCacheManager {
    static let shared = KnowledgeCacheManager()

    private let userDefaults = UserDefaults.standard
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    // 缓存键前缀
    private enum CacheKey {
        static let knowledgeTreePrefix = "knowledge_tree_grade_"
        static let knowledgePointPrefix = "knowledge_point_"
        static let cacheTimestamp = "_timestamp"
    }

    // 缓存有效期（秒）
    private enum CacheTTL {
        static let knowledgeTree: TimeInterval = 24 * 3600 // 24小时
        static let knowledgePoint: TimeInterval = 3600     // 1小时
    }

    private init() {
        // 配置日期编码策略
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
    }

    // MARK: - 知识树缓存

    /// 缓存知识树
    /// - Parameters:
    ///   - tree: 知识点树
    ///   - grade: 年级
    func cacheKnowledgeTree(_ tree: [KnowledgePoint], forGrade grade: Int) {
        let key = CacheKey.knowledgeTreePrefix + "\(grade)"

        do {
            let data = try encoder.encode(tree)
            userDefaults.set(data, forKey: key)
            userDefaults.set(Date().timeIntervalSince1970, forKey: key + CacheKey.cacheTimestamp)
            Logger.shared.info("缓存知识树成功 - 年级\(grade), 节点数: \(tree.count)")
        } catch {
            Logger.shared.error("缓存知识树失败: \(error.localizedDescription)")
        }
    }

    /// 获取缓存的知识树
    /// - Parameter grade: 年级
    /// - Returns: 知识点树，如果缓存不存在或已过期则返回nil
    func getCachedKnowledgeTree(forGrade grade: Int) -> [KnowledgePoint]? {
        let key = CacheKey.knowledgeTreePrefix + "\(grade)"

        // 检查缓存是否存在
        guard let data = userDefaults.data(forKey: key) else {
            Logger.shared.debug("知识树缓存不存在 - 年级\(grade)")
            return nil
        }

        // 检查缓存是否过期
        if isCacheExpired(key: key, ttl: CacheTTL.knowledgeTree) {
            Logger.shared.debug("知识树缓存已过期 - 年级\(grade)")
            clearKnowledgeTreeCache(forGrade: grade)
            return nil
        }

        // 解码缓存数据
        do {
            let tree = try decoder.decode([KnowledgePoint].self, from: data)
            Logger.shared.info("从缓存加载知识树 - 年级\(grade), 节点数: \(tree.count)")
            return tree
        } catch {
            Logger.shared.error("解码知识树缓存失败: \(error.localizedDescription)")
            clearKnowledgeTreeCache(forGrade: grade)
            return nil
        }
    }

    /// 清除指定年级的知识树缓存
    /// - Parameter grade: 年级
    func clearKnowledgeTreeCache(forGrade grade: Int) {
        let key = CacheKey.knowledgeTreePrefix + "\(grade)"
        userDefaults.removeObject(forKey: key)
        userDefaults.removeObject(forKey: key + CacheKey.cacheTimestamp)
    }

    // MARK: - 知识点详情缓存

    /// 缓存知识点详情
    /// - Parameter point: 知识点
    func cacheKnowledgePoint(_ point: KnowledgePoint) {
        let key = CacheKey.knowledgePointPrefix + "\(point.id)"

        do {
            let data = try encoder.encode(point)
            userDefaults.set(data, forKey: key)
            userDefaults.set(Date().timeIntervalSince1970, forKey: key + CacheKey.cacheTimestamp)
            Logger.shared.debug("缓存知识点成功 - ID: \(point.id), 名称: \(point.name)")
        } catch {
            Logger.shared.error("缓存知识点失败: \(error.localizedDescription)")
        }
    }

    /// 获取缓存的知识点详情
    /// - Parameter id: 知识点ID
    /// - Returns: 知识点，如果缓存不存在或已过期则返回nil
    func getCachedKnowledgePoint(id: Int) -> KnowledgePoint? {
        let key = CacheKey.knowledgePointPrefix + "\(id)"

        // 检查缓存是否存在
        guard let data = userDefaults.data(forKey: key) else {
            Logger.shared.debug("知识点缓存不存在 - ID: \(id)")
            return nil
        }

        // 检查缓存是否过期
        if isCacheExpired(key: key, ttl: CacheTTL.knowledgePoint) {
            Logger.shared.debug("知识点缓存已过期 - ID: \(id)")
            clearKnowledgePointCache(id: id)
            return nil
        }

        // 解码缓存数据
        do {
            let point = try decoder.decode(KnowledgePoint.self, from: data)
            Logger.shared.debug("从缓存加载知识点 - ID: \(id), 名称: \(point.name)")
            return point
        } catch {
            Logger.shared.error("解码知识点缓存失败: \(error.localizedDescription)")
            clearKnowledgePointCache(id: id)
            return nil
        }
    }

    /// 清除指定知识点的缓存
    /// - Parameter id: 知识点ID
    func clearKnowledgePointCache(id: Int) {
        let key = CacheKey.knowledgePointPrefix + "\(id)"
        userDefaults.removeObject(forKey: key)
        userDefaults.removeObject(forKey: key + CacheKey.cacheTimestamp)
    }

    // MARK: - 批量缓存管理

    /// 缓存知识点列表
    /// - Parameter points: 知识点列表
    func cacheKnowledgePoints(_ points: [KnowledgePoint]) {
        points.forEach { cacheKnowledgePoint($0) }
    }

    /// 清除所有知识点缓存
    func clearAllKnowledgeCache() {
        let keys = userDefaults.dictionaryRepresentation().keys

        // 清除知识树缓存
        keys.filter { $0.hasPrefix(CacheKey.knowledgeTreePrefix) }
            .forEach { userDefaults.removeObject(forKey: $0) }

        // 清除知识点缓存
        keys.filter { $0.hasPrefix(CacheKey.knowledgePointPrefix) }
            .forEach { userDefaults.removeObject(forKey: $0) }

        Logger.shared.info("已清除所有知识点缓存")
    }

    /// 获取缓存统计信息
    func getCacheStats() -> (treeCount: Int, pointCount: Int) {
        let keys = userDefaults.dictionaryRepresentation().keys

        let treeCount = keys.filter { $0.hasPrefix(CacheKey.knowledgeTreePrefix) && !$0.hasSuffix(CacheKey.cacheTimestamp) }.count
        let pointCount = keys.filter { $0.hasPrefix(CacheKey.knowledgePointPrefix) && !$0.hasSuffix(CacheKey.cacheTimestamp) }.count

        return (treeCount, pointCount)
    }

    // MARK: - 私有辅助方法

    /// 检查缓存是否过期
    /// - Parameters:
    ///   - key: 缓存键
    ///   - ttl: 生存时间（秒）
    /// - Returns: 是否过期
    private func isCacheExpired(key: String, ttl: TimeInterval) -> Bool {
        guard let timestamp = userDefaults.double(forKey: key + CacheKey.cacheTimestamp) as Double? else {
            return true
        }

        let cacheAge = Date().timeIntervalSince1970 - timestamp
        return cacheAge > ttl
    }
}
