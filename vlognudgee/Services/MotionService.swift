//
//  MotionService.swift
//  VlogNudge
//

import Foundation
import CoreMotion
import Observation
import SwiftData

@Observable
final class MotionService {
    static let shared = MotionService()

    enum Activity: String {
        case stationary, walking, running, automotive, cycling, unknown
    }

    private let manager = CMMotionActivityManager()
    private(set) var current: Activity = .unknown
    private(set) var lastTransitionAt: Date?

    var isAvailable: Bool { CMMotionActivityManager.isActivityAvailable() }

    private init() {}

    func start() {
        guard isAvailable else { return }
        manager.startActivityUpdates(to: .main) { [weak self] activity in
            guard let self, let activity else { return }
            let new = Self.classify(activity)
            if new != self.current {
                self.lastTransitionAt = Date()
                self.current = new
                // Notify scheduler of potentially interesting transition
                Task { @MainActor in
                    await self.handleTransition(to: new)
                }
            }
        }
    }

    func stop() {
        manager.stopActivityUpdates()
    }

    private static func classify(_ activity: CMMotionActivity) -> Activity {
        if activity.automotive { return .automotive }
        if activity.cycling    { return .cycling }
        if activity.running    { return .running }
        if activity.walking    { return .walking }
        if activity.stationary { return .stationary }
        return .unknown
    }

    @MainActor
    private func handleTransition(to new: Activity) async {
        // Interesting transitions: arrived somewhere (walking/automotive → stationary)
        let isArrival = (new == .stationary)
        guard isArrival else { return }

        let context = SharedModelContainer.backgroundContext()
        await NudgeScheduler.shared.evaluateContextTrigger(
            reason: "motion_arrived_stationary",
            context: context
        )
    }
}
