//
//  ScreenTimeService.swift
//  VlogNudge
//
//  Screen Time / Family Controls integration.
//  NOTE: Requires Apple to approve the FamilyControls entitlement for
//  non-parental-control apps. If denied, this service will gracefully
//  no-op and the rest of the app continues working.
//

import Foundation
import FamilyControls
import DeviceActivity
import ManagedSettings

@MainActor
final class ScreenTimeService {
    static let shared = ScreenTimeService()
    private let center = AuthorizationCenter.shared
    private let activityCenter = DeviceActivityCenter()

    private(set) var authorizationStatus: AuthorizationStatus = .notDetermined

    private init() {}

    func requestAuthorization() async {
        do {
            try await center.requestAuthorization(for: .individual)
            authorizationStatus = center.authorizationStatus
        } catch {
            print("Family Controls auth error: \(error)")
        }
    }

    /// Start monitoring for doomscrolling patterns.
    /// Defines a schedule that matches the user's active window and a rolling check.
    func startMonitoring(windowStart: DateComponents,
                         windowEnd: DateComponents) {
        let schedule = DeviceActivitySchedule(
            intervalStart: windowStart,
            intervalEnd: windowEnd,
            repeats: true
        )

        do {
            try activityCenter.startMonitoring(
                .daily,
                during: schedule
            )
        } catch {
            print("Device activity monitoring failed: \(error)")
        }
    }

    func stopMonitoring() {
        activityCenter.stopMonitoring([.daily])
    }
}

extension DeviceActivityName {
    static let daily = Self("VlogNudge.DailyActivity")
}

extension DeviceActivityEvent.Name {
    static let doomscroll = Self("VlogNudge.Doomscroll")
}
