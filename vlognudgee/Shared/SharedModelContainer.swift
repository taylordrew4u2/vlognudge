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

        let config: ModelConfiguration
        if let groupURL = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: AppConstants.appGroupID) {
            config = ModelConfiguration(
                schema: schema,
                url: groupURL.appendingPathComponent("VlogNudge.sqlite"),
                cloudKitDatabase: .private(AppConstants.cloudKitContainerID)
            )
        } else {
            // Unsigned builds (CI simulator runs) have no app group or iCloud entitlement.
            Logger.persistence.error("App group container unavailable; using a local, non-synced store.")
            try? FileManager.default.createDirectory(at: .applicationSupportDirectory,
                                                     withIntermediateDirectories: true)
            config = ModelConfiguration(
                schema: schema,
                url: URL.applicationSupportDirectory.appendingPathComponent("VlogNudge.sqlite"),
                cloudKitDatabase: .none
            )
        }

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

