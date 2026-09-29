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
    @State private var recordTaps = 0

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
                    greeting
                    heroCard
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
            .navigationBarTitleDisplayMode(.inline)
            .refreshable {
                await refresh()
            }
            .task {
                await refresh()
            }
        }
    }

    // MARK: - Greeting

    private var greeting: some View {
        VStack(alignment: .leading, spacing: VNSpacing.xs) {
            Text(Date(), format: .dateTime.weekday(.wide).month().day())
                .font(VNFont.caption)
                .textCase(.uppercase)
                .foregroundStyle(VNColor.textTertiary)
            Text(greetingText)
                .font(VNFont.title)
                .foregroundStyle(VNColor.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var greetingText: String {
        switch Calendar.current.component(.hour, from: Date()) {
        case 5..<12: return "Morning. Roll camera."
        case 12..<17: return "Afternoon check-in."
        case 17..<22: return "Evening's still a story."
        default: return "Night owl mode."
        }
    }

    // MARK: - Hero Card (progress ring + next nudge)

    private var heroCard: some View {
        HStack(spacing: VNSpacing.xl) {
            ZStack {
                VNProgressRing(progress: progressFraction, lineWidth: 10)
                VStack(spacing: 0) {
                    Text("\(todayClips.count)")
                        .font(VNFont.heroNumber)
                        .contentTransition(.numericText())
                    Text("of \(target)")
                        .font(VNFont.caption)
                        .opacity(0.8)
                }
            }
            .frame(width: 104, height: 104)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("\(todayClips.count) of \(target) clips today")

            VStack(alignment: .leading, spacing: VNSpacing.xs) {
                Label("Next nudge", systemImage: "bell.badge.fill")
                    .font(VNFont.caption)
                    .textCase(.uppercase)
                    .opacity(0.8)

                if settings.frequency == .contextOnly {
                    Text("When the moment's right")
                        .font(VNFont.title3)
                } else if let next = nextNudgeDate {
                    Text(next, style: .time)
                        .font(VNFont.bigTime)
                        .contentTransition(.numericText())
                    Text(relativeText(for: next))
                        .font(VNFont.callout)
                        .opacity(0.85)
                } else {
                    Text("All done")
                        .font(VNFont.bigTime)
                    Text("No more nudges today")
                        .font(VNFont.callout)
                        .opacity(0.85)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .vnHeroCard()
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
            recordTaps += 1
            appState.requestCapture(prompt: nil)
        } label: {
            HStack(spacing: VNSpacing.md) {
                Circle()
                    .fill(.white)
                    .frame(width: 14, height: 14)
                    .overlay(Circle().stroke(.white.opacity(0.4), lineWidth: 6).scaleEffect(1.6))
                Text("Record now")
                    .font(VNFont.title3)
                Spacer()
                Image(systemName: "arrow.right")
                    .font(.headline)
            }
            .foregroundStyle(.white)
            .padding(.horizontal, VNSpacing.xxl)
            .padding(.vertical, VNSpacing.xl)
            .background(VNGradient.record, in: RoundedRectangle(cornerRadius: VNRadius.lg))
            .background(VNPulse(color: VNColor.flagRed))
            .shadow(color: VNColor.flagRed.opacity(0.35), radius: 14, y: 8)
        }
        .buttonStyle(.vnPressable)
        .sensoryFeedback(.impact(weight: .medium), trigger: recordTaps)
        .accessibilityLabel("Record a clip now")
    }

    // MARK: - Capture Idea Button

    private var ideaButton: some View {
        Button {
            appState.deepLink = .ideaMemo
        } label: {
            HStack(spacing: VNSpacing.sm) {
                Image(systemName: "lightbulb.fill")
                    .foregroundStyle(VNColor.highlight)
                Text("Add a video idea")
                    .font(VNFont.subheadline)
                    .foregroundStyle(VNColor.textPrimary)
                Spacer()
                Image(systemName: "plus")
                    .foregroundStyle(VNColor.textTertiary)
            }
            .padding(.horizontal, VNSpacing.lg)
            .padding(.vertical, VNSpacing.lg)
            .vnCard(padding: 0, cornerRadius: VNRadius.md)
        }
        .buttonStyle(.vnPressable)
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

        nextNudgeDate = ScreenshotMode.isActive ? ScreenshotMode.sampleNextNudge : vlogNudges.first

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

