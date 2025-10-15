//
//  RealmManager.swift
//  BBLearning
//
//  Created by Claude Code on 2025-10-13.
//

import Foundation
import RealmSwift

/// Realm数据库管理器
final class RealmManager {

    static let shared = RealmManager()

    private var realm: Realm {
        do {
            return try Realm(configuration: realmConfiguration)
        } catch {
            fatalError("Failed to initialize Realm: \(error.localizedDescription)")
        }
    }

    private var realmConfiguration: Realm.Configuration {
        var config = Realm.Configuration.defaultConfiguration

        // 设置Schema版本
        config.schemaVersion = 1

        // 数据库文件路径
        let fileURL = FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("bblearning.realm")
        config.fileURL = fileURL

        // 数据库迁移
        config.migrationBlock = { migration, oldSchemaVersion in
            if oldSchemaVersion < 1 {
                // 执行迁移逻辑
            }
        }

        // 开发环境下，如果迁移失败则删除数据库
        #if DEBUG
        config.deleteRealmIfMigrationNeeded = true
        #endif

        return config
    }

    private init() {
        Logger.shared.info("Realm initialized at: \(realm.configuration.fileURL?.path ?? "unknown")")
    }

    // MARK: - Write Operations

    /// 写入对象
    func write<T: Object>(_ object: T, update: Realm.UpdatePolicy = .modified) throws {
        try realm.write {
            realm.add(object, update: update)
        }
        Logger.shared.debug("Realm write: \(T.self)")
    }

    /// 批量写入对象
    func write<T: Object>(_ objects: [T], update: Realm.UpdatePolicy = .modified) throws {
        try realm.write {
            realm.add(objects, update: update)
        }
        Logger.shared.debug("Realm batch write: \(objects.count) \(T.self)")
    }

    /// 异步写入
    func writeAsync<T: Object>(_ object: T, update: Realm.UpdatePolicy = .modified, completion: @escaping (Error?) -> Void) {
        DispatchQueue(label: "com.bblearning.realm.write").async { [weak self] in
            guard let self = self else { return }
            do {
                try self.write(object, update: update)
                DispatchQueue.main.async {
                    completion(nil)
                }
            } catch {
                DispatchQueue.main.async {
                    completion(error)
                }
            }
        }
    }

    // MARK: - Read Operations

    /// 查询所有对象
    func fetch<T: Object>(_ type: T.Type) -> Results<T> {
        return realm.objects(type)
    }

    /// 条件查询
    func fetch<T: Object>(_ type: T.Type, predicate: NSPredicate) -> Results<T> {
        return realm.objects(type).filter(predicate)
    }

    /// 查询并排序
    func fetch<T: Object>(_ type: T.Type, sortedBy keyPath: String, ascending: Bool = true) -> Results<T> {
        return realm.objects(type).sorted(byKeyPath: keyPath, ascending: ascending)
    }

    /// 条件查询并排序
    func fetch<T: Object>(
        _ type: T.Type,
        predicate: NSPredicate,
        sortedBy keyPath: String,
        ascending: Bool = true
    ) -> Results<T> {
        return realm.objects(type)
            .filter(predicate)
            .sorted(byKeyPath: keyPath, ascending: ascending)
    }

    /// 查询单个对象
    func fetchOne<T: Object>(_ type: T.Type, primaryKey: Any) -> T? {
        return realm.object(ofType: type, forPrimaryKey: primaryKey)
    }

    /// 查询第一个对象
    func fetchFirst<T: Object>(_ type: T.Type, predicate: NSPredicate? = nil) -> T? {
        if let predicate = predicate {
            return realm.objects(type).filter(predicate).first
        }
        return realm.objects(type).first
    }

    // MARK: - Delete Operations

    /// 删除对象
    func delete<T: Object>(_ object: T) throws {
        try realm.write {
            realm.delete(object)
        }
        Logger.shared.debug("Realm delete: \(T.self)")
    }

    /// 批量删除
    func delete<T: Object>(_ objects: [T]) throws {
        try realm.write {
            realm.delete(objects)
        }
        Logger.shared.debug("Realm batch delete: \(objects.count) \(T.self)")
    }

    /// 删除所有对象
    func deleteAll<T: Object>(_ type: T.Type) throws {
        let objects = realm.objects(type)
        try realm.write {
            realm.delete(objects)
        }
        Logger.shared.debug("Realm delete all: \(T.self)")
    }

    /// 条件删除
    func delete<T: Object>(_ type: T.Type, predicate: NSPredicate) throws {
        let objects = realm.objects(type).filter(predicate)
        try realm.write {
            realm.delete(objects)
        }
        Logger.shared.debug("Realm conditional delete: \(T.self)")
    }

    // MARK: - Update Operations

    /// 更新对象
    func update(_ block: () throws -> Void) throws {
        try realm.write {
            try block()
        }
    }

    // MARK: - Transaction

    /// 执行事务
    func transaction(_ block: () throws -> Void) throws {
        if realm.isInWriteTransaction {
            try block()
        } else {
            try realm.write {
                try block()
            }
        }
    }

    // MARK: - Observers

    /// 观察对象变化
    func observe<T: Object>(
        _ type: T.Type,
        onChange: @escaping (Results<T>) -> Void
    ) -> NotificationToken {
        let results = realm.objects(type)
        return results.observe { changes in
            switch changes {
            case .initial(let results):
                onChange(results)
            case .update(let results, _, _, _):
                onChange(results)
            case .error:
                break
            }
        }
    }

    // MARK: - Clear

    /// 清空数据库
    func clearDatabase() throws {
        try realm.write {
            realm.deleteAll()
        }
        Logger.shared.info("Realm database cleared")
    }

    // MARK: - Compact

    /// 压缩数据库
    func compactDatabase() {
        do {
            let config = realmConfiguration
            _ = try Realm(configuration: config)
            Logger.shared.info("Realm database compacted")
        } catch {
            Logger.shared.error("Failed to compact Realm: \(error.localizedDescription)")
        }
    }

    // MARK: - Migration

    /// 执行数据库迁移
    static func migrateIfNeeded() {
        let config = shared.realmConfiguration
        do {
            _ = try Realm(configuration: config)
            Logger.shared.info("Realm migration completed")
        } catch {
            Logger.shared.error("Realm migration failed: \(error.localizedDescription)")
        }
    }
}

// MARK: - Realm Extensions

extension Results {
    /// 转换为数组
    func toArray() -> [Element] {
        return Array(self)
    }
}
