//
//  StandByWidget.swift
//  VlogNudgeWidgets
//
//  Shows when the phone is docked sideways on a charger.
//  Big, glanceable, optimized for across-the-room legibility.
//

import SwiftUI
import WidgetKit
import AppIntents

struct StandByWidget: Widget {
    let kind = "StandByWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: HomeProvider()) { entry in
            StandByEntryView(entry: entry)
                .containerBackground(for: .widget) {
                    Color.black
                }
        }
        .configurationDisplayName("VlogNudge — StandBy")
        .description("Across-the-room display when your phone is docked sideways.")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}

struct StandByEntryView: View {
    var entry: HomeEntry

    private var pct: Double {
        Double(entry.clipsToday) / Double(max(1, entry.targetToday))
    }

    private var tint: Color {
        if pct >= 0.8 { return .green }
        if pct >= 0.5 { return .yellow }
        return .orange
    }

    var body: some View {
        ZStack {
            // Big clip count, designed to be legible from across the room
            VStack(spacing: 8) {
                Text("\(entry.clipsToday)")
                    .font(.system(size: 160, weight: .black, design: .rounded))
                    .foregroundStyle(tint)
                    .contentTransition(.numericText())
                    .minimumScaleFactor(0.5)

                Text("of \(entry.targetToday) clips")
                    .font(.title3)
                    .foregroundStyle(.white.opacity(0.6))

                if let next = entry.nextNudge {
                    HStack(spacing: 6) {
                        Image(systemName: "bell.fill")
                            .font(.caption)
                        Text("Next nudge \(next, style: .time)")
                            .font(.title3.bold())
                    }
                    .foregroundStyle(.white)
                    .padding(.top, 12)
                }
            }
        }
    }
}
