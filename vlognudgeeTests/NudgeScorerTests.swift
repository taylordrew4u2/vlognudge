//
//  NudgeScorerTests.swift
//  vlognudgeeTests
//
//  Unit tests for the nudge decision engine. NudgeScorer is a pure,
//  deterministic function — (context, settings, history) -> decision — so
//  every case here is exact and side-effect free. Times are pinned to a
//  fixed minute-of-day via DateHelpers.todayAt so they never depend on the
//  wall clock.
//

import XCTest
@testable import vlognudgee

final class NudgeScorerTests: XCTestCase {

    // Noon today — comfortably inside the default active window (10:00–22:00).
    private func noon() -> Date { DateHelpers.todayAt(minute: 12 * 60) }

    /// A context with no positive signals and no blocks, inside the window.
    private func openContext(at date: Date? = nil) -> ContextSnapshot {
        ContextSnapshot(timestamp: date ?? noon())
    }

    private func decision(context: ContextSnapshot,
                          settings: UserSettings = UserSettings(),
                          recentNudges: [NudgeEvent] = [],
                          lastClipDate: Date? = nil) -> NudgeDecision {
        NudgeScorer.score(context: context,
                          settings: settings,
                          recentNudges: recentNudges,
                          lastClipDate: lastClipDate)
    }

    // MARK: - Baseline

    func testQuietBaselineDoesNotFire() {
        let d = decision(context: openContext())
        XCTAssertFalse(d.hardBlocked)
        XCTAssertEqual(d.score, 0)
        XCTAssertFalse(d.shouldFire)
    }

    // MARK: - Hard blocks

    func testOutsideActiveWindowBlocks() {
        // 05:00 — before the 10:00 window opens.
        let d = decision(context: openContext(at: DateHelpers.todayAt(minute: 5 * 60)))
        XCTAssertTrue(d.hardBlocked)
        XCTAssertTrue(d.blockReasons.contains("outside_window"))
        XCTAssertFalse(d.shouldFire)
    }

    func testDrivingBlocksEvenWithQualifyingScore() {
        var ctx = openContext()
        ctx.lastGeofenceTransition = "home_entry"   // +3 positive signal
        ctx.motionActivity = "automotive"
        let d = decision(context: ctx)
        XCTAssertTrue(d.blockReasons.contains("driving"))
        XCTAssertFalse(d.shouldFire, "A hard block must override a qualifying score")
    }

    func testOnCallBlocks() {
        var ctx = openContext()
        ctx.lastGeofenceTransition = "gym_exit"
        ctx.isOnCall = true
        let d = decision(context: ctx)
        XCTAssertTrue(d.blockReasons.contains("on_call"))
        XCTAssertFalse(d.shouldFire)
    }

    func testFocusModeBlocksWhenEnabled() {
        var ctx = openContext()
        ctx.lastGeofenceTransition = "home_entry"
        ctx.inFocusMode = true
        let d = decision(context: ctx)               // useFocus defaults to true
        XCTAssertTrue(d.blockReasons.contains("focus_mode"))
        XCTAssertFalse(d.shouldFire)
    }

    func testFocusModeIgnoredWhenDisabled() {
        let settings = UserSettings()
        settings.useFocus = false
        var ctx = openContext()
        ctx.lastGeofenceTransition = "home_entry"    // +3
        ctx.inFocusMode = true
        let d = decision(context: ctx, settings: settings)
        XCTAssertFalse(d.blockReasons.contains("focus_mode"))
        XCTAssertTrue(d.shouldFire)
    }

    func testQuietHoursBlocks() {
        let settings = UserSettings()
        settings.quietHoursEnabled = true
        settings.quietStartMinute = 11 * 60          // 11:00
        settings.quietEndMinute = 13 * 60            // 13:00 — noon falls inside
        let d = decision(context: openContext(), settings: settings)
        XCTAssertTrue(d.blockReasons.contains("quiet_hours"))
        XCTAssertFalse(d.shouldFire)
    }

    func testCooldownBlocks() {
        let now = noon()
        let settings = UserSettings()
        settings.cooldownUntil = now.addingTimeInterval(30 * 60) // still cooling down
        var ctx = openContext(at: now)
        ctx.lastGeofenceTransition = "home_entry"
        let d = decision(context: ctx, settings: settings)
        XCTAssertTrue(d.blockReasons.contains("cooldown_active"))
        XCTAssertFalse(d.shouldFire)
    }

    func testBadDayMuteBlocks() {
        let now = noon()
        let settings = UserSettings()
        settings.badDayUntil = now.addingTimeInterval(60 * 60)
        var ctx = openContext(at: now)
        ctx.lastGeofenceTransition = "home_entry"
        let d = decision(context: ctx, settings: settings)
        XCTAssertTrue(d.blockReasons.contains("bad_day_muted"))
        XCTAssertFalse(d.shouldFire)
    }

    func testJustFilmedBlocks() {
        let now = noon()
        var ctx = openContext(at: now)
        ctx.lastGeofenceTransition = "home_entry"
        let d = decision(context: ctx, lastClipDate: now.addingTimeInterval(-10 * 60))
        XCTAssertTrue(d.blockReasons.contains("just_filmed"))
        XCTAssertFalse(d.shouldFire)
    }

    func testMinGapNotMetBlocks() {
        let now = noon()
        let nudge = NudgeEvent(scheduledFor: now,
                               score: 3,
                               triggerReason: "test",
                               context: openContext(at: now))
        nudge.firedAt = now.addingTimeInterval(-10 * 60)   // 10 min ago < 45 min default gap
        var ctx = openContext(at: now)
        ctx.lastGeofenceTransition = "home_entry"
        let d = decision(context: ctx, recentNudges: [nudge])
        XCTAssertTrue(d.blockReasons.contains("min_gap_not_met"))
        XCTAssertFalse(d.shouldFire)
    }

    func testMinGapMetDoesNotBlock() {
        let now = noon()
        let nudge = NudgeEvent(scheduledFor: now,
                               score: 3,
                               triggerReason: "test",
                               context: openContext(at: now))
        nudge.firedAt = now.addingTimeInterval(-90 * 60)   // 90 min ago > 45 min gap
        var ctx = openContext(at: now)
        ctx.lastGeofenceTransition = "home_entry"
        let d = decision(context: ctx, recentNudges: [nudge])
        XCTAssertFalse(d.blockReasons.contains("min_gap_not_met"))
        XCTAssertTrue(d.shouldFire)
    }

    // MARK: - Positive signals

    func testGeofenceTransitionFires() {
        var ctx = openContext()
        ctx.lastGeofenceTransition = "home_entry"
        let d = decision(context: ctx)
        XCTAssertEqual(d.score, 3)
        XCTAssertTrue(d.reasons.contains("geofence_transition"))
        XCTAssertTrue(d.shouldFire)
    }

    func testCalendarEventEndedFires() {
        var ctx = openContext()
        ctx.lastEventEndedMinutesAgo = 3
        let d = decision(context: ctx)
        XCTAssertEqual(d.score, 2)
        XCTAssertTrue(d.reasons.contains("calendar_event_ended"))
        XCTAssertTrue(d.shouldFire)
    }

    func testPreEventAloneIsBelowThreshold() {
        var ctx = openContext()
        ctx.upcomingEventInMinutes = 10            // +1 only
        let d = decision(context: ctx)
        XCTAssertEqual(d.score, 1)
        XCTAssertTrue(d.reasons.contains("pre_event"))
        XCTAssertFalse(d.shouldFire, "A single +1 signal must not clear the Normal threshold of 2")
    }

    func testChargingAloneIsBelowThreshold() {
        var ctx = openContext()
        ctx.isCharging = true
        let d = decision(context: ctx)
        XCTAssertEqual(d.score, 1)
        XCTAssertTrue(d.reasons.contains("just_charging"))
        XCTAssertFalse(d.shouldFire)
    }

    func testStationaryArrivalNotDoubleCounted() {
        var ctx = openContext()
        ctx.lastGeofenceTransition = "home_entry"  // +3
        ctx.motionActivity = "stationary"          // must NOT add a second +2
        let d = decision(context: ctx)
        XCTAssertEqual(d.score, 3)
        XCTAssertTrue(d.reasons.contains("geofence_transition"))
        XCTAssertFalse(d.reasons.contains("motion_stationary"))
    }

    func testStationaryWithoutGeofenceAddsScore() {
        var ctx = openContext()
        ctx.motionActivity = "stationary"
        let d = decision(context: ctx)
        XCTAssertEqual(d.score, 2)
        XCTAssertTrue(d.reasons.contains("motion_stationary"))
        XCTAssertTrue(d.shouldFire)
    }

    func testZeroClipsPastMidpointAddsScore() {
        // 17:00 — past the window midpoint (16:00), and no clips yet today.
        let d = decision(context: openContext(at: DateHelpers.todayAt(minute: 17 * 60)))
        XCTAssertTrue(d.reasons.contains("zero_clips_past_midpoint"))
        XCTAssertTrue(d.shouldFire)
    }

    func testLongGapSinceLastClipAddsScore() {
        let now = noon()
        let d = decision(context: openContext(at: now),
                         lastClipDate: now.addingTimeInterval(-5 * 3600)) // 5h ago > 4h (2× normal)
        XCTAssertTrue(d.reasons.contains("long_gap"))
        XCTAssertTrue(d.shouldFire)
    }

    // MARK: - Frequency → threshold mapping

    func testAggressiveThresholdAcceptsSinglePoint() {
        let settings = UserSettings()
        settings.frequency = .aggressive           // threshold 1
        var ctx = openContext()
        ctx.isCharging = true                      // +1
        let d = decision(context: ctx, settings: settings)
        XCTAssertEqual(d.threshold, 1)
        XCTAssertTrue(d.shouldFire)
    }

    func testChillThresholdRejectsTwoPoints() {
        let settings = UserSettings()
        settings.frequency = .chill                // threshold 3
        var ctx = openContext()
        ctx.lastEventEndedMinutesAgo = 3           // +2
        let d = decision(context: ctx, settings: settings)
        XCTAssertEqual(d.threshold, 3)
        XCTAssertEqual(d.score, 2)
        XCTAssertFalse(d.shouldFire)
    }
}
