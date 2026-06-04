//
//  PromptGeneratorTests.swift
//  vlognudgeeTests
//
//  PromptGenerator is a pure mapping from (reason, fire time) to copy.
//  Contextual reasons take priority; otherwise it falls back to a
//  time-of-day template.
//

import XCTest
@testable import vlognudgee

final class PromptGeneratorTests: XCTestCase {

    private func prompt(reason: String, hour: Int) -> NudgePrompt {
        PromptGenerator.prompt(for: DateHelpers.todayAt(minute: hour * 60 + 30),
                               reason: reason,
                               settings: UserSettings(),
                               lastClipDate: nil)
    }

    // MARK: - Contextual reasons (priority over time of day)

    func testGeofenceEntryPrefixMatches() {
        XCTAssertEqual(prompt(reason: "geofence_entry_home", hour: 11).title, "Just arrived somewhere")
    }

    func testGeofenceExitPrefixMatches() {
        XCTAssertEqual(prompt(reason: "geofence_exit_gym", hour: 11).title, "On the move")
    }

    func testCalendarEventEndedReason() {
        XCTAssertEqual(prompt(reason: "calendar_event_ended", hour: 11).title, "That just wrapped")
    }

    func testWorkoutEndedReason() {
        XCTAssertEqual(prompt(reason: "workout_ended", hour: 11).title, "Post-workout moment")
    }

    func testLongGapReason() {
        XCTAssertEqual(prompt(reason: "long_gap", hour: 11).title, "Long gap")
    }

    func testContextualReasonBeatsTimeOfDay() {
        // 11:00 would otherwise yield the "Mid-morning" template.
        let p = prompt(reason: "workout_ended", hour: 11)
        XCTAssertEqual(p.title, "Post-workout moment")
        XCTAssertNotEqual(p.title, "Mid-morning")
    }

    // MARK: - Time-of-day fallback for unrecognized reasons

    func testMorningTemplate() {
        XCTAssertEqual(prompt(reason: "scheduled", hour: 8).title, "Morning check-in")
    }

    func testMidMorningTemplate() {
        XCTAssertEqual(prompt(reason: "scheduled", hour: 11).title, "Mid-morning")
    }

    func testAfternoonTemplate() {
        XCTAssertEqual(prompt(reason: "scheduled", hour: 14).title, "Afternoon")
    }

    func testEveningTemplate() {
        XCTAssertEqual(prompt(reason: "scheduled", hour: 20).title, "Evening")
    }

    func testLateNightTemplate() {
        XCTAssertEqual(prompt(reason: "scheduled", hour: 23).title, "Late night")
    }

    // MARK: - Both fields populated

    func testPromptHasNonEmptyTitleAndBody() {
        let p = prompt(reason: "scheduled", hour: 14)
        XCTAssertFalse(p.title.isEmpty)
        XCTAssertFalse(p.body.isEmpty)
    }
}
