//
//  Models.swift
//  VlogNudge
//
//  All SwiftData models in one file for easy reference.
//

import Foundation
import SwiftData

// MARK: - Clip

@Model
final class Clip {
    var id: UUID = UUID()
    var recordedAt: Date = Date()
    var duration: TimeInterval = 0
    var photosAssetID: String = ""
    var topicPrompt: String?
    var starred: Bool = false
    var dayKey: String = ""
    var capturedContextJSON: String?

    init(recordedAt: Date = Date(),
         duration: TimeInterval,
         photosAssetID: String,
         topicPrompt: String? = nil,
         capturedContext: ContextSnapshot? = nil) {
        self.id = UUID()
        self.recordedAt = recordedAt
        self.duration = duration
        self.photosAssetID = photosAssetID
        self.topicPrompt = topicPrompt
        self.starred = false
        self.dayKey = DateHelpers.dayKey(from: recordedAt)
        if let context = capturedContext,
           let data = try? JSONEncoder().encode(context),
           let json = String(data: data, encoding: .utf8) {
            self.capturedContextJSON = json
        }
    }
}

// MARK: - NudgeEvent

@Model
final class NudgeEvent {
    var id: UUID = UUID()
    var scheduledFor: Date = Date()
    var firedAt: Date?
    var dismissedAt: Date?
    var resultedInClipID: UUID?
    var score: Int = 0
    var triggerReason: String = ""
    var contextSnapshotJSON: String = ""

    init(scheduledFor: Date,
         score: Int,
         triggerReason: String,
         context: ContextSnapshot) {
        self.id = UUID()
        self.scheduledFor = scheduledFor
        self.score = score
        self.triggerReason = triggerReason
        if let data = try? JSONEncoder().encode(context),
           let json = String(data: data, encoding: .utf8) {
            self.contextSnapshotJSON = json
        }
    }
}

// MARK: - Geofence

@Model
final class Geofence {
    var id: UUID = UUID()
    var name: String = ""
    var latitude: Double = 0
    var longitude: Double = 0
    var radius: Double = 100
    var nudgeOnEntry: Bool = true
    var nudgeOnExit: Bool = true
    var customPromptOnEntry: String?
    var customPromptOnExit: String?

    init(name: String, latitude: Double, longitude: Double, radius: Double = 100) {
        self.id = UUID()
        self.name = name
        self.latitude = latitude
        self.longitude = longitude
        self.radius = radius
    }
}

// MARK: - IdeaMemo

@Model
final class IdeaMemo {
    var id: UUID = UUID()
    var createdAt: Date = Date()
    var audioFilePath: String?
    var usedAt: Date?
    var shortLabel: String?

    init(audioFilePath: String? = nil, shortLabel: String? = nil) {
        self.id = UUID()
        self.createdAt = Date()
        self.audioFilePath = audioFilePath
        self.shortLabel = shortLabel
    }
}

// MARK: - UserSettings

enum NudgeFrequency: String, Codable, CaseIterable {
    case chill, normal, aggressive, contextOnly

    var baselineCountPerDay: Int {
        switch self {
        case .chill: return 4
        case .normal: return 6
        case .aggressive: return 10
        case .contextOnly: return 0
        }
    }

    var scoreThreshold: Int {
        switch self {
        case .chill: return 3
        case .normal: return 2
        case .aggressive: return 1
        case .contextOnly: return 2
        }
    }

    var displayName: String {
        switch self {
        case .chill: return "Chill"
        case .normal: return "Normal"
        case .aggressive: return "Aggressive"
        case .contextOnly: return "Context Only"
        }
    }

    var blurb: String {
        switch self {
        case .chill: return "4 baseline nudges/day plus strong context triggers. ~4–6/day total."
        case .normal: return "6 baseline nudges plus medium context triggers. ~8–10/day total."
        case .aggressive: return "10 baseline nudges plus any context trigger. ~12–15/day total."
        case .contextOnly: return "No scheduled nudges. Only fires when something happens."
        }
    }
}

enum OrientationLock: String, Codable { case vertical, horizontal, free }

@Model
final class UserSettings {
    var id: UUID = UUID()

    // Schedule
    var windowStartMinute: Int = 600      // 10:00am
    var windowEndMinute: Int = 1320       // 22:00

    // Nudge behavior
    var frequencyRaw: String = NudgeFrequency.normal.rawValue
    var minGapBetweenNudgesMin: Int = 45
    var enableEscalation: Bool = true
    var enableEndOfDayRecap: Bool = true
    var enableMidpointCheckIn: Bool = true

    // Quiet hours
    var quietHoursEnabled: Bool = false
    var quietStartMinute: Int = 1380
    var quietEndMinute: Int = 540

    // Context signals
    var useMotion: Bool = true
    var useLocation: Bool = true
    var useCalendar: Bool = true
    var useHealth: Bool = true
    var useWeather: Bool = true
    var useFocus: Bool = true
    var useScreenTime: Bool = true

    // Capture
    var orientationLockRaw: String = OrientationLock.vertical.rawValue
    var softClipLengthCap: Int = 60

    // Notifications
    var customSoundEnabled: Bool = true
    var hapticOnlyMode: Bool = false

    // Calibration mode
    var inCalibrationMode: Bool = false
    var calibrationStartedAt: Date?

    // Transient cool-downs (stored as time windows)
    var cooldownUntil: Date?              // set when 3 dismissals in 2hr
    var badDayUntil: Date?                // set by "Bad day" button

    init() {
        self.id = UUID()
    }

    // Computed helpers
    var frequency: NudgeFrequency {
        get { NudgeFrequency(rawValue: frequencyRaw) ?? .normal }
        set { frequencyRaw = newValue.rawValue }
    }

    var orientationLock: OrientationLock {
        get { OrientationLock(rawValue: orientationLockRaw) ?? .vertical }
        set { orientationLockRaw = newValue.rawValue }
    }
}

// MARK: - ContextSnapshot (plain Codable struct, not @Model)

struct ContextSnapshot: Codable {
    var timestamp: Date = Date()
    var motionActivity: String?
    var currentGeofenceID: String?
    var lastGeofenceTransition: String?
    var minutesSinceLastClip: Int?
    var unlocksInLast10Min: Int?
    var upcomingEventInMinutes: Int?
    var lastEventEndedMinutesAgo: Int?
    var inFocusMode: Bool = false
    var isCharging: Bool = false
    var isOnCall: Bool = false
    var weatherCondition: String?
    var phoneActiveDevice: Bool = true
}
