//
//  Color+Extension.swift
//  BBLearning
//
//  Created by Claude Code on 2025-10-13.
//

import SwiftUI

extension Color {

    // MARK: - Custom Colors

    static let primary = Color("Primary")
    static let secondary = Color("Secondary")
    static let accent = Color.accentColor

    static let background = Color("Background")
    static let surface = Color("Surface")

    static let success = Color("Success")
    static let warning = Color("Warning")
    static let error = Color("Error")
    static let info = Color("Info")

    static let textPrimary = Color("TextPrimary")
    static let textSecondary = Color("TextSecondary")
    static let textTertiary = Color("TextTertiary")
    
    // Alias for convenience
    static let text = textPrimary

    // MARK: - Hex Initializer

    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)

        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }

    // MARK: - Difficulty Colors

    static func forDifficulty(_ difficulty: String) -> Color {
        switch difficulty.lowercased() {
        case "easy":
            return .green
        case "medium":
            return .orange
        case "hard":
            return .red
        default:
            return .gray
        }
    }

    // MARK: - Progress Colors

    static func forProgress(_ progress: Double) -> Color {
        switch progress {
        case 0..<0.3:
            return .red
        case 0.3..<0.6:
            return .orange
        case 0.6..<0.8:
            return .yellow
        default:
            return .green
        }
    }
}
