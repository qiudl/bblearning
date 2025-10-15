//
//  Color+Extension.swift
//  BBLearning
//
//  Created by Claude Code on 2025-10-13.
//

import SwiftUI

extension Color {

    // MARK: - Custom Colors
    // Note: These reference colors in Assets.xcassets. If not found, fallback colors are used.

    static var primary: Color {
        if let color = UIColor(named: "Primary") {
            return Color(color)
        }
        return Color.blue
    }

    static var secondary: Color {
        if let color = UIColor(named: "Secondary") {
            return Color(color)
        }
        return Color.purple
    }

    static let accent = Color.accentColor

    static var background: Color {
        if let color = UIColor(named: "Background") {
            return Color(color)
        }
        return Color(UIColor.systemBackground)
    }

    static var surface: Color {
        if let color = UIColor(named: "Surface") {
            return Color(color)
        }
        return Color(UIColor.secondarySystemBackground)
    }

    static var success: Color {
        if let color = UIColor(named: "Success") {
            return Color(color)
        }
        return Color.green
    }

    static var warning: Color {
        if let color = UIColor(named: "Warning") {
            return Color(color)
        }
        return Color.orange
    }

    static var error: Color {
        if let color = UIColor(named: "Error") {
            return Color(color)
        }
        return Color.red
    }

    static var info: Color {
        if let color = UIColor(named: "Info") {
            return Color(color)
        }
        return Color.blue
    }

    static var textPrimary: Color {
        if let color = UIColor(named: "TextPrimary") {
            return Color(color)
        }
        return Color(UIColor.label)
    }

    static var textSecondary: Color {
        if let color = UIColor(named: "TextSecondary") {
            return Color(color)
        }
        return Color(UIColor.secondaryLabel)
    }

    static var textTertiary: Color {
        if let color = UIColor(named: "TextTertiary") {
            return Color(color)
        }
        return Color(UIColor.tertiaryLabel)
    }

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
