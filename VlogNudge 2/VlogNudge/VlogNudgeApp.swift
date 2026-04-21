//
//  VlogNudgeApp.swift
//  VlogNudge
//

import SwiftUI
import SwiftData
import UserNotifications

@main
struct VlogNudgeApp: App {
    @State private var appState = AppState.shared
    let modelContainer: ModelContainer = SharedModelContainer.shared

    init() {
        // Wire up notification delegate on launch
        UNUserNotificationCenter.current().delegate = NotificationDelegate.shared
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(appState)
                .task {
                    // Register categories on every launch (safe to call repeatedly)
                    NotificationService.shared.registerCategories()

                    // Start context services that observe changes in the background
                    MotionService.shared.start()
                    LocationService.shared.start()
                    HealthService.shared.startObservingWorkouts()
                    FocusService.shared.refresh()

                    // On cold launch, make sure today's nudges are scheduled
                    await NudgeScheduler.shared.ensureTodayIsScheduled(
                        context: modelContainer.mainContext
                    )
                    LiveActivityController.shared.startOrUpdateTodaysActivity(
                        context: modelContainer.mainContext
                    )

                    // Refresh monitored geofences based on current saved list
                    let fences = (try? modelContainer.mainContext.fetch(
                        FetchDescriptor<Geofence>())) ?? []
                    LocationService.shared.refreshGeofences(from: fences, near: nil)
                }
        }
        .modelContainer(modelContainer)
    }
}
