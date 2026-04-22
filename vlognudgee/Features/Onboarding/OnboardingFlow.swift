//
//  OnboardingFlow.swift
//  VlogNudge
//

import SwiftUI
import SwiftData
import UserNotifications
import AVFoundation
import Photos
import CoreMotion
import CoreLocation
import EventKit
import HealthKit

struct OnboardingFlow: View {
    @Environment(\.modelContext) private var modelContext
    @State private var step: Int = 0
    @AppStorage("hasCompletedOnboarding", store: UserDefaults(suiteName: AppConstants.appGroupID))
    private var hasCompletedOnboarding: Bool = false

    private let steps = 11

    var body: some View {
        VStack {
            ProgressView(value: Double(step + 1), total: Double(steps))
                .padding()

            Group {
                switch step {
                case 0:  valueProp
                case 1:  windowStep
                case 2:  frequencyStep
                case 3:  permissionStep(title: "Camera + Mic",
                                        body: "So you can film clips right in the app.",
                                        icon: "video.circle.fill",
                                        action: requestCameraAndMic,
                                        required: true)
                case 4:  permissionStep(title: "Photos",
                                        body: "Clips save to a Daily Vlogs album for CapCut.",
                                        icon: "photo.on.rectangle",
                                        action: requestPhotos,
                                        required: true)
                case 5:  permissionStep(title: "Notifications",
                                        body: "How nudges reach you. You control frequency.",
                                        icon: "bell.fill",
                                        action: requestNotifications,
                                        required: true)
                case 6:  permissionStep(title: "Motion",
                                        body: "So we don't nudge while you're driving, and we know when you've just arrived somewhere.",
                                        icon: "figure.walk",
                                        action: requestMotion,
                                        required: false)
                case 7:  permissionStep(title: "Location",
                                        body: "For geofence nudges like 'just got home' or 'arrived at Secret Pour'.",
                                        icon: "location.fill",
                                        action: requestLocation,
                                        required: false)
                case 8:  permissionStep(title: "Calendar",
                                        body: "We'll skip nudges during your events and film after they end.",
                                        icon: "calendar",
                                        action: requestCalendar,
                                        required: false)
                case 9:  permissionStep(title: "Health",
                                        body: "Post-workout is a great nudge moment.",
                                        icon: "heart.fill",
                                        action: requestHealth,
                                        required: false)
                case 10: addWidgetStep
                default: finalStep
                }
            }
            .frame(maxHeight: .infinity)

            bottomButtons
                .padding()
        }
    }

    // MARK: - Steps

    private var valueProp: some View {
        VStack(spacing: 24) {
            Image(systemName: "video.fill")
                .font(.system(size: 80))
                .foregroundStyle(.red)
            Text("VlogNudge")
                .font(.largeTitle.bold())
            Text("Film a day-in-the-life without remembering to. The app watches context and nudges when it's actually a good moment.")
                .font(.title3)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal)
        }
        .padding()
    }

    private var windowStep: some View {
        let settings = fetchSettings()
        return VStack(spacing: 20) {
            Text("When are you usually awake?")
                .font(.title2.bold())
            Text("Nudges will only fire in this window.")
                .foregroundStyle(.secondary)

            DatePicker("Start",
                       selection: minuteBinding(settings, \.windowStartMinute),
                       displayedComponents: .hourAndMinute)
            DatePicker("End",
                       selection: minuteBinding(settings, \.windowEndMinute),
                       displayedComponents: .hourAndMinute)
        }
        .padding()
    }

    private var frequencyStep: some View {
        let settings = fetchSettings()
        return VStack(spacing: 20) {
            Text("How often should we nudge?")
                .font(.title2.bold())
            Text("You can change this anytime.")
                .foregroundStyle(.secondary)

            ForEach(NudgeFrequency.allCases, id: \.self) { freq in
                Button {
                    settings.frequency = freq
                    try? modelContext.save()
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(freq.displayName).font(.headline)
                            Text(freq.blurb).font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        if settings.frequency == freq {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.blue)
                        }
                    }
                    .padding()
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
            }
        }
        .padding()
    }

    private func permissionStep(title: String,
                                body: String,
                                icon: String,
                                action: @escaping () async -> Void,
                                required: Bool) -> some View {
        VStack(spacing: 24) {
            Image(systemName: icon)
                .font(.system(size: 64))
                .foregroundStyle(.blue)
            Text(title)
                .font(.largeTitle.bold())
            Text(body)
                .font(.title3)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal)

            Button {
                Task {
                    await action()
                    step += 1
                }
            } label: {
                Text("Allow")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue, in: RoundedRectangle(cornerRadius: 12))
            }

            if !required {
                Button("Skip for now") {
                    step += 1
                }
                .foregroundStyle(.secondary)
            }
        }
        .padding()
    }

    private var addWidgetStep: some View {
        VStack(spacing: 24) {
            Image(systemName: "square.grid.2x2.fill")
                .font(.system(size: 64))
                .foregroundStyle(.purple)
            Text("Add a Lock Screen widget")
                .font(.largeTitle.bold())
            Text("The widget shows your next nudge and today's progress. It's a big part of how the app works.")
                .font(.title3)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal)
            Text("Long-press your Lock Screen → Customize → Add widget → VlogNudge")
                .font(.callout)
                .padding()
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10))
        }
        .padding()
    }

    private var finalStep: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(.green)
            Text("All set")
                .font(.largeTitle.bold())
            Button("Start using VlogNudge") {
                hasCompletedOnboarding = true
                Task {
                    await NudgeScheduler.shared.ensureTodayIsScheduled(context: modelContext)
                }
            }
            .font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue, in: RoundedRectangle(cornerRadius: 12))
            .padding()
        }
        .padding()
    }

    // MARK: - Bottom buttons

    private var bottomButtons: some View {
        HStack {
            if step > 0 && step < steps - 1 {
                Button("Back") { step -= 1 }
            }
            Spacer()
            if step < 3 && step != steps - 1 {
                Button("Next") { step += 1 }
                    .buttonStyle(.borderedProminent)
            } else if step == steps - 1 {
                EmptyView()
            } else if step == 10 {
                Button("Continue") { step += 1 }
                    .buttonStyle(.borderedProminent)
            }
        }
    }

    // MARK: - Permission requests

    private func requestCameraAndMic() async {
        _ = await RecordingService.shared.requestPermissions()
    }

    private func requestPhotos() async {
        _ = await PhotosService.requestAuthorization()
    }

    private func requestNotifications() async {
        _ = await NotificationService.shared.requestAuthorization()
    }

    private func requestMotion() async {
        guard CMMotionActivityManager.isActivityAvailable() else { return }

        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            let manager = CMMotionActivityManager()
            manager.queryActivityStarting(from: Date().addingTimeInterval(-60),
                                          to: Date(),
                                          to: .main) { _, _ in
                continuation.resume()
            }
        }
    }

    private func requestLocation() async {
        await LocationService.shared.requestAlwaysAuthorization()
    }

    private func requestCalendar() async {
        await CalendarService.shared.requestAccess()
    }

    private func requestHealth() async {
        await HealthService.shared.requestAuthorization()
    }

    // MARK: - Helpers

    private func fetchSettings() -> UserSettings {
        let descriptor = FetchDescriptor<UserSettings>()
        if let existing = try? modelContext.fetch(descriptor).first {
            return existing
        }
        let new = UserSettings()
        modelContext.insert(new)
        try? modelContext.save()
        return new
    }

    private func minuteBinding(_ settings: UserSettings,
                               _ keyPath: ReferenceWritableKeyPath<UserSettings, Int>) -> Binding<Date> {
        Binding(
            get: { DateHelpers.todayAt(minute: settings[keyPath: keyPath]) },
            set: { newDate in
                let comps = Calendar.current.dateComponents([.hour, .minute], from: newDate)
                settings[keyPath: keyPath] = (comps.hour ?? 0) * 60 + (comps.minute ?? 0)
                try? modelContext.save()
            }
        )
    }
}
