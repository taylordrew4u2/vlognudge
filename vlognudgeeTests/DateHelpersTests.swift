//
//  DateHelpersTests.swift
//  vlognudgeeTests
//
//  Pure date/window math. The midnight-crossing window case is the one
//  most worth pinning down.
//

import XCTest
@testable import vlognudgee

final class DateHelpersTests: XCTestCase {

    // MARK: - todayAt

    func testTodayAtProducesRequestedTimeOfDay() {
        let date = DateHelpers.todayAt(minute: 9 * 60 + 30)   // 09:30
        let comps = Calendar.current.dateComponents([.hour, .minute], from: date)
        XCTAssertEqual(comps.hour, 9)
        XCTAssertEqual(comps.minute, 30)
    }

    // MARK: - isInWindow (same-day window)

    func testInsideStandardWindow() {
        let noon = DateHelpers.todayAt(minute: 12 * 60)
        XCTAssertTrue(DateHelpers.isInWindow(noon, startMinute: 600, endMinute: 1320))  // 10:00–22:00
    }

    func testBeforeStandardWindowOpens() {
        let early = DateHelpers.todayAt(minute: 5 * 60)
        XCTAssertFalse(DateHelpers.isInWindow(early, startMinute: 600, endMinute: 1320))
    }

    func testStandardWindowBoundariesAreInclusive() {
        let start = DateHelpers.todayAt(minute: 600)
        let end = DateHelpers.todayAt(minute: 1320)
        XCTAssertTrue(DateHelpers.isInWindow(start, startMinute: 600, endMinute: 1320))
        XCTAssertTrue(DateHelpers.isInWindow(end, startMinute: 600, endMinute: 1320))
    }

    // MARK: - isInWindow (window crossing midnight, e.g. 22:00 → 06:00)

    func testInsideMidnightCrossingWindowLateNight() {
        let elevenPM = DateHelpers.todayAt(minute: 23 * 60)
        XCTAssertTrue(DateHelpers.isInWindow(elevenPM, startMinute: 1320, endMinute: 360))
    }

    func testInsideMidnightCrossingWindowEarlyMorning() {
        let twoAM = DateHelpers.todayAt(minute: 2 * 60)
        XCTAssertTrue(DateHelpers.isInWindow(twoAM, startMinute: 1320, endMinute: 360))
    }

    func testOutsideMidnightCrossingWindowMidday() {
        let noon = DateHelpers.todayAt(minute: 12 * 60)
        XCTAssertFalse(DateHelpers.isInWindow(noon, startMinute: 1320, endMinute: 360))
    }

    // MARK: - dayKey

    func testDayKeyFormat() {
        let key = DateHelpers.dayKey(from: DateHelpers.todayAt(minute: 12 * 60))
        XCTAssertNotNil(key.range(of: "^\\d{4}-\\d{2}-\\d{2}$", options: .regularExpression),
                        "Expected yyyy-MM-dd, got \(key)")
    }

    func testDayKeyIsStableWithinTheSameDay() {
        let morning = DateHelpers.todayAt(minute: 60)     // 01:00
        let night = DateHelpers.todayAt(minute: 23 * 60)  // 23:00
        XCTAssertEqual(DateHelpers.dayKey(from: morning), DateHelpers.dayKey(from: night))
    }

    func testDayKeyDiffersAcrossDays() {
        let now = Date()
        let twoDaysLater = now.addingTimeInterval(2 * 24 * 3600)
        XCTAssertNotEqual(DateHelpers.dayKey(from: now), DateHelpers.dayKey(from: twoDaysLater))
    }

    // MARK: - minutesAgo

    func testMinutesAgo() {
        let pastDate = Date().addingTimeInterval(-3630)  // 60.5 min ago → truncates to 60
        XCTAssertEqual(DateHelpers.minutesAgo(from: pastDate), 60)
    }
}
