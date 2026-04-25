//
//  SettingsView.swift
//  VlogNudge
//
//  6:3:1 — Dominant bg, Secondary rows/sections, Accent toggles & links.
//

import SwiftUI
import SwiftData
import UserNotifications
import AVFoundation
import Photos
import UIKit
import CoreLocation

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var settingsArray: [UserSettings]

    private var settings: UserSettings {
        if let existing = settingsArray.first { return existing }
        let new = UserSettings()
        modelContext.insert(new)
        try? modelContext.save()
        return new
    }

    var body: some View {
        NavigationStack {
            Form {
                frequencySection
                scheduleSection
                quietHoursSection
                contextSignalsSection
                notificationsSection
                captureSection
                badDaySection
                permissionsSection
                aboutSection
            }
            .scrollContentBackground(.hidden)
            .background(VNColor.dominant)
            .tint(VNColor.accent)
            .navigationTitle("Settings")
        }
    }

    // MARK: - Frequency

    private var frequencySection: some View {
        Section {
            Picker("Nudge frequency", selection: Binding(
                get: { settings.frequency },
                set: { settings.frequency = $0; save() }
            )) {
                ForEach(NudgeFrequency.allCases, id: \.self) { freq in
                    Text(freq.displayName).tag(freq)
                }
            }
            .pickerStyle(.segmented)

            Text(settings.frequency.blurb)
                .font(VNFont.caption)
                .foregroundStyle(VNColor.textSecondary)
        } header: {
            Text("Frequency")
        } footer: {
            Text("You can always hit Record manually regardless of frequency.")
        }
        .listRowBackground(VNColor.secondary)
    }

    // MARK: - Schedule

    private var scheduleSection: some View {
        Section("Active Window") {
            DatePicker("Start",
                       selection: minuteBinding(\.windowStartMinute),
                       displayedComponents: .hourAndMinute)
            DatePicker("End",
                       selection: minuteBinding(\.windowEndMinute),
                       displayedComponents: .hourAndMinute)

            Stepper("Min gap: \(settings.minGapBetweenNudgesMin) min",
                    value: Binding(
                        get: { settings.minGapBetweenNudgesMin },
                        set: { settings.minGapBetweenNudgesMin = $0; save() }
                    ),
                    in: 20...180,
                    step: 5)
        }
        .listRowBackground(VNColor.secondary)
    }

    // MARK: - Quiet Hours

    private var quietHoursSection: some View {
        Section("Quiet Hours") {
            Toggle("Enable quiet hours",
                   isOn: Binding(
                    get: { settings.quietHoursEnabled },
                    set: { settings.quietHoursEnabled = $0; save() }
                   ))

            if settings.quietHoursEnabled {
                DatePicker("Start",
                           selection: minuteBinding(\.quietStartMinute),
                           displayedComponents: .hourAndMinute)
                DatePicker("End",
                           selection: minuteBinding(\.quietEndMinute),
                           displayedComponents: .hourAndMinute)
            }
        }
        .listRowBackground(VNColor.secondary)
    }

    // MARK: - Context Signals

    private var contextSignalsSection: some View {
        Section {
            Toggle("Motion awareness",
                   isOn: Binding(get: { settings.useMotion },
                                 set: { settings.useMotion = $0; save() }))
            Toggle("Location (geofences)",
                   isOn: Binding(get: { settings.useLocation },
                                 set: { settings.useLocation = $0; save() }))
            Toggle("Calendar",
                   isOn: Binding(get: { settings.useCalendar },
                                 set: { settings.useCalendar = $0; save() }))
            Toggle("HealthKit (workouts)",
                   isOn: Binding(get: { settings.useHealth },
                                 set: { settings.useHealth = $0; save() }))
            Toggle("Focus mode awareness",
                   isOn: Binding(get: { settings.useFocus },
                                 set: { settings.useFocus = $0; save() }))
        } header: {
            Text("Context Signals")
        } footer: {
            Text("Each signal makes nudges smarter. Turn off any that feel wrong.")
        }
        .listRowBackground(VNColor.secondary)
    }

    // MARK: - Notifications

    private var notificationsSection: some View {
        Section("Notifications") {
            Toggle("Custom sound",
                   isOn: Binding(get: { settings.customSoundEnabled },
                                 set: { settings.customSoundEnabled = $0; save() }))
            Toggle("Haptic only (silent)",
                   isOn: Binding(get: { settings.hapticOnlyMode },
                                 set: { settings.hapticOnlyMode = $0; save() }))

            Button("Send test notification") {
                Task {
                    await NotificationService.shared.fireImmediateNudge(
                        title: "Test nudge",
                        body: "This is how a nudge will look.",
                        triggerReason: "test",
                        useCustomSound: settings.customSoundEnabled,
                        hapticOnly: settings.hapticOnlyMode
                    )
                }
            }
            .foregroundStyle(VNColor.accent)

            Toggle("End-of-day recap",
                   isOn: Binding(get: { settings.enableEndOfDayRecap },
                                 set: { settings.enableEndOfDayRecap = $0; save() }))
            Toggle("Midpoint check-in",
                   isOn: Binding(get: { settings.enableMidpointCheckIn },
                                 set: { settings.enableMidpointCheckIn = $0; save() }))
        }
        .listRowBackground(VNColor.secondary)
    }

    // MARK: - Capture

    private var captureSection: some View {
        Section("Capture") {
            Stepper("Soft clip length cap: \(settings.softClipLengthCap)s",
                    value: Binding(get: { settings.softClipLengthCap },
                                   set: { settings.softClipLengthCap = $0; save() }),
                    in: 15...300, step: 5)
        }
        .listRowBackground(VNColor.secondary)
    }

    // MARK: - Bad Day

    private var badDaySection: some View {
        Section {
            if let until = settings.badDayUntil, until > Date() {
                Button("Cancel bad day mute") {
                    settings.badDayUntil = nil
                    save()
                }
                .foregroundStyle(VNColor.destructive)
                Text("Muted until \(until, style: .time)")
                    .font(VNFont.caption)
                    .foregroundStyle(VNColor.textSecondary)
            } else {
                Button("Bad day — mute nudges for today") {
                    let endOfDay = Calendar.current.date(
                        bySettingHour: 23, minute: 59, second: 59, of: Date()
                    ) ?? Date().addingTimeInterval(12 * 3600)
                    settings.badDayUntil = endOfDay
                    save()
                    Task {
                        await NotificationService.shared.cancelAllScheduledNudges()
                    }
                }
                .foregroundStyle(VNColor.warning)
            }
        } footer: {
            Text("No guilt. Tomorrow resets normally.")
        }
        .listRowBackground(VNColor.secondary)
    }

    // MARK: - Permissions

    private var permissionsSection: some View {
        Section("Permissions & Places") {
            NavigationLink("Permissions status") {
                PermissionsStatusView()
            }
            NavigationLink("Location / Background Location") {
                BackgroundLocationSettingsView()
            }
            NavigationLink("Geofences") {
                GeofenceManagementView()
            }
            NavigationLink("Nudge analytics") {
                NudgeAnalyticsView()
            }
        }
        .listRowBackground(VNColor.secondary)
    }

    // MARK: - About

    private var aboutSection: some View {
        Section("About") {
            LabeledContent("Version") {
                Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                    .foregroundStyle(VNColor.textSecondary)
            }
        }
        .listRowBackground(VNColor.secondary)
    }

    // MARK: - Helpers

    private func minuteBinding(_ keyPath: ReferenceWritableKeyPath<UserSettings, Int>) -> Binding<Date> {
        Binding(
            get: { DateHelpers.todayAt(minute: settings[keyPath: keyPath]) },
            set: { newDate in
                let comps = Calendar.current.dateComponents([.hour, .minute], from: newDate)
                settings[keyPath: keyPath] = (comps.hour ?? 0) * 60 + (comps.minute ?? 0)
                save()
            }
        )
    }

    private func save() {
        try? modelContext.save()
        Task {
            await NudgeScheduler.shared.ensureTodayIsScheduled(context: modelContext)
        }
    }
}

// MARK: - Background Location Settings

struct BackgroundLocationSettingsView: View {
    // Public Apple Park coordinates (1 Apple Park Way, Cupertino, CA) provide an obvious App Review demo place.
    private static let demoLatitude: CLLocationDegrees = 37.3349
    private static let demoLongitude: CLLocationDegrees = -122.0090

    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Geofence.name) private var geofences: [Geofence]
    @State private var locationService = LocationService.shared
    @State private var placeNudgeError: String?

    var body: some View {
        List {
            Section {
                statusRow
            } header: {
                Text("Status")
            } footer: {
                Text("Background location is only used for Place Nudges after you turn it on here.")
            }

            Section("Place Nudges") {
                Text("VlogNudge can remind you to record when you arrive at or leave saved places, like home, work, or a favorite spot.")
                    .foregroundStyle(VNColor.textSecondary)
                Text("To send those reminders when the app is not open, iOS requires Always location permission and background location updates.")
                    .foregroundStyle(VNColor.textSecondary)
                Text("Start it with Enable Background Location. Stop it any time with Turn Off Background Location.")
                    .foregroundStyle(VNColor.textSecondary)
            }

            Section("Controls") {
                if locationService.authorizationStatus == .notDetermined {
                    Button("Allow Location While Using App") {
                        locationService.requestWhenInUseAuthorization()
                    }
                    .foregroundStyle(VNColor.accent)
                }

                if locationService.authorizationStatus != .authorizedAlways {
                    Button("Enable Background Location") {
                        enableBackgroundLocation()
                    }
                    .foregroundStyle(VNColor.accent)
                }

                if locationService.isBackgroundLocationEnabled {
                    Button("Turn Off Background Location") {
                        locationService.disableBackgroundLocation()
                    }
                    .foregroundStyle(VNColor.destructive)
                }

                Button("Open iOS Location Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }

                if let placeNudgeError {
                    Text(placeNudgeError)
                        .font(VNFont.caption)
                        .foregroundStyle(VNColor.destructive)
                }
            }

            Section("Review Demo") {
                Text("App Review can enable the feature here without special hardware. Add the demo place, then enable background location to see the feature become active.")
                    .foregroundStyle(VNColor.textSecondary)
                Button("Add demo review geofence") {
                    addDemoGeofenceIfNeeded()
                }
                .foregroundStyle(VNColor.accent)
                LabeledContent("Saved places") {
                    Text("\(geofences.count)")
                        .foregroundStyle(VNColor.textSecondary)
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(VNColor.dominant)
        .navigationTitle("Background Location")
        .task {
            locationService.restoreExplicitBackgroundLocationIfNeeded()
        }
    }

    private var statusRow: some View {
        HStack {
            Text(statusText)
            Spacer()
            Image(systemName: statusIcon)
                .foregroundStyle(statusColor)
        }
    }

    private var statusText: String {
        if locationService.authorizationStatus == .denied ||
            locationService.authorizationStatus == .restricted {
            return "Location permission needed"
        }
        if locationService.isBackgroundLocationActive {
            return "Background location is active"
        }
        if locationService.isBackgroundLocationEnabled &&
            locationService.authorizationStatus != .authorizedAlways {
            return "Location permission needed"
        }
        return "Background location is off"
    }

    private var statusIcon: String {
        locationService.isBackgroundLocationActive ? "location.fill" : "location.slash"
    }

    private var statusColor: Color {
        locationService.isBackgroundLocationActive ? VNColor.success : VNColor.warning
    }

    private func enableBackgroundLocation() {
        locationService.enableBackgroundLocation()
        refreshGeofences()
    }

    private func addDemoGeofenceIfNeeded() {
        if !geofences.contains(where: { $0.name == "App Review Demo Place" }) {
            let demo = Geofence(
                name: "App Review Demo Place",
                latitude: Self.demoLatitude,
                longitude: Self.demoLongitude,
                radius: 200
            )
            modelContext.insert(demo)
            do {
                try modelContext.save()
            } catch {
                placeNudgeError = "Could not save the demo place: \(error.localizedDescription)"
                return
            }
        }
        refreshGeofences()
    }

    private func refreshGeofences() {
        let allFences: [Geofence]
        do {
            allFences = try modelContext.fetch(FetchDescriptor<Geofence>())
            placeNudgeError = nil
        } catch {
            placeNudgeError = "Could not refresh saved places: \(error.localizedDescription)"
            return
        }
        LocationService.shared.refreshGeofences(
            from: allFences,
            near: LocationService.shared.currentLocation
        )
    }
}

// MARK: - Permissions Status (themed)

struct PermissionsStatusView: View {
    @State private var notificationGranted = false
    @State private var cameraGranted = false
    @State private var micGranted = false
    @State private var photosStatus = "Unknown"

    var body: some View {
        List {
            row(name: "Notifications", granted: notificationGranted)
            row(name: "Camera", granted: cameraGranted)
            row(name: "Microphone", granted: micGranted)
            HStack {
                Text("Photos")
                Spacer()
                Text(photosStatus).foregroundStyle(VNColor.textSecondary)
            }
            Button("Open iOS Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            .foregroundStyle(VNColor.accent)
        }
        .scrollContentBackground(.hidden)
        .background(VNColor.dominant)
        .navigationTitle("Permissions")
        .task {
            await refresh()
        }
    }

    private func row(name: String, granted: Bool) -> some View {
        HStack {
            Text(name)
            Spacer()
            Image(systemName: granted ? "checkmark.circle.fill" : "xmark.circle")
                .foregroundStyle(granted ? VNColor.success : VNColor.destructive)
        }
    }

    private func refresh() async {
        let status = await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
        notificationGranted = (status == .authorized || status == .provisional)
        cameraGranted = AVCaptureDevice.authorizationStatus(for: .video) == .authorized
        micGranted = AVCaptureDevice.authorizationStatus(for: .audio) == .authorized
        let photos = PHPhotoLibrary.authorizationStatus(for: .addOnly)
        switch photos {
        case .authorized: photosStatus = "Granted"
        case .limited: photosStatus = "Limited"
        case .denied: photosStatus = "Denied"
        case .notDetermined: photosStatus = "Not asked"
        default: photosStatus = "Unknown"
        }
    }
}
