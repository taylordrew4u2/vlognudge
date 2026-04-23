//
//  AppIntent.swift
//  vlog (widget extension)
//
//  Shared types mirrored from the main app target.
//  Keep in sync with vlognudgee/Intents/AppIntents.swift
//  and vlognudgee/Shared/AppConstants.swift.
//

import AppIntents
import Foundation

// MARK: - Constants

enum AppConstants {
    static let appGroupID = "group.com.taylordrew.vlognudge"
}

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
}

// MARK: - Intents

struct RecordClipIntent: AppIntent {
    static var title: LocalizedStringResource = "Record a vlog clip"
    static var description = IntentDescription("Opens the capture screen to film a clip.")
    static var openAppWhenRun: Bool = true

    func perform() async throws -> some IntentResult {
        AppIntentsInbox.enqueue(.record)
        return .result()
    }
}

struct CaptureIdeaIntent: AppIntent {
    static var title: LocalizedStringResource = "Capture a vlog idea"
    static var description = IntentDescription("Quick voice memo to save a vlog idea for later.")
    static var openAppWhenRun: Bool = true

    func perform() async throws -> some IntentResult {
        AppIntentsInbox.enqueue(.idea)
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
