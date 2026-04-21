//
//  VlogNudgeDeviceActivityMonitor.swift
//  VlogNudgeDeviceActivity (separate extension target)
//
//  Runs in a separate process when DeviceActivity events fire.
//  Communicates back to the main app via Darwin notifications + App Group.
//

import DeviceActivity
import Foundation

final class VlogNudgeDeviceActivityMonitor: DeviceActivityMonitor {

    override func intervalDidStart(for activity: DeviceActivityName) {
        super.intervalDidStart(for: activity)
        postDarwinNotification("vlognudge.interval.started")
    }

    override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)
        postDarwinNotification("vlognudge.interval.ended")
    }

    override func eventDidReachThreshold(_ event: DeviceActivityEvent.Name,
                                          activity: DeviceActivityName) {
        super.eventDidReachThreshold(event, activity: activity)

        // Log to app group so main app can pick it up
        let defaults = UserDefaults(suiteName: "group.com.taylordrew.vlognudge")
        defaults?.set(Date().timeIntervalSince1970, forKey: "lastDoomscrollDetectedAt")

        postDarwinNotification("vlognudge.doomscroll.detected")
    }

    private func postDarwinNotification(_ name: String) {
        let cfName = name as CFString
        CFNotificationCenterPostNotification(
            CFNotificationCenterGetDarwinNotifyCenter(),
            CFNotificationName(cfName),
            nil,
            nil,
            true
        )
    }
}
