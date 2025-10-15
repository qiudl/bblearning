//
//  Validator.swift
//  BBLearning
//
//  Created by Claude Code on 2025-10-13.
//

import Foundation

/// 数据验证工具
struct Validator {

    // MARK: - Username Validation

    static func isValidUsername(_ username: String) -> Bool {
        let trimmed = username.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= Configuration.minUsernameLength &&
              trimmed.count <= Configuration.maxUsernameLength else {
            return false
        }

        // 允许字母、数字、下划线
        let usernameRegex = "^[a-zA-Z0-9_]+$"
        return NSPredicate(format: "SELF MATCHES %@", usernameRegex).evaluate(with: trimmed)
    }

    static func usernameError(for username: String) -> String? {
        let trimmed = username.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmed.isEmpty {
            return "用户名不能为空"
        }

        if trimmed.count < Configuration.minUsernameLength {
            return "用户名至少\(Configuration.minUsernameLength)个字符"
        }

        if trimmed.count > Configuration.maxUsernameLength {
            return "用户名最多\(Configuration.maxUsernameLength)个字符"
        }

        if !isValidUsername(trimmed) {
            return "用户名只能包含字母、数字和下划线"
        }

        return nil
    }

    // MARK: - Password Validation

    static func isValidPassword(_ password: String) -> Bool {
        return password.count >= Configuration.minPasswordLength &&
               password.count <= Configuration.maxPasswordLength
    }

    static func passwordError(for password: String) -> String? {
        if password.isEmpty {
            return "密码不能为空"
        }

        if password.count < Configuration.minPasswordLength {
            return "密码至少\(Configuration.minPasswordLength)个字符"
        }

        if password.count > Configuration.maxPasswordLength {
            return "密码最多\(Configuration.maxPasswordLength)个字符"
        }

        return nil
    }

    static func isStrongPassword(_ password: String) -> Bool {
        // 至少包含一个大写字母、一个小写字母、一个数字
        let uppercaseRegex = ".*[A-Z]+.*"
        let lowercaseRegex = ".*[a-z]+.*"
        let digitRegex = ".*[0-9]+.*"

        let hasUppercase = NSPredicate(format: "SELF MATCHES %@", uppercaseRegex).evaluate(with: password)
        let hasLowercase = NSPredicate(format: "SELF MATCHES %@", lowercaseRegex).evaluate(with: password)
        let hasDigit = NSPredicate(format: "SELF MATCHES %@", digitRegex).evaluate(with: password)

        return hasUppercase && hasLowercase && hasDigit && password.count >= 8
    }

    // MARK: - Phone Number Validation

    static func isValidPhoneNumber(_ phone: String) -> Bool {
        let trimmed = phone.trimmingCharacters(in: .whitespacesAndNewlines)

        // 中国大陆手机号
        let phoneRegex = "^1[3-9]\\d{9}$"
        return NSPredicate(format: "SELF MATCHES %@", phoneRegex).evaluate(with: trimmed)
    }

    static func phoneNumberError(for phone: String) -> String? {
        let trimmed = phone.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmed.isEmpty {
            return "手机号不能为空"
        }

        if !isValidPhoneNumber(trimmed) {
            return "请输入正确的手机号码"
        }

        return nil
    }

    // MARK: - Email Validation

    static func isValidEmail(_ email: String) -> Bool {
        let trimmed = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        return NSPredicate(format: "SELF MATCHES %@", emailRegex).evaluate(with: trimmed)
    }

    static func emailError(for email: String) -> String? {
        let trimmed = email.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmed.isEmpty {
            return "邮箱不能为空"
        }

        if !isValidEmail(trimmed) {
            return "请输入正确的邮箱地址"
        }

        return nil
    }

    // MARK: - Nickname Validation

    static func isValidNickname(_ nickname: String) -> Bool {
        let trimmed = nickname.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.count >= 2 && trimmed.count <= 20
    }

    static func nicknameError(for nickname: String) -> String? {
        let trimmed = nickname.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmed.isEmpty {
            return "昵称不能为空"
        }

        if trimmed.count < 2 {
            return "昵称至少2个字符"
        }

        if trimmed.count > 20 {
            return "昵称最多20个字符"
        }

        return nil
    }

    // MARK: - Grade Validation

    static func isValidGrade(_ grade: Int) -> Bool {
        return grade >= 7 && grade <= 9
    }

    static func gradeError(for grade: Int) -> String? {
        if !isValidGrade(grade) {
            return "请选择7-9年级"
        }
        return nil
    }
}
