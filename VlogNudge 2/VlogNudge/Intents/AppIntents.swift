//
//  AppIntents.swift
//  VlogNudge
//
//  Intents backing notification actions and widget taps.
//

import AppIntents
import Foundation

struct RecordClipIntent: AppIntent {
    static var title: LocalizedStringResource = "Record a vlog clip"
    static var description = IntentDescription("Opens the capture screen to film a clip.")
    static var openAppWhenRun: Bool = true

    @MainActor
    func perform() async throws -> some IntentResult {
        AppState.shared.requestCapture(prompt: nil)
        return .result()
    }
}

struct CaptureIdeaIntent: AppIntent {
    static var title: LocalizedStringResource = "Capture a vlog idea"
    static var description = IntentDescription("Quick voice memo to save a vlog idea for later.")
    static var openAppWhenRun: Bool = true

    @MainActor
    func perform() async throws -> some IntentResult {
        AppState.shared.deepLink = .ideaMemo
        return .result()
    }
}

struct NotNowIntent: AppIntent {
    static var title: LocalizedStringResource = "Not now"
    static var openAppWhenRun: Bool = false

    @MainActor
    func perform() async throws -> some IntentResult {
        await NudgeScheduler.shared.registerNotNow()
        return .result()
    }
}

struct SkipHourIntent: AppIntent {
    static var title: LocalizedStringResource = "Skip this hour"
    static var openAppWhenRun: Bool = false

    @MainActor
    func perform() async throws -> some IntentResult {
        await NudgeScheduler.shared.skipNextHour()
        return .result()
    }
}
