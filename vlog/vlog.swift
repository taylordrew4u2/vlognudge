//
//  vlog.swift
//  vlog
//
//  Home screen widget: small, medium, and large sizes.
//  Reads clip progress and next nudge time from App Group UserDefaults.
//

import WidgetKit
import SwiftUI

// Widget-local palette — keep in sync with VNColor in DesignTokens.swift
private enum WidgetColor {
    static let accent = Color(red: 239/255, green: 83/255, blue: 80/255)       // Coral Red #EF5350
    static let secondaryAction = Color(red: 33/255, green: 40/255, blue: 56/255).opacity(0.85)  // #212838
}

// MARK: - Timeline Entry

struct VlogNudgeEntry: TimelineEntry {
    let date: Date
    let clipsToday: Int
    let targetToday: Int
    let nextNudgeDate: Date?
    let lastClipDate: Date?

    var progressFraction: Double {
        guard targetToday > 0 else { return 0 }
        return min(1.0, Double(clipsToday) / Double(targetToday))
    }

    var paceColor: Color {
        if progressFraction >= 0.75 { return .green }
        if progressFraction >= 0.4 { return .yellow }
        return .orange
    }

    static let placeholder = VlogNudgeEntry(
        date: .now,
        clipsToday: 3,
        targetToday: 6,
        nextNudgeDate: Date().addingTimeInterval(1380),
        lastClipDate: Date().addingTimeInterval(-1800)
    )
}

// MARK: - Timeline Provider

struct VlogNudgeProvider: TimelineProvider {
    func placeholder(in context: Context) -> VlogNudgeEntry {
        .placeholder
    }

    func getSnapshot(in context: Context, completion: @escaping (VlogNudgeEntry) -> Void) {
        completion(readEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<VlogNudgeEntry>) -> Void) {
        let entry = readEntry()
        var entries = [entry]

        // Add an entry at the next nudge time so the display refreshes
        if let nextNudge = entry.nextNudgeDate, nextNudge > .now {
            entries.append(VlogNudgeEntry(
                date: nextNudge,
                clipsToday: entry.clipsToday,
                targetToday: entry.targetToday,
                nextNudgeDate: nil,
                lastClipDate: entry.lastClipDate
            ))
        }

        completion(Timeline(entries: entries, policy: .atEnd))
    }

    private func readEntry() -> VlogNudgeEntry {
        let defaults = UserDefaults(suiteName: AppConstants.appGroupID)
        let clips = defaults?.integer(forKey: "clipsToday") ?? 0
        let target = defaults?.integer(forKey: "targetToday") ?? 6

        let nextNudge: Date? = {
            guard let ts = defaults?.object(forKey: "nextNudgeTimestamp") as? Double, ts > 0 else { return nil }
            let date = Date(timeIntervalSince1970: ts)
            return date > .now ? date : nil
        }()

        let lastClip: Date? = {
            guard let ts = defaults?.object(forKey: "lastClipTimestamp") as? Double, ts > 0 else { return nil }
            return Date(timeIntervalSince1970: ts)
        }()

        return VlogNudgeEntry(
            date: .now,
            clipsToday: clips,
            targetToday: target,
            nextNudgeDate: nextNudge,
            lastClipDate: lastClip
        )
    }
}

// MARK: - Shared Components

struct ProgressCapsule: View {
    let progress: Double
    let color: Color
    var height: CGFloat = 6

    var body: some View {
        GeometryReader { geo in
            Capsule()
                .fill(Color.secondary.opacity(0.2))
                .overlay(alignment: .leading) {
                    Capsule()
                        .fill(color)
                        .frame(width: max(geo.size.height, geo.size.width * progress))
                }
                .clipShape(Capsule())
        }
        .frame(height: height)
    }
}

private struct ClipCountView: View {
    let clips: Int
    let target: Int
    let size: CGFloat

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 1) {
            Text("\(clips)")
                .font(.system(size: size, weight: .heavy, design: .rounded))
            Text("/\(target)")
                .font(.system(size: size * 0.5, weight: .bold, design: .rounded))
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Small Widget

private struct SmallWidgetView: View {
    let entry: VlogNudgeEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("TODAY")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)

            ClipCountView(clips: entry.clipsToday, target: entry.targetToday, size: 40)

            Text("clips")
                .font(.caption)
                .foregroundStyle(.secondary)

            ProgressCapsule(progress: entry.progressFraction, color: entry.paceColor)

            Spacer(minLength: 0)

            if let next = entry.nextNudgeDate {
                HStack(spacing: 4) {
                    Image(systemName: "bell.fill")
                        .font(.caption2)
                        .foregroundStyle(entry.paceColor)
                    Text(next, style: .time)
                        .font(.caption2.weight(.medium))
                }
            } else {
                Text("No more nudges")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Medium Widget

private struct MediumWidgetView: View {
    let entry: VlogNudgeEntry

    var body: some View {
        HStack(spacing: 16) {
            // Left column: progress info
            VStack(alignment: .leading, spacing: 8) {
                Text("TODAY")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)

                ClipCountView(clips: entry.clipsToday, target: entry.targetToday, size: 48)

                Text("clips")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                ProgressCapsule(progress: entry.progressFraction, color: entry.paceColor)

                Spacer(minLength: 0)

                if let next = entry.nextNudgeDate {
                    HStack(spacing: 4) {
                        Image(systemName: "bell.fill")
                            .font(.caption2)
                            .foregroundStyle(entry.paceColor)
                        Text("Next")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text(next, style: .time)
                            .font(.caption2.weight(.medium))
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Right column: action buttons
            VStack(spacing: 10) {
                Spacer(minLength: 0)

                Link(destination: URL(string: "vlognudge://record")!) {
                    Label("Record", systemImage: "video.circle.fill")
                        .frame(maxWidth: .infinity)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.vertical, 8)
                        .background(WidgetColor.accent, in: RoundedRectangle(cornerRadius: 8))
                }

                Link(destination: URL(string: "vlognudge://idea")!) {
                    Label("Idea", systemImage: "lightbulb.fill")
                        .frame(maxWidth: .infinity)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.vertical, 8)
                        .background(WidgetColor.secondaryAction, in: RoundedRectangle(cornerRadius: 8))
                }
            }
            .frame(width: 120)
        }
    }
}

// MARK: - Large Widget

private struct LargeWidgetView: View {
    let entry: VlogNudgeEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("TODAY")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                Text("VlogNudge")
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.tertiary)
            }

            ClipCountView(clips: entry.clipsToday, target: entry.targetToday, size: 56)

            Text("clips")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            ProgressCapsule(progress: entry.progressFraction, color: entry.paceColor, height: 8)
                .padding(.top, 4)

            Spacer(minLength: 8)

            // Next nudge info
            if let next = entry.nextNudgeDate {
                HStack(spacing: 6) {
                    Image(systemName: "bell.fill")
                        .font(.caption)
                        .foregroundStyle(entry.paceColor)
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 4) {
                            Text("Next nudge")
                                .foregroundStyle(.secondary)
                            Text(next, style: .time)
                                .fontWeight(.medium)
                        }
                        Text(next, style: .relative)
                            .foregroundStyle(.secondary)
                    }
                    .font(.caption)
                }
            }

            // Last clip info
            if let last = entry.lastClipDate {
                HStack(spacing: 6) {
                    Image(systemName: "video.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 4) {
                            Text("Last clip")
                                .foregroundStyle(.secondary)
                            Text(last, style: .time)
                                .fontWeight(.medium)
                        }
                        Text(last, style: .relative)
                            .foregroundStyle(.secondary)
                    }
                    .font(.caption)
                }
            }

            Spacer(minLength: 8)

            // Action buttons
            HStack(spacing: 10) {
                Link(destination: URL(string: "vlognudge://record")!) {
                    Label("Record", systemImage: "video.circle.fill")
                        .frame(maxWidth: .infinity)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.vertical, 10)
                        .background(WidgetColor.accent, in: RoundedRectangle(cornerRadius: 8))
                }

                Link(destination: URL(string: "vlognudge://idea")!) {
                    Label("Idea", systemImage: "lightbulb.fill")
                        .frame(maxWidth: .infinity)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.vertical, 10)
                        .background(WidgetColor.secondaryAction, in: RoundedRectangle(cornerRadius: 8))
                }
            }
        }
    }
}

// MARK: - Entry View

struct VlogNudgeWidgetEntryView: View {
    var entry: VlogNudgeEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(entry: entry)
        case .systemMedium:
            MediumWidgetView(entry: entry)
        case .systemLarge:
            LargeWidgetView(entry: entry)
        default:
            SmallWidgetView(entry: entry)
        }
    }
}

// MARK: - Widget Definition

struct VlogNudgeWidget: Widget {
    let kind: String = "VlogNudgeWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: VlogNudgeProvider()) { entry in
            VlogNudgeWidgetEntryView(entry: entry)
                .widgetURL(URL(string: "vlognudge://record"))
                .containerBackground(for: .widget) {
                    Color(.systemBackground)
                }
        }
        .configurationDisplayName("VlogNudge")
        .description("Track your daily vlog progress and next nudge.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

// MARK: - Previews

#Preview(as: .systemSmall) {
    VlogNudgeWidget()
} timeline: {
    VlogNudgeEntry.placeholder
    VlogNudgeEntry(date: .now, clipsToday: 5, targetToday: 6, nextNudgeDate: nil, lastClipDate: .now)
}

#Preview(as: .systemMedium) {
    VlogNudgeWidget()
} timeline: {
    VlogNudgeEntry.placeholder
}

#Preview(as: .systemLarge) {
    VlogNudgeWidget()
} timeline: {
    VlogNudgeEntry.placeholder
}
