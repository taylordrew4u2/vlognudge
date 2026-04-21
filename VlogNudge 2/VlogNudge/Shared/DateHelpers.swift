//
//  DateHelpers.swift
//  VlogNudge
//

import Foundation

enum DateHelpers {
    static let dayKeyFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.timeZone = .current
        return f
    }()

    static func dayKey(from date: Date) -> String {
        dayKeyFormatter.string(from: date)
    }

    /// Given minutes-from-midnight, return today's Date at that time.
    static func todayAt(minute: Int, calendar: Calendar = .current) -> Date {
        let now = Date()
        let startOfDay = calendar.startOfDay(for: now)
        return startOfDay.addingTimeInterval(TimeInterval(minute * 60))
    }

    /// Check if a date falls inside a minutes-from-midnight window
    /// (handles windows that cross midnight).
    static func isInWindow(_ date: Date, startMinute: Int, endMinute: Int, calendar: Calendar = .current) -> Bool {
        let comps = calendar.dateComponents([.hour, .minute], from: date)
        let m = (comps.hour ?? 0) * 60 + (comps.minute ?? 0)
        if startMinute <= endMinute {
            return m >= startMinute && m <= endMinute
        } else {
            // crosses midnight
            return m >= startMinute || m <= endMinute
        }
    }

    static func humanReadable(_ date: Date) -> String {
        let f = DateFormatter()
        f.timeStyle = .short
        f.dateStyle = .none
        return f.string(from: date)
    }

    static func minutesAgo(from date: Date) -> Int {
        Int(Date().timeIntervalSince(date) / 60)
    }
}
