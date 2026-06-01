//
//  HealthService.swift
//  VlogNudge
//

import Foundation
import HealthKit
import os
import SwiftData

@MainActor
final class HealthService {
    static let shared = HealthService()
    private let healthStore = HKHealthStore()
    private var workoutObserverQuery: HKObserverQuery?

    private init() {}

    var isAvailable: Bool { HKHealthStore.isHealthDataAvailable() }

    func requestAuthorization() async {
        guard isAvailable else { return }
        let workoutType = HKObjectType.workoutType()
        do {
            try await healthStore.requestAuthorization(
                toShare: [],
                read: [workoutType]
            )
        } catch {
            Logger.health.error("HealthKit auth error: \(error.localizedDescription, privacy: .public)")
        }
    }

    func startObservingWorkouts() {
        guard isAvailable else { return }
        let workoutType = HKObjectType.workoutType()

        // Enable background delivery
        healthStore.enableBackgroundDelivery(for: workoutType, frequency: .immediate) { success, error in
            if let error = error {
                Logger.health.error("Background delivery error: \(error.localizedDescription, privacy: .public)")
            }
        }

        let query = HKObserverQuery(sampleType: workoutType, predicate: nil) { [weak self] _, completionHandler, error in
            defer { completionHandler() }
            guard error == nil else { return }
            Task { await self?.handleWorkoutChange() }
        }
        healthStore.execute(query)
        workoutObserverQuery = query
    }

    private func handleWorkoutChange() async {
        // Fetch most recent workout
        let workoutType = HKObjectType.workoutType()
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)

        let sampleQuery = HKSampleQuery(sampleType: workoutType,
                                         predicate: nil,
                                         limit: 1,
                                         sortDescriptors: [sort]) { _, samples, _ in
            guard let workout = samples?.first as? HKWorkout else { return }
            let endedAgo = Date().timeIntervalSince(workout.endDate)
            if endedAgo < 10 * 60 {
                Task { @MainActor in
                    let context = SharedModelContainer.backgroundContext()
                    await NudgeScheduler.shared.evaluateContextTrigger(
                        reason: "workout_ended",
                        context: context
                    )
                }
            }
        }
        healthStore.execute(sampleQuery)
    }
}
