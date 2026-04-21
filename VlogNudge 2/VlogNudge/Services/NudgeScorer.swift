//
//  NudgeScorer.swift
//  VlogNudge
//
//  Pure, deterministic scoring function. Given a context snapshot and
//  settings, returns whether a nudge should fire and why. No side effects.
//

import Foundation

struct NudgeDecision {
    let score: Int
    let threshold: Int
    let reasons: [String]
    let hardBlocked: Bool
    let blockReasons: [String]

    var shouldFire: Bool {
        !hardBlocked && score >= threshold
    }
}

enum NudgeScorer {

    /// Score a potential nudge moment. Higher = more confident this is a good moment.
    static func score(context: ContextSnapshot,
                      settings: UserSettings,
                      recentNudges: [NudgeEvent],
                      lastClipDate: Date?) -> NudgeDecision {
        var score = 0
        var reasons: [String] = []
        var blockReasons: [String] = []

        // MARK: Hard blocks (override everything)

        // Quiet hours
        if settings.quietHoursEnabled,
           DateHelpers.isInWindow(
                context.timestamp,
                startMinute: settings.quietStartMinute,
                endMinute: settings.quietEndMinute) {
            blockReasons.append("quiet_hours")
        }

        // Outside active window
        if !DateHelpers.isInWindow(
                context.timestamp,
                startMinute: settings.windowStartMinute,
                endMinute: settings.windowEndMinute) {
            blockReasons.append("outside_window")
        }

        // Bad day mute
        if let until = settings.badDayUntil, until > context.timestamp {
            blockReasons.append("bad_day_muted")
        }

        // Cool-down from repeated "not now"
        if let until = settings.cooldownUntil, until > context.timestamp {
            blockReasons.append("cooldown_active")
        }

        // Currently driving
        if context.motionActivity == "automotive" {
            blockReasons.append("driving")
        }

        // On a call
        if context.isOnCall {
            blockReasons.append("on_call")
        }

        // In blocking Focus mode
        if settings.useFocus && context.inFocusMode {
            blockReasons.append("focus_mode")
        }

        // Min gap between nudges
        if let lastNudge = recentNudges
            .compactMap(\.firedAt)
            .max() {
            let gapMin = Int(context.timestamp.timeIntervalSince(lastNudge) / 60)
            if gapMin < settings.minGapBetweenNudgesMin {
                blockReasons.append("min_gap_not_met")
            }
        }

        // Just filmed recently
        if let lastClip = lastClipDate {
            let minutesSince = Int(context.timestamp.timeIntervalSince(lastClip) / 60)
            if minutesSince < 30 {
                blockReasons.append("just_filmed")
            }
        }

        // MARK: Positive signals

        if settings.useLocation {
            if context.lastGeofenceTransition != nil {
                score += 3
                reasons.append("geofence_transition")
            }
        }

        if settings.useMotion {
            if let motion = context.motionActivity, motion == "stationary" {
                // Just arrived somewhere (walked → stopped, or drove → stopped)
                if let transition = context.lastGeofenceTransition,
                   transition.contains("entry") {
                    // Already counted above
                } else {
                    score += 2
                    reasons.append("motion_stationary")
                }
            }
        }

        if settings.useCalendar {
            if let ended = context.lastEventEndedMinutesAgo, ended <= 5 {
                score += 2
                reasons.append("calendar_event_ended")
            }
            if let upcoming = context.upcomingEventInMinutes, upcoming <= 15, upcoming >= 5 {
                score += 1
                reasons.append("pre_event")
            }
        }

        if let lastClip = lastClipDate {
            let hoursSince = context.timestamp.timeIntervalSince(lastClip) / 3600
            let normalInterval = normalIntervalHours(for: settings)
            if hoursSince >= normalInterval * 2 {
                score += 2
                reasons.append("long_gap")
            }
        } else {
            // No clips yet today and we're past midpoint — boost
            let windowMidpoint = (settings.windowStartMinute + settings.windowEndMinute) / 2
            let calendar = Calendar.current
            let comps = calendar.dateComponents([.hour, .minute], from: context.timestamp)
            let currentMinute = (comps.hour ?? 0) * 60 + (comps.minute ?? 0)
            if currentMinute >= windowMidpoint {
                score += 2
                reasons.append("zero_clips_past_midpoint")
            }
        }

        if settings.useScreenTime {
            if let unlocks = context.unlocksInLast10Min, unlocks >= 5 {
                score += 1
                reasons.append("doomscroll_detected")
            }
        }

        if context.isCharging {
            score += 1
            reasons.append("just_charging")
        }

        if settings.useWeather, context.weatherCondition == "just_changed" {
            score += 2
            reasons.append("weather_changed")
        }

        // MARK: Decision

        let hardBlocked = !blockReasons.isEmpty
        let threshold = settings.frequency.scoreThreshold

        return NudgeDecision(
            score: score,
            threshold: threshold,
            reasons: reasons,
            hardBlocked: hardBlocked,
            blockReasons: blockReasons
        )
    }

    /// Normal interval between clips, in hours, given the user's target.
    private static func normalIntervalHours(for settings: UserSettings) -> Double {
        let windowHours = Double(settings.windowEndMinute - settings.windowStartMinute) / 60.0
        let target = max(1, settings.frequency.baselineCountPerDay)
        return windowHours / Double(target)
    }
}
