//
//  AppIntents.swift
//  VlogNudge
//
//  Intents backing notification actions and widget taps.
//
//  This file must compile in BOTH the main app target AND the widget
//  extension target (the widget invokes RecordClipIntent/CaptureIdeaIntent
//  via Button(intent:)). To keep that possible, intents here may only
//  reference types visible to both targets: Foundation, AppIntents, and
//  AppConstants. They signal work via the shared App Group UserDefaults;
//  the main app drains the queue on foreground (see AppIntentsInbox).
//

import AppIntents
import Foundation

// MARK: - Shared signalling

enum PendingAppIntentAction: String, Codable {
    case record
    case idea
    case notNow
    case skipHour
}

enum AppIntentsInbox {
    static let queueKey = "pendingIntentActions"
    static let updatedAtKey = "pendingIntentActionsUpdatedAt"

    static func enqueue(_ action: PendingAppIntentAction) {
        guard let defaults = UserDefaults(suiteName: AppConstants.appGroupID) else { return }
        var queue = defaults.stringArray(forKey: queueKey) ?? []
        queue.append(action.rawValue)
        defaults.set(queue, forKey: queueKey)
        defaults.set(Date().timeIntervalSince1970, forKey: updatedAtKey)
    }

    static func drain() -> [PendingAppIntentAction] {
        guard let defaults = UserDefaults(suiteName: AppConstants.appGroupID) else { return [] }
        let raw = defaults.stringArray(forKey: queueKey) ?? []
        defaults.removeObject(forKey: queueKey)
        return raw.compactMap(PendingAppIntentAction.init(rawValue:))
    }
}

// MARK: - Intents

struct RecordClipIntent: AppIntent {
    static var title: LocalizedStringResource = "Record a vlog clip"
    static var description = IntentDescription("Opens the capture screen to film a clip.")
    static var openAppWhenRun: Bool = true

    func perform() async throws -> some IntentResult {
        // Enqueue to inbox (always works, even cross-process)
        AppIntentsInbox.enqueue(.record)
        // Also set directly in case we're running in the app process
        await MainActor.run {
            AppState.shared.requestCapture(prompt: nil)
        }
        return .result()
    }
}

struct CaptureIdeaIntent: AppIntent {
    static var title: LocalizedStringResource = "Capture a vlog idea"
    static var description = IntentDescription("Quick voice memo to save a vlog idea for later.")
    static var openAppWhenRun: Bool = true

    func perform() async throws -> some IntentResult {
        AppIntentsInbox.enqueue(.idea)
        await MainActor.run {
            AppState.shared.deepLink = .ideaMemo
        }
        return .result()
    }
}

struct NotNowIntent: AppIntent {
    static var title: LocalizedStringResource = "Not now"
    static var openAppWhenRun: Bool = false

    func perform() async throws -> some IntentResult {
        AppIntentsInbox.enqueue(.notNow)
        return .result()
    }
}

struct SkipHourIntent: AppIntent {
    static var title: LocalizedStringResource = "Skip this hour"
    static var openAppWhenRun: Bool = false

    func perform() async throws -> some IntentResult {
        AppIntentsInbox.enqueue(.skipHour)
        return .result()
    }
}
