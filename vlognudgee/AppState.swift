//
//  AppState.swift
//  VlogNudge
//

import SwiftUI
import Observation

@Observable
final class AppState {
    static let shared = AppState()

    enum DeepLink: Equatable {
        case none
        case capture(prompt: String?)
        case ideaMemo
        case timeline(date: Date)
    }

    var deepLink: DeepLink = .none
    var isRecording: Bool = false
    var currentPrompt: String?
    var activeAlbumName: String = AppConstants.photosAlbumName

    /// Set when the user triggers "capture idea" so the Ideas tab opens the
    /// new-idea editor immediately. Consumed (reset) by IdeasView.
    var composeIdea: Bool = false

    private init() {}

    func requestCapture(prompt: String? = nil) {
        currentPrompt = prompt
        deepLink = .capture(prompt: prompt)
    }

    func clearDeepLink() {
        deepLink = .none
    }
}
