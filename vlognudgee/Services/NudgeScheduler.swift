//
//  NudgeScheduler.swift
//  VlogNudge
//
//  Maintains a rolling queue of scheduled notifications for today.
//  Re-runs on cold launch, after any clip is filmed, when context
//  changes wake the app, and from BGAppRefreshTask each morning.
//
//  Key design: pre-schedule the day's baseline nudges so they fire
//  even if the app is suspended. Context triggers modify the queue
//  (push next nudge back, or fire an immediate extra) when events happen.
//

import Foundation
import SwiftData
import BackgroundTasks
import UserNotifications
import WidgetKit

@MainActor
final class NudgeScheduler {
    static let shared = NudgeScheduler()

    private init() {}

    // MARK: - Public API

    /// Called on app launch and every morning via BGAppRefreshTask.
    /// Ensures today's baseline nudges are scheduled.
    func ensureTodayIsScheduled(context: ModelContext) async {
        guard let settings = fetchOrCreateSettings(context: context) else { return }

        // Clear any stale pending nudges
        await NotificationService.shared.cancelAllScheduledNudges()

        // Compute baseline fire times within today's window
        let baselineTimes = computeBaselineTimes(settings: settings)

        for time in baselineTimes where time > Date() {
            let prompt = PromptGenerator.prompt(
                for: time,
                reason: "baseline",
                settings: settings,
                lastClipDate: fetchLastClipDate(context: context)
            )

            await NotificationService.shared.scheduleNudge(
                at: time,
                title: prompt.title,
                body: prompt.body,
                triggerReason: "baseline",
                useCustomSound: settings.customSoundEnabled,
                hapticOnly: settings.hapticOnlyMode
            )
        }

        // Schedule end-of-day recap if enabled
        if settings.enableEndOfDayRecap {
            let recapTime = DateHelpers.todayAt(minute: settings.windowEndMinute - 60)
            if recapTime > Date() {
                await NotificationService.shared.scheduleNudge(
                    at: recapTime,
                    title: "Recap the day?",
                    body: "Quick clip about what you did today — great for voiceover B-roll.",
                    triggerReason: "end_of_day_recap",
                    useCustomSound: settings.customSoundEnabled,
                    hapticOnly: settings.hapticOnlyMode
                )
            }
        }

        // Schedule BG refresh for tomorrow morning
        scheduleBackgroundRefresh()

        // Update shared defaults so widgets show the right info
        await updateSharedDefaults(context: context, settings: settings)
    }

    /// Push current state to App Group defaults so widgets read up-to-date data.
    func updateSharedDefaults(context: ModelContext, settings: UserSettings) async {
        let defaults = UserDefaults(suiteName: AppConstants.appGroupID)

        // Find soonest pending nudge
        let pending = await UNUserNotificationCenter.current().pendingNotificationRequests()
        let upcoming = pending
            .filter { $0.content.categoryIdentifier == AppConstants.notificationCategoryID }
            .compactMap { ($0.trigger as? UNCalendarNotificationTrigger)?.nextTriggerDate() }
            .filter { $0 > Date() }
            .min()

        if let next = upcoming {
            defaults?.set(next.timeIntervalSince1970, forKey: "nextNudgeTimestamp")
        } else {
            defaults?.removeObject(forKey: "nextNudgeTimestamp")
        }

        // Today's clip count
        let todayKey = DateHelpers.dayKey(from: Date())
        let todayDescriptor = FetchDescriptor<Clip>(
            predicate: #Predicate { $0.dayKey == todayKey }
        )
        let todayCount = (try? context.fetchCount(todayDescriptor)) ?? 0
        defaults?.set(todayCount, forKey: "clipsToday")
        defaults?.set(settings.frequency.baselineCountPerDay, forKey: "targetToday")

        // Last clip timestamp
        if let lastDate = fetchLastClipDate(context: context) {
            defaults?.set(lastDate.timeIntervalSince1970, forKey: "lastClipTimestamp")
        }

        // Force widgets to refresh
        WidgetCenter.shared.reloadAllTimelines()
    }

    /// Called when a context event wakes the app (geofence, motion, calendar).
    /// Decides whether to fire an immediate extra nudge.
    func evaluateContextTrigger(reason: String,
                                context: ModelContext) async {
        guard let settings = fetchOrCreateSettings(context: context) else { return }

        let snapshot = buildContextSnapshot(reason: reason, context: context)
        let lastClip = fetchLastClipDate(context: context)
        let recentNudges = fetchRecentNudges(context: context)

        let decision = NudgeScorer.score(
            context: snapshot,
            settings: settings,
            recentNudges: recentNudges,
            lastClipDate: lastClip
        )

        guard decision.shouldFire else {
            print("Context trigger \(reason) suppressed. Score: \(decision.score), blocks: \(decision.blockReasons)")
            return
        }

        let prompt = PromptGenerator.prompt(
            for: Date(),
            reason: reason,
            settings: settings,
            lastClipDate: lastClip
        )

        await NotificationService.shared.fireImmediateNudge(
            title: prompt.title,
            body: prompt.body,
            triggerReason: reason,
            useCustomSound: settings.customSoundEnabled,
            hapticOnly: settings.hapticOnlyMode
        )

        // Log the event
        let event = NudgeEvent(
            scheduledFor: Date(),
            score: decision.score,
            triggerReason: reason,
            context: snapshot
        )
        event.firedAt = Date()
        context.insert(event)
        try? context.save()
    }

    /// Called after a clip is filmed — push the next scheduled nudge back.
    func clipWasFilmed(context: ModelContext) async {
        guard let settings = fetchOrCreateSettings(context: context) else { return }

        // Write last-clip timestamp to App Group so widgets and notification
        // service extension can read it
        let defaults = UserDefaults(suiteName: AppConstants.appGroupID)
        defaults?.set(Date().timeIntervalSince1970, forKey: "lastClipTimestamp")

        // Update today's clip count for widgets
        let todayKey = DateHelpers.dayKey(from: Date())
        let todayDescriptor = FetchDescriptor<Clip>(
            predicate: #Predicate { $0.dayKey == todayKey }
        )
        let todayCount = (try? context.fetchCount(todayDescriptor)) ?? 0
        defaults?.set(todayCount, forKey: "clipsToday")
        defaults?.set(settings.frequency.baselineCountPerDay, forKey: "targetToday")

        // Cancel any pending nudges in the near future (next hour)
        await NotificationService.shared.cancelNudges(after: Date())

        // Recompute and reschedule remaining baseline nudges for today
        let now = Date()
        let baselineTimes = computeBaselineTimes(settings: settings)
            .filter { $0 > now.addingTimeInterval(60 * 60) } // gap after this clip

        let lastClipDate = Date()

        for time in baselineTimes {
            let prompt = PromptGenerator.prompt(
                for: time,
                reason: "baseline",
                settings: settings,
                lastClipDate: lastClipDate
            )
            await NotificationService.shared.scheduleNudge(
                at: time,
                title: prompt.title,
                body: prompt.body,
                triggerReason: "baseline",
                useCustomSound: settings.customSoundEnabled,
                hapticOnly: settings.hapticOnlyMode
            )
        }

        // Clear any delivered nudges still sitting on Lock Screen
        NotificationService.shared.clearDeliveredNudges()

        // Update Live Activity
        LiveActivityController.shared.refresh(context: context)

        // Push fresh state to widgets
        await updateSharedDefaults(context: context, settings: settings)
    }

    /// User tapped "Not now" on a nudge. Track for cool-down logic.
    func registerNotNow() async {
        let context = SharedModelContainer.backgroundContext()

        guard let settings = fetchOrCreateSettings(context: context) else { return }

        // Count dismissals in last 2hr
        let twoHoursAgo = Date().addingTimeInterval(-2 * 3600)
        let recentDismissals = fetchRecentNudges(context: context)
            .filter { ($0.dismissedAt ?? Date.distantPast) > twoHoursAgo }
            .count

        if recentDismissals >= 3 {
            settings.cooldownUntil = Date().addingTimeInterval(2 * 3600)
            try? context.save()
            print("User dismissed 3 nudges in 2hr — auto cool-down for 2hr")
        }
    }

    func skipNextHour() async {
        let until = Date().addingTimeInterval(60 * 60)
        await NotificationService.shared.cancelNudges(after: Date())
        // Re-schedule from the "until" time onward next time scheduler runs
        print("Skipping nudges for 1 hour (until \(until))")
    }

    func logNudgeResult(triggerReason: String, filmed: Bool) async {
        let context = SharedModelContainer.backgroundContext()

        let recent = fetchRecentNudges(context: context)
            .filter { $0.triggerReason == triggerReason }
            .sorted { ($0.firedAt ?? .distantPast) > ($1.firedAt ?? .distantPast) }

        if let latest = recent.first {
            if filmed {
                // resultedInClipID set by capture flow
            } else {
                latest.dismissedAt = Date()
            }
            try? context.save()
        }
    }

    // MARK: - Baseline computation

    private func computeBaselineTimes(settings: UserSettings) -> [Date] {
        let count = settings.frequency.baselineCountPerDay
        guard count > 0 else { return [] }

        let windowStart = settings.windowStartMinute
        let windowEnd = settings.windowEndMinute
        let windowMinutes = max(60, windowEnd - windowStart)
        let interval = windowMinutes / (count + 1) // space so none are at the exact edges

        var times: [Date] = []
        for i in 1...count {
            let minute = windowStart + (interval * i)
            // Add ±10 min jitter so nudges don't feel like rigid alarms
            let jitter = Int.random(in: -10...10)
            let finalMinute = minute + jitter
            times.append(DateHelpers.todayAt(minute: finalMinute))
        }
        return times
    }

    // MARK: - Background refresh

    static let bgTaskIdentifier = "com.taylordrew.vlognudge.refresh"

    func registerBackgroundRefreshTask() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: Self.bgTaskIdentifier, using: nil) { task in
            guard let refreshTask = task as? BGAppRefreshTask else {
                task.setTaskCompleted(success: false)
                return
            }

            self.handleBackgroundRefresh(task: refreshTask)
        }
    }

    func scheduleBackgroundRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: Self.bgTaskIdentifier)
        // Fire tomorrow at window-open time
        guard let settings = try? fetchSettingsStandalone() else { return }
        let tomorrowOpen = Calendar.current.date(
            byAdding: .day,
            value: 1,
            to: DateHelpers.todayAt(minute: settings.windowStartMinute)
        )
        request.earliestBeginDate = tomorrowOpen

        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            print("Failed to schedule BG refresh: \(error)")
        }
    }

    // MARK: - Private helpers

    private func handleBackgroundRefresh(task: BGAppRefreshTask) {
        scheduleBackgroundRefresh()

        task.expirationHandler = {
            task.setTaskCompleted(success: false)
        }

        Task { @MainActor in
            let context = SharedModelContainer.backgroundContext()
            await ensureTodayIsScheduled(context: context)
            task.setTaskCompleted(success: true)
        }
    }

    private func fetchOrCreateSettings(context: ModelContext) -> UserSettings? {
        let descriptor = FetchDescriptor<UserSettings>()
        if let existing = try? context.fetch(descriptor).first {
            return existing
        }
        let new = UserSettings()
        context.insert(new)
        try? context.save()
        return new
    }

    private func fetchSettingsStandalone() throws -> UserSettings? {
        let context = ModelContext(SharedModelContainer.shared)
        let descriptor = FetchDescriptor<UserSettings>()
        return try context.fetch(descriptor).first
    }

    private func fetchLastClipDate(context: ModelContext) -> Date? {
        var descriptor = FetchDescriptor<Clip>(
            sortBy: [SortDescriptor(\.recordedAt, order: .reverse)]
        )
        descriptor.fetchLimit = 1
        return try? context.fetch(descriptor).first?.recordedAt
    }

    private func fetchRecentNudges(context: ModelContext) -> [NudgeEvent] {
        let twentyFourHoursAgo = Date().addingTimeInterval(-24 * 3600)
        let descriptor = FetchDescriptor<NudgeEvent>(
            predicate: #Predicate { $0.scheduledFor > twentyFourHoursAgo }
        )
        return (try? context.fetch(descriptor)) ?? []
    }

    private func buildContextSnapshot(reason: String, context: ModelContext) -> ContextSnapshot {
        var snapshot = ContextSnapshot()
        snapshot.timestamp = Date()

        if let lastClip = fetchLastClipDate(context: context) {
            snapshot.minutesSinceLastClip = Int(Date().timeIntervalSince(lastClip) / 60)
        }

        // Services will fill in motion, location, calendar, weather here
        // when they're wired up. For now we just carry the reason forward
        // so the scorer has something to work with.
        if reason.hasPrefix("geofence") {
            snapshot.lastGeofenceTransition = reason
        } else if reason.hasPrefix("motion") {
            snapshot.motionActivity = reason.replacingOccurrences(of: "motion_", with: "")
        }

        return snapshot
    }
}
