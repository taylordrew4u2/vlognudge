import Foundation

/// Shared gates for pre-scheduled reminders. Context scoring alone cannot stop
/// notifications that iOS already holds while the app is suspended.
enum NudgeSchedulePolicy {
    static func allows(_ date: Date, settings: UserSettings, lastClipDate: Date?) -> Bool {
        if let until = settings.cooldownUntil, date < until { return false }
        if let until = settings.badDayUntil, date < until { return false }
        if let lastClipDate, date < lastClipDate.addingTimeInterval(3600) { return false }
        guard DateHelpers.isInWindow(date, startMinute: settings.windowStartMinute,
                                     endMinute: settings.windowEndMinute) else { return false }
        if settings.quietHoursEnabled,
           DateHelpers.isInWindow(date, startMinute: settings.quietStartMinute,
                                  endMinute: settings.quietEndMinute) { return false }
        return true
    }
}
