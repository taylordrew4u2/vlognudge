# VlogNudge — Xcode Setup Guide

ADHD-aware iOS app for capturing day-in-the-life vlog clips, built to feed a CapCut editing workflow. This folder contains the full Swift source tree for a fresh Xcode project.

Stack: iOS 17.0 min · Swift 5.9 · SwiftUI · SwiftData + CloudKit · ActivityKit · WidgetKit · AppIntents

---

## 1. Create the Xcode project

1. Xcode → File → New → Project → **iOS → App**
2. Settings:
   - Product Name: **VlogNudge**
   - Team: your Apple Developer team
   - Organization Identifier: `com.taylordrew`
   - Interface: **SwiftUI**
   - Language: **Swift**
   - Storage: **SwiftData**
   - Host in CloudKit: **✓ checked**
3. Deployment Target: **iOS 17.0**, iPhone + iPad

## 2. Capabilities on the main app target

Signing & Capabilities → `+ Capability`:

- **App Groups** — `group.com.taylordrew.vlognudge`
- **iCloud** → CloudKit, container `iCloud.com.taylordrew.vlognudge`
- **Push Notifications**
- **Background Modes** — Location updates, Background fetch, Background processing
- **HealthKit**
- **Family Controls** (request entitlement from Apple; if denied, set `useScreenTime = false` default and skip Screen Time features)

## 3. Add extension targets

You need **four** extension targets besides the main app:

### 3a. Widget Extension
- File → New → Target → **Widget Extension**
- Name: `VlogNudgeWidgets`
- ✓ **Include Live Activity**
- Add App Groups capability (same ID)

### 3b. Notification Service Extension
- File → New → Target → **Notification Service Extension**
- Name: `VlogNudgeNotificationService`
- Add App Groups capability

### 3c. Device Activity Monitor Extension (optional — only if using Screen Time)
- File → New → Target → **Device Activity Monitor Extension**
- Name: `VlogNudgeDeviceActivity`
- Add App Groups capability

### 3d. (Skip for now) App Intents Extension
The intents are defined in the main app and shared with the widget target via target membership — no separate extension needed for v1.

## 4. Info.plist keys (main app target)

| Key | Value |
|---|---|
| NSCameraUsageDescription | We use your camera to film vlog clips. |
| NSMicrophoneUsageDescription | We record audio with your vlog clips. |
| NSPhotoLibraryAddUsageDescription | Clips save to a Daily Vlogs album. |
| NSMotionUsageDescription | So we avoid nudging while driving and detect when you arrive somewhere. |
| NSLocationWhenInUseUsageDescription | For location-based nudges like "just got home." |
| NSLocationAlwaysAndWhenInUseUsageDescription | So we can trigger nudges when you arrive at places even if the app is backgrounded. |
| NSCalendarsUsageDescription | We skip nudges during your events and nudge right after they end. |
| NSCalendarsFullAccessUsageDescription | Same — reads upcoming and just-ended events. |
| NSHealthShareUsageDescription | Post-workout is a great vlog moment. |
| NSFocusStatusUsageDescription | So we don't interrupt you in Sleep or Do Not Disturb. |

Also:
- **Permitted background task scheduler identifiers** (array): add `com.taylordrew.vlognudge.refresh`
- **URL Types** → URL Schemes → add `vlognudge` so widget deep links work

## 5. Drop in source files

Copy the folders into Xcode matching their structure. Most files belong to one target; a few need **multiple target memberships**:

**Files that need membership in MULTIPLE targets** (use Xcode's File Inspector → Target Membership):

| File | Main app | Widget | Notification Svc | Device Activity |
|---|---|---|---|---|
| `Shared/AppConstants.swift` | ✓ | ✓ | ✓ | ✓ |
| `Services/LiveActivityAttributes.swift` | ✓ | ✓ | | |
| `Intents/AppIntents.swift` | ✓ | ✓ | | |

Everything else goes in the target that matches its folder.

## 6. Custom notification sound

Add `NudgeSound.caf` to the main app bundle. Keep it short (~0.4s) and distinctive. To create one:

```bash
afconvert input.wav -f caff -d ima4 NudgeSound.caf
```

Drag into Xcode with "Copy items if needed" checked and main app target selected.

## 7. First build

1. Build + run on a real device (simulator has limits with Live Activities, HealthKit, Focus, location)
2. Walk through onboarding — camera/mic/photos/notifications are required; motion/location/calendar/health are optional but strongly recommended
3. On Today screen: tap **Record now** — confirm a clip saves to the Photos "Daily Vlogs" album
4. Go to Settings → **Send test notification** — confirm custom sound plays and the **Record** action button opens the capture screen directly
5. Add a geofence (Settings → Geofences) — try your home
6. Leave phone alone — Lock Screen should show the Live Activity with next nudge time, the widget should show clip count

## 8. What's in this scaffold

### Main app target (`VlogNudge/`)

```
VlogNudgeApp.swift                  — entry, notification delegate wiring
AppState.swift                      — observable app state, deep link routing
RootView.swift                      — tabs + onboarding gate + URL schemes

Shared/
├── AppConstants.swift              — shared IDs (include in all targets)
├── DateHelpers.swift               — day keys, window math
└── SharedModelContainer.swift      — SwiftData+CloudKit container singleton

Models/
└── Models.swift                    — Clip, NudgeEvent, Geofence, IdeaMemo,
                                      UserSettings, ContextSnapshot,
                                      NudgeFrequency, OrientationLock

Services/
├── NotificationService.swift       — categories, actions, scheduling
├── NotificationDelegate.swift      — action button routing
├── NudgeScorer.swift               — pure scoring function
├── NudgeScheduler.swift            — orchestrator, rolling queue
├── PromptGenerator.swift           — contextual prompt copy
├── LiveActivityAttributes.swift    — shared shape (ALSO in widget target)
├── LiveActivityController.swift    — daily Live Activity
├── RecordingService.swift          — AVFoundation, vertical lock
├── PhotosService.swift             — Daily Vlogs album
├── MotionService.swift             — CoreMotion activity detection
├── LocationService.swift           — geofences + significant location
├── CalendarService.swift           — EventKit event-end triggers
├── HealthService.swift             — workout-end observer
├── WeatherService.swift            — WeatherKit conditions
├── FocusService.swift              — Focus mode read
└── ScreenTimeService.swift         — Family Controls (optional)

Intents/
└── AppIntents.swift                — RecordClip, NotNow, SkipHour, CaptureIdea
                                      (ALSO in widget target)

Features/
├── Today/TodayView.swift           — home screen
├── Capture/CaptureView.swift       — full-screen camera UI
├── Timeline/TimelineView.swift     — calendar + clip list + preview
├── IdeaMemo/IdeasView.swift        — voice memo list + recorder
├── Settings/
│   ├── SettingsView.swift
│   ├── GeofenceManagementView.swift — list + map editor
│   └── NudgeAnalyticsView.swift     — conversion-rate charts
└── Onboarding/OnboardingFlow.swift
```

### Widget extension (`VlogNudgeWidgets/`)

```
VlogNudgeWidgetsBundle.swift        — registers all widgets
LockScreenWidget/
└── LockScreenWidget.swift          — rectangular, circular, inline
HomeScreenWidget/
└── HomeScreenWidget.swift          — small, medium, large (interactive)
StandByWidget/
└── StandByWidget.swift             — big glanceable for docked phone
LiveActivity/
└── VlogNudgeLiveActivity.swift     — Lock Screen + Dynamic Island
```

### Notification Service Extension (`VlogNudgeNotificationService/`)

```
NotificationService.swift           — enriches delivered notifications
                                      with "Last clip Xm ago" +
                                      "Nudged: [reason]"
```

### Device Activity Extension (`VlogNudgeDeviceActivity/`)

```
VlogNudgeDeviceActivityMonitor.swift — Screen Time event handler
```

## 9. Known gotchas

- **Live Activities are flaky in Simulator.** Test on device.
- **Family Controls entitlement** is gated by Apple. Budget waiting time or remove the capability and set `useScreenTime = false` default — the rest of the app works fine without it.
- **BGAppRefreshTask** runs when iOS wants it to, not when you ask. The scheduled notifications are the reliable backbone; background refresh just extends the queue into tomorrow.
- **Geofence monitoring** has a ~20-region limit. `LocationService.refreshGeofences` trims to 18 nearest.
- **WeatherKit** needs paid dev program enrollment + capability. Cheap at this scale.
- **SwiftData + CloudKit** requires every `@Model` property to have a default value. The scaffold already does this.
- **Significant location changes are slow** by design (battery). Expect minutes, not seconds.

## 10. Quick fixes if something doesn't compile

- **"Cannot find AppConstants in scope"** in widget → add `AppConstants.swift` to widget target membership
- **"Cannot find VlogNudgeActivityAttributes in scope"** in widget → same, add `LiveActivityAttributes.swift` to widget target
- **"Cannot find RecordClipIntent in scope"** in widget → add `AppIntents.swift` to widget target
- **Crash on launch re: ModelContainer** → verify App Group ID matches exactly in capabilities *and* in `AppConstants.swift`
- **Notifications don't show custom sound** → verify `NudgeSound.caf` is in the main app bundle and target membership is correct

## 11. Next steps after shipping v1

The app is complete as a v1 but these are natural extensions:

- **Calibration mode** — first 3 days observe behavior and auto-tune scoring weights based on which nudges convert
- **True iPad Handoff routing** — CloudKit gets data cross-device; nudge-targeting-by-active-device needs NSUbiquitousKeyValueStore heartbeat
- **Watch app** (you said no watch — skipping)
- **CapCut share extension** once CapCut exposes a URL scheme for multi-asset import
- **Idea memo transcription** via SFSpeechRecognizer (you said skip for v1)
- **Solar/golden hour trigger** via Solar position calculation (stub exists in scorer)
- **Co-host mode** — pair with another user for gentle accountability presence
