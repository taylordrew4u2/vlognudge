//
//  NudgeAnalyticsView.swift
//  VlogNudge
//
//  "What's working for me" — conversion rate by trigger type.
//  No ML, just honest reporting on which nudges you act on.
//

import SwiftUI
import SwiftData
import Charts

struct NudgeAnalyticsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \NudgeEvent.scheduledFor, order: .reverse) private var allEvents: [NudgeEvent]
    @Query(sort: \Clip.recordedAt, order: .reverse) private var allClips: [Clip]

    @State private var range: TimeRange = .week

    enum TimeRange: String, CaseIterable {
        case week = "7 days"
        case month = "30 days"
        case all = "All time"

        var cutoff: Date {
            switch self {
            case .week: return Date().addingTimeInterval(-7 * 24 * 3600)
            case .month: return Date().addingTimeInterval(-30 * 24 * 3600)
            case .all: return .distantPast
            }
        }
    }

    private var filteredEvents: [NudgeEvent] {
        allEvents.filter { $0.scheduledFor >= range.cutoff }
    }

    private var filteredClips: [Clip] {
        allClips.filter { $0.recordedAt >= range.cutoff }
    }

    var body: some View {
        List {
            Section {
                Picker("Range", selection: $range) {
                    ForEach(TimeRange.allCases, id: \.self) { r in
                        Text(r.rawValue).tag(r)
                    }
                }
                .pickerStyle(.segmented)
            }

            Section("Summary") {
                LabeledContent("Nudges fired") {
                    Text("\(firedCount)")
                        .foregroundStyle(.secondary)
                }
                LabeledContent("Clips filmed") {
                    Text("\(filteredClips.count)")
                        .foregroundStyle(.secondary)
                }
                LabeledContent("Dismissed") {
                    Text("\(dismissedCount)")
                        .foregroundStyle(.secondary)
                }
                LabeledContent("Overall conversion") {
                    Text("\(overallConversion)%")
                        .foregroundStyle(conversionColor)
                        .bold()
                }
            }

            if !triggerStats.isEmpty {
                Section("Conversion by trigger") {
                    Chart(triggerStats) { stat in
                        BarMark(
                            x: .value("Trigger", stat.displayName),
                            y: .value("Conversion %", stat.conversionPct)
                        )
                        .foregroundStyle(stat.color)
                        .annotation(position: .top) {
                            Text("\(Int(stat.conversionPct))%")
                                .font(.caption2)
                        }
                    }
                    .frame(height: 220)

                    ForEach(triggerStats) { stat in
                        HStack {
                            Text(stat.displayName)
                            Spacer()
                            Text("\(stat.filmed)/\(stat.total)")
                                .foregroundStyle(.secondary)
                            Text("\(Int(stat.conversionPct))%")
                                .bold()
                                .foregroundStyle(stat.color)
                                .frame(width: 60, alignment: .trailing)
                        }
                        .font(.caption)
                    }
                }
            }

            Section("Clips per day") {
                Chart(clipsPerDay) { day in
                    BarMark(
                        x: .value("Day", day.date, unit: .day),
                        y: .value("Clips", day.count)
                    )
                    .foregroundStyle(.blue)
                }
                .frame(height: 160)
            }
        }
        .navigationTitle("Analytics")
    }

    // MARK: - Computations

    private var firedCount: Int {
        filteredEvents.filter { $0.firedAt != nil }.count
    }

    private var dismissedCount: Int {
        filteredEvents.filter { $0.dismissedAt != nil }.count
    }

    private var overallConversion: Int {
        guard firedCount > 0 else { return 0 }
        // A nudge "converted" if a clip was filmed within 10 min of it firing
        let converted = filteredEvents.filter { event in
            guard let fired = event.firedAt else { return false }
            return filteredClips.contains { clip in
                clip.recordedAt >= fired &&
                    clip.recordedAt <= fired.addingTimeInterval(10 * 60)
            }
        }.count
        return Int(Double(converted) / Double(firedCount) * 100)
    }

    private var conversionColor: Color {
        switch overallConversion {
        case 0..<20:  return .red
        case 20..<50: return .orange
        case 50..<75: return .yellow
        default:      return .green
        }
    }

    struct TriggerStat: Identifiable {
        let id = UUID()
        let triggerReason: String
        let filmed: Int
        let total: Int

        var conversionPct: Double {
            guard total > 0 else { return 0 }
            return Double(filmed) / Double(total) * 100
        }

        var displayName: String {
            let name = triggerReason
                .replacingOccurrences(of: "_", with: " ")
                .replacingOccurrences(of: ":", with: " ")
            return name.prefix(24).capitalized
        }

        var color: Color {
            switch conversionPct {
            case 0..<20:  return .red
            case 20..<50: return .orange
            case 50..<75: return .yellow
            default:      return .green
            }
        }
    }

    private var triggerStats: [TriggerStat] {
        let fired = filteredEvents.filter { $0.firedAt != nil }
        // Group by root trigger type (strip the ":details" part)
        let grouped = Dictionary(grouping: fired) { event in
            event.triggerReason.components(separatedBy: ":").first ?? event.triggerReason
        }

        return grouped.map { (reason, events) in
            let filmed = events.filter { event in
                guard let firedAt = event.firedAt else { return false }
                return filteredClips.contains { clip in
                    clip.recordedAt >= firedAt &&
                        clip.recordedAt <= firedAt.addingTimeInterval(10 * 60)
                }
            }.count
            return TriggerStat(triggerReason: reason, filmed: filmed, total: events.count)
        }
        .sorted { $0.total > $1.total }
    }

    struct DayCount: Identifiable {
        let id = UUID()
        let date: Date
        let count: Int
    }

    private var clipsPerDay: [DayCount] {
        let grouped = Dictionary(grouping: filteredClips) { $0.dayKey }
        let calendar = Calendar.current
        return grouped.compactMap { (key, clips) in
            guard let date = DateHelpers.dayKeyFormatter.date(from: key) else { return nil }
            return DayCount(date: calendar.startOfDay(for: date), count: clips.count)
        }
        .sorted { $0.date < $1.date }
    }
}
