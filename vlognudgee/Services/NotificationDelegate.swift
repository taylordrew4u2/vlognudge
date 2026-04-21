//
//  NotificationDelegate.swift
//  VlogNudge
//
//  Routes action button taps from notifications into the app.
//

import Foundation
import UserNotifications
import UIKit

final class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationDelegate()

    // Show notifications even when app is in foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                 willPresent notification: UNNotification) async
        -> UNNotificationPresentationOptions {
        return [.banner, .sound, .badge]
    }

    // Handle action button taps
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                 didReceive response: UNNotificationResponse) async {
        let actionID = response.actionIdentifier
        let userInfo = response.notification.request.content.userInfo
        let triggerReason = userInfo["triggerReason"] as? String ?? "unknown"

        switch actionID {
        case NotificationService.ActionID.record,
             UNNotificationDefaultActionIdentifier:
            await MainActor.run {
                AppState.shared.requestCapture(prompt: response.notification.request.content.body)
            }
            await NudgeScheduler.shared.logNudgeResult(
                triggerReason: triggerReason,
                filmed: true
            )

        case NotificationService.ActionID.notNow:
            await NudgeScheduler.shared.registerNotNow()
            await NudgeScheduler.shared.logNudgeResult(
                triggerReason: triggerReason,
                filmed: false
            )

        case NotificationService.ActionID.skipHour:
            await NudgeScheduler.shared.skipNextHour()

        case UNNotificationDismissActionIdentifier:
            await NudgeScheduler.shared.logNudgeResult(
                triggerReason: triggerReason,
                filmed: false
            )

        default:
            break
        }
    }
}
