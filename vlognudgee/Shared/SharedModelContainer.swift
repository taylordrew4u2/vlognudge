//
//  SharedModelContainer.swift
//  VlogNudge
//
//  Single source of truth for the SwiftData container across the app.
//  Background callbacks (motion, location, health, calendar) need the
//  CloudKit-enabled container, not a bare in-memory one, so writes sync
//  to iCloud and across devices.
//

import Foundation
import SwiftData

enum SharedModelContainer {
    static let shared: ModelContainer = {
        let schema = Schema([
            Clip.self,
            NudgeEvent.self,
            Geofence.self,
            IdeaMemo.self,
            UserSettings.self,
            VlogAlbum.self
        ])

        let groupContainerURL = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: AppConstants.appGroupID)!
            .appendingPathComponent("VlogNudge.sqlite")

        let config = ModelConfiguration(
            schema: schema,
            url: groupContainerURL,
            cloudKitDatabase: .private(AppConstants.cloudKitContainerID)
        )

        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            // If the store is incompatible, delete and recreate rather than crashing.
            // Acceptable pre-launch; replace with proper migration once shipping.
            print("ModelContainer init failed: \(error). Resetting store.")
            try? FileManager.default.removeItem(at: groupContainerURL)
            do {
                return try ModelContainer(for: schema, configurations: [config])
            } catch {
                fatalError("Failed to initialize shared ModelContainer after reset: \(error)")
            }
        }
    }()

    /// Convenience for background callbacks to get a fresh context
    /// attached to the shared (CloudKit-synced) container.
    @MainActor
    static func backgroundContext() -> ModelContext {
        ModelContext(shared)
    }
}
