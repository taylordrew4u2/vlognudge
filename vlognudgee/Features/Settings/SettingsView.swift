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
import CoreMotion
import EventKit
import HealthKit
import Intents

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
                customScheduleSection
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

    // MARK: - Custom Schedule

    private var customScheduleSection: some View {
        Section {
            Toggle("Custom schedule",
                   isOn: Binding(get: { settings.customScheduleEnabled },
                                 set: { settings.customScheduleEnabled = $0; save() }))
            if settings.customScheduleEnabled {
                NavigationLink("Set days & times") {
                    CustomScheduleEditorView(settings: settings)
                }
            }
        } header: {
            Text("Custom Schedule")
        } footer: {
            Text("Pick exact notification times for specific days. When on, this replaces the frequency-based schedule — context nudges still apply.")
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

// MARK: - Custom Schedule Editor

struct CustomScheduleEditorView: View {
    @Environment(\.modelContext) private var modelContext
    let settings: UserSettings

    /// Per-weekday "add" draft time (defaults to noon).
    @State private var draftTimes: [Int: Date] = [:]

    // Calendar.weekdaySymbols is ordered Sunday…Saturday (index 0 = Sunday),
    // matching Calendar's weekday component (1 = Sunday … 7 = Saturday).
    private var symbols: [String] { Calendar.current.weekdaySymbols }

    var body: some View {
        List {
            ForEach(1...7, id: \.self) { weekday in
                weekdaySection(weekday)
            }
        }
        .scrollContentBackground(.hidden)
        .background(VNColor.dominant)
        .navigationTitle("Days & Times")
    }

    private func weekdaySection(_ weekday: Int) -> some View {
        let times = (settings.customSchedule[weekday] ?? []).sorted()
        return Section(symbols[weekday - 1]) {
            if times.isEmpty {
                Text("No nudges")
                    .font(VNFont.caption)
                    .foregroundStyle(VNColor.textTertiary)
            } else {
                ForEach(times, id: \.self) { minute in
                    HStack {
                        Text(timeLabel(minute))
                            .foregroundStyle(VNColor.textPrimary)
                        Spacer()
                        Button(role: .destructive) {
                            remove(minute, from: weekday)
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .foregroundStyle(VNColor.destructive)
                        }
                        .buttonStyle(.borderless)
                    }
                }
            }

            HStack {
                DatePicker("Add time",
                           selection: draftBinding(for: weekday),
                           displayedComponents: .hourAndMinute)
                    .labelsHidden()
                Spacer()
                Button("Add") { addDraft(for: weekday) }
                    .foregroundStyle(VNColor.accent)
            }
        }
        .listRowBackground(VNColor.secondary)
    }

    // MARK: - Helpers

    private func draftBinding(for weekday: Int) -> Binding<Date> {
        Binding(
            get: { draftTimes[weekday] ?? DateHelpers.todayAt(minute: 12 * 60) },
            set: { draftTimes[weekday] = $0 }
        )
    }

    private func minute(from date: Date) -> Int {
        let c = Calendar.current.dateComponents([.hour, .minute], from: date)
        return (c.hour ?? 0) * 60 + (c.minute ?? 0)
    }

    private func timeLabel(_ minute: Int) -> String {
        DateHelpers.todayAt(minute: minute).formatted(date: .omitted, time: .shortened)
    }

    private func addDraft(for weekday: Int) {
        let m = minute(from: draftTimes[weekday] ?? DateHelpers.todayAt(minute: 12 * 60))
        var schedule = settings.customSchedule
        var arr = schedule[weekday] ?? []
        guard !arr.contains(m) else { return }
        arr.append(m)
        schedule[weekday] = arr.sorted()
        settings.customSchedule = schedule
        persist()
    }

    private func remove(_ minute: Int, from weekday: Int) {
        var schedule = settings.customSchedule
        var arr = schedule[weekday] ?? []
        arr.removeAll { $0 == minute }
        schedule[weekday] = arr.isEmpty ? nil : arr
        settings.customSchedule = schedule
        persist()
    }

    private func persist() {
        try? modelContext.save()
        Task { await NudgeScheduler.shared.ensureTodayIsScheduled(context: modelContext) }
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
    enum Status {
        case granted, limited, denied, notAsked, unavailable, managedElsewhere

        var label: String {
            switch self {
            case .granted: return "On"
            case .limited: return "Limited"
            case .denied: return "Off"
            case .notAsked: return "Tap to allow"
            case .unavailable: return "Unavailable"
            case .managedElsewhere: return "In Health app"
            }
        }

        var icon: String {
            switch self {
            case .granted: return "checkmark.circle.fill"
            case .limited: return "circle.lefthalf.filled"
            case .denied: return "xmark.circle.fill"
            case .notAsked: return "plus.circle.fill"
            case .unavailable: return "minus.circle"
            case .managedElsewhere: return "arrow.up.right.circle"
            }
        }

        var color: Color {
            switch self {
            case .granted: return VNColor.success
            case .limited: return VNColor.warning
            case .denied: return VNColor.destructive
            case .notAsked: return VNColor.accent
            case .unavailable, .managedElsewhere: return VNColor.textTertiary
            }
        }
    }

    enum Kind: String, CaseIterable, Identifiable {
        case notifications, camera, microphone, photos, motion, location, calendar, health, focus
        var id: String { rawValue }

        var title: String {
            switch self {
            case .notifications: return "Notifications"
            case .camera: return "Camera"
            case .microphone: return "Microphone"
            case .photos: return "Photos"
            case .motion: return "Motion & Fitness"
            case .location: return "Location"
            case .calendar: return "Calendar"
            case .health: return "Health"
            case .focus: return "Focus"
            }
        }

        var why: String {
            switch self {
            case .notifications: return "How nudges reach you"
            case .camera: return "Film clips in the app"
            case .microphone: return "Record audio with clips"
            case .photos: return "Save to your Daily Vlogs album"
            case .motion: return "No nudges while driving"
            case .location: return "Place Nudges when you arrive"
            case .calendar: return "Nudge right after events end"
            case .health: return "Post-workout nudges"
            case .focus: return "Stay quiet during Focus"
            }
        }

        var icon: String {
            switch self {
            case .notifications: return "bell.fill"
            case .camera: return "video.fill"
            case .microphone: return "mic.fill"
            case .photos: return "photo.on.rectangle"
            case .motion: return "figure.walk"
            case .location: return "location.fill"
            case .calendar: return "calendar"
            case .health: return "heart.fill"
            case .focus: return "moon.fill"
            }
        }
    }

    @State private var statuses: [Kind: Status] = [:]
    @Environment(\.scenePhase) private var scenePhase

    private var grantedCount: Int {
        statuses.values.filter { $0 == .granted || $0 == .limited }.count
    }

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: VNSpacing.sm) {
                    Text("\(grantedCount) of \(Kind.allCases.count) on")
                        .font(VNFont.title2)
                    Text("Everything stays on your device. Turn on more for smarter nudges.")
                        .font(VNFont.callout)
                        .opacity(0.85)
                    Button("Allow everything not yet asked") {
                        Task { await requestAllNotAsked() }
                    }
                    .font(VNFont.subheadline)
                    .padding(.top, VNSpacing.xs)
                    .tint(.white)
                    .buttonStyle(.bordered)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .vnHeroCard()
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
            }

            Section {
                ForEach(Kind.allCases) { kind in
                    row(kind)
                }
            } footer: {
                Text("Tap a row to allow it, or to change it in iOS Settings. Health access is managed in the Health app.")
            }

            Section {
                Button("Open iOS Settings") { openSettings() }
                    .foregroundStyle(VNColor.accent)
            }
        }
        .scrollContentBackground(.hidden)
        .background(VNColor.dominant)
        .navigationTitle("Permissions")
        .task { await refresh() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { Task { await refresh() } }
        }
    }

    private func row(_ kind: Kind) -> some View {
        let status = statuses[kind] ?? .notAsked
        return Button {
            Task { await handleTap(kind, status: status) }
        } label: {
            HStack(spacing: VNSpacing.md) {
                Image(systemName: kind.icon)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(width: 32, height: 32)
                    .background(VNGradient.hero, in: RoundedRectangle(cornerRadius: VNRadius.sm))
                VStack(alignment: .leading, spacing: 2) {
                    Text(kind.title)
                        .foregroundStyle(VNColor.textPrimary)
                    Text(kind.why)
                        .font(VNFont.caption)
                        .foregroundStyle(VNColor.textSecondary)
                }
                Spacer()
                Label(status.label, systemImage: status.icon)
                    .labelStyle(.titleAndIcon)
                    .font(VNFont.caption)
                    .foregroundStyle(status.color)
            }
        }
        .disabled(status == .unavailable)
        .accessibilityLabel("\(kind.title), \(status.label)")
    }

    // MARK: - Requests

    private func handleTap(_ kind: Kind, status: Status) async {
        switch status {
        case .notAsked:
            await request(kind)
        case .denied, .limited, .managedElsewhere:
            if kind == .health, let url = URL(string: "x-apple-health://") {
                _ = await UIApplication.shared.open(url)
            } else {
                openSettings()
            }
        case .granted:
            openSettings()
        case .unavailable:
            break
        }
        await refresh()
    }

    private func requestAllNotAsked() async {
        for kind in Kind.allCases where statuses[kind] == .notAsked {
            await request(kind)
            await refresh()
        }
    }

    private func request(_ kind: Kind) async {
        switch kind {
        case .notifications:
            _ = await NotificationService.shared.requestAuthorization()
        case .camera:
            _ = await AVCaptureDevice.requestAccess(for: .video)
        case .microphone:
            _ = await AVCaptureDevice.requestAccess(for: .audio)
        case .photos:
            _ = await PhotosService.requestAuthorization()
        case .motion:
            guard CMMotionActivityManager.isActivityAvailable() else { return }
            let manager = CMMotionActivityManager()
            await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
                manager.queryActivityStarting(from: Date().addingTimeInterval(-60),
                                              to: Date(),
                                              to: .main) { _, _ in
                    withExtendedLifetime(manager) { continuation.resume() }
                }
            }
        case .location:
            LocationService.shared.requestWhenInUseAuthorization()
            // The system prompt is async and delegate-driven; give it a moment before refreshing.
            try? await Task.sleep(for: .seconds(1))
        case .calendar:
            await CalendarService.shared.requestAccess()
        case .health:
            await HealthService.shared.requestAuthorization()
        case .focus:
            await FocusService.shared.requestAuthorization()
        }
    }

    private func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }

    // MARK: - Status

    private func refresh() async {
        var next: [Kind: Status] = [:]

        switch await UNUserNotificationCenter.current().notificationSettings().authorizationStatus {
        case .authorized, .ephemeral: next[.notifications] = .granted
        case .provisional: next[.notifications] = .limited
        case .denied: next[.notifications] = .denied
        default: next[.notifications] = .notAsked
        }

        next[.camera] = Self.avStatus(.video)
        next[.microphone] = Self.avStatus(.audio)

        switch PHPhotoLibrary.authorizationStatus(for: .readWrite) {
        case .authorized: next[.photos] = .granted
        case .limited: next[.photos] = .limited
        case .denied, .restricted: next[.photos] = .denied
        default: next[.photos] = .notAsked
        }

        if !CMMotionActivityManager.isActivityAvailable() {
            next[.motion] = .unavailable
        } else {
            switch CMMotionActivityManager.authorizationStatus() {
            case .authorized: next[.motion] = .granted
            case .denied, .restricted: next[.motion] = .denied
            default: next[.motion] = .notAsked
            }
        }

        switch CLLocationManager().authorizationStatus {
        case .authorizedAlways: next[.location] = .granted
        case .authorizedWhenInUse: next[.location] = .limited
        case .denied, .restricted: next[.location] = .denied
        default: next[.location] = .notAsked
        }

        switch EKEventStore.authorizationStatus(for: .event) {
        case .fullAccess, .authorized: next[.calendar] = .granted
        case .writeOnly: next[.calendar] = .limited
        case .denied, .restricted: next[.calendar] = .denied
        default: next[.calendar] = .notAsked
        }

        // HealthKit never reveals read-permission state, only whether we've asked.
        if !HKHealthStore.isHealthDataAvailable() {
            next[.health] = .unavailable
        } else {
            let requestStatus = try? await HKHealthStore().statusForAuthorizationRequest(
                toShare: [], read: [HKObjectType.workoutType()]
            )
            next[.health] = requestStatus == .unnecessary ? .managedElsewhere : .notAsked
        }

        switch INFocusStatusCenter.default.authorizationStatus {
        case .authorized: next[.focus] = .granted
        case .denied, .restricted: next[.focus] = .denied
        default: next[.focus] = .notAsked
        }

        statuses = next
    }

    private static func avStatus(_ type: AVMediaType) -> Status {
        switch AVCaptureDevice.authorizationStatus(for: type) {
        case .authorized: return .granted
        case .denied, .restricted: return .denied
        default: return .notAsked
        }
    }
}
