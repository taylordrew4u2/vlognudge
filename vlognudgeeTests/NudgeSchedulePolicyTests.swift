import XCTest
import UserNotifications
@testable import vlognudgee

@MainActor
final class NudgeSchedulePolicyTests: XCTestCase {
    func testCancellationKeepsRemindersAfterPauseAndOtherCategories() {
        let now = Date()
        let end = now.addingTimeInterval(3600)
        func request(_ minutes: Double, category: String = AppConstants.notificationCategoryID) -> UNNotificationRequest {
            let content = UNMutableNotificationContent()
            content.categoryIdentifier = category
            let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: now.addingTimeInterval(minutes * 60))
            return UNNotificationRequest(identifier: UUID().uuidString, content: content,
                trigger: UNCalendarNotificationTrigger(dateMatching: components, repeats: false))
        }
        XCTAssertTrue(NotificationService.shouldCancel(request(30), after: now, before: end))
        XCTAssertFalse(NotificationService.shouldCancel(request(90), after: now, before: end))
        XCTAssertFalse(NotificationService.shouldCancel(request(30, category: "unrelated"), after: now, before: end))
        XCTAssertTrue(NotificationService.shouldCancel(request(90), after: now, before: nil))
    }

    func testPauseEndsAfterOneHourAndLaterRemindersSurvive() {
        let settings = UserSettings()
        settings.windowStartMinute = 0
        settings.windowEndMinute = 1439
        let noon = DateHelpers.todayAt(minute: 720)
        settings.cooldownUntil = noon.addingTimeInterval(3600)
        XCTAssertFalse(NudgeSchedulePolicy.allows(noon.addingTimeInterval(3599), settings: settings, lastClipDate: nil))
        XCTAssertTrue(NudgeSchedulePolicy.allows(noon.addingTimeInterval(3600), settings: settings, lastClipDate: nil))
        XCTAssertTrue(NudgeSchedulePolicy.allows(noon.addingTimeInterval(7200), settings: settings, lastClipDate: nil))
    }

    func testQuietHoursBlockBaselineEvenInsideActiveWindow() {
        let settings = UserSettings()
        settings.quietHoursEnabled = true
        settings.quietStartMinute = 720
        settings.quietEndMinute = 780
        XCTAssertFalse(NudgeSchedulePolicy.allows(DateHelpers.todayAt(minute: 750), settings: settings, lastClipDate: nil))
        XCTAssertTrue(NudgeSchedulePolicy.allows(DateHelpers.todayAt(minute: 800), settings: settings, lastClipDate: nil))
    }

    func testBadDayAndRecentClipBlockRescheduling() {
        let settings = UserSettings()
        let noon = DateHelpers.todayAt(minute: 720)
        settings.badDayUntil = noon.addingTimeInterval(7200)
        XCTAssertFalse(NudgeSchedulePolicy.allows(noon, settings: settings, lastClipDate: nil))
        settings.badDayUntil = nil
        XCTAssertFalse(NudgeSchedulePolicy.allows(noon, settings: settings, lastClipDate: noon.addingTimeInterval(-600)))
    }
}
