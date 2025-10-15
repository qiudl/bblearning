//
//  Logger.swift
//  BBLearning
//
//  Created by Claude Code on 2025-10-13.
//

import Foundation
import Logging

/// 日志管理器
final class Logger {

    static let shared = Logger()

    private let logger: Logging.Logger

    private init() {
        var logger = Logging.Logger(label: "com.bblearning.ios")

        // 配置日志级别
        #if DEBUG
        logger.logLevel = .debug
        #else
        logger.logLevel = .info
        #endif

        self.logger = logger
    }

    // MARK: - Log Levels

    func debug(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        guard Configuration.enableDebugLogging else { return }
        let fileName = (file as NSString).lastPathComponent
        logger.debug("[\(fileName):\(line)] \(function) - \(message)")
    }

    func info(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        let fileName = (file as NSString).lastPathComponent
        logger.info("[\(fileName):\(line)] \(function) - \(message)")
    }

    func warning(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        let fileName = (file as NSString).lastPathComponent
        logger.warning("[\(fileName):\(line)] \(function) - \(message)")
    }

    func error(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        let fileName = (file as NSString).lastPathComponent
        logger.error("[\(fileName):\(line)] \(function) - \(message)")
    }

    func critical(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        let fileName = (file as NSString).lastPathComponent
        logger.critical("[\(fileName):\(line)] \(function) - \(message)")
    }

    // MARK: - Special Categories

    func network(_ message: String) {
        guard Configuration.enableDebugLogging else { return }
        logger.debug("[Network] \(message)")
    }

    func database(_ message: String) {
        guard Configuration.enableDebugLogging else { return }
        logger.debug("[Database] \(message)")
    }

    func ui(_ message: String) {
        guard Configuration.enableDebugLogging else { return }
        logger.debug("[UI] \(message)")
    }
}
