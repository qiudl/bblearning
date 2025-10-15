//
//  String+Extension.swift
//  BBLearning
//
//  Created by Claude Code on 2025-10-13.
//

import Foundation

extension String {

    // MARK: - Validation

    var isNotEmpty: Bool {
        return !trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var trimmed: String {
        return trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - MD5 Hash

    var md5: String {
        guard let data = self.data(using: .utf8) else { return self }
        return data.md5
    }

    // MARK: - URL Encoding

    var urlEncoded: String? {
        return addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
    }

    // MARK: - Base64

    var base64Encoded: String? {
        return data(using: .utf8)?.base64EncodedString()
    }

    var base64Decoded: String? {
        guard let data = Data(base64Encoded: self) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    // MARK: - Subscript

    subscript(i: Int) -> Character {
        return self[index(startIndex, offsetBy: i)]
    }

    subscript(range: Range<Int>) -> String {
        let start = index(startIndex, offsetBy: range.lowerBound)
        let end = index(startIndex, offsetBy: range.upperBound)
        return String(self[start..<end])
    }

    // MARK: - Localization

    var localized: String {
        return NSLocalizedString(self, comment: "")
    }

    func localized(with arguments: CVarArg...) -> String {
        return String(format: localized, arguments: arguments)
    }
}

extension Data {
    var md5: String {
        // 简化版MD5，实际应使用CryptoKit
        return self.base64EncodedString()
    }
}
