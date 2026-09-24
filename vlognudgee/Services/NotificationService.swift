//
//  NotificationService.swift
//  VlogNudge
//
//  Handles authorization, categories, action buttons, and scheduling.
//  Uses UNNotificationRequest queue as the reliable backbone — iOS
//  holds these in its own scheduler so they fire even if the app is
//  suspended.
//

import Foundation
import os
import UserNotifications
import UIKit

@MainActor
final class NotificationService {
    static let shared = NotificationService()

    // Action identifiers
    enum ActionID {
        static let record = "ACTION_RECORD"
        static let notNow = "ACTION_NOT_NOW"
        static let skipHour = "ACTION_SKIP_HOUR"
    }

    private init() {}

    // MARK: - Authorization

    @discardableResult
    func requestAuthorization() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge, .providesAppNotificationSettings])
            if granted { registerCategories() }
            return granted
        } catch {
            Logger.notifications.error("Notification auth error: \(error.localizedDescription, privacy: .public)")
            return false
        }
    }

    func currentAuthorizationStatus() async -> UNAuthorizationStatus {
        await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
    }

    // MARK: - Category Registration

    func registerCategories() {
        // "Record" opens the app via App Intent when tapped.
        let recordAction = UNNotificationAction(
            identifier: ActionID.record,
            title: "Record",
            options: [.foreground],
            icon: UNNotificationActionIcon(systemImageName: "video.circle.fill")
        )

        let notNowAction = UNNotificationAction(
            identifier: ActionID.notNow,
            title: "Not now",
            options: [],
            icon: UNNotificationActionIcon(systemImageName: "xmark.circle")
        )

        let skipHourAction = UNNotificationAction(
            identifier: ActionID.skipHour,
            title: "Skip this hour",
            options: [],
            icon: UNNotificationActionIcon(systemImageName: "forward.fill")
        )

        let category = UNNotificationCategory(
            identifier: AppConstants.notificationCategoryID,
            actions: [recordAction, notNowAction, skipHourAction],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )

        UNUserNotificationCenter.current().setNotificationCategories([category])
    }

    // MARK: - Scheduling

    /// Schedule a single nudge for a specific date with a contextual prompt.
    func scheduleNudge(at fireDate: Date,
                       title: String,
                       body: String,
                       triggerReason: String,
                       useCustomSound: Bool = true,
                       hapticOnly: Bool = false) async {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.categoryIdentifier = AppConstants.notificationCategoryID
        content.userInfo = [
            "triggerReason": triggerReason,
            "scheduledFor": fireDate.timeIntervalSince1970
        ]

        if !hapticOnly {
            content.sound = useCustomSound
                ? UNNotificationSound(named: UNNotificationSoundName("NudgeSound.wav"))
                : .default
        }

        // Thread identifier groups nudges so they stack nicely
        content.threadIdentifier = "vlog-nudges"

        // Relevance score helps iOS prioritize surfacing this in notification summaries
        content.relevanceScore = 0.8

        // Interruption level — timeSensitive pushes past Focus modes we haven't hard-blocked
        content.interruptionLevel = .timeSensitive

        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute, .second],
            from: fireDate
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

        let request = UNNotificationRequest(
            identifier: nudgeIdentifier(for: fireDate, reason: triggerReason),
            content: content,
            trigger: trigger
        )

        do {
            try await UNUserNotificationCenter.current().add(request)
        } catch {
            Logger.notifications.error("Failed to schedule nudge: \(error.localizedDescription, privacy: .public)")
        }
    }

    /// Fire a nudge immediately (for context-triggered nudges where we want it NOW).
    func fireImmediateNudge(title: String,
                            body: String,
                            triggerReason: String,
                            useCustomSound: Bool = true,
                            hapticOnly: Bool = false) async {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.categoryIdentifier = AppConstants.notificationCategoryID
        content.userInfo = ["triggerReason": triggerReason]

        if !hapticOnly {
            content.sound = useCustomSound
                ? UNNotificationSound(named: UNNotificationSoundName("NudgeSound.wav"))
                : .default
        }
        content.threadIdentifier = "vlog-nudges"
        content.interruptionLevel = .timeSensitive

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "immediate-\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )

        do {
            try await UNUserNotificationCenter.current().add(request)
        } catch {
            Logger.notifications.error("Failed to fire immediate nudge: \(error.localizedDescription, privacy: .public)")
        }
    }

    /// Cancel all scheduled nudges. Called at start of each day before rescheduling.
    func cancelAllScheduledNudges() async {
        let center = UNUserNotificationCenter.current()
        let pending = await center.pendingNotificationRequests()
        let vlogIDs = pending
            .filter { $0.content.categoryIdentifier == AppConstants.notificationCategoryID }
            .map { $0.identifier }
        center.removePendingNotificationRequests(withIdentifiers: vlogIDs)
    }

    /// Cancel nudges scheduled after a specific date (e.g., when user just filmed,
    /// push future nudges back).
    func cancelNudges(after date: Date, before endDate: Date? = nil) async {
        let center = UNUserNotificationCenter.current()
        let pending = await center.pendingNotificationRequests()
        let toCancel = pending.filter {
            Self.shouldCancel($0, after: date, before: endDate)
        }.map(\.identifier)
        center.removePendingNotificationRequests(withIdentifiers: toCancel)
    }

    /// Clear delivered notifications when user films (they're no longer relevant).
    func clearDeliveredNudges() {
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
    }

    static func shouldCancel(_ request: UNNotificationRequest, after date: Date, before endDate: Date?) -> Bool {
        guard request.content.categoryIdentifier == AppConstants.notificationCategoryID,
              let next = nextFireDate(for: request.trigger), next > date else { return false }
        return endDate.map { next < $0 } ?? true
    }

    private static func nextFireDate(for trigger: UNNotificationTrigger?) -> Date? {
        if let calendar = trigger as? UNCalendarNotificationTrigger { return calendar.nextTriggerDate() }
        if let interval = trigger as? UNTimeIntervalNotificationTrigger { return interval.nextTriggerDate() }
        return nil
    }

    // MARK: - Helpers

    private func nudgeIdentifier(for date: Date, reason: String) -> String {
        "nudge-\(Int(date.timeIntervalSince1970))-\(reason)"
    }

    func pendingNudgeCount() async -> Int {
        let pending = await UNUserNotificationCenter.current().pendingNotificationRequests()
        return pending.filter { $0.content.categoryIdentifier == AppConstants.notificationCategoryID }.count
    }
}

