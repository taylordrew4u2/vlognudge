# VlogNudge — Full App Specification

*An ADHD-aware iOS app for capturing day-in-the-life vlog clips, built for batching into CapCut edits.*

---

## 1. Philosophy

Every design decision in this app follows three rules:

1. **The app remembers so you don't have to.** Never ask the user to recall context. Always surface last-clip time, gap length, and what they were thinking.
2. **Nudges should feel observational, not mechanical.** "You just got home" beats "3pm reminder." The user should feel the app noticed something, not that a timer went off.
3. **No punishment mechanics.** No streaks that break, no guilt notifications, no red. Miss a day, the app continues tomorrow.

---

## 2. Platform & Stack

- **iOS 17.0 minimum** (iPhone + iPad, universal)
- **Swift 5.9 / SwiftUI**
- **SwiftData** for persistence (not Core Data)
- **Observation framework** (`@Observable`) for view models
- **App Intents** for widget interactivity and Siri donations
- **ActivityKit** for Live Activities / Dynamic Island
- **WidgetKit** for Lock Screen + Home Screen widgets
- **AVFoundation** for capture
- **Photos / PhotosUI** for library integration
- **UserNotifications** for nudges
- **CoreMotion** for activity detection
- **CoreLocation** for geofences + significant location changes
- **EventKit** for calendar awareness
- **HealthKit** for workout detection
- **WeatherKit** for weather-aware prompts
- **DeviceActivity + FamilyControls + ManagedSettings** for Screen Time features
- **INFocusStatusCenter** for Focus mode awareness

---

## 3. Xcode Targets

1. **VlogNudge** (main app)
2. **VlogNudgeWidgets** (Widget Extension — Lock Screen widget, Home Screen widget, Live Activity)
3. **VlogNudgeIntents** (App Intents Extension — for record-from-widget and Siri)
4. **VlogNudgeDeviceActivity** (DeviceActivityMonitor Extension — for Screen Time triggers)
5. **VlogNudgeNotificationService** (Notification Service Extension — for dynamic notification content)

**App Group** (`group.com.taylordrew.vlognudge`) shared between all targets for shared defaults and data.

---

## 4. Info.plist Keys

```
NSCameraUsageDescription
NSMicrophoneUsageDescription
NSPhotoLibraryAddUsageDescription
NSPhotoLibraryUsageDescription
NSMotionUsageDescription
NSLocationWhenInUseUsageDescription
NSLocationAlwaysAndWhenInUseUsageDescription
NSCalendarsUsageDescription
NSCalendarsFullAccessUsageDescription
NSHealthShareUsageDescription
NSFocusStatusUsageDescription
NSUserNotificationsUsageDescription
```

**Background Modes:** Location updates, Background processing, Background fetch, Audio (for Live Activity audio updates if needed).

**Entitlements:**
- App Groups
- HealthKit
- WeatherKit (requires Apple Developer Program enrollment + capability)
- Family Controls (Screen Time — requires explicit request from Apple for non-parental-control use, this may gate some features)
- Push Notifications
- Background Modes

---

## 5. Project Structure

```
VlogNudge/
├── VlogNudgeApp.swift
├── AppState.swift                    // @Observable global state
│
├── Features/
│   ├── Today/
│   │   ├── TodayView.swift
│   │   ├── TodayViewModel.swift
│   │   └── ClipStripView.swift
│   ├── Capture/
│   │   ├── CaptureView.swift
│   │   ├── CaptureViewModel.swift
│   │   ├── CameraPreviewLayer.swift
│   │   └── FramingGuideOverlay.swift
│   ├── Timeline/
│   │   ├── TimelineView.swift
│   │   ├── CalendarGridView.swift
│   │   ├── DayClipListView.swift
│   │   └── ClipPreviewView.swift
│   ├── IdeaMemo/
│   │   ├── IdeaMemoRecordView.swift
│   │   └── IdeaMemoListView.swift
│   ├── Settings/
│   │   ├── SettingsView.swift
│   │   ├── ScheduleSettingsView.swift
│   │   ├── NudgeSettingsView.swift
│   │   ├── GeofenceManagementView.swift
│   │   └── PermissionsStatusView.swift
│   └── Onboarding/
│       ├── OnboardingFlow.swift
│       ├── ValuePropStep.swift
│       ├── SchedulePickerStep.swift
│       └── PermissionStep.swift
│
├── Services/
│   ├── RecordingService.swift
│   ├── PhotosService.swift
│   ├── NotificationService.swift
│   ├── MotionService.swift
│   ├── LocationService.swift
│   ├── CalendarService.swift
│   ├── HealthService.swift
│   ├── WeatherService.swift
│   ├── FocusService.swift
│   ├── DeviceActivityService.swift
│   ├── ScreenTimeService.swift
│   ├── NudgeScorer.swift
│   ├── NudgeScheduler.swift
│   ├── LiveActivityController.swift
│   ├── PromptGenerator.swift
│   └── HandoffService.swift          // for iPad routing
│
├── Models/
│   ├── Clip.swift
│   ├── NudgeEvent.swift
│   ├── Geofence.swift
│   ├── IdeaMemo.swift
│   ├── Settings.swift
│   └── ContextSnapshot.swift
│
├── Intents/
│   ├── RecordClipIntent.swift
│   ├── SkipNudgeIntent.swift
│   ├── NotNowIntent.swift
│   └── CaptureIdeaIntent.swift
│
├── Shared/
│   ├── Theme.swift
│   ├── HapticEngine.swift
│   ├── SoundPlayer.swift
│   └── DateHelpers.swift
│
└── Resources/
    ├── NudgeSound.caf                // custom notification sound
    └── Prompts.json                  // bank of prompt templates
```

```
VlogNudgeWidgets/
├── VlogNudgeWidgetsBundle.swift
├── LockScreenWidget/
│   ├── LockScreenWidget.swift
│   ├── LockScreenProvider.swift
│   └── LockScreenEntryView.swift
├── HomeScreenWidget/
│   ├── HomeScreenWidget.swift
│   └── HomeScreenEntryView.swift
├── StandByWidget/
│   └── StandByWidget.swift
└── LiveActivity/
    ├── VlogNudgeLiveActivity.swift
    ├── LiveActivityAttributes.swift
    └── DynamicIslandViews.swift
```

---

## 6. Data Models (SwiftData)

```swift
@Model
final class Clip {
    var id: UUID = UUID()
    var recordedAt: Date
    var duration: TimeInterval
    var photosAssetID: String        // PHAsset localIdentifier
    var topicPrompt: String?
    var starred: Bool = false
    var dayKey: String               // "2026-04-21"
    var capturedContext: String?     // JSON: location name, motion state, etc.

    init(recordedAt: Date, duration: TimeInterval, photosAssetID: String, topicPrompt: String? = nil) {
        self.recordedAt = recordedAt
        self.duration = duration
        self.photosAssetID = photosAssetID
        self.topicPrompt = topicPrompt
        self.dayKey = DateHelpers.dayKey(from: recordedAt)
    }
}

@Model
final class NudgeEvent {
    var id: UUID = UUID()
    var scheduledFor: Date
    var firedAt: Date?
    var dismissedAt: Date?
    var resultedInClipID: UUID?
    var score: Int
    var triggerReason: String        // "calendar_end", "geofence_exit:Home", "time_baseline"
    var contextSnapshotJSON: String
}

@Model
final class Geofence {
    var id: UUID = UUID()
    var name: String
    var latitude: Double
    var longitude: Double
    var radius: Double = 100         // meters
    var nudgeOnEntry: Bool = true
    var nudgeOnExit: Bool = true
    var customPromptOnEntry: String?
    var customPromptOnExit: String?
}

@Model
final class IdeaMemo {
    var id: UUID = UUID()
    var createdAt: Date
    var transcription: String?
    var audioFilePath: String?
    var usedAt: Date?                // when surfaced as a prompt
}

@Model
final class UserSettings {
    var id: UUID = UUID()

    // Schedule
    var windowStartMinute: Int = 600  // minutes from midnight — 10:00am
    var windowEndMinute: Int = 1320   // 22:00
    var targetClipsPerDay: Int = 8

    // Quiet hours
    var quietHoursEnabled: Bool = false
    var quietStartMinute: Int = 1380
    var quietEndMinute: Int = 540

    // Nudge behavior
    var sensitivity: Int = 1          // 0 chill, 1 normal, 2 aggressive
    var minGapBetweenNudgesMin: Int = 45
    var enableEscalation: Bool = true
    var enableEndOfDayRecap: Bool = true
    var enableMidpointCheckIn: Bool = true

    // Context signals
    var useMotion: Bool = true
    var useLocation: Bool = true
    var useCalendar: Bool = true
    var useHealth: Bool = true
    var useWeather: Bool = true
    var useFocus: Bool = true
    var useScreenTime: Bool = false   // off by default — heavy permission

    // Capture
    var orientationLock: OrientationLock = .vertical
    var softClipLengthCap: Int = 60   // seconds
    var saveToPhotosAlbumName: String = "Daily Vlogs"

    // Notifications
    var customSoundEnabled: Bool = true
    var hapticOnlyMode: Bool = false
}

enum OrientationLock: String, Codable { case vertical, horizontal, free }

struct ContextSnapshot: Codable {
    let timestamp: Date
    let motionActivity: String?       // "stationary", "walking", "automotive"
    let currentGeofenceID: UUID?
    let lastGeofenceTransition: String?
    let minutesSinceLastClip: Int?
    let unlocksInLast10Min: Int?
    let upcomingEventInMinutes: Int?
    let lastEventEndedMinutesAgo: Int?
    let inFocusMode: Bool
    let isCharging: Bool
    let isOnCall: Bool
    let weatherCondition: String?
    let phoneActiveDevice: Bool       // vs iPad active
}
```

---

## 7. Services (what each one does)

### RecordingService
Wraps `AVCaptureSession`. Responsibilities:
- Configure session (vertical lock, 1080p, 30fps, default mic)
- Expose a `CMSampleBufferDisplayLayer` or `AVCaptureVideoPreviewLayer` for UI
- `startRecording()` → writes to temp file via `AVCaptureMovieFileOutput`
- `stopRecording()` → returns temp URL, hands to PhotosService
- Handle interruptions (call comes in, audio route change) gracefully
- Single source of truth for "am I currently recording"

### PhotosService
- Creates/retrieves the "Daily Vlogs" album on first use
- Saves recorded file to the album and returns `PHAsset.localIdentifier`
- Fetches `AVAsset` or thumbnail for a given asset ID (for preview)
- Filters album by starred clips for CapCut export
- Handles limited library selection gracefully

### NotificationService
- Requests auth, registers notification categories with actions (`RECORD`, `NOT_NOW`, `SKIP_HOUR`)
- Schedules upcoming nudges as `UNNotificationRequest` with category identifiers
- Registers App Intents for action buttons so tapping "Record" opens capture directly
- Plays custom `NudgeSound.caf` when sensitivity allows
- Handles delivered notification cleanup when a clip is filmed

### MotionService
- `CMMotionActivityManager.startActivityUpdates` — publishes current activity
- Queries historical activity (`queryActivityStarting:to:`) to detect transitions
- Publishes `@Observable` current state: `.stationary`, `.walking`, `.running`, `.automotive`, `.cycling`, `.unknown`
- Transition events emitted via AsyncStream

### LocationService
- Requests When In Use authorization first
- Requests Always authorization only after the user enables Place Nudges background location in Settings
- Starts significant location changes (low battery) only while Place Nudges background location is active
- Registers `CLCircularRegion` for each saved Geofence, monitors entry/exit while Place Nudges background location is active
- On entry/exit, writes an event to a shared App Group defaults key so other components (NudgeScheduler) can react
- Handles "new location" detection by comparing against known geofences

### CalendarService
- Requests EventKit authorization (write-free, read-only)
- Queries upcoming events in a rolling 2-hour window
- Detects events that just ended (within last 5 min)
- Auto-creates "busy" mute periods during events matching keywords ("set", "show", "meeting") — user-configurable

### HealthService
- Requests read access to workouts
- Subscribes to new workout saves via `HKObserverQuery`
- On workout completion, fires a "just finished workout" trigger

### WeatherService
- WeatherKit `Weather.current` for current location on demand
- Detects significant changes (rain started, snow, temp drop > 10°)
- Called by PromptGenerator for weather-aware prompt copy

### FocusService
- Reads `INFocusStatus` via `INFocusStatusCenter`
- Publishes current Focus mode state
- NudgeScorer hard-blocks nudges during Sleep / DND / Work (configurable)

### ScreenTimeService + DeviceActivityService
- FamilyControls `AuthorizationCenter.shared.requestAuthorization(for: .individual)`
- DeviceActivityMonitor extension observes app usage thresholds
- Detects: unlock streaks (N unlocks in M minutes), opening of specified apps (TikTok, Instagram), daily screen time milestones
- Reports events back to main app via shared Darwin notifications

### NudgeScorer
Pure, deterministic function. Inputs: `ContextSnapshot`, `UserSettings`, `[NudgeEvent]` (recent history). Output: `NudgeDecision { score: Int, reasons: [String], hardBlocked: Bool, blockReasons: [String] }`.

Scoring table (configurable, defaults):
```
+3  Just changed geofence (entry or exit of known region)
+3  New unknown location detected
+2  Motion transition: walking → stationary (arrived somewhere)
+2  Motion transition: automotive → stationary (arrived after drive)
+2  Calendar event ended within last 5 min
+2  Workout ended within last 10 min
+2  > 2x normal interval since last clip
+2  Weather condition just changed significantly
+1  Phone unlocked after > 15 min idle
+1  AirPods just connected
+1  Just plugged in to charge
+1  Golden hour (solar elevation 3–10°)
+1  Upcoming calendar event in next 15 min (pre-event clip)

Hard blocks (score ignored, nudge suppressed):
- Currently driving (automotive motion, sustained)
- In active phone call (CXCallObserver)
- In Focus mode that user marked as blocking
- Within quiet hours
- Within minGapBetweenNudges from last nudge
- Within 30 min of last clip
- Already hit target for the day (unless user opts into "past target" nudges)
- User tapped "Not now" 3+ times in last 2 hours (temporary 2hr cool-down)
- User tapped "Bad day" button
```

Threshold to fire a context-triggered nudge: **score ≥ 2** (normal sensitivity).
Chill sensitivity: **≥ 3**. Aggressive sensitivity: **≥ 1**.

Baseline time-based nudges fire regardless of score (but still respect hard blocks) if the ideal-spacing timer elapses with no context-triggered nudge.

### NudgeScheduler
The orchestrator. Runs in multiple contexts (main app foreground, BGAppRefreshTask, location change callback, motion activity callback, DeviceActivity callback). Always follows the same loop:

1. Gather current `ContextSnapshot` from all services
2. Pull recent `NudgeEvent` history from SwiftData
3. Pass to `NudgeScorer`
4. If should-fire: create UNNotificationRequest, schedule immediate delivery, log NudgeEvent, update Live Activity
5. If should-not-fire but baseline time is passing: schedule the next baseline-time notification as a fallback
6. Update Live Activity regardless (keeps "next nudge" time fresh)

### LiveActivityController
- Starts a Live Activity at window-open time each day (scheduled via `BGTask`)
- Updates throughout day with: next nudge time, clips filmed today, target, subtle color state
- Ends at window close
- Dynamic Island: compact = "4/8", expanded = full progress + Record button
- Subtle color shift: green (on track) → yellow (behind) → soft orange (well behind). Never red.

### PromptGenerator
Picks a contextual prompt for the next nudge. Priority order:
1. Unused IdeaMemo from today (surfaces voice-memo'd ideas)
2. Custom geofence prompt if triggered by geofence
3. Time-of-day template ("Morning energy check", "What are you up to", "Recap the day")
4. Gap-aware template if gap > 3h ("Long gap — catch us up")
5. Weather-aware template if weather is notable
6. Generic fallback

Prompts live in `Prompts.json`, easily tunable without code changes.

### HandoffService (iPad routing)
- Detects which device was most recently active via NSUbiquitousKeyValueStore heartbeat
- Before scheduling a nudge, writes "preferred target" to iCloud KV
- Widget Extensions on each device check the preferred-target flag and suppress Live Activity on the non-preferred device

---

## 8. Screens

### 8.1 Onboarding

Stepped flow, each step full-screen:

1. **Value prop** — "Film a day-in-the-life without remembering to. VlogNudge watches the context and nudges when it's actually a good moment."
2. **Active window** — time range picker, default 10am–10pm
3. **Target clips per day** — stepper, default 8
4. **Permission: Camera + Mic** — plain-English "so you can film"
5. **Permission: Photos** — "clips save to a Daily Vlogs album for CapCut"
6. **Permission: Notifications** — "how nudges reach you. You control sound and frequency."
7. **Permission: Motion** (optional, skippable) — "so we don't nudge while you're driving, and we know when you just arrived somewhere"
8. **Permission: Location When In Use** (optional) — "to add saved places for Place Nudges"; Always permission is requested later only from Settings → Location / Background Location when the user enables background Place Nudges
9. **Permission: Calendar** (optional) — "we'll skip nudges during your events"
10. **Permission: Health** (optional) — "post-workout is a great nudge moment"
11. **Lock Screen widget add prompt** — with screenshot, deep link to add widget
12. **Done** — lands on Today screen

### 8.2 Today (tab 1)

- Header: current time, today's date
- Big next-nudge countdown: "Next nudge: ~2:40pm" (or "Anytime — context-triggered" if no baseline due)
- Progress row: "5 of 8 clips" with progress dots
- Today's clips strip (horizontal scroll): thumbnail, time, duration
- Prominent "Record now" button (always works, ignores schedule)
- Secondary: "Capture idea" button → IdeaMemo voice recording
- Subtle footer: "Last clip: 11:47am (3h ago)"

### 8.3 Capture (modal, full-screen)

- Full-screen camera preview, vertical lock
- Top-left: close (×)
- Top-center: "Last clip: 11:47am (3h ago)" pill
- Top-right: camera flip
- Middle: subtle framing guide (rule of thirds grid, optional toggle)
- Above record button: topic prompt pill if one exists ("Talk about Brad roast prep")
- Bottom center: big red record button (tap to start, tap to stop)
- Recording indicator: timer ticks up, soft pulse
- Post-record 2-second screen: thumbnail preview, optional star toggle, auto-dismisses

### 8.4 Timeline (tab 2)

- Top: month calendar grid, dots on days with clips
- Selected day below: list of clips — thumbnail, time, duration, topic, star icon
- Tap clip → ClipPreviewView (video player with scrub, delete option, star toggle, notes editor)
- Toolbar action: "Export starred to CapCut" → opens Photos app filtered to starred clips in album

### 8.5 Ideas (tab 3)

- List of IdeaMemos, newest first
- Each row: waveform icon, transcription (if available), time captured, "used" badge if already surfaced
- Tap row to play back
- Big "Capture idea" button at bottom

### 8.6 Settings (tab 4)

- Schedule (window, target, quiet hours)
- Nudge behavior (sensitivity, min gap, escalation on/off, end-of-day recap, midpoint check-in)
- Context signals (toggles for motion, location, calendar, health, weather, focus, screen time)
- Geofences (list, add, edit, delete)
- Notifications (sound on/off, haptic-only mode, test notification button)
- Capture (orientation lock, clip length cap, album name)
- Permissions status (read-only list showing granted/denied with deep link to Settings.app for each)
- About / version / feedback

---

## 9. Widgets

### 9.1 Lock Screen widget (small + rectangular family)

- `rectangular`: "Next: 2:40pm" / "5 of 8 clips today" / progress dots
- `circular`: progress ring with count in center
- `inline`: "Vlog next at 2:40pm"
- Tap anywhere → `RecordClipIntent` opens capture

### 9.2 Home Screen widget

- Small: clip count + next nudge time
- Medium: last 4 clip thumbnails + record button + next nudge
- Large: today's full strip + next nudge + topic prompt + record button
- All interactive (iOS 17 App Intents)

### 9.3 StandBy widget

- Large, glanceable — clock-style display when iPad/iPhone docked sideways
- Shows next nudge time big, clip count smaller
- Subtle ambient pulse in last 10 min before nudge

### 9.4 Live Activity

**Default (Lock Screen presentation):**
- Left: big "4/8" clip count
- Center: "Next: 2:40pm" + subtle progress bar
- Right: tap-to-record button
- Color state: green / yellow / soft orange gradient accent

**Dynamic Island:**
- Compact leading: small record icon
- Compact trailing: "4/8"
- Minimal: record icon
- Expanded: full view with next time, today's clips row, record button

---

## 10. App Intents

```swift
struct RecordClipIntent: AppIntent {
    static var title: LocalizedStringResource = "Record a vlog clip"
    static var openAppWhenRun: Bool = true
    func perform() async throws -> some IntentResult {
        AppState.shared.deepLink = .capture
        return .result()
    }
}

struct NotNowIntent: AppIntent {
    static var title: LocalizedStringResource = "Not now"
    static var openAppWhenRun: Bool = false
    func perform() async throws -> some IntentResult {
        NudgeScheduler.shared.registerNotNow()
        return .result()
    }
}

struct SkipHourIntent: AppIntent {
    static var title: LocalizedStringResource = "Skip this hour"
    static var openAppWhenRun: Bool = false
    func perform() async throws -> some IntentResult {
        NudgeScheduler.shared.skipNextHour()
        return .result()
    }
}

struct CaptureIdeaIntent: AppIntent {
    static var title: LocalizedStringResource = "Capture a vlog idea"
    static var openAppWhenRun: Bool = true
    func perform() async throws -> some IntentResult {
        AppState.shared.deepLink = .ideaMemo
        return .result()
    }
}
```

Notification categories register these as actions so tapping "Record" from the Lock Screen works without opening the app to a menu first.

---

## 11. Nudge Mechanisms (complete list, mapped to v1)

All of the following are in v1:

**Persistent presence**
- Live Activity pinned on Lock Screen all day during active window
- Lock Screen widget (rectangular, circular, inline)
- Home Screen widget (small, medium, large)
- StandBy widget (large glanceable)
- Dynamic Island compact display throughout window + pulse in last 10 min before scheduled nudge

**Notifications**
- Custom NudgeSound.caf
- Inline action buttons: Record, Not now, Skip hour
- Haptic-only mode for public/on-stage situations
- Escalating haptic pattern for second-attempt nudges

**Context triggers (NudgeScorer inputs)**
- Geofence entry (just got home, just got to Secret Pour, etc.)
- Geofence exit (just left home)
- New unknown location detected
- Motion transition: walking → stationary (arrived somewhere)
- Motion transition: automotive → stationary (arrived after drive)
- Calendar event just ended
- Upcoming calendar event in 15 min (pre-event prompt)
- HealthKit workout just completed
- Weather condition just changed significantly
- Golden hour solar position
- Phone unlocked after >15 min idle
- AirPods just connected
- Just plugged in to charge
- Unlock-streak detection (5+ unlocks in 10 min without filming)
- App-open trigger (TikTok/Instagram opened) — Screen Time

**Behavioral / ADHD-specific**
- "You just changed locations" contextual prompts
- Gap-aware prompts ("Long gap — catch us up")
- Last-clip-time grounding shown on every record screen
- Momentum detection (3 clips in 15 min → suppress next 2 nudges)
- "Not now" learns → drops sensitivity for 2hr automatically
- "Bad day" button → mutes for today with no guilt
- End-of-day recap prompt (9pm-ish, "you got X clips today, quick recap?")
- Midpoint check-in if 0 clips by window midpoint

**Prompt intelligence (what the nudge says)**
- IdeaMemo voice-captured thoughts surface as prompts
- Location-aware prompt bank (per-geofence custom prompts)
- Time-of-day prompt templates
- Weather-aware prompt phrasing
- Gap-aware prompt phrasing
- Last-clip-topic follow-up phrasing

**Cross-device (iPad routing)**
- Most-recently-active device receives the nudge
- Nudge on iPad opens iPad app's record screen OR shows "record on iPhone" push depending on setting
- StandBy nudge on docked iPad

**Philosophy reminders surfaced in UI**
- Every notification shows the reason ("Nudged because: you just got home") via Notification Service Extension
- Analytics view in Settings → "What's working": shows nudge→clip conversion rate by trigger type so user can tune

---

## 12. CapCut Export Flow

CapCut imports from the iOS Photos library, so the path is:

1. All clips save to `Daily Vlogs` album in Photos on record
2. Timeline screen has "Export starred to CapCut" button
3. Tapping it opens the Photos app via `photos-redirect://` URL scheme to the album
4. User selects clips (starred are visually distinct via a Smart Album filter we create) and shares to CapCut

Future enhancement (not v1): a tighter CapCut handoff is only possible if CapCut publishes a public import API (e.g. a URL scheme or share extension that accepts a set of asset IDs). No such API exists today, so the manual Photos → share path above is the supported flow.

---

## 13. Build Sequence

Even though everything ships in v1, there's a sensible order to write the code so you always have something running. Rough week-by-week:

**Week 1 — foundations**
- Xcode project setup, all targets created, App Group wired up
- Models defined in SwiftData, basic persistence working
- Tab bar scaffold: Today, Timeline, Ideas, Settings
- RecordingService + CaptureView: can manually record and save to Photos album
- PhotosService: album creation, fetch, thumbnails

**Week 2 — nudges baseline**
- NotificationService + categories + action intents
- NudgeScheduler time-based baseline
- Today screen wired to show next nudge + clip count
- Live Activity (basic version)
- Lock Screen widget (rectangular)

**Week 3 — context services**
- MotionService + integration into NudgeScorer
- LocationService + geofence monitoring + GeofenceManagementView
- PromptGenerator with Prompts.json
- Idea memo record flow + SFSpeechRecognizer transcription

**Week 4 — calendar, health, weather, focus**
- CalendarService + EventKit integration
- HealthService + workout observer
- WeatherService + significant change detection
- FocusService + hard-block wiring
- Golden hour calculation

**Week 5 — Screen Time, iPad, polish**
- DeviceActivityService + extension
- Unlock streak detection, app-open triggers
- iPad universal layout pass
- HandoffService + cross-device routing
- StandBy widget
- Home Screen widget variants

**Week 6 — polish + analytics**
- End-of-day recap flow
- Midpoint check-in
- "Not now" / "Bad day" learning
- Nudge analytics view in Settings
- Custom NudgeSound.caf design
- Onboarding flow polish
- Test on actual daily use for at least 3 days before shipping

---

## 14. Decisions Still Needed

Before we start coding, confirm or push back on:

1. **Photos album name** — "Daily Vlogs" or something else? (Changes album creation string)
2. **Orientation** — vertical-only for v1? (Simpler, matches shorts workflow)
3. **Default target clips/day** — 8 feels right given hourly-ish goal. Confirm?
4. **Default window** — 10am–10pm. Confirm given your schedule (open mics late)?
5. **App name** — "VlogNudge" is placeholder. Real name?
6. **iCloud sync across iPhone/iPad** — yes or no for v1? (If yes, CloudKit adds real complexity. If no, each device is independent.)
7. **Transcription on IdeaMemos** — on-device via SFSpeechRecognizer (free, works offline) or skip for v1?
8. **Screen Time features** — genuinely off by default? (They're powerful but the permission is heavy and DeviceActivityMonitor is the hardest extension in this app.)

---

## 15. Risks / Things That Will Take Longer Than Expected

Being honest about where the schedule will probably slip:

- **Family Controls / Screen Time APIs.** Apple gates these heavily. The DeviceActivityMonitor extension has a weird execution model (separate process, limited runtime, unusual debugging). Budget extra time or cut this for v1.
- **Live Activity edge cases.** Starting, updating, ending across day boundaries, app termination, device reboot — lots of states to handle. ActivityKit has improved a lot in iOS 17 but still has gotchas.
- **Background execution limits.** iOS aggressively kills background tasks. The scheduler has to be resilient to being woken briefly, doing its work, and suspending. This is why each service must be designed for short-burst execution, not long-running loops.
- **Geofence count limits.** iOS allows ~20 monitored regions per app. If you want to save lots of spots, need a rolling activation strategy based on current location.
- **iCloud sync.** If you want iPad ↔ iPhone sync, CloudKit + SwiftData sync works but has conflict edge cases. Plan for "last write wins" and accept some imperfection.
- **WeatherKit.** Requires paid developer account and has request quotas. Cheap at this scale but not free.

---

## 16. Ready to Code?

Once you sign off (or adjust) sections 14 and 15, next step is:

1. Create the Xcode project (universal, iOS 17 min)
2. Add the widget, intents, device activity, and notification service targets
3. Configure App Group + entitlements
4. Drop in the folder structure from section 5
5. Start with `RecordingService` + `CaptureView` — get a clip saving to the Photos album before anything else

That's the foundation everything else builds on. Ship the record path first, then layer nudges, then layer context.
