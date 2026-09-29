//
//  ScreenshotMode.swift
//  VlogNudge
//
//  Launch-argument driven demo mode used by scripts/capture_screenshots.sh.
//  `-ScreenshotMode` skips onboarding and background services, swaps in an
//  in-memory store seeded with sample clips, and `-ScreenshotTab N` /
//  `-ScreenshotSettingsPlaces` pick the screen to capture.
//

import Foundation
import SwiftData

enum ScreenshotMode {
    private static let arguments = ProcessInfo.processInfo.arguments

    static let isActive = arguments.contains("-ScreenshotMode")

    static var initialTab: Int? {
        guard isActive,
              let index = arguments.firstIndex(of: "-ScreenshotTab"),
              arguments.indices.contains(index + 1) else { return nil }
        return Int(arguments[index + 1])
    }

    static var scrollToPlaces: Bool {
        isActive && arguments.contains("-ScreenshotSettingsPlaces")
    }

    /// Next-nudge time shown on Today, since no notifications are scheduled.
    static var sampleNextNudge: Date { Date().addingTimeInterval(47 * 60) }

    @MainActor
    static func seed(_ context: ModelContext) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)

        let albums = [
            VlogAlbum(name: AppConstants.photosAlbumName, systemIcon: "video.fill",
                      colorHex: "FF3B30", isDefault: true),
            VlogAlbum(name: "Tokyo Trip", systemIcon: "airplane", colorHex: "007AFF"),
            VlogAlbum(name: "Gym Days", systemIcon: "figure.run", colorHex: "34C759")
        ]
        for (index, album) in albums.enumerated() {
            album.sortOrder = index
            context.insert(album)
        }

        // Relative to now so "last clip … ago" reads sensibly whenever it runs.
        let todayPrompts: [(minutesAgo: Int, prompt: String)] = [
            (190, "Morning coffee ritual"),
            (95, "You just got to the office — quick clip?"),
            (25, "What's for lunch?")
        ]
        for item in todayPrompts {
            let date = max(today, Date().addingTimeInterval(-Double(item.minutesAgo) * 60))
            context.insert(Clip(recordedAt: date, duration: 12, photosAssetID: "",
                                topicPrompt: item.prompt))
        }

        // Scatter clips across the past few weeks so the Timeline has texture.
        for dayOffset in [1, 2, 3, 5, 6, 8, 9, 12, 13, 15, 16, 19, 20, 22] {
            guard let day = calendar.date(byAdding: .day, value: -dayOffset, to: today) else { continue }
            for hour in [9, 14, 19].prefix(1 + dayOffset % 3) {
                let date = calendar.date(bySettingHour: hour, minute: 20, second: 0, of: day) ?? day
                context.insert(Clip(recordedAt: date, duration: 15, photosAssetID: "",
                                    albumName: dayOffset % 4 == 0 ? "Gym Days" : AppConstants.photosAlbumName))
            }
        }

        for text in ["Film the sunset walk home", "Desk setup tour", "Cooking dinner time-lapse"] {
            context.insert(IdeaMemo(text: text))
        }

        context.insert(Geofence(name: "Home", latitude: 37.3349, longitude: -122.0090))
        context.insert(UserSettings())
        try? context.save()
    }
}
