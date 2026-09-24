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
import os
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
            Logger.persistence.error("ModelContainer init failed: \(error.localizedDescription, privacy: .public). Existing store preserved.")
            fatalError("Unable to open VlogNudge data. The existing store has been preserved: \(error)")
        }
    }()

    /// Convenience for background callbacks to get a fresh context
    /// attached to the shared (CloudKit-synced) container.
    @MainActor
    static func backgroundContext() -> ModelContext {
        ModelContext(shared)
    }
}

