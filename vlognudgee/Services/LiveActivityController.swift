//
//  LiveActivityController.swift
//  VlogNudge
//

import Foundation
import ActivityKit
import os
import SwiftData

@MainActor
final class LiveActivityController {
    static let shared = LiveActivityController()
    private init() {}

    private var currentActivity: Activity<VlogNudgeActivityAttributes>?

    /// Start a Live Activity for today if we're in the active window and don't have one.
    /// Update it with current state if we do.
    func startOrUpdateTodaysActivity(context: ModelContext) {
        let settings = fetchSettings(context: context) ?? UserSettings()

        // Only run within window
        guard DateHelpers.isInWindow(
            Date(),
            startMinute: settings.windowStartMinute,
            endMinute: settings.windowEndMinute)
        else {
            endCurrentActivity()
            return
        }

        let state = buildState(context: context, settings: settings)

        // If one already exists for today, update it
        if let existing = Activity<VlogNudgeActivityAttributes>.activities.first(
            where: { $0.attributes.dayKey == DateHelpers.dayKey(from: Date()) }
        ) {
            currentActivity = existing
            Task { await existing.update(ActivityContent(state: state, staleDate: nil)) }
            return
        }

        // Start a new one
        let attrs = VlogNudgeActivityAttributes(
            dayKey: DateHelpers.dayKey(from: Date()),
            windowStart: DateHelpers.todayAt(minute: settings.windowStartMinute),
            windowEnd: DateHelpers.todayAt(minute: settings.windowEndMinute)
        )

        do {
            let activity = try Activity.request(
                attributes: attrs,
                content: ActivityContent(state: state, staleDate: nil),
                pushType: nil
            )
            currentActivity = activity
        } catch {
            Logger.liveActivity.error("Failed to start Live Activity: \(error.localizedDescription, privacy: .public)")
        }
    }

    func refresh(context: ModelContext) {
        startOrUpdateTodaysActivity(context: context)
    }

    func endCurrentActivity() {
        Task {
            for activity in Activity<VlogNudgeActivityAttributes>.activities {
                await activity.end(nil, dismissalPolicy: .immediate)
            }
            currentActivity = nil
        }
    }

    // MARK: - State building

    private func buildState(context: ModelContext,
                            settings: UserSettings) -> VlogNudgeActivityAttributes.State {
        let clipsToday = fetchTodayClipCount(context: context)
        let target = settings.frequency.baselineCountPerDay
        let nextNudge = fetchNextNudgeDate()
        let lastClip = fetchLastClipDate(context: context)

        // Compute color based on progress vs. expected progress at this time
        let expectedSoFar = expectedClipsByNow(settings: settings)
        let color: VlogNudgeActivityAttributes.State.ProgressColor
        if Double(clipsToday) >= expectedSoFar * 0.9 {
            color = .green
        } else if Double(clipsToday) >= expectedSoFar * 0.6 {
            color = .yellow
        } else {
            color = .orange
        }

        return VlogNudgeActivityAttributes.State(
            clipsToday: clipsToday,
            targetClipsToday: target,
            nextNudgeAt: nextNudge,
            lastClipAt: lastClip,
            progressColor: color
        )
    }

    private func expectedClipsByNow(settings: UserSettings) -> Double {
        let now = Date()
        let windowStart = DateHelpers.todayAt(minute: settings.windowStartMinute)
        let windowEnd = DateHelpers.todayAt(minute: settings.windowEndMinute)

        guard now >= windowStart else { return 0 }
        guard now <= windowEnd else { return Double(settings.frequency.baselineCountPerDay) }

        let fractionOfWindow = now.timeIntervalSince(windowStart)
            / windowEnd.timeIntervalSince(windowStart)
        return Double(settings.frequency.baselineCountPerDay) * fractionOfWindow
    }

    private func fetchNextNudgeDate() -> Date? {
        // Synchronous isn't possible with UNUserNotificationCenter; return nil
        // and let widget timelines handle their own "next" computation.
        // We'll improve this by caching the next time in App Group defaults.
        let defaults = UserDefaults(suiteName: AppConstants.appGroupID)
        if let ts = defaults?.object(forKey: "nextNudgeTimestamp") as? TimeInterval {
            return Date(timeIntervalSince1970: ts)
        }
        return nil
    }

    private func fetchTodayClipCount(context: ModelContext) -> Int {
        let today = DateHelpers.dayKey(from: Date())
        let descriptor = FetchDescriptor<Clip>(
            predicate: #Predicate { $0.dayKey == today }
        )
        return (try? context.fetchCount(descriptor)) ?? 0
    }

    private func fetchLastClipDate(context: ModelContext) -> Date? {
        var descriptor = FetchDescriptor<Clip>(
            sortBy: [SortDescriptor(\.recordedAt, order: .reverse)]
        )
        descriptor.fetchLimit = 1
        return try? context.fetch(descriptor).first?.recordedAt
    }

    private func fetchSettings(context: ModelContext) -> UserSettings? {
        let descriptor = FetchDescriptor<UserSettings>()
        return try? context.fetch(descriptor).first
    }
}
