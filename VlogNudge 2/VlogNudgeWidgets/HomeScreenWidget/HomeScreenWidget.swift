//
//  HomeScreenWidget.swift
//  VlogNudgeWidgets
//

import SwiftUI
import WidgetKit
import AppIntents

struct HomeScreenWidget: Widget {
    let kind = "HomeScreenWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: HomeProvider()) { entry in
            HomeEntryView(entry: entry)
                .containerBackground(for: .widget) {
                    LinearGradient(
                        colors: [.black, Color(white: 0.1)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                }
        }
        .configurationDisplayName("VlogNudge — Home")
        .description("Today's progress at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

struct HomeEntry: TimelineEntry {
    let date: Date
    let clipsToday: Int
    let targetToday: Int
    let nextNudge: Date?
    let lastClipTime: Date?
}

struct HomeProvider: TimelineProvider {
    func placeholder(in context: Context) -> HomeEntry {
        HomeEntry(
            date: Date(),
            clipsToday: 3,
            targetToday: 8,
            nextNudge: Date().addingTimeInterval(45 * 60),
            lastClipTime: Date().addingTimeInterval(-90 * 60)
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (HomeEntry) -> Void) {
        completion(current())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<HomeEntry>) -> Void) {
        var entries: [HomeEntry] = []
        let base = current()
        for i in 0..<6 {
            let date = Date().addingTimeInterval(TimeInterval(i * 10 * 60))
            entries.append(HomeEntry(
                date: date,
                clipsToday: base.clipsToday,
                targetToday: base.targetToday,
                nextNudge: base.nextNudge,
                lastClipTime: base.lastClipTime
            ))
        }
        completion(Timeline(entries: entries, policy: .atEnd))
    }

    private func current() -> HomeEntry {
        let defaults = UserDefaults(suiteName: AppConstants.appGroupID)
        let clips = defaults?.integer(forKey: "clipsToday") ?? 0
        let target = defaults?.integer(forKey: "targetToday") ?? 8
        var next: Date?
        var last: Date?
        if let ts = defaults?.object(forKey: "nextNudgeTimestamp") as? TimeInterval {
            next = Date(timeIntervalSince1970: ts)
        }
        if let ts = defaults?.object(forKey: "lastClipTimestamp") as? TimeInterval {
            last = Date(timeIntervalSince1970: ts)
        }
        return HomeEntry(
            date: Date(),
            clipsToday: clips,
            targetToday: target == 0 ? 8 : target,
            nextNudge: next,
            lastClipTime: last
        )
    }
}

struct HomeEntryView: View {
    var entry: HomeEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:  smallView
        case .systemMedium: mediumView
        case .systemLarge:  largeView
        default: smallView
        }
    }

    private var progressColor: Color {
        let pct = Double(entry.clipsToday) / Double(max(1, entry.targetToday))
        if pct >= 0.8 { return .green }
        if pct >= 0.5 { return .yellow }
        return .orange
    }

    // MARK: - Small

    private var smallView: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: "video.circle.fill")
                    .foregroundStyle(.red)
                Spacer()
                Text("\(entry.clipsToday)/\(entry.targetToday)")
                    .font(.title2.bold())
                    .foregroundStyle(progressColor)
            }

            Spacer()

            if let next = entry.nextNudge {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Next")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.6))
                    Text(next, style: .time)
                        .font(.headline)
                        .foregroundStyle(.white)
                }
            }

            Button(intent: RecordClipIntent()) {
                HStack(spacing: 4) {
                    Image(systemName: "record.circle.fill")
                    Text("Record")
                        .font(.caption.bold())
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(.red, in: Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(12)
    }

    // MARK: - Medium

    private var mediumView: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("\(entry.clipsToday)")
                    .font(.system(size: 56, weight: .bold, design: .rounded))
                    .foregroundStyle(progressColor)
                Text("of \(entry.targetToday) today")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.7))
            }

            Divider().background(.white.opacity(0.3))

            VStack(alignment: .leading, spacing: 8) {
                if let next = entry.nextNudge {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Next nudge")
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.6))
                        Text(next, style: .time)
                            .font(.headline)
                            .foregroundStyle(.white)
                    }
                }
                if let last = entry.lastClipTime {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Last clip")
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.6))
                        Text(last, style: .relative)
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.9))
                    }
                }
                Spacer()
                Button(intent: RecordClipIntent()) {
                    HStack {
                        Image(systemName: "record.circle.fill")
                        Text("Record").font(.subheadline.bold())
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(.red, in: Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16)
    }

    // MARK: - Large

    private var largeView: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(entry.clipsToday) of \(entry.targetToday)")
                        .font(.title.bold())
                        .foregroundStyle(.white)
                    Text("clips today")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.6))
                }
                Spacer()
                if let next = entry.nextNudge {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Next")
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.6))
                        Text(next, style: .time)
                            .font(.title3.bold())
                            .foregroundStyle(progressColor)
                    }
                }
            }

            HStack(spacing: 6) {
                ForEach(0..<entry.targetToday, id: \.self) { i in
                    Capsule()
                        .fill(i < entry.clipsToday
                              ? progressColor
                              : Color.white.opacity(0.15))
                        .frame(height: 10)
                }
            }

            if let last = entry.lastClipTime {
                HStack {
                    Image(systemName: "clock")
                    Text("Last clip \(last, style: .relative) ago")
                }
                .font(.caption)
                .foregroundStyle(.white.opacity(0.6))
            }

            Spacer()

            HStack(spacing: 10) {
                Button(intent: RecordClipIntent()) {
                    HStack {
                        Image(systemName: "record.circle.fill")
                        Text("Record").font(.headline)
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(.red, in: RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)

                Button(intent: CaptureIdeaIntent()) {
                    HStack {
                        Image(systemName: "lightbulb.fill")
                        Text("Idea").font(.headline)
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(.blue.opacity(0.8), in: RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16)
    }
}
