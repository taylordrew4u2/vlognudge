//
//  AppLogger.swift
//  VlogNudge
//
//  Centralized os.Logger instances, one per subsystem area. Prefer these
//  over print(): logs are structured, viewable in Console.app and sysdiagnose,
//  carry privacy annotations, and are compiled out of release builds where
//  appropriate. Error values are interpolated as `.public` so they remain
//  legible while developing.
//

import os

extension Logger {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "comedy.vlognudgee"

    static let health = Logger(subsystem: subsystem, category: "Health")
    static let liveActivity = Logger(subsystem: subsystem, category: "LiveActivity")
    static let recording = Logger(subsystem: subsystem, category: "Recording")
    static let notifications = Logger(subsystem: subsystem, category: "Notifications")
    static let calendar = Logger(subsystem: subsystem, category: "Calendar")
    static let scheduler = Logger(subsystem: subsystem, category: "Scheduler")
    static let persistence = Logger(subsystem: subsystem, category: "Persistence")
    static let capture = Logger(subsystem: subsystem, category: "Capture")
    static let ideas = Logger(subsystem: subsystem, category: "Ideas")
}
