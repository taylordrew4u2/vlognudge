//
//  LockScreenWidget.swift
//  VlogNudgeWidgets
//

import SwiftUI
import WidgetKit
import AppIntents

struct LockScreenWidget: Widget {
    let kind: String = "LockScreenWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: LockScreenProvider()) { entry in
            LockScreenEntryView(entry: entry)
        }
        .configurationDisplayName("VlogNudge")
        .description("Next nudge + today's clip count.")
        .supportedFamilies([
            .accessoryRectangular,
            .accessoryCircular,
            .accessoryInline
        ])
    }
}

struct LockScreenEntry: TimelineEntry {
    let date: Date
    let clipsToday: Int
    let targetToday: Int
    let nextNudge: Date?
}

struct LockScreenProvider: TimelineProvider {
    func placeholder(in context: Context) -> LockScreenEntry {
        LockScreenEntry(date: Date(), clipsToday: 3, targetToday: 8, nextNudge: Date().addingTimeInterval(45 * 60))
    }

    func getSnapshot(in context: Context, completion: @escaping (LockScreenEntry) -> Void) {
        completion(currentEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<LockScreenEntry>) -> Void) {
        // Build 6 entries over the next hour so the widget refreshes the countdown
        var entries: [LockScreenEntry] = []
        let base = currentEntry()
        for i in 0..<6 {
            let date = Date().addingTimeInterval(TimeInterval(i * 10 * 60))
            entries.append(LockScreenEntry(
                date: date,
                clipsToday: base.clipsToday,
                targetToday: base.targetToday,
                nextNudge: base.nextNudge
            ))
        }
        completion(Timeline(entries: entries, policy: .atEnd))
    }

    private func currentEntry() -> LockScreenEntry {
        let defaults = UserDefaults(suiteName: AppConstants.appGroupID)
        let clips = defaults?.integer(forKey: "clipsToday") ?? 0
        let target = defaults?.integer(forKey: "targetToday") ?? 8
        var next: Date?
        if let ts = defaults?.object(forKey: "nextNudgeTimestamp") as? TimeInterval {
            next = Date(timeIntervalSince1970: ts)
        }
        return LockScreenEntry(
            date: Date(),
            clipsToday: clips,
            targetToday: target == 0 ? 8 : target,
            nextNudge: next
        )
    }
}

struct LockScreenEntryView: View {
    var entry: LockScreenEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .accessoryRectangular: rectangular
        case .accessoryCircular:    circular
        case .accessoryInline:      inline
        default: rectangular
        }
    }

    private var rectangular: some View {
        Link(destination: URL(string: "vlognudge://record")!) {
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Image(systemName: "video.circle.fill")
                    Text("\(entry.clipsToday)/\(entry.targetToday) clips")
                        .font(.headline)
                }
                if let next = entry.nextNudge {
                    Text("Next: \(next, style: .time)")
                        .font(.caption2)
                } else {
                    Text("Tap to record")
                        .font(.caption2)
                }
            }
        }
    }

    private var circular: some View {
        Link(destination: URL(string: "vlognudge://record")!) {
            Gauge(value: Double(entry.clipsToday), in: 0...Double(entry.targetToday)) {
                Image(systemName: "video.fill")
            } currentValueLabel: {
                Text("\(entry.clipsToday)")
            }
            .gaugeStyle(.accessoryCircular)
        }
    }

    private var inline: some View {
        if let next = entry.nextNudge {
            Text("Vlog \(entry.clipsToday)/\(entry.targetToday) — next \(next, style: .time)")
        } else {
            Text("Vlog \(entry.clipsToday)/\(entry.targetToday)")
        }
    }
}
