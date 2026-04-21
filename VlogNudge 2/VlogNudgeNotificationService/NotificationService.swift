//
//  NotificationService.swift
//  VlogNudgeNotificationService
//
//  Runs briefly when a notification is about to be presented.
//  We use it to:
//    1. Inject "last clip Xm ago" grounding into the body
//    2. Add "Nudged because: [reason]" tail so the user sees why
//    3. Read shared App Group state for up-to-the-moment context
//

import UserNotifications
import Foundation

class NotificationService: UNNotificationServiceExtension {

    var contentHandler: ((UNNotificationContent) -> Void)?
    var bestAttemptContent: UNMutableNotificationContent?

    override func didReceive(_ request: UNNotificationRequest,
                             withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        self.contentHandler = contentHandler
        bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)

        guard let content = bestAttemptContent else {
            contentHandler(request.content)
            return
        }

        let userInfo = content.userInfo
        let reason = userInfo["triggerReason"] as? String ?? ""

        let defaults = UserDefaults(suiteName: "group.com.taylordrew.vlognudge")

        // Enrich with last-clip grounding
        var addendum: [String] = []

        if let ts = defaults?.object(forKey: "lastClipTimestamp") as? TimeInterval {
            let lastClip = Date(timeIntervalSince1970: ts)
            let minutes = Int(Date().timeIntervalSince(lastClip) / 60)
            if minutes < 60 {
                addendum.append("Last clip \(minutes)m ago")
            } else {
                addendum.append("Last clip \(minutes / 60)h ago")
            }
        } else {
            addendum.append("No clips yet today")
        }

        // Nudged-because reason
        if !reason.isEmpty, reason != "baseline" {
            let pretty = prettyReason(reason)
            addendum.append("Nudged: \(pretty)")
        }

        if !addendum.isEmpty {
            content.body += "\n" + addendum.joined(separator: " · ")
        }

        contentHandler(content)
    }

    override func serviceExtensionTimeWillExpire() {
        if let contentHandler, let bestAttemptContent {
            contentHandler(bestAttemptContent)
        }
    }

    private func prettyReason(_ reason: String) -> String {
        // "geofence_entry:UUID" → "arrived at known spot"
        if reason.hasPrefix("geofence_entry") { return "arrived somewhere" }
        if reason.hasPrefix("geofence_exit")  { return "leaving a spot" }
        if reason == "geofence_new_location"  { return "new location" }
        if reason == "motion_arrived_stationary" { return "just settled in" }
        if reason == "calendar_event_ended"   { return "event ended" }
        if reason == "pre_event"              { return "something coming up" }
        if reason == "workout_ended"          { return "post-workout" }
        if reason == "weather_changed"        { return "weather shifted" }
        if reason == "doomscroll_detected"    { return "scroll break" }
        if reason == "end_of_day_recap"       { return "end of day recap" }
        if reason == "long_gap"               { return "long gap since last clip" }
        return reason.replacingOccurrences(of: "_", with: " ")
    }
}
