//
//  Date+Extension.swift
//  BBLearning
//
//  Created by Claude Code on 2025-10-13.
//

import Foundation

extension Date {

    // MARK: - Formatters

    static let iso8601Formatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.timeZone = TimeZone.current
        return formatter
    }()

    // MARK: - String Conversion

    func toString(format: String = "yyyy-MM-dd HH:mm:ss") -> String {
        Date.dateFormatter.dateFormat = format
        return Date.dateFormatter.string(from: self)
    }

    func toShortDateString() -> String {
        return toString(format: "yyyy-MM-dd")
    }

    func toShortTimeString() -> String {
        return toString(format: "HH:mm")
    }

    func toISO8601String() -> String {
        return Date.iso8601Formatter.string(from: self)
    }

    static func from(string: String, format: String = "yyyy-MM-dd HH:mm:ss") -> Date? {
        Date.dateFormatter.dateFormat = format
        return Date.dateFormatter.date(from: string)
    }

    static func fromISO8601(string: String) -> Date? {
        return Date.iso8601Formatter.date(from: string)
    }

    // MARK: - Relative Dates

    var isToday: Bool {
        return Calendar.current.isDateInToday(self)
    }

    var isYesterday: Bool {
        return Calendar.current.isDateInYesterday(self)
    }

    var isTomorrow: Bool {
        return Calendar.current.isDateInTomorrow(self)
    }

    var isThisWeek: Bool {
        return Calendar.current.isDate(self, equalTo: Date(), toGranularity: .weekOfYear)
    }

    var isThisMonth: Bool {
        return Calendar.current.isDate(self, equalTo: Date(), toGranularity: .month)
    }

    var isThisYear: Bool {
        return Calendar.current.isDate(self, equalTo: Date(), toGranularity: .year)
    }

    // MARK: - Date Manipulation

    func adding(_ component: Calendar.Component, value: Int) -> Date? {
        return Calendar.current.date(byAdding: component, value: value, to: self)
    }

    func startOfDay() -> Date {
        return Calendar.current.startOfDay(for: self)
    }

    func endOfDay() -> Date? {
        var components = DateComponents()
        components.day = 1
        components.second = -1
        return Calendar.current.date(byAdding: components, to: startOfDay())
    }

    func startOfWeek() -> Date? {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: self)
        return calendar.date(from: components)
    }

    func endOfWeek() -> Date? {
        guard let startOfWeek = startOfWeek() else { return nil }
        return Calendar.current.date(byAdding: .day, value: 6, to: startOfWeek)?.endOfDay()
    }

    func startOfMonth() -> Date? {
        let components = Calendar.current.dateComponents([.year, .month], from: self)
        return Calendar.current.date(from: components)
    }

    func endOfMonth() -> Date? {
        guard let startOfMonth = startOfMonth() else { return nil }
        var components = DateComponents()
        components.month = 1
        components.second = -1
        return Calendar.current.date(byAdding: components, to: startOfMonth)
    }

    // MARK: - Comparison

    func isSameDay(as date: Date) -> Bool {
        return Calendar.current.isDate(self, inSameDayAs: date)
    }

    func daysBetween(_ date: Date) -> Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: startOfDay(), to: date.startOfDay())
        return abs(components.day ?? 0)
    }

    // MARK: - Relative String

    func relativeString() -> String {
        if isToday {
            return "今天 " + toShortTimeString()
        } else if isYesterday {
            return "昨天 " + toShortTimeString()
        } else if isTomorrow {
            return "明天 " + toShortTimeString()
        } else if isThisWeek {
            let weekday = Calendar.current.component(.weekday, from: self)
            let weekdayString = ["周日", "周一", "周二", "周三", "周四", "周五", "周六"][weekday - 1]
            return weekdayString + " " + toShortTimeString()
        } else if isThisYear {
            return toString(format: "MM-dd HH:mm")
        } else {
            return toString(format: "yyyy-MM-dd")
        }
    }
}
