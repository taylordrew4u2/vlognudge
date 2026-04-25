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
        NudgeScheduler.shared.registerBackgroundRefreshTask()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(appState)
                .onOpenURL { url in
                    guard url.scheme == "vlognudge" else { return }
                    switch url.host {
                    case "record":
                        appState.requestCapture(prompt: nil)
                    case "idea":
                        appState.deepLink = .ideaMemo
                    case "timeline":
                        appState.deepLink = .timeline(date: .now)
                    default:
                        break
                    }
                }
                .task {
                    // Register categories on every launch (safe to call repeatedly)
                    NotificationService.shared.registerCategories()

                    // Start context services that observe changes in the background
                    MotionService.shared.start()
                    LocationService.shared.restoreExplicitBackgroundLocationIfNeeded()
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

                    // Seed default album if none exist
                    let albumCount = (try? modelContainer.mainContext.fetchCount(
                        FetchDescriptor<VlogAlbum>())) ?? 0
                    if albumCount == 0 {
                        let defaultAlbum = VlogAlbum(
                            name: AppConstants.photosAlbumName,
                            systemIcon: "video.fill",
                            colorHex: "FF3B30",
                            isDefault: true
                        )
                        modelContainer.mainContext.insert(defaultAlbum)
                        try? modelContainer.mainContext.save()
                    }
                }
        }
        .modelContainer(modelContainer)
    }
}
