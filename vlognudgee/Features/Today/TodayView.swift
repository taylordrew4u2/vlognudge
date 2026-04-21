//
//  TodayView.swift
//  VlogNudge
//

import SwiftUI
import SwiftData
import UserNotifications

struct TodayView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState

    @Query(sort: \Clip.recordedAt, order: .reverse) private var allClips: [Clip]
    @Query private var settingsArray: [UserSettings]

    @State private var nextNudgeDate: Date?
    @State private var refreshTick = 0

    private var settings: UserSettings {
        settingsArray.first ?? UserSettings()
    }

    private var todayClips: [Clip] {
        let today = DateHelpers.dayKey(from: Date())
        return allClips.filter { $0.dayKey == today }
    }

    private var target: Int {
        settings.frequency.baselineCountPerDay == 0
            ? 8  // show something reasonable in context-only mode
            : settings.frequency.baselineCountPerDay
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    nextNudgeCard
                    progressCard
                    clipsStrip
                    recordButton
                    ideaButton
                    lastClipFooter
                }
                .padding(.horizontal)
                .padding(.bottom, 40)
            }
            .navigationTitle("Today")
            .refreshable {
                await refresh()
            }
            .task {
                await refresh()
            }
        }
    }

    // MARK: - Cards

    private var nextNudgeCard: some View {
        VStack(spacing: 8) {
            Text("Next nudge")
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            if settings.frequency == .contextOnly {
                Text("Whenever something happens")
                    .font(.title2.bold())
            } else if let next = nextNudgeDate {
                Text(next, style: .time)
                    .font(.system(size: 44, weight: .bold, design: .rounded))
                    .contentTransition(.numericText())
                Text(relativeText(for: next))
                    .font(.callout)
                    .foregroundStyle(.secondary)
            } else {
                Text("—")
                    .font(.system(size: 44, weight: .bold, design: .rounded))
                Text("No more nudges scheduled today")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    private var progressCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("\(todayClips.count) of \(target) clips")
                    .font(.headline)
                Spacer()
                Text("\(Int(Double(todayClips.count) / Double(max(1, target)) * 100))%")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 6) {
                ForEach(0..<target, id: \.self) { index in
                    Capsule()
                        .fill(index < todayClips.count ? Color.accentColor : Color.secondary.opacity(0.2))
                        .frame(height: 8)
                }
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    private var clipsStrip: some View {
        VStack(alignment: .leading, spacing: 8) {
            if !todayClips.isEmpty {
                Text("Today's clips")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(todayClips) { clip in
                            ClipThumb(clip: clip)
                        }
                    }
                }
            }
        }
    }

    private var recordButton: some View {
        Button {
            appState.requestCapture(prompt: nil)
        } label: {
            HStack {
                Image(systemName: "video.circle.fill")
                    .font(.title2)
                Text("Record now")
                    .font(.title3.bold())
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(Color.red, in: RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }

    private var ideaButton: some View {
        Button {
            appState.deepLink = .ideaMemo
        } label: {
            HStack {
                Image(systemName: "lightbulb.fill")
                Text("Capture idea")
            }
            .font(.subheadline.bold())
            .foregroundStyle(.primary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var lastClipFooter: some View {
        if let last = todayClips.first {
            Text("Last clip: \(last.recordedAt, style: .time) · \(DateHelpers.minutesAgo(from: last.recordedAt))m ago")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Helpers

    private func relativeText(for date: Date) -> String {
        let minutes = Int(date.timeIntervalSinceNow / 60)
        if minutes < 1 {
            return "any moment now"
        } else if minutes < 60 {
            return "in \(minutes) min"
        } else {
            let h = minutes / 60
            let m = minutes % 60
            return "in \(h)h \(m)m"
        }
    }

    private func refresh() async {
        // Ask scheduler for next pending, stash in app group for widget
        let center = UNUserNotificationCenter.current()
        let pending = await center.pendingNotificationRequests()

        let vlogNudges = pending
            .filter { $0.content.categoryIdentifier == AppConstants.notificationCategoryID }
            .compactMap { req -> Date? in
                (req.trigger as? UNCalendarNotificationTrigger)?.nextTriggerDate()
            }
            .sorted()

        nextNudgeDate = vlogNudges.first

        // Share to widget via App Group
        let defaults = UserDefaults(suiteName: AppConstants.appGroupID)
        defaults?.set(todayClips.count, forKey: "clipsToday")
        defaults?.set(target, forKey: "targetToday")
        if let next = nextNudgeDate {
            defaults?.set(next.timeIntervalSince1970, forKey: "nextNudgeTimestamp")
        } else {
            defaults?.removeObject(forKey: "nextNudgeTimestamp")
        }
    }
}

// MARK: - Thumb

struct ClipThumb: View {
    let clip: Clip

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.secondary.opacity(0.2))
                .frame(width: 100, height: 140)
                .overlay(
                    Image(systemName: "video.fill")
                        .font(.title)
                        .foregroundStyle(.secondary)
                )
                .overlay(alignment: .topTrailing) {
                    if clip.starred {
                        Image(systemName: "star.fill")
                            .font(.caption)
                            .foregroundStyle(.yellow)
                            .padding(4)
                    }
                }
            Text(clip.recordedAt, style: .time)
                .font(.caption2.bold())
            Text("\(Int(clip.duration))s")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}
