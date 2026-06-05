//
//  TodayView.swift
//  VlogNudge
//
//  6:3:1 — Dominant bg, Secondary cards, Accent progress & CTAs.
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
        if settings.customScheduleEnabled {
            return max(1, settings.customTimesForToday.count)
        }
        return settings.frequency.baselineCountPerDay == 0
            ? 8
            : settings.frequency.baselineCountPerDay
    }

    private var progressFraction: Double {
        Double(todayClips.count) / Double(max(1, target))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: VNSpacing.xxl) {
                    nextNudgeCard
                    progressCard
                    clipsStrip
                    recordButton
                    ideaButton
                    lastClipFooter
                }
                .padding(.horizontal, VNSpacing.lg)
                .padding(.top, VNSpacing.sm)
                .padding(.bottom, VNSpacing.huge)
            }
            .background(VNColor.dominant)
            .navigationTitle("Today")
            .refreshable {
                await refresh()
            }
            .task {
                await refresh()
            }
        }
    }

    // MARK: - Next Nudge Card

    private var nextNudgeCard: some View {
        VStack(spacing: VNSpacing.sm) {
            Text("Next nudge")
                .font(VNFont.caption)
                .foregroundStyle(VNColor.textTertiary)
                .frame(maxWidth: .infinity, alignment: .leading)

            if settings.frequency == .contextOnly {
                Text("Whenever something happens")
                    .font(VNFont.title2)
                    .foregroundStyle(VNColor.textPrimary)
            } else if let next = nextNudgeDate {
                Text(next, style: .time)
                    .font(VNFont.bigTime)
                    .foregroundStyle(VNColor.accent)
                    .contentTransition(.numericText())
                Text(relativeText(for: next))
                    .font(VNFont.callout)
                    .foregroundStyle(VNColor.textSecondary)
            } else {
                Text("—")
                    .font(VNFont.bigTime)
                    .foregroundStyle(VNColor.textTertiary)
                Text("No more nudges scheduled today")
                    .font(VNFont.callout)
                    .foregroundStyle(VNColor.textSecondary)
            }
        }
        .frame(maxWidth: .infinity)
        .vnCard()
    }

    // MARK: - Progress Card (capsule bar)

    private var progressCard: some View {
        VStack(alignment: .leading, spacing: VNSpacing.md) {
            HStack {
                Text("\(todayClips.count) of \(target) clips")
                    .font(VNFont.headline)
                    .foregroundStyle(VNColor.textPrimary)
                Spacer()
                Text("\(Int(progressFraction * 100))%")
                    .font(VNFont.subheadline)
                    .foregroundStyle(VNColor.accent)
            }

            HStack(spacing: 6) {
                ForEach(0..<target, id: \.self) { index in
                    Capsule()
                        .fill(index < todayClips.count ? VNColor.accent : VNColor.textTertiary.opacity(0.2))
                        .frame(height: 8)
                        .animation(.easeInOut(duration: 0.3).delay(Double(index) * 0.05), value: todayClips.count)
                }
            }
        }
        .vnCard()
    }

    // MARK: - Today's Clips Strip

    private var clipsStrip: some View {
        VStack(alignment: .leading, spacing: VNSpacing.sm) {
            if !todayClips.isEmpty {
                Text("Today's clips")
                    .font(VNFont.caption)
                    .foregroundStyle(VNColor.textTertiary)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: VNSpacing.md) {
                        ForEach(todayClips) { clip in
                            ClipThumb(clip: clip)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Record Button (accent CTA)

    private var recordButton: some View {
        Button {
            appState.requestCapture(prompt: nil)
        } label: {
            HStack(spacing: VNSpacing.sm) {
                Image(systemName: "video.circle.fill")
                    .font(.title2)
                Text("Record now")
                    .font(VNFont.title3)
            }
            .foregroundStyle(VNColor.dominant)
            .frame(maxWidth: .infinity)
            .padding(.vertical, VNSpacing.xl)
            .background(VNColor.accent, in: RoundedRectangle(cornerRadius: VNRadius.lg))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Record a clip now")
    }

    // MARK: - Capture Idea Button

    private var ideaButton: some View {
        Button {
            appState.deepLink = .ideaMemo
        } label: {
            HStack(spacing: VNSpacing.sm) {
                Image(systemName: "lightbulb.fill")
                    .foregroundStyle(VNColor.accent)
                Text("Add a video idea")
                    .font(VNFont.subheadline)
                    .foregroundStyle(VNColor.textPrimary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, VNSpacing.lg)
            .background(VNColor.secondary, in: RoundedRectangle(cornerRadius: VNRadius.md))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Last Clip Footer

    @ViewBuilder
    private var lastClipFooter: some View {
        if let last = todayClips.first {
            Text("Last clip: \(last.recordedAt, style: .time) · \(DateHelpers.minutesAgo(from: last.recordedAt))m ago")
                .font(VNFont.caption)
                .foregroundStyle(VNColor.textTertiary)
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
        let center = UNUserNotificationCenter.current()
        let pending = await center.pendingNotificationRequests()

        let vlogNudges = pending
            .filter { $0.content.categoryIdentifier == AppConstants.notificationCategoryID }
            .compactMap { req -> Date? in
                (req.trigger as? UNCalendarNotificationTrigger)?.nextTriggerDate()
            }
            .sorted()

        nextNudgeDate = vlogNudges.first

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

// MARK: - Clip Thumbnail (themed)

struct ClipThumb: View {
    let clip: Clip

    var body: some View {
        VStack(alignment: .leading, spacing: VNSpacing.xs) {
            RoundedRectangle(cornerRadius: VNRadius.md)
                .fill(VNColor.secondaryLight)
                .frame(width: 100, height: 140)
                .overlay(
                    Image(systemName: "video.fill")
                        .font(.title)
                        .foregroundStyle(VNColor.textTertiary)
                )
                .overlay(alignment: .topTrailing) {
                    if clip.starred {
                        Image(systemName: "star.fill")
                            .font(.caption)
                            .foregroundStyle(VNColor.warning)
                            .padding(VNSpacing.xs)
                    }
                }
            Text(clip.recordedAt, style: .time)
                .font(VNFont.caption)
                .foregroundStyle(VNColor.textPrimary)
            Text("\(Int(clip.duration))s")
                .font(VNFont.caption2)
                .foregroundStyle(VNColor.textTertiary)
        }
    }
}
