//
//  VlogNudgeActivityAttributes.swift
//  Shared (vlognudgee + vlogExtension)
//
//  The shape of data the Live Activity consumes. Defined once here and
//  compiled into both the app and the widget extension via shared target
//  membership, so the two targets can never drift out of sync.
//

import ActivityKit
import Foundation

struct VlogNudgeActivityAttributes: ActivityAttributes {
    public typealias ContentState = State

    public struct State: Codable, Hashable {
        var clipsToday: Int
        var targetClipsToday: Int
        var nextNudgeAt: Date?
        var lastClipAt: Date?
        var progressColor: ProgressColor

        enum ProgressColor: String, Codable {
            case green   // on track
            case yellow  // behind pace
            case orange  // well behind
        }

        var progressFraction: Double {
            guard targetClipsToday > 0 else { return 0 }
            return min(1.0, Double(clipsToday) / Double(targetClipsToday))
        }
    }

    // Static attributes — set at start, never change
    var dayKey: String
    var windowStart: Date
    var windowEnd: Date
}
